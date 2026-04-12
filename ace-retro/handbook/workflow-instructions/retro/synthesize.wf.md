---
doc-type: workflow
title: Synthesize Retros Workflow Instruction
purpose: Documentation for ace-retro/handbook/workflow-instructions/retro/synthesize.wf.md
ace-docs:
  last-updated: 2026-04-12
  last-checked: 2026-04-12
---

# Synthesize Retros Workflow Instruction

## Goal

Reduce multiple retros into a single synthesis retro that can itself be synthesized again later. Distill recurring themes from N input retros, validate them against current repo reality, rank them by recurrence and impact, and archive the processed sources after the new synthesis is complete.

## Prerequisites

- At least 2 active retros exist to synthesize
- Access to `ace-retro` CLI
- Access to repo search tools (`rg`, file reads, `ace-bundle`) for current-state validation

## Project Context Loading

- Load `handbook/templates/retro/retro.template.md`
- Load `docs/handbook.md` and `README.md` for current package positioning
- Load current workflow examples with `ace-bundle wfi://retro/selfimprove` and `ace-bundle wfi://retro/analyze-worktree`
- Load candidate source retros with `ace-retro show REF --content`

## Process Steps

### 1. Gather Retros

Resolve the input set:

- If the user provides retro refs, synthesize exactly those refs.
- If the user provides no refs, select the 10 oldest active retros.

Find candidate retros:

```bash
# List active retros
ace-retro list --status active

# Filter by tags if synthesizing a specific topic
ace-retro list --status active --tags TAG
```

Default oldest-selection rule:

- Sort by `created_at` ascending.
- If `created_at` is missing or invalid, fall back to the timestamp decoded from the b36ts retro ID.
- If timestamps tie, sort by full retro ID ascending.

Record the exact input refs and whether selection mode was `explicit` or `oldest`.

### 2. Load Content

Read each selected retro:

```bash
ace-retro show REF --content
```

For each loaded retro, capture:

- retro ref and title
- whether it is a raw retro or an existing synthesis retro
- listed source retro refs if the retro is itself a synthesis
- the major findings, learnings, and action items

If a referenced retro cannot be loaded, mark it as skipped and do not archive it later.

### 3. Normalize Evidence

Build a normalized evidence set before ranking:

- For raw retros, treat the retro's own ID as the original source ID.
- For prior synthesis retros, expand evidence using the synthesis artifact's recorded original source IDs when available.
- Dedupe by original source ID so the same historical retro is only counted once, even when nested syntheses overlap.
- If a synthesis retro lacks source-trace metadata, fall back to its own retro ID and note reduced confidence.

This workflow must prefer under-counting over double-counting. Never inflate recurrence by counting the same original retro twice.

### 4. Reduce to Themes

Analyze all input retros together. Identify:

- **Common themes** — issues or observations that appear across multiple retros
- **Recurring patterns** — problems or successes that repeat
- **Shared action items** — improvements suggested in multiple retros
- **Contradictions** — conflicting recommendations that need resolution
- **Unique insights** — one-off observations worth preserving

For each theme, capture:

- title
- theme type (`success`, `problem`, `learning`, `action`)
- contributing original source IDs
- recurrence count from deduped original source IDs
- impact/risk/value assessment
- representative evidence snippets or paraphrases

Merge equivalent findings, but do not discard meaningful contradictions. Preserve them as explicit tension in the synthesis.

### 5. Confront Current Repo Reality

Before final ranking, validate each candidate theme against the current codebase, docs, and workflows.

Use repo inspection to determine whether the theme is:

- `open` — the gap is still substantially unaddressed
- `partial` — some protections or fixes exist, but meaningful work remains
- `addressed` — the recommendation is already implemented well enough that it should not be treated as active follow-up

Current-state validation may inspect:

- current workflow instructions in `ace-*/handbook/workflow-instructions/`
- current guides/docs in `ace-*/docs/`, `README.md`, and `handbook/`
- current implementation files when the theme is code-backed rather than process-backed

For each theme, record:

- what already exists
- what is still missing
- the status classification (`open`, `partial`, `addressed`)

### 6. Rank Findings

Rank findings using this order:

1. unresolved status: `open` before `partial` before `addressed`
2. recurrence count across deduped original source IDs
3. likely impact/risk/value
4. breadth across packages or workflows
5. confidence in the evidence

Use the ranking to shape the synthesis narrative:

- `Action Items` should include only `open` and `partial` themes.
- `addressed` themes still belong in the synthesis as validated learnings, but not as backlog-facing actions.
- Keep notable one-off insights when they materially sharpen understanding, even if they rank below the dominant themes.

### 7. Create Synthesis Retro

```bash
ace-retro create "synthesis-TOPIC" --tags synthesis
```

Read the created file path from the output.

### 8. Populate

Fill the synthesis retro using the standard template format (`tmpl://retro/retro`). The content is distilled from the N input retros:

- **What Went Well** — patterns of success across multiple retros, validated approaches
- **What Could Be Improved** — recurring issues, systemic problems identified across retros
- **Key Learnings** — consolidated insights, with frequency noted where relevant
- **Action Items** — merged and deduplicated action items, limited to `open` and `partial` themes and prioritized by recurrence and impact

Add these synthesis-specific sections:

- **Current State Validation** — themes checked against current repo reality, with `addressed` / `partial` / `open` classification
- **Ranked Improvements** — highest-value unresolved themes with recurrence, impact, current coverage, and remaining gap
- **Source Traceability** — input refs, deduped original source count, and any skipped or low-confidence evidence cases

When populating:

- reference source retros to provide traceability (e.g., "Identified in 7 original retros")
- distinguish historical recurrence from present-day gap status
- write the output so it stands on its own for later synthesis passes

Add synthesis metadata to frontmatter:

- `synthesis.input_refs`
- `synthesis.original_source_ids`
- `synthesis.original_source_count`
- `synthesis.selection_mode`

### 9. Archive Sources

After the synthesis retro is populated and complete, archive each successfully processed source retro — they have been "consumed" by the synthesis:

```bash
ace-retro update REF --move-to archive
```

Do not archive:

- refs that failed to load
- refs intentionally skipped because they duplicated another selected input before analysis
- any retro when synthesis creation or population failed

### 10. Validate

Before finishing, verify:

- the synthesis retro includes ranked unresolved improvements plus validated addressed themes
- recurrence counts reflect deduped original source IDs
- `Action Items` exclude fully addressed themes
- frontmatter contains synthesis trace metadata for future recursive synthesis
- only successfully processed source retros were archived

## Success Criteria

- Synthesis retro created using standard retro format plus synthesis trace metadata
- Common themes and recurring patterns identified across inputs with deduped original-source counting
- Current repo reality checked for major themes and reflected in the synthesis
- Action items limited to unresolved (`open` / `partial`) improvements
- Source retros archived only after successful processing
- Output stands on its own and can be synthesized again later without double-counting original evidence
