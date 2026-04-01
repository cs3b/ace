---
doc-type: workflow
name: review-cookbooks
title: Review Cookbooks
description: Review and validate cookbook assets and standards
purpose: Documentation for ace-handbook/handbook/workflow-instructions/handbook/review-cookbooks.wf.md
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-handbook:*)
  - Read
ace-docs:
  last-updated: 2026-04-01
  last-checked: 2026-04-01
---

# Review Cookbooks

## Goal

Review cookbook assets for standards compliance, provenance quality, discovery compatibility, and concise downstream
propagation guidance.

## Prerequisites

- Access to cookbook files under review
- Understanding of handbook workflow/skill ownership boundaries

## Embedded Review Standards

### Required canonical structure

Each cookbook under review must:

- use `.cookbook.md` file naming
- include `## Source Provenance` with explicit source references
- include `## Propagation Notes` with concise downstream updates
- keep workflow ownership guidance aligned to `ace-handbook`

### Canonical storage paths to validate

- Package-owned cookbooks (inside `ace-handbook`): `ace-handbook/handbook/cookbooks/`
- Project-local cookbooks (outside package scope): `.ace-handbook/cookbooks/`

## Process Steps

1. **Define review scope:**
   - Review one cookbook, a category, or all cookbook files.
2. **Validate canonical format:**
   - File naming uses `.cookbook.md`.
   - Structure remains consistent with cookbook standards.
3. **Validate provenance and source traceability:**
   - Cookbook includes backward-derived source material references.
   - Validation source for key procedures is explicit.
4. **Validate propagation guidance quality:**
   - Downstream propagation instructions are concise and actionable.
   - No instructions suggest copying full cookbook text into `CLAUDE.md` or `AGENTS.md`.
5. **Validate ownership and workflow linkage:**
   - Cookbook lifecycle references `ace-handbook` workflows/skills.
   - No wording implies cookbook ownership lives in `ace-docs`.
6. **Validate discovery and command contracts:**
   - Ensure cookbook names/locations are resolvable through `cookbook://`.
   - Confirm package-owned vs project-local path placement is correct.
   - Verify workflow commands referenced in cookbook guidance load correctly.
7. **Report findings with severity:**
   - Critical: ownership/provenance/discovery breaks.
   - Major: incomplete propagation or validation guidance.
   - Minor: wording/formatting consistency issues.

## Review Checklist

- [ ] Uses `.cookbook.md` canonical format
- [ ] Includes provenance references
- [ ] Includes validation source references
- [ ] Includes concise propagation guidance
- [ ] Avoids ownership drift to `ace-docs`
- [ ] Respects `cookbook://` discovery requirements

## Validation Commands

```bash
ace-bundle wfi://handbook/manage-cookbooks
ace-bundle wfi://handbook/review-cookbooks
ace-nav list 'cookbook://*'
ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace
```

## Success Criteria

- Cookbook reviews consistently enforce handbook cookbook standards.
- Findings clearly classify blocking vs non-blocking issues.
- Discovery and workflow command contracts are validated as part of review.
