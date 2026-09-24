.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: test-contracts
test-contracts: ## Run contract validation tests
	pytest contracts/tests/ -v

.PHONY: test-dbt
test-dbt: ## Compile dbt DAG, build models, run snapshot checks, and validate tests
	mkdir -p .tmp
	cd dbt_transforms && dbt deps --profiles-dir . && dbt compile --profiles-dir . && dbt run --select path:models/silver --profiles-dir . && dbt snapshot --profiles-dir . && dbt run --select path:models/gold --profiles-dir . && dbt test --profiles-dir .

.PHONY: validate-tf
validate-tf: ## Validate Terraform modules
	cd terraform/modules/compute_warehouse && terraform init -backend=false && terraform validate

.PHONY: verify-all
verify-all: test-contracts test-dbt validate-tf ## Run all verification steps
	@echo "All architectural assertions, models, and IaC patterns verified successfully."
