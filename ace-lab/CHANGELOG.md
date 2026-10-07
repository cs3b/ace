# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Run protected handlers through the shared bounded subprocess owner with separate 16KiB stdout/8KiB stderr caps and owned cleanup. Stream EOF does not imply child exit; timeout or unconfirmed reaping never produces a receipt or domain absence proof. Receiver recovery and domain inspection remain required source work.

### Added

- Compose the fixed read-only Inbox context completion owner with existing Endcap services over the same protected canonical journals and deployment history. Installed context provisioning remains separate.

## [0.4.0] - 2026-10-05

### Added

- Protected service policy, receiver and authority composition; incomplete full-service startup remains refused.
- Resolve immutable second-commander proposals through confirmed-delivery sixteen-hour policy and canonical Assign authorization.

### Changed

- Declare the required direct dependencies and minimum producer versions for this coordinated release: `ace-assign ~> 0.64`, `ace-runtime ~> 0.2`.

## [0.3.1] - 2026-10-04

### Changed
- Track the runtime-neutral ace-assign 0.62 line (the published 0.3.0 still allows `~> 0.61`, which resolves 0.62 — this release ships the tightened constraint).

## [0.3.0] - 2026-10-04

### Added
- **HITL delivery authorization policy (spec 8wq.t.34i)**: `Molecules::HitlAuthorizer` derives the lab-side transport facts (trusted transport uids, trusted HITL service identity, per-project Captain visibility) from the SAME trusted deployment document the grant resolver reads — uid-exact, project-scoped, never from claimed names or the cascade.

## [0.2.0] - 2026-10-02

### Added

- `service request` and `service status` for exact authorized operations,
  idempotent assignment-journal claims, peer-verified execution receipts,
  dry-run previews, and conservative uncertain-state recovery.

### Fixed

- Recheck the configured operation, authorization, and lease at dispatch;
  bind terminal receipts to the assignment request before acceptance.

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
