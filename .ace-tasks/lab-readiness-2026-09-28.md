# Lab readiness: specification and execution index

This is the ACE entry point to the approved spec-first program. The canonical cross-repository owner map is lab-config task `8wl.t.gad`; this index does not create another program or state engine. Specifications describe target behavior, not delivered runtime functionality. No application code or deployed Lab was changed in this pass.

## Decisions carried forward

- Remove Python lab/labd and replaced control brokers after their used capabilities have successors and installed acceptance; keep domain catalog/provisioning/installers.
- ace-assign alone owns attempts, accepted execution evidence and effect claims. Store evidence in a separate Git ref so recording a receipt cannot change reviewed candidate HEAD.
- Runtime is tmux/herdr; deployment topology and role services are independent. Adapters stay inside existing wrapper gems; callback uses ace-runtime send.
- Any precisely presented proposal can be authorized by 16h of verified silence after transport-confirmed delivery, including publication/deployment/access changes. Existing valid direct or scoped standing authorization need not be proposed again. Technical tests, independent review, exact target and credentials remain required.
- Ordinary HITL questions and OTP do not inherit proposal expiry. OTP bypasses persistent folder answer files through protected ephemeral consumption.
- Executed tests and independent review gate delivery; CI is advisory.

## Task dispositions and evidence

| Tasks | Disposition | Reason and evidence |
|---|---|---|
| k86 and .0–.3 | Keep and repair | Contract absent in source; preserve send/wait semantics and decisions, correct actual HERDR_* detection, packaging contradiction, callback resolution and excluded worktree/E2E consumers. |
| 34i | Rewrite | Was title-only; source lifecycle store uses protected ownership and old daemon binding. Now scoped multi-user store contract with real UID/IPC checks. |
| y23, y24, vs2 | Rewrite | Existing Deliverer/HermesBox are foundations, not complete queue/plugin/daemon-free delivery. Provider Lab#deliver is unsupported and DaemonBinding still calls labd.sock. |
| vs3 | Refine | Keep authorized publication pilot; separate fake executor proof from real release, authorization from ephemeral OTP, and uncertainty from retry. |
| 1w2, 1w4, 1w5 | Rewrite | Title-only briefs become test isolation, stable topology and attributable recovery contracts. Replace stale historical 1cl/1ce/1cc refs. |
| ocz | Verify existing delivery, repair only reproduced gap | Source registration/payload/packaging test exist. Neutral local resolve probe failed; current built/installed isolated proof is still required, not assumed missing source. |
| qjl, qjx, qjy, qjz, qk0 | New uncovered outcomes | Durable assignment evidence; scoped service seam; real Pi wake extension; commander policy; generic responsive roles and removal of legacy LabClient/runtime=lab. |
| qk1/.0–.2, qkb/.0–.1, qkc | New ACE owners for remaining l2d outcomes | Foundation provider API is primarily read-only; actual consumers still bind GitHub. Define both-provider mutations, downstream workflows and parity acceptance, with real child slices. |
| k84, vs0, vs1, vrz, y21, 1w0, 1vz, l1e, release records | Preserve completed scope | Source ControlSurface/Deliverer/HermesBox/lifecycle/tidy/provider core and loop prompt exist. These records are not proof of full daemon removal or a timer plugin. Do not reopen completed scope to add new behavior. |
| lab-overseer l2d.0–.2 | Skipped, replaced | ACE l1e owns shipped foundation; skipped avoids inventing new delivery proof. l2d.3–.8 now accept exact ACE owner receipts, not duplicate implementations. |
| lab-config gad.7 | Skipped, replaced | Generic wrapper owned by ACE vs0/k84/k86. Other corrected domain scopes remain real receiving/executor/installation tasks. |
| lab-config sdx | Existing source fix, installed proof unresolved | Preserve pending; source d416616/aa8929c is not newly reimplemented and local spec pass does not attest current live runtime. |
| lab-config shk | Outside next-test gate | Defer obsolete-code refactor; supersession requires actual deletion evidence, not intent to delete. |
| vle and unrelated active/maybe/archive feature work | Outside program | No discovered dependency on daemon-free Lab acceptance. No blanket reopening of archived README/compressor/scheduler/performance work. |

Historical bodies remain under task history/audit artifacts with non-normative labels. Do not execute instructions from those snapshots. No invalidated/obsolete custom lifecycle status is introduced.

## Executable path after spec approval

Start with `8wq.t.1w2` as the reliability prerequisite (hermetic tests); `8wq.t.k86.0` is the first runtime capability slice. Independent ready roots are `8wq.t.k86.0`, `8wr.t.qjl`, `8wq.t.1w4`, `8wr.t.qjy`, `8wj.t.ocz` and forge consumer `8wr.t.qk1.0` (after existing l1e foundation); qk1.1/.2 follow qk1.0.

1. k86.0 → k86.1 and k86.2 → k86.3; parent closes on all child outcomes.
2. qjl + 1w4 → qjx → 34i; existing vs0 + qjl → y23; existing vs1 + 34i → y24.
3. 34i + y23 + y24 + qjy + delivered vs0/vs1 → vs2. qjl + k86 + y23 → 1w5.
4. vs2 + qjx + qjy → qjz; k86 + qjl + qjx + qjy + 1w5 + vs2 + qjz → qk0.
5. qk1.0 → qk1.1 and qk1.2 → qk1; qk1 + qjl → qkb.0; qkb.0 + qk0/qjx/qjz → qkb.1. Deliver qkb.0/.1 together; qkb → qkc provider matrix.
6. Domain gad.b/gad.8/.9/.5/nfe consume exact ACE contracts. gad.b tests publication using fake/sandbox endpoints; vs3 later uses its accepted executor for a genuinely authorized real release. Neither prerequisite waits for the later full Lab acceptance.
7. gad.a installs coherent artifacts → gad.2 proves full model with legacy disabled → gad.3 removes legacy and repeats acceptance → gad.4 proves cold-start docs. Domain metadata/body gates specify exact prerequisite receipts.

Local `dependencies` are executable ordering constraints. Cross-repository references name repository+task and the required receipt; they are not inserted as unresolved local IDs. Independent installed fixtures prove prerequisite tasks; later integrated Lab acceptance is a distinct gate, avoiding circular completion requirements.

## Review and verification

All materially changed/new specs enter draft with needs_review. Independent reviewer checks children, families and the whole program before promotion; acceptance does not claim implementation. The final verdict and behavioral hashes are recorded in `lab-spec-review-2026-09-28.md`.

ACE doctor baseline: 7 historical errors and 451 warnings, all retained outside the edited program; post-edit doctor has the same 7 historical errors and 446 warnings after correcting five titles. lab-config baseline: 52 tasks and two warnings; corrected domain index has 53 tasks and no issues. lab-overseer baseline: 13 tasks/no issues. Final report records actual post-promotion checks separately.

Skills loaded/applied: as-task-finder, as-search-feature-research, as-task-draft, as-task-review, as-task-update, as-test-plan. as-task-plan informed the earlier roadmap only; no source implementation workflow executed. Verification here is task structure/IDs/dependency graph/diff and independent spec review, not runtime acceptance.
