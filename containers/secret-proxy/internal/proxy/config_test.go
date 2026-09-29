package proxy

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
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

func TestUpstreamValidation(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "token", "dummy-secret")
	for _, tc := range []struct {
		name string
		edit func(*upstreamConfig)
	}{
		{"unknown auth", func(c *upstreamConfig) { c.Auth.Type = "oauth" }},
		{"credential traversal", func(c *upstreamConfig) { c.Auth.Credential = "../token" }},
		{"credential absolute path", func(c *upstreamConfig) { c.Auth.Credential = "/token" }},
		{"missing credential", func(c *upstreamConfig) { c.Auth.Credential = "missing" }},
		{"missing username", func(c *upstreamConfig) { c.Auth.Username = "" }},
		{"ambiguous username", func(c *upstreamConfig) { c.Auth.Username = "git:extra" }},
		{"unexpected basic header", func(c *upstreamConfig) { c.Auth.Header = "X-Key" }},
		{"unexpected bearer username", func(c *upstreamConfig) { c.Auth.Type = "bearer" }},
		{"invalid header name", func(c *upstreamConfig) {
			c.Auth = &authConfig{Type: "header", Credential: "token", Header: "X-Key\r\nExtra"}
		}},
		{"transport header", func(c *upstreamConfig) {
			c.Auth = &authConfig{Type: "header", Credential: "token", Header: "cOnNeCtIoN"}
		}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			cfg := upstreamConfig{Auth: &authConfig{Type: "basic", Username: "git", Credential: "token"}}
			tc.edit(&cfg)
			_, err := compileAuth(cfg.Auth, dir)
			if err == nil {
				t.Fatal("accepted invalid upstream")
			}
			if strings.Contains(err.Error(), "secret") {
				t.Fatalf("error leaked data: %v", err)
			}
		})
	}
}

func TestConfigurationAndCheck(t *testing.T) {
	dir := t.TempDir()
	if _, err := loadConfig(filepath.Join(dir, "missing.json"), dir); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("missing configuration lost its cause: %v", err)
	}
	writeFile(t, dir, "token", "dummy-secret")
	cfg := config{
		Endpoints: []endpointConfig{{Adapter: pathAdapter, Address: "127.0.0.1:8787"}, {Adapter: hostAdapter, Address: filepath.Join(dir, "proxy.sock")}},
		Upstreams: map[string]upstreamConfig{
			"git.overleaf.com": {Auth: &authConfig{Type: "basic", Username: "git", Credential: "token"}},
			"api.example.com":  {Auth: &authConfig{Type: "bearer", Credential: "token"}},
		},
	}
	file := writeConfig(t, dir, cfg)
	loaded, err := loadConfig(file, dir)
	if err != nil || len(loaded.endpoints) != 2 || len(loaded.upstreams) != 2 {
		t.Fatalf("load: %v", err)
	}
	var output bytes.Buffer
	t.Setenv("CREDENTIALS_DIRECTORY", dir)
	if err := Run(context.Background(), []string{"-config", file, "-check"}, &output); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(output.String(), "valid (2 endpoints, 2 upstreams)") || strings.Contains(output.String(), "dummy-secret") {
		t.Fatal("invalid check output")
	}
	if _, err := os.Lstat(cfg.Endpoints[1].Address); !os.IsNotExist(err) {
		t.Fatal("check created socket")
	}
	for _, address := range []string{":8787", "localhost:8787", "127.0.0.1:0", "[::1]:8787"} {
		cfg.Endpoints[0].Address = address
		if _, err := loadConfig(writeConfig(t, dir, cfg), dir); err != nil {
			t.Errorf("address %q: %v", address, err)
		}
	}
	for _, text := range []string{
		`{"services":{}}`, `{"listeners":[]}`, `null`, `{} {}`,
		`{"endpoints":[{"adapter":"unknown","address":"127.0.0.1:1"}],"upstreams":{"api.example.com":{}}}`,
		`{"endpoints":[{"adapter":"http"}]}`,
		`{"endpoints":[{"adapter":"http","address":"127.0.0.1:1"}],"upstreams":{"api.example.com":{"secret":"do-not-log-me"}}}`,
	} {
		_, err := loadConfig(writeFile(t, dir, "config.json", text), dir)
		if err == nil {
			t.Errorf("accepted invalid config %s", text)
		} else if strings.Contains(err.Error(), "do-not-log-me") {
			t.Fatal("error leaked data")
		} else if strings.Contains(text, "do-not-log-me") && !strings.Contains(err.Error(), `unknown field "secret"`) {
			t.Fatalf("unknown field was not identified: %v", err)
		}
	}
}

func TestUpstreamHosts(t *testing.T) {
	dir := t.TempDir()
	cfg := config{Endpoints: []endpointConfig{{Adapter: pathAdapter, Address: "127.0.0.1:8787"}}}
	if loaded, err := loadConfig(writeConfig(t, dir, cfg), ""); err != nil || len(loaded.upstreams) != 0 {
		t.Fatalf("configuration without credentials: %v", err)
	}
	for _, host := range []string{"", "example.com:80", "example.com:", "secret@example.com", "example.com/path", "%65xample.com", ".", "..", "example.com.", "https://example.com", "example.com?x", "example.com#x", "-bad.example"} {
		cfg.Upstreams = map[string]upstreamConfig{host: {}}
		if _, err := loadConfig(writeConfig(t, dir, cfg), ""); err == nil {
			t.Errorf("accepted invalid host %q", host)
		}
	}
	cfg.Upstreams = map[string]upstreamConfig{"API.example.com": {}, "api.example.com:443": {}}
	if _, err := loadConfig(writeConfig(t, dir, cfg), ""); err == nil {
		t.Fatal("accepted equivalent hosts")
	}
	delete(cfg.Upstreams, "api.example.com:443")
	if loaded, err := loadConfig(writeConfig(t, dir, cfg), ""); err != nil {
		t.Fatal(err)
	} else if _, ok := loaded.upstreams["api.example.com"]; !ok {
		t.Fatal("host was not normalized")
	}
}
