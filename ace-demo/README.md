<div align="center">
  <h1> ACE - Demo </h1>

  Record terminal sessions as proof-of-work evidence for pull requests.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-demo"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-demo.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-demo demo](docs/demo/ace-demo-getting-started.gif)

`ace-demo` records terminal sessions as proof-of-work evidence for agent-driven workflows. Tapes define what to capture — either as simple [VHS](https://github.com/charmbracelet/vhs) scripts (`.tape`) or as YAML specs (`.tape.yml`) with sandbox setup, scenes, and teardown.

Recordings attach directly to GitHub pull requests as reviewable evidence. Requires `vhs`, `chromium`, and `ttyd` for deterministic rendering (see [setup requirements](docs/setup.md)).

## How It Works

1. **Define a tape** — inline commands, a VHS `.tape` script, or a `.tape.yml` with sandbox setup, recording scenes, and teardown cleanup.
2. **Record** — ace-demo compiles the tape to VHS, executes in an isolated sandbox, and produces a GIF, MP4, or WebM artifact.
3. **Deliver evidence** — attach the recording to a GitHub pull request with `--pr`, where it serves as proof-of-work for code review or assignment verification.

## Tape Format

A `.tape.yml` file defines a self-contained recording scenario:

```yaml
setup:
- sandbox            # create isolated working directory
- git-init           # initialize a git repo in the sandbox
- copy-fixtures      # copy fixture files from adjacent fixtures/ dir

scenes:
- name: Main flow
  commands:
  - type: ace-demo list
    sleep: 4s
  - type: ace-demo record hello
    sleep: 6s

teardown:
- cleanup            # remove sandbox directory
```

- **setup** — sandbox isolation, git init, fixture copying, or arbitrary shell via `run: <cmd>`
- **scenes** — named command sequences compiled to VHS directives (`Type`, `Enter`, `Sleep`)
- **teardown** — cleanup directives that always run (even on failure)
- **settings** — optional `font_size`, `width`, `height`, `format` overrides

Legacy `.tape` files use raw VHS syntax directly. See the [Usage Guide](docs/usage.md) for the full tape specification.

## Use Cases

**Deliver proof-of-work for agent tasks** — pair with [ace-assign](../ace-assign) for scoped task workflows that require demo evidence, using [ace-bundle](../ace-bundle) for loading workflow context that drives repeatable demo scenarios.

**Attach visual evidence to pull requests** — record a tape with [`ace-demo record --pr`](docs/usage.md) or attach an existing file with [`ace-demo attach`](docs/usage.md) so reviewers see actual terminal output. Use `/as-demo-record` for agent-driven recording sessions.

*Future: web interaction recording is planned alongside terminal capture.*

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
