-include .env
export

help:
	@echo "Available commands:"
	@echo ""
	@echo "Protocol Buffers:"
	@echo "  make proto-deps       Update Buf dependencies"
	@echo "  make proto-format     Format .proto files"
	@echo "  make proto-lint       Lint .proto files"
	@echo "  make proto-generate   Generate Go code from .proto files"
	@echo "  make proto            Lint and generate protobuf code"
	@echo "  make proto-breaking   Check for breaking changes against main"
	@echo ""
	@echo "Application:"
	@echo "  make run              Run the application"
	@echo "  make run-product      Run the product service"
	@echo "  make run-proxy        Run the reserve proxy"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean            Remove generated code and clean Go build artifacts"
	@echo "  make wire             Generate dependency injection code"
.PHONY: help

proto-deps:
	buf dep update
.PHONY: proto-deps

proto-format:
	buf format -w
.PHONY: proto-format

proto-lint:
	buf lint
.PHONY: proto-lint

proto-generate:
	buf generate
.PHONY: proto-generate

proto:
	$(MAKE) proto-lint
	$(MAKE) proto-generate
.PHONY: proto

proto-breaking:
	buf breaking --against '.git#branch=main'
.PHONY: proto-breaking

clean:
	rm -rf gen && \
	go clean
.PHONY: clean

run:
	$(MAKE) run-product & \
	$(MAKE) run-proxy & \
	wait
.PHONY: run

run-product:
	cd cmd/product && go mod tidy && go mod download && \
	CGO_ENABLED=0 go run github.com/qwenhn/go-coffee-shop/cmd/product
.PHONY: run-product

run-proxy:
	cd cmd/proxy && go mod tidy && go mod download && \
	CGO_ENABLED=0 go run github.com/qwenhn/go-coffee-shop/cmd/proxy
.PHONY: run-proxy

wire:
	cd internal/product/app && wire && cd -
.PHONY: wire

linter-golangci: ### check by golangci linter
	golangci-lint run
.PHONY: linter-golangci

