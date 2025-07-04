# Minecraft Bedrock Server Manager Makefile 2025

# Variables
BINARY_NAME = client
BUILD_DIR = cmd/client
MAIN_PATH = cmd/client/main.go
CONFIG_FILE = config.yaml
BRANCH_FILE = branch
VERSIONS_DIR = versions
BEDROCK_ARCHIVE = $(VERSIONS_DIR)/bedrock-server.zip

# Default target
.DEFAULT_GOAL := help

.PHONY: help clean docker-build docker-run docker-stop docker-clean branch-main branch-dev branch-staging branch-production bedrock-split bedrock-recombine bedrock-extract bedrock-clean bedrock-status config-check config-example status current-branch bedrock-setup

# Help target
help: ## Show this help message
	@echo "Minecraft Bedrock Server Manager"
	@echo "================================"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Branch Management:"
	@echo "  \033[36mbranch-main\033[0m        Switch to main branch"
	@echo "  \033[36mbranch-dev\033[0m         Switch to dev branch"
	@echo "  \033[36mbranch-staging\033[0m     Switch to staging branch"
	@echo "  \033[36mbranch-production\033[0m  Switch to production branch"
	@echo ""
	@echo "Bedrock Server Management:"
	@echo "  \033[36mbedrock-split\033[0m      Split Bedrock archive into 10 layers"
	@echo "  \033[36mbedrock-recombine\033[0m  Recombine layers into archive"
	@echo "  \033[36mbedrock-extract\033[0m    Extract recombined archive"
	@echo "  \033[36mbedrock-clean\033[0m      Clean Bedrock files and layers"
	@echo "  \033[36mbedrock-status\033[0m     Show Bedrock server status"
	@echo ""

# Clean build artifacts
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	@echo "Clean completed!"

# Docker commands
docker-build: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t minecraft-bedrock-manager .
	@echo "Docker image built successfully!"

docker-run: ## Run with Docker Compose
	@echo "Starting with Docker Compose..."
	docker-compose up --build

docker-stop: ## Stop Docker Compose
	@echo "Stopping Docker Compose..."
	docker-compose down

docker-clean: ## Clean Docker artifacts
	@echo "Cleaning Docker artifacts..."
	docker-compose down -v
	docker rmi minecraft-bedrock-manager 2>/dev/null || true
	@echo "Docker cleanup completed!"

# Branch management commands
branch-main: ## Switch to main branch
	@echo "main" > $(BRANCH_FILE)
	@echo "Switched to main branch"

branch-dev: ## Switch to dev branch
	@echo "dev" > $(BRANCH_FILE)
	@echo "Switched to dev branch"

branch-staging: ## Switch to staging branch
	@echo "staging" > $(BRANCH_FILE)
	@echo "Switched to staging branch"

branch-production: ## Switch to production branch
	@echo "production" > $(BRANCH_FILE)
	@echo "Switched to production branch"

# Bedrock server management commands
bedrock-split: ## Split Bedrock archive into 10 layers
	@echo "Splitting Bedrock server archive..."
	@if [ ! -f $(BEDROCK_ARCHIVE) ]; then \
		echo "Error: $(BEDROCK_ARCHIVE) not found"; \
		echo "Please place your Bedrock server archive in $(BEDROCK_ARCHIVE)"; \
		exit 1; \
	fi
	@mkdir -p $(VERSIONS_DIR)
	@echo "Archive size: $(shell stat -c%s $(BEDROCK_ARCHIVE)) bytes"
	@echo "Layer size: $(shell echo $$(($(shell stat -c%s $(BEDROCK_ARCHIVE)) / 10)) bytes"
	@echo "Splitting into 10 layers..."
	@split -b $$(($(shell stat -c%s $(BEDROCK_ARCHIVE)) / 10)) $(BEDROCK_ARCHIVE) $(VERSIONS_DIR)/bedrock-server.layer.
	@echo "Layers created:"
	@ls -la $(VERSIONS_DIR)/bedrock-server.layer.*

bedrock-recombine: ## Recombine layers into archive
	@echo "Recombining Bedrock server layers..."
	@if [ ! -f $(VERSIONS_DIR)/bedrock-server.layer.0 ]; then \
		echo "Error: No layer files found in $(VERSIONS_DIR)/"; \
		echo "Run 'make bedrock-split' first"; \
		exit 1; \
	fi
	@cat $(VERSIONS_DIR)/bedrock-server.layer.* > $(VERSIONS_DIR)/bedrock-server-recombined.zip
	@echo "Archive recombined: $(VERSIONS_DIR)/bedrock-server-recombined.zip"
	@echo "Size: $(shell stat -c%s $(VERSIONS_DIR)/bedrock-server-recombined.zip) bytes"

bedrock-extract: ## Extract recombined archive
	@echo "Extracting Bedrock server archive..."
	@if [ ! -f $(VERSIONS_DIR)/bedrock-server-recombined.zip ]; then \
		echo "Error: Recombined archive not found"; \
		echo "Run 'make bedrock-recombine' first"; \
		exit 1; \
	fi
	@rm -rf bedrock-server-extracted
	@mkdir -p bedrock-server-extracted
	@echo "Extracting zip archive..."
	@if unzip -o $(VERSIONS_DIR)/bedrock-server-recombined.zip -d bedrock-server-extracted 2>/dev/null; then \
		echo "Extracted with unzip"; \
	else \
		echo "zip extraction failed, trying tar.gz..."; \
		if tar -xzf $(VERSIONS_DIR)/bedrock-server-recombined.zip -C bedrock-server-extracted 2>/dev/null; then \
			echo "Extracted with tar.gz"; \
		else \
			echo "Failed to extract archive. Trying to find bedrock_server executable..."; \
			if find bedrock-server-extracted -name "bedrock_server" -type f 2>/dev/null; then \
				echo "Found bedrock_server executable"; \
			else \
				echo "No bedrock_server executable found in extracted files"; \
			fi; \
		fi; \
	fi
	@if [ -f bedrock-server-extracted/bedrock_server ]; then \
		chmod +x bedrock-server-extracted/bedrock_server; \
		echo "Made bedrock_server executable"; \
	fi

bedrock-clean: ## Clean Bedrock files and layers
	@echo "Cleaning Bedrock server files..."
	@rm -f $(VERSIONS_DIR)/bedrock-server.layer.* 2>/dev/null || true
	@rm -f $(VERSIONS_DIR)/bedrock-server-recombined.zip 2>/dev/null || true
	@rm -rf bedrock-server-extracted 2>/dev/null || true
	@echo "Bedrock files cleaned"

bedrock-status: ## Show Bedrock server status
	@echo "Bedrock Server Status"
	@echo "===================="
	@echo "Original archive: $(shell [ -f $(BEDROCK_ARCHIVE) ] && echo "Yes ($(shell stat -c%s $(BEDROCK_ARCHIVE)) bytes)" || echo "No")"
	@echo "Layer files: $(shell ls $(VERSIONS_DIR)/bedrock-server.layer.* 2>/dev/null | wc -l | tr -d ' ') / 10"
	@echo "Recombined archive: $(shell [ -f $(VERSIONS_DIR)/bedrock-server-recombined.zip ] && echo "Yes ($(shell stat -c%s $(VERSIONS_DIR)/bedrock-server-recombined.zip) bytes)" || echo "No")"
	@echo "Extracted directory: $(shell [ -d bedrock-server-extracted ] && echo "Yes" || echo "No")"
	@echo "Executable: $(shell [ -f bedrock-server-extracted/bedrock_server ] && echo "Yes (executable)" || echo "No")"

# Configuration commands
config-check: ## Check configuration file
	@echo "Checking configuration..."
	@if [ -f $(CONFIG_FILE) ]; then \
		echo "Configuration file exists: $(CONFIG_FILE)"; \
		echo "Current settings:"; \
		grep -E "^(github|http|server):" $(CONFIG_FILE) || echo "No settings found"; \
	else \
		echo "Configuration file not found: $(CONFIG_FILE)"; \
		echo "Please create $(CONFIG_FILE) with your settings"; \
	fi

config-example: ## Create example configuration
	@echo "Creating example configuration..."
	@if [ ! -f $(CONFIG_FILE) ]; then \
		cp example-servers.yaml servers-example.yaml; \
		echo "Created servers-example.yaml"; \
		echo "Please copy and modify config.yaml from the example"; \
	else \
		echo "Configuration file already exists: $(CONFIG_FILE)"; \
	fi

# Status commands
status: ## Show application status
	@echo "Application Status"
	@echo "=================="
	@echo "Binary exists: $(shell [ -f $(BUILD_DIR)/$(BINARY_NAME) ] && echo "Yes" || echo "No")"
	@echo "Config exists: $(shell [ -f $(CONFIG_FILE) ] && echo "Yes" || echo "No")"
	@echo "Branch file: $(shell [ -f $(BRANCH_FILE) ] && echo "Yes ($(shell cat $(BRANCH_FILE)))" || echo "No (using default)")"
	@echo "Docker image: $(shell docker images minecraft-bedrock-manager 2>/dev/null | grep -q minecraft-bedrock-manager && echo "Yes" || echo "No")"
	@echo ""
	@$(MAKE) bedrock-status

# Show current branch
current-branch: ## Show current branch configuration
	@echo "Current branch configuration:"
	@if [ -f $(BRANCH_FILE) ]; then \
		echo "Branch file: $(shell cat $(BRANCH_FILE))"; \
	else \
		echo "No branch file found, using default from config.yaml"; \
	fi

# Complete Bedrock setup
bedrock-setup: bedrock-split bedrock-recombine bedrock-extract ## Complete Bedrock server setup
	@echo "Bedrock server setup completed!"
	@echo "Executable ready: bedrock-server-extracted/bedrock_server" 