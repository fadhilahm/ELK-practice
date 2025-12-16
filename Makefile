.PHONY: \
	help \
	up \
	build \
	restart \
	check-env \
	test-logstash \
	logstash-interactive \
	logstash-interactive-no-restart

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

# Test Logstash connectivity and functionality
test-logstash:
	@echo "=== Testing Logstash ==="
	@echo ""
	@echo "1. Checking Logstash health status..."
	@curl -s http://localhost:9600/_node/stats | jq '.' || echo "Logstash may not be running or jq is not installed"
	@echo ""
	@echo "2. Testing TCP input (port 5000)..."
	@echo "Sending test log via TCP..."
	@echo '{"message": "Test log from TCP", "timestamp": "'$$(date -Iseconds)'", "level": "INFO"}' | nc localhost 5000 || echo "Failed to send via TCP (nc may not be installed)"
	@echo "Log sent via TCP"
	@echo ""
	@echo "3. Testing UDP input (port 5000)..."
	@echo "Sending test log via UDP..."
	@sh -c 'echo "{\"message\": \"Test log from UDP\", \"timestamp\": \"$$(date -Iseconds)\", \"level\": \"INFO\"}" | (nc -u localhost 5000 & PID=$$!; sleep 0.2; kill $$PID 2>/dev/null || true)'
	@echo "Log sent via UDP"
	@echo ""
	@echo "4. Testing HTTP input (port 8080)..."
	@echo "Sending test log via HTTP..."
	@curl -s --max-time 2 -X POST http://localhost:8080 -H "Content-Type: application/json" -d "{\"message\": \"Test log from HTTP\", \"timestamp\": \"$$(date -Iseconds)\", \"level\": \"INFO\"}" 2>/dev/null || echo "HTTP test completed (timeout or connection issue)"
	@echo "Log sent via HTTP"
	@echo ""
	@echo "5. Checking Elasticsearch for recent logs..."
	@sleep 2
	@curl -s "http://localhost:9200/_cat/indices?v" | head -10
	@echo ""
	@echo "Searching for test logs..."
	@curl -s "http://localhost:9200/logstash-*/_search?q=*&size=5&sort=@timestamp:desc" | jq '.hits.hits[] | {timestamp: ._source["@timestamp"], message: ._source.message}' 2>/dev/null || echo "No logs found or jq not installed"
	@echo ""
	@echo "=== Test Complete ==="
	@echo ""
	@echo "To view logs in Kibana, go to: http://localhost:5601"
	@echo "To check Logstash logs: docker logs logstash"

# Run Logstash container in interactive mode (useful for testing stdin input or debugging)
logstash-interactive:
	@docker compose run --rm logstash

# Run Logstash container in interactive mode without restarting the container
logstash-interactive-no-restart:
	@docker compose exec logstash bash
