---
doc-type: user
title: ace-idea CLI Usage Reference
purpose: Command reference for ace-idea
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-idea CLI Usage Reference

Reference for `ace-idea` commands, options, and everyday workflows.

## Installation

```bash
gem install ace-idea
```

## Command Overview

`ace-idea` ships six workflow commands:

* `create` captures a new idea from text or clipboard input
* `show` prints one idea by short or full ID
* `list` filters ideas by folder, status, tags, or generic field filters
* `update` edits frontmatter fields and folder placement
* `doctor` checks idea storage and metadata health
* `status` shows up-next and recently-done summaries

Run `ace-idea --help` for the top-level command list. Use `ace-idea version` when you only need the installed version.

## Quick Start

Capture one idea, review it, and move it into your next queue:

```bash
ace-idea create "Dark mode for night coding" --title "Dark mode"
ace-idea list
ace-idea update q7w --move-to next
ace-idea status
```

Success looks like a new folder appearing in `.ace-ideas/`, a matching ID in list output, and the idea moving into the
root-scope `next` queue after the update.

## Common Scenarios

### Scenario 1: Capture from Clipboard and Expand It

**Goal:** Turn a copied note into a structured idea file.

```bash
ace-idea create --clipboard --llm-enhance
```

**Expected output:**

```text
Idea created: 8ppq7w Dark mode
  Path: /path/to/project/.ace-ideas/8ppq7w-dark-mode/8ppq7w-dark-mode.idea.s.md
```

### Scenario 2: Move an Idea Through GTD-Style Folders

**Goal:** Keep active ideas separate from maybe-later work.

```bash
ace-idea update q7w --move-to next
ace-idea update q7w --move-to maybe
ace-idea update q7w --move-to root
```

**Expected output:**

```text
Idea updated: 8ppq7w Dark mode -> root
```

### Scenario 3: Audit the Idea Store

**Goal:** Find broken structure or metadata before ideas drift.

```bash
ace-idea doctor --auto-fix --dry-run
ace-idea status --up-next-limit 5
```

## Commands

### `ace-idea create [CONTENT]`

Create a new idea from direct text or clipboard input.

**Syntax:**

```bash
ace-idea create [CONTENT] [options]
```

**Options:**

* `--title`, `-t` - Explicit title for the new idea
* `--tags`, `-T` - Comma-separated tags
* `--move-to`, `-m` - Place the idea in `next`, `maybe`, `anytime`, or `archive`
* `--clipboard`, `-c` - Read idea content from the system clipboard
* `--llm-enhance`, `-l` - Expand or refine the captured content with the configured LLM
* `--dry-run`, `-n` - Preview the capture without writing files
* `--git-commit`, `--gc` - Commit the created idea automatically
* `--quiet`, `-q` - Suppress non-essential output
* `--verbose`, `-v` - Show verbose output
* `--debug`, `-d` - Show debug output

**Examples:**

```bash
ace-idea create "My idea"
ace-idea create "Dark mode" --title "Dark mode" --tags ux,design
ace-idea create --clipboard --llm-enhance --move-to maybe
ace-idea create "Rough note" --dry-run
```

### `ace-idea show REF`

Display one idea by full 6-character ID or 3-character shortcut.

**Syntax:**

```bash
ace-idea show REF [options]
```

**Options:**

* `--path` - Print only the file path
* `--content` - Print the raw markdown content
* `--quiet`, `-q` - Suppress non-essential output
* `--verbose`, `-v` - Show verbose output
* `--debug`, `-d` - Show debug output

**Examples:**

```bash
ace-idea show q7w
ace-idea show 8ppq7w --path
ace-idea show q7w --content
```

### `ace-idea list`

List ideas with folder, status, tag, or generic field filters.

**Syntax:**

```bash
ace-idea list [options]
```

**Options:**

* `--status`, `-s` - Filter by status: `pending`, `in-progress`, `done`, `obsolete`
* `--tags`, `-T` - Filter by comma-separated tags
* `--in`, `-i` - Filter by folder: `next`, `all`, `maybe`, `anytime`, `archive`
* `--root`, `-r` - Override the root path within the ideas tree
* `--filter`, `-f` - Repeatable `key:value` filter, including `a|b` and negation forms
* `--quiet`, `-q` - Suppress non-essential output
* `--verbose`, `-v` - Show verbose output
* `--debug`, `-d` - Show debug output

**Examples:**

```bash
ace-idea list
ace-idea list --in maybe
ace-idea list --status pending --tags ux,design
ace-idea list --filter status:pending --filter tags:ux|design
```

### `ace-idea update REF`

Update idea frontmatter and folder placement.

**Syntax:**

```bash
ace-idea update REF [options]
```

**Options:**

* `--set` - Set a scalar field with `key=value`
* `--add` - Add a value to an array field with `key=value`
* `--remove` - Remove a value from an array field with `key=value`
* `--move-to`, `-m` - Move the idea to `archive`, `maybe`, `anytime`, `next`, or `root`
* `--git-commit`, `--gc` - Commit the update automatically
* `--quiet`, `-q` - Suppress non-essential output
* `--verbose`, `-v` - Show verbose output
* `--debug`, `-d` - Show debug output

**Examples:**

```bash
ace-idea update q7w --set status=done
ace-idea update q7w --set status=in-progress --add tags=research
ace-idea update q7w --remove tags=research --move-to next
ace-idea update q7w --move-to archive
```

### `ace-idea doctor`

Run health checks across the idea store.

**Syntax:**

```bash
ace-idea doctor [options]
```

**Options:**

* `--quiet`, `-q` - Exit silently unless the check fails
* `--verbose`, `-v` - Show warnings and additional detail
* `--auto-fix`, `-f` - Apply safe fixes after confirmation
* `--auto-fix-with-agent` - Apply safe fixes and then launch an agent for the remaining issues
* `--model` - Provider/model override for agent-assisted fixes
* `--errors-only` - Hide warnings and show only errors
* `--no-color` - Disable ANSI colors
* `--json` - Emit JSON output
* `--dry-run`, `-n` - Preview fixes without writing changes
* `--check` - Restrict checks to `frontmatter`, `structure`, or `scope`

**Examples:**

```bash
ace-idea doctor
ace-idea doctor --auto-fix --dry-run
ace-idea doctor --check frontmatter --json
```

### `ace-idea status`

Show a dashboard view of up-next and recently completed ideas.

**Syntax:**

```bash
ace-idea status [options]
```

**Options:**

* `--up-next-limit` - Maximum items to show in the up-next section
* `--recently-done-limit` - Maximum items to show in the recently-done section

**Examples:**

```bash
ace-idea status
ace-idea status --up-next-limit 5
ace-idea status --recently-done-limit 3
```

## Storage Notes

By default, ideas are stored in `.ace-ideas/` under the current directory. Each idea gets its own folder and spec file:

```text
.ace-ideas/
  8ppq7w-dark-mode/
    8ppq7w-dark-mode.idea.s.md
```

Special folders such as `_maybe`, `_anytime`, and `_archive` sit under the same root and are managed through
`ace-idea update --move-to ...`. The `next` queue is the virtual root-only view, so `ace-idea update --move-to next`
returns an idea to the root and `ace-idea list --in next` filters for root-scope ideas.

## Troubleshooting

### Problem: `ace-idea create` says no content was provided

**Symptom:** You ran `create` with no positional text and no `--clipboard`.

**Solution:**

```bash
ace-idea create "Your idea text here"
```

### Problem: Clipboard capture fails

**Symptom:** `--clipboard` cannot read copied content on your system.

**Solution:** Fall back to direct text input or install the clipboard support expected by your environment.

### Problem: An idea cannot be found by shortcut

**Symptom:** `ace-idea show q7w` or `ace-idea update q7w ...` reports that the idea does not exist.

**Solution:** Use `ace-idea list --in all` to confirm the idea ID and folder placement, then retry with the full 6-character
ID if needed.

### Problem: `ace-idea doctor` says the idea directory is missing

**Symptom:** The configured ideas root does not exist yet.

**Solution:** Create an idea first or set `idea.root_dir` in config before running `doctor`.
