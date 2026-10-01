# Approved review and pilot program -- source evidence

This is the factual handoff for R1-R3 and L1-L5, approved by the user on 2026-10-01. It preserves the evidence needed to understand the specifications without the source conversation. It is not a new implementation or an independent review of the future ACE changes.

## Approved task map

| Plan | ACE task | Owner |
|---|---|---|
| R1: durable campaign, separate receipt validity | 8x0.t.ig2 | ace-review |
| R2: one review-loop owner and visible policy | 8x0.t.ig3 | ace-review with ace-assign consumer |
| R3: bounded convergence and escalation | 8x0.t.ig4 | ace-review |
| Pilot orchestrator | 8x0.t.ig5 | ace-assign |
| L1: isolated discovery | 8x0.t.ig5.0 | ace-assign |
| L2: portable synthesis | 8x0.t.ig5.1 | ace-assign |
| L3: final delivery and authorized escalation | 8x0.t.ig5.2 | ace-assign |
| L4: verified invariant/probe knowledge | 8x0.t.ig5.3 | ace-review export; ace-task consumption |
| L5: three-arm benchmark | 8x0.t.ig5.4 | ace-assign |

R1 -> R2 -> R3; R3 -> L1 and L4; L1 + L4 -> L2 -> L3 -> L5. Existing qjl supplies attempt evidence; qkb supplies provider-neutral delivery. The parent contains no hidden implementation goal.

## Original experiment and its limits

The task was to remove physical PostgreSQL Client query overlap, including silent two-query overlap, while preserving safe Pool scheduling, transaction ownership, lazy acquisition, ordered errors/results, independent concurrency and cleanup after owned work. Its permanent test gate had to cover both Vitest projects and child/skip/error paths. It also required measured route budgets without demonstrated regression; it did not authorize a production-wide queue or driver upgrade.

| Artifact | Reviewed identity | Recorded conclusion |
|---|---|---|
| [A, PR175](https://github.com/cs3b/st-nervus-chat/pull/175) | d04064f60ed4aab4a4181f205fb742614c34d036 | Additional fixes required |
| [B, PR176](https://github.com/cs3b/st-nervus-chat/pull/176) | 5eca96ec334c67274176bbfc993070f1e0c34193 | Additional fixes required |
| [C, PR177](https://github.com/cs3b/st-nervus-chat/pull/177) | 4fc734c4340d24ecddd685d12cb328f02c9329a3 | Acceptance demonstrated with documented residual risk |

Common baseline: a1aee0cfb37ccaa5a8f30151a969667fb10734dd. Seven of eight changed C production files match A; project-memory adds stop-on-failure worker scheduling. C is therefore informed synthesis/reuse, not a fresh independent trial proving any model's superiority. Do not infer A/B authorship from results.

The catalog contains 120 historical reports (A 11, B 109). These are reports, not verified campaign-round counts. C had two newly commissioned formal reviews: the first identified one valid Medium exit-behavior defect; the second found no remaining issues after repair. The parent independently verified C across repairs. One implementation subagent was used. Session logs recorded three parent and two child compactions. External reviewers' internal context management is outside this count.

Three full C release attempts were recorded: one failed and two passed on different heads. The final head passed 221 Vitest files / 2,108 tests, 55 app Node tests, and 138 browser tests with one intentional remote-AI skip and no retries. Seven named files separately executed 69 tests without skips; those overlap the broad suite. Thirty independent adversarial controls passed expected outcomes, including deliberate nonzero gate-positive failures. A broad passing suite was not treated as proof that every custom guard path was correct.

User observation: this conversation consumed an estimated 8-10% of weekly allowance versus about 2% for A. This is an unverified subscription-usage estimate, not measured API spend or a model-price ratio. No 4-6x cost claim is accepted as fact.

## Confirmed C defects and general lessons

All four issues below were classified Medium and fixed before final acceptance. They establish why a no-High streak alone cannot imply acceptance.

| Finding | Minimal failing scenario | Required invariant / repaired outcome |
|---|---|---|
| C-1: late runner error registration | A collection-time or ignored-child violation is registered only after the runner computed its exit; all tests may be skipped | The consumer accepts failure evidence before acknowledging producer progress; the actual runner exits nonzero |
| C-2: stale active marker after local pg validation | An invalid-values query invokes a callback/error listener, which safely submits recovery; guard mistakes stale driver state for physical work | Preserve native safe local-error recovery while retaining ownership for real in-flight work |
| C-3: Vite-transformed preload URL | Client/happy-dom setup transforms a static URL to a non-file scheme; 126 suites fail collection | Resolve the preload in the Node owner and verify an actual clean and violating client-environment execution |
| C-4: deferred process.exit | process.exit(0) followed by an unreachable throw executes the throw under the pre-fix guard | Leave native synchronous exit semantics intact while retaining targeted warning evidence before exit |

A/B also exposed early ownership release on timeout/serialization notification, dispatch of later provider batches after failure, cleanup before siblings drained, ignored child instrumentation gaps, imprecise warning matching and subsequent source errors hidden by an early return. L4 must distinguish confirmed final-head defects from earlier historical findings when exporting entries.

Useful portable-probe recipes for L4 implementation:

- Hold real backend work beyond caller timeout; attempt the second query; require detection until physical completion. Include a safe max-one Pool control.
- Hold sibling provider work, fail the first provider, and observe that the owning operation remains unsettled; release the sibling, prove no third batch was claimed and cleanup occurs last.
- Producer A emits evidence, producer B resets its state; the consumer must retain A's unacknowledged evidence.
- Spawn a violating connected child whose exit is ignored, including a skipped test file; the parent test runner must still fail.
- Emit the exact targeted warning and exit immediately; it must fail. Unrelated warning and native clean/immediate exit controls must remain unchanged.
- Trigger local query validation failure, recover inside native callback/event handling and compare guarded versus unguarded outcomes; include reused Query controls.

These are behavioral recipes, not already delivered portable probes. The historical scripts contain local assumptions; L4 owns packaging, version applicability and positive/negative execution proof.

## Residual risks, not erased by green final results

An earlier C release run retried a cross-Space transfer after PostgreSQL reported a serialization conflict on an unchanged search_index UPDATE under unchanged SERIALIZABLE policy. Earlier read sequencing changed, so timing impact cannot be excluded. The final run passed first attempt; no controlled baseline/C failure-rate comparison was established.

An existing gallery fixture inserts an empty preview manifest; an unchanged launch handler accesses missing routes and emits an iframe HTTP500 while panel-structure assertions pass. This is a concrete coverage limit, not an intentional asserted negative-response test or a proven new PostgreSQL regression.

The test guard deliberately couples to pg8.22.0 fields and Vitest error-state behavior. Child guarantees assume inherited preload/collector configuration. These are documented boundaries, not arbitrary hostile-child fault tolerance.

## Process observations that motivate the ACE tasks

- Canonical ace-review workflow already says commits/squash/rebase do not reset rounds; its rounds.md bookkeeping is agent-owned. R1 makes this mechanically persistent rather than merely repeating the instruction.
- Nervus has a project-specific review workflow requiring batched verified Medium-or-higher repairs and exact-head receipts. Its delivery preset also schedules verify/apply stages separately. This is an observed responsibility overlap, not proof that every invocation actually duplicated work.
- Shared-root session creation and worktree-bound context loading required an explicit existing-API storage-root override; feedback operations needed explicit session identity. R2 makes this supported behavior, not an ad-hoc workaround.
- The final release gate exposed a client-environment failure that focused Node checks had missed. Verification must exercise actual production/test harness boundaries, not only convenient helper tests.
- External review initially required user authorization; the user authorized it. Task completion/archive was separately rejected and left pending. Authorization scope should be known early, persisted and reused correctly; it must never be bypassed to save a round.

ACE source inspected at 55df2b0b7 on main; Nervus consumed pinned ace-review0.56.0 and ace-assign0.57.1 during this work. Source and installed consumer policy are not assumed identical. The ACE target task qjl is recorded done; qkb is pending. Verify their live disposition again at implementation time.

## Pilot decisions

The user selected a pilot plus measurement, not a full autonomous factory, and three experimental arms rather than two. The single-Flash control helps distinguish the benefit of candidate diversity from the benefit of Sol synthesis itself. Pre-register three fresh task categories and common acceptance. Keep anonymous quality judgment separate from cost analysis. One run per task/arm is descriptive pilot evidence, not statistical dominance. No automatic routing change, benchmark execution or provider transmission is authorized merely by creating these drafts.

## Evidence provenance

`source-manifest.json` records source-repository-relative artifact locations, inspected-byte SHA256 digests and purposes. Originals live in the Nervus checkout's ignored review store and are not claimed to be published. This digest provides portable context; original machine artifacts remain the authority for detailed historical claims. Future implementation must preserve required reproductions as L4 acceptance artifacts rather than depending on this author's local checkout.
