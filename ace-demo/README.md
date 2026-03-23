<div align="center">
  <h1> ACE - Demo </h1>

  Record deterministic terminal demos and attach review-ready media to pull requests.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-demo"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-demo.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

![ace-demo demo](docs/demo/ace-demo-getting-started.gif)

`ace-demo` turns terminal sessions into reproducible GIF/MP4/WebM artifacts, supports inline and tape-driven recordings, and can post the resulting media directly to GitHub pull requests. It relies on `vhs`, `chromium`, and `ttyd` for deterministic terminal rendering (see [setup requirements](docs/setup.md)).

## How It Works

1. Define a demo as a tape (built-in preset, local tape file, or inline commands) that captures a terminal session.
2. Record the tape into a GIF, MP4, or WebM artifact with optional playback-speed control.
3. Attach the recording to a GitHub pull request with `--pr` or the separate `attach` command.

## Use Cases

**Show command behavior in code review** - record built-in or custom tapes with [`ace-demo record`](docs/usage.md) to replace ambiguous text-only explanations. Use `/as-demo-record` for agent-driven recording sessions.

**Attach visual proof to pull requests** - use `--pr` during recording or [`ace-demo attach`](docs/usage.md) for existing files to comment directly on a PR through [gh](https://cli.github.com/) integration.

**Create reusable terminal demos quickly** - generate tapes from shell commands with `/as-demo-create` or [`ace-demo create`](docs/usage.md) and reuse them across docs, demos, and verification loops.

**Provide demo evidence for assignments** - pair with [ace-assign](../ace-assign) for scoped task workflows that require demo evidence, using [ace-bundle](../ace-bundle) for loading workflow context that drives repeatable demo scenarios.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)

