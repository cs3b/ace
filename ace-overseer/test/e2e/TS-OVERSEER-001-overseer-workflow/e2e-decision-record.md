# E2E Decision Record - TS-OVERSEER-001 Overseer Workflow

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help survey | KEEP | Validates real packaged CLI help output and command discoverability from binary execution. | `test/fast/commands/cli_test.rb` |
| TC-002 work-on | KEEP | Requires real worktree + tmux + assignment orchestration side effects that are not fully representable in isolated unit assertions. | `test/fast/organisms/work_on_orchestrator_test.rb`, `test/fast/molecules/assignment_launcher_test.rb` |
| TC-003 idempotent rerun | KEEP | Confirms end-to-end rerun behavior against real repo/tmux/assignment state transitions, not just method-level stubs. | `test/fast/organisms/work_on_orchestrator_test.rb`, `test/fast/molecules/worktree_provisioner_test.rb` |
| TC-004 preset override | KEEP | Ensures CLI/user-facing preset resolution works through the full invocation path and persisted environment context. | `test/fast/atoms/preset_resolver_test.rb`, `test/fast/commands/work_on_command_test.rb` |
| TC-005 prune workflow | KEEP | Exercises prune safety in real worktree/task/assignment states and verifies safe-removal behavior with filesystem impact. | `test/fast/organisms/prune_orchestrator_test.rb`, `test/fast/molecules/assignment_prune_safety_checker_test.rb`, `test/fast/molecules/prune_safety_checker_test.rb` |
| Candidate: duplicate deterministic formatter/detail assertions in scenario checks | SKIP | Formatter and model-level value assertions belong in deterministic fast tests; scenario scope remains workflow-level orchestration. | `test/fast/atoms/status_formatter_test.rb`, `test/fast/models/prune_candidate_test.rb` |
