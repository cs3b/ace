# Synthesize Retros Workflow Instruction

## Goal

Reduce multiple retros into a single synthesis retro. Distill common themes, recurring issues, and shared action items from N input retros into one consolidated retro using the standard retro format.

## Prerequisites

- At least 2 active retros exist to synthesize
- Access to `ace-retro` CLI

## Process Steps

### 1. Gather Retros

Find candidate retros for synthesis:

```bash
# List active retros
ace-retro list --status active

# Filter by tags if synthesizing a specific topic
ace-retro list --status active --tags TAG
```

Select which retros to include. Good candidates share a common theme, time period, or tag.

### 2. Load Content

Read each selected retro:

```bash
ace-retro show REF --content
```

Collect the content from all selected retros before proceeding to analysis.

### 3. Reduce

Analyze all input retros together. Identify:

- **Common themes** — issues or observations that appear across multiple retros
- **Recurring patterns** — problems or successes that repeat
- **Shared action items** — improvements suggested in multiple retros
- **Contradictions** — conflicting recommendations that need resolution
- **Unique insights** — one-off observations worth preserving

For each theme, note which source retros contributed to it and how frequently it appeared.

### 4. Create Synthesis Retro

```bash
ace-retro create "synthesis-TOPIC" --tags synthesis
```

Read the created file path from the output.

### 5. Populate

Fill the synthesis retro using the standard template format (`tmpl://retro/retro`). The content is distilled from the N input retros:

- **What Went Well** — patterns of success across multiple retros, validated approaches
- **What Could Be Improved** — recurring issues, systemic problems identified across retros
- **Key Learnings** — consolidated insights, with frequency noted where relevant
- **Action Items** — merged and deduplicated action items, prioritized by how often they appeared

When populating, reference source retros to provide traceability (e.g., "Identified in 3/5 retros").

### 6. Archive Sources

After the synthesis retro is populated and complete, archive each source retro — they have been "consumed" by the synthesis:

```bash
ace-retro move REF --to archive
```

Repeat for each source retro.

## Success Criteria

- Synthesis retro created using standard retro format
- Common themes and recurring patterns identified across inputs
- Action items deduplicated and prioritized by frequency
- Source retros archived after processing
- Output is a single retro that stands on its own — no external templates or analytics needed
