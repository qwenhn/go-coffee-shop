package router

import (
	"context"
	"fmt"
	"log/slog"
	"math"

	"github.com/google/wire"
	"github.com/pkg/errors"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	productv1 "github.com/qwenhn/go-coffee-shop/gen/go/product/v1"
	"github.com/qwenhn/go-coffee-shop/internal/product/usecases/products"
)

var _ productv1.ProductServiceServer = (*productGRPCServer)(nil)

var ProductGRPCServerSet = wire.NewSet(NewProductGRPCServer)

var ErrItemTypeOutOfRange = errors.New("item type is out of int32 range")

type productGRPCServer struct {
	productv1.UnimplementedProductServiceServer
	uc products.UseCase
}

func NewProductGRPCServer(
	grpcServer *grpc.Server,
	uc products.UseCase,
) productv1.ProductServiceServer {
	svc := productGRPCServer{
		uc: uc,
	}

	productv1.RegisterProductServiceServer(grpcServer, &svc)

	reflection.Register(grpcServer)

	return &svc
}

func (p *productGRPCServer) GetItemTypes(ctx context.Context, request *productv1.GetItemTypesRequest) (*productv1.GetItemTypesResponse, error) {
	slog.Info("gRPC client", "http_method", "GET", "http_name", "GetItemTypes")

	res := productv1.GetItemTypesResponse{}

	results, err := p.uc.GetItemTypes(ctx)
	if err != nil {
		return nil, errors.Wrap(err, "productGRPCServer-GetItemTypes")
	}

	for _, item := range results {
		if item.Type < math.MinInt32 || item.Type > math.MaxInt32 {
			return nil, fmt.Errorf("%w: %d", ErrItemTypeOutOfRange, item.Type)
		}

		res.ItemTypes = append(res.ItemTypes, &productv1.ItemType{
			Name:  item.Name,
			Type:  int32(item.Type),
			Price: item.Price,
			Image: item.Image,
		})
	}

	return &res, nil
}

func (p *productGRPCServer) GetItemsByType(ctx context.Context, request *productv1.GetItemsByTypeRequest) (*productv1.GetItemsByTypeResponse, error) {
	slog.Info("gRPC client", "http_method", "GET", "http_name", "GetItemsByType", "item_types", request.ItemTypes)

	res := productv1.GetItemsByTypeResponse{}

	results, err := p.uc.GetItemsByType(ctx, request.ItemTypes)
	if err != nil {
		return nil, errors.Wrap(err, "productGRPCServer-GetItemsByType")
	}

	for _, item := range results {
		if item.Type < math.MinInt32 || item.Type > math.MaxInt32 {
			return nil, fmt.Errorf("%w: %d", ErrItemTypeOutOfRange, item.Type)
		}

		res.Items = append(res.Items, &productv1.Item{
			Type:  int32(item.Type),
			Price: item.Price,
		})
	}

	return &res, nil
}
