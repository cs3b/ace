---
doc-type: user
purpose: CLI reference for ace-retro commands and options.
ace-docs:
  last-updated: '2026-03-22'
---

# ace-retro CLI Reference

Complete command reference for `ace-retro`.

## Installation

```bash
gem install ace-retro
```

## Testing Model

Use the restarted package test contract:

- `ace-test ace-retro` for default deterministic fast coverage.
- `ace-test ace-retro all` for full deterministic coverage.
- `ace-test-e2e ace-retro` for workflow-value scenario coverage in `test/e2e/`.
- `ace-test ace-retro feat` only when the package has explicit `test/feat/` contracts.

## Global Options

All commands support:

| Flag | Description |
|------|-------------|
| `-q`, `--quiet` | Suppress non-essential output |
| `-v`, `--verbose` | Show verbose output |
| `-d`, `--debug` | Show debug output |
| `-h`, `--help` | Show command help |

## Commands

### ace-retro create TITLE

Create a new retrospective.

| Option | Alias | Description |
|--------|-------|-------------|
| `--type` | `-t` | Retro type: `standard`, `conversation-analysis`, `self-review` |
| `--tags` | `-T` | Comma-separated tags |
| `--move-to` | `-m` | Create directly in a target folder (for example `archive`) |
| `--dry-run` | `-n` | Preview without writing |
| `--gc`, `--git-commit` | | Auto-commit changes |

```bash
ace-retro create "Sprint Review" --type standard --tags sprint,team
ace-retro create "Session Review" --type conversation-analysis
ace-retro create "Release Retro" --move-to archive
```

### ace-retro show REF

Show one retro by full 6-char ID or 3-char shortcut.

| Option | Description |
|--------|-------------|
| `--path` | Print file path only |
| `--content` | Print raw markdown content |

```bash
ace-retro show q7w
ace-retro show 8ppq7w --path
ace-retro show q7w --content
```

### ace-retro list

List retros with optional filtering.

| Option | Alias | Description |
|--------|-------|-------------|
| `--status` | `-s` | Filter by status (`active`, `done`) |
| `--type` | `-t` | Filter by type |
| `--tags` | `-T` | Filter by tags (comma-separated, any match) |
| `--in` | `-i` | Folder scope: `next` (root only), `all`, `archive` |
| `--root` | `-r` | Override retros root path |

```bash
ace-retro list
ace-retro list --in all
ace-retro list --in archive --type standard
ace-retro list --status active --tags sprint,team
```

### ace-retro update REF

Update frontmatter fields and/or move a retro between folders.

| Option | Description |
|--------|-------------|
| `--set` | Set scalar metadata: `key=value` (repeatable) |
| `--add` | Add to array field: `key=value` (repeatable) |
| `--remove` | Remove from array field: `key=value` (repeatable) |
| `--move-to`, `-m` | Move retro to folder (`archive`, `next`) |
| `--gc`, `--git-commit` | Auto-commit changes |

```bash
ace-retro update q7w --set status=done
ace-retro update q7w --set status=done --set title="Refined title"
ace-retro update q7w --add tags=reviewed --remove tags=in-progress
ace-retro update q7w --set status=done --move-to archive
```

### ace-retro doctor

Run health checks across retros.

| Option | Alias | Description |
|--------|-------|-------------|
| `--auto-fix` | `-f` | Auto-fix safe issues |
| `--auto-fix-with-agent` | | Auto-fix then launch agent for unresolved items |
| `--model` | | Provider:model for agent session |
| `--errors-only` | | Show only errors |
| `--no-color` | | Disable colored output |
| `--json` | | Emit JSON output |
| `--dry-run` | `-n` | Preview fixes without applying |
| `--check` | | Limit to check: `frontmatter` (YAML metadata block at file top), `structure`, `scope` |

```bash
ace-retro doctor
ace-retro doctor --auto-fix
ace-retro doctor --auto-fix --dry-run
ace-retro doctor --check frontmatter
ace-retro doctor --json
```

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-retro create "..." --type standard` | Create a retrospective |
| `ace-retro show <ref>` | Display one retro |
| `ace-retro list --in all` | List active and archived retros |
| `ace-retro update <ref> --set status=done` | Update metadata |
| `ace-retro update <ref> --move-to archive` | Archive a retro |
| `ace-retro doctor` | Validate retro health |

## Runtime Help

```bash
ace-retro help
ace-retro <command> --help
```
