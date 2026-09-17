package main

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"syscall"

	_ "github.com/lib/pq"
	"go.uber.org/automaxprocs/maxprocs"
	"google.golang.org/grpc"

	"github.com/qwenhn/go-coffee-shop/cmd/counter/config"
	"github.com/qwenhn/go-coffee-shop/internal/counter/app"
	"github.com/qwenhn/go-coffee-shop/pkg/logger"
	"github.com/qwenhn/go-coffee-shop/pkg/postgres"
	"github.com/qwenhn/go-coffee-shop/pkg/rabbitmq"
	pkgConsumer "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/consumer"
	pkgPublisher "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
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

	cleanup := prepareApp(ctx, cancel, cfg, server)

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
			<-ctx.Done()
		}
	}()

	err = server.Serve(l)
	if err != nil {
		slog.Error("failed start gRPC server", "error", err, "network", network, "address", address)
		cancel()
		<-ctx.Done()
	}

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	select {
	case v := <-quit:
		cleanup()
		slog.Info("signal.Notify", "value", v)
	case done := <-ctx.Done():
		cleanup()
		slog.Info("ctx.Done", "app done", done)
	}
}

func prepareApp(ctx context.Context, cancel context.CancelFunc, cfg *config.Config, server *grpc.Server) func() {
	a, cleanup, err := app.InitApp(cfg, postgres.DBConnString(cfg.DsnURL), rabbitmq.RabbitMQConnStr(cfg.RabbitMQ.URL), server)
	if err != nil {
		slog.Error("failed init app", "error", err)
		cancel()
		<-ctx.Done()
	}

	a.BaristaOrderPub.Configure(
		pkgPublisher.ExchangeName("barista-order-exchange"),
		pkgPublisher.BindingKey("barista-order-routing-key"),
		pkgPublisher.MessageTypeName("barista-order-created"),
	)

	a.KitchenOrderPub.Configure(
		pkgPublisher.ExchangeName("kitchen-order-exchange"),
		pkgPublisher.BindingKey("kitchen-order-routing-key"),
		pkgPublisher.MessageTypeName("kitchen-order-created"),
	)

	a.Consumer.Configure(
		pkgConsumer.ExchangeName("counter-order-exchange"),
		pkgConsumer.QueueName("counter-order-queue"),
		pkgConsumer.BindingKey("counter-order-routing-key"),
		pkgConsumer.ConsumerTag("counter-order-consumer"),
	)

	go func() {
		err := a.Consumer.StartConsumer(a.Worker)
		if err != nil {
			slog.Error("failed to start Consumer", "error", err)
			cancel()
			<-ctx.Done()
		}
	}()

	return cleanup
}
