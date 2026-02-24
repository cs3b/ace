---
tc-id: TC-001
title: Section Preset End-to-End
mode: goal
---

## Objective

Verify that ace-bundle loads a section preset from disk, processes files matching glob patterns, executes commands, embeds content, and produces proper XML-style tags in markdown-xml format.

## Available Tools

- `ace-bundle`
- standard shell tools (`grep`, `bash`)

## Success Criteria

- Exit code: 0
- Output contains file content (README.md, package.json)
- Output contains command execution results (all 3 commands)
- Output contains embedded section content
- Output contains XML-style `<file path=...>` and `<output command=...>` tags with closing tags
- Section title "Complete Review" present in output

## Hints

- Capture command output once, then validate all criteria against the captured output.
- Validate both opening and closing XML tags to avoid partial-match false positives.
