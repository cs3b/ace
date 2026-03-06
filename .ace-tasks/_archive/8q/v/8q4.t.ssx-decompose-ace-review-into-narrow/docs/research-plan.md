# Research plan: narrow reviewers for ace-review

## Objective

Turn the proven value of broad mixed ace-review output into a reusable architecture built from narrow reviewers, provider definitions, and orchestration pipelines. Preserve the ability to recreate broad mixed presets later, but do not use broad presets as the source of truth.

## Research conclusions

### 1. Narrow reviewers should be the canonical unit

The current system gets value from multiple perspectives, but the perspective boundaries are trapped inside large presets. The redesign should move those boundaries into explicit reviewer definitions so the system can compose them flexibly and run them independently.

### 2. Sparse orchestration beats full reviewer cross-talk

The best default architecture is not a fully connected debate mesh. Initial reviewers should work independently. Challenge and referee stages should run only for disputed, low-confidence, or high-severity findings.

Sources:
- https://aclanthology.org/2024.findings-emnlp.427/
- https://arxiv.org/abs/2406.04692
- https://github.com/deeplearning-wisc/debate-or-vote

### 3. Judges need constrained evidence

Judge-style steps are useful, but only when they receive normalized, blinded evidence rather than raw cross-agent prompt transcripts. This reduces evaluator bias and prompt-infection risk.

Sources:
- https://arxiv.org/abs/2305.17926
- https://arxiv.org/abs/2405.01724
- https://arxiv.org/abs/2410.07283

### 4. ace-assign should choose lanes by risk

The first real consumer of the new reviewer library should be `ace-assign`. Its review stages should stop assuming the same wide review cycle for every task. Instead, it should always run a safe minimal lane set and then add optional lanes from changed-surface and task-risk signals.

## Recommended architecture

```text
.ace/review/
  reviewers/
  providers/
  pipelines/
  presets/
  config.yml
```

### Reviewer responsibilities

- define one narrow review perspective
- own focus prompts and reviewer policy
- define default providers
- define lane type: blocking, advisory, or evidence

### Provider responsibilities

- define how a reviewer is executed
- own model or tool invocation params
- remain reusable across many reviewers

### Pipeline responsibilities

- define execution topology
- define challenge/adjudication rules
- define merge strategy

### Preset responsibilities

- remain thin and user-facing
- bind subject/context to a pipeline
- optionally override reviewer selection

## Recommended v1 reviewer catalog

### Blocking

- `correctness`
- `contracts`
- `tests`
- `security`

### Advisory

- `simplicity`
- `architecture-fit`
- `performance`
- `docs-dx`

### Evidence

- `lint`
- `pr-comments`
- `task-spec`

### Meta-review

- `skeptic`
- `referee`

## Recommended default lane behavior

### Always-on minimal set

- `correctness`
- `contracts`

### Add `tests` when

- behavior changed
- bug fix task
- CLI/workflow/config behavior changed
- new branching or business logic added

### Add `security` when

- auth, secrets, shell execution, file writes, API/LLM/provider boundaries, GitHub integrations, or prompt ingestion changed

### Add `simplicity` when

- abstractions, config layers, or orchestration concepts grew

### Add `architecture-fit` when

- new modules, gems, orchestration paths, or major refactors appear

### Add `performance` when

- iteration, batching, parsing, filesystem walking, or concurrency paths change

### Add `docs-dx` when

- user-facing CLI/help/workflow/docs behavior changes

## Broad preset position

- `code-deep` is evidence that mixed-perspective review is useful.
- `code-deep` is not an architectural requirement.
- If needed later, recreate `code-deep` by composing narrow reviewers after the narrow system is validated.

## Recommended spike scenario

Use one PR-oriented scenario where:

- a preset resolves to a risk-based pipeline
- the pipeline always runs `correctness` and `contracts`
- the pipeline conditionally adds `tests`, `simplicity`, and `security`
- one evidence lane is included
- findings normalize into one merge format
- skeptic/referee are triggered only for disputed or risky findings

## Expected output contract

All review lanes should normalize to one finding envelope:

```json
{
  "title": "string",
  "finding": "string",
  "context": "string",
  "files": ["path/file.rb:42"],
  "priority": "critical|high|medium|low",
  "confidence": 0.0,
  "blocking_hint": true,
  "reviewer": "correctness",
  "reviewer_type": "llm|tool|human",
  "provider": "cc-opus",
  "stage": "collect",
  "evidence": ["structured summary"]
}
```

## Concepts to keep, remove, and defer

| Concept | Decision | Why |
|--------|----------|-----|
| Weighted consensus synthesis | KEEP | Already valuable and close to the needed merge model |
| Reviewer metadata (`weight`, `critical`, file filters) | KEEP | Good base for narrow-reviewer behavior |
| Preset-heavy mixed review definitions | REMOVE | Too much perspective logic trapped in large configs |
| Provider/model coupling inside reviewer definitions | REMOVE | Prevents reuse and clean composition |
| Risk-based lane selection for ace-assign | KEEP | Best first consumer and best leverage point |
| Recreated broad presets | DEFER | Useful later, not the first delivery |
| Always-on tribunal/debate flow | DEFER | Too expensive and too noisy as a default |

## Implementation guidance for later planning

- build reviewer definitions before recreating wide presets
- validate concept boundaries with one spike before drafting more subtasks
- keep feedback items as the primary output artifact
- never pass raw reviewer markdown directly into another reviewer prompt
