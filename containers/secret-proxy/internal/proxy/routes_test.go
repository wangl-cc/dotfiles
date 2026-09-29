package proxy

import (
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
)

func TestAdaptersShareDestinationsAndIsolateCredentials(t *testing.T) {
	upstreams := map[string]credential{
		"api.example.com":     {"Authorization", "Bearer first-token"},
		"second.example.com":  {"Authorization", "Bearer second-token"},
		"uploads.example.com": {"X-Api-Key", "upload-token"},
	}
	for _, a := range []adapter{pathAdapter, hostAdapter} {
		for _, tc := range []struct{ host, path, header, value string }{
			{"API.EXAMPLE.COM:443", "/repos/a%2Fb?x=a%2Bb&literal=a;b", "Authorization", "Bearer first-token"},
			{"second.example.com", "/graphql", "Authorization", "Bearer second-token"},
			{"uploads.example.com", "/assets", "X-Api-Key", "upload-token"},
			{"downloads.example.com", "/?", "", ""},
			{"api.example.com.other.example", "/asset", "", ""},
		} {
			t.Run(string(a)+"/"+tc.host, func(t *testing.T) {
				transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
					host := strings.ToLower(strings.TrimSuffix(tc.host, ":443"))
					if r.URL.Scheme != "https" || r.URL.RequestURI() != tc.path || r.Host != host || r.URL.Host != host {
						t.Errorf("request changed: %s %s", r.Host, r.URL)
					}
					for _, name := range []string{"Authorization", "X-Api-Key", "Proxy-Authorization", "Cookie"} {
						want := ""
						if name == tc.header {
							want = tc.value
						}
						if r.Header.Get(name) != want {
							t.Errorf("wrong %s for %s", name, host)
						}
					}
					return &http.Response{StatusCode: 200, Header: make(http.Header), Body: http.NoBody, Request: r}, nil
				})
				path := tc.path
				if a == pathAdapter {
					path = "/" + tc.host + path
				}
				req := httptest.NewRequest("GET", path, nil)
				req.Host = tc.host
				if a == pathAdapter {
					req.Host = "proxy.internal:8787"
				}
				req.Header.Set("Authorization", "client-secret")
				req.Header.Set("X-Api-Key", "client-secret")
				req.Header.Set("Proxy-Authorization", "client-secret")
				req.Header.Set("Cookie", "client-secret")
				recorder := httptest.NewRecorder()
				a.handler(upstreams, transport, log.New(io.Discard, "", 0)).ServeHTTP(recorder, req)
				if recorder.Code != 200 {
					t.Fatalf("status %d", recorder.Code)
				}
			})
		}
	}
}

func TestAdaptersRejectInvalidDestinations(t *testing.T) {
	transport := roundTripFunc(func(*http.Request) (*http.Response, error) { t.Fatal("unexpected upstream call"); return nil, nil })
	for _, a := range []adapter{pathAdapter, hostAdapter} {
		for _, host := range []string{"", "api.example.com.", "api.example.com:80", "api.example.com:", "secret@api.example.com", "%61pi.example.com", "api.example.com%2Fevil", ".."} {
			path := "/graphql"
			if a == pathAdapter {
				path = "/" + host + path
			}
			req := httptest.NewRequest("GET", path, nil)
			req.Host = host
			recorder := httptest.NewRecorder()
			a.handler(nil, transport, log.New(io.Discard, "", 0)).ServeHTTP(recorder, req)
			if recorder.Code != 403 {
				t.Errorf("%s host %q status %d", a, host, recorder.Code)
			}
		}
	}
}

func TestAdaptersRejectUnsupportedRequests(t *testing.T) {
	upstreams := map[string]credential{"api.example.com": {}}
	transport := roundTripFunc(func(*http.Request) (*http.Response, error) { t.Fatal("unexpected upstream call"); return nil, nil })
	for _, a := range []adapter{pathAdapter, hostAdapter} {
		for _, tc := range []struct{ method, path, upgrade string }{
			{"GET", "https://api.example.com/path", ""},
			{"CONNECT", "/api.example.com/path", ""},
			{"GET", "/api.example.com/path", "websocket"},
		} {
			req := httptest.NewRequest(tc.method, tc.path, nil)
			req.Host = "api.example.com"
			req.Header.Set("Upgrade", tc.upgrade)
			recorder := httptest.NewRecorder()
			a.handler(upstreams, transport, log.New(io.Discard, "", 0)).ServeHTTP(recorder, req)
			if recorder.Code != http.StatusBadRequest {
				t.Errorf("%s %s %s: status %d", a, tc.method, tc.path, recorder.Code)
			}
		}
	}
}

func TestRedirectsReturnThroughSameAdapter(t *testing.T) {
	for _, a := range []adapter{pathAdapter, hostAdapter} {
		for _, tc := range []struct {
			name, location, target string
			denied                 bool
		}{
			{name: "relative", location: "../asset?signature=a%2Fb", target: "api.example.com/asset?signature=a%2Fb"},
			{name: "root relative", location: "/asset", target: "api.example.com/asset"},
			{name: "API", location: "https://api.example.com/repos/a", target: "api.example.com/repos/a"},
			{name: "download", location: "https://download.example.com/a%2Fb?sig=x#section", target: "download.example.com/a%2Fb?sig=x#section"},
			{name: "default port", location: "https://DOWNLOAD.example.com:443/asset", target: "download.example.com/asset"},
			{name: "root", location: "https://download.example.com", target: "download.example.com/"},
			{name: "HTTP", location: "http://api.example.com/repos", denied: true},
			{name: "network relative", location: "//download.example.com/asset", target: "download.example.com/asset"},
			{name: "userinfo", location: "https://secret@download.example.com/asset", denied: true},
			{name: "bad port", location: "https://download.example.com:80/asset", denied: true},
			{name: "invalid host", location: "https://download.example.com./asset", denied: true},
			{name: "opaque", location: "https:opaque", denied: true},
		} {
			t.Run(string(a)+"/"+tc.name, func(t *testing.T) {
				transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
					return &http.Response{StatusCode: 302, Header: http.Header{"Location": {tc.location}}, Body: io.NopCloser(strings.NewReader("")), Request: r}, nil
				})
				handler := a.handler(nil, transport, log.New(io.Discard, "", 0))
				path := "/repos/a"
				if a == pathAdapter {
					path = "/api.example.com" + path
				}
				req := httptest.NewRequest("GET", path, nil)
				req.Host = "api.example.com"
				recorder := httptest.NewRecorder()
				handler.ServeHTTP(recorder, req)
				if tc.denied {
					if recorder.Code != 502 || recorder.Header().Get("Location") != "" {
						t.Fatal("unsafe redirect escaped")
					}
				} else {
					want := "https://" + tc.target
					if a == pathAdapter {
						want = "/" + tc.target
					}
					if recorder.Code != 302 || recorder.Header().Get("Location") != want {
						t.Fatalf("got %d %q, want 302 %q", recorder.Code, recorder.Header().Get("Location"), want)
					}
				}
			})
		}
	}
}

func TestRedirectFollowWithRealTransport(t *testing.T) {
	upstreams := map[string]credential{
		"api.example.com":     {"Authorization", "Bearer fixture-token"},
		"uploads.example.com": {"X-Api-Key", "upload-token"},
	}
	for _, http2 := range []bool{false, true} {
		name, protocol := "HTTP1", 1
		if http2 {
			name, protocol = "HTTP2", 2
		}
		t.Run(name, func(t *testing.T) {
			var calls atomic.Int32
			upstream := httptest.NewUnstartedServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				calls.Add(1)
				if r.ProtoMajor != protocol {
					t.Errorf("upstream used HTTP/%d, want HTTP/%d", r.ProtoMajor, protocol)
				}
				switch r.Host {
				case "api.example.com":
					if r.Header.Get("Authorization") != "Bearer fixture-token" {
						t.Error("missing API credential")
					}
					w.Header().Set("Location", "https://download.example.com/a%2Fb?sig=a%2Bb")
					w.WriteHeader(http.StatusFound)
				case "download.example.com":
					if r.Header.Get("Authorization") != "" || r.Header.Get("X-Api-Key") != "" || r.URL.RequestURI() != "/a%2Fb?sig=a%2Bb" {
						t.Error("wrong download path or leaked credential")
					}
					w.Header().Set("Location", "https://uploads.example.com/asset")
					w.WriteHeader(http.StatusFound)
				case "uploads.example.com":
					if r.Header.Get("Authorization") != "" || r.Header.Get("X-Api-Key") != "upload-token" {
						t.Error("redirect did not select the target credential")
					}
					_, _ = io.WriteString(w, "asset")
				default:
					t.Errorf("unexpected upstream: %s", r.Host)
					w.WriteHeader(http.StatusBadRequest)
				}
			}))
			upstream.EnableHTTP2 = http2
			upstream.StartTLS()
			defer upstream.Close()
			transport := fixtureTransport(upstream)
			defer transport.CloseIdleConnections()
			server := httptest.NewServer(pathAdapter.handler(upstreams, transport, log.New(io.Discard, "", 0)))
			defer server.Close()
			resp, err := server.Client().Get(server.URL + "/api.example.com/asset")
			if err != nil {
				t.Fatal(err)
			}
			defer resp.Body.Close()
			body, err := io.ReadAll(resp.Body)
			if err != nil || resp.StatusCode != 200 || string(body) != "asset" || calls.Load() != 3 || resp.Request.URL.Host != strings.TrimPrefix(server.URL, "http://") {
				t.Fatal("redirect left the proxy or failed to reach the target")
			}
		})
	}
}
