# Specification-stage completion — 2026-09-28

The user-approved specification stage is complete. No runtime implementation, deployment, release, Git commit or live-Lab acceptance was performed. Only `.ace-tasks/` artifacts changed across ACE, lab-config and lab-overseer.

## Review and promotion

The independent reviewer approved 55 task/disposition records, 41 usage files and the ACE program index after correction rounds. 46 approved drafts were promoted through `ace-task update` (27 ACE, 11 lab-config, 8 lab-overseer), children before their parents; each was verified with `ace-task show`. The original editing-pass notes saying draft/review pending describe earlier history. The final independent report and current frontmatter are authoritative for this specification stage.

The exact independent verdict is `lab-spec-review-2026-09-28.md`; its companion manifest is `lab-spec-review-2026-09-28.manifest.json` (named manifest.json in the reviewer working directory). Copies exist in all three repositories. Approval covers specification readiness, not delivered behavior.

## First work and gates

Start with ACE `8wq.t.1w2` for reliable hermetic verification. The first runtime capability is `8wq.t.k86.0`; independent contract roots are `8wr.t.qjl`, `8wq.t.1w4`, `8wr.t.qjy`, `8wj.t.ocz`, and `8wr.t.qk1.0` after delivered l1e. Other pending tasks wait on their recorded prerequisites and external evidence gates: pending means reviewed, not all immediately runnable.

The full ordered path is in `lab-readiness-2026-09-28.md` in ACE and the canonical cross-repository umbrella is lab-config `8wl.t.gad`. Full system acceptance belongs to gad.2 after coherent installation gad.a; gad.3 removes legacy and repeats acceptance, followed by gad.4 cold-start proof. The full test must not be mistaken for an early validation of the old control plane.

Replaced scopes: lab-config gad.7 → ACE vs0/k84/k86; lab-overseer l2d.0–.2 → delivered ACE l1e. These four are skipped, with history and successor links. Historical completed gad.0/.1/.6 remain done only for their original scope. New work is 13 ACE records plus lab-config gad.b; the latter explicitly owns each privileged domain operation rather than hiding it in an umbrella.

Outstanding evidence: lab-config sdx remains pending with the source fix present but no current installed proof; shk remains deferred draft outside the next-test gate and can be cancelled only once retirement is evidenced. None of the newly reviewed contracts has an unresolved specification blocker. Runtime implementation, executed tests, independent candidate review, exact artifact installation and controlled live drills remain future delivery requirements.

## Executed verification

| Check | Result |
|---|---|
| ace-task show | All 46 promotions verified individually. |
| ace-task list | All three repositories list the intended current parents and dispositions. |
| ACE doctor | 732 tasks; same 7 historical errors as baseline, 446 warnings (baseline 451). No new program error. |
| lab-config doctor | 53 tasks, no errors/warnings, score 100/100 (baseline 52 tasks and 2 warnings). |
| lab-overseer doctor | 13 tasks, no errors/warnings, score 100/100. |
| Local metadata dependency graph / bundle paths | Independent review found no cycles or missing reviewed bundle paths; body-level cross-repository cycles corrected before approval. |
| lab-config task-ID provenance unittest | Passed (1 test). |
| git diff --check | Passed in all three repositories. |
| Change scope | Only task artifacts; product source untouched. |

The seven pre-existing ACE doctor errors are archived records: obsolete status in 8c0.t.070; missing IDs in 8q5.t.na8/nah/nai/naj and 8vt.t.rtr; invalid in_progress in 8qm.t.5nx. They were not converted into programme blockers or silently repaired. The mise warning about tracking-config symlinks outside the sandbox did not prevent successful task operations.

## Final selected task states

### ace

| Task | State | Local prerequisites |
|---|---|---|
| `8wj.t.ocz` | pending | None; see explicit external receipt gates in spec |
| `8wm.t.vs2` | pending | 8wq.t.34i, 8wm.t.y23, 8wm.t.y24, 8wm.t.vs0, 8wm.t.vs1, 8wr.t.qjy |
| `8wm.t.vs3` | pending | 8wm.t.vs2, 8wr.t.qjx, 8wr.t.qkb |
| `8wm.t.y23` | pending | 8wm.t.vs0, 8wr.t.qjl |
| `8wm.t.y24` | pending | 8wm.t.vs1, 8wq.t.34i |
| `8wq.t.1w2` | pending | None; see explicit external receipt gates in spec |
| `8wq.t.1w4` | pending | None; see explicit external receipt gates in spec |
| `8wq.t.1w5` | pending | 8wr.t.qjl, 8wq.t.k86, 8wm.t.y23 |
| `8wq.t.34i` | pending | 8wr.t.qjl, 8wr.t.qjx |
| `8wq.t.k86` | pending | 8wq.t.k84, 8wm.t.vs0 |
| `8wq.t.k86.0` | pending | None; see explicit external receipt gates in spec |
| `8wq.t.k86.1` | pending | 8wq.t.k86.0 |
| `8wq.t.k86.2` | pending | 8wq.t.k86.0, 8wq.t.k84 |
| `8wq.t.k86.3` | pending | 8wq.t.k86.1, 8wq.t.k86.2 |
| `8wr.t.qjl` | pending | None; see explicit external receipt gates in spec |
| `8wr.t.qjx` | pending | 8wq.t.1w4, 8wr.t.qjl |
| `8wr.t.qjy` | pending | None; see explicit external receipt gates in spec |
| `8wr.t.qjz` | pending | 8wm.t.vs2, 8wr.t.qjx, 8wr.t.qjy |
| `8wr.t.qk0` | pending | 8wq.t.k86, 8wr.t.qjl, 8wr.t.qjx, 8wr.t.qjy, 8wq.t.1w5, 8wm.t.vs2, 8wr.t.qjz |
| `8wr.t.qk1` | pending | 8wk.t.l1e |
| `8wr.t.qk1.0` | pending | 8wk.t.l1e |
| `8wr.t.qk1.1` | pending | 8wr.t.qk1.0 |
| `8wr.t.qk1.2` | pending | 8wr.t.qk1.0 |
| `8wr.t.qkb` | pending | 8wr.t.qk1, 8wr.t.qjl |
| `8wr.t.qkb.0` | pending | 8wr.t.qk1, 8wr.t.qjl |
| `8wr.t.qkb.1` | pending | 8wr.t.qkb.0, 8wr.t.qk0, 8wr.t.qjx, 8wr.t.qjz |
| `8wr.t.qkc` | pending | 8wr.t.qk1, 8wr.t.qkb |

### lab-config

| Task | State | Local prerequisites |
|---|---|---|
| `8wl.t.gad` | pending | None; see explicit external receipt gates in spec |
| `8wl.t.gad.0` | done | None; see explicit external receipt gates in spec |
| `8wl.t.gad.1` | done | None; see explicit external receipt gates in spec |
| `8wl.t.gad.2` | pending | 8wl.t.gad.a, 8wl.t.gad.b, 8wl.t.gad.5, 8wl.t.gad.8, 8wl.t.gad.9, 8wm.t.nfe |
| `8wl.t.gad.3` | pending | 8wl.t.gad.2 |
| `8wl.t.gad.4` | pending | 8wl.t.gad.3 |
| `8wl.t.gad.5` | pending | None; see explicit external receipt gates in spec |
| `8wl.t.gad.6` | done | None; see explicit external receipt gates in spec |
| `8wl.t.gad.7` | skipped | None; see explicit external receipt gates in spec |
| `8wl.t.gad.8` | pending | None; see explicit external receipt gates in spec |
| `8wl.t.gad.9` | pending | None; see explicit external receipt gates in spec |
| `8wl.t.gad.a` | pending | 8wl.t.gad.b, 8wl.t.gad.5, 8wl.t.gad.8, 8wl.t.gad.9 |
| `8wl.t.gad.b` | pending | None; see explicit external receipt gates in spec |
| `8wl.t.gae` | pending | 8wm.t.nfe, 8wl.t.gad.4 |
| `8wm.t.nfe` | pending | 8wl.t.gad.5, 8wl.t.gad.8, 8wl.t.gad.9, 8wl.t.gad.b |
| `8wn.t.shk` | draft | None; see explicit external receipt gates in spec |
| `8wp.t.sdx` | pending | None; see explicit external receipt gates in spec |

### lab-overseer

| Task | State | Local prerequisites |
|---|---|---|
| `8vu.t.l2d` | pending | None; see explicit external receipt gates in spec |
| `8vu.t.l2d.0` | skipped | None; see explicit external receipt gates in spec |
| `8vu.t.l2d.1` | skipped | None; see explicit external receipt gates in spec |
| `8vu.t.l2d.2` | skipped | None; see explicit external receipt gates in spec |
| `8vu.t.l2d.3` | pending | None; see explicit external receipt gates in spec |
| `8vu.t.l2d.4` | pending | None; see explicit external receipt gates in spec |
| `8vu.t.l2d.5` | pending | None; see explicit external receipt gates in spec |
| `8vu.t.l2d.6` | pending | 8vu.t.l2d.3, 8vu.t.l2d.4, 8vu.t.l2d.5 |
| `8vu.t.l2d.7` | pending | 8vu.t.l2d.6 |
| `8vu.t.l2d.8` | pending | 8vu.t.l2d.3, 8vu.t.l2d.4, 8vu.t.l2d.5, 8vu.t.l2d.6, 8vu.t.l2d.7 |
| `8wl.t.gc0` | pending | None; see explicit external receipt gates in spec |


## Final post-promotion verification

All 97 reviewed artifact hashes match the final independent manifest. The reviewer proved the 11 lab-config serialization changes equivalent by reconstructing the exact pre-promotion hashes; see `lab-spec-promotion-equivalence-2026-09-28.json`. Final manifest SHA-256: `8481234b1bfb1b56b3202e8d6c55d6dd3afc49df32f8e1fb756cc0b4d13bd855`.
