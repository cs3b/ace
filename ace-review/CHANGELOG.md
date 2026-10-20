# Changelog

All notable changes to ace-review will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [0.62.1] - 2026-10-20

### Changed

- Unify `wfi://review/pr` with the coworker role rules: state the shared 3/2/10 convergence rule (minimum 3 full rounds, last 2 consecutive clean, maximum 10 with escalation) and reference the reviewer role workflow (`wfi://coworker/reviewer`) and its deterministic `ace-coworker rounds record` counters instead of duplicating them.

### Added

- Cover the adopted forge-neutral typed PR subject fix (qkc.0, commit 9b9d72d65) in the fast suite: URL parsing never rewrites a forge URL to github.com or guesses a host (exact host, port and base-path expectations), performs no network calls, and extracts the number and repository identity for every accepted shape (number, `owner/repo#number`, GitHub `/pull/` and Forgejo `/pulls/` URLs, including port and base-path URLs).

