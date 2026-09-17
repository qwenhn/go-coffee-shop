package handlers

import (
	"context"

	"github.com/google/wire"
	"github.com/pkg/errors"
	"github.com/qwenhn/go-coffee-shop/internal/counter/events"
	"github.com/qwenhn/go-coffee-shop/internal/counter/usecases/orders"
	"github.com/qwenhn/go-coffee-shop/internal/pkg/event"
)

type baristaOrderUpdatedEventHandler struct {
	orderRepo orders.OrderRepo
}

var _ events.BaristaOrderUpdatedEventHandler = (*baristaOrderUpdatedEventHandler)(nil)

var BaristaOrderUpdatedEventHandlerSet = wire.NewSet(NewBaristaOrderUpdatedEventHandler)

func NewBaristaOrderUpdatedEventHandler(orderRepo orders.OrderRepo) events.BaristaOrderUpdatedEventHandler {
	return &baristaOrderUpdatedEventHandler{
		orderRepo: orderRepo,
	}
}

func (h *baristaOrderUpdatedEventHandler) Handle(ctx context.Context, e *event.BaristaOrderUpdated) error {
	order, err := h.orderRepo.GetByID(ctx, e.OrderID)
	if err != nil {
		return errors.Wrap(err, "orderRepo.GetByID")
	}

	orderUp := event.OrderUp{
		OrderID:    e.OrderID,
		ItemLineID: e.ItemLineID,
		Name:       e.Name,
		ItemType:   e.ItemType,
		TimeUp:     e.TimeUp,
		MadeBy:     e.MadeBy,
	}

	if err = order.Apply(&orderUp); err != nil {
		return errors.Wrap(err, "order.Apply")
	}

	_, err = h.orderRepo.Update(ctx, order)
	if err != nil {
		return errors.Wrap(err, "orderRepo.Update")
	}

	return nil
}
