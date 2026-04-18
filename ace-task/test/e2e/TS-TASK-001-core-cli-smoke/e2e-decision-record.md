# E2E Decision Record - TS-TASK-001 Core CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help survey | KEEP | Validates packaged CLI command registration/help surface from real binary invocation. | `test/fast/commands/create_test.rb`, `test/fast/commands/doctor_test.rb` |
| TC-002 create/show/list lifecycle | KEEP | Confirms cross-command state continuity and persisted `.ace-tasks` artifacts across separate CLI calls. | `test/fast/commands/create_test.rb` |
| TC-003 update and archive movement | KEEP | Verifies end-to-end move-to-archive behavior with real file relocation under `.ace-tasks/_archive`. | `test/fast/commands/update_test.rb` |
| TC-004 doctor health/error split | KEEP | Validates command-level health scoring transition from healthy to broken filesystem state in one sandbox run. | `test/fast/commands/doctor_test.rb` |
| Candidate: plan cache refresh/content matrix | MOVE | Moved to `TS-TASK-002/TC-002` with path-mode-only assertions to keep smoke scope focused while retaining public-surface E2E coverage. | `test/fast/commands/plan_test.rb` |
| Candidate: create dry-run formatting | SKIP | Output formatting and no-write behavior are already covered by fast command tests and does not require broader sandbox orchestration. | `test/fast/commands/create_test.rb` |
