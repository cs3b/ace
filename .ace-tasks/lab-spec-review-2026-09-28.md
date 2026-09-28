# Independent specification readiness review — 2026-09-28

Reviewer: delegated independent agent `/root/spec_reviewer`. This reviewer did not author, edit or promote the task specifications. Review used `as-task-review` / `wfi://task/review`, current source, task-local usage, and the user-approved spec-first program.

**Verdict: APPROVE SPECIFICATIONS. No remaining blocking findings in the reviewed program.** This is readiness for implementation, not proof of runtime delivery, release, installation or live Lab readiness. No operational action is authorized by this review.

## Per-family verdict

| Family | Verdict and scope |
|---|---|
| ACE k86.0–.3, then k86 | APPROVE. Contract/adapter ownership, callback precedence, unavailable versus absent runtime behavior, send uncertainty, lifecycle observation limits and worktree/E2E consumers agree. |
| ACE 1w2 | APPROVE. Deterministic isolation and explicit live-test boundary have observable poisoned-environment and nested-run acceptance. |
| ACE qjl and 1w5 | APPROVE. One assignment execution authority; distinct base/candidate/evidence heads prevent self-invalidating review; recovery preserves uncertain effects and worktrees. |
| ACE 1w4 and qjx | APPROVE. Stable topology and generic scoped request/receipt boundary have distinct ownership; no credential-based authority or second Work engine. |
| ACE 34i, y23, y24, vs2 | APPROVE. Real identity boundary, once-or-uncertain transport, correlated Telegram, ingress reconciliation and ephemeral secret IPC compose without labd. y24 depends on 34i; vs2 depends on actual qjy live wake. |
| ACE qjy, qjz, qk0 | APPROVE. Prompt versus plugin and live wake versus dead-process recovery are explicit. Every precisely presented proposal is eligible for 16-hour silence authorization; technical gates persist. HITL owns decisions while execution state is projected from assignment claims. |
| ACE qk1.0–.2, then qk1 | APPROVE. Provider-neutral worktree, review and issue behavior retains exact identity and provenance, handles mutation uncertainty, and requires server-side merge preconditions. |
| ACE qkb.0–.1, then qkb; qkc | APPROVE. Real assignment and canonical workflow slices ship coherently; direct, standing and proposal authorization paths agree. One owner runs the full provider matrix. |
| ACE ocz and vs3 | APPROVE. Installed workflow verification does not invent missing source; publisher pilot separates artifact authority, OTP and actual registry receipt. No pilot/executor acceptance cycle. |
| lab-config gad.2–.5, .8–.b, nfe; then gad | APPROVE. Domain operation matrix preserves all five root-broker operations plus merge/sync/publish/deploy. Authenticated isolated host maintenance is the sole quiescence exception. Installation, disabled-legacy acceptance, physical retirement and cold-start documentation are distinct gates. |
| lab-config gae, shk, sdx, historical gad.0/.1/.6 and replaced gad.7 | APPROVE DISPOSITIONS. Preserve historical delivered scope, do not infer fresh runtime acceptance, keep obsolete refactor outside next-test path, and link actual successors. shk remains deferred draft; sdx remains pending installed evidence or actual retirement. |
| lab-overseer l2d.3–.8, then l2d; gc0 | APPROVE. Local receipt acceptance and charter adoption are distinct from ACE implementation. l2d.0–.2 skipped dispositions correctly link the delivered foundation, without claiming full consumer migration. |
| Whole cross-repository program | APPROVE. Original intended outcomes have real task owners; cross-repository receipt gates are explicit; first reliability work 1w2 and runtime slice k86.0 are clear; reviewed children precede parent promotion. |

## Findings resolved through independent review

1. Assignment journal commits could change the very candidate HEAD they attested. qjl now uses a separate evidence ref/audit checkout and distinct base_head, candidate_head, evidence_git_ref and journal_commit; qjx/qjz/qkb consume that distinction and tests reject even task-only candidate changes.
2. Commander deadline evaluation lacked a producer contract for ingress drainage. y24 now exposes request/revision received_at and monotonic reconciliation checkpoints; qjz defers on unknown health/backlog and consumes them under its transition boundary.
3. Ordinary Hermes answer files would persist OTP. y24/vs2 now reject this route and pass secret bytes only through the 34i authenticated ephemeral boundary; unavailable consumers require a fresh code.
4. HITL executing/succeeded states risked duplicate execution ownership. qjz now expressly projects assignment claims and service receipts.
5. gad.b publisher acceptance referenced the later vs3 pilot. It now proves the existing tested publisher through qkb on sandbox/fake endpoints; vs3 subsequently owns the authorized real release.
6. Runtime promotion rejected its own active maintenance attempt. gad.b/.a/.3 now specify exactly one authenticated host-maintenance exception whose updater, authorization verifier and receipt sink survive outside the replaced set; all product writers must be quiescent.
7. Umbrella row order placed recovery before its queue dependency. The table is now a capability map with explicit dependency-led sequencing.
8. qkb.1 inadvertently required a new proposal even for an already authorized operation. Direct approval, scoped standing authorization and resolved proposal are now equally valid exact-scope inputs.
9. Runtime drafts retained contradictory fallback, enum and callback flag rules. Normative family text and usage now agree; missing backend is an error, while only assign auto with no detected runtime chooses headless.
10. Generic task completion could be read as waiting for later dependent Lab acceptance. 34i/qk0 distinguish their installed isolated acceptance from later full gad.2 proof.
11. New protected IPC/live-watch dependencies were missing or incompletely listed. y24 now depends on 34i, and vs2 metadata/body include qjy.

12. Program index initially called qk1.1/.2 independent roots. It now places them after qk1.0 and distinguishes first reliability work 1w2 from first runtime slice k86.0.

## Evidence and checks performed

Read all 55 selected task/disposition records and their 41 task-local usage files. Compared critical claims against current DaemonBinding, assignment EvidenceCalculator, Pi loop prompt, Hermes message schema/box, HITL secret handling, provider Base/ServerRegistry, GitHub-coupled consumer paths, and lab_root_broker operation dispatch/environment-approval source.

All reviewed bundle.files resolve, including the added runtime E2E paths. Independent static traversal found no metadata dependency cycles across ACE (1102 records including archive), lab-config (53), and lab-overseer (13). Reviewed body-level cross-repository gates for acceptance cycles as well; the identified cycles were corrected as above. These are static checks, not package or installed runtime test results.

No implementation or live tests were required to approve specifications. Their future requirements are explicit: actual package tests through ace-test/ace-test-suite, independent exact-candidate review, real OS identity/IPC fixtures, installed runtime and transport drills, provider matrix, controlled real 16-hour run and authorized publication pilot. CI remains advisory.

## Digest evidence and promotion

`manifest.json` records exact paths and SHA-256 values for 55 task specs plus 41 usage files and the ACE program index. Task normalized hashes omit only top-level lifecycle metadata lines status, needs_review and position. IDs, dependencies, bundle, all normative body text and usage remain covered. Raw hashes are also retained. Promotion through ace-task may change the excluded metadata without invalidating behavioral approval; any behavioral/dependency/interface edit requires re-review. Persist this report beside tasks rather than inserting it into the hashed normative text.

Manifest SHA-256: `8481234b1bfb1b56b3202e8d6c55d6dd3afc49df32f8e1fb756cc0b4d13bd855`.

Ready draft children may be promoted before their approved parents. Keep expressly deferred/out-of-program tasks and unverified installed evidence in their stated dispositions. Review approval never marks implementation done.

## Post-promotion verification

Independent recheck confirms substantive approval is unchanged after promotion. All 11 changed lab-config normalized hashes reconstruct EXACTLY to their reviewed hashes by restoring only double quotes around title values and a blank line before bundle (plus a blank before title for gad.b). No body, dependency, bundle or metadata-value change occurred. ACE/lab-overseer normalized hashes, all usage files and program index remain unchanged. Current hashes and reconstruction proof are recorded in the refreshed manifest.

The dated wording “Draft; independent review required before promotion” records the editing-pass state. Current pending/needs_review=false metadata and this separate completed independent verdict establish the post-review state; that historical paragraph does not introduce an unresolved review question.
