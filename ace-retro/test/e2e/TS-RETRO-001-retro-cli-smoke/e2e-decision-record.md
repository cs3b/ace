# E2E Decision Record - TS-RETRO-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help and usage surface | ADD | Verifies packaged CLI invocation and command wiring (`ace-retro --help`, process exit semantics) in real executable context. | `test/commands/retro_cli_test.rb` |
| TC-002 create/list/show lifecycle | ADD | Confirms cross-command state continuity and persisted retro files across separate CLI calls and shell parsing boundaries. | `test/commands/retro_cli_test.rb`, `test/molecules/retro_creator_test.rb`, `test/molecules/retro_scanner_test.rb` |
| TC-003 folder and filter views | ADD | Validates real `_archive` folder placement and list filtering against actual on-disk retros in one sandbox workflow. | `test/commands/retro_cli_test.rb`, `test/molecules/retro_scanner_test.rb` |
| TC-004 doctor health to failure transition | ADD | Requires real file corruption and repeated CLI health checks to validate operator-visible transition from healthy to failing state. | `test/commands/retro_cli_test.rb`, `test/organisms/retro_doctor_test.rb` |
| Candidate: create dry-run output formatting details | SKIP | Formatting/no-write details are already strongly covered by command-level tests and do not require separate E2E smoke cost. | `test/commands/retro_cli_test.rb` |
| Candidate: every list filter combination matrix | SKIP | Full combinatorial filter matrix is unit/command-test territory; smoke E2E keeps one representative per high-value path. | `test/commands/retro_cli_test.rb`, `test/molecules/retro_scanner_test.rb` |
