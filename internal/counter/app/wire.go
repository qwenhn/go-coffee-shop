//go:build wireinject
// +build wireinject

package app

import (
	"github.com/google/wire"
	amqp "github.com/rabbitmq/amqp091-go"
	"google.golang.org/grpc"

	"github.com/qwenhn/go-coffee-shop/cmd/counter/config"
	"github.com/qwenhn/go-coffee-shop/internal/counter/app/router"
	"github.com/qwenhn/go-coffee-shop/internal/counter/events/handlers"
	"github.com/qwenhn/go-coffee-shop/internal/counter/infras"
	infrasGRPC "github.com/qwenhn/go-coffee-shop/internal/counter/infras/grpc"
	"github.com/qwenhn/go-coffee-shop/internal/counter/infras/repo"
	orderUC "github.com/qwenhn/go-coffee-shop/internal/counter/usecases/orders"
	"github.com/qwenhn/go-coffee-shop/pkg/postgres"
	"github.com/qwenhn/go-coffee-shop/pkg/rabbitmq"
	pkgConsumer "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/consumer"
	pkgPublisher "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

func InitApp(
	cfg *config.Config,
	dbConnStr postgres.DBConnString,
	rabbitMQConnStr rabbitmq.RabbitMQConnStr,
	grpcServer *grpc.Server,
) (*App, func(), error) {
	panic(wire.Build(
		New,
		dbEngineFunc,
		rabbitMQFunc,
		pkgPublisher.EventPublisherSet,
		pkgConsumer.EventConsumerSet,

		infras.BaristaEventPublisherSet,
		infras.KitchenEventPublisherSet,
		infrasGRPC.ProductGRPCClientSet,
		router.CounterGRPCServerSet,
		repo.RepositorySet,
		orderUC.UseCaseSet,
		handlers.BaristaOrderUpdatedEventHandlerSet,
		handlers.KitchenOrderUpdatedEventHandlerSet,
	))
}

func dbEngineFunc(url postgres.DBConnString) (postgres.DBEngine, func(), error) {
	db, err := postgres.NewPostgresDB(url)
	if err != nil {
		return nil, nil, err
	}
	return db, func() { db.Close() }, nil
}

func rabbitMQFunc(url rabbitmq.RabbitMQConnStr) (*amqp.Connection, func(), error) {
	conn, err := rabbitmq.NewRabbitMQConn(url)
	if err != nil {
		return nil, nil, err
	}

	return conn, func() { conn.Close() }, nil
}
