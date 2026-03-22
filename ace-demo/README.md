---
doc-type: user
title: ace-demo
purpose: Landing page for ace-demo
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-demo

`ace-demo` records terminal demos and attaches them to pull requests.

![ace-demo getting started](docs/demo/ace-demo-getting-started.gif)

Record deterministic terminal demos as GIF, MP4, or WebM files and post visual proof directly in code review.

## Why

`ace-demo` makes reproducible terminal recording simple for teams and agents:
- It turns command output into stable review artifacts, not flaky screen recordings.
- It reduces ambiguity by showing exactly what ran and what changed.
- It brings consistency when human and AI contributors need the same workflow.

## Works With

- `ace-assign` for scoped task workflows
- `ace-bundle` for workflow and config loading
- `gh` for authenticated PR attachments
- `ace-demo` package-owned skills for demos and recordings

## Agent Skills

- `as-demo-record`
- `as-demo-create`

## Features

- Built-in presets and project-level `.ace/demo/tapes` overrides
- Inline recording from shell commands
- PR attachment for existing recordings
- Playback-speed postprocessing (`retime` and `--playback-speed`)
- Tape discovery (`list`) and inspection (`show`)

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Catalog](docs/handbook.md)
- Command help: `ace-demo --help`

## Part of ACE

`ace-demo` is part of [ACE](../README.md): CLI tools for practical agent workflows.
