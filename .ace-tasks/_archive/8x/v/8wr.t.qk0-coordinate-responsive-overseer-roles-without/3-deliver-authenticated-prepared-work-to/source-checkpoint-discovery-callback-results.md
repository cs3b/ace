# Protected discovery callback result source checkpoint

Scope: existing Runtime ProtectedTaskContextEntry only. Both discovery and held-entry callbacks now preserve their exact return value after the unchanged-artifact post-check. No new API, permission, schema or authority; nil/false and object identity remain intact, and verification errors still refuse before any result returns.

The actual Lab emitted-wrapper/Runtime/Assign/Bundle fixture exposed this defect: the fixed child produced a valid principal response, but with_entry returned the subsequent verification value; with also discarded final raw text. The earlier fake entry owner preserved callback values and therefore missed the join. Lab diagnostic 83814 terminal failed 94.554 s with genuine canonical target 1/11 assertions at report /Users/mc/Ps/ace/ace-assign/.ace-local/test/reports/assign/34b96c9d-5861-409b-b9f1-50e78e312ce4. Source inspection confirms the exact return loss.

Executed in isolated codex/assign-producer-join (base c876271bb):

- bin/ace-test ace-runtime molecules test/molecules/protected_task_context_entry_test.rb: PASS 7 tests / 25 assertions, 22.72 ms; receipt 24aa3edb-fa48-406e-a468-a37eed3438f5. Callback results include nil/false/object identity; existing post-callback tamper refusal and descriptor closure remain covered.
- bin/ace-test ace-bundle molecules test/molecules/protected_task_context_test.rb: PASS 8 / 432, 43.11 ms; receipt 5254cc27-861e-4642-b0b4-50af1ce11916. New composed regression uses actual Runtime held descriptors and protected entry, with only filesystem protection and child execution injected; exact Bundle raw text returns, while mutation after child response refuses and all handed-off descriptors close.

Initial Bundle regression f77fabec-3104-4a0f-956a-ce0c92f5a219 failed 8 / 414 with one error: fixture artifacts shared /tmp ancestry with Bundle's own private-selector directory creation. Corrected fixture artifact location to package .ace-local, preserving every ancestor check; no production retry or relaxation.

No native/provider/installed probe. Root independent source review and actual Lab composed rerun against reviewed integration remain required. No whole qk0.3/Lab closure.

Root independent source review APPROVE (2026-10-07), exact current five-path scope: outer and entry callback values return only after unchanged post-verification; nil/false identity and real Runtime→Bundle held-artifact/tamper cases covered by combined 15 tests / 457 assertions. No protection relaxation. Source-only verdict, not whole producer or installed acceptance.
