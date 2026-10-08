# Direct Inbox enqueue/deliver source checkpoint

## Independent review repair

Review session review-8x71j2 verified findings 8x71u09h/i: normalize the actual BoundedProcess selector deadline before downstream starts, and add package changelogs. The repair catches Timeout::Error only in discovery/selection; a downstream effect's Timeout::Error is re-raised unchanged. An actual controlled Ruby sleeping child reaches the real bounded runner deadline before any context/effect callback. Cosmetic duplicate blank/help drift is corrected too.

Executed inspected test file: `bin/ace-test ace-herdr test/feat/protected_inbox_cli_test.rb --config-path /Users/mc/.codex/worktrees/xza-direct-cli-contract/ace/.ace/test/runner.yml`. Retained report `.ace-local/test/reports/herdr/537d8327-af51-4ab1-a155-b1955475fa98`: actual 3 tests/103 assertions PASS, raw seed21541, 0.184256s. Includes the existing registered socket composition and both deadline regressions; native/Linux identity and installed probes remain excluded. Separate returned-issuer state implementation is not part of this repair.

The root independently reviewed the technical candidate through ce9b5c576 and accepted bounded technical readiness; equivalent documentation is integrated on main through c2ea2feeb. This implementation worktree retains its original candidate ancestry and imports the shared participant classifier main05e7c951e as1a3f593ea. Whole xza.3 remains draft; this checkpoint changes no task metadata or success criteria and is not self-approved.

## Implemented bounded source

The fixed Assign inbox-context-principal and inbox-context-selection commands reuse PreparedTaskContext's accepted immutable entry hook and ProtectedAssignmentContext's shared current/retained classifier. Selection reads exact current descriptor/history references through held artifacts and returns only fixed endpoint/credential/context references; authorization remains on the actual context socket peer.

Herdr's registered Inbox command classifies before local config or file construction, refuses protected selectors including empty values in absent/ordinary environments, and uses the held Runtime entry/FD selector protocol without importing Assign. Enqueue carries one bounded strict metadata envelope then exact raw UTF8 payload/EOF. The same existing context owner persists direct effect selectors before entry, performs source Inbox enqueue, revalidates the real retained record before known idle, and independently revalidates on resumed admission/end. Unknown post-write interruption remains unknown across restart.

Protected delivery compares the explicit original claim generation inside the same Inbox event transaction. Older-generation replay returns retained state before native or wake paths. Source owner keeps uncertain/native-unknown or delivered/pending-wake admission unknown; the CLI never ends from delivered state alone. Closed source replies expose only bounded record fields and the idle/unknown observation, not raw native output. Existing canonical reconciliation completion validation and other-purpose with_operation invariants remain unchanged.

## Executed controlled evidence

Final inspected command:

`bin/ace-test ace-herdr test/fast/commands/inbox_test.rb test/fast/organisms/inbox_context_server_test.rb test/fast/organisms/inbox_direct_effects_test.rb test/feat/protected_inbox_cli_test.rb --config-path /Users/mc/.codex/worktrees/xza-direct-cli-contract/ace/.ace/test/runner.yml`

Report `.ace-local/test/reports/herdr/ed933a09-b0ff-49fe-ae3c-b55ddf63987a`: actual4/38 files,19 tests/227 assertions PASS, raw seed49298,1.341770s. Report JSON confirms the exact absolute config path and selected files. The maintained composition uses the registered Herdr parser, actual Runtime held-entry discovery and descriptor selector, actual fixed Assign command/ProtectedAssignmentContext projection, authenticated real path context sockets, actual owner/key/store/DeliveryRecord and locks. Static installed descriptor/history owners/protection, kernel observations and native execution are controlled. The selected-child subprocess boundary is explicitly dispatched in process to the actual source command in this fixture, not executed as a child subprocess; that complete producer/child proof remains open.

Coverage includes exact enqueue/deliver replay with one native submission; conflict leaves ledger bytes unchanged and unknown admission retained; short/surplus/invalid-length/hash/UTF8/NUL/extra-field ingress refuses before effect entry; known-idle reply-loss-style restart rechecks retention before begin/end; interrupted enqueue after durable write cannot become completion by restart; pending wake stays unknown and replay calls neither native nor wake; future generation and foreign attempt refuse before effect entry; ordinary commands remain supported with all installation observations injected.

Earlier reports retained: c7ee4384 (production constant qualification error, fixed); a1666d01 (fixture expected integer failure return although Runner raises typed CLI error, fixed);7f02be86 (fixture compared raw wake explanation with deliberately bounded projection, replaced by exact ledger-byte comparison);199067b5 (fixture used wrong retained-control filename, fixed). Intermediate PASS reports3ab37a43 (1/58),047bccae (1/96),5add1cfe (5/126),a048f2d1 (11/183) remain available. No installed/native/Linux identity/root/systemd/external probes were executed.

## Remaining required work and gate

Independent source review is required before integration. The selected immutable Lab producer allowlist join and actual selected child subprocess→registered CLI composition remain required; the in-process dispatch seam does not substitute for them. Protected direct reconciliation through the existing authority RPC, actual canonical import/CAS/completion/replay and receiver-role negatives remain unimplemented here. Additional input/projection/ref-drift negatives, lost actual transport reply, wrong/dead context peers and concurrent issuer cases must complete the reviewed map before whole-source acceptance. Existing xza.3 original-writer termination/downstream-drain recovery and full receipt-key retirement criteria remain mandatory family scope. This checkpoint neither closes xza.3 nor claims installed Lab acceptance; all installation/system executions remain solely gad.2.
