package infras

import (
	"context"

	"github.com/google/wire"

	"github.com/qwenhn/go-coffee-shop/internal/counter/usecases/orders"
	"github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

var (
	BaristaEventPublisherSet = wire.NewSet(NewBaristaEventPublisher)
	KitchenEventPublisherSet = wire.NewSet(NewKitchenEventPublisher)
)

type baristaEventPublisher struct {
	pub publisher.EventPublisher
}

type kitchenEventPublisher struct {
	pub publisher.EventPublisher
}

func NewBaristaEventPublisher(pub publisher.EventPublisher) orders.BaristaEventPublisher {
	return &baristaEventPublisher{
		pub: pub,
	}
}

func (b *baristaEventPublisher) Configure(opts ...publisher.Option) {
	b.pub.Configure(opts...)
}

func (b *baristaEventPublisher) Publish(ctx context.Context, body []byte, contentType string) error {
	return b.pub.Publish(ctx, body, contentType)
}

func NewKitchenEventPublisher(pub publisher.EventPublisher) orders.KitchenEventPublisher {
	return &kitchenEventPublisher{
		pub: pub,
	}
}

func (k *kitchenEventPublisher) Configure(opts ...publisher.Option) {
	k.pub.Configure(opts...)
}

func (k *kitchenEventPublisher) Publish(ctx context.Context, body []byte, contentType string) error {
	return k.pub.Publish(ctx, body, contentType)
}
