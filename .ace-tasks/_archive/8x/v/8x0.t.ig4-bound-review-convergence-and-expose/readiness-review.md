# Specification readiness review

Reviewed on 2026-10-01 against ACE main `55df2b0b70780ed40c92657eae3227bb70a0d24b`.

Scope: local author/readiness review using `wfi://task/review`, not an independent implementation review, runtime verification or provider approval. The user narrowed this pass to R1-R3; pilot tasks are not promoted by this review.

## Findings resolved before promotion

| Gap | Resolution |
|---|---|
| SC2 mixed convergence with acceptance | Separate no-High search threshold from open-defect/current-evidence acceptance requirements. |
| Uncounted final review could bypass budget | Every substantive final review counts; a required fix at round five needs escalation. |
| Budget restart loophole | Resume only an explicitly authorized finite phase, retaining campaign lifetime history and findings. |
| Severity corrections and duplicate reports | Recompute audit-backed streak; no model-label/text similarity shortcuts, no extra rounds from duplicate import. |
| Infrastructure retries and empty outputs | Separate attempt budget; a genuine executed empty-finding report differs from a zero-model no-op. |

## Source inspection

- `ace-review/lib/ace/review/cli.rb` and `cli/commands/review.rb`: single-command dispatch and repeatable option handling.
- `ace-review/lib/ace/review/molecules/review_evidence.rb`: prior evidence is context, not current readiness certification.
- `ace-review/lib/ace/review/cli/commands/feedback/session_discovery.rb`: current implicit most-recent-session behavior.
- `ace-review/lib/ace/review/atoms/feedback_state_validator.rb`: terminal done/invalid/skip transitions.
- `ace-assign/lib/ace/assign/molecules/receipt_verifier.rb`: live-head, producer/reviewer and in-repository artifact validation.
- `ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb`: head change invalidates accepted candidate receipts, not all accepted journal history.
- `ace-assign/.ace-defaults/assign/presets/work-on-task.yml` and catalog composition rules: existing unified review stage.
- Task qjl is done; qkb is pending and owns provider-neutral delivery. Do not infer installed provider support from a pending spec.

## Readiness checklist disposition

- Behavior, input/process/output, public contracts, observable acceptance and positive/negative usage: covered.
- Scope, package ownership, consumer inventory, explicit defaults and operating modes: covered.
- Identity/empty/malformed inputs, replay, concurrent execution, restart, and evidence drift: covered by the readiness decisions and mapped verification.
- Dependencies and end-to-end slice: explicit; no cycle. Large scope remains advisory, not a reason to bypass tests.
- Bundle presets/files/commands order and required context files: checked; usage document exists.
- Criterion-to-verification mapping: included in the specification; implementation must supply actual named cases and evidence.
- Contradictory directives and hidden assumptions: corrected as listed above.
- Title/folder/file naming: within task naming limits. Orchestrator/child promotion and subtask naming rules: not applicable to these three standalone tasks.
- Blocking product questions: none. Runtime provider availability is not a blocker to implementing deterministic campaign policy and receipt handling.

## Decision

Specification is ready for `pending` with `needs_review: false`; execution still follows its declared dependencies. This review neither implements the task nor proves future runtime acceptance. No benchmark, external review transmission, merge or deployment was executed.
