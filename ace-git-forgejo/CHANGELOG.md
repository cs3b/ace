# Changelog

All notable changes to ace-git-forgejo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
