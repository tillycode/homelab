##@ Utility
.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


ANSI_GREEN := \033[0;32m
ANSI_RESET := \033[0m

define message
	@echo -e "$(ANSI_GREEN)> $(1)$(ANSI_RESET)"
endef

##@ Generate

##@ Deployment
.PHONY: deploy-local
deploy-local: ## Build and deploy the local machine
	$(call message, Building and deploying to $$(hostname))
	nixos-rebuild switch --flake ".#$$(hostname)" --use-remote-sudo
