---
id: 8qr.t.zoz.1
status: pending
priority: medium
created_at: "2026-03-29 00:19:51"
estimate: TBD
dependencies: [8qr.t.zoz.0]
tags: [config, migration, roles]
parent: 8qr.t.zoz
bundle:
  presets: [project]
  files: [.ace/llm/config.yml, .ace/task/config.yml, .ace/review/config.yml, .ace/review/presets/code-valid.yml, .ace/review/presets/code-fit.yml, .ace/review/presets/code-shine.yml, .ace/review/presets/spec.yml, .ace/review/presets/docs.yml, .ace/assign/config.yml, .ace/e2e-runner/config.yml, .ace/git/commit.yml, .ace/docs/config.yml, .ace/prompt-prep/config.yml, ace-task/.ace-defaults/task/config.yml, ace-review/.ace-defaults/review/config.yml, ace-review/.ace-defaults/review/presets/code-valid.yml, ace-review/.ace-defaults/review/presets/code-fit.yml, ace-review/.ace-defaults/review/presets/code-shine.yml, ace-review/.ace-defaults/review/presets/spec.yml, ace-review/.ace-defaults/review/presets/docs.yml, ace-assign/.ace-defaults/assign/config.yml, ace-test-runner-e2e/.ace-defaults/e2e-runner/config.yml, ace-sim/.ace-defaults/sim/presets/validate-task.yml, ace-sim/.ace-defaults/sim/presets/validate-idea.yml, ace-compressor/.ace-defaults/compressor/config.yml, ace-prompt-prep/.ace-defaults/prompt-prep/config.yml, ace-idea/.ace-defaults/idea/config.yml, ace-retro/.ace-defaults/retro/config.yml, ace-lint/.ace-defaults/lint/config.yml, ace-git-commit/.ace-defaults/git/commit.yml, ace-docs/.ace-defaults/docs/config.yml, docs/architecture.md, docs/vision.md, ace-compressor/docs/usage.md, ace-compressor/docs/demo/fixtures/architecture.md, ace-git-commit/docs/usage.md, ace-git-commit/docs/getting-started.md, ace-review/docs/feedback-workflow.md, ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/fixtures/pkg-a/.ace/git/commit.yml, ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/fixtures/pkg-b/.ace/git/commit.yml, ace-review/test/e2e/TS-REVIEW-001-review-workflow/fixtures/.ace/review/config.yml, ace-review/test/e2e/TS-REVIEW-001-review-workflow/fixtures/.ace/review/presets/single.yml, ace-review/test/e2e/TS-REVIEW-001-review-workflow/fixtures/.ace/review/presets/multi.yml, ace-review/test/e2e/TS-REVIEW-001-review-workflow/fixtures/.ace/review/presets/reviewers-test.yml, ace-review/test/e2e/TS-REVIEW-001-review-workflow/fixtures/.ace/review/presets/level_1.yml, ace-sim/test/e2e/TS-SIM-001-next-phase-smoke/fixtures/.ace/sim/presets/validate-task.yml, ace-sim/test/e2e/TS-SIM-001-next-phase-smoke/fixtures/.ace/sim/presets/validate-idea.yml, .ace-tasks/8qr.t.zoz-named-model-pools-roles-for/1-migrate-ace-configs-to-roles/ux-usage.md]
  commands: []
needs_review: false
---

# Migrate ACE configs to roles-first model selection

## Objective

Migrate ACE consumer configs, presets, docs, examples, and fixtures to use stable `role:` references first wherever they currently hardcode model/provider selections. This task is the system rollout half of the parent orchestrator and intentionally standardizes ACE on one canonical role catalog across project configs and package defaults, even where current per-layer values differ today.

## Behavioral Specification

### User Experience

- **Input:** Operators keep model/provider choices in `llm.roles`; ACE consumer configs reference roles instead of provider/model literals wherever possible
- **Process:** The task inventories all current model-selection surfaces, maps them to a canonical role catalog, then updates project configs, package defaults, review presets, execution-provider fields, docs, examples, and fixtures to the role-based form. Where current project overrides and package defaults differ, the migration normalizes them to the canonical role catalog rather than preserving the old per-layer split
- **Output:** A roles-first repo where most consumer-facing config surfaces read as intent (`role:doctor`, `role:planner`, `role:review-synthesizer`) rather than concrete provider/model strings

### Expected Behavior

1. All consumer config surfaces currently using direct model/provider values are explicitly inventoried
2. A canonical role catalog is established and used consistently across the migration
3. The migration intentionally standardizes differing project/default model choices onto that canonical role catalog
4. Project override configs under `.ace/` are migrated to role references
5. Package default configs under `ace-*/.ace-defaults` are migrated to role references
6. Review preset arrays keep their multi-model shape but use role references per reviewer slot
7. Execution/simulation fields named `provider` are migrated when they semantically represent LLM selection
8. Docs, examples, and fixtures touched by the migration are updated in the same task

### Inventory Contract

The migration inventory is fixed by this spec and must not rely on implementation-time discovery for scope:

| Surface | Current field(s) | Target role(s) |
| --- | --- | --- |
| Project task config | `task.doctor_agent_model`, `task.plan.model` | `doctor`, `planner` |
| Project review config | `defaults.model`, `feedback.synthesis_model` | `review-default`, `review-synthesizer` |
| Project review presets | `.ace/review/presets/*: models[]` | `review-claude`, `review-codex`, `review-gemini` |
| Project assign config | `execution.provider` | `assign-executor` |
| Project e2e config | `reporting.model`, `execution.provider` | `e2e-reporter`, `e2e-executor` |
| Project git config | `git.model` | `commit` |
| Project docs config | `llm.model` only; preserve `llm.provider: ace-llm-query` | `docs-analysis` |
| Project prompt-prep config | `model` | `prompt-enhance` |
| Package task defaults | `task.doctor_agent_model`, `task.plan.model` | `doctor`, `planner` |
| Package review defaults | `defaults.model`, `feedback.synthesis_model`, `feedback.fallback_models[]` | `review-default`, `review-synthesizer`, `review-fallback` |
| Package review presets | `ace-review/.ace-defaults/review/presets/*: models[]` | `review-claude`, `review-codex`, `review-gemini` |
| Package assign defaults | `execution.provider` | `assign-executor` |
| Package e2e defaults | `reporting.model`, `execution.provider` | `e2e-reporter`, `e2e-executor` |
| Package sim presets | `provider[]`, `synthesis_provider` | `sim-primary`, `sim-synthesis` |
| Package compressor defaults | `agent_model` | `compressor` |
| Package prompt-prep defaults | `model` | `prompt-enhance` |
| Package idea defaults | `idea.llm_model`, `idea.doctor_agent_model` | `idea-enhance`, `doctor` |
| Package retro defaults | `retro.doctor_agent_model` | `doctor` |
| Package lint defaults | `lint.doctor_agent_model` | `doctor` |
| Package git defaults | `git.model` | `commit` |
| Package docs defaults | `llm.model` with existing provider semantics preserved | `docs-analysis` |
| Teaching docs/examples | config-teaching examples in `docs/architecture.md`, `docs/vision.md`, `ace-compressor/docs/usage.md`, `ace-git-commit/docs/usage.md`, `ace-git-commit/docs/getting-started.md`, `ace-review/docs/feedback-workflow.md`, and this task's usage doc | roles-first examples only |
| Shipped fixtures | review, sim, and git-commit fixture configs under the listed `test/e2e/**/fixtures` paths | same roles used by shipped config surfaces |

### Interface Contract

```yaml
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
# Single-model migration examples
task:
  doctor_agent_model: role:doctor
  plan:
    model: role:planner

git:
  model: role:commit

llm:
  provider: ace-llm-query
  model: role:docs-analysis

idea:
  llm_model: role:idea-enhance
  doctor_agent_model: role:doctor

compressor:
  agent_model: role:compressor
```

```yaml
# Multi-model review preset migration example
models:
  - role:review-claude
  - role:review-codex
  - role:review-gemini

feedback:
  synthesis_model: role:review-synthesizer
  fallback_models:
    - role:review-fallback
```

```yaml
# Execution-provider migration example
execution:
  provider: role:e2e-executor
reporting:
  model: role:e2e-reporter
```

### Error Handling

- If a consumer field cannot yet accept `role:<name>`, the migration must either add the necessary loader/parser support in the touched package or record the field as an explicit blocker
- If a role name would hide an important difference in intent, the task must use distinct role names rather than forcing unrelated consumers onto one role
- If current project and default configs disagree, the migration follows the canonical role catalog and updates both sides to the standardized target instead of preserving the old divergence

### Edge Cases

- Review presets with `models:` arrays remain arrays
- `feedback.fallback_models` migrate to role references as arrays
- `provider:` fields are migrated only when they encode LLM selection, not when they encode provider registry metadata
- `.ace/docs/config.yml` migrates `llm.model` to `role:docs-analysis`, but keeps `llm.provider: ace-llm-query` unchanged
- Commented examples and shipped documentation are in scope when they teach hardcoded model usage
- CLI override examples showing intentional one-off `--model` or `--provider` flags remain valid and do not need conversion to roles

## Success Criteria

1. Every current consumer-facing model/provider config surface is accounted for in the task spec, including all current review preset files in project config and package defaults
2. The canonical role catalog is explicit enough for implementation without more naming decisions
3. Project configs and package defaults have a clear migration path to role references
4. The migration explicitly standardizes currently divergent project/default model choices onto the canonical role catalog
5. Review presets, synthesis models, fallback models, execution-provider fields, docs, examples, and fixtures are all explicitly in scope
6. The migration remains a single task under the parent, with no nested migration subtasks

## Validation Questions

- No blocking questions remain
- This task intentionally includes docs, default config, examples, and fixtures in the same migration scope
- Current project/default model differences are intentionally normalized rather than preserved

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone migration task**

- **Slice:** inventory, role catalog, config migration, preset migration, docs/examples/fixtures follow-through
- **Advisory size:** Large
- **Context dependencies:** `8qr.t.zoz.0`, consumer config files, shipped defaults, docs and fixture surfaces

## Verification Plan

### Unit/Component Validation

- config loaders continue to accept migrated values in touched packages
- review preset loaders accept role-based `models:` arrays
- review feedback config continues to accept role-based `fallback_models`
- execution/sim loaders accept role-based `provider:` fields where applicable
- docs config continues to use `llm.provider: ace-llm-query` while resolving `llm.model` through roles

### Integration/E2E Validation

- project `.ace` configs resolve through roles after child `8qr.t.zoz.0` lands
- package defaults ship role-based selectors instead of hardcoded provider/model literals
- review and simulation workflows still compose valid provider/model requests through role resolution
- repo-level teaching docs no longer show stale hardcoded model examples for migrated consumer surfaces
- shipped E2E/demo fixtures that mirror migrated config surfaces are updated to the same roles-first selectors

### Failure/Invalid Path Validation

- no consumer surface that should migrate is silently left hardcoded
- no review preset loses multi-model behavior during migration
- `.ace/docs/config.yml` does not rewrite `llm.provider` to a `role:` value
- docs/examples do not keep teaching stale hardcoded config values after migration
- `idea.llm_model` and `feedback.fallback_models` are not missed by inventory or validation scans

### Verification Commands

- `ace-search "role:" --content --hidden --include ".ace/**/*.yml,ace-*/.ace-defaults/**/*.yml" --max-results 200`
- `ace-search "doctor_agent_model|llm_model|synthesis_model|fallback_models|agent_model|^\s*model:|^\s*provider:|^\s*models:|synthesis_provider:" --content --hidden --include ".ace/**/*.yml,ace-*/.ace-defaults/**/*.yml" --max-results 200`
- `ace-search "codex:|claude:|gemini:|google:|glite|openai:|zai:" --content --hidden --include "docs/**/*.md,ace-*/docs/**/*.md,ace-*/test/e2e/**/fixtures/**/*.yml,.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/1-migrate-ace-configs-to-roles/*.md" --max-results 200`
- package-specific `ace-test` commands for each touched package during implementation

## Scope of Work

### Included

- inventory of current consumer surfaces
- canonical role catalog
- explicit global standardization of current project/default differences
- project override migration
- package default migration
- review preset and synthesis/fallback migration
- execution/simulation provider-field migration
- docs/examples/fixtures follow-through

### Out of Scope

- implementing the `ace-llm` role engine itself
- redesigning provider catalogs under `.ace/llm/providers/**`
- inventing a second migration task tree beneath this task

## Deliverables

### Behavioral Specifications

- one migration spec covering all ACE consumer surfaces
- explicit role catalog and mapping examples
- roles-first examples for single-model, multi-model, and execution-provider surfaces

### Validation Artifacts

- inventory-backed migration scope
- updated docs/examples/fixtures included in the task contract
- companion usage examples for roles-first migration surfaces

## References

- Parent rollout task: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/8qr.t.zoz-named-model-pools-roles-for-ace-llm.s.md`
- `ace-llm` feature child: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/0-implement-role-resolution-in-ace/8qr.t.zoz.0-implement-role-resolution-in-ace-llm.s.md`
- Usage doc for this migration: `.ace-tasks/8qr.t.zoz-named-model-pools-roles-for/1-migrate-ace-configs-to-roles/ux-usage.md`
- Repo teaching docs in scope: `docs/architecture.md`, `docs/vision.md`
- Package docs/examples in scope: `ace-compressor/docs/usage.md`, `ace-git-commit/docs/usage.md`, `ace-git-commit/docs/getting-started.md`, `ace-review/docs/feedback-workflow.md`
- Fixture configs in scope: `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/fixtures/pkg-a/.ace/git/commit.yml`, `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/fixtures/pkg-b/.ace/git/commit.yml`, `ace-review/test/e2e/TS-REVIEW-001-review-workflow/fixtures/.ace/review/config.yml`, `ace-review/test/e2e/TS-REVIEW-001-review-workflow/fixtures/.ace/review/presets/{single,multi,reviewers-test,level_1}.yml`, `ace-sim/test/e2e/TS-SIM-001-next-phase-smoke/fixtures/.ace/sim/presets/{validate-task,validate-idea}.yml`
