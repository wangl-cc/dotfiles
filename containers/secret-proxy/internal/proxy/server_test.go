package proxy

import (
	"context"
	"errors"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestUnixSocketOwnership(t *testing.T) {
	t.Run("regular file", func(t *testing.T) {
		path := writeFile(t, t.TempDir(), "proxy.sock", "do not remove")
		if listener, err := listenUnix(path); err == nil {
			listener.Close()
			t.Fatal("replaced regular file")
		}
		data, err := os.ReadFile(path)
		if err != nil || string(data) != "do not remove" {
			t.Fatal("existing file changed")
		}
	})
	t.Run("symlink", func(t *testing.T) {
		dir := t.TempDir()
		target := writeFile(t, dir, "target", "do not remove")
		path := filepath.Join(dir, "proxy.sock")
		if err := os.Symlink(target, path); err != nil {
			t.Fatal(err)
		}
		if listener, err := listenUnix(path); err == nil {
			listener.Close()
			t.Fatal("replaced symlink")
		}
		if got, err := os.Readlink(path); err != nil || got != target {
			t.Fatal("existing symlink changed")
		}
	})
	t.Run("active socket", func(t *testing.T) {
		path := filepath.Join(t.TempDir(), "proxy.sock")
		active, err := listenUnix(path)
		if err != nil {
			t.Fatal(err)
		}
		defer active.Close()
		before, _ := os.Lstat(path)
		if listener, err := listenUnix(path); err == nil {
			listener.Close()
			t.Fatal("replaced active socket")
		}
		after, err := os.Lstat(path)
		if err != nil || !os.SameFile(before, after) {
			t.Fatal("active socket changed")
		}
		conn, err := net.Dial("unix", path)
		if err != nil {
			t.Fatal("active socket no longer reachable")
		}
		conn.Close()
	})
	t.Run("stale socket", func(t *testing.T) {
		path := filepath.Join(t.TempDir(), "proxy.sock")
		stale, err := net.ListenUnix("unix", &net.UnixAddr{Name: path, Net: "unix"})
		if err != nil {
			t.Fatal(err)
		}
		stale.SetUnlinkOnClose(false)
		stale.Close()
		listener, err := listenUnix(path)
		if err != nil {
			t.Fatal(err)
		}
		info, err := os.Stat(path)
		if err != nil || info.Mode().Perm() != 0600 {
			t.Fatal("socket permissions are not 0600")
		}
		listener.Close()
		if _, err := os.Lstat(path); !errors.Is(err, os.ErrNotExist) {
			t.Fatal("clean close left socket")
		}
	})
}

func TestUnixListenerIntegrationAndShutdown(t *testing.T) {
	socket := filepath.Join(t.TempDir(), "proxy.sock")
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.WriteString(w, "fixture result")
	})
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	done := make(chan error, 1)
	go func() {
		done <- serve(ctx, []endpoint{{network: "tcp", address: ":0", handler: http.NotFoundHandler()}, {network: "unix", address: socket, handler: handler}})
	}()
	deadline := time.Now().Add(2 * time.Second)
	for {
		if _, err := os.Stat(socket); err == nil {
			break
		}
		select {
		case err := <-done:
			t.Fatalf("serve stopped: %v", err)
		default:
		}
		if time.Now().After(deadline) {
			t.Fatal("socket not created")
		}
		time.Sleep(time.Millisecond)
	}
	clientTransport := &http.Transport{DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
		return (&net.Dialer{}).DialContext(ctx, "unix", socket)
	}}
	defer clientTransport.CloseIdleConnections()
	client := &http.Client{Transport: clientTransport, Timeout: time.Second}
	response, err := client.Get("http://proxy.internal/status")
	if err != nil {
		t.Fatal(err)
	}
	body, err := io.ReadAll(response.Body)
	response.Body.Close()
	if err != nil || response.StatusCode != 200 || string(body) != "fixture result" {
		t.Fatal("Unix HTTP response changed")
	}
	cancel()
	select {
	case err := <-done:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("shutdown did not finish")
	}
	if _, err := os.Lstat(socket); !errors.Is(err, os.ErrNotExist) {
		t.Fatal("shutdown left socket")
	}
}

func TestStartupFailureClosesUnixListener(t *testing.T) {
	occupied, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer occupied.Close()
	socket := filepath.Join(t.TempDir(), "proxy.sock")

	err = serve(context.Background(), []endpoint{{network: "unix", address: socket, handler: http.NotFoundHandler()}, {network: "tcp", address: occupied.Addr().String(), handler: http.NotFoundHandler()}})
	var opErr *net.OpError
	if !errors.As(err, &opErr) || !strings.Contains(err.Error(), occupied.Addr().String()) {
		t.Fatalf("occupied address lost its cause or address: %v", err)
	}
	if _, err := os.Lstat(socket); !errors.Is(err, os.ErrNotExist) {
		t.Fatal("failed startup leaked Unix socket")
	}
	listener, err := listenUnix(socket)
	if err != nil {
		t.Fatalf("failed startup retained listener: %v", err)
	}
	listener.Close()
}

func TestEndpointTransports(t *testing.T) {
	upstreams := map[string]credential{"api.example.com": {}}
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		return &http.Response{StatusCode: 200, Header: make(http.Header), Body: io.NopCloser(strings.NewReader(r.URL.String())), Request: r}, nil
	})
	for _, a := range []adapter{pathAdapter, hostAdapter} {
		t.Run(string(a), func(t *testing.T) {
			address := "localhost:0"
			if a == hostAdapter {
				address = filepath.Join(t.TempDir(), "proxy.sock")
			}
			listener, err := net.Listen(a.network(), address)
			if err != nil {
				t.Fatal(err)
			}
			server := &http.Server{Handler: a.handler(upstreams, transport, log.New(io.Discard, "", 0))}
			done := make(chan struct{})
			go func() { server.Serve(listener); close(done) }()
			defer func() { server.Close(); <-done }()
			clientTransport := &http.Transport{DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
				return (&net.Dialer{}).DialContext(ctx, a.network(), listener.Addr().String())
			}}
			defer clientTransport.CloseIdleConnections()
			client := &http.Client{Transport: clientTransport, Timeout: time.Second}
			url := "http://api.example.com/status"
			if a == pathAdapter {
				url = "http://proxy.internal:8787/api.example.com/status"
			}
			response, err := client.Get(url)
			if err != nil {
				t.Fatal(err)
			}
			defer response.Body.Close()
			body, err := io.ReadAll(response.Body)
			if err != nil || response.StatusCode != 200 || string(body) != "https://api.example.com/status" {
				t.Fatalf("%s endpoint: %d %q, %v", a, response.StatusCode, body, err)
			}
		})
	}
}
