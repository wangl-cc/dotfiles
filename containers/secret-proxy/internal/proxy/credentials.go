package proxy

import (
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

type authConfig struct {
	Type       string `json:"type"`
	Credential string `json:"credential"`
	Username   string `json:"username,omitempty"`
	Header     string `json:"header,omitempty"`
}

type credential struct{ headerName, headerValue string }

func compileAuth(cfg *authConfig, credentialsDir string) (credential, error) {
	s := credential{}
	a := cfg
	if a == nil {
		return s, nil
	}
	if credentialsDir == "" {
		return credential{}, errors.New("set -credentials-dir or CREDENTIALS_DIRECTORY")
	}
	if !validName(a.Credential) {
		return credential{}, errors.New("credential must be a filename without directory components")
	}
	s.headerName = "Authorization"
	switch a.Type {
	case "basic":
		if a.Username == "" || strings.Contains(a.Username, ":") || !validHeaderValue(a.Username) || a.Header != "" {
			return credential{}, errors.New("basic auth requires a username without colons or control characters, and no header field")
		}
	case "bearer":
		if a.Username != "" || a.Header != "" {
			return credential{}, errors.New("bearer auth does not accept username or header fields")
		}
	case "header":
		if a.Username != "" || !validHeaderName(a.Header) || reservedHeader(a.Header) {
			return credential{}, errors.New("header auth requires an authentication header name and no username")
		}
		s.headerName = http.CanonicalHeaderKey(a.Header)
	default:
		return credential{}, errors.New("auth type must be basic, bearer, or header")
	}

	secret, err := readCredential(filepath.Join(credentialsDir, a.Credential))
	if err != nil {
		return credential{}, err
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
		return "", fmt.Errorf("open credential: %w", err)
	}
	defer f.Close()
	const maxSize = 64 << 10
	data, err := io.ReadAll(io.LimitReader(f, maxSize+1))
	if err != nil {
		return "", fmt.Errorf("read credential: %w", err)
	}
	if len(data) > maxSize {
		return "", fmt.Errorf("credential %q exceeds 64 KiB", filename)
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
