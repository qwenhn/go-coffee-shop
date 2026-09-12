package repo

import (
	"context"

	"github.com/google/wire"

	"github.com/qwenhn/go-coffee-shop/internal/product/domain"
)

var _ domain.ProductRepo = (*productInMemRepo)(nil)

var RepositorySet = wire.NewSet(NewOrderRepo)

type productInMemRepo struct {
	itemTypes map[string]*domain.ItemTypeDto
}

func NewOrderRepo() domain.ProductRepo {
	itemTypes := map[string]*domain.ItemTypeDto{
		"CAPPUCCINO": {
			Type:  0,
			Price: 4.5,
			Image: "img/CAPPUCCINO.png",
		},
		"COFFEE_BLACK": {
			Type:  1,
			Price: 3,
			Image: "img/COFFEE_BLACK.png",
		},
		"COFFEE_WITH_ROOM": {
			Type:  2,
			Price: 3,
			Image: "img/COFFEE_WITH_ROOM.png",
		},
		"ESPRESSO": {
			Type:  3,
			Price: 3.5,
			Image: "img/ESPRESSO.png",
		},
		"ESPRESSO_DOUBLE": {
			Type:  4,
			Price: 4.5,
			Image: "img/ESPRESSO_DOUBLE.png",
		},
		"LATTE": {
			Type:  5,
			Price: 4.5,
			Image: "img/LATTE.png",
		},
		"CAKEPOP": {
			Type:  6,
			Price: 2.5,
			Image: "img/CAKEPOP.png",
		},
		"CROISSANT": {
			Type:  7,
			Price: 3.25,
			Image: "img/CROISSANT.png",
		},
		"MUFFIN": {
			Type:  8,
			Price: 3,
			Image: "img/MUFFIN.png",
		},
		"CROISSANT_CHOCOLATE": {
			Type:  9,
			Price: 3.5,
			Image: "img/CROISSANT_CHOCOLATE.png",
		},
	}

	for name, item := range itemTypes {
		item.Name = name
	}

	return &productInMemRepo{
		itemTypes: itemTypes,
	}
}

func (p *productInMemRepo) GetAll(ctx context.Context) ([]*domain.ItemTypeDto, error) {
	results := make([]*domain.ItemTypeDto, 0)

	for _, v := range p.itemTypes {
		results = append(results, &domain.ItemTypeDto{
			Name:  v.Name,
			Type:  v.Type,
			Price: v.Price,
			Image: v.Image,
		})
	}

	return results, nil
}

func (p *productInMemRepo) GetByTypes(ctx context.Context, itemTypes []string) ([]*domain.ItemDto, error) {
	results := make([]*domain.ItemDto, 0)

	for _, itemType := range itemTypes {
		item := p.itemTypes[itemType]
		if item.Name != "" {
			results = append(results, &domain.ItemDto{
				Price: item.Price,
				Type:  item.Type,
			})
		}
	}

	return results, nil
}
