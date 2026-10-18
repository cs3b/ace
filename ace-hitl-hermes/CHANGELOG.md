# Changelog

All notable changes to `ace-hitl-hermes` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2026-10-18

### Added

- HITL delivery adapter (8xg.t.sbz.1.2 / L2.3): `lib/ace/hitl/adapters/hermes.rb`
  registers the `hermes` adapter for `ace-hitl send`. Route config
  (`hitl.adapters.routes`): `channel`, `machine` (defaults to `hitl.machine`),
  absolute `folder`, optional `sender`. Both HITL questions and reports are
  published as the outbound `question` kind — the shared rendering's
  `[HITL question]`/`[HITL report <result>]` prefix preserves the type and
  only questions carry `Reply-To:`. Explicit event id: an identical resend
  (same question body and sender) is idempotent `delivered`; a
  different-bytes collision fails without overwriting; a missing/invalid
  channel folder is `unavailable` (never a silent reroute).

## [0.7.0] - 2026-10-18

### Removed

- Remove second-commander proposal reconciliation from the runtime, relay and boundary scenario: `proposal_due`/`reconcile_proposals`, proposal acknowledge/reconcile/reply paths, and the proposal boundary-surface positive case. The proposal model is removed with the old installed authority; Hermes now handles only local HITL/relay traffic (pending publication, delivery, ingress reconciliation).

### Changed

- The nh0-A host boundary scenario documents that attempt-bound managed ask creation is unavailable until the L2 boundary replaces the removed installed authority; package tests continue to use the relay transport only.

## [0.6.0] - 2026-10-16

### Added

- Route explicitly authenticated operator questions through existing project correlation and durable ingress; require declared request-context capabilities before activating a project authority.

### Changed

- Require runtime/v2 for project-routed authorities, refusing old runtime configuration without rewriting it.
- Require ace-hitl 0.17 operator-question bindings and the ace-hitl-contract 0.3 envelope for routed questions.
- Replace channel-wide authority configuration with channels/v2 project routes, project-qualified correlation and folders, and explicit project CLI selection. Refuse old journals and ambiguous Reply IDs without migrating retained evidence.
- Persist ordinary ingress through the existing private message.v1 folders before confirming Telegram offsets; retry independently per project across crashes and authority outages, retaining configuration and Captain allowlist bindings. Keep OTP values and hashes out of files.

### Fixed

- Treat Captain allowlists as sets when binding routes; retain other array ordering. Use the hardened shared directory fsync for ingress creation, recovery and cleanup, and avoid recreating already-cleaned terminal folders.
- Preserve typed static ingress refusal diagnostics without logging lower-level causes or secret bodies. Document exact-backup recovery for intentionally blocked missing bodies and count actual lifecycle delivery calls in crash-replay regressions.
- Fsync message directories after publication and recovery before committing ingress body metadata or advancing Telegram offsets. Preserve the first body and offset when the directory barrier fails.
- Bound DNS lookup and TCP connection as well as TLS handshake/frame deadlines; make positive TLS fixtures independent of host DNS aliases.

## [0.4.0] - 2026-10-14

### Added

- Route registered Telegram channels over the host/Incus mTLS crossing: channels resolve to exactly one authority (`hitl_socket` XOR `hitl_endpoint`); remote endpoints must be exactly `tls+tcp://` with a DNS host, TLS 1.3 only, and server URI SAN, EKU, and configured fingerprint pin verified before any frame; clients cache per endpoint plus credential identity; activation is atomic at the poller — no channel is enabled until every configured authority passes an authenticated health and project-binding check.
- Add the `ace-hitl-boundary-scenario` executable (`run`, `ask`, `verify-acceptance`) with the closed `ace.hitl.boundary.scenario/v1` manifest and in-slice acceptance-receipt schema as the source-side harness for the fixture-gated nh0-A boundary handoff; missing or fabricated asks fail truthfully and the certificate identity maps only to the Hermes transport role while the local worker runs as the kernel-verified worker actor.
- Surface informed unknown-chat coverage gaps at late registration: chat ID, skipped-update count, update-ID range, and the new coverage generation are durably recorded before offset advancement and reported once per gap.

### Changed

- Require `tls_service_user`/`tls_service_group` for remote channels and verify the runtime, registry, and every referenced credential tree against the exact provisioning layout before any connection.

## [0.3.0] - 2026-10-11

### Added

- Route each registered Telegram channel through its configured lifecycle socket and explicit service identity, with lazy client reuse per distinct socket.
- Durably record skipped unregistered group IDs and expose the coverage gap as a new polling generation when a group is registered.

### Changed

- Qualify request correlation, delivery lookup and reconciliation by channel so independent project authorities cannot overwrite or answer one another's requests.
- Require `--channel` for delivery and ingress reconciliation status queries.

### Fixed

- Continue proposal reconciliation across healthy project authorities when another channel's lifecycle service is unavailable.
- Channel-qualify ingress drainage and proposal ordering, preserve existing transport/v1 journals, and atomically surface late-registration coverage generations.

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
