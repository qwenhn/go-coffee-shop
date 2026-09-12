package main

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"syscall"

	"go.uber.org/automaxprocs/maxprocs"
	"google.golang.org/grpc"

	"github.com/qwenhn/go-coffee-shop/cmd/product/config"
	"github.com/qwenhn/go-coffee-shop/internal/product/app"
	"github.com/qwenhn/go-coffee-shop/pkg/logger"
)

func main() {
	_, err := maxprocs.Set()
	if err != nil {
		slog.Error("failed to set GOMAXPROCS", "error", err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	cfg, err := config.NewConfig()
	if err != nil {
		slog.Error("failed to get config", "error", err)
		os.Exit(1)
	}

	slog.SetDefault(logger.NewLogger(cfg.Level))

	slog.Info("⚡️ init app", "name", cfg.Name, "version", cfg.Version)

	server := grpc.NewServer()

	go func() {
		defer server.GracefulStop()

		<-ctx.Done()
	}()

	_, err = app.InitApp(cfg, server)
	if err != nil {
		slog.Error("failed to init app", "error", err)
		cancel()
	}

	// gRPC Server.
	address := fmt.Sprintf("%s:%d", cfg.Host, cfg.Port)
	network := "tcp"

	var lc net.ListenConfig

	l, err := lc.Listen(ctx, network, address)
	if err != nil {
		slog.Error("failed to listen to address", "error", err, "network", network, "address", address)
		cancel()
	}

	slog.Info("🌏 start server...", "address", address)

	defer func() {
		if err = l.Close(); err != nil {
			slog.Error("failed to close", "error", err, "network", network, "address", address)
		}
	}()

	err = server.Serve(l)
	if err != nil {
		slog.Error("failed start gRPC server", "error", err, "network", network, "address", address)
		cancel()
	}

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	select {
	case v := <-quit:
		slog.Info("signal.Notify", "val", v)
	case done := <-ctx.Done():
		slog.Info("ctx.Done", "done", done)
	}
}
