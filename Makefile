

BROKER_BINARY=brokerApp
AUTH_BINARY=authApp
SERVICE_BINARY=serviceApp

# Images name to be pushed to docker hub
AUTHENTICATION_IMAGE := biostech/polygon-swiftlink-authentication-service:1.0.0
BROKER_IMAGE := biostech/polygon-swiftlink-broker-service:1.0.0
SERVICE_IMAGE := biostech/polygon-swiftlink-api-service:1.0.0

# up: starts all containers in the background without forcing build
up: ## Start all containers in the background without forcing build
	@echo "Starting Docker images..."
	docker compose up -d
	@echo "Docker images started!"

# down: stop docker compose
down: ## Stop Docker Compose
	@echo "Stopping Docker Compose..."
	docker compose down
	@echo "Done!"

# up_build: stops docker compose (if running), builds all projects and starts docker compose
up_build: build_broker_service build_auth_service build_service_api ## Stop, build, and start Docker Compose
	@echo "Stopping Docker images (if running...)"
	docker compose down
	@echo "Building (when required) and starting Docker images..."
	docker compose up --build
	@echo "Docker images built and started!"

# build_service: builds the main service api binary as a linux executable
build_service_api: ## Build the main service api service binary
	@echo "Building service api binary..."
	@cd ../polygon_swiftlink_services_api && env GOOS=linux CGO_ENABLED=0 go build -o ${SERVICE_BINARY} ./cmd/api
	@echo "Done!"


# build_broker_service: builds the broker binary as a linux executable
build_broker_service: ## Build the broker service binary
	@echo "Building broker service binary..."
	@cd ../polygon_swiftlink_broker_api && env GOOS=linux CGO_ENABLED=0 go build -o ${BROKER_BINARY} ./cmd/api
	@echo "Done!"


# build_auth_service: builds the auth binary as a linux executable
build_auth_service: ## Build the authentication service binary
	@echo "Building logging service binary..."
	@cd ../polygon_swiftlink_auth_api && env GOOS=linux CGO_ENABLED=0 go build -o ${AUTH_BINARY} ./cmd/api
	@echo "Done!"


# push_authentication_service: push authentication service to docker hub
build_push_authentication_service: ## Push the authentication service to Docker Hub
	cd ../build_auth_service/ && docker build --no-cache -f Dockerfile -t $(AUTHENTICATION_IMAGE) . && docker push $(AUTHENTICATION_IMAGE)

# push_broker_service: push broker service to docker hub
build_push_broker_service: ## Push the broker service to Docker Hub
	cd ../polygon_swiftlink_broker_api/ && docker build --no-cache -f Dockerfile -t $(BROKER_IMAGE) . && docker push $(BROKER_IMAGE)

# push_api_service: push main service api to docker hub
build_push_api_service: ## Push the main service api to Docker Hub
	cd ../polygon_swiftlink_services_api/ && docker build --no-cache -f Dockerfile -t $(SERVICE_IMAGE) . && docker push $(SERVICE_IMAGE)


# build_push: push all images to docker hub
build_push: build_push_authentication_service   build_push_broker_service build_push_api_service ## Build and push all images to Docker Hub
	@echo "Building and pushing updated images"

# migrate_up_local: apply all migrations locally
migrate_up_local: ## Apply all migrations locally
	migrate -path ../polygon_swiftlink_db_migrations/migrations -database "postgresql://admin:password@localhost:5432/polygon_swiftlink_db?sslmode=disable" -verbose up

# migrate_down_local: rollback all migrations locally
migrate_down_local: ## Rollback all migrations locally
	migrate -path ../polygon_swiftlink_db_migrations/migrations -database "postgresql://admin:password@localhost:5432/polygon_swiftlink_db?sslmode=disable" -verbose down

# migrate_down_last_local: rollback the last migration locally
migrate_down_last_local: ## Rollback the last migration locally
	migrate -path ../polygon_swiftlink_db_migrations/migrations -database "postgresql://admin:password@localhost:5432/polygon_swiftlink_db?sslmode=disable" -verbose down 1

# dropdb: drop the database
dropdb: ## Drop the database
	docker exec -it postgres dropdb -U admin polygon_swiftlink_db

# createdb: create the database
createdb: ## Create the database
	docker exec -it postgres createdb --username=admin --owner=admin polygon_swiftlink_db

# migrate: create a new migration file e.g make migrate schema=<migration_name>
MIGRATE_CMD = migrate create -ext sql -dir ../polygon_swiftlink_db_migrations/migrations -seq
migrate: ## Create a new migration file e.g make migrate schema=<migration_name>
	@$(MIGRATE_CMD) $(schema)

# Variables
BRANCH ?= main

# make commit_name message="commit message"
# commit_broker: pushes broker service to github
commit_broker: ## commit_broker: pushes broker service to github
	@if [ "$(message)" = "" ]; then echo "Commit message required"; exit 1; fi
	@cd ../polygon_swiftlink_broker_api && git status
	@cd ../polygon_swiftlink_broker_api && git add .
	@cd ../polygon_swiftlink_broker_api && git commit -m "$(message)"
	@cd ../polygon_swiftlink_broker_api && git push origin $(BRANCH)

# commit_auth: pushes auth service to github
commit_auth: ## commit_auth: pushes auth service to github
	@if [ "$(message)" = "" ]; then echo "Commit message required"; exit 1; fi
	@cd ../polygon_swiftlink_auth_api && git status
	@cd ../polygon_swiftlink_auth_api && git add .
	@cd ../polygon_swiftlink_auth_api && git commit -m "$(message)"
	@cd ../polygon_swiftlink_auth_api && git push origin $(BRANCH)

# commit_main_api_service: pushes main_api_service service to github
commit_service_api: ## commit_main_api_service: pushes main_api_service to github
	@if [ "$(message)" = "" ]; then echo "Commit message required"; exit 1; fi
	@cd ../polygon_swiftlink_services_api && git status
	@cd ../polygon_swiftlink_services_api && git add .
	@cd ../polygon_swiftlink_services_api && git commit -m "$(message)"
	@cd ../polygon_swiftlink_services_api && git push origin $(BRANCH)

# commit_mobile: pushes polygon_swiftlink_mobile app to github
commit_mobile: ## commit_mobile: pushes polygon_swiftlink_mobile to github
	@if [ "$(message)" = "" ]; then echo "Commit message required"; exit 1; fi
	@cd ../polygon_swiftlink_mobile && git status
	@cd ../polygon_swiftlink_mobile && git add .
	@cd ../polygon_swiftlink_mobile && git commit -m "$(message)"
	@cd ../polygon_swiftlink_mobile && git push origin $(BRANCH)

# commit_db: push project database sql to github
commit_db: ## commit_db: push project database sql to github
	@if [ "$(message)" = "" ]; then echo "Commit message required"; exit 1; fi
	@cd ../polygon_swiftlink_db_migrations && git status
	@cd ../polygon_swiftlink_db_migrations && git add .
	@cd ../polygon_swiftlink_db_migrations && git commit -m "$(message)"
	@cd ../polygon_swiftlink_db_migrations && git push origin $(BRANCH)

# commit_setup: push project setup to github
commit_setup: ## push project setup to github
	@if [ "$(message)" = "" ]; then echo "Commit message required"; exit 1; fi
	@git status
	@git add .
	@git commit -m "$(message)"
	@git push origin $(BRANCH)

# help: list all make commands
help: ## Show this help
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-30s %s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: migrate createdb dropdb migrate_down_last_local migrate_down_local migrate_up_local build_push build_service_api \
		build_broker_service build_broker_service build_auth_service build_push_authentication_service build_push_broker_service \
		build_push_api_service commit_setup commit_db commit_service_api commit_auth commit_broker 

		




#----------------------------------------Kubernetes commands-----------------------------------------------#
# encode a secret - base64: echo -n 'redis' | base64
# decode a secret - base64: echo 'cmVkaXMuCg==' | base64 --decode; echo
# decode a secret - kubectl: kubectl get secret secret -o jsonpath="{.data.REDIS_URL}" | base64 --decode




#------------------------------------Packages installed for react-native app-----------------------------------------#
#1. create reat-app - expo init my-new-project
#2. react-navigation   https://reactnavigation.org/docs/getting-started
#3. screen components get {route, navigation } props automatically
#4. icons -  https://docs.expo.dev/guides/icons/
# cd cmp/api go test -v .