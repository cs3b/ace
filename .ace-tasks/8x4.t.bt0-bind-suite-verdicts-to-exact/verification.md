# Invocation-bound suite evidence verification

Final frozen source: `3df9e6027e36c66e42e6e2e46fa1251cce25ba8e`, isolated branch `codex/suite-invocation-evidence`. This includes implementation `ddfddf5bc`, reviewed corrections `ef7be0535`, and root main `4d1c415e6` with independently approved IBL tests. Independent source re-review: **APPROVE**, zero unresolved findings. Root owns integration, lifecycle and publication. No version bump or task completion was performed in this worktree.

## Final executed gates

| Invocation | Outcome | Concrete execution/report identity |
|---|---|---|
| `bin/ace-test ace-test-runner fast` | PASS 182 tests / 534 assertions | `5ff600cf-f615-40c7-8db0-20c774d64a76` |
| Actual completion regression selection | PASS 10 / 189 | `80296747-3b92-4621-abde-8f1a1bbe0fe5` |
| `bin/ace-test ace-test-runner all` on final combined source | PASS 268 / 1228; 31 selected files | `30ac133e-a668-40b9-a981-353c3b93c440` |
| `bin/ace-test-suite --timeout 300` on final combined source | Exit 0; 51 passed entries / zero failed; 212.09s | All 51 exact receipts in `evidence/2026-10-05/suite-package-receipts.json` |
| Focused run after suite runner child completion | PASS 1 / 52 | `ff8f1c13-ddeb-4235-9020-55855fecf823` |
| Actual focused `--no-save-reports` invocation | PASS 1 / 52, no optional report directory | `e71cff7b-20d7-405f-a8d5-df29b27ff501` |

The suite manifest retains each actual completion, process PID, selected files, package/entry/execution identity, concrete report directory, summary and detailed-result readback. All 51 entry IDs, execution IDs and report directories are distinct. Summary/detail IDs, selection and counts were compared with that exact completion; no latest pointer supplied acceptance evidence.

Aggregate arithmetic over all 51 receipts: **11,229 total = 11,205 passed + 24 skipped + zero failed/errors; 34,232 assertions**. These equal the final suite's displayed totals. Assign completed in 206.04s; the explicit authorized timeout override was necessary. The existing 120-second configuration and selections remain unchanged.

## Controlled interference during the final gate

The real suite printed its completed ace-test-runner child before the focused invocation was launched. Child execution `23838e67-ba9a-4bb2-b9ae-5d35e0264bbf`, entry `18df26e5-6901-488a-a0c6-13cd36b72e20`, PID 83442, retained **182 tests / 534 assertions**. While other suite entries remained active, the focused formatter regression executed **1 test / 52 assertions**, identity `ff8f1c13-ddeb-4235-9020-55855fecf823`, and changed latest to that identity. Latest still pointed at the focused run after the suite exited.

The final aggregate includes the suite child's 182/534, not the focused 1/52. Replacing that child with focused latest would produce 11,048 total / 11,024 passed / 33,750 assertions: a loss of **181 tests and 482 assertions**. The actual aggregate remains 11,229 / 11,205 / 34,232. Both completions, concrete report/summary/raw artifacts and the full arithmetic are retained in the evidence folder.

The duplicate Lab selections each retain 199 total / 198 passed / one skip / 697 assertions:

| Entry ID | Execution ID |
|---|---|
| `6f8817ce-e935-43f0-b145-08b5deb01fe5` | `ae69c453-a922-4bef-aa4a-8343ce91bb2e` |
| `95585189-a6df-4027-8fdf-78d761668d60` | `8654928e-d045-4041-8e5a-fe338bab45b2` |

Both separately contribute to totals: 398 total / 396 passed / two skips / 1,394 assertions. Their concrete report directories and full completions are in the manifest. Explicit zero-selection completions for ace-monorepo-e2e, ace-support-mac-clipboard and ace-test have empty selected_files and zero tests. The retained actual no-save completion has report_dir:null; no raw/detailed/human report was created for that identity.

## Acceptance coverage and review history

SC1/SC4: Barrier-controlled child A, opposite-outcome saved run B, release A, then another latest replacement. Four saved/no-save passing/failing cases retain A's captured verdict/counts/assertions/link. The actual final gate adds concurrent focused interference with retained arithmetic.

SC2: Fixed-clock concurrent real ReportStorage allocation preserves eight reports. Real CLI duplicate entries and both displays preserve separate states. Final suite retains all 51 reports including both Lab selections.

SC3: Absent/incomplete/malformed/mismatched/unreadable completion and mixed summary/detail fail. Nonzero exit/timeout/interruption dominate valid passing completion without fabricating completed test errors; trustworthy counts remain.

SC5: Actual saved/no-save duplicate CLI children and explicit zero discovery pass. Selected-but-unexecuted zero success is rejected by saved/no-save readers, and actual CLI execution publishes truthful failure/nonzero exit. Both progress formatters cover failure headers, truncation and exact saved links; no-save never invents latest/details links.

SC6: Actual CLI fixtures, affected package all, final default fast suite with configured duplicate entries, and independent exact-SHA review all passed. No required user flags were added. No further tests ran after these gates without a concrete evidence requirement.

Initial source `ddfddf5bc` received REQUEST CHANGES for two independently reproduced P2 gaps: no-save formatter latest links and selected-but-unexecuted zero success. Both were fixed, meaningful regressions added and re-reviewed at the final combined SHA. The original review/red boundary evidence remains in `bt0-source-review.md`; approval and independent 19/223 plus formerly red boundary 3/57 receipts are in `bt0-source-review-round2.md`. Earlier development checks also exposed outdated diagnostic tests and Suite::Error shadowing; those were corrected before final gates. No failed check is claimed as a pass.

## Skills and workaround

Loaded/executed task-work, test-plan and worktree-create workflows, and used scoped commit/test verification workflows. Native Git worktree creation was root-authorized because the task-aware tool is known to fail in private commit_scoped and mutate primary task frontmatter despite no-status/no-commit. That tool remained outside scope. No paid, native, VM or privilege probe was added. Only root integration/task lifecycle/publication remains.
