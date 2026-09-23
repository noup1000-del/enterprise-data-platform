# ADR 005: Platform and Engine Neutrality

## Status
Accepted

## Context
A reference architecture should not be tied to a single vendor or engine in a way that prevents adoption or testing.

## Decision
Use portable SQL patterns with a local DuckDB reference implementation and a Terraform-defined cloud warehouse pattern.

## Consequences
- Local validation is fast and accessible.
- Cloud implementation remains representative but not a rigid dependency.
- The architecture demonstrates principles rather than a single vendor lock-in.
