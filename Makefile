.PHONY: help up build restart validate-env show-env load-env reset-password create-enrollment-token

# Function to strip quotes from a value (handles both single and double quotes)
# Usage: $(call strip-quotes,"value") or $(call strip-quotes,'value')
define strip-quotes
$(shell echo $(1) | sed "s/^['\"]//" | sed "s/['\"]$$//")
endef

# Function to extract, strip, and export environment variables from .env file
define load-env
$(if $(wildcard ./.env), \
    $(eval $(shell awk -F= '!/^#/ && NF>=2 { \
        key=$$1; \
        gsub(/^[ \t]+|[ \t]+$$/, "", key); \
        if (key != "") { \
            value=substr($$0, index($$0, "=") + 1); \
            gsub(/^[ \t]+|[ \t]+$$/, "", value); \
            gsub(/^["'\'']|["'\'']$$/, "", value); \
            print key " := " value "\n" \
        } \
    }' ./.env)) \
    $(eval export $(shell awk -F= '!/^#/ && NF>=2 { \
        key=$$1; \
        gsub(/^[ \t]+|[ \t]+$$/, "", key); \
        if (key != "") { \
            print key " " \
        } \
    }' ./.env)) \
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
		export $$(awk -F= '!/^#/ && NF>=2 { \
			key=$$1; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			if (key != "") { \
				value=substr($$0, index($$0, "=") + 1); \
				gsub(/^[ \t]+|[ \t]+$$/, "", value); \
				gsub(/^["'\'']|["'\'']$$/, "", value); \
				print key "=" value \
			} \
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
		export $$(awk -F= '!/^#/ && NF>=2 { \
			key=$$1; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			if (key != "") { \
				value=substr($$0, index($$0, "=") + 1); \
				gsub(/^[ \t]+|[ \t]+$$/, "", value); \
				gsub(/^["'\'']|["'\'']$$/, "", value); \
				print key "=" value \
			} \
		}' .env | xargs); \
		docker compose down; \
		docker compose up -d; \
	else \
		docker compose down; \
		docker compose up -d; \
	fi

# Validate environment variables
# Add validation rules below - each rule checks a variable with an optional condition
# To add a new rule, add: if [ condition ]; then check_var "VAR_NAME" "description"; fi
validate-env:
	@if [ -f .env ]; then \
		export $$(awk -F= '!/^#/ && NF>=2 { \
			key=$$1; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			if (key != "") { \
				value=substr($$0, index($$0, "=") + 1); \
				gsub(/^[ \t]+|[ \t]+$$/, "", value); \
				gsub(/^["'\'']|["'\'']$$/, "", value); \
				print key "=" value \
			} \
		}' .env | xargs); \
		errors=0; \
		check_var() { \
			var_name=$$1; \
			description=$$2; \
			var_value=$$(eval echo \$$$$var_name); \
			if [ -z "$$var_value" ]; then \
				if [ -n "$$description" ]; then \
					echo "❌ Error: $$var_name is required ($$description)"; \
				else \
					echo "❌ Error: $$var_name is required"; \
				fi; \
				errors=$$((errors + 1)); \
			fi; \
		}; \
		if [ "$$ENABLE_SECURITY" = "true" ]; then \
			check_var "ELASTIC_PASSWORD" "required when ENABLE_SECURITY=true"; \
			check_var "KIBANA_PASSWORD" "required when ENABLE_SECURITY=true"; \
		fi; \
		if [ $$errors -gt 0 ]; then \
			exit 1; \
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
		awk -F= '!/^#/ && NF>=2 { \
			key=$$1; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			if (key != "") { \
				value=substr($$0, index($$0, "=") + 1); \
				gsub(/^[ \t]+|[ \t]+$$/, "", value); \
				gsub(/^["'\'']|["'\'']$$/, "", value); \
				if (key == "ELASTIC_PASSWORD" || key == "KIBANA_PASSWORD") { \
					printf "  %-20s = %s\n", key, "***HIDDEN***"; \
				} else { \
					printf "  %-20s = %s\n", key, value; \
				} \
			} \
		}' .env; \
		echo ""; \
		export $$(awk -F= '!/^#/ && NF>=2 { \
			key=$$1; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			if (key != "") { \
				value=substr($$0, index($$0, "=") + 1); \
				gsub(/^[ \t]+|[ \t]+$$/, "", value); \
				gsub(/^["'\'']|["'\'']$$/, "", value); \
				print key "=" value \
			} \
		}' .env | xargs); \
		warnings=0; \
		validated=0; \
		check_var() { \
			var_name=$$1; \
			description=$$2; \
			var_value=$$(eval echo \$$$$var_name); \
			if [ -z "$$var_value" ]; then \
				if [ -n "$$description" ]; then \
					echo "⚠️  Warning: $$var_name is not set ($$description)"; \
				else \
					echo "⚠️  Warning: $$var_name is not set"; \
				fi; \
				warnings=$$((warnings + 1)); \
			else \
				echo "✅ Validation: $$var_name is set"; \
				validated=$$((validated + 1)); \
			fi; \
		}; \
		if [ "$$ENABLE_SECURITY" = "true" ]; then \
			check_var "ELASTIC_PASSWORD" "required when ENABLE_SECURITY=true"; \
			check_var "KIBANA_PASSWORD" "required when ENABLE_SECURITY=true"; \
		fi; \
		if [ "$$ENABLE_SECURITY" != "true" ]; then \
			echo "ℹ️  Security is disabled (ENABLE_SECURITY=false or not set)"; \
		fi; \
		if [ $$validated -gt 0 ] && [ $$warnings -eq 0 ]; then \
			echo "✅ All required environment variables are properly set"; \
		fi; \
	else \
		echo "⚠️  No .env file found."; \
		echo "   Environment variables will use defaults from docker-compose.yml"; \
	fi

# Load environment variables from .env file
load-env:
	@if [ -f .env ]; then \
		echo "Loading environment variables from .env..."; \
		export $$(awk -F= '!/^#/ && NF>=2 { \
			key=$$1; \
			gsub(/^[ \t]+|[ \t]+$$/, "", key); \
			if (key != "") { \
				value=substr($$0, index($$0, "=") + 1); \
				gsub(/^[ \t]+|[ \t]+$$/, "", value); \
				gsub(/^["'\'']|["'\'']$$/, "", value); \
				print key "=" value \
			} \
		}' .env | xargs); \
		echo "Environment variables loaded. Run 'make build' or 'make restart' to use them."; \
	else \
		echo "No .env file found."; \
	fi

# Reset Elasticsearch password for the elastic user
reset-password:
	@if ! docker compose ps elasticsearch | grep -q "Up"; then \
		echo "❌ Error: Elasticsearch container is not running. Start it with 'make build' first."; \
		exit 1; \
	fi
	@echo "Resetting password for elastic user in Elasticsearch container..."
	@docker compose exec elasticsearch ./bin/elasticsearch-reset-password -u elastic --silent | tee password-reset.log
	@cat password-reset.log | pbcopy
	@echo "Password reset successfully! Output saved to password-reset.log and copied to clipboard"
	@rm -f password-reset.log

# Create enrollment token for elastic user in Elasticsearch container
create-enrollment-token:
	@if ! docker compose ps elasticsearch | grep -q "Up"; then \
		echo "❌ Error: Elasticsearch container is not running. Start it with 'make build' first."; \
		exit 1; \
	fi
	@echo "Creating enrollment token for elastic user in Elasticsearch container..."
	@docker compose exec elasticsearch ./bin/elasticsearch-create-enrollment-token -s kibana -u elastic --silent | tee enrollment-token.log
	@cat enrollment-token.log | pbcopy
	@echo "Enrollment token created successfully! Output saved to enrollment-token.log and copied to clipboard"
	@rm -f enrollment-token.log
