package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func testHandler(t *testing.T, upstream *httptest.Server, auth authConfig, timeout time.Duration, output io.Writer) http.Handler {
	t.Helper()
	dir := t.TempDir()
	auth.Credential = "token"
	writeFile(t, dir, "token", "dummy-secret\n")
	s, err := compileService(serviceConfig{Upstream: upstream.URL + "/base", Auth: auth}, dir)
	if err != nil {
		t.Fatal(err)
	}
	return newHandler(map[string]service{"example": s}, upstream.Client().Transport, timeout, log.New(output, "", 0))
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
			upstream := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.Method != http.MethodPost || r.RequestURI != "/base/project%20name/git-receive-pack?x=a%2Bb&x=c&literal=a;b" {
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
			defer upstream.Close()
			proxy := httptest.NewServer(testHandler(t, upstream, tc.auth, time.Second, io.Discard))
			defer proxy.Close()
			req, err := http.NewRequest(http.MethodPost, proxy.URL+"/example/project%20name/git-receive-pack?x=a%2Bb&x=c&literal=a;b", bytes.NewReader(body))
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

func TestRouteIsolationAndUnsupportedRequests(t *testing.T) {
	var calls atomic.Int32
	upstream := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		_, _ = io.WriteString(w, r.Header.Get("X-Key"))
	}))
	defer upstream.Close()
	dir := t.TempDir()
	services := make(map[string]service)
	for _, name := range []string{"first", "second"} {
		writeFile(t, dir, name, name+"-secret")
		s, err := compileService(serviceConfig{Upstream: upstream.URL, Auth: authConfig{Type: "header", Header: "X-Key", Credential: name}}, dir)
		if err != nil {
			t.Fatal(err)
		}
		services[name] = s
	}
	handler := newHandler(services, upstream.Client().Transport, time.Second, log.New(io.Discard, "", 0))
	for name := range services {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/"+name+"/anything", nil))
		if recorder.Code != 200 || recorder.Body.String() != name+"-secret" {
			t.Fatalf("wrong service selected for %s", name)
		}
	}
	for _, tc := range []struct {
		method, path, upgrade string
		status                int
	}{
		{"GET", "/", "", 404},
		{"GET", "/missing/path", "", 404},
		{"GET", "/first-suffix/path", "", 404},
		{"GET", "/%66irst/path", "", 404},
		{"GET", "https://other.example/first/path", "", 400},
		{"CONNECT", "/first/path", "", 400},
		{"GET", "/first/path", "websocket", 400},
	} {
		recorder := httptest.NewRecorder()
		req := httptest.NewRequest(tc.method, tc.path, nil)
		req.Header.Set("Upgrade", tc.upgrade)
		handler.ServeHTTP(recorder, req)
		if recorder.Code != tc.status {
			t.Errorf("%s %s: got %d, want %d", tc.method, tc.path, recorder.Code, tc.status)
		}
	}
	if calls.Load() != 2 {
		t.Fatal("unmatched or unsupported request reached upstream")
	}
}

func TestRedirectDoesNotEscapeProxy(t *testing.T) {
	var redirected atomic.Int32
	other := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { redirected.Add(1) }))
	defer other.Close()
	upstream := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, other.URL+"/private-target", http.StatusTemporaryRedirect)
	}))
	defer upstream.Close()
	proxy := httptest.NewServer(testHandler(t, upstream, authConfig{Type: "bearer"}, time.Second, io.Discard))
	defer proxy.Close()
	resp, err := proxy.Client().Get(proxy.URL + "/example/path")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusBadGateway || resp.Header.Get("Location") != "" || redirected.Load() != 0 || strings.Contains(string(body), "private-target") {
		t.Fatal("redirect was followed or returned to the caller")
	}
}

func TestStreamingAndCancellation(t *testing.T) {
	canceled := make(chan struct{})
	upstream := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.WriteString(w, "first chunk\n")
		w.(http.Flusher).Flush()
		<-r.Context().Done()
		close(canceled)
	}))
	defer upstream.Close()
	proxy := httptest.NewServer(testHandler(t, upstream, authConfig{Type: "bearer"}, 3*time.Second, io.Discard))
	defer proxy.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, proxy.URL+"/example/stream", nil)
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

func TestErrorsAreRedactedAndRequestsExpire(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "token", "dummy-secret")
	s, err := compileService(serviceConfig{Upstream: "https://example.com", Auth: authConfig{Type: "bearer", Credential: "token"}}, dir)
	if err != nil {
		t.Fatal(err)
	}
	for _, deadline := range []bool{false, true} {
		var output bytes.Buffer
		transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
			if deadline {
				<-r.Context().Done()
			}
			return nil, errors.New("transport failure with dummy-secret and private-path")
		})
		handler := newHandler(map[string]service{"example": s}, transport, 20*time.Millisecond, log.New(&output, "", 0))
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/example/private-path", nil))
		want := http.StatusBadGateway
		if deadline {
			want = http.StatusGatewayTimeout
		}
		if w.Code != want {
			t.Errorf("got %d, want %d", w.Code, want)
		}
		for _, secret := range []string{"dummy-secret", "private-path"} {
			if strings.Contains(output.String()+w.Body.String(), secret) {
				t.Errorf("error output leaked %s", secret)
			}
		}
	}
}

func TestTransportIgnoresProxyEnvironment(t *testing.T) {
	t.Setenv("HTTPS_PROXY", "http://unexpected-proxy.invalid")
	transport := newTransport()
	defer transport.CloseIdleConnections()
	if transport.Proxy != nil || transport.TLSClientConfig != nil && transport.TLSClientConfig.InsecureSkipVerify {
		t.Fatal("transport can send credentials through an environment proxy or skip certificate verification")
	}
	if transport.ResponseHeaderTimeout != 0 {
		t.Fatal("transport overrides the overall request deadline with an earlier header timeout")
	}
}

func TestResponseTrailersFilterCredentialsAndPreserveOtherFields(t *testing.T) {
	upstream := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Trailer", "X-Api-Key, Authorization, Set-Cookie, X-Result")
		w.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(w, "body")
		w.(http.Flusher).Flush()
		w.Header().Set("X-Api-Key", "dummy-secret")
		w.Header().Set("Authorization", "Bearer dummy-secret")
		w.Header().Set("Set-Cookie", "session=dummy-secret")
		w.Header().Set("X-Result", "finished")
	}))
	defer upstream.Close()
	proxy := httptest.NewServer(testHandler(t, upstream, authConfig{Type: "header", Header: "X-Api-Key"}, time.Second, io.Discard))
	defer proxy.Close()
	resp, err := proxy.Client().Get(proxy.URL + "/example/path")
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
