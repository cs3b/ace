# Spike Scenario Validation: Narrow Reviewer Architecture

## Scenario Goal
Validate one coherent end-to-end review path where a thin preset resolves to a pipeline, the pipeline selects narrow reviewers by risk, includes one evidence lane, and emits normalized findings with provenance.

## Selected Flow
- Entry command: `ace-review --preset pr-risk-based --auto-execute`
- Assignment context: `ace-assign` review policy chooses optional lanes from changed-surface/risk signals
- Guaranteed baseline: `correctness + contracts`

## End-to-End Narrative

### 1. Preset -> Pipeline Resolution
1. User runs `ace-review --preset pr-risk-based --auto-execute`.
2. Preset resolves to:
   - pipeline: `narrow-risk-based`
   - default lane policy: always-on `correctness + contracts`
   - optional lanes by rule matrix
3. The preset remains user-facing only; reviewer logic lives in reviewer/provider/pipeline surfaces.

### 2. Pipeline -> Reviewer Selection
Pipeline selection phase computes lane set in this order:
1. Start with always-on reviewers:
   - `correctness`
   - `contracts`
2. Add optional lanes from risk rules:
   - `tests` when behavior/logic/CLI/workflow/config branching changes
   - `security` when auth/secrets/shell/fs/network/provider boundaries change
   - `simplicity` when abstraction/indirection grows
   - `architecture-fit` when modules/gems/workflows/config layers change
   - `performance` when loops/batch/parsing/hot paths change
   - `docs-dx` when user-facing CLI/docs/workflow output changes
3. Add at least one evidence lane (`pr-comments`) so non-LLM evidence participates in the same merge path.

### 3. Reviewer + Evidence Execution
- Reviewer lanes run independently in collect stage.
- Evidence lane (`pr-comments`) contributes normalized observations using the same output contract as LLM/tool lanes.
- Skeptic/referee remain deferred by default and are not required for this spike path.

### 4. Findings Convergence
All lanes converge into one normalized finding envelope with provenance:

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
  "provider": "provider-or-tool-id",
  "stage": "collect",
  "evidence": ["structured summary"]
}
```

## Assignment Bridge (Current -> Target)
Current assignment review cycles (`code-valid`, `code-fit`, `code-shine`) are retained as user-facing compatibility layers while internals shift to narrow lanes:
- `code-valid` maps primarily to blocking lanes (`correctness`, `contracts`, plus risk-triggered `tests/security`)
- `code-fit` maps to architecture and quality lanes (`architecture-fit`, `performance`, `tests`)
- `code-shine` maps to advisory polish lanes (`simplicity`, `docs-dx`)

This allows phased cutover without requiring immediate CLI preset surface changes.

## Error Handling Outcomes
- **Missing reviewer reference**: fail setup with explicit missing reviewer name.
- **Missing provider reference**: fail setup with explicit missing provider name.
- **Under-specified risk rules**: output lists missing signals and affected lanes; no silent defaulting beyond always-on baseline.

## Edge Case Outcomes
- **No optional lanes selected**: run only `correctness + contracts` and still produce valid findings.
- **Mixed evidence types**: LLM/tool/human evidence share one normalized finding contract.
- **Broad preset reconstruction deferred**: `code-deep` reconstruction remains possible later as composition over narrow lanes.

## Acceptance Mapping
- End-to-end scenario described: yes
- Pipeline selects narrow reviewers: yes
- Includes at least one evidence lane: yes (`pr-comments`)
- Findings converge with provenance: yes
- Risk-based lane rules for `ace-assign`: yes
