# ADR 004: ELT Pushdown with dbt

## Status
Accepted

## Context
The architecture needs a transformation layer that is portable and maintainable without hand-optimizing every warehouse-specific query.

## Decision
Use ELT patterns with dbt Core and ANSI-aligned SQL, keeping warehouse-specific logic isolated to configuration and macros.

## Consequences
- Transformation logic is easier to review and test.
- Work is aligned with the warehouse engine rather than fragmented across scripts.
- The model remains understandable to broader engineering teams.
