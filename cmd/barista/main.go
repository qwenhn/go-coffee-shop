package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	_ "github.com/lib/pq"
	"go.uber.org/automaxprocs/maxprocs"

	"github.com/qwenhn/go-coffee-shop/cmd/barista/config"
	"github.com/qwenhn/go-coffee-shop/internal/barista/app"
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

	a, cleanup, err := app.InitApp(cfg, postgres.DBConnString(cfg.DsnURL), rabbitmq.RabbitMQConnStr(cfg.URL))
	if err != nil {
		slog.Error("failed init app", "error", err)
		cancel()
	}

	a.CounterOrderPub.Configure(
		pkgPublisher.ExchangeName("counter-order-exchange"),
		pkgPublisher.BindingKey("counter-order-routing-key"),
		pkgPublisher.MessageTypeName("barista-order-updated"),
	)

	a.Consumer.Configure(
		pkgConsumer.ExchangeName("barista-order-exchange"),
		pkgConsumer.QueueName("barista-order-queue"),
		pkgConsumer.BindingKey("barista-order-routing-key"),
		pkgConsumer.ConsumerTag("barista-order-consumer"),
	)

	slog.Info("🌏 start server...", "address", fmt.Sprintf("%s:%d", cfg.Host, cfg.Port))

	go func() {
		err := a.Consumer.StartConsumer(a.Worker)
		if err != nil {
			slog.Error("failed to start Consumer", "error", err)
			cancel()
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	select {
	case v := <-quit:
		cleanup()
		slog.Info("signal.Notify", "value", v)
	case done := <-ctx.Done():
		cleanup()
		slog.Info("ctx.Done", "done", done)
	}
}
