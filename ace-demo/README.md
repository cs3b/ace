# ace-demo

Record deterministic terminal demos and attach review-ready media to pull requests.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Setup](docs/setup.md) | [Handbook Reference](docs/handbook.md)

![ace-demo getting started](docs/demo/ace-demo-getting-started.gif)

`ace-demo` turns terminal sessions into reproducible GIF/MP4/WebM artifacts, supports inline and tape-driven recordings,
and can post the resulting media directly to GitHub pull requests.

## Use Cases

**Show command behavior in code review** - record built-in or custom tapes to replace ambiguous text-only explanations.

**Attach visual proof to pull requests** - use `--pr` during recording or `attach` for existing files to comment directly on a PR.

**Create reusable terminal demos quickly** - generate tapes from shell commands and reuse them across docs, demos, and verification loops.

## Works With

- **[ace-assign](../ace-assign)** for scoped task and assignment workflows that require demo evidence.
- **[ace-bundle](../ace-bundle)** for loading workflows and config that drive repeatable demo scenarios.
- **[gh](https://cli.github.com/)** for authenticated pull-request media attachment.
- **`vhs` + `chromium` + `ttyd`** from [setup requirements](docs/setup.md) for deterministic terminal rendering and capture.

## Features

- Tape discovery and inspection with `list` and `show`.
- Tape creation from shell command input via `create`.
- Recording from built-in presets, local tape files, or inline commands via `record`.
- PR attachment during record (`--pr`) or as a separate action (`attach`).
- Playback-speed postprocessing with `retime` and `record --playback-speed`.
- Support for GIF, MP4, and WebM output formats.

## Quick Start

```bash
ace-demo list

ace-demo record hello

ace-demo record hello --pr 42

ace-demo create my-demo -- "git status"
ace-demo record my-demo

ace-demo retime .ace-local/demo/hello.gif --playback-speed 4x

```

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Setup](docs/setup.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-demo --help`

## Agent Skills

- `as-demo-record`
- `as-demo-create`

## Part of ACE

`ace-demo` is part of [ACE](../README.md) (Agentic Coding Environment).
