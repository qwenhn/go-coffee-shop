package eventhandlers

import (
	"context"

	"github.com/qwenhn/go-coffee-shop/internal/pkg/event"
)

type BaristaOrderedEventHandler interface {
	Handle(context.Context, event.BaristaOrdered) error
}
