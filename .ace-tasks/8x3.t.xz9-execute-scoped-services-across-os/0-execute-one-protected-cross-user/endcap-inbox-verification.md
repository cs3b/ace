# Canonical inbox consumer integration — 2026-10-05

Independent review approved consumer correction `943444bcc28b3387d825a45624e6ef3ca99c9a0c` and shared-settlement correction `07ee624430518909945eb4fa2b970c386a096821`. The cumulative candidate was integrated at `881cc43868b75d198a4666db8b8e08158ccb21d3`. The merged product, tests and configuration are byte-identical to the verified candidate; intervening main changes contain task records and evidence only.

Delivered source: existing canonical inbox registrations can be reconciled through their fixed protected context; exact signed bytes and projection are imported into the existing journal. Retained proof joins the original native/child lineage and current claim. Shared settlement verifies every attributable live/archive copy under the original no-create event lock. Missing, conflicting, malformed or unsettled evidence refuses release. No new journal, fake peer or public scope operation was introduced.

## Executed verification

- `bin/ace-test ace-assign all`: 1003 passed, 2 skipped, 4853 assertions; execution `2862773c-c655-4f44-a272-96012c08e82c`.
- `bin/ace-test ace-herdr all`: 476 passed, 1641 assertions; execution `aafc3f4b-beea-4ebc-bbaf-d435379c3a1e`.
- `bin/ace-test-suite`: exit 1 because Assign exceeded the configured 120-second deadline; the other 50 entries completed with 10434 passed, 24 skipped, 31468 assertions. Assign produced no completed report in this invocation. This failed execution is preserved, not relabeled as a pass.
- Separate retry `bin/ace-test ace-assign fast --timeout=300`: 818 passed, 3017 assertions, 101.81 seconds; execution `c70e071b-4722-4339-9ac5-162b3e56fba3`.

Together the 50 completed suite entries and the separate missing-entry retry cover 11252 passed tests, 24 skipped and 34485 assertions. Every completed entry's immutable execution identity, summary and detailed report digest was independently checked. This is composed coverage, not a claim that the original single suite invocation passed. Exact package reports/raw output and the suite manifest are retained in `evidence/endcap-inbox-verification/`.

Original negative review regressions and corrected passes remain in `evidence/endcap-inbox-review/`; the earlier interrupted full Assign run remains incomplete.

## Remaining scope

This checkpoint supplies reconciliation and the reusable settlement predicate. Canonical `bind_inbox`, finish/recover, complete scope lifecycle and public services composition remain open. No task-wide completion, installed/native/distinct-user proof, publication or Lab acceptance is claimed. Downstream source must consume the independently accepted scope-owner interfaces before enabling these operations.
