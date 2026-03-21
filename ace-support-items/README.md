---
doc-type: user
title: ace-support-items
purpose: Documentation for ace-support-items/README.md
ace-docs:
  last-updated: 2026-03-01
  last-checked: 2026-03-21
---

# ace-support-items

Shared item management infrastructure for ACE gems (ace-task, ace-idea, etc.).

## Overview

Provides reusable components for managing items (tasks, ideas) stored as directories with b36ts-based IDs:

- **`DirectoryScanner`** - Recursively scans item directories, returns `ScanResult` objects
- **`ShortcutResolver`** - Resolves 3-char suffix shortcuts to full 6-char b36ts IDs
- **`SlugSanitizer`** - Strict kebab-case slug sanitization for filesystem safety
- **`FieldArgumentParser`** - Parses `key=value` CLI arguments with type inference
- **`SpecialFolderDetector`** - Recognizes `_archive`, `_maybe`, `_anytime`, `_next` folders

## Item Directory Convention

Items follow this convention:
```
.ace-ideas/
  8ppq7w-dark-mode-support/
    8ppq7w-dark-mode-support.idea.s.md
  _maybe/
    9xzr1k-some-idea/
      9xzr1k-some-idea.idea.s.md
```

## Usage

```ruby
require "ace/support/items"

# Scan for items
scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
  ".ace-ideas",
  file_pattern: "*.idea.s.md"
)
results = scanner.scan

# Resolve shortcut
resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)
result = resolver.resolve("q7w")  # Matches ID ending in "q7w"
```

## License

MIT
