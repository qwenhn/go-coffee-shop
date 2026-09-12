package app

import (
	"github.com/qwenhn/go-coffee-shop/cmd/product/config"
	productv1 "github.com/qwenhn/go-coffee-shop/gen/go/product/v1"
	productUC "github.com/qwenhn/go-coffee-shop/internal/product/usecases/products"
)

type App struct {
	Cfg               *config.Config
	UC                productUC.UseCase
	ProductGRPCServer productv1.ProductServiceServer
}

func New(
	cfg *config.Config,
	uc productUC.UseCase,
	productGRPCServer productv1.ProductServiceServer,
) *App {
	return &App{
		Cfg:               cfg,
		UC:                uc,
		ProductGRPCServer: productGRPCServer,
	}
}
