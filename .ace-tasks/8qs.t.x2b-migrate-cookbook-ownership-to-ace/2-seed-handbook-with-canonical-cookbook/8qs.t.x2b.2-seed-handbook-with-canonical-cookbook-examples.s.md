---
id: 8qs.t.x2b.2
status: draft
priority: medium
created_at: "2026-03-29 22:02:43"
estimate: TBD
dependencies: [8qs.t.x2b.0, 8qs.t.x2b.1]
tags: [docs, cookbook, examples, ace-handbook]
parent: 8qs.t.x2b
bundle:
  presets: [project]
  files:
    - ace-handbook/handbook/templates/cookbooks/cookbook.template.md
    - CLAUDE.md
    - AGENTS.md
  commands: []
needs_review: false
---

# Seed handbook with canonical cookbook examples

## Objective

Prove the cookbook model with two real, package-owned examples that show how backward-derived project learnings become reusable handbook cookbooks and distilled project guidance.

## Behavioral Specification

### User Experience

- **Input:** A maintainer wants concrete examples of what a good ACE cookbook looks like, and a project maintainer wants to see how cookbook learnings should be turned into actionable docs and concise agent rules.
- **Process:** The package adds two canonical example cookbooks based on completed work: an Astro project setup flow and a multi-ruby-gem monorepo setup flow.
- **Output:** `ace-handbook` ships two discoverable cookbooks that demonstrate the intended tone, provenance model, structure, and propagation behavior.

### Expected Behavior

1. The package ships an Astro cookbook and a multi-ruby-gem monorepo cookbook under handbook-owned cookbook content.
2. Both example cookbooks are derived from real work and explicitly state the source context they were learned from.
3. Both examples stay action-first and reusable rather than project-diary style.
4. Both examples include a section or metadata that identifies what should be distilled into project docs and what should be distilled into concise agent guidance.
5. Both examples are discoverable through `cookbook://`.

### Interface Contract

```bash
ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace
ace-nav resolve cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace
```

### Error Handling

- If either example lacks provenance from real work, it does not validate the cookbook model.
- If either example duplicates full cookbook content into `CLAUDE.md` or `AGENTS.md`, it violates the propagation model.
- If either example is too specific to a single project and cannot serve as reusable starting guidance, it is incomplete.

### Edge Cases

- The Astro example may include stack-specific gotchas, but those must be framed as reusable guidance.
- The monorepo example must cover ACE-specific sequencing and conventions without assuming the ACE mono-repo is the only valid downstream shape.

## Success Criteria

1. Two canonical cookbook files exist in the handbook-owned cookbook location.
2. Both resolve through `cookbook://`.
3. Both use the updated cookbook structure and provenance expectations from child `8qs.t.x2b.0`.
4. Both define concise downstream propagation targets for docs and agent guidance.
5. The examples are strong enough to serve as references for future cookbook drafting and review.

## Validation Questions

- No blocking questions remain.
- This task depends on `8qs.t.x2b.0` and `8qs.t.x2b.1` so the examples land in the final ownership model and use the final standards.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type:** Standalone subtask
- **Slice outcome:** handbook ships two canonical cookbook examples
- **Advisory size:** Medium
- **Context dependencies:** final handbook cookbook template, final discovery path, concise agent-guidance model

## Verification Plan

### Unit/Component Validation

- `ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace` succeeds.
- `ace-nav resolve cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace` succeeds.

### Integration/E2E Validation

- Both examples read as reusable ACE cookbooks, not one-off build logs.
- Both examples show how cookbook learnings become distilled rules for package docs and agent instruction surfaces.

### Failure/Invalid Path Validation

- No example omits its “learned from” context.
- No example becomes a tutorial/reference hybrid that loses the action-first cookbook behavior.

### Verification Commands

- `ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace`
- `ace-nav resolve cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace`

## Scope of Work

### Included

- Two canonical example cookbooks
- Provenance and propagation modeling inside those examples

### Out of Scope

- Broader cookbook library beyond the first two examples
- Implementation of downstream project docs updates outside the example guidance itself

## Deliverables

### Behavioral Specifications

- Astro cookbook contract
- Multi-ruby-gem monorepo cookbook contract

### Validation Artifacts

- Cookbook URIs for both examples

## References

- User-provided Astro cookbook draft
- Current ACE mono-repo conventions
- `CLAUDE.md`
- `AGENTS.md`
