---
id: 8qm4nu
title: selfimprove-readme-overseer-feedback
type: self-improvement
tags: [process-fix]
created_at: "2026-03-23 03:06:29"
status: active
---

# selfimprove-readme-overseer-feedback

## What Went Well

- Use Cases pattern continued to work well for ace-overseer
- Blockquote tagline, Ruby badge, and "Works with:" line landed quickly once identified
- Linking actual preset/workflow files gives readers concrete entry points

## What Could Be Improved

- Intro paragraph listed subcommands instead of describing the problem space (ambiguous instructions — guide didn't say "don't list commands")
- Agent described multi-task as parallel worktrees when implementation uses single worktree (assumed context — relied on research summary, not code)
- CLI example omitted `--preset` flag (missing example — guide didn't specify "include all meaningful flags")
- Prose repeated what a code block already showed (missing validation — no guidance against redundancy)
- Customize use case didn't link actual config files in other packages (missing example — guide only covered `docs/usage.md` linking)

## Action Items

- [x] Guide: intro paragraph now says "do not list subcommands or features — let Use Cases do that"
- [x] Guide: Use Cases section now includes rules for CLI flags, prose/code redundancy, and cross-package config linking
- [x] Template: intro comment updated to say "do NOT list subcommands or features here"

