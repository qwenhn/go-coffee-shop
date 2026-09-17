package events

import (
	"context"

	"github.com/qwenhn/go-coffee-shop/internal/pkg/event"
)

type BaristaOrderUpdatedEventHandler interface {
	Handle(context.Context, *event.BaristaOrderUpdated) error
}

type KitchenOrderUpdatedEventHandler interface {
	Handle(context.Context, *event.KitchenOrderUpdated) error
}
