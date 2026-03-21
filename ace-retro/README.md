---
doc-type: user
title: ace-retro
purpose: Documentation for ace-retro/README.md
ace-docs:
  last-updated: 2026-03-01
  last-checked: 2026-03-21
---

# ace-retro

Standalone retrospective management gem for ACE with b36ts-based IDs.

## Overview

Manages retrospectives in `.ace-retros/` using raw 6-char b36ts IDs, flat directory structure, and 5-command pattern.

## Features

- Raw b36ts IDs (no type markers): `8ppq7w`
- Folder-based storage: `{id}-{slug}/{id}-{slug}.retro.md`
- 5-command pattern: create, show, list, move, update
- Retro types: standard, conversation-analysis, self-review
- Task linking via `--task-ref`
- Special folder support: `_archive` with date partitioning

## CLI Usage

```bash
# Create retros
ace-retro create "Sprint Review" --type standard --tags sprint,team
ace-retro create "Quick self-review" --type self-review
ace-retro create "Task retro" --task-ref q7w
ace-retro create "Sprint Review" --move-to archive
ace-retro create "Sprint Review" --dry-run

# Show a retro
ace-retro show q7w                  # Formatted display
ace-retro show 8ppq7w --path        # File path only
ace-retro show q7w --content        # Raw markdown

# List retros
ace-retro list                      # All retros
ace-retro list --in archive         # Retros in _archive/
ace-retro list --type standard --status active
ace-retro list --tags sprint

# Move retros
ace-retro move q7w --to archive
ace-retro move q7w --to root        # Remove from special folder

# Update metadata
ace-retro update q7w --set status=done
ace-retro update q7w --add tags=reviewed --remove tags=in-progress

# Help and version
ace-retro help
ace-retro version
```

## Ruby API

```ruby
require "ace/retro"

manager = Ace::Retro::Organisms::RetroManager.new

# Create
retro = manager.create("Sprint Review",
                       type: "standard",
                       tags: ["sprint", "team"],
                       task_ref: "q7w")

# Show
retro = manager.show("q7w")  # last 3 chars of ID

# List
retros = manager.list(status: "active", type: "standard", in_folder: "archive", tags: ["sprint"])

# Update
manager.update("q7w", set: { "status" => "done" }, add: { "tags" => "reviewed" })

# Move
manager.move("q7w", to: "archive")
```

## Frontmatter Schema

```yaml
---
id: 8ppq7w
title: "Sprint Review"
type: standard
tags: [sprint, team]
status: active
created_at: 2026-03-01 12:00:00
task_ref: q7w
---

# Sprint Review

## What Went Well
...
```

## License

MIT
