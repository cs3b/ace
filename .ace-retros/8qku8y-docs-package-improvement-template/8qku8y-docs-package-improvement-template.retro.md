---
id: 8qku8y
title: docs-package-improvement-template
type: standard
tags: []
created_at: "2026-03-21 20:09:58"
status: active
task_ref: 8q4.t.ums.5
---

# Documentation Package Improvement Template

Learnings from improving ace-task docs — patterns to apply to every package.

## What Went Well

- **Separating concerns across files works**: README (sell/why), getting-started.md (tutorial), usage.md (reference), handbook.md (agent catalog) — each file has a clear purpose and audience
- **Value-first README structure**: tagline → demo GIF → why → features → integrations → skills → docs links creates a natural funnel from "what is this?" to "let me try it"
- **Handbook.md fills a real gap**: 21 skills and 14 workflows were completely undocumented for users — now discoverable without reading source code

## What Could Be Improved

Every package in the batch (ace-bundle, ace-review, ace-git-commit, root README) needs the same treatment. The initial fork-generated docs have these common issues:

### 1. README is too thin — missing sell speech and integrations
- **Current**: Generic tagline, quick-start commands inline, no interop mentions
- **Needed**: Punchy first line that sells the value, "Works with" section showing how the tool fits in the ecosystem, agent skills summary
- **Pattern**: First line = verb phrase describing what users get (e.g., "Draft, organize, and tackle tasks — for you and your agents")

### 2. No usage.md — CLI reference missing
- **Current**: Common commands in README (wrong place), no full options reference
- **Needed**: Dedicated usage.md with every command, every flag, options tables, and examples sourced from actual CLI code
- **Pattern**: Read `lib/*/cli/commands/*.rb` for accurate flags, don't guess from --help

### 3. No handbook.md — agent capabilities undocumented
- **Current**: Skills and workflows exist in handbook/ but no user-facing catalog
- **Needed**: handbook.md listing all skills (grouped by domain), workflow instructions (with wfi:// paths), guides, and templates
- **Pattern**: One sentence per skill describing WHAT it does, not HOW

### 4. Getting-started.md needs Common Commands table
- **Current**: Tutorial steps only, no quick-reference
- **Needed**: Common Commands table (same as usage.md) plus links to usage.md and handbook.md at the bottom
- **Pattern**: Tutorial walks through, table provides cheat sheet

### 5. Demo tapes are minimal
- **Current**: 4 basic commands, doesn't showcase the tool's real capabilities
- **Needed**: Expanded scenarios covering list/filter, create-with-options, show+tree, update/archive
- **Pattern**: Demo should show the most impressive/useful workflows, skip boring ones (like plan which needs LLM)

### 6. README should NOT contain commands
- **Current**: Quick Start and Common Commands sections in README
- **Needed**: Remove commands from README entirely — just link to getting-started.md
- **Pattern**: README sells, getting-started.md teaches

### 7. Cross-domain skills need careful attribution
- **Current**: All handbook skills listed as if they belong to the package
- **Needed**: Separate package-owned skills from cross-domain skills that happen to ship in the same handbook
- **Pattern**: README lists only skills that are ABOUT the package's domain

## Action Items

### Per-package checklist (apply to ace-bundle, ace-review, ace-git-commit):

- **STOP**: Putting quick-start commands in README — link to getting-started.md instead
- **STOP**: Listing all handbook skills as if they belong to the package — separate by domain ownership
- **START**: Creating usage.md with full CLI reference sourced from actual command files
- **START**: Creating handbook.md cataloging all skills, workflows, guides, templates
- **START**: Writing sell-first taglines that describe user value in first line
- **START**: Adding "Works with" section showing ecosystem integrations
- **START**: Expanding demo tapes to cover 4-6 real scenarios
- **CONTINUE**: Keeping getting-started.md as end-to-end tutorial with common commands table

### Template structure for each package:

```
README.md          — sell: tagline, GIF, why, features, integrations, skills, doc links
docs/getting-started.md — teach: tutorial + common commands table + next steps
docs/usage.md      — reference: every command, every flag, examples
docs/handbook.md   — catalog: skills, workflows, guides, templates
docs/demo/*.tape   — demo: 4-6 real scenarios for GIF recording
```

