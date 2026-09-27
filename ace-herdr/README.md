<div align="center">
  <h1> ACE - HERDR </h1>

  Zero-token push delivery and agent bootstrap for the Herdr runtime, behind the ace-hitl provider delivery contract.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-herdr"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-herdr.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-herdr` is to herdr what `ace-tmux` is to tmux: a deterministic, zero-token wrapper over the `herdr` CLI. It implements the ace-hitl push-delivery contract — `deliver(ref, answer)` maps to `herdr agent prompt <pane>`, bootstrapping the agent first (`herdr agent start`) when the pane has none, so an answer is never lost — and adds one-command agent dispatch, noiseless monitoring, and closure on top.

## How It Works

1. Every ace-hitl ask captures a reverse address (`HERDR_SESSION` / `HERDR_PANE`, schema `ace.hitl.ref/v1`). `ace-herdr deliver` pushes an answer back to that address.
2. Delivery is idempotent per event id: write-ahead delivery records under `.ace-local/herdr/deliveries/` make retries safe — identical content is never delivered twice.
3. If the target pane has no agent, `ace-herdr` bootstraps one (`herdr agent start --kind <kind> --pane <pane>`), waits for readiness, and exports `HERDR_SESSION` / `HERDR_PANE` into the agent's environment.
4. Retryable failures back off on a fixed deterministic schedule; terminal failures are reported and persisted in the delivery record.
5. `ace-herdr dispatch`, `wait`, and `close` give agents one-command subagent lifecycle with sensible defaults (same workspace as the caller, label = task id, prompt from file or stdin).

## Use Cases

- Push an HITL answer to the pane that asked, even if its agent was restarted since.
- Dispatch a subagent in one command with deterministic defaults and no LLM decisions.
- Wait for agent readiness or completion without scraping pane noise.
- Close out finished agent panes (rename/close) and return their result.

## Installation

Install as part of the ACE toolkit (see the repo README), or add to your Gemfile:

```ruby
gem "ace-herdr"
```

## Testing

Fast tests only (no live herdr needed):

```bash
ace-test ace-herdr
```

## License

MIT — see [LICENSE](LICENSE).
