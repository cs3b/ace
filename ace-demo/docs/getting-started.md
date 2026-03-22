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

This writes `.ace/demo/tapes/my-demo.tape.yml`.

```bash
ace-demo record my-demo
```

`my-demo` now behaves like a preset.

## 7. Record inline without a prewritten tape

```bash
ace-demo record quick-check -- "echo hello"
```

This creates both:
- a temporary `.ace-local/demo/<session>/quick-check.tape.yml`
- an output recording file in the same session folder

## 8. Tune format and speed

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
