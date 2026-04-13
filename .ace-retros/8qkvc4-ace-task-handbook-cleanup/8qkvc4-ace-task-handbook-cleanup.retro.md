---
id: 8qkvc4
title: ace-task-handbook-cleanup
type: standard
tags: [docs, cleanup]
created_at: "2026-03-21 20:53:29"
status: active
task_ref: 8q4.t.ums.5
---

# ace-task Handbook Cleanup & Documentation Overhaul

Scope: 17 commits, 48 files changed, +636/-2166 lines across ace-task docs, handbook skills, workflows, templates, and guides.

## What Went Well

- **Docs file separation works well**: README (sell), getting-started (tutorial), usage.md (reference), handbook.md (skill catalog) — each has a clear audience and purpose. The pattern is immediately reusable for other packages.
- **Skill ownership cleanup was overdue and clean**: Moving 8 misplaced skills to their correct packages (ace-idea, ace-retro, ace-docs, ace-test) was straightforward. Each target package already had the workflows — the skills just needed to follow.
- **Template pruning was significant**: Removing 6 dead templates (-828 lines) and renaming `templates/task-management/` → `templates/task/` simplified the structure without losing anything active. Only 3 templates are genuinely embedded in workflows.
- **manage-status → update rename aligned CLI and workflow naming**: The old workflow was a 167-line redundant wrapper around `ace-task update`. The new 44-line version bundles `--help` and adds only pattern examples — much closer to the finder.wf.md minimal pattern.
- **Incremental approach** — doing ace-task first as template, then planning to apply to other packages — avoided a big-bang rewrite and let us course-correct per-file.

## What Could Be Improved

- **Dead content accumulated silently**: 6 dead templates, 2 unused guides, 9 misplaced skills, and a bloated workflow all existed without any signal they were stale. There's no automated check for "this template/guide/skill has zero references."
- **Skill-to-package mapping was implicit**: The only way to know `as-idea-capture` belonged in ace-idea was manual inspection. The SKILL.md `source:` field said `ace-task` even though the workflow lived in ace-idea.
- **Provider projections (`.claude/skills/`, `.codex/skills/`, etc.) are manual**: After moving/deleting skills, we had to manually clean up 5 provider directories. There should be an automated sync step.
- **`tmpl://` protocol paths coupled to directory names**: Renaming `templates/task-management/` to `templates/task/` required updating 5 template references in 2 workflow files. The coupling is tight.
- **Workflow verbosity had no ceiling**: manage-status.wf.md grew to 167 lines by repeating what `--help` already says. No pattern enforcement prevented this drift.

## Key Learnings

- **The finder.wf.md pattern is the right default**: Bundle loads CLI help, instructions add only what help doesn't cover. Most workflows should start from this minimal shape.
- **`source:` in SKILL.md should match the package that owns the workflow, not where the skill file currently lives.** This would have flagged misplacement earlier.
- **Templates should be considered dead unless embedded in an active `<template>` XML block in a workflow.** Physical template files with no embedded reference are effectively orphaned.

## Action Items

- **START**: Auditing other packages' handbooks for the same misplacement pattern (skills in wrong packages, dead templates, bloated workflows)
- **START**: Adding a handbook lint check: "skill references workflow in another package" → warning
- **START**: Adding a template lint check: "template file has no `<template path=...>` reference in any .wf.md" → warning
- **CONTINUE**: Using the finder.wf.md minimal pattern as the default for new/rewritten workflows
- **CONTINUE**: Applying the README/getting-started/usage/handbook docs structure to ace-bundle, ace-review, ace-git-commit next

