package proxy

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"sync"
	"syscall"
	"time"
)

// The service owns listeners, not their parent directory. A preserved systemd
// RuntimeDirectory can contain a socket left behind by SIGKILL; only a socket
// confirmed to have no listener may be removed during startup.
func listenUnix(path string) (*net.UnixListener, error) {
	info, err := os.Lstat(path)
	if err == nil {
		if info.Mode()&os.ModeSocket == 0 {
			return nil, errors.New("Unix socket path already exists and is not a socket")
		}
		conn, dialErr := net.DialTimeout("unix", path, time.Second)
		if dialErr == nil {
			conn.Close()
			return nil, errors.New("Unix socket already has a listener")
		}
		if !errors.Is(dialErr, syscall.ECONNREFUSED) && !errors.Is(dialErr, os.ErrNotExist) {
			return nil, fmt.Errorf("check stale Unix socket: %w", dialErr)
		}
		current, statErr := os.Lstat(path)
		if statErr == nil {
			if !os.SameFile(info, current) {
				return nil, errors.New("Unix socket changed during startup")
			}
			if err := os.Remove(path); err != nil {
				return nil, fmt.Errorf("remove stale Unix socket: %w", err)
			}
		} else if !errors.Is(statErr, os.ErrNotExist) {
			return nil, fmt.Errorf("inspect Unix socket: %w", statErr)
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, fmt.Errorf("inspect Unix socket: %w", err)
	}
	listener, err := net.ListenUnix("unix", &net.UnixAddr{Name: path, Net: "unix"})
	if err != nil {
		return nil, err
	}
	if err := os.Chmod(path, 0600); err != nil {
		listener.Close()
		return nil, fmt.Errorf("restrict Unix socket permissions: %w", err)
	}
	return listener, nil
}

type endpoint struct {
	network, address string
	handler          http.Handler
}

func serve(ctx context.Context, endpoints []endpoint) error {
	var listeners []net.Listener
	defer func() {
		for _, listener := range listeners {
			listener.Close()
		}
	}()
	for _, endpoint := range endpoints {
		var listener net.Listener
		var err error
		if endpoint.network == "unix" {
			listener, err = listenUnix(endpoint.address)
		} else {
			listener, err = net.Listen("tcp", endpoint.address)
		}
		if err != nil {
			return fmt.Errorf("listen %s %q: %w", endpoint.network, endpoint.address, err)
		}
		listeners = append(listeners, listener)
	}
	servers := make([]*http.Server, len(listeners))
	done := make(chan error, len(listeners))
	for i, listener := range listeners {
		server := &http.Server{
			Handler:           endpoints[i].handler,
			ReadHeaderTimeout: 5 * time.Second,
			IdleTimeout:       60 * time.Second,
			ErrorLog:          log.New(io.Discard, "", 0),
		}
		servers[i] = server
		go func() { done <- server.Serve(listener) }()
	}
	var serveErr error
	completed := 0
	select {
	case <-ctx.Done():
	case err := <-done:
		completed++
		if !errors.Is(err, http.ErrServerClosed) {
			serveErr = fmt.Errorf("serve HTTP: %w", err)
		}
	}
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	var shutdown sync.WaitGroup
	for _, server := range servers {
		shutdown.Go(func() {
			if err := server.Shutdown(shutdownCtx); err != nil {
				server.Close()
			}
		})
	}
	shutdown.Wait()
	for completed < len(servers) {
		<-done
		completed++
	}
	return serveErr
}
