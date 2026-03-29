---
id: 8qs.t.x2b.0
status: draft
priority: medium
created_at: "2026-03-29 22:02:43"
estimate: TBD
dependencies: []
tags: [docs, cookbook, ace-handbook, protocols, workflows]
parent: 8qs.t.x2b
bundle:
  presets: [project]
  files:
    - ace-handbook/handbook/templates/cookbooks/cookbook.template.md
    - ace-handbook/docs/handbook.md
    - ace-handbook/docs/usage.md
    - ace-handbook/README.md
  commands: []
needs_review: false
---

# Create handbook cookbook standards and workflows

## Objective

Define the canonical cookbook asset model in `ace-handbook`, including standards, template shape, handbook workflows, handbook skills, documentation surface, and `cookbook://` discovery.

## Behavioral Specification

### User Experience

- **Input:** A maintainer wants one handbook-owned workflow for creating and reviewing cookbooks, and a project maintainer wants cookbook assets to be discoverable and explained like other handbook assets.
- **Process:** The package introduces cookbook-specific standards and external interfaces without creating a second file format or splitting ownership across packages.
- **Output:** `ace-handbook` exposes clear cookbook creation and review paths, ships a cookbook-aware template, documents the asset class, and resolves cookbook resources through nav discovery.

### Expected Behavior

1. Cookbook standards are defined as a handbook-owned asset model rather than an `ace-docs` workflow.
2. The `.cookbook.md` format remains canonical; the task does not invent a second cookbook format.
3. `ace-handbook` exposes two cookbook-facing workflows: manage and review.
4. `ace-handbook` exposes matching cookbook-facing skills.
5. `cookbook://` discovery resolves handbook cookbook content.
6. Handbook documentation explains cookbooks alongside guides, workflows, agents, and templates.
7. Cookbook guidance explicitly requires backward-derived source material and concise downstream propagation into project docs and agent guidance.

### Interface Contract

```bash
ace-bundle wfi://handbook/manage-cookbooks
ace-bundle wfi://handbook/review-cookbooks
ace-nav list 'cookbook://*'
ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace
ace-handbook sync
```

### Error Handling

- If cookbook discovery exists but handbook docs do not mention the asset type, the behavior is incomplete.
- If the workflows create cookbook content but do not encode provenance or propagation expectations, the behavior is incomplete.
- If the package exposes cookbook skills without clear workflow loading paths, the behavior is incomplete.

### Edge Cases

- Cookbook standards must distinguish cookbooks from guides and reference docs.
- Cookbook instructions must support project-local storage under `docs/cookbooks/` while the package keeps its own canonical examples.
- Agent-facing propagation must remain distilled and concise.

## Success Criteria

1. `ace-handbook` has cookbook-specific workflow instructions and skills.
2. The handbook cookbook template requires provenance, validation source, and propagation guidance.
3. `cookbook://` discovery works for handbook-owned cookbook files.
4. README, handbook reference, and usage docs describe cookbooks as first-class handbook assets.
5. A downstream project maintainer can discover the cookbook interfaces without reading `ace-docs`.

## Validation Questions

- No blocking questions remain.
- The change intentionally combines standards, docs surface, and cookbook discovery into one vertical slice because users experience them as one handbook capability.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type:** Standalone subtask
- **Slice outcome:** `ace-handbook` presents a coherent cookbook interface surface
- **Advisory size:** Medium
- **Context dependencies:** handbook docs, template, nav protocol source layout, root agent guidance surfaces

## Verification Plan

### Unit/Component Validation

- `ace-bundle wfi://handbook/manage-cookbooks` loads.
- `ace-bundle wfi://handbook/review-cookbooks` loads.
- `ace-nav list 'cookbook://*'` shows handbook cookbook items.

### Integration/E2E Validation

- Handbook docs describe when to use cookbooks, how they differ from guides/workflows, and where project-local cookbooks live.
- Cookbook standards, workflows, skills, and docs all agree on `.cookbook.md` and category-based naming.

### Failure/Invalid Path Validation

- No docs tell users that `ace-docs` is still the cookbook owner.
- No interface tells users to duplicate full cookbook text into `CLAUDE.md` or `AGENTS.md`.

### Verification Commands

- `ace-bundle wfi://handbook/manage-cookbooks`
- `ace-bundle wfi://handbook/review-cookbooks`
- `ace-nav list 'cookbook://*'`

## Scope of Work

### Included

- Cookbook standards and workflow definitions
- Cookbook skill definitions
- Cookbook template updates
- Cookbook protocol registration
- Handbook README and docs updates

### Out of Scope

- Removing `ace-docs` workflow references
- Writing the two example cookbook files

## Deliverables

### Behavioral Specifications

- Cookbook asset definition
- Cookbook creation and review interface contracts
- Cookbook discovery behavior

### Validation Artifacts

- Draft usage doc describing cookbook-facing commands and scenarios

## References

- `ace-handbook/handbook/templates/cookbooks/cookbook.template.md`
- `ace-handbook/docs/handbook.md`
- `ace-handbook/docs/usage.md`
- `ace-handbook/README.md`
