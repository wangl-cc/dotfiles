package proxy

import (
	"log"
	"net"
	"net/http"
	"net/url"
	"strings"
)

type adapter string

const (
	pathAdapter adapter = "http"
	hostAdapter adapter = "gh"
)

func (a adapter) network() string {
	switch a {
	case pathAdapter:
		return "tcp"
	case hostAdapter:
		return "unix"
	default:
		return ""
	}
}

// Canonical authorities have an implicit HTTPS port. Reject URL syntax and
// encoded hosts so path parsing cannot disagree with host routing or redirects.
func matchHost(authority string) (string, bool) {
	if strings.ContainsAny(authority, "%/\\?#@") || strings.HasSuffix(authority, ":") {
		return "", false
	}
	u, err := url.Parse("https://" + authority)
	if err != nil || u.Host != authority || u.Hostname() == "" {
		return "", false
	}
	if port := u.Port(); port != "" && port != "443" {
		return "", false
	}
	host := strings.ToLower(u.Hostname())
	if strings.Contains(host, ":") {
		if net.ParseIP(host) == nil {
			return "", false
		}
		return "[" + host + "]", true
	}
	for _, label := range strings.Split(host, ".") {
		if label == "" || strings.HasPrefix(label, "-") || strings.HasSuffix(label, "-") {
			return "", false
		}
		for _, c := range label {
			if !(c >= 'a' && c <= 'z' || c >= '0' && c <= '9' || c == '-') {
				return "", false
			}
		}
	}
	return host, true
}

// Decode the wire request into one HTTPS destination before the shared handler
// selects credentials. Preserve the original body/trailers and escaped path.
func (a adapter) handler(upstreams map[string]credential, transport http.RoundTripper, logger *log.Logger) http.Handler {
	next := newHandler(upstreams, transport, logger, a.location)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodConnect || r.URL.IsAbs() || r.URL.Host != "" || r.URL.User != nil || r.URL.Opaque != "" || r.Header.Get("Upgrade") != "" || !strings.HasPrefix(r.URL.Path, "/") {
			http.Error(w, "only ordinary HTTP requests are supported", http.StatusBadRequest)
			return
		}
		target := *r.URL
		host := r.Host
		if a == pathAdapter {
			var rest string
			host, rest, _ = strings.Cut(strings.TrimPrefix(r.URL.EscapedPath(), "/"), "/")
			target.RawPath = "/" + rest
			var err error
			target.Path, err = url.PathUnescape(target.RawPath)
			if err != nil {
				http.Error(w, "invalid destination path", http.StatusBadRequest)
				return
			}
		}
		var ok bool
		target.Host, ok = matchHost(host)
		if !ok {
			http.Error(w, "destination refused", http.StatusForbidden)
			return
		}
		target.Scheme = "https"
		adapted := r.WithContext(r.Context())
		adapted.URL = &target
		adapted.Host = target.Host
		next.ServeHTTP(w, adapted)
	})
}

// Redirects must re-enter through the same adapter. In particular, an absolute
// upstream Location must not send path-mode clients directly to the Internet.
func (a adapter) location(target *url.URL) string {
	if a == pathAdapter {
		location := "/" + target.Host + target.RequestURI()
		if target.Fragment != "" {
			location += "#" + target.EscapedFragment()
		}
		return location
	}
	return target.String()
}
