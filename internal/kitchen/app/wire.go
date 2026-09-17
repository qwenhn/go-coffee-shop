//go:build wireinject
// +build wireinject

package app

import (
	"github.com/google/wire"
	amqp "github.com/rabbitmq/amqp091-go"

	"github.com/qwenhn/go-coffee-shop/cmd/kitchen/config"
	"github.com/qwenhn/go-coffee-shop/internal/kitchen/eventhandlers"
	"github.com/qwenhn/go-coffee-shop/pkg/postgres"
	"github.com/qwenhn/go-coffee-shop/pkg/rabbitmq"
	pkgConsumer "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/consumer"
	pkgPublisher "github.com/qwenhn/go-coffee-shop/pkg/rabbitmq/publisher"
)

func InitApp(
	cfg *config.Config,
	dbConnStr postgres.DBConnString,
	rabbitMQConnStr rabbitmq.RabbitMQConnStr,
) (*App, func(), error) {
	panic(wire.Build(
		New,
		dbEngineFunc,
		rabbitMQFunc,
		pkgPublisher.EventPublisherSet,
		pkgConsumer.EventConsumerSet,
		eventhandlers.KitchenOrderedEventHandlerSet,
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
