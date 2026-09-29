package proxy

import (
	"context"
	"errors"
	"flag"
	"io"
	"log"
	"os"
)

// Run validates configuration and owns every configured listener until shutdown.
func Run(ctx context.Context, args []string, output io.Writer) error {
	flags := flag.NewFlagSet("secret-proxy", flag.ContinueOnError)
	flags.SetOutput(output)
	configFile := flags.String("config", "/etc/secret-proxy/config.json", "JSON configuration file")
	credentialsDir := flags.String("credentials-dir", os.Getenv("CREDENTIALS_DIRECTORY"), "directory containing credential files")
	check := flags.Bool("check", false, "validate configuration and credentials, then exit")
	if err := flags.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	if flags.NArg() != 0 {
		return errors.New("unexpected arguments")
	}
	cfg, err := loadConfig(*configFile, *credentialsDir)
	if err != nil {
		return err
	}
	logger := log.New(output, "secret-proxy: ", log.LstdFlags)
	if *check {
		logger.Printf("configuration and credentials valid (%d endpoints, %d upstreams)", len(cfg.endpoints), len(cfg.upstreams))
		return nil
	}
	transport := newTransport()
	defer transport.CloseIdleConnections()
	endpoints := make([]endpoint, len(cfg.endpoints))
	for i, entry := range cfg.endpoints {
		endpoints[i] = endpoint{network: entry.Adapter.network(), address: entry.Address, handler: entry.Adapter.handler(cfg.upstreams, transport, logger)}
	}
	return serve(ctx, endpoints)
}
