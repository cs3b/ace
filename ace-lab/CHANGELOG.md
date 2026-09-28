# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-28

### Added

- Topology/routing CLI (`ace-lab`) addressing projects, agents, and services by
  stable IDs: `projects`, `agents`, `services`, `resolve`, `route` commands with
  deterministic JSON output (`--format json`).
- ADR-022 configuration contract for Lab topology (`schema_version: 1`) with
  validated stable IDs, project references, capability normalization, binding
  attestation fields, and verified-local-principal authorization mapping.
- Classified query outcomes: `missing`, `ambiguous`, `stale`, `unauthorized`,
  `invalid_configuration`.
- Allowlist-based public projection; tokens, auth-file paths, endpoint
  credentials, URL userinfo, query parameters, fragments, and raw pane/session
  identifiers never appear in public output.
