# Archived Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) that are **deprecated** and no longer applicable to the current codebase.

## Why Archive Instead of Delete?

Archived ADRs preserve historical context and help understand the evolution of the codebase. They document decisions that were valid during the legacy `dev-tools` phase but have been superseded by the mono-repo migration to ace-* gems.

## Archived ADRs

### ADR-006: CI-Aware VCR Configuration
- **Archived**: October 14, 2025
- **Reason**: VCR HTTP mocking only used in legacy dev-tools. Current ace-* gems do not use VCR.
- **Current State**: ace-llm uses Faraday directly without VCR mocking

### ADR-007: Zeitwerk for Autoloading
- **Archived**: October 14, 2025
- **Reason**: Zeitwerk autoloading only used in legacy dev-tools. Current ace-* gems use explicit requires.
- **Current State**: ace-llm and other gems use explicit `require_relative` statements

### ADR-008: Observability with dry-monitor
- **Archived**: October 14, 2025
- **Reason**: dry-monitor pub/sub system only used in legacy dev-tools. Current gems do not use dry-monitor.
- **Current State**: No centralized observability system in current ace-* gems

### ADR-009: Centralized CLI Error Reporting
- **Archived**: October 14, 2025
- **Reason**: ErrorReporter module only used in legacy dev-tools. Current gems use standard error handling.
- **Current State**: Thor CLI commands handle errors with standard Ruby exception patterns (see ADR-018)

### ADR-019: Configuration Architecture
- **Archived**: December 13, 2025
- **Reason**: Superseded by ADR-022 which adds explicit guidance for default configuration loading from `.ace-defaults/` files
- **Current State**: Use ADR-022 for configuration patterns in ace-* gems

## Migration Context

These ADRs were created during the **legacy dev-tools phase** (pre-v0.9.0) before the mono-repo migration (ADR-015). The migration to ace-* gems (v0.9.0+, October 2025) introduced new patterns:

- **ADR-018**: Thor CLI Commands Pattern (replaces ADR-009)
- **ADR-010**: HTTP Client Strategy with Faraday (current approach, no VCR)
- **Explicit Requires**: No autoloading framework needed for smaller, focused gems

## Related Active ADRs

For current architecture decisions, see:
- **ADR-015**: Mono-Repo Migration to ace-* Gems
- **ADR-016**: Handbook Directory Architecture
- **ADR-018**: Thor CLI Commands Pattern
- **docs/decisions.md**: Summary of all active decisions

---

**Note**: These archived ADRs are kept for historical reference only. Do not implement patterns from archived ADRs in new code.
