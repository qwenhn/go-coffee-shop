-include .env
export

GO ?= go
BUF ?= buf
DOCKER ?= docker
MIGRATE ?= migrate
SQLC ?= sqlc
WIRE ?= wire
GOLANGCI_LINT ?= golangci-lint
GOFLAGS ?=

PRODUCT_DIR := cmd/product
COUNTER_DIR := cmd/counter
BARISTA_DIR := cmd/barista
KITCHEN_DIR := cmd/kitchen
PROXY_DIR := cmd/proxy

SERVICES := product counter barista kitchen proxy

MIGRATION_DIR := db/migrations

CONN_STRING := postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DB)?sslmode=$(POSTGRES_SSLMODE)


# ============================================================
# Phony Targets
# ============================================================

.PHONY: help \
	proto-deps proto-format proto-lint proto-generate proto proto-breaking \
	run run-product run-counter run-barista run-kitchen run-proxy \
	build build-product build-counter build-barista build-kitchen build-proxy \
	test test-race fmt vet tidy check \
	wire sqlc \
	lint linter-golangci \
	docker-up docker-down \
	docker-compose-core docker-compose-core-start docker-compose-core-stop \
	migrate-create migrate-up migrate-down migrate-down-n \
	migrate-force migrate-goto migrate-drop \
	clean


# ============================================================
# Help
# ============================================================

help:
	@echo "Available commands:"
	@echo ""
	@echo "Protocol Buffers:"
	@echo "  make proto-deps                  Update Buf dependencies"
	@echo "  make proto-format                Format .proto files"
	@echo "  make proto-lint                  Lint .proto files"
	@echo "  make proto-generate              Generate Go code from .proto files"
	@echo "  make proto                       Lint and generate protobuf code"
	@echo "  make proto-breaking              Check for breaking changes against main"
	@echo ""
	@echo "Application:"
	@echo "  make run                         Run all services"
	@echo "  make run-product                 Run the product service"
	@echo "  make run-counter                 Run the counter service"
	@echo "  make run-barista                 Run the barista service"
	@echo "  make run-kitchen                 Run the kitchen service"
	@echo "  make run-proxy                   Run the proxy service"
	@echo ""
	@echo "Build & Test:"
	@echo "  make build                       Build all services"
	@echo "  make build-product               Build the product service"
	@echo "  make build-counter               Build the counter service"
	@echo "  make build-barista               Build the barista service"
	@echo "  make build-kitchen               Build the kitchen service"
	@echo "  make build-proxy                 Build the proxy service"
	@echo "  make test                        Run all tests"
	@echo "  make test-race                   Run tests with the race detector"
	@echo "  make fmt                         Format Go code"
	@echo "  make vet                         Run go vet"
	@echo "  make tidy                        Tidy all Go modules"
	@echo "  make check                       Run formatting, vet, lint, and tests"
	@echo ""
	@echo "Code Generation:"
	@echo "  make wire                        Generate dependency injection code"
	@echo "  make sqlc                        Generate SQL code with sqlc"
	@echo ""
	@echo "Linting:"
	@echo "  make lint                        Run golangci-lint"
	@echo "  make linter-golangci             Run golangci-lint directly"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up                   Start full development environment"
	@echo "  make docker-down                 Stop full development environment"
	@echo "  make docker-compose-core         Restart core infrastructure"
	@echo "  make docker-compose-core-start   Start core infrastructure"
	@echo "  make docker-compose-core-stop    Stop core infrastructure"
	@echo ""
	@echo "Database:"
	@echo "  make migrate-create NAME=x       Create a new migration"
	@echo "  make migrate-up                  Run all pending migrations"
	@echo "  make migrate-down                Rollback the last migration"
	@echo "  make migrate-down-n N=x          Rollback N migrations"
	@echo "  make migrate-force VERSION=x     Force migration version"
	@echo "  make migrate-goto VERSION=x      Apply migration up to version"
	@echo "  make migrate-drop                Drop all migrations"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean                       Remove generated code and build artifacts"


# ============================================================
# Protocol Buffers
# ============================================================

proto-deps:
	$(BUF) dep update

proto-format:
	$(BUF) format -w

proto-lint:
	$(BUF) lint

proto-generate:
	$(BUF) generate

proto: proto-lint proto-generate

proto-breaking:
	$(BUF) breaking --against '.git#branch=main'


# ============================================================
# Application
# ============================================================

# Run all services concurrently.
run:
	@echo "Starting all services..."
	$(MAKE) run-product & \
	$(MAKE) run-counter & \
	$(MAKE) run-barista & \
	$(MAKE) run-kitchen & \
	$(MAKE) run-proxy & \
	wait

run-product:
	cd $(PRODUCT_DIR) && \
	CGO_ENABLED=0 $(GO) run ./...

run-counter:
	cd $(COUNTER_DIR) && \
	CGO_ENABLED=0 $(GO) run ./...

run-barista:
	cd $(BARISTA_DIR) && \
	CGO_ENABLED=0 $(GO) run ./...

run-kitchen:
	cd $(KITCHEN_DIR) && \
	CGO_ENABLED=0 $(GO) run ./...

run-proxy:
	cd $(PROXY_DIR) && \
	CGO_ENABLED=0 $(GO) run ./...


# ============================================================
# Build
# ============================================================

build: build-product build-counter build-barista build-kitchen build-proxy

build-product:
	cd $(PRODUCT_DIR) && \
	CGO_ENABLED=0 $(GO) build $(GOFLAGS) -o bin/product ./...

build-counter:
	cd $(COUNTER_DIR) && \
	CGO_ENABLED=0 $(GO) build $(GOFLAGS) -o bin/counter ./...

build-barista:
	cd $(BARISTA_DIR) && \
	CGO_ENABLED=0 $(GO) build $(GOFLAGS) -o bin/barista ./...

build-kitchen:
	cd $(KITCHEN_DIR) && \
	CGO_ENABLED=0 $(GO) build $(GOFLAGS) -o bin/kitchen ./...

build-proxy:
	cd $(PROXY_DIR) && \
	CGO_ENABLED=0 $(GO) build $(GOFLAGS) -o bin/proxy ./...


# ============================================================
# Testing
# ============================================================

test:
	cd $(PRODUCT_DIR) && $(GO) test ./...
	cd $(COUNTER_DIR) && $(GO) test ./...
	cd $(BARISTA_DIR) && $(GO) test ./...
	cd $(KITCHEN_DIR) && $(GO) test ./...
	cd $(PROXY_DIR) && $(GO) test ./...

test-race:
	cd $(PRODUCT_DIR) && $(GO) test -race ./...
	cd $(COUNTER_DIR) && $(GO) test -race ./...
	cd $(BARISTA_DIR) && $(GO) test -race ./...
	cd $(KITCHEN_DIR) && $(GO) test -race ./...
	cd $(PROXY_DIR) && $(GO) test -race ./...


# ============================================================
# Go Development
# ============================================================

fmt:
	cd $(PRODUCT_DIR) && $(GO) fmt ./...
	cd $(COUNTER_DIR) && $(GO) fmt ./...
	cd $(BARISTA_DIR) && $(GO) fmt ./...
	cd $(KITCHEN_DIR) && $(GO) fmt ./...
	cd $(PROXY_DIR) && $(GO) fmt ./...

vet:
	cd $(PRODUCT_DIR) && $(GO) vet ./...
	cd $(COUNTER_DIR) && $(GO) vet ./...
	cd $(BARISTA_DIR) && $(GO) vet ./...
	cd $(KITCHEN_DIR) && $(GO) vet ./...
	cd $(PROXY_DIR) && $(GO) vet ./...

tidy:
	cd $(PRODUCT_DIR) && $(GO) mod tidy
	cd $(COUNTER_DIR) && $(GO) mod tidy
	cd $(BARISTA_DIR) && $(GO) mod tidy
	cd $(KITCHEN_DIR) && $(GO) mod tidy
	cd $(PROXY_DIR) && $(GO) mod tidy

check: fmt vet lint test


# ============================================================
# Code Generation
# ============================================================

wire:
	cd internal/barista/app && $(WIRE)
	cd internal/counter/app && $(WIRE)
	cd internal/kitchen/app && $(WIRE)
	cd internal/product/app && $(WIRE)

sqlc:
	$(SQLC) generate


# ============================================================
# Linting
# ============================================================

lint: linter-golangci

linter-golangci:
	$(GOLANGCI_LINT) run


# ============================================================
# Docker Compose
# ============================================================

docker-up:
	$(DOCKER) compose up --build

docker-down:
	$(DOCKER) compose down

docker-compose-core: docker-compose-core-stop docker-compose-core-start

docker-compose-core-start:
	$(DOCKER) compose -f docker-compose-core.yaml up --build -d

docker-compose-core-stop:
	$(DOCKER) compose -f docker-compose-core.yaml down --remove-orphans


# ============================================================
# Database Migrations
# ============================================================

migrate-create:
	@test -n "$(NAME)" || (echo "ERROR: NAME is required. Example: make migrate-create NAME=add_users"; exit 1)
	$(MIGRATE) create -ext sql -dir $(MIGRATION_DIR) -seq $(NAME)

migrate-up:
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		up

migrate-down:
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		down 1

migrate-down-n:
	@test -n "$(N)" || (echo "ERROR: N is required. Example: make migrate-down-n N=2"; exit 1)
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		down $(N)

migrate-force:
	@test -n "$(VERSION)" || (echo "ERROR: VERSION is required. Example: make migrate-force VERSION=1"; exit 1)
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		force $(VERSION)

migrate-goto:
	@test -n "$(VERSION)" || (echo "ERROR: VERSION is required. Example: make migrate-goto VERSION=3"; exit 1)
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		goto $(VERSION)

migrate-drop:
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		drop


# ============================================================
# Maintenance
# ============================================================

clean:
	rm -rf gen
	rm -rf $(PRODUCT_DIR)/bin
	rm -rf $(COUNTER_DIR)/bin
	rm -rf $(BARISTA_DIR)/bin
	rm -rf $(KITCHEN_DIR)/bin
	rm -rf $(PROXY_DIR)/bin
	$(GO) clean
