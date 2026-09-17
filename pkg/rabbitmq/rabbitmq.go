package rabbitmq

import (
	"errors"
	"log/slog"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

const (
	_retryTimes     = 5
	_backOffSeconds = 2
)

type RabbitMQConnStr string

var ErrCannotConnectRabbitMQ = errors.New("cannot connect to rabbit")

func NewRabbitMQConn(rabbitmqURL RabbitMQConnStr) (*amqp.Connection, error) {
	var (
		amqpConn *amqp.Connection
		counts   int64
	)

	for {
		connection, err := amqp.Dial(string(rabbitmqURL))
		if err != nil {
			slog.Error("failed to connect to RabbitMQ...", "error", err, "url", rabbitmqURL)

			counts++
		} else {
			amqpConn = connection

			break
		}

		if counts > _retryTimes {
			slog.Error("failed to retry", "error", err)

			return nil, ErrCannotConnectRabbitMQ
		}

		slog.Info("Backing off for 2 seconds...")
		time.Sleep(_backOffSeconds * time.Second)

		continue
	}

	slog.Info("📫 connected to rabbitmq 🎉")

	return amqpConn, nil
}
