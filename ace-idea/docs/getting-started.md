---
doc-type: user
title: ace-idea Getting Started
purpose: Tutorial for first-run ace-idea workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-idea

This walkthrough shows the core `ace-idea` loop: capture one thought, improve it with clipboard or LLM context,
organize it, and list what should happen next.

## Prerequisites

* Ruby 3.2+
* `ace-idea` installed
* A project directory where you want ideas stored
* Optional: clipboard support for `--clipboard`
* Optional: LLM provider configuration for `--llm-enhance`

## Installation

```bash
gem install ace-idea
```

By default, `ace-idea` stores ideas in `.ace-ideas/` under your current working directory.

## 1. Capture Your First Idea

Start with a direct text capture:

```bash
ace-idea create "My idea" --title "Feature X"
```

This creates a new folder inside `.ace-ideas/` with a matching `.idea.s.md` file and a short ID you can use later.

## 2. Capture from Clipboard

When the idea is already copied, skip the paste step:

```bash
ace-idea create --clipboard
```

You can also combine clipboard text with a short lead-in:

```bash
ace-idea create "Dashboard notes" --clipboard
```

## 3. Ask for LLM Enhancement

If the idea is rough, let `ace-idea` expand it before writing the file:

```bash
ace-idea create --clipboard --llm-enhance
```

If enhancement fails, the raw capture is still saved.

## 4. Organize the Idea

Move an idea into your next queue after you review it:

```bash
ace-idea update q7w --move-to next
```

`next` is the root-scope queue alias. Use the same command for `maybe`, `anytime`, `archive`, or `root`.

## 5. List What Matters Now

See everything queued for action:

```bash
ace-idea list --in next
ace-idea status
```

`list` is useful for focused filtering. `status` gives you a broader dashboard with up-next items and recently done work.

## Common Commands

| Goal | Command |
|------|---------|
| Create a new idea | `ace-idea create "My idea" --title "Feature X"` |
| Capture from clipboard | `ace-idea create --clipboard` |
| Enhance clipboard content | `ace-idea create --clipboard --llm-enhance` |
| Move an idea into the root `next` queue | `ace-idea update q7w --move-to next` |
| List ideas in the root `next` queue | `ace-idea list --in next` |
| Show one idea in full | `ace-idea show q7w` |

## Next Steps

* Add metadata with `ace-idea update q7w --set status=in-progress --add tags=research`
* Run `ace-idea doctor --auto-fix --dry-run` to preview idea hygiene fixes
* Convert a strong idea into a task with your normal `ace-task` workflow
* Browse more commands with `ace-idea --help`
