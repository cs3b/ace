# E2E Decision Record - TS-TASK-002 Auxiliary CLI Journeys

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 status dashboard real state | KEEP | Validates operator-visible dashboard output against real task state transitions in one sandbox run. | `test/fast/commands/status_command_test.rb` |
| TC-002 plan path cache refresh | KEEP | Confirms public path-mode plan flow and refresh behavior with real plan artifact paths. | `test/fast/commands/plan_test.rb` |
