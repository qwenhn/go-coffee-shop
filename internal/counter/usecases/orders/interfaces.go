package orders

import (
	"context"

	"github.com/google/uuid"

	"github.com/qwenhn/go-coffee-shop/internal/counter/domain"
	"github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

type OrderRepo interface {
	GetAll(context.Context) ([]*domain.Order, error)
	GetByID(context.Context, uuid.UUID) (*domain.Order, error)
	Create(context.Context, *domain.Order) error
	Update(context.Context, *domain.Order) (*domain.Order, error)
}

type UseCase interface {
	GetListOrderFulfillment(context.Context) ([]*domain.Order, error)
	PlaceOrder(context.Context, *domain.PlaceOrderModel) error
}

type BaristaEventPublisher interface {
	Configure(...publisher.Option)
	Publish(context.Context, []byte, string) error
}

type KitchenEventPublisher interface {
	Configure(...publisher.Option)
	Publish(context.Context, []byte, string) error
}
