package eventhandlers

import (
	"context"
	"database/sql"
	"encoding/json"
	"log/slog"

	"github.com/google/wire"
	"github.com/pkg/errors"

	"github.com/qwenhn/go-coffee-shop/internal/barista/domain"
	"github.com/qwenhn/go-coffee-shop/internal/barista/infras/postgresql"
	"github.com/qwenhn/go-coffee-shop/internal/pkg/event"
	"github.com/qwenhn/go-coffee-shop/pkg/postgres"
	"github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

var _ BaristaOrderedEventHandler = (*baristaOrderedEventHandler)(nil)

var BaristaOrderedEventHandlerSet = wire.NewSet(NewBaristaOrderedEventHandler)

type baristaOrderedEventHandler struct {
	pg         postgres.DBEngine
	counterPub publisher.EventPublisher
}

func NewBaristaOrderedEventHandler(pg postgres.DBEngine, counterPub publisher.EventPublisher) BaristaOrderedEventHandler {
	return &baristaOrderedEventHandler{
		pg:         pg,
		counterPub: counterPub,
	}
}

func (h *baristaOrderedEventHandler) Handle(ctx context.Context, e event.BaristaOrdered) error {
	slog.Info("received event", "event.BaristaOrdered", e)

	order := domain.NewBaristaOrder(e)

	db := h.pg.GetDB()
	querier := postgresql.New(db)

	tx, err := db.Begin()
	if err != nil {
		return errors.Wrap(err, "baristaOrderedEventHandler.Handle")
	}

	qtx := querier.WithTx(tx)

	_, err = qtx.CreateOrder(ctx, postgresql.CreateOrderParams{
		ID:       order.ID,
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

		return errors.Wrap(err, "baristaOrderedEventHandler-querier.CreateOrder")
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
