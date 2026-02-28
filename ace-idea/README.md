# ace-idea

Standalone idea management gem for ACE with b36ts-based IDs.

## Overview

Manages ideas in `.ace-ideas/` using raw 6-char b36ts IDs, flat directory structure, and 5-command pattern.

## Features

- Raw b36ts IDs (no type markers): `8ppq7w`, not `8pp.i.q7w`
- Folder-based storage: `{id}-{slug}/{id}-{slug}.idea.s.md`
- 5-command pattern: create, show, list, move, update
- Clipboard capture (text, rich media, images)
- LLM enhancement with 3-Question Brief structure
- Special folder support: `_archive`, `_maybe`, `_anytime`, `_next`

## CLI Usage

```bash
# Create ideas
ace-idea create "Dark mode for night coding" --title "Dark mode" --tags ux,design --move-to next
ace-idea create --clipboard --llm-enhance --move-to next
ace-idea create "rough idea" --dry-run

# Show an idea
ace-idea show q7w                  # Formatted display
ace-idea show 8ppq7w --path        # File path only
ace-idea show q7w --content        # Raw markdown

# List ideas
ace-idea list                      # All ideas
ace-idea list --in maybe           # Ideas in _maybe/
ace-idea list --tags ux --status pending

# Move ideas
ace-idea move q7w --to archive
ace-idea move q7w --to maybe
ace-idea move q7w --to root        # Remove from special folder

# Update metadata
ace-idea update q7w --set status=done
ace-idea update q7w --add tags=implemented --remove tags=pending-review

# Help and version
ace-idea help
ace-idea version
```

## Ruby API

```ruby
require "ace/idea"

manager = Ace::Idea::Organisms::IdeaManager.new

# Create
idea = manager.create("Dark mode would be great for night coding",
                      title: "Dark mode support",
                      tags: ["ux", "design"],
                      move_to: "next")

# Create from clipboard
idea = manager.create_from_clipboard(llm_enhance: true)

# Show
idea = manager.show("q7w")  # last 3 chars of ID

# List
ideas = manager.list(status: "pending", in_folder: "maybe", tags: ["ux"])

# Update
manager.update("q7w", set: { "status" => "done" }, add: { "tags" => "implemented" })

# Move
manager.move("q7w", to: "archive")
```

## Frontmatter Schema

```yaml
---
id: 8ppq7w
status: pending          # pending, in-progress, done, obsolete
title: "Dark mode support"
tags: [ux, design]
created_at: 2026-02-26 19:15:00
---

# Dark mode support

## What I Hope to Accomplish
...
```

## License

MIT
