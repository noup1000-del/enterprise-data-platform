# ADR-003: Producer-Owned Schema Contracts with Boundary Quarantine

* **Status:** Accepted
* **Deciders:** Enterprise Data Architect
* **Date:** 2026-03-18

## Context & Problem Statement
Silent schema drift from operational systems (e.g., newly added status enum values, omitted customer identifiers, or altered numeric formats) historically caused silent pipeline corruption or mid-night batch job failures.

## Decision
We enforce **producer-owned Data Contracts** at the ingestion boundary using JSON Schema Draft 7 with strict RFC3339 date-time validation:
1. Contracts reside in version control (`/contracts/`) alongside platform code.
2. Payloads failing validation are immediately rejected and routed to a quarantine dead-letter location without blocking the rest of the batch.
3. Breaking changes require an explicit major contract version bump (`x.0.0`) and downstream subscriber notification.

## Consequences & Trade-offs
* **Positive:** Guarantees schema determinism for Silver/Gold dbt pipelines. Eliminates silent runtime failures in downstream financial reports.
* **Negative:** Shifts governance friction upstream onto producer engineering teams, requiring automated schema testing in producer CI/CD workflows.
