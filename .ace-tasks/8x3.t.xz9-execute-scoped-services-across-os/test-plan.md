# Test responsibility map — protected scoped services

All authority/data-integrity behaviors are high risk. Plan only: no implementation tests were run for this spec change.

| Parent criterion | Child | Layer and proof owner |
|---|---|---|
| SC1 protected cross-user effect | xz9.0 | ace-lab/assign integration; real installed launcher/reviewer/worker/authority/executor UID fixture |
| SC2 invalid authority refusal | xz9.0 | ace-assign unit role/binding validation; real filesystem/socket symlink/ref/config/candidate substitution integration |
| SC3 duplicates and loss | xz9.1 | journal CAS/lifecycle integration; actual concurrent CLI and crash-after-effect E2E |
| SC4 listener and descendants | xz9.1 | protected socket ownership integration and real process group timeout/late-write E2E |
| SC5 same-user/Unix behavior | both | existing ace-lab contract suite plus Linux multi-UID and actual macOS peer smoke; independent review |

Unit: immutable fields, authorization reuse, role grants, fixed root mapping and redaction; bounded artifacts/config parsing. Integration: real canonical Git ref/CAS and protected evidence ancestry; do not mock UID/stat/lstat/peer credentials for boundary acceptance. Mock external fixture handler outcome only in unit classification; installed fixture must actually write one harmless protected effect. E2E: terminalization-before-claim, revoke-before-dispatch, worker mutable HEAD after review, all crash windows, same ID conflicting input, second authority/listener startup and noisy/stuck descendant output. Restore current source fixture after each crash; never treat worker cache as authority. Failure evidence includes no effect count and unchanged accepted journal state.

Record source SHA, exact commands, real UIDs, protected roots/ownership, approved candidate/generation/reviewer and qjl receipt digest. `bin/ace-test --help` selects affected package/layer commands at implementation; run `bin/ace-test-suite` default fast suite then installed multi-user scenario. gad.8/gad.b separately prove real installation/domain services; generic fixture does not close them. No broadened retention/16h policy.
