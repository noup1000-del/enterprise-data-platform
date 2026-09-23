# ADR-002: Kimball Dimensional Modeling for Analytics Consumption

* **Status:** Accepted
* **Deciders:** Enterprise Data Architect
* **Date:** 2026-03-15

## Context & Problem Statement
We require an analytical data model supporting cross-departmental revenue auditing and self-service ad-hoc reporting across commercial sales and regional finance.

## Decision
We implement **Kimball Dimensional Modeling (Star Schema)** with SCD Type 2 tracking in the Gold tier, fed by normalized Silver entities.

## Evaluation & Trade-offs
* **Why not Data Vault 2.0:** While Data Vault provides exceptional source-system change isolation via Hubs, Links, and Satellites, it introduces significant join overhead for direct BI consumption. Given that raw auditability is already guaranteed at the Bronze boundary, introducing an additional Hub/Satellite layer before reporting would add unnecessary operational overhead for this workload.
* **Why not One Big Table (OBT):** Completely flattened wide tables simplify queries but duplicate mutable dimensional attributes, making point-in-time historical corrections (e.g., retroactively updated corporate tax rates or territory reassignments) computationally expensive and difficult to govern.

## Consequences & Trade-offs
* **Positive:** High analytical performance, low join count for BI tools, and intuitive drill-down capabilities for financial auditors.
* **Negative:** Requires disciplined surrogate key management and explicit SCD2 snapshot DAG coordination within dbt.
