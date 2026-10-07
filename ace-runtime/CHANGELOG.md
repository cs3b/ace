# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Preserve Ruby already-loaded builtin require no-ops only for the allowlisted startup features verified at first guard activation; later activation cannot grow that authority.

- Resolve guarded Ruby native-extension requests using the selected interpreter platform extension, including explicit `.so`/`.o` aliases, while authenticating only exact declared files.

- Reject duplicate JSON keys, invalid UTF-8, comments and excessive nesting in protected socket frames while preserving exact byte boundaries between successive frames.

- Authenticate the boot-selected private devpts backing and exact instance-local ptmx node before API exemption; shared host views refuse even when read-only. Verify the explicit unit projections and pinned contained ptmx link/node observations.

### Added

- Expose a scoped authenticated read-only duplicate of a retained artifact for exact inode handoff; verify before and after callbacks and close on every exit.

- Allow trusted installer code to select a bounded artifact count through `ProtectedArtifactSet.new(count_limit:)`; ordinary callers retain the 256-artifact default and both read interfaces enforce the same budget.

- Verify immutable per-boot original host baseline selections and the fixed readiness configuration/runtime load surface. Collect complete bounded server mount/IPC views through contained pinned descriptors and verify exact original backing plus the authenticated read-only authority socket projection. Trusted domain boot-proof production/refresh and installed effectiveness remain separate obligations.

## [0.2.0] - 2026-10-05

### Added

- Authenticate bounded root-produced network profile/report/trace artifacts with closed strict JSON schemas, exact context/check joins and held protected file descriptors. Missing or incomplete evidence refuses; effective network enforcement and immutable publication remain the domain installer’s responsibility.

- Verify fixed execution-unit artifact bytes and typed effective system-manager properties, including retained parent activation hierarchy, service enablement routes and exact native/readiness commands. Installation verification remains separate from live boundary and whole-scope proof.

- Add fixed system-systemd unit operations with bounded noninteractive jobs and descriptor-pinned cgroup-v2 population/membership observation. These primitives do not manufacture canonical scope proof or claim installed boundary acceptance.

- Ship the immutable native worker gate and protected Linux/socket primitives with exact process birth, pidfd exit, enforced Yama 2, empty capability sets and NoNewPrivs checks.

- Add read-only process ownership observation with PID birth identity, OS ancestry, unknown liveness and shared adapter contract coverage.

### Fixed

- Parse genuine typed nsfs mount roots while rejecting them as backing-storage projections, and query activation properties through the correct fixed slice and service interfaces.

## [0.1.1] - 2026-10-04

### Fixed
- Adapter `LoadError`s propagate instead of being swallowed, and the runtime contract enforces its typed error surface (k86.3 consumer migration).

## [0.1.0] - 2026-09-28

### Added

- Runtime-neutral terminal intent contract (spec 8wq.t.k86.0): duck-typed adapter registry with fail-closed resolution and lazy `ace/runtime/adapters/<name>` entrypoint loading.
- Side-effect-free environment detection (`Ace::Runtime.detect`) with documented tmux precedence when both runtimes are live.
- Shared window/tab name sanitization (`Ace::Runtime.sanitize_name`).
- The 11-operation intent API with opaque adapter-owned target handles, seconds-based wait timeouts, and the typed error model (`UnknownRuntimeError`, `RuntimeUnavailableError`, `TargetNotFoundError`, `WindowConflictError`, `SendRejectedError`, `SendStalledError`, `WaitTimeoutError`).
- Central send-matrix validation (`Ace::Runtime::Atoms::SendContract`) for `:plain_pane` and `:agent_aware` profiles, including ordered `{message:}/{key:}` items and the callback shapes that submit exactly once.
- The single neutral callback CLI: `ace-runtime send`.
- The packaged adapter contract-test suite (`Ace::Runtime::Testing::AdapterContract`) with the `ScriptedRuntime` fixture, documented as the acceptance bar for any adapter.
