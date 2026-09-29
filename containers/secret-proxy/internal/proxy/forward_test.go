package proxy

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"errors"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"syscall"
	"testing"
	"time"
)

// Keep real TLS and HTTP exchanges local while preserving the configured Host.
func fixtureTransport(server *httptest.Server) *http.Transport {
	transport := server.Client().Transport.(*http.Transport).Clone()
	transport.Proxy = nil
	transport.TLSClientConfig = transport.TLSClientConfig.Clone()
	transport.TLSClientConfig.ServerName, _, _ = net.SplitHostPort(server.Listener.Addr().String())
	transport.DialContext = func(ctx context.Context, _, _ string) (net.Conn, error) {
		return (&net.Dialer{}).DialContext(ctx, "tcp", server.Listener.Addr().String())
	}
	return transport
}

func testHandler(t *testing.T, server *httptest.Server, auth authConfig, output io.Writer) http.Handler {
	t.Helper()
	dir := t.TempDir()
	auth.Credential = "token"
	writeFile(t, dir, "token", "dummy-secret\n")
	s, err := compileAuth(&auth, dir)
	if err != nil {
		t.Fatal(err)
	}
	return pathAdapter.handler(map[string]credential{"example.com": s}, fixtureTransport(server), log.New(output, "", 0))
}

func TestAuthAndHTTPForwarding(t *testing.T) {
	for _, tc := range []struct {
		name          string
		auth          authConfig
		header, value string
	}{
		{"basic", authConfig{Type: "basic", Username: "git"}, "Authorization", "Basic " + base64.StdEncoding.EncodeToString([]byte("git:dummy-secret"))},
		{"bearer", authConfig{Type: "bearer"}, "Authorization", "Bearer dummy-secret"},
		{"header", authConfig{Type: "header", Header: "X-Api-Key"}, "X-Api-Key", "dummy-secret"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			body := []byte{0, 1, 2, 255, '\n', 'x'}
			server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.Method != http.MethodPost || r.RequestURI != "/project%20name/git-receive-pack?x=a%2Bb&x=c&literal=a;b" {
					t.Errorf("request changed: %s %s", r.Method, r.RequestURI)
				}
				if r.Header.Get(tc.header) != tc.value || len(r.Header.Values(tc.header)) != 1 {
					t.Errorf("incorrect injected authentication header")
				}
				if tc.header != "Authorization" && r.Header.Get("Authorization") != "" {
					t.Error("client Authorization reached custom-header upstream")
				}
				for _, header := range []string{"Proxy-Authorization", "Cookie", "Forwarded", "X-Forwarded-Host", "X-Forwarded-For"} {
					if r.Header.Get(header) != "" {
						t.Errorf("client %s reached upstream", header)
					}
				}
				if r.Host == "caller.invalid" {
					t.Error("caller controlled upstream Host")
				}
				if r.Header.Get("Git-Protocol") != "version=2" {
					t.Error("Git-Protocol header lost")
				}
				got, err := io.ReadAll(r.Body)
				if err != nil || !bytes.Equal(got, body) {
					t.Errorf("request body changed: %v", err)
				}
				w.Header().Set("Content-Type", "application/x-git-receive-pack-result")
				w.Header().Set(tc.header, tc.value)
				w.Header().Set("Set-Cookie", "not-a-session-proxy")
				w.WriteHeader(http.StatusAccepted)
				_, _ = w.Write(body)
			}))
			defer server.Close()
			proxy := httptest.NewServer(testHandler(t, server, tc.auth, io.Discard))
			defer proxy.Close()
			req, err := http.NewRequest(http.MethodPost, proxy.URL+"/example.com/project%20name/git-receive-pack?x=a%2Bb&x=c&literal=a;b", bytes.NewReader(body))
			if err != nil {
				t.Fatal(err)
			}
			req.Host = "caller.invalid"
			req.Header.Set(tc.header, "caller-secret")
			req.Header.Set("Authorization", "caller-secret")
			req.Header.Set("Proxy-Authorization", "caller-secret")
			req.Header.Set("Cookie", "caller-secret")
			req.Header.Set("Connection", tc.header)
			req.Header.Set("Forwarded", "host=evil.example")
			req.Header.Set("X-Forwarded-Host", "evil.example")
			req.Header.Set("X-Forwarded-For", "1.2.3.4")
			req.Header.Set("Git-Protocol", "version=2")
			resp, err := proxy.Client().Do(req)
			if err != nil {
				t.Fatal(err)
			}
			defer resp.Body.Close()
			got, err := io.ReadAll(resp.Body)
			if err != nil || !bytes.Equal(got, body) || resp.StatusCode != http.StatusAccepted {
				t.Fatalf("response changed: %d %x %v", resp.StatusCode, got, err)
			}
			if resp.Header.Get(tc.header) != "" || resp.Header.Get("Set-Cookie") != "" {
				t.Error("authentication header or cookie reflected to client")
			}
		})
	}
}

func TestStreamingAndCancellation(t *testing.T) {
	canceled := make(chan struct{})
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.WriteString(w, "first chunk\n")
		w.(http.Flusher).Flush()
		<-r.Context().Done()
		close(canceled)
	}))
	defer server.Close()
	proxy := httptest.NewServer(testHandler(t, server, authConfig{Type: "bearer"}, io.Discard))
	defer proxy.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, proxy.URL+"/example.com/stream", nil)
	resp, err := proxy.Client().Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	buf := make([]byte, len("first chunk\n"))
	if _, err := io.ReadFull(resp.Body, buf); err != nil || string(buf) != "first chunk\n" {
		t.Fatalf("response was not streamed: %q %v", buf, err)
	}
	cancel()
	select {
	case <-canceled:
	case <-time.After(time.Second):
		t.Fatal("client cancellation did not reach upstream")
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestErrorsReportCausesWithoutSensitiveData(t *testing.T) {
	for _, tc := range []struct {
		name, reason string
		err          error
		status       int
	}{
		{"DNS", "DNS lookup failed", &net.DNSError{Err: "no such host", Name: "example.com", IsNotFound: true}, 502},
		{"TLS", "x509.UnknownAuthorityError", &tls.CertificateVerificationError{Err: x509.UnknownAuthorityError{}}, 502},
		{"connection", "connection refused", &net.OpError{Op: "dial", Net: "tcp", Err: syscall.ECONNREFUSED}, 502},
		{"timeout", "network timeout", context.DeadlineExceeded, 504},
		{"unknown", "upstream failure", errors.New("failure with dummy-secret and private-path"), 502},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var output bytes.Buffer
			transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
				return nil, &url.Error{Op: "Get", URL: r.URL.String(), Err: tc.err}
			})
			handler := pathAdapter.handler(nil, transport, log.New(&output, "", 0))
			w := httptest.NewRecorder()
			handler.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/example.com/private-path?signature=dummy-secret", nil))
			if w.Code != tc.status || !strings.Contains(output.String(), tc.reason) || !strings.Contains(output.String(), "example.com") {
				t.Fatalf("status %d, log %q; want %d and %q", w.Code, output.String(), tc.status, tc.reason)
			}
			for _, secret := range []string{"dummy-secret", "private-path"} {
				if strings.Contains(output.String()+w.Body.String(), secret) {
					t.Errorf("error output leaked %s", secret)
				}
			}
		})
	}
}

func TestTransportIgnoresProxyEnvironment(t *testing.T) {
	t.Setenv("HTTPS_PROXY", "http://unexpected-proxy.invalid")
	transport := newTransport()
	defer transport.CloseIdleConnections()
	if transport.Proxy != nil || transport.TLSClientConfig != nil && transport.TLSClientConfig.InsecureSkipVerify {
		t.Fatal("transport can send credentials through an environment proxy or skip certificate verification")
	}
}

func TestResponseTrailersFilterCredentialsAndPreserveOtherFields(t *testing.T) {
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Trailer", "X-Api-Key, Authorization, Set-Cookie, X-Result")
		w.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(w, "body")
		w.(http.Flusher).Flush()
		w.Header().Set("X-Api-Key", "dummy-secret")
		w.Header().Set("Authorization", "Bearer dummy-secret")
		w.Header().Set("Set-Cookie", "session=dummy-secret")
		w.Header().Set("X-Result", "finished")
	}))
	defer server.Close()
	proxy := httptest.NewServer(testHandler(t, server, authConfig{Type: "header", Header: "X-Api-Key"}, io.Discard))
	defer proxy.Close()
	resp, err := proxy.Client().Get(proxy.URL + "/example.com/path")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if _, err := io.ReadAll(resp.Body); err != nil {
		t.Fatal(err)
	}
	for _, header := range []string{"X-Api-Key", "Authorization", "Set-Cookie"} {
		if resp.Header.Get(header) != "" || resp.Trailer.Get(header) != "" {
			t.Errorf("credential or cookie survived in %s", header)
		}
	}
	if resp.Trailer.Get("X-Result") != "finished" {
		t.Fatal("ordinary response trailer was lost")
	}
}
