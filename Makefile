# Development Database Commands
postgres:
	docker run --name postgres12 -e POSTGRES_PASSWORD=secret -e POSTGRES_USER=root -p 5432:5432 -d postgres:15-alpine

createdb:
	docker exec -it postgres12 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres12 dropdb simple_bank

# Migration Commands
migrateup:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose down

# CI Migration (uses environment variable for flexibility)
migrateup-ci:
	migrate -path db/migration -database "$(DB_URL)" -verbose up

# Code Generation
sqlc:
	sqlc generate

# Testing Commands
test:
	go test -v -cover ./...

test-race:
	go test -race -short ./...

test-coverage:
	go test -v -cover -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Code Quality Commands
lint:
	golangci-lint run

lint-fix:
	golangci-lint run --fix

# Security Commands
security:
	gosec ./...

security-report:
	gosec -fmt sarif -out gosec-report.sarif ./...

# Build Commands
build:
	go build -o bin/main .

build-linux:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Docker Commands
docker-build:
	docker build -t bank-microservice .

docker-run:
	docker run -p 8080:8080 bank-microservice

# Utility Commands
clean:
	rm -rf bin/ coverage.out coverage.html gosec-report.sarif

deps:
	go mod download
	go mod tidy

# Setup Commands for CI
setup-tools:
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
	go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.54.2

# CI Commands
ci-test: deps sqlc test test-race

ci-quality: lint security

ci-build: build-linux

ci: ci-quality ci-test ci-build

# Help Command
help:
	@echo "Available commands:"
	@echo "  Development:"
	@echo "    postgres     - Start PostgreSQL container"
	@echo "    createdb     - Create database"
	@echo "    migrateup    - Run database migrations"
	@echo "    sqlc         - Generate SQLC code"
	@echo "  Testing:"
	@echo "    test         - Run tests with coverage"
	@echo "    test-race    - Run race condition tests"
	@echo "  Quality:"
	@echo "    lint         - Run linter"
	@echo "    security     - Run security scan"
	@echo "  Build:"
	@echo "    build        - Build binary"
	@echo "    docker-build - Build Docker image"
	@echo "  CI:"
	@echo "    ci           - Run full CI pipeline locally"

.PHONY: postgres createdb dropdb migrateup migratedown migrateup-ci sqlc test test-race test-coverage lint lint-fix security security-report build build-linux docker-build docker-run clean deps setup-tools ci-test ci-quality ci-build ci help