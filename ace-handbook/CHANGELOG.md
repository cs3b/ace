# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `wfi://release/publisher` (task 8xs.t.pu0.9): the publisher coworker role —
  existing release workflows, ace-lab auth access, OTP as a secret HITL ask,
  resume that recognizes already-published artifacts by version+digest, and
  the hand-off to install/verify/record.
- `wfi://release/cycle-record`: the delivery-cycle evidence record contract
  (task/cycle, source HEAD, bound review/test evidence, publish
  versions+digests, runtime paths and outcome) through a normal record-only
  PR that never triggers a release by itself.

### Added

- Provider manifests can declare `extensions_package`: extension assets project
  from the named asset package (local sibling directory first, installed gem
  second), enabling gem-backed extension shipping such as `ace-wake` for the pi
  provider (task 8xs.t.pu0.0).

## [0.36.2] - 2026-10-27

### Added

- Add the "Asking the Counterpart" guide: one-paragraph default agent behavior for asking a counterpart through `ace-hitl ask` (send + auto-arm wake + end turn, no block/poll, no urgency language), including the secret-into-environment-variable-only rule.

## [0.36.1] - 2026-10-25

### Changed

- Extend the RubyGems publish workflow and release skill with the semantic-wake OTP handoff (PR74): readiness-only HITL fallback and the agent-driven single-OTP wait contract.


## [0.36.0] - 2026-10-20

### Changed

- Remove the attempt/authority requirement from `wfi://handbook/perform-delivery`: record actual artifacts, executed checks and the independent reviewer verdict in the assignment report instead of attempt receipts; managed delivery remains planned for L5.5.

