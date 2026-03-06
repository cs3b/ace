# ace-review narrow reviewer architecture - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (review config models and resolvers)
- [x] Agent API (assignment-driven review policy)
- [x] Configuration (reviewer, provider, pipeline, preset files)

## Usage Scenarios

### Scenario 1: Run a PR review with risk-based narrow reviewers

**Goal**: Review only the perspectives that match the changed surface while preserving a safe baseline.

```bash
ace-review --preset pr-risk-based --auto-execute

# Expected behavior:
# - always runs correctness and contracts
# - conditionally adds tests, simplicity, security, performance, docs-dx
# - outputs feedback items with reviewer and provider provenance
```

### Scenario 2: Assignment workflow selects review lanes automatically

**Goal**: `ace-assign` chooses narrower review lanes from task risk instead of always running one wide mixed review cycle.

```bash
ace-assign ...  # assignment preset includes review_policy.mode: risk-based

# Expected behavior:
# - derives a reviewer lane set from changed files and task surface
# - runs the minimal safe set plus optional risk-triggered lanes
# - records which lanes were chosen and why
```

### Scenario 3: Recreate a wide mixed review later

**Goal**: Preserve the ability to assemble a broader review mode after narrow reviewers exist.

```bash
ace-review --preset code-deep --auto-execute

# Expected behavior:
# - code-deep is a composition over narrow reviewers
# - no reviewer logic is duplicated inside the code-deep preset
# - broad review remains possible without being the source of truth
```

## Notes for Implementer
- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
- The first implementation should prioritize reviewer decomposition and risk-based selection over broad-preset reconstruction.
