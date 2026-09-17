package eventhandlers

import (
	"context"
	"database/sql"
	"encoding/json"
	"log/slog"

	"github.com/google/wire"
	"github.com/pkg/errors"

	"github.com/qwenhn/go-coffee-shop/internal/kitchen/domain"
	"github.com/qwenhn/go-coffee-shop/internal/kitchen/infras/postgresql"
	"github.com/qwenhn/go-coffee-shop/internal/pkg/event"
	"github.com/qwenhn/go-coffee-shop/pkg/postgres"
	pkgPublisher "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

type kitchenOrderedEventHandler struct {
	pg         postgres.DBEngine
	counterPub pkgPublisher.EventPublisher
}

var _ KitchenOrderedEventHandler = (*kitchenOrderedEventHandler)(nil)

var KitchenOrderedEventHandlerSet = wire.NewSet(NewKitchenOrderedEventHandler)

func NewKitchenOrderedEventHandler(
	pg postgres.DBEngine,
	counterPub pkgPublisher.EventPublisher,
) KitchenOrderedEventHandler {
	return &kitchenOrderedEventHandler{
		pg:         pg,
		counterPub: counterPub,
	}
}

func (h *kitchenOrderedEventHandler) Handle(ctx context.Context, e event.KitchenOrdered) error {
	slog.Info("kitchenOrderedEventHandler-Handle", "KitchenOrdered", e)

	order := domain.NewKitchenOrder(e)

	db := h.pg.GetDB()
	querier := postgresql.New(db)

	tx, err := db.Begin()
	if err != nil {
		return errors.Wrap(err, "kitchenOrderedEventHandler.Handle")
	}

	qtx := querier.WithTx(tx)

	_, err = qtx.CreateOrder(ctx, postgresql.CreateOrderParams{
		ID:       order.ID,
		OrderID:  e.OrderID,
		ItemType: int32(order.ItemType),
		ItemName: order.ItemName,
		TimeUp:   order.TimeUp,
		Created:  order.Created,
		Updated: sql.NullTime{
			Time:  order.Updated,
			Valid: true,
		},
	})
	if err != nil {
		slog.Info("failed to call to repo", "error", err)

		return errors.Wrap(err, "kitchenOrderedEventHandler-querier.CreateOrder")
	}

	for _, event := range order.DomainEvents() {
		eventBytes, err := json.Marshal(event)
		if err != nil {
			return errors.Wrap(err, "json.Marshal[event]")
		}

		if err := h.counterPub.Publish(ctx, eventBytes, "text/plain"); err != nil {
			return errors.Wrap(err, "counterPub.Publish")
		}
	}

	return tx.Commit()
}
