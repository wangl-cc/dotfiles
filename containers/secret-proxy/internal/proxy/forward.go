package proxy

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"syscall"
)

var errRedirectRefused = errors.New("upstream redirect refused")

func newTransport() *http.Transport {
	t := http.DefaultTransport.(*http.Transport).Clone()
	// Credentials go directly to the configured TLS upstream, independently of
	// proxy environment variables inherited by the container runtime.
	t.Proxy = nil
	return t
}

// Both adapters share credential filtering, streaming, and failure reporting.
func newReverseProxy(transport http.RoundTripper, logger *log.Logger, credentialHeaders []string, rewrite func(*httputil.ProxyRequest), allowResponse func(*http.Response) bool) *httputil.ReverseProxy {
	return &httputil.ReverseProxy{
		Transport:     transport,
		FlushInterval: -1,
		ErrorLog:      log.New(io.Discard, "", 0),
		Rewrite: func(pr *httputil.ProxyRequest) {
			// Rewrite runs after hop-by-hop header removal, so filtering and
			// credential injection cannot be overridden by Connection headers.
			stripCredentials(pr.Out.Header, credentialHeaders)
			stripCredentials(pr.Out.Trailer, credentialHeaders)
			if pr.Out.Body != nil {
				pr.Out.Body = &credentialFilteredBody{ReadCloser: pr.Out.Body, trailer: pr.Out.Trailer, headers: credentialHeaders}
			}
			rewrite(pr)
		},
		ModifyResponse: func(resp *http.Response) error {
			if !allowResponse(resp) {
				return errRedirectRefused
			}
			stripCredentials(resp.Header, credentialHeaders)
			stripCredentials(resp.Trailer, credentialHeaders)
			resp.Body = &credentialFilteredBody{ReadCloser: resp.Body, trailer: resp.Trailer, headers: credentialHeaders}
			return nil
		},
		ErrorHandler: func(w http.ResponseWriter, r *http.Request, err error) {
			logger.Printf("upstream %s: %s", r.URL.Host, upstreamFailure(err))
			var networkError net.Error
			if errors.As(err, &networkError) && networkError.Timeout() {
				http.Error(w, "upstream timeout", http.StatusGatewayTimeout)
				return
			}
			http.Error(w, "upstream request failed", http.StatusBadGateway)
		},
	}
}

// Network errors can include signed URLs or upstream-controlled text. Report
// typed causes and OS error messages without logging that arbitrary content.
func upstreamFailure(err error) string {
	var dns *net.DNSError
	var cert *tls.CertificateVerificationError
	var record tls.RecordHeaderError
	var errno syscall.Errno
	var networkError net.Error
	switch {
	case errors.As(err, &dns):
		return "DNS lookup failed"
	case errors.As(err, &cert):
		return fmt.Sprintf("TLS certificate verification failed (%T)", cert.Err)
	case errors.As(err, &record):
		return "invalid TLS record"
	case errors.As(err, &errno):
		return errno.Error()
	case errors.As(err, &networkError) && networkError.Timeout():
		return "network timeout"
	case errors.Is(err, context.Canceled):
		return "request canceled"
	case errors.Is(err, errRedirectRefused):
		return errRedirectRefused.Error()
	default:
		return fmt.Sprintf("upstream failure (%T)", err)
	}
}

func stripCredentials(headers http.Header, credentialHeaders []string) {
	for _, name := range credentialHeaders {
		headers.Del(name)
	}
	headers.Del("Authorization")
	headers.Del("Proxy-Authorization")
	headers.Del("Cookie")
	headers.Del("Set-Cookie")
}

// Trailers are populated as the body reaches EOF. Filtering only the initial
// headers would allow the same fields to be forwarded later as trailers.
type credentialFilteredBody struct {
	io.ReadCloser
	trailer http.Header
	headers []string
}

func (b *credentialFilteredBody) Read(p []byte) (int, error) {
	n, err := b.ReadCloser.Read(p)
	if err != nil {
		stripCredentials(b.trailer, b.headers)
	}
	return n, err
}
