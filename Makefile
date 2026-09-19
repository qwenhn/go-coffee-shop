-include .env
export

# ============================================================
# Tools
# ============================================================

GO ?= go
BUF ?= buf
DOCKER ?= docker
MIGRATE ?= migrate
SQLC ?= sqlc
WIRE ?= wire
GOLANGCI_LINT ?= golangci-lint

GOFLAGS ?=
GO_ENV ?= CGO_ENABLED=0

# ============================================================
# Directories
# ============================================================

PRODUCT_DIR := cmd/product
COUNTER_DIR := cmd/counter
BARISTA_DIR := cmd/barista
KITCHEN_DIR := cmd/kitchen
PROXY_DIR := cmd/proxy
WEB_DIR := cmd/web

# Services containing Go modules.
SERVICES := product counter barista kitchen proxy

SERVICE_DIR_product := $(PRODUCT_DIR)
SERVICE_DIR_counter := $(COUNTER_DIR)
SERVICE_DIR_barista := $(BARISTA_DIR)
SERVICE_DIR_kitchen := $(KITCHEN_DIR)
SERVICE_DIR_proxy := $(PROXY_DIR)

MIGRATION_DIR := db/migrations

# ============================================================
# Database
# ============================================================

CONN_STRING := postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DB)?sslmode=$(POSTGRES_SSLMODE)

# ============================================================
# Phony Targets
# ============================================================

.PHONY: \
	help \
	proto-deps proto-format proto-lint proto-generate proto proto-breaking \
	run run-product run-counter run-barista run-kitchen run-proxy run-web \
	build build-product build-counter build-barista build-kitchen build-proxy \
	test test-race \
	fmt fmt-check vet tidy check \
	wire sqlc \
	lint linter-golangci \
	docker-compose docker-up docker-down \
	docker-compose-core docker-compose-core-start docker-compose-core-stop \
	migrate-create migrate-up migrate-down migrate-down-n \
	migrate-force migrate-goto migrate-drop \
	check-env clean


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
	@echo "  make run-web                     Run the web service"
	@echo ""
	@echo "Build & Test:"
	@echo "  make build                       Build all services"
	@echo "  make build-product               Build the product service"
	@echo "  make build-counter               Build the counter service"
	@echo "  make build-barista               Build the barista service"
	@echo "  make build-kitchen               Build the kitchen service"
	@echo "  make build-proxy                 Build the proxy service"
	@echo "  make test                        Run all tests"
	@echo "  make test-race                   Run tests with race detector"
	@echo "  make fmt                         Format Go code"
	@echo "  make fmt-check                   Check formatting without modifying files"
	@echo "  make vet                         Run go vet"
	@echo "  make tidy                        Tidy all Go modules"
	@echo "  make check                       Run CI checks"
	@echo ""
	@echo "Code Generation:"
	@echo "  make wire                        Generate dependency injection code"
	@echo "  make sqlc                        Generate SQL code with sqlc"
	@echo ""
	@echo "Linting:"
	@echo "  make lint                        Run golangci-lint"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-compose              Restart full development environment"
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

run:
	@echo "Starting all services..."
	@set -e; \
	pids=""; \
	trap 'kill $$pids 2>/dev/null || true' INT TERM EXIT; \
	$(MAKE) run-product & pids="$$pids $$!"; \
	$(MAKE) run-counter & pids="$$pids $$!"; \
	$(MAKE) run-barista & pids="$$pids $$!"; \
	$(MAKE) run-kitchen & pids="$$pids $$!"; \
	$(MAKE) run-proxy & pids="$$pids $$!"; \
	$(MAKE) run-web & pids="$$pids $$!"; \
	wait

run-product:
	cd $(PRODUCT_DIR) && $(GO_ENV) $(GO) run ./...

run-counter:
	cd $(COUNTER_DIR) && $(GO_ENV) $(GO) run ./...

run-barista:
	cd $(BARISTA_DIR) && $(GO_ENV) $(GO) run ./...

run-kitchen:
	cd $(KITCHEN_DIR) && $(GO_ENV) $(GO) run ./...

run-proxy:
	cd $(PROXY_DIR) && $(GO_ENV) $(GO) run ./...

run-web:
	cd $(WEB_DIR) && $(GO_ENV) $(GO) run ./...


# ============================================================
# Build
# ============================================================

build: $(addprefix build-,$(SERVICES))

build-product:
	cd $(PRODUCT_DIR) && $(GO_ENV) $(GO) build $(GOFLAGS) -o bin/product ./...

build-counter:
	cd $(COUNTER_DIR) && $(GO_ENV) $(GO) build $(GOFLAGS) -o bin/counter ./...

build-barista:
	cd $(BARISTA_DIR) && $(GO_ENV) $(GO) build $(GOFLAGS) -o bin/barista ./...

build-kitchen:
	cd $(KITCHEN_DIR) && $(GO_ENV) $(GO) build $(GOFLAGS) -o bin/kitchen ./...

build-proxy:
	cd $(PROXY_DIR) && $(GO_ENV) $(GO) build $(GOFLAGS) -o bin/proxy ./...


# ============================================================
# Testing
# ============================================================

test:
	@set -e; \
	for service in $(SERVICES); do \
		echo "==> Testing $$service"; \
		cd $$(eval echo \$$(SERVICE_DIR_$$service)) && $(GO) test ./...; \
		cd - >/dev/null; \
	done

test-race:
	@set -e; \
	for service in $(SERVICES); do \
		echo "==> Race testing $$service"; \
		cd $$(eval echo \$$(SERVICE_DIR_$$service)) && $(GO) test -race ./...; \
		cd - >/dev/null; \
	done


# ============================================================
# Go Development
# ============================================================

fmt:
	@set -e; \
	for service in $(SERVICES); do \
		echo "==> Formatting $$service"; \
		cd $$(eval echo \$$(SERVICE_DIR_$$service)) && $(GO) fmt ./...; \
		cd - >/dev/null; \
	done

fmt-check:
	@set -e; \
	files="$$(find . -type f -name '*.go' \
		-not -path './vendor/*' \
		-not -path './.git/*')"; \
	unformatted="$$(gofmt -l $$files)"; \
	if [ -n "$$unformatted" ]; then \
		echo "The following files are not formatted:"; \
		echo "$$unformatted"; \
		exit 1; \
	fi

vet:
	@set -e; \
	for service in $(SERVICES); do \
		echo "==> Vetting $$service"; \
		cd $$(eval echo \$$(SERVICE_DIR_$$service)) && $(GO) vet ./...; \
		cd - >/dev/null; \
	done

tidy:
	@set -e; \
	for service in $(SERVICES); do \
		echo "==> Tidying $$service"; \
		cd $$(eval echo \$$(SERVICE_DIR_$$service)) && $(GO) mod tidy; \
		cd - >/dev/null; \
	done

check: fmt-check vet lint test


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

lint:
	$(GOLANGCI_LINT) run

linter-golangci: lint


# ============================================================
# Docker Compose
# ============================================================

docker-compose: docker-down docker-up

docker-up:
	$(DOCKER) compose up --build

docker-down:
	$(DOCKER) compose down --remove-orphans -v

docker-compose-core: docker-compose-core-stop docker-compose-core-start

docker-compose-core-start:
	$(DOCKER) compose -f docker-compose-core.yaml up --build -d

docker-compose-core-stop:
	$(DOCKER) compose -f docker-compose-core.yaml down --remove-orphans


# ============================================================
# Database Migrations
# ============================================================

check-env:
	@test -n "$(POSTGRES_USER)" || (echo "ERROR: POSTGRES_USER is required"; exit 1)
	@test -n "$(POSTGRES_PASSWORD)" || (echo "ERROR: POSTGRES_PASSWORD is required"; exit 1)
	@test -n "$(POSTGRES_HOST)" || (echo "ERROR: POSTGRES_HOST is required"; exit 1)
	@test -n "$(POSTGRES_PORT)" || (echo "ERROR: POSTGRES_PORT is required"; exit 1)
	@test -n "$(POSTGRES_DB)" || (echo "ERROR: POSTGRES_DB is required"; exit 1)
	@test -n "$(POSTGRES_SSLMODE)" || (echo "ERROR: POSTGRES_SSLMODE is required"; exit 1)

migrate-create:
	@test -n "$(NAME)" || (echo "ERROR: NAME is required. Example: make migrate-create NAME=add_users"; exit 1)
	$(MIGRATE) create -ext sql -dir $(MIGRATION_DIR) -seq "$(NAME)"

migrate-up: check-env
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		up

migrate-down: check-env
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		down 1

migrate-down-n: check-env
	@test -n "$(N)" || (echo "ERROR: N is required. Example: make migrate-down-n N=2"; exit 1)
	@test "$(N)" -gt 0 || (echo "ERROR: N must be greater than 0"; exit 1)
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		down "$(N)"

migrate-force: check-env
	@test -n "$(VERSION)" || (echo "ERROR: VERSION is required. Example: make migrate-force VERSION=1"; exit 1)
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		force "$(VERSION)"

migrate-goto: check-env
	@test -n "$(VERSION)" || (echo "ERROR: VERSION is required. Example: make migrate-goto VERSION=3"; exit 1)
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		goto "$(VERSION)"

migrate-drop: check-env
	$(MIGRATE) \
		-path $(MIGRATION_DIR) \
		-database "$(CONN_STRING)" \
		drop


# ============================================================
# Maintenance
# ============================================================

clean:
	rm -rf gen
	rm -rf $(addsuffix /bin,$(addprefix $(PRODUCT_DIR) ,))
	rm -rf $(PRODUCT_DIR)/bin
	rm -rf $(COUNTER_DIR)/bin
	rm -rf $(BARISTA_DIR)/bin
	rm -rf $(KITCHEN_DIR)/bin
	rm -rf $(PROXY_DIR)/bin
	$(GO) clean

.PHONY: dev-nomad
dev-nomad:
	bash ./scripts/dev/up.sh

.PHONY: dev-nomad-down
dev-nomad-down:
	bash ./scripts/dev/down.sh

.PHONY: dev-nomad-reset
dev-nomad-reset:
	bash ./scripts/dev/reset.sh

.PHONY: dev-nomad-verify
dev-nomad-verify:
	bash ./scripts/dev/verify.sh
