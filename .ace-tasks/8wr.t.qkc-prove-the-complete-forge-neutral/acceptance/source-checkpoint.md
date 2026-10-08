# qkc executable asset source checkpoint — 2026-10-08

Base: `238074f43`, isolated branch `codex/qkc-acceptance-assets`. Source preparation adds three maintained TS-format scenarios under `ace-assign/test/e2e`, nine runner/verifier TC pairs, decision records, an explicit non-secret scope template, matrix and producer prerequisite register. No new CLI/framework, runtime fixture, account installer or second Lab deployment was introduced. Existing coupling-inventory.md and qkc.0 ownership are preserved.

Executed syntax/discovery checks (each exit 0):

- `bin/ace-test-e2e ace-assign TS-DELIVERY-001 --dry-run`: 4 TCs loaded.
- `bin/ace-test-e2e ace-assign TS-DELIVERY-002 --dry-run`: 2 TCs loaded.
- `bin/ace-test-e2e ace-assign TS-DELIVERY-003 --dry-run`: 3 TCs loaded.

These calls load the existing ScenarioLoader and artifact contract validation. They do not execute the scenario, prove an installed producer, verify supplied operation scopes, or establish that every requested fault is currently inducible. Goals and matrix rows express obligations; they are not execution evidence.

Executed existing deterministic tooling check: `bin/ace-test ace-test-runner-e2e all`, exit 0, **657 tests, 2217 assertions, 0 failures, 0 errors, 0 skipped**. Retained report: `/private/tmp/ace-qkc-acceptance-assets/.ace-local/test/reports/test-runner-e2e/298f51d7-df5e-47de-90e6-9d7ee6d74b8a/` (summary.json, report.json, report.md and raw outputs). Verified every decision-record test reference exists. This existing tooling suite is not execution of forge, protected authority or native installed matrix rows. Root delivery owns integrated affected-package/monorepo checks and the single combined independent review; no additional review round was run here.

All installed outcomes remain **UNEXECUTED**. Actual Codex attempt-owned endpoint/startup provenance, actual signed Codex/Pi observation and gad.b operation-specific no-effect/merge handlers require matching producer and installation receipts. The matrix explicitly requires fail/unexecuted reporting for absent public producer/fault controls; it cannot pass from canned goals, local fixture JSON or unsupported required merge capability. gad.2 owns the one installed run; Omarchy→Incus installation remains root-owned, and publication remains Captain interactive OTP. Task completion, main merge and publication were not performed.

Two unintended scope deviations occurred while following repository skills: `bin/ace-task plan qkc` generated a role:planner artifact rather than returning only a cached plan; loading `bin/ace-bundle wfi://git/commit` included ace-git status and read-only GitHub PR activity. Neither is implementation or test evidence, neither produced a remote mutation, and neither is used to justify acceptance. No further planner/model/provider calls were made. The generated plan remains ignored local output. Explicit-message scoped commit avoids LLM message generation.
