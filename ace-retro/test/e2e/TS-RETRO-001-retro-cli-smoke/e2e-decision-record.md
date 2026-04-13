# E2E Decision Record - TS-RETRO-001 CLI Smoke (Migration)

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help and usage surface | KEEP | Retain packaged CLI invocation and command wiring (`ace-retro --help`, process exit semantics) as real executable-path coverage. | `test/fast/commands/retro_cli_test.rb` |
| TC-002 create/list/show lifecycle | KEEP | Retain cross-command state continuity and persisted retro files across separate CLI calls and shell parsing boundaries. | `test/fast/commands/retro_cli_test.rb`, `test/fast/molecules/retro_creator_test.rb`, `test/fast/molecules/retro_scanner_test.rb` |
| TC-003 folder and filter views | KEEP | Retain real `_archive` folder placement and list filtering checks in a single operator workflow. | `test/fast/commands/retro_cli_test.rb`, `test/fast/molecules/retro_scanner_test.rb` |
| TC-004 doctor health to failure transition | KEEP | Retain file-corruption and repeated CLI health-check transition in full CLI context. | `test/fast/commands/retro_cli_test.rb`, `test/fast/organisms/retro_doctor_test.rb` |
| Candidate: create dry-run output formatting details | REMOVE | Formatting/no-write details are deterministic and remain covered by command-level tests; no additional E2E expansion required. | `test/fast/commands/retro_cli_test.rb` |
| Candidate: every list filter combination matrix | REMOVE | Combinatorial filter matrix remains deterministic fast-test scope; smoke E2E keeps representative workflow paths only. | `test/fast/commands/retro_cli_test.rb`, `test/fast/molecules/retro_scanner_test.rb` |
