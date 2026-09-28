# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-09-28

### Added

- Runtime-neutral terminal intent contract (spec 8wq.t.k86.0): duck-typed adapter registry with fail-closed resolution and lazy `ace/runtime/adapters/<name>` entrypoint loading.
- Side-effect-free environment detection (`Ace::Runtime.detect`) with documented tmux precedence when both runtimes are live.
- Shared window/tab name sanitization (`Ace::Runtime.sanitize_name`).
- The 11-operation intent API with opaque adapter-owned target handles, seconds-based wait timeouts, and the typed error model (`UnknownRuntimeError`, `RuntimeUnavailableError`, `TargetNotFoundError`, `WindowConflictError`, `SendRejectedError`, `SendStalledError`, `WaitTimeoutError`).
- Central send-matrix validation (`Ace::Runtime::Atoms::SendContract`) for `:plain_pane` and `:agent_aware` profiles, including ordered `{message:}/{key:}` items and the callback shapes that submit exactly once.
- The single neutral callback CLI: `ace-runtime send`.
- The packaged adapter contract-test suite (`Ace::Runtime::Testing::AdapterContract`) with the `ScriptedRuntime` fixture, documented as the acceptance bar for any adapter.
