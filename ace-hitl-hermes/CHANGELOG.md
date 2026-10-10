# Changelog

All notable changes to `ace-hitl-hermes` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] - 2026-10-10

### Fixed

- Require the published producer and consumer patch versions containing the protected context and managed-attempt APIs; exclude incompatible prior dependency graphs.

## [0.2.1] - 2026-10-08

### Fixed

- Preserve the selected project for proposal operations and transport ingress instead of resolving a different ambient journal.

## [0.2.0] - 2026-10-05

### Added

- Resolve immutable second-commander proposals through confirmed-delivery sixteen-hour policy and canonical Assign authorization.
- Installable correlated Telegram transport, explicit Captain/group registry, authenticated HITL IPC and guarded Hermes plugin assets.
- Durable non-secret submission acknowledgements, ingress receipts, polling offsets and conservative reconciliation checkpoints.
- Supervised single polling actor with gateway ownership checks and recovery without duplicate lifecycle effects.

### Changed

- Declare the required direct dependencies and minimum producer versions for this coordinated release: `ace-hitl ~> 0.12`, `ace-hitl-contract ~> 0.2`.

- Consume the shared managed binding envelope and publish newly created authenticated pending requests through explicitly registered project channels in the existing single Telegram polling actor.
- Ordinary answer folder publication requires authenticated request classification; OTP and sensitive answers are refused before any file creation.

### Fixed

- Block later proposal approval behind unresolved earlier ingress and reconcile canonical proposer wakes after the existing transport poll loop establishes coverage.
- Submit authenticated requests from users named captain; leave unmanaged instructions for their target based on lifecycle authority, not sender labels.
- Retain the continuous polling owner across transient pending-publication transport outages, report the channel failure and retry without consuming the request.

## [0.1.0] - 2026-09-27

### Added
- **Folder-as-interface plugin + registry (spec 8wm.t.vs1)**: new package owning the channel registry, notification texts, and message formats for the shared lab <-> hermes folder. Folder contract `ace.hitl.hermes.folder/v1` + message schema `ace.hitl.hermes.message/v1` (JSON Schema asset shipped at `lib/ace/hitl/hermes/schemas/message.v1.schema.json`): a message is a file named `<id>.json`, the address is `<machine>/<folder>/<id>`, the Captain's answer file carries `answer` / `sender` / `received_at`. Fail-closed filename validation, UTF-8 + 64 KiB bounds, id/filename cross-check, ownership/permissions (files 0640, tmp 0600, quarantine 0750; running as root is refused), atomic same-directory tmp+rename writes, quarantine for invalid files with reason sidecars, bounded collision and undeleted-file retry policies, and the write -> validate -> deliver -> ACK deletion state machine. Canonical shared-contract file location/ownership is settled by A4 (8wm.t.vs2); the lab-config consumer side is 8wm.t.vp9 (separate repo).

### Fixed
- **PR#336 review hardening (codex astra high)**: `publish` validates the exact serialized envelope bytes through the consumer decode gate (UTF-8 + 64 KiB) before any disk write, so an oversized envelope fails at the producer instead of being terminally quarantined by its own poll; `poll` opens message files with `O_NOFOLLOW` and requires a regular file on the descriptor, quarantining top-level symlinks instead of following them (no re-delivery of quarantined content, no importing foreign content through links); the shipped JSON Schema now rejects the envelopes the Ruby exact-field and body-strip checks reject (mutually exclusive kind fields, nonblank bodies).
