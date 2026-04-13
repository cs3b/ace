# E2E Decision Record - TS-DEMO-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help and command surface | ADD | Validates packaged executable wiring and command registry exposure through real `ace-demo --help` process execution. | `test/fast/commands/cli_test.rb` |
| TC-002 create/show tape lifecycle | ADD | Requires real filesystem writes and cross-command continuity (`create` then `show`) in a sandbox repo. | `test/fast/commands/create_test.rb`, `test/fast/molecules/tape_scanner_test.rb`, `test/fast/organisms/tape_creator_test.rb` |
| TC-003 inline record dry-run preview | ADD | Confirms CLI-level dry-run output contract for inline mode and attach preview messaging in real command invocation context. | `test/fast/commands/cli_test.rb`, `test/fast/organisms/demo_recorder_test.rb`, `test/fast/molecules/inline_recorder_test.rb` |
| TC-004 attach missing --pr error | ADD | Verifies end-user exit code and validation message path from command invocation (operator-visible failure semantics). | `test/fast/commands/cli_test.rb` |
| Candidate: all supported output formats for every command | SKIP | Format matrix coverage is already strongly exercised in unit/command tests; smoke E2E keeps one representative path. | `test/fast/commands/cli_test.rb`, `test/fast/commands/retime_test.rb` |
| Candidate: tape content generator formatting details | SKIP | Line-by-line tape formatting fidelity belongs to atom/molecule-level tests, not smoke E2E. | `test/fast/atoms/tape_content_generator_test.rb`, `test/fast/organisms/tape_creator_test.rb` |
