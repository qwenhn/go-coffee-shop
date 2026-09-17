package app

import (
	"context"
	"encoding/json"
	"log/slog"

	amqp "github.com/rabbitmq/amqp091-go"

	"github.com/qwenhn/go-coffee-shop/cmd/counter/config"
	counterv1 "github.com/qwenhn/go-coffee-shop/gen/go/counter/v1"
	"github.com/qwenhn/go-coffee-shop/internal/counter/domain"
	"github.com/qwenhn/go-coffee-shop/internal/counter/events"
	ordersUC "github.com/qwenhn/go-coffee-shop/internal/counter/usecases/orders"
	shared "github.com/qwenhn/go-coffee-shop/internal/pkg/event"
	"github.com/qwenhn/go-coffee-shop/pkg/postgres"
	pkgConsumer "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/consumer"
	pkgPublisher "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

type App struct {
	Cfg       *config.Config
	PG        postgres.DBEngine
	AMQPConn  *amqp.Connection
	Publisher pkgPublisher.EventPublisher
	Consumer  pkgConsumer.EventConsumer

	BaristaOrderPub ordersUC.BaristaEventPublisher
	KitchenOrderPub ordersUC.KitchenEventPublisher

	ProductDomainSvc  domain.ProductDomainService
	UC                ordersUC.UseCase
	CounterGRPCServer counterv1.CounterServiceServer

	baristaHandler events.BaristaOrderUpdatedEventHandler
	kitchenHandler events.KitchenOrderUpdatedEventHandler
}

func New(
	cfg *config.Config,
	pg postgres.DBEngine,
	amqpConn *amqp.Connection,
	publisher pkgPublisher.EventPublisher,
	consumer pkgConsumer.EventConsumer,

	baristaOrderPub ordersUC.BaristaEventPublisher,
	kitchenOrderPub ordersUC.KitchenEventPublisher,

	productDomainSvc domain.ProductDomainService,
	uc ordersUC.UseCase,
	counterGRPCServer counterv1.CounterServiceServer,

	baristaHandler events.BaristaOrderUpdatedEventHandler,
	kitchenHandler events.KitchenOrderUpdatedEventHandler,
) *App {
	return &App{
		Cfg:       cfg,
		PG:        pg,
		AMQPConn:  amqpConn,
		Publisher: publisher,
		Consumer:  consumer,

		BaristaOrderPub: baristaOrderPub,
		KitchenOrderPub: kitchenOrderPub,

		ProductDomainSvc:  productDomainSvc,
		UC:                uc,
		CounterGRPCServer: counterGRPCServer,

		baristaHandler: baristaHandler,
		kitchenHandler: kitchenHandler,
	}
}

func (a *App) Worker(ctx context.Context, messages <-chan amqp.Delivery) {
	for delivery := range messages {
		slog.Info("processDeliveries", "delivery_tag", delivery.DeliveryTag)
		slog.Info("received", "delivery_type", delivery.Type)

		switch delivery.Type {
		case "barista-order-updated":
			var payload shared.BaristaOrderUpdated

			err := json.Unmarshal(delivery.Body, &payload)
			if err != nil {
				slog.Error("failed to Unmarshal message", "error", err)
			}

			err = a.baristaHandler.Handle(ctx, &payload)

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
		case "kitchen-order-updated":
			var payload shared.KitchenOrderUpdated

			err := json.Unmarshal(delivery.Body, &payload)
			if err != nil {
				slog.Error("failed to Unmarshal message", "error", err)
			}

			err = a.kitchenHandler.Handle(ctx, &payload)

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

	slog.Info("Deliveries channel closed")
}
