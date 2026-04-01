---
doc-type: workflow
name: manage-cookbooks
title: Manage Cookbooks
description: Create and maintain handbook cookbook standards and assets
purpose: Documentation for ace-handbook/handbook/workflow-instructions/handbook/manage-cookbooks.wf.md
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-handbook:*)
  - Read
  - Write
ace-docs:
  last-updated: 2026-04-01
  last-checked: 2026-04-01
---

# Manage Cookbooks

## Goal

Create, update, and maintain cookbook assets as a handbook-owned capability. This workflow defines the canonical
`.cookbook.md` model, provenance expectations, and downstream propagation requirements for project maintainers and agents.

## Prerequisites

- Understanding of handbook asset conventions
- Access to cookbook template and handbook docs
- Clear source material for backward-derived cookbook guidance

## Project Context Loading

- Load cookbook template: `ace-handbook/handbook/templates/cookbooks/cookbook.template.md`
- Load package docs: `ace-handbook/docs/handbook.md`, `ace-handbook/docs/usage.md`, `ace-handbook/README.md`
- Load workflow catalog for consistency: `ace-handbook/handbook/workflow-instructions/handbook/`

## Process Steps

1. **Define cookbook scope and audience:**
   - Confirm cookbook category and intended audience.
   - Ensure the cookbook solves a practical implementation problem.
2. **Collect source evidence before authoring:**
   - Gather primary source inputs (existing workflows, implementation docs, validated command behavior).
   - Record where each instruction originated.
3. **Author or update cookbook in canonical format:**
   - Use `.cookbook.md` extension.
   - Keep content action-oriented and operational.
   - Store project-local cookbooks under `docs/cookbooks/`.
4. **Encode provenance and validation source:**
   - Add explicit provenance and validation references in the cookbook content.
   - Ensure each major section can be traced back to source material.
5. **Add concise propagation guidance:**
   - Include short downstream guidance for how cookbook outcomes should be reflected in docs and agent guidance.
   - Do not duplicate full cookbook bodies into `CLAUDE.md` or `AGENTS.md`.
6. **Cross-check handbook ownership boundaries:**
   - Confirm cookbook instructions refer to handbook workflows/skills, not `ace-docs` ownership.
   - Keep cookbook standards in `ace-handbook` surfaces.
7. **Validate discovery readiness:**
   - Confirm naming is protocol-friendly and resolves via `cookbook://`.
   - Validate references and internal links.
8. **Finalize and synchronize integrations:**
   - Run `ace-handbook sync` when canonical handbook skills changed.
   - Update usage docs if command examples changed.

## Success Criteria

- Cookbook guidance is defined as a handbook-owned asset model.
- `.cookbook.md` remains the canonical format.
- Provenance, validation source, and propagation guidance are explicit.
- Content is discoverable through handbook cookbook protocol surfaces.
- Documentation and workflow references remain aligned.

## Validation Commands

```bash
ace-bundle wfi://handbook/manage-cookbooks
ace-bundle wfi://handbook/review-cookbooks
ace-nav list 'cookbook://*'
ace-handbook sync
```

## Error Handling

- **Missing provenance source:** stop authoring and collect source artifacts before finalizing.
- **Ownership drift (`ace-docs` references):** rewrite guidance to point to handbook-owned workflows/skills.
- **Discovery mismatch:** verify cookbook protocol registration and file naming/paths.
