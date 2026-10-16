# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2026-10-16

### Added

- Run the ordinary merge listener and receiver through `service listen`, with authenticated admission, canonical Assign acknowledgement/status/receipts, restart reconciliation and bounded fixed execution.
- Invoke and inspect real Forgejo merges under the installed scoped service identity; revalidate authorization per request and bind the provider mutation to the approved candidate head.

### Changed

- Require ace-assign 0.69 and ace-git-forgejo 0.7 for the receiver record-listing and scoped provider APIs.

- Move the Forgejo merge provider ownership out of ace-lab (xz9.5): `ForgejoMergeAdapter` is now a thin delegation to the `ace-git-forgejo` provider (`Ace::Git::Forgejo::PullRequestApi` over its `HttpClient`, under the host-installed scoped service identity) — HTTP transport, authentication, payload shape, and failure classification live in the provider package, while the adapter keeps the receiver's closed outcome translation (`:invoked`/`:refused`/`:ambiguous`/`Unavailable`), the exact-head binding guard, and the normalized readback/nil-absence contract unchanged.

## [0.6.0] - 2026-10-14

### Added

- Add the ordinary fixed merge producer mode (`ace-lab service request/status --mode ordinary-merge`) per xz9.4: durable-once admission that issues the opaque reference only through the committed journal record, canonical SHA-256 request digests over the full eight-field binding, identical-replay acknowledgment, authorization/binding conflict refusals, read-only status, and terminal receipts bound to the admitted record and its execution identity.

## [0.5.2] - 2026-10-11

### Changed

- Follow the `ace-hitl` 0.14 lifecycle boundary line with dedicated per-authority socket-group configuration.

## [0.5.1] - 2026-10-10

### Fixed

- Require the published producer and consumer patch versions containing the protected context and managed-attempt APIs; exclude incompatible prior dependency graphs.

## [0.5.0] - 2026-10-08

### Added

- Deliver scoped RubyGems publication through the fixed receiver and canonical HITL authorization, preserving original request, OTP challenge and publication-result evidence.

### Changed

- Compose actual service/result owners without a read-proof completion handler; retain authenticated service settlement and cleanup boundaries.

### Fixed

- Load protected policy/listener dependencies directly and keep cleanup inspection tied to the original receiver and immutable result evidence.

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
