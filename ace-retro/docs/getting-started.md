---
doc-type: user
purpose: Quickstart guide for creating, reviewing, and archiving retros with ace-retro.
ace-docs:
  last-updated: '2026-03-22'
---

# Getting Started with ace-retro

Create your first retrospective, connect it to task work, and keep your workspace tidy with archive moves.

## Prerequisites

- Ruby installed
- `gem install ace-retro`

## Installation

```bash
gem install ace-retro
```

## 1) Create your first retrospective

```bash
ace-retro create "Sprint Review" --type standard --tags sprint,team
```

Create other retro types when needed:

```bash
ace-retro create "Session Review" --type conversation-analysis
ace-retro create "Weekly Self Review" --type self-review
```

## 2) View and list retros

Every retro gets a short ID (last 3 characters of a timestamp-based identifier). Use the ID printed by `create` (e.g. `q7w`) to inspect a specific retro:

```bash
ace-retro show q7w          # replace q7w with the ID from step 1
ace-retro list
ace-retro list --in all
```

Use filters to focus your review queue:

```bash
ace-retro list --status active
ace-retro list --type standard
ace-retro list --tags sprint,team
```

## 3) Archive completed retros

```bash
ace-retro update q7w --set status=done --move-to archive   # replace q7w with your retro ID
```

Archive moves keep active retros in your main workspace while preserving historical records.

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-retro create "..." --type standard` | Create a new retrospective |
| `ace-retro show <ref>` | Display one retro by ID or shortcut |
| `ace-retro list --in all` | List active and archived retros |
| `ace-retro update <ref> --set status=done` | Update retro metadata |
| `ace-retro update <ref> --move-to archive` | Move retro to archive |
| `ace-retro doctor` | Run retro health checks |

## What to try next

- Explore additional commands in [Usage Guide](usage.md)
- Browse workflows and skills in [Handbook Reference](handbook.md)
- Use runtime help: `ace-retro --help` and `ace-retro <command> --help`
