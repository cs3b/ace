---
doc-type: user
title: ace-demo Getting Started
purpose: Tutorial for first-run ace-demo workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-demo

`ace-demo` records deterministic terminal output and prepares review-ready media assets.

## 1. Prerequisites

- Ruby 3.2+
- `ace-demo` installed
- `vhs` installed for recording
- Optional: `gh` CLI for PR attachments
- Optional: `ttyd` and `chromium` for VHS local playback

## 2. Install and verify `ace-demo`

```bash
gem install ace-demo
ace-demo --version
```

## 3. Discover available presets

The built-in `hello` demo is ready to use immediately.

```bash
ace-demo list
```

If you run this in a repo where this package is present, you will see both built-in and local project presets.

## 4. Record your first demo

```bash
ace-demo record hello
```

You should see:

```text
Recorded: .ace-local/demo/hello.gif
```

## 5. Attach a demo to a pull request

Use `--pr` to post inline to PR comments.

```bash
ace-demo record hello --pr 42
```

If not using authentication yet, add `--dry-run` first:

```bash
ace-demo record hello --pr 42 --dry-run
```

## 6. Create a custom tape file

```bash
ace-demo create my-demo -- "git status"
```

This writes `.ace/demo/tapes/my-demo.tape.yml`. Record it with:

```bash
ace-demo record my-demo
```

`my-demo` now behaves like a preset.

## 7. Write a YAML tape with setup, scenes, and teardown

The generated tape from step 6 contains a single scene. For more control, edit the `.tape.yml` directly or write one from scratch.

### Tape structure

A `.tape.yml` has four optional top-level sections:

```yaml
description: Demonstrate git workflow in a clean sandbox
tags:
- git
- proof-of-work

settings:
  width: 1100
  height: 600
  font_size: 16
  format: gif
  playback_speed: 4x
  output: docs/demo/my-demo.gif

setup:
- sandbox          # create isolated working directory
- git-init         # initialize git repo (branch: main)
- copy-fixtures    # copy files from adjacent fixtures/ dir
- run: echo "ready" > status.txt   # arbitrary shell command

scenes:
- name: Check initial state
  commands:
  - type: git status
    sleep: 3s
  - type: cat status.txt
    sleep: 2s

- name: Make a commit
  commands:
  - type: git add -A
    sleep: 1s
  - type: git commit -m 'initial commit'
    sleep: 3s
  - type: git log --oneline
    sleep: 2s

teardown:
- cleanup          # remove sandbox directory (runs even on failure)
```

### Section reference

| Section | Required | Purpose |
|---------|----------|---------|
| `description` | No | Metadata shown by `ace-demo show` |
| `tags` | No | Array or comma-separated string for categorization |
| `settings` | No | Override `width`, `height`, `font_size`, `format`, `playback_speed`, `output` |
| `setup` | No | Directives that run before recording starts |
| `scenes` | **Yes** | One or more named command sequences |
| `teardown` | No | Cleanup directives that always run |

### Setup directives

| Directive | What it does |
|-----------|-------------|
| `sandbox` | Create an isolated working directory under `.ace-local/demo/sandbox/` |
| `git-init` | Run `git init -b main` and configure a demo user in the sandbox |
| `copy-fixtures` | Copy all files from a `fixtures/` directory next to the tape file |
| `run: <cmd>` | Execute an arbitrary shell command in the sandbox |

### Scene commands

Each scene has a `name` (optional) and a `commands` array. Each command has:

- `type` — the shell command to execute (compiled to VHS `Type` + `Enter`)
- `sleep` — delay after the command (default `2s`, compiled to VHS `Sleep`)

Multiple scenes record sequentially into the same output file. Use them to organize logically distinct steps.

### Teardown directives

| Directive | What it does |
|-----------|-------------|
| `cleanup` | Remove the sandbox directory |
| `run: <cmd>` | Execute an arbitrary shell command |

Teardown always runs, even when recording fails — similar to `ensure` in Ruby.

### Record the tape

```bash
ace-demo record .ace/demo/tapes/my-demo.tape.yml
```

When `settings.playback_speed` and `settings.output` are both set, recording runs in retime-only output mode:
- raw recording stays in `.ace-local/demo/<name>.<format>`
- retimed output is written exactly to `settings.output` (no `-4x` suffix)

Or, since tapes in `.ace/demo/tapes/` are discovered by name:

```bash
ace-demo record my-demo
```

### Provide fixtures

Place fixture files in a `fixtures/` directory next to the tape:

```
.ace/demo/tapes/
  my-demo.tape.yml
  fixtures/
    config.yml
    sample.txt
```

When setup includes `copy-fixtures`, these files are copied into the sandbox before recording starts.

## 8. Record inline without a prewritten tape

```bash
ace-demo record quick-check -- "echo hello"
```

This creates both:
- a temporary `.ace-local/demo/<session>/quick-check.tape.yml`
- an output recording file in the same session folder

## 9. Tune format and speed

```bash
ace-demo record hello --format mp4 --playback-speed 2x --output /tmp/hello.mp4
```

You can also post-process an existing recording:

```bash
ace-demo retime .ace-local/demo/hello.gif --playback-speed 4x
```

## Common Commands

| Goal | Command |
|------|---------|
| Show all available tapes | `ace-demo list` |
| Inspect a tape | `ace-demo show hello` |
| Record a preset | `ace-demo record hello` |
| Record with PR attachment | `ace-demo record hello --pr 42` |
| Create custom tape file | `ace-demo create my-demo -- "git status"` |
| Record inline from shell input | `ace-demo record my-demo -- "echo hello"` |
| Attach existing recording | `ace-demo attach .ace-local/demo/hello.gif --pr 42` |
| Produce faster playback | `ace-demo retime .ace-local/demo/hello.gif --playback-speed 4x` |

## What to try next

- Add multiple commands to a custom tape: `ace-demo create flow -- "git status" "git diff"`
- Try `-n/--dry-run` for each command when you want a preview
- Use `--format mp4` or `--format webm` for large demos
- Add metadata with `--desc` and `--tags` when creating custom tapes
