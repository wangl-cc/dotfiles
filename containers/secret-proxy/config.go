package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type config struct {
	Listen   string                   `json:"listen"`
	Services map[string]serviceConfig `json:"services"`
}

type serviceConfig struct {
	Upstream string     `json:"upstream"`
	Auth     authConfig `json:"auth"`
}

type authConfig struct {
	Type       string `json:"type"`
	Credential string `json:"credential"`
	Username   string `json:"username,omitempty"`
	Header     string `json:"header,omitempty"`
}

// A service contains validated routing and one precomputed credential header.
// Neither it nor the raw configuration is logged.
type service struct {
	upstream    *url.URL
	headerName  string
	headerValue string
}

func loadConfig(filename, credentialsDir string) (string, map[string]service, error) {
	f, err := os.Open(filename)
	if err != nil {
		return "", nil, errors.New("cannot open configuration file")
	}
	defer f.Close()

	const maxConfigSize = 1 << 20
	data, err := io.ReadAll(io.LimitReader(f, maxConfigSize+1))
	if err != nil || len(data) > maxConfigSize {
		return "", nil, errors.New("cannot read configuration or configuration exceeds 1 MiB")
	}
	var cfg config
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&cfg); err != nil {
		return "", nil, errors.New("invalid configuration JSON or unknown field")
	}
	if err := dec.Decode(new(any)); err != io.EOF {
		return "", nil, errors.New("configuration must contain one JSON object")
	}
	if cfg.Listen == "" {
		cfg.Listen = "127.0.0.1:8787"
	}
	host, port, err := net.SplitHostPort(cfg.Listen)
	portNumber, portErr := strconv.Atoi(port)
	if err != nil || !net.ParseIP(host).IsLoopback() || portErr != nil || portNumber < 1 || portNumber > 65535 {
		return "", nil, errors.New("listen must be a numeric loopback address and port")
	}
	if len(cfg.Services) == 0 {
		return "", nil, errors.New("at least one service is required")
	}
	if credentialsDir == "" {
		return "", nil, errors.New("set -credentials-dir or CREDENTIALS_DIRECTORY")
	}

	services := make(map[string]service, len(cfg.Services))
	for name, entry := range cfg.Services {
		if !validName(name) {
			return "", nil, errors.New("invalid service name")
		}
		s, err := compileService(entry, credentialsDir)
		if err != nil {
			return "", nil, fmt.Errorf("service %q: %w", name, err)
		}
		services[name] = s
	}
	return cfg.Listen, services, nil
}

func compileService(cfg serviceConfig, credentialsDir string) (service, error) {
	u, err := url.Parse(cfg.Upstream)
	if err != nil || u.Scheme != "https" || u.Hostname() == "" || u.User != nil || u.RawQuery != "" || u.ForceQuery || u.Fragment != "" || u.Opaque != "" {
		return service{}, errors.New("upstream must be an HTTPS URL without userinfo, query, or fragment")
	}
	a := cfg.Auth
	if !validName(a.Credential) {
		return service{}, errors.New("credential must be a filename without directory components")
	}
	s := service{upstream: u, headerName: "Authorization"}
	switch a.Type {
	case "basic":
		if a.Username == "" || strings.Contains(a.Username, ":") || !validHeaderValue(a.Username) || a.Header != "" {
			return service{}, errors.New("basic auth requires a username without colons or control characters, and no header field")
		}
	case "bearer":
		if a.Username != "" || a.Header != "" {
			return service{}, errors.New("bearer auth does not accept username or header fields")
		}
	case "header":
		if a.Username != "" || !validHeaderName(a.Header) || reservedHeader(a.Header) {
			return service{}, errors.New("header auth requires an authentication header name and no username")
		}
		s.headerName = http.CanonicalHeaderKey(a.Header)
	default:
		return service{}, errors.New("auth type must be basic, bearer, or header")
	}

	secret, err := readCredential(filepath.Join(credentialsDir, a.Credential))
	if err != nil {
		return service{}, err
	}
	switch a.Type {
	case "basic":
		s.headerValue = "Basic " + base64.StdEncoding.EncodeToString([]byte(a.Username+":"+secret))
	case "bearer":
		s.headerValue = "Bearer " + secret
	case "header":
		s.headerValue = secret
	}
	return s, nil
}

func readCredential(filename string) (string, error) {
	f, err := os.Open(filename)
	if err != nil {
		return "", errors.New("cannot open credential file")
	}
	defer f.Close()
	const maxSize = 64 << 10
	data, err := io.ReadAll(io.LimitReader(f, maxSize+1))
	if err != nil || len(data) > maxSize {
		return "", errors.New("cannot read credential or credential exceeds 64 KiB")
	}
	// Accept the final line ending from an editor or password prompt, without
	// silently changing leading/trailing spaces in the actual credential.
	secret := string(data)
	if strings.HasSuffix(secret, "\n") {
		secret = strings.TrimSuffix(strings.TrimSuffix(secret, "\n"), "\r")
	}
	if secret == "" || !validHeaderValue(secret) {
		return "", errors.New("credential is empty or contains control characters")
	}
	return secret, nil
}

func validName(s string) bool {
	if s == "" || s == "." || s == ".." {
		return false
	}
	for _, c := range s {
		if !(c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-' || c == '_' || c == '.') {
			return false
		}
	}
	return true
}

func validHeaderName(s string) bool {
	if s == "" {
		return false
	}
	for _, c := range s {
		if !(c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || strings.ContainsRune("!#$%&'*+-.^_`|~", c)) {
			return false
		}
	}
	return true
}

func validHeaderValue(s string) bool {
	for i := 0; i < len(s); i++ {
		if s[i] < 0x20 || s[i] == 0x7f {
			return false
		}
	}
	return true
}

func reservedHeader(s string) bool {
	switch http.CanonicalHeaderKey(s) {
	case "Host", "Connection", "Content-Length", "Transfer-Encoding", "Te", "Trailer", "Upgrade", "Keep-Alive", "Proxy-Authenticate", "Proxy-Authorization", "Accept-Encoding", "Forwarded", "X-Forwarded-For", "X-Forwarded-Host", "X-Forwarded-Proto", "Cookie", "Set-Cookie":
		return true
	}
	return false
}
