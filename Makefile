.PHONY: help dev up down logs ps build clean migrate seed

# ─── Colors ───────────────────────────────────────────────────
CYAN  := \033[0;36m
RESET := \033[0m

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-15s$(RESET) %s\n", $$1, $$2}'

# ─── Local dev ────────────────────────────────────────────────
dev: ## Start all services in development mode
	docker compose up --build

up: ## Start all services (detached)
	docker compose up -d

down: ## Stop all services
	docker compose down

down-v: ## Stop all services and remove volumes
	docker compose down -v

logs: ## Tail logs (usage: make logs s=api)
	docker compose logs -f $(s)

ps: ## Show running containers
	docker compose ps

# ─── Build ────────────────────────────────────────────────────
build: ## Build all Docker images
	docker compose build

build-prod: ## Build production images
	docker compose -f docker-compose.yml -f docker-compose.staging.yml build

# ─── Database ─────────────────────────────────────────────────
migrate: ## Run Prisma migrations
	docker compose exec api npx prisma migrate dev

migrate-prod: ## Deploy migrations (no prompt)
	docker compose exec api npx prisma migrate deploy

seed: ## Seed the database
	docker compose exec api npx prisma db seed

studio: ## Open Prisma Studio
	npx prisma studio --schema packages/db/prisma/schema.prisma

# ─── Cleanup ──────────────────────────────────────────────────
clean: ## Remove containers, images, volumes
	docker compose down -v --rmi local
	docker builder prune -f

# ─── CI helpers ───────────────────────────────────────────────
lint: ## Run linter
	npx turbo run lint

test: ## Run tests
	npx turbo run test

typecheck: ## Run type checks
	npx turbo run typecheck
