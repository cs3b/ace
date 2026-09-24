# Changelog

All notable changes to ace-git-github will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
