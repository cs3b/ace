# E2E Decision Record - TS-TASK-001 Core CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help survey | ADD | Validates packaged CLI command registration/help surface from real binary invocation. | `test/commands/create_test.rb`, `test/commands/doctor_test.rb` |
| TC-002 create/show/list lifecycle | ADD | Confirms cross-command state continuity and persisted `.ace-tasks` artifacts across separate CLI calls. | `test/commands/create_test.rb` |
| TC-003 update and archive movement | ADD | Verifies end-to-end move-to-archive behavior with real file relocation under `.ace-tasks/_archive`. | `test/commands/update_test.rb` |
| TC-004 doctor health/error split | ADD | Validates command-level health scoring transition from healthy to broken filesystem state in one sandbox run. | `test/commands/doctor_test.rb` |
| Candidate: plan cache refresh/content matrix | SKIP | Unit tests already cover refresh/content/model override logic; E2E would require LLM backend and adds cost without new CLI/filesystem risk coverage for this smoke scope. | `test/commands/plan_test.rb` |
| Candidate: create dry-run formatting | SKIP | Output formatting and no-write behavior are already covered by command tests and does not require broader sandbox orchestration. | `test/commands/create_test.rb` |
