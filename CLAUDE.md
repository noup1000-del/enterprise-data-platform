1. Granular Contract Tests with Dedicated Failure Fixtures
Instead of collapsing errors into a dictionary where multiple field errors overwrite each other, the test suite introduces isolated negative fixtures where each test proves one explicit failure mode.

Directory Layout
Plaintext
contracts/
├── erp_orders.contract.yaml
└── tests/
    ├── fixtures/
    │   ├── valid_order.json
    │   ├── missing_required_field.json
    │   ├── invalid_enum.json
    │   ├── invalid_numeric_range.json
    │   └── invalid_datetime.json
    └── test_erp_orders_contract.py
Fixture Examples
contracts/tests/fixtures/missing_required_field.json

JSON
{
  "order_id": "ORD-109283",
  "order_status": "FULFILLED",
  "currency": "EUR",
  "order_total": 482.50,
  "order_timestamp": "2026-09-23T14:15:00Z"
}
contracts/tests/fixtures/invalid_enum.json

JSON
{
  "order_id": "ORD-109283",
  "customer_id": "CUST-44021",
  "order_status": "DISPATCHED_NEW",
  "currency": "EUR",
  "order_total": 482.50,
  "order_timestamp": "2026-09-23T14:15:00Z"
}
contracts/tests/fixtures/invalid_numeric_range.json

JSON
{
  "order_id": "ORD-109283",
  "customer_id": "CUST-44021",
  "order_status": "FULFILLED",
  "currency": "EUR",
  "order_total": -15.00,
  "order_timestamp": "2026-09-23T14:15:00Z"
}
contracts/tests/fixtures/invalid_datetime.json

JSON
{
  "order_id": "ORD-109283",
  "customer_id": "CUST-44021",
  "order_status": "FULFILLED",
  "currency": "EUR",
  "order_total": 482.50,
  "order_timestamp": "2026-09-23 14:15:00"
}
contracts/tests/test_erp_orders_contract.py
Python
import json
from pathlib import Path
import pytest
import yaml
from jsonschema import Draft7Validator, FormatChecker

CONTRACT_PATH = Path(__file__).resolve().parent.parent / "erp_orders.contract.yaml"
FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures"

@pytest.fixture(scope="module")
def contract_spec():
    with open(CONTRACT_PATH, "r", encoding="utf-8") as f:
        spec = yaml.safe_load(f)
    assert spec["contract_version"] == "1.0.0"
    assert "schema" in spec
    return spec

@pytest.fixture(scope="module")
def schema_validator(contract_spec):
    schema = contract_spec["schema"]
    Draft7Validator.check_schema(schema)
    return Draft7Validator(schema, format_checker=FormatChecker())

def load_fixture(fixture_name: str) -> dict:
    with open(FIXTURES_DIR / fixture_name, "r", encoding="utf-8") as f:
        return json.load(f)

def test_contract_accepts_valid_payload(schema_validator):
    payload = load_fixture("valid_order.json")
    errors = list(schema_validator.iter_errors(payload))
    assert errors == [], f"Expected 0 errors, got: {[e.message for e in errors]}"

def test_contract_rejects_missing_required_field(schema_validator):
    payload = load_fixture("missing_required_field.json")
    errors = list(schema_validator.iter_errors(payload))
    messages = [e.message for e in errors]
    assert any("'customer_id' is a required property" in msg for msg in messages)

def test_contract_rejects_invalid_enum(schema_validator):
    payload = load_fixture("invalid_enum.json")
    errors = list(schema_validator.iter_errors(payload))
    failed_paths = [e.path[0] for e in errors if e.path]
    assert "order_status" in failed_paths
    assert any("DISPATCHED_NEW" in e.message for e in errors)

def test_contract_rejects_invalid_numeric_range(schema_validator):
    payload = load_fixture("invalid_numeric_range.json")
    errors = list(schema_validator.iter_errors(payload))
    failed_paths = [e.path[0] for e in errors if e.path]
    assert "order_total" in failed_paths
    assert any("less than the minimum of 0" in e.message for e in errors)

def test_contract_rejects_invalid_datetime_format(schema_validator):
    payload = load_fixture("invalid_datetime.json")
    errors = list(schema_validator.iter_errors(payload))
    failed_paths = [e.path[0] for e in errors if e.path]
    assert "order_timestamp" in failed_paths
    assert any("is not a 'date-time'" in e.message for e in errors)
2. Defensible Portability Matrix & Principle
Updated the portability matrix and principles to reflect real-world dbt usage (dbt abstractions and adapter dependencies rather than literal "100% ANSI SQL").

Markdown
### Implementation Portability Matrix

| Architectural Tier | Local Reference (`duckdb`) | Target Cloud Warehouse | Portability Classification |
|---|---|---|---|
| **Contract Ingestion Gate** | Python `jsonschema` Draft 7 | Cloud Function / Ingestion Worker | **Shared Logic** (Vendor-agnostic) |
| **Silver Normalization** | dbt models + SQL CTEs | dbt models + SQL CTEs | **High Portability** (ANSI-aligned dbt SQL) |
| **Gold Dimensional Facts** | Star Schema Surrogates & Measures | Star Schema Surrogates & Measures | **High Portability** (ANSI-aligned dbt SQL) |
| **SCD Type 2 Snapshots** | `dbt snapshot` via DuckDB adapter | `dbt snapshot` via Warehouse adapter | **dbt-Managed** (Adapter-dependent DDL) |
| **Compute / Storage Isolation**| In-process single-thread engine | Virtual Warehouse compute tiers | **Engine-Specific** (Terraform infrastructure) |
Portability Principle: Core transformation models are written in portable dbt SQL designed for broad ANSI SQL compliance, isolating adapter-specific syntax to configuration blocks and target macros.

3. Tested Provider Pinning in Terraform (terraform/modules/compute_warehouse/main.tf)
Updated to the official snowflakedb/snowflake provider, pinned to a tested version, and explicitly labeled as a representative infrastructure pattern.

Terraform
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    # Representative enterprise cloud infrastructure pattern
    # Tested against official Snowflake provider v2.x
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.21"
    }
  }
}

# ------------------------------------------------------------------------------
# Workload-Isolated Compute Clusters
# Demonstrates architectural pattern for segregating batch ETL transformations
# from high-concurrency BI ad-hoc workloads with automated FinOps auto-suspend.
# ------------------------------------------------------------------------------

resource "snowflake_warehouse" "etl_transformation_wh" {
  name                = "WH_TRANSFORMATION_${upper(var.environment)}"
  warehouse_size      = var.etl_warehouse_size
  auto_suspend        = 60 # Aggressive auto-suspend for batch FinOps efficiency
  auto_resume         = true
  initially_suspended = true
  comment             = "Dedicated compute cluster for dbt Medallion batch transformations."
}

resource "snowflake_warehouse" "bi_serving_wh" {
  name                = "WH_BI_SERVING_${upper(var.environment)}"
  warehouse_size      = var.bi_warehouse_size
  auto_suspend        = 300 # 5-minute buffer to maintain warm query caches for BI dashboards
  auto_resume         = true
  initially_suspended = true
  comment             = "Dedicated compute cluster for BI tools and self-serve ad-hoc reporting."
}
4. Complete, Portfolio-Ready README.md
Markdown
# Enterprise Data Platform Reference Architecture: Medallion Storage, Data Contracts & Kimball Modeling

[![IaC: Terraform](https://img.shields.io/badge/IaC-Terraform_1.5+-623CE4.svg)](terraform/)
[![Engine: dbt](https://img.shields.io/badge/Modeling-dbt_Core-FF694B.svg)](dbt_transforms/)
[![Governance: Contracts](https://img.shields.io/badge/Governance-JSON_Schema_Draft_7-2EA44F.svg)](contracts/)
[![Docs: ADRs](https://img.shields.io/badge/Architecture-ADRs_Documented-blue.svg)](docs/adr/)
[![License: MIT](https://img.shields.io/badge/License-MIT-gray.svg)](LICENSE)

An executable enterprise reference architecture demonstrating core platform design patterns: **producer-consumer data contract enforcement**, **strict Medallion lifecycle boundaries**, **conformed Kimball dimensional modeling (SCD2)**, and **declarative infrastructure management**.

This repository demonstrates architectural patterns and executable controls; it is not presented as a complete production platform or multi-cloud implementation.

---

## 1. Architectural Principles

1. **Raw Storage Immutability:** Bronze data is append-only and strictly source-aligned to ensure zero-loss replayability.
2. **Producer-Owned Contracts:** Ingestion schemas, SLAs, and governance expectations are owned upstream; schema drift is intercepted before publication.
3. **Layered Transformation Lifecycle:** Bronze preserves origin payloads; Silver normalizes and conforms enterprise entities; Gold exposes business-optimized Star Schemas.
4. **Consumption-First Modeling:** Gold structures optimize for reporting intuition and analytical engine performance rather than source application models.
5. **Deterministic History (SCD2):** Dimensional state transitions maintain temporal validity intervals (`valid_from`, `valid_to`, `is_current`).
6. **Declarative Infrastructure:** Compute isolation, warehouse auto-suspend policies, and role-based access controls are version-controlled via Terraform.
7. **Architectural Traceability:** Every structural pattern traces directly from business requirement to an ADR, an implementation file, and an automated verification test.
8. **Portable dbt SQL:** Core transformation models minimize engine-specific SQL, isolating adapter-specific behavior to configurations and macros.

---

## 2. Architecture Quality Attributes

| Quality Attribute | Architectural Strategy & Design Response | Executable Verification |
|---|---|---|
| **Replayability** | Append-only raw Bronze tier; zero business logic executed prior to Silver. | Fixture ingestion replay into Silver staging models. |
| **Data Integrity** | Machine-enforced JSON Schema Draft 7 contracts with quarantine rejection. | `pytest contracts/tests/` |
| **Historical Audit** | SCD Type 2 snapshotting with surrogate keys and temporal validity bounds. | `dbt snapshot` state transition verification. |
| **Maintainability** | Strict separation of concerns (Bronze $\rightarrow$ Silver $\rightarrow$ Gold) and documented ADRs. | Decoupled dbt DAGs in `/models`. |
| **Compute Governance** | Independent compute cluster sizing and auto-suspend policies via IaC. | Terraform configuration in `/terraform`. |
| **Portability** | Core transformations written in portable dbt SQL; local runner decoupled from cloud targets. | Portable dbt Core profiles. |

---

## 3. End-to-End Architectural Traceability

           BUSINESS REQUIREMENT: Accurate Cross-Departmental Revenue Auditing
                                           │
                                           ▼
           ARCHITECTURAL PRINCIPLE: Historical State Must Be Deterministic
                                           │
                                           ▼
           ARCHITECTURE DECISION: ADR-002 (Kimball Dimensional Modeling + SCD2)
                                           │
                   ┌───────────────────────┴───────────────────────┐
                   ▼                                               ▼
           DESIGN CHOICE: SCD Type 2                       TRADE-OFF: Managed
         on dim_customers (`billing_city`)              Silver-to-Gold Schema Updates
                   │                                               │
                   └───────────────────────┬───────────────────────┘
                                           │
                                           ▼
           IMPLEMENTATION: `dbt_transforms/snapshots/snap_customers.sql`
                                           │
                                           ▼
           AUTOMATED VERIFICATION: Deterministic Before/After Row Expiration Test
                                           │
                                           ▼
           CI PIPELINE GATE: GitHub Actions blocks invalid modeling migrations

---

## 4. Implementation Portability Matrix

| Architectural Tier | Local Reference (`duckdb`) | Target Cloud Warehouse | Portability Classification |
|---|---|---|---|
| **Contract Ingestion Gate** | Python `jsonschema` Draft 7 | Cloud Function / Ingestion Worker | **Shared Logic** (Vendor-agnostic) |
| **Silver Normalization** | dbt models + SQL CTEs | dbt models + SQL CTEs | **High Portability** (ANSI-aligned dbt SQL) |
| **Gold Dimensional Facts** | Star Schema Surrogates & Measures | Star Schema Surrogates & Measures | **High Portability** (ANSI-aligned dbt SQL) |
| **SCD Type 2 Snapshots** | `dbt snapshot` via DuckDB adapter | `dbt snapshot` via Warehouse adapter | **dbt-Managed** (Adapter-dependent DDL) |
| **Compute / Storage Isolation**| In-process single-thread engine | Virtual Warehouse compute tiers | **Engine-Specific** (Terraform infrastructure) |

---

## 5. Non-Goals

To maintain rigorous technical depth, this project explicitly does not attempt to provide:
* An all-in-one data platform template supporting every cloud vendor simultaneously.
* Sub-second real-time streaming topologies (Kafka/Flink topologies are documented as architectural extensions).
* An open table-format catalog orchestration engine (Apache Iceberg / Delta Lake REST catalogs).
* A replacement for enterprise Master Data Management (MDM) software.

---

## 6. Local Quickstart & Verification

### Step 1: Execute Schema Contract Tests
Verify that the test suite enforces the JSON Schema Draft 7 specification against fixtures:
```bash
pip install -r requirements-dev.txt
pytest contracts/tests/test_erp_orders_contract.py -v
Step 2: Compile Models & Execute SCD2 Snapshots
Bash
cd dbt_transforms
dbt deps
dbt compile --profiles-dir .
dbt snapshot --profiles-dir .
dbt test --profiles-dir .
Step 3: Validate Terraform Architecture Definitions
Bash
cd terraform/modules/compute_warehouse
terraform init -backend=false
terraform validate
7. License
Distributed under the MIT License. See LICENSE for details.


---

### 5. Deterministic CI Pipeline (`.github/workflows/ci.yml`) & `Makefile`

This ties the entire verification loop together: **contract validation $\rightarrow$ dbt execution $\rightarrow$ terraform linting**.

#### `.github/workflows/ci.yml`
```yaml
name: Architecture Verification CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate-contracts-and-models:
    name: Verify Data Contracts & Transformations
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      - name: Install Dependencies
        run: |
          pip install --upgrade pip
          pip install -r requirements-dev.txt

      - name: Execute Contract Validation Suite
        run: |
          pytest contracts/tests/ -v

      - name: Compile and Test dbt DAG
        run: |
          cd dbt_transforms
          dbt deps
          dbt compile --profiles-dir .
          dbt snapshot --profiles-dir .
          dbt test --profiles-dir .

  validate-terraform:
    name: Validate Terraform Infrastructure Patterns
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      - name: Validate Compute Warehouse Module
        run: |
          cd terraform/modules/compute_warehouse
          terraform init -backend=false
          terraform validate
Makefile
Makefile
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: test-contracts
test-contracts: ## Run granular contract enforcement tests against JSON fixtures
	pytest contracts/tests/ -v

.PHONY: test-dbt
test-dbt: ## Compile dbt DAG, execute snapshots, and run data tests
	cd dbt_transforms && dbt deps && dbt compile --profiles-dir . && dbt snapshot --profiles-dir . && dbt test --profiles-dir .

.PHONY: validate-tf
validate-tf: ## Initialize and validate Terraform modules
	cd terraform/modules/compute_warehouse && terraform init -backend=false && terraform validate

.PHONY: verify-all
verify-all: test-contracts test-dbt validate-tf ## Run all automated architectural verifications
	@echo "All architectural assertions, models, and IaC patterns verified successfully.