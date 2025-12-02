.PHONY: help up build restart validate-env show-env load-env

# Function to strip quotes from a value (handles both single and double quotes)
# Usage: $(call strip-quotes,"value") or $(call strip-quotes,'value')
define strip-quotes
$(shell echo $(1) | sed "s/^['\"]//" | sed "s/['\"]$$//")
endef

# Function to extract, strip, and export environment variables from .env file
define load-env
$(if $(wildcard ./.env), \
    $(eval $(shell awk -F= '!/^#/ && NF==2 { \
        key=$$1; \
        value=$$2; \
        gsub(/^[ \t]+|[ \t]+$$/, "", key); \
        gsub(/^[ \t]+|[ \t]+$$/, "", value); \
        gsub(/^["'\'']|["'\'']$$/, "", value); \
        print key " := " value "\n" \
    }' ./.env)) \
    $(eval export $(shell awk -F= '!/^#/ && NF==2 {key=$$1; gsub(/^[ \t]+|[ \t]+$$/, "", key); print key " "}' ./.env)) \
)
endef

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

# Build and start services
build: validate-env
	@if [ -f .env ]; then \
		export $$(awk -F= '!/^#/ && NF==2 { \
			key=$$1; \
			value=$$2; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			gsub(/^[ \t]+|[ \t]+$$/, "", value); \
			gsub(/^["'\'']|["'\'']$$/, "", value); \
			print key "=" value \
		}' .env | xargs); \
		docker compose up -d; \
	else \
		docker compose up -d; \
	fi

# Stop and remove services
stop:
	@docker compose down

# Restart services
restart: validate-env
	@if [ -f .env ]; then \
		export $$(awk -F= '!/^#/ && NF==2 { \
			key=$$1; \
			value=$$2; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			gsub(/^[ \t]+|[ \t]+$$/, "", value); \
			gsub(/^["'\'']|["'\'']$$/, "", value); \
			print key "=" value \
		}' .env | xargs); \
		docker compose down; \
		docker compose up -d; \
	else \
		docker compose down; \
		docker compose up -d; \
	fi

# Validate environment variables
validate-env:
	
	@if [ -f .env ]; then \
		export $$(awk -F= '!/^#/ && NF==2 { \
			key=$$1; \
			value=$$2; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			gsub(/^[ \t]+|[ \t]+$$/, "", value); \
			gsub(/^["'\'']|["'\'']$$/, "", value); \
			print key "=" value \
		}' .env | xargs); \
		if [ "$$ENABLE_SECURITY" = "true" ]; then \
			if [ -z "$$ELASTIC_PASSWORD" ]; then \
				echo "❌ Error: ELASTIC_PASSWORD is required when ENABLE_SECURITY=true"; \
				exit 1; \
			fi; \
		fi; \
		echo "✅ Validation: Environment variables are set"; \
	else \
		echo "⚠️  No .env file found."; \
		echo "   Environment variables will use defaults from docker-compose.yml"; \
	fi

# Show environment variables and their values
show-env:
	@echo "Environment variables from .env file:"
	@echo "-----------------------------------"
	@if [ -f .env ]; then \
		awk -F= '!/^#/ && NF==2 { \
			key=$$1; \
			value=$$2; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			gsub(/^[ \t]+|[ \t]+$$/, "", value); \
			gsub(/^["'\'']|["'\'']$$/, "", value); \
			if (key == "ELASTIC_PASSWORD") { \
				printf "  %-20s = %s\n", key, "***HIDDEN***"; \
			} else { \
				printf "  %-20s = %s\n", key, value; \
			} \
		}' .env; \
		echo ""; \
		export $$(awk -F= '!/^#/ && NF==2 { \
			key=$$1; \
			value=$$2; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			gsub(/^[ \t]+|[ \t]+$$/, "", value); \
			gsub(/^["'\'']|["'\'']$$/, "", value); \
			print key "=" value \
		}' .env | xargs); \
		if [ "$$ENABLE_SECURITY" = "true" ]; then \
			if [ -z "$$ELASTIC_PASSWORD" ]; then \
				echo "⚠️  Warning: ELASTIC_PASSWORD is not set (required when ENABLE_SECURITY=true)"; \
			else \
				echo "✅ Validation: ELASTIC_PASSWORD is set"; \
			fi; \
		else \
			echo "ℹ️  Security is disabled (ENABLE_SECURITY=false or not set)"; \
		fi; \
	else \
		echo "⚠️  No .env file found."; \
		echo "   Environment variables will use defaults from docker-compose.yml"; \
	fi

# Load environment variables from .env file
load-env:
	@if [ -f .env ]; then \
		echo "Loading environment variables from .env..."; \
		export $$(awk -F= '!/^#/ && NF==2 { \
			key=$$1; \
			value=$$2; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			gsub(/^[ \t]+|[ \t]+$$/, "", value); \
			gsub(/^["'\'']|["'\'']$$/, "", value); \
			print key "=" value \
		}' .env | xargs); \
		echo "Environment variables loaded. Run 'make build' or 'make restart' to use them."; \
	else \
		echo "No .env file found."; \
	fi
