# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.11.0] - 2026-10-18

### Fixed (review PR #383, round 3)

- `ace-lab status` resolves state locations against the git worktree top
  (falling back to the cwd outside a repository), so running it from a
  project subdirectory no longer misreports an initialized lab as absent.

### Added

- `ace-lab status`: read-only lab status snapshot with three strictly
  separated sections. `configuration` distinguishes `configured` (explicit
  cascade sources plus aggregate topology counts), `not_configured` (no
  explicit `.ace/lab/config.yml` or `~/.ace/lab/config.yml` — never an
  empty-ready lab), and `error` (source/parse/schema failure, path-bearing
  content-free message). `state_files` reports presence and entry counts for
  the canonical lab-flow locations (`.ace-tasks`, `.ace-tasks/_overseer`,
  `.ace-local/assign`, `.ace-local/coworker`, `.ace-local/hitl`, `.ace-wt`)
  with informational notes for absent coworker/overseer state — presence never
  declares readiness. `worktree_view` points at the existing
  `ace-git-worktree list` (k9y) instead of duplicating it. Table default,
  `--format json`; exit 0 whenever a report renders (8xg.t.sbz.6.0 / L7.1).

## [0.10.0] - 2026-10-17

### Removed

- Remove the protected authority/admission/receiver/listener/worker/recovery/publication/cleanup stack and the generic service-request admission/journal (`service request|status` without `--mode`), including their CLI selectors and tests.
- Remove the retained installed ordinary fixed-merge producer/receiver (`service request|status|listen --mode ordinary-merge`), the `ace-lab assignment …` ordinary-owner commands, and the installed run/command kernel (`run`, `run-status`, `command execute`), including their organisms, molecules, CLI registrations, authorizers, probes and tests.
- Remove the obsolete protected/generic policy, executor, input and receipt models plus the ordinary merge/assignment owner configuration (ordinary journal/authority/admission wiring) and command admission/policy/runtime helpers.
- Drop the now-unused runtime gem dependencies `ace-assign`, `ace-runtime`, `ace-herdr` and `ace-hitl`; the package keeps `ace-support-cli`, `ace-support-core`, `ace-support-config` and `ace-git-forgejo`.

### Changed

- `ace-lab` ships read-only topology queries only. The old installed authority/journal/command path is removed in L1 and the local file-based flow ([docs/lab-flow.md](../docs/lab-flow.md)) does not use it.
- Retain the Forgejo merge adapter and its trusted configuration loader as provider building blocks; the local flow does not invoke them.
- Refocus README and usage documentation on environment/project preparation, with the installer marked as planned L8.

## [0.9.0] - 2026-10-16

### Added

- Wire ordinary artifact retention to fresh installed project visibility and the existing exact service or canonical proposal decision; retention does not select an executor or consume publication authorization.
- Expose ordinary candidate upload, assigned review export/acceptance and canonical merge evidence through retained assignment requests. Compose their proof owner with the existing merge receiver and command executor journal.
- Compile configured candidate test commands from canonical references into sealed retained source views with explicit installed runtime and external output; revalidate native origin, current policy, source and configuration for test evidence. Preserve existing views and remove only fresh failed pre-child materializations.

- Expose ordinary driver status, bootstrap, progress, result and exact recovery commands using the selected Assign owner; authenticate coordinator replacement with bounded process-generation observation.

### Changed

- Require an explicit `purpose: command` or `purpose: test` on every installed command-policy entry. Only test commands with exact candidate head/tree and canonical successful execution can authorize merge evidence; previous entries without purpose are refused.

## [0.8.0] - 2026-10-16

### Added

- Compose ordinary Assign, HITL and Forgejo merge under one installed owner and journal, with readiness barriers and fresh native/project admission.
- Optionally serve existing mTLS HITL beside the ordinary Unix listener under the same canonical owner, journal, proposal policy and one-use OTP vault. Validate the configured project and service identity before either listener starts.
- Add retained assignment prepare/request clients and bounded canonical worktree observations. Separate stable configuration identity from changing decisions, preserve no-effect settlement after slow provider calls, and clean delivery handler process groups.
- This source cut enables initial installation; it does not claim autonomous release or installed two-project acceptance.

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
