# Qjz review round 2 — rejected source and contract

Independent Sol 6.1 source review completed against `722d079e93ef9b983252b16125249a260ea48738` (later `36dc887f` changes receipt/changelog documents only). The five reproduced source findings below remain open until corrected source is independently reviewed.

Root repeated the independent probes: `hitl/8x43ya`, 4 tests/14 assertions, four failures; `overseer/8x43y5`, 3 tests/7 assertions, one failure. These verify the reported defects; they are not passing acceptance. Original probes remain `/tmp/qjz_review_probes_test.rb` and `/tmp/qjz_status_review_probe_test.rb`.

A separate readiness review found two Medium interface gaps: create must return persisted IDs/current delivery state immediately with delivery time/deadline absent until acknowledgement, and revise needs stable operation identity plus expected source revision for retry after a lost response. Those findings have IDs `8x43p13y` and `8x43p13z`. Readiness remains unaccepted pending repair.

Review infrastructure incident: concurrently started source/spec reviews in the same worktree chose `review-8x43mu`. The spec review published its two findings first; the completed source report then replaced the Markdown report, and source feedback extraction explicitly refused to overwrite published findings. The source report below is preserved verbatim. A separate ACE-prepared session `qjz-source-722-round2-recovered` holds the identical source report and explicit recovery provenance for feedback extraction. This is not a second independent review. Future concurrent reviews use distinct explicit session directories; neither review can be treated as approval.

---

<a id="detailed_review_format"></a>
# Detailed Review Format

<a id="enhanced_output_structure"></a>
## Enhanced Output Structure

**Verdict: Changes requested.** The canonical Assign claim guard and separate proposer/transport admission are good foundations. Five correctness issues were reproduced.

<a id="deep_diff_analysis"></a>
### Deep Diff Analysis

1. **High — Retrying a committed revision creates another revision.**  
   [proposals.rb:35](/Users/mc/Ps/ace/.ace-wt/codex-qjz-review-repair/ace-hitl/lib/ace/hitl/lifecycle/proposals.rb:35)  
   If revision 2 commits but its response is lost, an identical `revise` retry reads revision 2, supersedes it, and creates revision 3. The probe returned **3 instead of 2**, replacing the request and potentially restarting its delivery window. Recognize an exact retry of the committed content/caller binding and recover that revision’s prepared projection before superseding anything.

2. **Medium — Ordinary questions now use a byte limit instead of their character limit.**  
   [store.rb:122](/Users/mc/Ps/ace/.ace-wt/codex-qjz-review-repair/ace-hitl/lib/ace/hitl/lifecycle/store.rb:122)  
   The changed condition rejects `"é" * 121`, although it contains fewer than 240 characters and previously passed. Keep the proposal byte bound while retaining the ordinary character bound:
   ```ruby
   question_too_long = kind == "proposal" ?
     question.bytesize > 4096 : question.length > MAX_PLAN_QUESTION
   ```

3. **Medium — Lab status silently hides proposal tick failures.**  
   [status.rb:31](/Users/mc/Ps/ace/.ace-wt/codex-qjz-review-repair/ace-overseer/lib/ace/overseer/cli/commands/status.rb:31)  
   `tick_proposals` captures the failure, but the Lab branch returns before displaying `@proposal_error`. The probe produced normal Lab status with empty stderr despite failed reconciliation. Report the deferred state in Lab table/JSON output while preserving status availability.

<a id="code_quality_assessment"></a>
### Code Quality Assessment

*No issues found*

<a id="architectural_analysis"></a>
### Architectural Analysis

4. **Medium — Generic creation accepts proposals without canonical proposal state.**  
   [store.rb:105](/Users/mc/Ps/ace/.ace-wt/codex-qjz-review-repair/ace-hitl/lib/ace/hitl/lifecycle/store.rb:105)  
   An admitted proposer can submit `kind: "proposal"` through ordinary lifecycle creation. This persists a request without an Assign proposal record. The probe successfully created `hitl-proposal001`; reading it then raised `invalid proposal revision request`. Hermes cannot submit it, and proposal-specific consume/cancel guards leave it unusable. Reject this kind in public `create`, directing callers to `proposal_create`; retain internal preparation for canonical projection.

<a id="documentation_impact_assessment"></a>
### Documentation Impact Assessment

*No issues found*

<a id="quality_assurance_requirements"></a>
### Quality Assurance Requirements

- Existing focused proposal tests: **22 tests, 157 assertions, zero failures/errors**.
- Additional probes reproduced all five findings: [HITL results](/Users/mc/Ps/ace/.ace-wt/codex-qjz-review-repair/.ace-local/test/reports/hitl/8x43u8/report.md), [Lab status results](/Users/mc/Ps/ace/.ace-wt/codex-qjz-review-repair/.ace-local/test/reports/overseer/8x43rs/report.md).
- Add maintained regressions for these cases. Full affected suites and installed sixteen-hour acceptance were not run in this review. Coverage percentage was not measured.

<a id="security_review"></a>
### Security Review

5. **High — Requester reads bypass current project authorization.**  
   [proposals.rb:126](/Users/mc/Ps/ace/.ace-wt/codex-qjz-review-repair/ace-hitl/lib/ace/hitl/lifecycle/proposals.rb:126)  
   Both `proposal_history` and `proposal_access!` allow the original username/UID without checking current project visibility. With that UID’s current grants restricted to `other`, the probe still retrieved its `ace` proposal through both history and show. This violates the documented project visibility gate and exposes prior decision context and rationale after project access is removed. Require current project authorization alongside requester ownership, while preserving project-scoped transport access.

<a id="refactoring_opportunities"></a>
### Refactoring Opportunities

*No issues found*