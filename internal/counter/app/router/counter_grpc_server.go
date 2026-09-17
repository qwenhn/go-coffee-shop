package router

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/google/uuid"
	"github.com/google/wire"
	"github.com/pkg/errors"
	"github.com/samber/lo"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/qwenhn/go-coffee-shop/cmd/counter/config"
	counterv1 "github.com/qwenhn/go-coffee-shop/gen/go/counter/v1"
	"github.com/qwenhn/go-coffee-shop/internal/counter/domain"
	"github.com/qwenhn/go-coffee-shop/internal/counter/usecases/orders"
	shared "github.com/qwenhn/go-coffee-shop/internal/pkg/shared_kernel"
)

type counterGRPCServer struct {
	counterv1.UnimplementedCounterServiceServer
	cfg *config.Config
	uc  orders.UseCase
}

var _ counterv1.CounterServiceServer = (*counterGRPCServer)(nil)

var CounterGRPCServerSet = wire.NewSet(NewGRPCCounterServer)

func NewGRPCCounterServer(
	grpcServer *grpc.Server,
	cfg *config.Config,
	uc orders.UseCase,
) counterv1.CounterServiceServer {
	svc := counterGRPCServer{
		cfg: cfg,
		uc:  uc,
	}

	counterv1.RegisterCounterServiceServer(grpcServer, &svc)

	reflection.Register(grpcServer)

	return &svc
}

func (g *counterGRPCServer) GetListOrderFulfillment(
	ctx context.Context,
	request *counterv1.GetListOrderFulfillmentRequest,
) (*counterv1.GetListOrderFulfillmentResponse, error) {
	slog.Info("GET: GetListOrderFulfillment")

	res := counterv1.GetListOrderFulfillmentResponse{}

	entities, err := g.uc.GetListOrderFulfillment(ctx)
	if err != nil {
		return nil, fmt.Errorf("uc.GetListOrderFulfillment: %w", err)
	}

	for _, entity := range entities {
		res.Orders = append(res.Orders, &counterv1.Order{
			Id:              entity.ID.String(),
			OrderSource:     int32(entity.OrderSource),
			OrderStatus:     int32(entity.OrderStatus),
			Location:        int32(entity.Location),
			LoyaltyMemberId: entity.LoyaltyMemberID.String(),
			LineItems: lo.Map(entity.LineItems, func(item *domain.LineItem, _ int) *counterv1.LineItem {
				return &counterv1.LineItem{
					Id:             item.ID.String(),
					ItemType:       int32(item.ItemType),
					Name:           item.Name,
					Price:          float64(item.Price),
					ItemStatus:     int32(item.ItemStatus),
					IsBaristaOrder: item.IsBaristaOrder,
				}
			}),
		})
	}

	return &res, nil
}

func (g *counterGRPCServer) PlaceOrder(
	ctx context.Context,
	request *counterv1.PlaceOrderRequest,
) (*counterv1.PlaceOrderResponse, error) {
	slog.Info("POST: PlaceOrder")

	loyaltyMemberID, err := uuid.Parse(request.LoyaltyMemberId)
	if err != nil {
		return nil, errors.Wrap(err, "uuid.Parse")
	}

	model := domain.PlaceOrderModel{
		CommandType:     shared.CommandType(request.CommandType),
		OrderSource:     shared.OrderSource(request.OrderSource),
		Location:        shared.Location(request.Location),
		LoyaltyMemberID: loyaltyMemberID,
		Timestamp:       request.Timestamp.AsTime(),
	}

	for _, barista := range request.BaristaItems {
		model.BaristaItems = append(model.BaristaItems, &domain.OrderItemModel{
			ItemType: shared.ItemType(barista.ItemType),
		})
	}

	for _, kitchen := range request.KitchenItems {
		model.KitchenItems = append(model.KitchenItems, &domain.OrderItemModel{
			ItemType: shared.ItemType(kitchen.ItemType),
		})
	}

	err = g.uc.PlaceOrder(ctx, &model)
	if err != nil {
		return nil, errors.Wrap(err, "uc.PlaceOrder")
	}

	res := counterv1.PlaceOrderResponse{}

	return &res, nil
}
