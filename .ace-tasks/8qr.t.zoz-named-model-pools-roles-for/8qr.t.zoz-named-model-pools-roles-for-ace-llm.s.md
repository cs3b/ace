---
id: 8qr.t.zoz
status: pending
priority: medium
created_at: "2026-03-28 23:47:46"
estimate: TBD
dependencies: []
tags: [ace-llm, config, model-resolution, orchestrator]
bundle:
  presets: [project]
  files: [.ace/llm/config.yml, .ace/task/config.yml, .ace/review/config.yml, .ace/assign/config.yml, .ace/e2e-runner/config.yml, .ace-tasks/8qr.t.zoz-named-model-pools-roles-for/0-implement-role-resolution-in-ace/8qr.t.zoz.0-implement-role-resolution-in-ace-llm.s.md, .ace-tasks/8qr.t.zoz-named-model-pools-roles-for/1-migrate-ace-configs-to-roles/8qr.t.zoz.1-migrate-ace-configs-to-roles-first-model.s.md, .ace-tasks/8qr.t.zoz-named-model-pools-roles-for/1-migrate-ace-configs-to-roles/ux-usage.md]
  commands: []
needs_review: false
---

# Roles-first LLM configuration rollout

## Objective

Roll out named model roles across ACE in two steps: first add `role:` support in `ace-llm`, then migrate ACE consumer configs to use roles first. This should make provider and model changes centrally manageable through `llm.roles` without per-file edits across the repo.

## Behavioral Specification

### User Experience

- **Input:** Operators define stable role names in `llm.roles`; ACE consumer configs reference those roles instead of hardcoded provider/model strings wherever possible
- **Process:** The rollout is split into two child tasks: `8qr.t.zoz.0` adds the `ace-llm` capability, and `8qr.t.zoz.1` migrates shipped and project configs, presets, docs, examples, and fixtures to the new roles-first style, standardizing onto one canonical role catalog
- **Output:** The system has a central role catalog, consumer configs prefer `role:<name>`, and changing a role definition updates many consumers without touching each consumer file

### Expected Behavior

1. The parent task acts only as an orchestrator and rollout contract
2. Child `8qr.t.zoz.0` delivers `role:` support in `ace-llm`
3. Child `8qr.t.zoz.1` migrates ACE consumer surfaces to use those roles
4. The migration child covers project config, package defaults, review presets, execution-provider fields, docs, examples, and fixtures in one task, and intentionally standardizes currently divergent project/default selections onto the canonical role catalog
5. The parent is complete when both children are complete and the repo has a coherent roles-first configuration story

### Interface Contract

```yaml
# Central role catalog
.ace/llm/config.yml:
  llm:
    roles:
      doctor:
        - gemini:flash-latest@yolo
      planner:
        - codex:gpt@ro
      review-default:
        - codex:codex@ro
      review-synthesizer:
        - codex:gpt@ro
      review-fallback:
        - claude:sonnet
      review-claude:
        - claude:opus@ro
      review-codex:
        - codex:gpt@ro
      review-gemini:
        - gemini:pro-latest@ro
      assign-executor:
        - codex:codex@yolo
      e2e-executor:
        - claude:haiku@yolo
      e2e-reporter:
        - claude:haiku
      prompt-enhance:
        - glite
      commit:
        - codex:mini
      docs-analysis:
        - glite
      idea-enhance:
        - gemini:flash-latest
      compressor:
        - glite
      sim-primary:
        - google:flash-preview
      sim-synthesis:
        - claude:haiku
```

```yaml
# Consumer configs after rollout
task:
  doctor_agent_model: role:doctor
  plan:
    model: role:planner

review:
  defaults:
    model: role:review-default
  feedback:
    synthesis_model: role:review-synthesizer
    fallback_models:
      - role:review-fallback
```

### Error Handling

- If child `8qr.t.zoz.0` does not land the `role:` capability, child `8qr.t.zoz.1` cannot be completed
- If a consumer surface cannot accept `role:<name>` without parser/loader work, that gap must be captured in child `8qr.t.zoz.1` rather than silently skipped

### Edge Cases

- Multi-model review presets remain arrays; each array element becomes a role reference rather than collapsing the preset to one role
- `provider:` fields that currently accept `provider:model@preset` remain valid surfaces for migration when they represent LLM choice rather than provider metadata
- Docs, examples, and fixtures are part of the rollout, not deferred to an unspecified future task

## Success Criteria

1. The task tree contains exactly two direct children: `8qr.t.zoz.0` and `8qr.t.zoz.1`
2. Child `8qr.t.zoz.0` completely specifies the `ace-llm` role feature
3. Child `8qr.t.zoz.1` completely specifies the ACE migration scope in one task without nested subtasks
4. The role catalog is explicit enough that implementers do not need to invent role names later
5. Changing one role definition is explicitly documented as a system-wide update mechanism

## Validation Questions

- No blocking behavioral questions remain
- The rollout intentionally uses one migration child task, not a deeper task tree

## Vertical Slice Decomposition (Task/Subtask Model)

**Orchestrator with two child tasks**

- **Child `8qr.t.zoz.0`:** Implement role resolution in `ace-llm`
- **Child `8qr.t.zoz.1`:** Migrate ACE configs to roles-first model selection
- **Advisory size:** Large
- **Context dependencies:** `.ace/llm/config.yml`, consumer config surfaces, child task specs

## Verification Plan

### Unit/Component Validation

- `ace-task show t.zoz` reports exactly two direct children
- `ace-task show t.zoz.1` reports no subtasks

### Integration/E2E Validation

- Child `8qr.t.zoz.0` and child `8qr.t.zoz.1` together cover both capability and rollout behavior
- The role catalog shown in the specs maps the repo's current hardcoded selections to stable role names

### Failure/Invalid Path Validation

- No accidental extra migration grandchildren remain under `8qr.t.zoz.1`
- The parent no longer contains the detailed `ace-llm` implementation behavior that belongs in child `8qr.t.zoz.0`

### Verification Commands

- `ace-task show t.zoz`
- `ace-task show t.zoz.0`
- `ace-task show t.zoz.1`

## Scope of Work

### Included

- Parent orchestration spec for the roles rollout
- Two-child task structure
- Explicit role catalog for the rollout
- Clear division between capability work and migration work

### Out of Scope

- Implementing the `ace-llm` role engine in this parent task
- Executing consumer config migrations in this parent task
- Reintroducing nested migration subtasks under `8qr.t.zoz.1`

## Deliverables

### Behavioral Specifications

- Parent rollout contract
- Child `ace-llm` feature spec
- Child system migration spec

### Validation Artifacts

- Two-child task tree
- No nested migration grandchildren

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| `role:` parser support | `8qr.t.zoz.0` | -- | KEPT |
| system migration to role refs | `8qr.t.zoz.1` | -- | KEPT |
| nested migration subtasks | prior mistaken decomposition | parent repair | REMOVED |

## References

- Child feature spec: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/0-implement-role-resolution-in-ace/8qr.t.zoz.0-implement-role-resolution-in-ace-llm.s.md`
- Child migration spec: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/1-migrate-ace-configs-to-roles/8qr.t.zoz.1-migrate-ace-configs-to-roles-first-model.s.md`
- Usage doc for child feature: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/0-implement-role-resolution-in-ace/ux-usage.md`
- Usage doc for child migration: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/1-migrate-ace-configs-to-roles/ux-usage.md`
