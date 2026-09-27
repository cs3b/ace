# Changelog

All notable changes to `ace-herdr` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Gem bootstrap (spec 8wm.t.vs0): push delivery + agent bootstrap for the Herdr runtime, implementing the ace-hitl provider delivery contract (`deliver(ref, answer)` -> `DeliverResult` with `:delivered`/`:retryable`/`:failed`).
- `Ace::Herdr::Organisms::Deliverer`: idempotent per event id with write-ahead delivery records under `.ace-local/herdr/deliveries/` (atomic writes; the answer is never lost), duplicate-identical short-circuit, fail-closed content conflicts, bootstrap of missing agents (`herdr agent start` with `HERDR_SESSION`/`HERDR_PANE` exported into the pane shell), a readiness gate before prompting, retry limits with fixed deterministic backoff, and terminal-failure reporting persisted in the record.
- `Ace::Herdr::Organisms::Dispatcher`: one-command subagent dispatch — tab + `herdr agent start` + prompt with deterministic defaults (caller's workspace, label = agent/pane name, prompt from file/stdin/`--no-prompt`).
- `ace-herdr` CLI: `deliver`, `dispatch`, `wait`, `close` (JSON output, exception-based exit codes per ADR-023).
- `Ace::Herdr::Molecules::HerdrExecutor`: the single seam to the herdr CLI (argv arrays per ADR-031) with typed error classification from herdr's machine-readable codes (`agent_blocked`, `agent_prompt_stalled`, `pane_not_found`, `timeout`).
- Config cascade (ADR-022) defaults: `default_agent_kind`, delivery retry limits/backoff, timeouts, deliveries dir (ADR-029).
