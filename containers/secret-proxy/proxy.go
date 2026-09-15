package main

import (
	"context"
	"errors"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"strings"
	"time"
)

func newTransport() *http.Transport {
	t := http.DefaultTransport.(*http.Transport).Clone()
	// Credentials go directly to the configured TLS upstream, independently of
	// proxy environment variables inherited by the container runtime.
	t.Proxy = nil
	t.DialContext = (&net.Dialer{Timeout: 10 * time.Second, KeepAlive: 30 * time.Second}).DialContext
	t.TLSHandshakeTimeout = 10 * time.Second
	// The request context bounds server processing as well as body streaming;
	// a shorter header timeout would abort slow Git pushes prematurely.
	t.ResponseHeaderTimeout = 0
	t.MaxConnsPerHost = 32
	t.MaxIdleConnsPerHost = 8
	return t
}

func newHandler(services map[string]service, transport http.RoundTripper, timeout time.Duration, logger *log.Logger) http.Handler {
	routes := make(map[string]*httputil.ReverseProxy, len(services))
	for name, s := range services {
		routes[name] = &httputil.ReverseProxy{
			Transport: transport,
			// Stream Git pack data and API responses rather than buffering them.
			FlushInterval: -1,
			// Transport errors can contain request data. Emit only our fixed
			// diagnostic in ErrorHandler, never the library's detailed errors.
			ErrorLog: log.New(io.Discard, "", 0),
			Rewrite: func(pr *httputil.ProxyRequest) {
				pr.Out.URL.Path = strings.TrimPrefix(pr.In.URL.Path, "/"+name)
				pr.Out.URL.RawPath = strings.TrimPrefix(pr.In.URL.EscapedPath(), "/"+name)
				// ReverseProxy cleans some raw queries before Rewrite. We do not
				// interpret queries and must preserve the upstream's own syntax.
				pr.Out.URL.RawQuery = pr.In.URL.RawQuery
				if pr.Out.URL.Path == "" {
					pr.Out.URL.Path = "/"
					pr.Out.URL.RawPath = ""
				}
				pr.SetURL(s.upstream)
				pr.Out.Header.Del("Authorization")
				pr.Out.Header.Del("Proxy-Authorization")
				pr.Out.Header.Del("Cookie")
				// Rewrite runs after hop-by-hop header removal, so a caller's
				// Connection header cannot suppress the injected credential.
				pr.Out.Header.Set(s.headerName, s.headerValue)
			},
			ModifyResponse: func(resp *http.Response) error {
				// Do not let clients follow a redirect outside the local route.
				// Upstreams must be configured with their final HTTPS address.
				if resp.StatusCode >= 300 && resp.StatusCode < 400 && resp.Header.Get("Location") != "" {
					return errors.New("upstream redirect refused")
				}
				stripResponseCredentials(resp.Header, s.headerName)
				stripResponseCredentials(resp.Trailer, s.headerName)
				resp.Body = &credentialFilteredBody{ReadCloser: resp.Body, trailer: resp.Trailer, header: s.headerName}
				return nil
			},
			ErrorHandler: func(w http.ResponseWriter, r *http.Request, _ error) {
				if r.Context().Err() == context.DeadlineExceeded {
					logger.Printf("service %s: request timed out", name)
					http.Error(w, "upstream timeout", http.StatusGatewayTimeout)
					return
				}
				logger.Printf("service %s: upstream request failed", name)
				http.Error(w, "upstream request failed", http.StatusBadGateway)
			},
		}
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodConnect || r.URL.IsAbs() || r.Header.Get("Upgrade") != "" {
			http.Error(w, "only ordinary HTTP requests are supported", http.StatusBadRequest)
			return
		}
		path := r.URL.EscapedPath()
		if !strings.HasPrefix(path, "/") {
			http.NotFound(w, r)
			return
		}
		name, _, _ := strings.Cut(path[1:], "/")
		proxy, ok := routes[name]
		if !ok {
			http.NotFound(w, r)
			return
		}
		ctx, cancel := context.WithTimeout(r.Context(), timeout)
		defer cancel()
		// Context cancellation bounds the upstream request; socket deadlines
		// also bound slow clients sending a body or reading a streamed response.
		deadline, _ := ctx.Deadline()
		controller := http.NewResponseController(w)
		_ = controller.SetReadDeadline(deadline)
		_ = controller.SetWriteDeadline(deadline)
		proxy.ServeHTTP(w, r.WithContext(ctx))
	})
}

func stripResponseCredentials(headers http.Header, credentialHeader string) {
	headers.Del(credentialHeader)
	headers.Del("Authorization")
	headers.Del("Proxy-Authorization")
	headers.Del("Set-Cookie")
}

// Trailers are populated as the body reaches EOF. Filtering only the initial
// headers would allow the same fields to be forwarded later as trailers.
type credentialFilteredBody struct {
	io.ReadCloser
	trailer http.Header
	header  string
}

func (b *credentialFilteredBody) Read(p []byte) (int, error) {
	n, err := b.ReadCloser.Read(p)
	if err != nil {
		stripResponseCredentials(b.trailer, b.header)
	}
	return n, err
}
