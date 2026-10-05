# Independent bt0 source review — corrected combined freeze

Candidate: `3df9e6027e36c66e42e6e2e46fa1251cce25ba8e` (includes correction ef7be0535 and main 4d1c415e6).
Reviewer worktree: `/Users/mc/Ps/ace/.ace-wt/review-bt0`, detached at exact candidate. Author worktree/report paths were not used for independent execution.

Verdict: **APPROVE source; zero unresolved verified findings.** Original REQUEST CHANGES at ddfddf5 and its two red boundary checks remain preserved in `bt0-source-review.md`.

The exact correction delta resolves both P2 findings:

- Both ProgressFormatter and ProgressFileFormatter remove every mutable-latest report fallback in report headers, excess-failure headers and truncation tails. A supplied concrete report_path is used; otherwise output explicitly says No saved report and does not invent failures.json or individual detail links. New regression coverage exercises saved/no-save output, header, truncated remainder and individual failure references for both formats.
- ExecutionEvidence#read now refuses successful total-zero snapshots with nonempty selected_files in saved and no-save modes. TestOrchestrator additionally turns actual selected-file/zero-test execution into execution_success:false before report/completion publication in both batch and sequential execution paths. The real CLI child regression verifies nonzero exit and an attributable failed completion, not just a reader refusal. Genuine zero discovery still uses handle_no_tests and remains covered by actual duplicate CLI children in saved/no-save modes. PatternResolver excludes empty sequential target groups, so legitimate empty selection reaches handle_no_tests rather than the selected-execution failure path.

Reviewed the combined candidate against the previously reviewed core: UUID execution identities, exclusive report reservation/completion publication, atomic navigational latest, exact entry/package/path/PID/report identity/count agreement, completion captured once and child exit/timeout/interruption dominance remain intact. Orchestrator, monitor, aggregate, both displays and failure reporters retain separate duplicate entry attribution. No unrelated saved run can replace a captured completion. Historical duration scheduling may read latest without granting verdict authority. No additional source defect was verified.

Independent executed checks at exact candidate:

| Selection | Result | Concrete receipt beneath reviewer worktree |
|---|---|---|
| execution_evidence_test, process_monitor_test, result_aggregator_test via bin/ace-test ace-test-runner feat | PASS 19 tests / 223 assertions, zero failures/errors/skips, 8.92s | `.ace-local/test/reports/test-runner/a2e8ec1e-9568-4f43-a3e2-abab4f3c913e/` |
| progress_report_links_test plus unchanged reviewer-local boundary checks via bin/ace-test ace-test-runner | PASS 3 tests / 57 assertions, zero failures/errors/skips, 4.6ms | `.ace-local/test/reports/test-runner/fe0978cb-6f7e-4419-86d7-986d2ec6ef65/` |

Both report.md files were read. The reviewer-local checks that previously failed now pass at this exact SHA. Author all-target and final combined-suite gates remain separate evidence for root to assess; no broad duplicate suite was run. This is a source verdict for accidental concurrency attribution, without unrequested cryptographic attestation or expanded trust assumptions. No source edits, delegation, native/VM/security probes, push or publication were performed.
