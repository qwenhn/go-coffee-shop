package app

import (
	"context"
	"encoding/json"
	"log/slog"

	amqp "github.com/rabbitmq/amqp091-go"

	"github.com/qwenhn/go-coffee-shop/cmd/kitchen/config"
	"github.com/qwenhn/go-coffee-shop/internal/kitchen/eventhandlers"
	"github.com/qwenhn/go-coffee-shop/internal/pkg/event"
	"github.com/qwenhn/go-coffee-shop/pkg/postgres"
	pkgConsumer "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/consumer"
	pkgPublisher "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

type App struct {
	Cfg *config.Config

	PG       postgres.DBEngine
	AMQPConn *amqp.Connection

	CounterOrderPub pkgPublisher.EventPublisher
	Consumer        pkgConsumer.EventConsumer

	handler eventhandlers.KitchenOrderedEventHandler
}

func New(
	cfg *config.Config,
	pg postgres.DBEngine,
	amqpConn *amqp.Connection,
	counterOrderPub pkgPublisher.EventPublisher,
	consumer pkgConsumer.EventConsumer,
	handler eventhandlers.KitchenOrderedEventHandler,
) *App {
	return &App{
		Cfg:      cfg,
		PG:       pg,
		AMQPConn: amqpConn,

		CounterOrderPub: counterOrderPub,
		Consumer:        consumer,

		handler: handler,
	}
}

func (c *App) Worker(ctx context.Context, messages <-chan amqp.Delivery) {
	for delivery := range messages {
		slog.Info("processDeliveries", "delivery_tag", delivery.DeliveryTag)
		slog.Info("received", "delivery_type", delivery.Type)

		switch delivery.Type {
		case "kitchen-order-created":
			var payload event.KitchenOrdered

			err := json.Unmarshal(delivery.Body, &payload)
			if err != nil {
				slog.Error("failed to Unmarshal message", "error", err)
			}

			err = c.handler.Handle(ctx, payload)
			if err != nil {
				if err = delivery.Reject(false); err != nil {
					slog.Error("failed to delivery.Reject", "error", err)
				}

				slog.Error("failed to process delivery", "error", err)
			} else {
				err = delivery.Ack(false)
				if err != nil {
					slog.Error("failed to acknowledge delivery", "error", err)
				}
			}
		default:
			slog.Info("default")
		}
	}

	slog.Info("deliveries channel closed")
}
