<div align="center">
  <h1> ACE - HERDR </h1>

  Zero-token terminal transport and agent bootstrap for the Herdr runtime.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-herdr"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-herdr.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

> **State owner:** none for task, assignment, or HITL state. `ace-herdr` owns
> only terminal transport and its delivery retry records under
> `.ace-local/herdr/deliveries/`. tmux/Herdr are transports, not owners of the
> file-based flow ([docs/lab-flow.md](../docs/lab-flow.md)).

[Usage Guide](docs/usage.md)

`ace-herdr` is to herdr what `ace-tmux` is to tmux: a deterministic, zero-token
wrapper over the `herdr` CLI. It sends text and keys to panes, starts agents,
captures output, waits for agent state or output, and closes finished panes.
It also implements the HITL push-delivery transport used by `ace-hitl` adapters.

## How It Works

1. Terminal operations address panes through opaque handles; `ace-runtime`
   selects tmux or Herdr and hides the difference.
2. `ace-herdr deliver` pushes an answer to the pane that asked, bootstrapping an
   agent (`herdr agent start`) when the pane has none.
3. Delivery is idempotent per event id: write-ahead delivery records under
   `.ace-local/herdr/deliveries/` make retries safe.
4. `ace-herdr dispatch`, `wait`, and `close` give agents one-command subagent
   lifecycle with deterministic defaults.

## Use Cases

- Push an answer to the pane that asked, even if its agent restarted.
- Dispatch a subagent in one command with deterministic defaults.
- Wait for agent readiness or completion without scraping pane noise.
- Close finished agent panes and return their result.
- Use Herdr through the shared [ace-runtime](../ace-runtime) API.

## Installation

```ruby
gem "ace-herdr"
```

## Planned waves

> **Planned (L2):** the unified report/question/reply interface and configurable
> adapter set are not available yet. `ace-herdr` remains a transport/adapter
> building block; it does not own HITL state.
>
> The old durable agent inbox (`inbox`) and guarded native-source requirements
> belong to the replaced protected model and are not part of the file-based
> flow.

## Testing

Fast tests only (no live herdr needed):

```bash
bin/ace-test ace-herdr
```

## License

MIT -- see [LICENSE](LICENSE).
