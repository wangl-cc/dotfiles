package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := run(ctx, os.Args[1:], os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "secret-proxy:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string, output io.Writer) error {
	flags := flag.NewFlagSet("secret-proxy", flag.ContinueOnError)
	flags.SetOutput(output)
	configFile := flags.String("config", "/etc/secret-proxy/config.json", "JSON configuration file")
	credentialsDir := flags.String("credentials-dir", os.Getenv("CREDENTIALS_DIRECTORY"), "directory containing credential files")
	timeout := flags.Duration("request-timeout", 10*time.Minute, "maximum duration of each request, including streaming")
	check := flags.Bool("check", false, "validate configuration and credentials, then exit")
	if err := flags.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	if flags.NArg() != 0 || *timeout <= 0 {
		return errors.New("unexpected arguments or nonpositive request timeout")
	}
	listen, services, err := loadConfig(*configFile, *credentialsDir)
	if err != nil {
		return err
	}
	logger := log.New(output, "secret-proxy: ", log.LstdFlags)
	if *check {
		logger.Printf("configuration and credentials valid (%d services)", len(services))
		return nil
	}
	transport := newTransport()
	defer transport.CloseIdleConnections()
	server := &http.Server{
		Addr:              listen,
		Handler:           newHandler(services, transport, *timeout, logger),
		ReadHeaderTimeout: 5 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    1 << 20,
		ErrorLog:          log.New(io.Discard, "", 0),
	}
	done := make(chan error, 1)
	go func() { done <- server.ListenAndServe() }()
	select {
	case err := <-done:
		if !errors.Is(err, http.ErrServerClosed) {
			return errors.New("HTTP listener failed")
		}
		return nil
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			_ = server.Close()
		}
		<-done
		return nil
	}
}
