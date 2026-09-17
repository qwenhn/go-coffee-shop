package eventhandlers

import (
	"context"

	"github.com/qwenhn/go-coffee-shop/internal/pkg/event"
)

type KitchenOrderedEventHandler interface {
	Handle(context.Context, event.KitchenOrdered) error
}
