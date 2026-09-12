//go:build wireinject
// +build wireinject

package app

import (
	"github.com/google/wire"
	"google.golang.org/grpc"

	"github.com/qwenhn/go-coffee-shop/cmd/product/config"
	"github.com/qwenhn/go-coffee-shop/internal/product/app/router"
	"github.com/qwenhn/go-coffee-shop/internal/product/infras/repo"
	productsUC "github.com/qwenhn/go-coffee-shop/internal/product/usecases/products"
)

func InitApp(
	cfg *config.Config,
	grpcServer *grpc.Server,
) (*App, error) {
	panic(wire.Build(
		New,
		router.ProductGRPCServerSet,
		repo.RepositorySet,
		productsUC.UseCaseSet,
	))
}
