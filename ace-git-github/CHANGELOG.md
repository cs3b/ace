# Changelog

All notable changes to ace-git-github will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-10-03

### Added
- GitHub issue tracking through the shared provider contract, including repository-bound lookup and mutation.

### Fixed
- Issue labels are looked up and created on demand before attachment (concurrent creations tolerated), and the label listing no longer sends the gh-incompatible `--slurp` + `--jq` combination.

## [0.3.0] - 2026-10-02

### Added
- Repository-bound GitHub PR comment and review retrieval, comment create/update, and thread resolution through the shared provider contract.
- Correlation-based comment reconciliation after uncertain posts and explicit malformed or unsupported result classification.

## [0.2.0] - 2026-09-28

### Added
- PR lifecycle mutations with atomic provider-side expected-head enforcement:
  exact-match lookup (`find_open_pull_requests`), idempotent draft-create
  reconciliation, expected-head merge via the gh match-head-commit flag,
  head-verified update/ready.
- Cross-repository PR provenance: head repository URL resolved from gh
  evidence and returned in normalized PR evidence.
- Classified lifecycle failures (conflicting matches, expected-head conflict,
  unknown create outcome with reconciliation identity).

### Changed
- `gh pr view`/`list` JSON field sets extended with head-repository fields.


### Added
- PR lifecycle mutations with atomic provider-side expected-head enforcement:
  exact-match lookup (`find_open_pull_requests`), idempotent draft-create
  reconciliation, expected-head merge via the gh match-head-commit flag,
  head-verified update/ready.
- Cross-repository PR provenance: head repository URL resolved from gh
  evidence and returned in normalized PR evidence.
- Classified lifecycle failures (conflicting matches, expected-head conflict,
  unknown create outcome with reconciliation identity).

### Changed
- `gh pr view`/`list` JSON field sets extended with head-repository fields.


## [0.1.2] - 2026-09-26

### Added
- `IssueSync.available?` probe: true when the `gh` CLI is installed and authenticated, letting callers treat GitHub sync as best-effort.

## [0.1.1] - 2026-09-24

### Fixed
- Pass PR number and repository as separate `gh` arguments for cross-repository pull requests.

## [0.1.0] - 2026-09-21

### Added

- Initial GitHub provider package implementing the forge-neutral ace-git provider contract.
- Owns all `gh` CLI invocation, output parsing, and authentication verification
  (moved out of the ace-git core as part of foundation chunk F0, task 8wk.t.l1e).
- Normalized evidence translation for pull requests, issues, checks, and repository
  metadata, with the shared classified failure taxonomy (no silent fallbacks).
- Shared provider-contract parity suite coverage against scripted fakes.
