package publisher

import (
	"context"
	"log"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/google/wire"
	"github.com/pkg/errors"
	amqp "github.com/rabbitmq/amqp091-go"
)

const (
	_publishMandatory = false
	_publishImmediate = false

	_exchangeName    = "orders-exchange"
	_bindingKey      = "orders-routing-key"
	_messageTypeName = "ordered"
)

type publisher struct {
	exchangeName    string
	bindingKey      string
	messageTypeName string
	amqpChan        *amqp.Channel
	amqpConn        *amqp.Connection
}

var _ EventPublisher = (*publisher)(nil)

var EventPublisherSet = wire.NewSet(NewPublisher)

func NewPublisher(amqpConn *amqp.Connection) (EventPublisher, error) {
	ch, err := amqpConn.Channel()
	if err != nil {
		panic(err)
	}
	defer func() {
		if err := ch.Close(); err != nil {
			log.Printf("failed to close AMQP channel: %v", err)
		}
	}()

	pub := &publisher{
		amqpConn: amqpConn,
		amqpChan: ch,

		exchangeName:    _exchangeName,
		bindingKey:      _bindingKey,
		messageTypeName: _messageTypeName,
	}

	return pub, nil
}

func (p *publisher) Configure(opts ...Option) EventPublisher {
	for _, opt := range opts {
		opt(p)
	}

	return p
}

func (p *publisher) Publish(ctx context.Context, body []byte, contentType string) error {
	ch, err := p.amqpConn.Channel()
	if err != nil {
		return errors.Wrap(err, "CreateChannel")
	}
	defer func() {
		if err = ch.Close(); err != nil {
			log.Printf("failed to close AMQP channel: %v", err)
		}
	}()

	slog.Info("publish message", "exchange", p.exchangeName, "routing_key", p.bindingKey)

	err = ch.PublishWithContext(
		ctx,
		p.exchangeName,
		p.bindingKey,
		_publishMandatory,
		_publishImmediate,
		amqp.Publishing{
			ContentType:  contentType,
			DeliveryMode: amqp.Persistent,
			MessageId:    uuid.New().String(),
			Timestamp:    time.Now(),
			Body:         body,
			Type:         p.messageTypeName,
		},
	)
	if err != nil {
		return errors.Wrap(err, "ch.Publish")
	}

	return nil
}
