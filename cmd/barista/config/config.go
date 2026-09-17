package config

import (
	"fmt"

	"github.com/ilyakaznacheev/cleanenv"

	configs "github.com/qwenhn/go-coffee-shop/pkg/config"
)

type Config struct {
	configs.App  `yaml:"app"`
	configs.HTTP `yaml:"http"`
	configs.Log  `yaml:"logger"`
	PG           `yaml:"postgres"`
	RabbitMQ     `yaml:"rabbitmq"`
}

type PG struct {
	PoolMax int    `env-required:"true" yaml:"pool_max" env:"PG_POOL_MAX"`
	DsnURL  string `env-required:"true" yaml:"dsn_url" env:"PG_DSN_URL"`
}

type RabbitMQ struct {
	URL string `env-required:"true" yaml:"url" env:"RABBITMQ_URL"`
}

func NewConfig() (*Config, error) {
	cfg := new(Config)

	err := cleanenv.ReadConfig("config.yml", cfg)
	if err != nil {
		return nil, fmt.Errorf("config err: %w", err)
	}

	err = cleanenv.ReadEnv(cfg)
	if err != nil {
		return nil, err
	}

	return cfg, nil
}
