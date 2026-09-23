# ADR-001: Three-Tier Medallion Storage Boundary Strategy

* **Status:** Accepted
* **Deciders:** Enterprise Data Architect
* **Date:** 2026-03-10

## Context & Problem Statement
Legacy batch reporting combined source-system replication directly with reporting SQL. Upstream transactional modifications broke downstream financial calculations, and retroactive logic changes required painful, non-deterministic rebuilds from live operational databases.

## Decision
We enforce a strict physical and logical **three-tier Medallion architecture (Bronze, Silver, Gold)**:
1. **Bronze (Raw Tier):** Append-only, immutable event logs retaining original payload structure plus ingestion technical metadata (`_ingested_at`, `_source_file`). Strictly zero business logic or type casting.
2. **Silver (Normalized Tier):** Conformed enterprise domain entities. Handles null handling, string normalization, deduplication, and schema typing.
3. **Gold (Dimensional Tier):** Kimball star schemas with surrogate keys, conformed dimensions, and pre-computed measures optimized for business consumption.

## Consequences & Trade-offs
* **Positive:** Complete historical replayability from Bronze without impacting production OLTP systems. Decoupled development cycles between engineering (Silver) and business analysts (Gold).
* **Negative:** Increased initial storage footprint due to retaining immutable raw snapshots alongside modeled tables.
