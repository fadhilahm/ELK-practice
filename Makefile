.PHONY: help up build restart check-env

# Load .env file if it exists and export variables
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Colors for formatting
YELLOW := \033[33m
CYAN := \033[36m
RESET := \033[0m

# Show available commands and their descriptions
help:
	@printf "\nUsage: make ${CYAN}[target]${RESET}\n\nTargets:\n"
	@awk '/^[a-zA-Z0-9_-]+:/ { \
		helpMessage = match(lastLine, /^# (.*)/); \
		if (helpMessage) { \
			target = substr($$1, 0, index($$1, ":")); \
			printf "  ${YELLOW}%-10s${RESET} %s\n", target, substr(lastLine, RSTART + 2, RLENGTH); \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@printf "\n${CYAN}Security Configuration:${RESET}\n"
	@printf "  To enable security, create a ${YELLOW}.env${RESET} file with:\n"
	@printf "    ${YELLOW}ENABLE_SECURITY=true${RESET}\n"
	@printf "    ${YELLOW}ELASTIC_PASSWORD=your_password${RESET} (required when security enabled)\n"
	@printf "    ${YELLOW}ELASTICSEARCH_USERNAME=elastic${RESET} (optional, defaults to 'elastic')\n"
	@printf "\n  If ${YELLOW}ENABLE_SECURITY${RESET} is not set or set to false, security is disabled.\n"
	@printf "  The ${YELLOW}.env${RESET} file is gitignored for security.\n\n"

# Build and start services
build:
	@make check-env
	@docker compose up -d

# Stop and remove services
stop:
	@docker compose down

# Restart services
restart:
	@docker compose down
	@make check-env
	@docker compose up -d

# Check if required environment variables are set (only when security is enabled)
check-env:
	@echo "Checking environment configuration..."
	@SECURITY_ENABLED=$$(echo $$ENABLE_SECURITY | tr -d '"'); \
	if [ "$$SECURITY_ENABLED" = "true" ]; then \
		echo "Security is enabled. Validating environment variables..."; \
		PASSWORD=$$(echo $$ELASTIC_PASSWORD | tr -d '"'); \
		if [ -z "$$PASSWORD" ]; then \
			echo "Error: ELASTIC_PASSWORD is required when ENABLE_SECURITY=true"; \
			exit 1; \
		fi; \
		USERNAME=$$(echo $$ELASTICSEARCH_USERNAME | tr -d '"'); \
		if [ -z "$$USERNAME" ]; then \
			echo "Warning: ELASTICSEARCH_USERNAME is not set, will default to 'elastic'"; \
		fi; \
		echo "✓ Environment variables validated successfully"; \
	else \
		echo "Security is disabled (ENABLE_SECURITY is not 'true')"; \
	fi
