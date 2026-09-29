package proxy

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
)

type config struct {
	Endpoints []endpointConfig          `json:"endpoints"`
	Upstreams map[string]upstreamConfig `json:"upstreams"`
}

// An endpoint owns both listening and interpreting its client's requests.
// HTTP clients carry the destination in the path; gh supplies the HTTP Host.
type endpointConfig struct {
	Adapter adapter `json:"adapter"`
	Address string  `json:"address"`
}

type upstreamConfig struct {
	Auth *authConfig `json:"auth,omitempty"`
}

type configuration struct {
	endpoints []endpointConfig
	upstreams map[string]credential
}

func loadConfig(filename, credentialsDir string) (configuration, error) {
	f, err := os.Open(filename)
	if err != nil {
		return configuration{}, fmt.Errorf("open configuration: %w", err)
	}
	defer f.Close()
	const maxConfigSize = 1 << 20
	data, err := io.ReadAll(io.LimitReader(f, maxConfigSize+1))
	if err != nil {
		return configuration{}, fmt.Errorf("read configuration: %w", err)
	}
	if len(data) > maxConfigSize {
		return configuration{}, errors.New("configuration exceeds 1 MiB")
	}
	var cfg config
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&cfg); err != nil {
		return configuration{}, fmt.Errorf("decode configuration %q: %w", filename, err)
	}
	if err := dec.Decode(new(any)); err != io.EOF {
		return configuration{}, errors.New("configuration must contain one JSON object")
	}
	if len(cfg.Endpoints) == 0 {
		return configuration{}, errors.New("at least one endpoint is required")
	}
	for i, entry := range cfg.Endpoints {
		if entry.Adapter.network() == "" || entry.Address == "" {
			return configuration{}, fmt.Errorf("endpoint %d requires adapter http or gh and an address", i+1)
		}
	}
	result := configuration{endpoints: cfg.Endpoints, upstreams: make(map[string]credential)}
	for host, entry := range cfg.Upstreams {
		host, ok := matchHost(host)
		if !ok {
			return configuration{}, errors.New("upstream key must be a hostname with no port or port 443")
		}
		if _, exists := result.upstreams[host]; exists {
			return configuration{}, errors.New("duplicate equivalent upstream hosts")
		}
		u, err := compileAuth(entry.Auth, credentialsDir)
		if err != nil {
			return configuration{}, fmt.Errorf("upstream %s: %w", host, err)
		}
		result.upstreams[host] = u
	}
	return result, nil
}
