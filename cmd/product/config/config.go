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
