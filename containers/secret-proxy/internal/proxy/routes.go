package proxy

import (
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
)

// Both adapters use the same credential table. Unmatched hosts receive no
// credential; client headers never choose auth.
func newHandler(upstreams map[string]credential, transport http.RoundTripper, logger *log.Logger, location func(*url.URL) string) http.Handler {
	var headers []string
	for _, u := range upstreams {
		if u.headerName != "" {
			headers = append(headers, u.headerName)
		}
	}
	return newReverseProxy(transport, logger, headers, func(pr *httputil.ProxyRequest) {
		// Copy the adapted URL, including the raw query that ReverseProxy may
		// otherwise clean (for example, query parameters containing semicolons).
		target := *pr.In.URL
		pr.Out.URL = &target
		pr.Out.Host = target.Host
		u := upstreams[target.Host]
		if u.headerName != "" {
			pr.Out.Header.Set(u.headerName, u.headerValue)
		}
	}, func(resp *http.Response) bool { return rewriteRedirect(resp, location) })
}

func rewriteRedirect(resp *http.Response, encodeLocation func(*url.URL) string) bool {
	if resp.StatusCode == http.StatusSwitchingProtocols {
		return false
	}
	locations := resp.Header.Values("Location")
	if resp.StatusCode < 300 || resp.StatusCode >= 400 || len(locations) == 0 {
		return true
	}
	if len(locations) != 1 || resp.Request == nil {
		return false
	}
	location, err := url.Parse(locations[0])
	if err != nil {
		return false
	}
	target := resp.Request.URL.ResolveReference(location)
	if target.Scheme != "https" || target.User != nil || target.Opaque != "" {
		return false
	}
	var ok bool
	target.Host, ok = matchHost(target.Host)
	if !ok {
		return false
	}
	if target.Path == "" {
		target.Path = "/"
	}
	resp.Header.Set("Location", encodeLocation(target))
	return true
}
