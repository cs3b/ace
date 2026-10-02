# Changelog

All notable changes to ace-git-forgejo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-10-02

### Added
- Forgejo issue tracking through the shared provider contract with selected-server authority checks and parsed issue evidence.

## [0.3.0] - 2026-09-29

### Added
- Selected-repository binding for every `fj` repository command: the
  resolved server's host/owner/repository is validated once (malformed
  selections raise `ConfigError` before any subprocess) and stamped onto
  every call via `-H` plus qualified `owner/repo#N` ids or `-r owner/repo`,
  so a named server selection can never be silently retargeted by cwd,
  remotes, default login, or another checkout.
- Capability table grounded in observed forgejo-cli v0.6.0 help/output
  (upstream release binary, plus real-server read-only probes); operations
  without an observed argv form and installed versions outside the observed
  set refuse with `ProviderUnsupportedCapabilityError` before launch.
- Returned-identity validation: PR/issue numbers and repository view
  full-name/URL must agree with the selection or evidence fails closed
  with `ProviderIdentityMismatchError`.

### Changed
- All `fj` subprocess launches now go through a two-path executor boundary:
  an allowlisted control path (`fj version`, `fj auth list`) and the
  repository boundary. Authentication compares `fj auth list` lines exactly
  against the selected authority (substring hosts no longer count) and
  scans both output streams (observed v0.6.0 prints "No logins." on stderr
  with exit 0).
- Unauthenticated-API failures are classified as authentication errors
  (observed Lab text "Only signed in user is allowed to call APIs.").
- `merge_commit_sha` stays empty: observed fj v0.6.0 exposes no
  authoritative merge-commit field for a selected PR, so cleanup evidence
  never claims one.

### Fixed
- Selected-host fidelity: `-H` now carries the selected `scheme://authority`
  (fj assumes HTTPS for a bare host, so an http authority was silently
  upgraded), non-http(s) server schemes are rejected as configuration
  errors before any subprocess, and the provider refuses to launch
  repository commands when the readable fj keys file aliases the selected
  host to a different endpoint (read-only check; absent/unreadable keys
  file is allowed, never modified).

## [0.2.0] - 2026-09-28

### Added
- PR lifecycle mutations matching the shared provider contract: exact-match
  lookup via `fj pr search`, idempotent create reconciliation, head-verified
  title/body updates.
- Fork provenance: the `fj pr view` head-repository segment is parsed and
  returned in normalized PR evidence.

### Changed
- `pr ready` and `pr merge` are classified unsupported capabilities: `fj`
  offers no draft-to-ready command and cannot enforce an expected-head merge
  precondition atomically, so both refuse instead of racing.
- PR view parser captures the fork repository prefix of the `From` segment.

### Added
- PR lifecycle mutations matching the shared provider contract: exact-match
  lookup via `fj pr search`, idempotent create reconciliation, head-verified
  title/body updates.
- Fork provenance: the `fj pr view` head-repository segment is parsed and
  returned in normalized PR evidence.

### Changed
- `pr ready` and `pr merge` are classified unsupported capabilities: `fj`
  offers no draft-to-ready command and cannot enforce an expected-head merge
  precondition atomically, so both refuse instead of racing.
- PR view parser captures the fork repository prefix of the `From` segment.

## [0.1.1] - 2026-09-28


### Fixed

- Parse real `fj` v0.6.0 minimal-style output: strip Unicode bidi isolate/pop-directional marks (U+2066–U+2069, U+202A–U+202E, U+200E/U+200F, soft hyphen) that `[[:cntrl:]]` does not cover. Real `fj` output wraps dynamic fields (titles, numbers, URLs) in U+2068/U+2069, which made `parse_pr_view` return `nil` and leaked marks into repo-URL evidence.
- Listing API: `fj pr search` has no `--limit` flag on real `fj`; the flag made both listing paths fail unconditionally. Fetch all and cap `recent_pull_requests` client-side after the newest-first sort.
- Presence probe: `fj` rejects `--version` ("unexpected argument"), so `check_available!` misclassified healthy installs as missing. Probe with the supported `fj version` subcommand; classified `ProviderCliMissingError` semantics unchanged.
- Captured real `fj` outputs (pr view/commits/search, issue view, repo view) as fixtures; parser, executor, provider, and contract-parity suites assert against them.

## [0.1.0] - 2026-09-21

### Added

- Initial Forgejo provider package implementing the forge-neutral ace-git provider contract.
- Owns all `fj` CLI invocation, minimal-style output parsing, and authentication
  verification (foundation chunk F0, task 8wk.t.l1e; the ace-git core previously
  had zero Forgejo support).
- Normalized evidence translation for pull requests, issues, Actions checks, and
  repository metadata, with the shared classified failure taxonomy.
- Ad-hoc curl fallbacks are strictly excluded; `fj` failures surface as
  classified provider failures.
- Shared provider-contract parity suite coverage against scripted fakes.
