# h8x delivery queue — integration decision record (§1b first application)

- Decision actor: overseer-ace (w6:p1), queue owner
- Decision time: 2026-10-12 (records-verification pass)
- Evidence revision: design doc + §1b (commit 16ab615ce→ae73ded33 lineage); PR37 R2 APPROVED; PR38/39 executor reports
- Callback routing correction (host): executor/reviewer callbacks route to the PROJECT OVERSEER (overseer-ace, w6:p1); lab coordinator (overseer w1:pS) = escalation + host-relay lane only. Friction recorded: EXECUTOR-H8X-A/B-DONE callbacks initially addressed to the lab overseer per the earlier template — results valid, adopted here; template corrected for all future h8x dispatches.

## Queue entries (eligible-set evaluation)

| Entry | Head | State | Eligibility inputs |
|---|---|---|---|
| PR37 closure records (8xa.t.ega) | 928a128c | APPROVED (R1→R2), records-only | fresh evidence bound to head ✓; no code deps; ff on 1a8fa820 ✓ |
| PR38 presets/skill (qkb.1 impl) | 969d86af | PR-ready; independent review PENDING (dispatching) | 4 commits on origin/main 1a8fa820 ✓ ff-eligible; worker self-reported review + tests — standing independent review being dispatched |
| PR39 create --in atomic fix (qkd.0/#333) | b5102259 | REBASE REQUIRED then re-verify | branch base rides PR37 commits (7b268023f, a2284f897) + ho4 bookkeeping — must rebase --onto origin/main EXCLUDING PR37-riding commits so the diff = ho4 bookkeeping + atomic fix only; renewed exact-head evidence required after rebase |

## Decision

- ORDERED ELIGIBLE SET (integration order proposed to host): PR37 → PR38 → PR39 (39 rebased first; all three mutually independent after 39's rebase; 37 first because 38/39 were staged against a main lineage that includes 37's content only locally).
- SELECTED now: dispatch independent review PR38; delegate PR39 rebase+re-push to its own worker (h8x-impl-b); dispatch PR39 independent review after its re-verified head lands.
- DEFERRED: none. Reasons: n/a.
- Integration effect: HOST-owned (standalone root integrator) — WAIT(host-integrator, relay reference = coordinator escalation lane; per M2 no durable pollable record exists — recorded, not assumed).

## RE-EVALUATION #1 (2026-10-12, post-review)

Trigger: PR39 evidence superseded — independent review R1 APPROVED at new head c11d6b6df (pr39-review-r1.md; reviewer agy gemini-3.8-flash-medium, distinct from codex executor; own suite execution 515 tests passing; SC1–SC4 atomic contract verified; refs/pull/39/head == c11d6b6df verified). PR38 review still in flight. Order stands: PR37 → PR38 → PR39; PR39 STOP-for-integration relayed to coordinator (final head c11d6b6df).

## RE-EVALUATION #2 (2026-10-12, PR38 review landed)

Trigger: PR38 evidence completed — independent review R1 APPROVED at exact head 969d86af (pr38-review-r1.md; reviewer pi, distinct from executors; ff-eligible confirmed: merge-base == origin/main tip; own suite re-execution: ace-overseer 310 tests/1918 assertions green, ace-assign fast 88 green incl. new tests, feat tier env-blocked with baseline proof — recorded as non-blocking environment observations; worker self-review subordinated to the independent gate). ALL THREE queue entries now APPROVED at verified heads. Order unchanged: PR37 → PR38 → PR39; PR38 STOP-for-integration relayed to coordinator (final head 969d86af). Non-blocking N1–N4 (environment/test-infra observations) recorded in the review file. NOTE: this approval was later SUPERSEDED by re-evaluation #3 (main moved; renewed verdict required) — the R1 report remains valid evidence of the content review at 969d86af.

## RE-EVALUATION #3 (2026-10-12, PR37 INTEGRATED — host result)

PR37 INTEGRATED: fast-forward at exact reviewed head 928a128c4; integrated tree == reviewed tree 7f6676dd; main identical; receipt exit0; R1+R2 attached pre-integration. WAIT resolved for PR37.

Consequences (stale approvals NOT reusable — renewed-evidence rule):

- origin/main = 928a128c4. PR38 (969d86af, based 1a8fa820) and PR39 (b5102259, base contained upstreamed riders) are REBASE-REQUIRED onto 928a128c4 with FRESH test execution + FRESH independent verdicts at the new exact heads (content-identical replay expected; fresh verdicts mandatory regardless).
- Delegated: h8x-impl-a → PR38 rebase + ace-overseer/ace-assign fresh suites; h8x-impl-b → PR39 rebase (riders 7b268023f/a2284f897 drop out — already upstream) + ace-task fresh suite. New STOPs with new exact heads follow reviews.
- F3 lost-operation drill window MOVED to PR38 integration (coordinator): host will withhold the PR38 integration result — my path: no state mutation on assumption; durable re-verification (ls-remote main/refs/pull/38/head, authorized reads); RESULT-QUERY to coordinator. Recorded as the declared drill, not an anomaly.
- Local main note: main checkout = ae73ded33 (spec commits 16ab615ce/ae73ded33 ride the NEXT records PR — intentionally diverged from origin/main 928a128c4, which contains everything else).

## RE-EVALUATION #6 (2026-10-12, PR38 INTEGRATED — host receipt adopted)

PR38 INTEGRATED: fast-forward at exact head 1fbfd1ad; integrated tree == reviewed tree 446efa60; source_ancestor true; exit0; Forgejo API independently shows Merged; R1/R2 attached pre-operation. origin/main = 1fbfd1ad (verified). PR37 integrated 928a128c remains ancestor (source_ancestor true confirms).

## RE-EVALUATION #7 (2026-10-12, queue re-evaluation on moved main + PR40 review reconciliation)

- PR39 (c5dda07f, based 928a128c): REBASE-REQUIRED onto 1fbfd1ad (ace-task-only files; PR38 touched ace-assign/ace-overseer → clean replay expected). Renewed: fresh suite + fresh exact-head verdict (c5dda07f approval stale). Delegated to same worker h8x-impl-b.
- PR40 (ab5bbcc5, based 928a128c): REBASE-REQUIRED onto 1fbfd1ad (ace-hitl/ace-hitl-hermes/ace-lab files; no overlap with PR38 → clean). Review reconciliation: first independent review invocation kTyVFkFl (agy one-shot, pane w6:pG) ended deadline_exceeded at 600.0s (ace-llm default) before writing any report; worktree verified CLEAN (no side effects, no test reports, no orphan processes — process ended conclusively). Recovery path chosen: RE-DISPATCH fresh review at the post-rebase head with --timeout 1800 (resume has nothing durable to resume; re-dispatch is justified, not blind — uncertainty resolved by verification). Delegated: rebase to same worker h8x-impl-c; review re-dispatch follows at the new head.

## RE-EVALUATION #4 (2026-10-12, PR38 R2 re-verification landed)

PR38 R2 APPROVED at NEW exact head 1fbfd1ad (pr38-review-r2.md: range-diff 4×-identical replay vs R1 scope 969d86af; fresh suites re-executed by the reviewer — ace-overseer 310 tests/1918 assertions + ace-assign fast 88 incl. the five new preset contract tests; §1b decision-record fields + placeholder-only publication + no-reparent/PR-ready language intact; callback JSON verified overseer-ace seq 3268). SUPERSEDES re-evaluation #2's head: PR38 integration-eligible at **1fbfd1ad** (not 969d86af); updated STOP relayed to coordinator. Non-blocking N1–N4 carry over.

## RE-EVALUATION #5 (2026-10-12, PR39 R2 re-verification landed)

PR39 R2 APPROVED at NEW exact head c5dda07f (pr39-review-r2.md: range-diff content-identical 6-commit replay vs R1 scope c11d6b6df; fresh suite 515t/1512a; SC1–SC4 spot-checked at the new head; callback JSON verified overseer-ace seq 3265). SUPERSEDES re-evaluation #1's head: PR39 integration-eligible at **c5dda07f** (not c11d6b6df); updated STOP relayed to coordinator. Order unchanged: PR37 (integrated) → PR38 1fbfd1ad → PR39 c5dda07f.

## RE-EVALUATION #8 (2026-10-12, PR39 renewed-evidence verdict at 1265313a)

PR39 re-verified APPROVED at NEW exact head 1265313a (verdict appended to
pr39-review-r2.md: range-diff byte-for-byte identical replay vs R2 scope
c5dda07f; suite 515 tests/1512 assertions green; atomic contract intact;
callback delivered to overseer-ace). SUPERSEDES re-evaluation #5's head:
PR39 integration-eligible at **1265313a** (not c5dda07f); updated STOP
relayed to coordinator. Order unchanged: PR37 (integrated) → PR38 1fbfd1ad
→ PR39 1265313a.

## RE-EVALUATION #9 (2026-10-12, PR40 first review APPROVED)

PR40 (shared-Hermes multi-project transport, task 8xa.t.nh0) R1 APPROVED at
exact head 6a2eae4f (pr40-review-r1.md: 7 commits enumerated all-in-scope;
G-A per-channel socket routing + explicit service identity verified;
G-B --group + dedicated-directory guidance verified; G-D registration-gap
journaling verified; OTP/receipt/restart semantics unchanged; own suite
re-execution ace-hitl 246t/1402a + ace-hitl-hermes 128t/710a green; scope =
ace-hitl + ace-hitl-hermes + ace-lab 0.5.2 dependency only; callback JSON
verified overseer-ace seq 3290). Cosmetic note: the review header's base
line cites 928a128c (stale from the brief); the actual base/diff range used
origin/main 1fbfd1ad (worktree refs fetched post-PR38-integration) — ranges
correct, prose line stale. PR40 integration-eligible at **6a2eae4f**; STOP
relayed to coordinator.

QUEUE COMPLETE: all four entries APPROVED at verified heads — 37 integrated
(928a128c); 38 1fbfd1ad, 39 1265313a, 40 6a2eae4f awaiting host integrator
(order per §1b; 38/39/40 mutually independent files — any order acceptable,
numerical order proposed).

## RE-EVALUATION #10 (2026-10-12, PR38 integration confirmed + stale STOP-UPDATE reconciled + timeout direction recorded)

Host confirmed PR38 was ALREADY MERGED at 1fbfd1ad (exit0, tree 446efa60,
source_ancestor true) BEFORE my STOP-UPDATE arrived — that update was
redundant on arrival; NO repeat integration occurred or is needed. Queue
truth verified on the forge: main = 1fbfd1ad; PR39 head 1265313a and PR40
head 6a2eae4f remain awaiting integration (order PR39 → PR40). Captain
review-timeout tuning direction recorded with incident kTyVFkFl:
900s preferred budget for future/recovered long reviews, subject/context
size + elapsed time recorded per invocation, context-aware sizing assigned
to the existing timeout/review owner for investigation (no unvalidated
formula, no broad global change), PR40's completed review NOT re-run.
See .ace-local/evidence/gad8-hitl/review-timeout-tuning.md.

## RE-EVALUATION #10 (2026-10-12, PR39 INTEGRATED — host receipt adopted)

PR39 INTEGRATED: fast-forward at exact head 1265313a; integrated tree ==
reviewed tree 6a474e66; source_ancestor true; exit0; independent Forgejo
view confirms Merged; R1/R2 attached before effect. PR37/38/39 ALL
INTEGRATED. No publication/installation claim.

## RE-EVALUATION #11 (2026-10-12, PR40 provenance defect + re-evaluation on moved main)

PR40 (6a2eae4f) re-evaluated on moved main: merge-base(6a2eae4f,
1fbfd1ad) = 1fbfd1ad → branch is a direct descendant of current main;
ff-eligible; NO rebase required. Provenance defect (host-verified):
pr40-review-r1.md recorded Base Commit 928a128c4083754... which git
cat-file -e REJECTS (exit 128) — the reviewer expanded the brief's
ambiguous short-prefix prose ("base origin/main 928a128c4") into a
non-existent object without executing verification; the TRUE base at
review time was 1fbfd1ad (worktree origin/main ref, post-PR37-fetch) and
the COMPUTED diff range was correct — only the recorded provenance was
wrong. Root cause shared: queue-owner brief used short/stale base prose.
Correction dispatched (R2) with executed-output requirements.

## RE-EVALUATION #11 (2026-10-12, PR39 INTEGRATED — host receipt adopted)

PR39 INTEGRATED: fast-forward at exact head 1265313a; integrated tree ==
reviewed tree 6a474e66; source_ancestor true; exit0; independent Forgejo
view confirms Merged; R1/R2 attached before effect. PR37/38/39 ALL
INTEGRATED — no publication/installation claims anywhere.

## RE-EVALUATION #12 (2026-10-12, main moved again — PR40 rebase + sharpened review requirements)

origin/main = 1265313a (PR39 integrated). PR40 (6a2eae4f, based 1fbfd1ad)
is REBASE-REQUIRED onto 1265313a (ace-hitl/hermes/ace-lab files; no overlap
with PR37-39 content → clean replay expected). Host SHARPENED the review
requirements: (1) REAL base at review time = origin/main 1265313a after
rebase, exact head stated, ranges provably consistent — no stale-base
artifacts; (2) every host/Incus transport claim explicitly CLASSIFIED:
verified-with-evidence (cited) vs unproven/attribution-required
(attributable gap, host/platform verification like the fullsuite
precedent) — no transport claim passes as verified without evidence.
In-flight pG correction run (base 1fbfd1ad-era) remains a valid analysis
input; the FINAL sharpened review executes post-rebase. Publication
manifest (ace-hitl 0.14.0 / ace-hitl-hermes 0.3.0 / ace-lab 0.5.2 +
digests) prepared alongside per coordinator.

## RE-EVALUATION #13 (2026-10-12, PR40 R2 provenance correction APPROVED)

PR40 R2 correction APPROVED at 6a2eae4f (pr40-review-r2.md: executed-output
provenance correction — R1's base field was a NON-EXISTENT sha
(928a128c4083...) transcribed from the dispatch brief's short-prefix prose,
cat-file exit 128 recorded; TRUE base at R1 review time = 1fbfd1ad; the
COMPUTED diff range in R1 was correct — only the recorded provenance was
wrong; root cause shared with the queue-owner's brief). Locality
qualification: source acceptance is LOCAL-RUNTIME ONLY (within-runtime
SO_PEERCRED valid); the authenticated host+Lab cross-locality route is NOT
executed and remains a MIGRATION GAP owned by gad.8/gad.b — nh0 acceptance
explicitly NOT fully satisfied for the locality aspect. Callback verified
overseer-ace (agent_prompted). MAIN MOVED AGAIN: PR40 rebase onto
origin/main 1265313a delegated to h8x-impl-c (renewed-evidence rule;
final sharpened confirmation review at the post-rebase head with
claim-classification per host sharpening, then STOP).

## RE-EVALUATION #14 (2026-10-12, CAPTAIN AUTHORITY CORRECTION — publication authorized)

Captain authority correction (relayed by coordinator, superseding coordinator
refinements): publication of the SCOPED CHANGED GEMS + required internal
dependencies is AUTHORIZED — the earlier "publication NOT authorized / no
publish action or request" constraint is SUPERSEDED (additive correction;
history preserved). Scope: supervision presets/skill (PR38: ace-assign,
ace-overseer), ace-task atomic fix (PR39), HITL changes (PR40: ace-hitl,
ace-hitl-hermes, ace-lab 0.5.2) + required internal dependencies. Boundaries
unchanged: no credentials granted, no root, exact-head review / artifact
binding / OTP NOT waived — actual supported publisher admission; specific
missing provisioning requested ONCE; fresh OTP only after artifacts ready.
Queue owner now owns release planning + delegation THROUGH PUBLICATION
RECEIPTS. Missing version preparation discovered: ace-assign 0.66.1,
ace-overseer 0.20.2, ace-task 0.39.2 (merged changes UNRELEASED — bumps
pending); ace-hitl 0.14.0 / ace-hitl-hermes 0.3.0 / ace-lab 0.5.2 prepared
(PR40) with artifacts + digests already manifested.

## RE-EVALUATION #15 (2026-10-12, PR41 R1 CHANGES REQUESTED — fix delegated)

PR41 R1 (agy reviewer, distinct from codex executor): CHANGES REQUESTED —
two must-fixes, both diagnosed with executed outputs in
pr41-review-r1.md: (MF1) ace-overseer.gemspec pins ace-assign '~> 0.66.1'
violated by the 0.67.0 bump + Gemfile.lock hand-edited without bundler →
invalid lockfile (bundle check fails at HEAD); (MF2) branch based on
pre-PR40 1265313a → diff vs de4aeb2c reverts PR40 (−795). FIX DELEGATED to
the same worker h8x-impl-c (rebase onto de4aeb2c + gemspec floor to
'~> 0.67' + bundler-regenerated lock + bundle check green + re-push), seq
3328. R2 delta review follows at the reworked head. ROUTING FRICTION
recorded: REVIEWER41-R1-DONE delivered three times (duplicate relays) —
disposition recorded once; no duplicate actions taken.

## RE-EVALUATION #16 (2026-10-12, PR41 R2 APPROVED at a922ef91)

PR41 R2 (post-rework) APPROVED at exact head a922ef91 (R2 section in
pr41-review-r1.md: clean rebase on main, dependency floors harmonized
including the two rebase-resolved gemspec constraint lines judged
legitimate, bundle check satisfied by the queue owner's executed check;
callback JSON delivered overseer-ace via the queue-owner-executed
invocation). SUPERSEDES #15: PR41 integration-eligible at **a922ef91**.
ANCESTRY NOTE: a922ef91's ancestry INCLUDES PR40 (de4aeb2c) — the
recommended integration order preserves exact-head binding: PR38 1fbfd1ad
→ PR39 1265313a → PR40 de4aeb2c → PR41 a922ef91 (each reviewed head
integrates exactly; PR41 last carries the version preparation for the
publication manifest). ROUTING FRICTION: REVIEWER41-R2-DONE also relayed
duplicately — disposition recorded once.

## CORRECTION (2026-10-12, sha-confusion ref operation — host-verified)

ERROR: the queue owner's realignment executed `git reset --hard origin/main`
while checked out on records/h8x-final-records, rewinding that branch from
its true head 6a5c8d88448859920f6d612475e84807d7434f2c to 112ca853e; the
subsequent branch-restore used 6a2eae4f (PR40's head) instead of 6a5c8d88 —
sha confusion between the two similar prefixes hit an actual ref operation.
FIXED (verbatim host commands): records/h8x-final-records =
6a5c8d88448859920f6d612475e84807d7434f2c (rev-parse proof posted). TRUE
heads: PR43 forge head = 5c755cc29 (was correct in prior text); PR44 forge
head = 6a5c8d88 (prior texts citing 6a2eae4f as PR44's head were WRONG —
6a2eae4f is PR40's head). Artifact validity unchanged (host-verified:
PR43 records/design-only, PR44 records/spec-only → the 6 gems built at
a922ef914 remain valid; no re-build). DISCIPLINE ADDED: all future ref
operations use copy-pasted full shas — no manual sha transcription.
