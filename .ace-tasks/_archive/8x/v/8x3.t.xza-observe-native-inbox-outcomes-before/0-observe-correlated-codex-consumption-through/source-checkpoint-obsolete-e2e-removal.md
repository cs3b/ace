# Obsolete installed-inbox scenario removal

Base: `a275ee043`; worktree: `/tmp/ace-remove-obsolete-inbox-e2e`.
Scoped source cleanup only; task completion and the combined review remain open.

## Approved rewrite plan

The user's bounded cleanup request is the inline approved plan, applied using
the locally read `as-e2e-rewrite` skill and canonical `e2e/rewrite` workflow.

- REMOVE: all three goals, scenario/runner/verifier and three fake executables
  in `ace-herdr/test/e2e/TS-HERDR-001-installed-inbox/` (12 files).
- KEEP: maintained ACE delivery record, inbox, native queue and authenticated
  socket tests; central lab-config:8wl.t.gad.2 installed acceptance ownership.
- MODIFY: active qkc matrix and Pi runner references; qualify the historical
  retrospective result; give the unrelated runtime-context setup unit test a
  generic scenario label so it does not resemble removed discovery.
- CONSOLIDATE: none. ADD: no scenario, fixture, environment or replacement harness.
- Proposed scenario structure: ace-herdr has zero E2E scenarios after removal;
  the existing central TS-DELIVERY assets remain unchanged except the Pi wording.

## Reason and retained requirements

The removed Codex shell script manufactured `consumed_acknowledged` with a
`fake-native:` reference. Its positive verifier required a removed argv
`queue --thread` operation. Fake Herdr and Pi scripts supplied predetermined
pane/session identity and queue receipts. Installing ACE gems around those
scripts did not prove actual original native runtime consumption.

No behavior requirement is removed:

| Former goal requirement | Retained source check / installed obligation |
|---|---|
| Durable enqueue/deliver, concurrent duplicate and restart without resend | `inbox_test.rb`, `delivery_record_test.rb`, `delivery_record_store_test.rb`; gad.2 actual installed execution |
| Lost submission remains uncertain; unsigned/mismatched proof refuses; exact authenticated proof settles | `inbox_test.rb`, `protected_inbox_test.rb`, `inbox_context_service_test.rb`; gad.2 actual observer/signer/import correlation |
| Exact Codex client/thread and payload association | `codex_app_server_transport_test.rb`, `native_queue_executor_test.rb`, `inbox_context_service_test.rb`; gad.2 held installed runtime provenance and completed-turn read |
| Independent Pi session/digest receipt, duplicate suppression, idle wake without payload | `native_queue_executor_test.rb`, `inbox_test.rb`, `protected_inbox_test.rb`; gad.2 actual Pi producer and settlement |
| Installed gem/executable manifest resolution from external checkout | Existing qkc TS-DELIVERY-002/TC-001 obligation under gad.2; local record/socket checks do not prove it |

All listed ACE test paths are beneath `ace-herdr/test/fast/` in their existing
models/molecules/organisms layer. Coverage entries identify source responsibility,
not a new claim that this cleanup executed those tests or passed installed rows.
The removed scenario and its original historical result remain retrievable in Git.

## Verification

Read the complete scenario, runner/verifier, all six goal files, and all three
fixture scripts before deletion. Repository-wide hidden-file reference search
excluding Git and `.ace-local` found no active reference to the removed scenario;
only the qualified historical retrospective and this deletion record retain its ID.
The filesystem-discovered `ace-herdr/test/e2e` scenario count is zero. There is no
new empty scenario directory or runner/verifier pair.

Executed `bin/ace-test ace-test-runner-e2e fast
test/fast/molecules/setup_executor_test.rb`: 44 tests, 137 assertions, pass,
report `.ace-local/test/reports/test-runner-e2e/c354ec65-88d4-42e8-b339-c7d9d238cf33/`.
`git diff --check` passes. No model, E2E execution, native/provider probe,
installation, main merge, push or release was performed.
