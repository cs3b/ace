<div align="center">
  <h1> ACE - Handbook Integration PI </h1>

  pi-agent provider integration for ACE handbook skills and workflows.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-handbook-integration-pi"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook-integration-pi.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[ace-handbook](../ace-handbook)
`ace-handbook-integration-pi` translates canonical ACE handbook skills into PI provider assets so that skill invocations from pi-agent resolve to the correct provider entrypoints while preserving shared semantics from [ace-handbook](../ace-handbook).

## Use Cases

**Consume canonical skills from PI tooling** - keep provider-specific behavior while preserving shared semantics, so agents running under pi-agent get the same skill intent as any other provider.

**Run the in-process overseer loop with `/work-backlog`** - the canonical `handbook/prompts/work-backlog.md` template projects to `.pi/prompts/work-backlog.md` (`ace-handbook sync --provider pi`), giving pi a slash command that cycles the task backlog (select → execute via `as-task-work` → verify → report) inside the pi session itself - no tmux windows or external orchestrator.

**Wake idle agents with `/loop` timers and `/watch` file subscriptions** - the bundled ace-wake extension (projected to `.pi/extensions/ace-wake.js`) queues bounded wake messages to the live agent through `sendUserMessage` only. Wakes coalesce per source, busy agents receive queued follow-ups instead of interruptions, definitions survive reload/restart with exactly-once re-registration, and there is no cron, systemd, or external heartbeat dependency. See [docs/usage.md](docs/usage.md).

**Keep provider updates constrained** - update projection assets inside this package instead of canonical definitions, keeping changes isolated from [ace-handbook](../ace-handbook).

**Enable incremental provider onboarding** - add or update PI support independently of core ACE changes, maintaining a focused provider shim layer.

## Testing

This package ships fast tests plus one installed-extension acceptance level.

- Deterministic coverage (including the JavaScript wake suite run via Node) lives under `test/fast/` and `test/js/`.
- `test/feat/` runs the ace-wake acceptance scenario against the projected extension inside the real Pi SDK runtime; it requires the `pi` CLI and Node.
- This package does not introduce `test/e2e/`.

Verification commands:

- `ace-test ace-handbook-integration-pi`
- `ace-test ace-handbook-integration-pi all`

---

Part of [ACE](https://github.com/cs3b/ace)
