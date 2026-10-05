# Independent bt0 readiness review

Reviewed frozen ACE main `2627a7144a7caca950173fb1af9fc815fe42879a`.
Task: `8x4.t.bt0`, including observed-race.md and ux/usage.md.
Verdict: **REQUEST CHANGES — two concrete readiness corrections below.** No implementation or task promotion performed.

The observed arithmetic is coherent: replacing 390/1025 with 25/86 removes 365 tests and 939 assertions, exactly explaining 11203/34177 becoming 10838/33238. The all-green observation proves attribution corruption, and correctly does not claim reproduced verdict contamination. Actual ProcessMonitor reads mutable latest with only mtime freshness; ResultAggregator resolves latest again. ReportStorage allocates clock-derived names using mkdir_p, which can reuse an existing directory. The contract's fixed-clock collision, controlled overlap and failure-direction regression requirements address those real owners.

## Concrete corrections

1. **P2 — Define report-disabled execution semantics.** Spec lines 25-31 require an identity/directory and summary/detail/raw evidence for every invocation, and line 29 makes absent/incomplete evidence a failed result. Existing supported `save_reports: false` causes ProcessMonitor#build_command to add --no-save and TestOrchestrator#run/save paths to skip report persistence. SC5 preserves standalone/suite usability, but does not decide what disabled reports mean under the new mandatory evidence requirement. Declare a single behavior before promotion: recommended default is an internal identity-bound machine completion receipt for every suite child independent of optional human report saving; report-disabled mode must preserve truthful captured counts/verdict without borrowing latest or exit-only proof. Specify whether concrete retained detail links exist in this mode or are explicitly absent, and add a real CLI test with saving disabled. Do not leave implementation to silently override the user's saving preference or fail every previously usable report-disabled run.

2. **P2 — Include required consumer owners in fresh-session task context.** The bundle currently names only ProcessMonitor, ResultAggregator, ReportStorage and ReportPathResolver. Actual duplicate-entry identity and progress ownership also live in Suite::Orchestrator (results keyed by package name), DisplayManager and SimpleDisplayManager (statuses keyed by package name). FailedPackageReporter resolves latest anew for detail links; TestOrchestrator owns report creation/publication and optional save behavior. Add these source files to bundle.files and explicitly list them as affected runner consumers. This is required to deliver the stated end-to-end duplicate-entry/progress/stable-link result rather than repairing only aggregation.

## Accepted contract decisions

One unique identity per actual invocation, exclusive allocation under equal clocks, separate duplicate entries, captured result retention, identity consistency between summary/detail, immutable concrete links, missing/malformed/incomplete/mismatched/unreadable evidence refusal, nonzero/timeout/interruption dominance and no latest/mtime/exit-only fallback are all sufficiently clear. Ordinary zero executed tests with a valid attributable completed receipt should follow existing selection semantics; zero exit without such evidence remains unverifiable. Internal allocation/publication mechanisms are implementation decisions, not new user-facing protocol work. Default budgets and test selection remain outside this repair.

Verification is appropriately deterministic and includes actual child/storage orchestration plus focused/affected package/default-suite gates and independent source review. No tests were necessary for this specs-only review: both corrections follow directly from current source and explicit draft requirements. No host-load burn, native probes, source edits, agents, push or publication.

Reviewed as-task-review SKILL.md and loaded wfi://task/review; bounded assignment explicitly reserves promotion and task edits to root.

## Repaired contract rereview

Reviewed `f907861a31a6bb34a971917287f471320654e911`. Both prior readiness findings are resolved: mandatory identity-bound machine completion is independent of optional saved reports; no-save output exposes no fabricated persistent link; explicit completed zero-selection is distinguished from missing completion. All actual orchestration/display/failure-link/publication owners are now bundled and explicitly share the contract. The behavior is decision-complete, including truthful failure dominance and duplicate entries.

Verdict at this SHA: **REQUEST CHANGES for one concrete usage correction only.** `ux/usage.md` says "a suite entry using save_reports: false". The actual existing seam is suite-wide `test_suite.test_options.save_reports`: Suite::Orchestrator reads that shared options hash once and ProcessMonitor#build_command reads options["save_reports"], with no package-entry override. Replace the example with that exact nested configuration key (or equivalent YAML). This keeps usage executable without silently introducing a new per-entry configuration contract. No implementation or tests are needed for this correction; source directly establishes it.

## Final readiness verdict

Reviewed `ae6fc43966c6848e4554de85e2146b2467635345` and its exact task-scoped delta from f907861a3. The only behavioral usage delta replaces the unsupported per-entry saving example with the actual existing suite configuration `test_suite: { test_options: { save_reports: false } }`. It matches Suite::Orchestrator's shared test_options and ProcessMonitor's save_reports lookup. Earlier review history is retained separately.

**APPROVE readiness for 8x4.t.bt0 at this exact SHA. Zero unresolved findings or blocking behavior decisions.** Execution identity, collision-safe saved evidence, independent duplicate entries, current machine completion in saved/no-save/zero-selection modes, truthful failure dominance, both display modes and immutable optional links are specified end to end. Verification scenarios cover the corresponding success, invalid and concurrency paths. This is specification readiness only; no implementation, execution acceptance, task promotion or tests were performed in this final correction review.
