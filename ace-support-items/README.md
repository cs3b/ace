# ace-support-items

Shared item management infrastructure for ACE gems -- directory scanning, ID resolution, and slug sanitization.

## Overview

`ace-support-items` provides reusable item-management primitives for ACE packages such as `ace-task`
and `ace-idea`.

It standardizes directory scanning, shortcut resolution, and slug sanitization for b36ts-based item
stores while keeping CLI field parsing and special-folder detection consistent across tools.

## Installation

Add to your gemspec:

```ruby
spec.add_dependency "ace-support-items", "~> 0.15"
```

## Core Components

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

## Basic Usage

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

## Part of ACE

`ace-support-items` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit
for agent-assisted development.

## License

MIT
