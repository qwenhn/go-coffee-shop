package consumer

type Option func(*consumer)

func ExchangeName(exchangeName string) Option {
	return func(c *consumer) {
		c.exchangeName = exchangeName
	}
}

func QueueName(queueName string) Option {
	return func(c *consumer) {
		c.queueName = queueName
	}
}

func BindingKey(bindingKey string) Option {
	return func(p *consumer) {
		p.bindingKey = bindingKey
	}
}

func ConsumerTag(consumerTag string) Option {
	return func(p *consumer) {
		p.consumerTag = consumerTag
	}
}

func WorkerPoolSize(workerPoolSize int) Option {
	return func(p *consumer) {
		p.workerPoolSize = workerPoolSize
	}
}
