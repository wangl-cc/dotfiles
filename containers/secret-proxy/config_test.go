package main

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeFile(t *testing.T, dir, name, value string) string {
	t.Helper()
	filename := filepath.Join(dir, name)
	if err := os.WriteFile(filename, []byte(value), 0600); err != nil {
		t.Fatal(err)
	}
	return filename
}

func writeConfig(t *testing.T, dir string, cfg config) string {
	t.Helper()
	data, err := json.Marshal(cfg)
	if err != nil {
		t.Fatal(err)
	}
	return writeFile(t, dir, "config.json", string(data))
}

func TestCredentialValidation(t *testing.T) {
	for _, tc := range []struct {
		name, input, want string
		invalid           bool
	}{
		{name: "no newline", input: "a-token", want: "a-token"},
		{name: "LF", input: "a-token\n", want: "a-token"},
		{name: "CRLF", input: "a-token\r\n", want: "a-token"},
		{name: "preserve spaces", input: " token \n", want: " token "},
		{name: "empty", invalid: true},
		{name: "empty line", input: "\n", invalid: true},
		{name: "multiple lines", input: "first\nsecond", invalid: true},
		{name: "two trailing lines", input: "token\n\n", invalid: true},
		{name: "bare CR", input: "token\r", invalid: true},
		{name: "header injection", input: "token\r\nInjected: yes", invalid: true},
		{name: "oversize", input: strings.Repeat("x", (64<<10)+1), invalid: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			file := writeFile(t, t.TempDir(), "credential", tc.input)
			got, err := readCredential(file)
			if tc.invalid {
				if err == nil {
					t.Fatal("accepted invalid credential")
				}
			} else if err != nil || got != tc.want {
				t.Fatalf("got %q, %v; want %q", got, err, tc.want)
			}
		})
	}
}

func TestServiceValidation(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "token", "dummy-secret")
	for _, tc := range []struct {
		name string
		edit func(*serviceConfig)
	}{
		{"HTTP upstream", func(c *serviceConfig) { c.Upstream = "http://example.com" }},
		{"userinfo", func(c *serviceConfig) { c.Upstream = "https://secret@example.com" }},
		{"query", func(c *serviceConfig) { c.Upstream = "https://example.com/?key=secret" }},
		{"empty query", func(c *serviceConfig) { c.Upstream = "https://example.com/?" }},
		{"fragment", func(c *serviceConfig) { c.Upstream = "https://example.com/#secret" }},
		{"missing host", func(c *serviceConfig) { c.Upstream = "https:///path" }},
		{"unknown auth", func(c *serviceConfig) { c.Auth.Type = "oauth" }},
		{"credential traversal", func(c *serviceConfig) { c.Auth.Credential = "../token" }},
		{"credential absolute path", func(c *serviceConfig) { c.Auth.Credential = "/token" }},
		{"missing credential", func(c *serviceConfig) { c.Auth.Credential = "missing" }},
		{"missing username", func(c *serviceConfig) { c.Auth.Username = "" }},
		{"ambiguous username", func(c *serviceConfig) { c.Auth.Username = "git:extra" }},
		{"unexpected basic header", func(c *serviceConfig) { c.Auth.Header = "X-Key" }},
		{"unexpected bearer username", func(c *serviceConfig) { c.Auth.Type = "bearer" }},
		{"invalid header name", func(c *serviceConfig) {
			c.Auth = authConfig{Type: "header", Credential: "token", Header: "X-Key\r\nExtra"}
		}},
		{"transport header", func(c *serviceConfig) { c.Auth = authConfig{Type: "header", Credential: "token", Header: "cOnNeCtIoN"} }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			cfg := serviceConfig{Upstream: "https://example.com", Auth: authConfig{Type: "basic", Username: "git", Credential: "token"}}
			tc.edit(&cfg)
			_, err := compileService(cfg, dir)
			if err == nil {
				t.Fatal("accepted invalid service")
			}
			if strings.Contains(err.Error(), "secret") {
				t.Fatalf("error contains configuration or credential data: %v", err)
			}
		})
	}
}

func TestConfigurationAndCheck(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "token", "dummy-secret")
	cfg := config{Services: map[string]serviceConfig{
		"overleaf": {Upstream: "https://git.overleaf.com", Auth: authConfig{Type: "basic", Username: "git", Credential: "token"}},
	}}
	file := writeConfig(t, dir, cfg)
	listen, services, err := loadConfig(file, dir)
	if err != nil || listen != "127.0.0.1:8787" || len(services) != 1 {
		t.Fatalf("unexpected load result: %q, %d services, %v", listen, len(services), err)
	}
	var output bytes.Buffer
	t.Setenv("CREDENTIALS_DIRECTORY", dir)
	if err := run(context.Background(), []string{"-config", file, "-check"}, &output); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(output.String(), "valid (1 services)") || strings.Contains(output.String(), "dummy-secret") {
		t.Fatalf("unexpected check output: %s", output.String())
	}

	for _, listen := range []string{"0.0.0.0:8787", ":8787", "localhost:8787", "127.0.0.1:http", "127.0.0.1:0", "127.0.0.1:99999"} {
		cfg.Listen = listen
		if _, _, err := loadConfig(writeConfig(t, dir, cfg), dir); err == nil {
			t.Errorf("accepted invalid listener %q", listen)
		}
	}
	for _, text := range []string{
		`{"services": {}, "misspelling": true}`,
		`{"services": {}}`,
		`null`,
		`{} {}`,
		`{"services":{"a":{"upstream":"https://example.com","auth":{"type":"bearer","credential":"token","secret":"do-not-log-me"}}}}`,
	} {
		_, _, err := loadConfig(writeFile(t, dir, "config.json", text), dir)
		if err == nil {
			t.Errorf("accepted invalid JSON configuration: %s", text)
		} else if strings.Contains(err.Error(), "do-not-log-me") {
			t.Error("configuration error leaked an unknown field's value")
		}
	}
}
