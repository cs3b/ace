# Roles-First Config Migration - Draft Usage

## API Surface

- [x] Configuration (`role:<name>` replaces direct model/provider selectors in consumer configs)
- [x] Presets (review `models[]`, simulation `provider[]`, review `fallback_models[]`)
- [x] Documentation/examples (teaching docs switch from concrete model strings to roles-first examples)
- [ ] CLI (no new CLI commands)
- [ ] Agent API (no new workflows or protocols)

## Usage Scenarios

### Scenario 1: Migrate a single-model consumer config

**Goal**: Replace hardcoded selectors in project and package configs with intent-based roles

```yaml
# Before
task:
  doctor_agent_model: gemini:flash-latest@yolo
  plan:
    model: codex:gpt@ro

# After
task:
  doctor_agent_model: role:doctor
  plan:
    model: role:planner
```

### Expected Output

Task tooling keeps the same behavior, but future provider/model swaps happen centrally in `llm.roles`.

### Scenario 2: Migrate review defaults and fallback arrays

**Goal**: Preserve review behavior while removing concrete model strings from review config

```yaml
# Before
defaults:
  model: codex:codex@ro
feedback:
  synthesis_model: gemini:flash-latest@ro
  fallback_models:
    - claude:sonnet

# After
defaults:
  model: role:review-default
feedback:
  synthesis_model: role:review-synthesizer
  fallback_models:
    - role:review-fallback
```

### Expected Output

Primary review and fallback routing still work, and the array shape remains unchanged.

### Scenario 3: Migrate multi-model presets without collapsing them

**Goal**: Keep reviewer diversity in preset arrays

```yaml
# Before
models:
  - claude:opus@ro
  - codex:gpt@ro
  - gemini:pro-latest@ro

# After
models:
  - role:review-claude
  - role:review-codex
  - role:review-gemini
```

### Expected Output

Review presets still run multiple reviewer slots; only the selectors change.

### Scenario 4: Migrate execution-provider and reporting fields

**Goal**: Update execution-like fields that currently encode LLM choice

```yaml
# Before
execution:
  provider: claude:haiku@yolo
reporting:
  model: claude:haiku

# After
execution:
  provider: role:e2e-executor
reporting:
  model: role:e2e-reporter
```

### Expected Output

Execution/reporting flows keep their semantics, but model selection becomes centralized.

### Scenario 5: Preserve non-model provider metadata

**Goal**: Avoid converting provider registry fields that are not model selectors

```yaml
# Before
llm:
  provider: ace-llm-query
  model: glite

# After
llm:
  provider: ace-llm-query
  model: role:docs-analysis
```

### Expected Output

`.ace/docs/config.yml` keeps its provider integration contract while its model choice becomes role-based.

### Scenario 6: Update teaching docs to the new style

**Goal**: Ensure docs stop teaching stale hardcoded model strings once the migration lands

```markdown
Before: model: codex:mini
After:  model: role:commit
```

### Expected Output

Repo docs and examples describe roles-first configuration, matching shipped config defaults.

## Notes for Implementer

- This migration standardizes currently divergent project/default values onto the canonical role catalog in the task spec; preserving old divergence is out of scope.
- `docs/architecture.md` and `docs/vision.md` are explicitly in scope because they teach concrete model examples today.
- Inventory completeness must include `idea.llm_model` and review `fallback_models`, not just generic `model` or `provider` keys.
