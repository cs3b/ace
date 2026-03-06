# Spike Concept Inventory: KEPT / REMOVE / DEFER

## Decision Rule
This spike is valid only if one coherent end-state can be explained with fewer concepts than the preset-heavy model and with clear ownership boundaries between reviewer, provider, and pipeline.

## Concept Decisions

| Concept | Decision | Why |
|---|---|---|
| Narrow reviewer definitions | KEPT | Canonical unit for review intent and scope |
| Provider definitions | KEPT | Separates execution runtime from review perspective |
| Pipeline orchestration | KEPT | Controls lane topology and merge behavior |
| Normalized finding envelope with provenance | KEPT | Enables shared merge path for LLM/tool/human evidence |
| Always-on baseline (`correctness + contracts`) | KEPT | Safe minimum coverage when risk signals are sparse |
| Risk-based optional lane selection in `ace-assign` | KEPT | First practical consumer with highest leverage |
| Preset-heavy mixed review definitions as source-of-truth | REMOVE | Traps review intent in large opaque configs |
| Provider/model coupling inside reviewer definitions | REMOVE | Prevents provider reuse and clean composition |
| Wide-preset reconstruction (`code-deep`) in first milestone | DEFER | Useful later, not required for initial architecture validation |
| Always-on skeptic/referee tribunal flow | DEFER | Expensive/noisy as default; trigger only when disputed/high-risk |

## Boundary Validation

### Reviewer boundary
- Owns perspective, focus, criticality, and file/subject scope.
- Does not own provider runtime details.

### Provider boundary
- Owns model/tool runtime behavior.
- Reusable across multiple reviewers.

### Pipeline boundary
- Owns lane selection and orchestration order.
- Owns challenge/adjudication trigger policy.
- Does not redefine reviewer semantics.

## Minimal Coherent End-State
1. Thin preset selects a pipeline.
2. Pipeline starts with `correctness + contracts`.
3. Pipeline adds optional lanes by deterministic risk rules.
4. Pipeline includes at least one evidence lane (`pr-comments`).
5. Outputs converge into one finding contract with provenance.

## Optional Lane Triggers for `ace-assign`
- Add `tests` for behavior/logic/CLI/workflow/config branching changes.
- Add `security` for auth/secrets/shell/fs/network/provider-boundary changes.
- Add `simplicity` for abstraction/indirection growth.
- Add `architecture-fit` for module/gem/workflow/config-layer additions.
- Add `performance` for loops/batching/parsing/hot-path changes.
- Add `docs-dx` for user-visible CLI/docs/workflow changes.

## Failure Boundary (Stop Condition)
If future implementation cannot preserve reviewer/provider/pipeline separation or cannot emit one normalized finding contract across evidence types, downstream decomposition should pause and the orchestrator spec must be revised before continuing.

## Spike Verdict
- Coherent minimal architecture: validated.
- Additional subtasks can proceed under this concept set.
