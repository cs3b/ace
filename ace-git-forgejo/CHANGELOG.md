# Changelog

All notable changes to ace-git-forgejo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
