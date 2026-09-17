package orders

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"

	"github.com/google/wire"
	"github.com/pkg/errors"

	"github.com/qwenhn/go-coffee-shop/internal/counter/domain"
)

type usecase struct {
	orderRepo        OrderRepo
	productDomainSvc domain.ProductDomainService
	baristaEventPub  BaristaEventPublisher
	kitchenEventPub  KitchenEventPublisher
}

var _ UseCase = (*usecase)(nil)

var UseCaseSet = wire.NewSet(NewUseCase)

func NewUseCase(
	orderRepo OrderRepo,
	productDomainSvc domain.ProductDomainService,
	baristaEventPub BaristaEventPublisher,
	kitchenEventPub KitchenEventPublisher,
) UseCase {
	return &usecase{
		orderRepo:        orderRepo,
		productDomainSvc: productDomainSvc,
		baristaEventPub:  baristaEventPub,
		kitchenEventPub:  kitchenEventPub,
	}
}

func (uc *usecase) GetListOrderFulfillment(ctx context.Context) ([]*domain.Order, error) {
	entities, err := uc.orderRepo.GetAll(ctx)
	if err != nil {
		return nil, fmt.Errorf("orderRepo.GetAll: %w", err)
	}

	return entities, nil
}

func (uc *usecase) PlaceOrder(ctx context.Context, model *domain.PlaceOrderModel) error {
	order, err := domain.CreateOrderFrom(ctx, model, uc.productDomainSvc)
	if err != nil {
		return errors.Wrap(err, "domain.CreateOrderFrom")
	}

	err = uc.orderRepo.Create(ctx, order)
	if err != nil {
		return errors.Wrap(err, "orderRepo.Create")
	}

	slog.Debug("order created", "order", *order)

	for _, event := range order.DomainEvents() {
		if event.Identity() == "BaristaOrdered" {
			eventBytes, err := json.Marshal(event)
			if err != nil {
				return errors.Wrap(err, "json.Marshal[event]")
			}

			err = uc.baristaEventPub.Publish(ctx, eventBytes, "text/plain")
			if err != nil {
				return errors.Wrap(err, "baristaEventPub")
			}
		}

		if event.Identity() == "KitchenOrdered" {
			eventBytes, err := json.Marshal(event)
			if err != nil {
				return errors.Wrap(err, "json.Marshal[event]")
			}

			err = uc.kitchenEventPub.Publish(ctx, eventBytes, "text/plain")
			if err != nil {
				return errors.Wrap(err, "baristaEventPub")
			}
		}
	}

	return nil
}
