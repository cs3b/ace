# TS-MONO-003 / TS-MONO-004 implementation record

These scenarios remain required acceptance, not completed component probes.
Use the existing scenario runner/verifier format under ace-monorepo-e2e.
The runner supplies one bootstrap goal and the existing four Forgejo issues;
it must not create the overseers' tasks, choose assignments, implement changes,
write reviews or merge on their behalf. No GitHub service is involved.

| Scenario / case | Decision | Real-system outcome | Public surface / setup owner | Component coverage reviewed |
| --- | --- | --- | --- | --- |
| 003 / bootstrap | ADD | Worker prepares ACE, independent verifier accepts, project overseer reaches first turn and active eyes | ace-overseer start; lab-vm runtime/forgejo/fixture setup | ace-lab/test/fast/auth/session_configuration_test.rb; ace-herdr/test/fast/molecules/herdr_executor_test.rb |
| 003 / multi-issue delivery | ADD | Base and dependent CLI merge in order, docs merge independently; current-HEAD tests and independent reviews; release remains open | Forgejo fixture issues; ace-task, ace-assign, ace-coworker, native Herdr | ace-lab/test/fast/auth/session_configuration_test.rb; ace-herdr/test/fast/molecules/herdr_executor_test.rb |
| 003 / idle | ADD | After pending notifications drain, 300 seconds of unchanged state produces no additional model turns | Existing observe/eyes and real Pi session transcripts | ace-herdr/test/fast/molecules/herdr_executor_test.rb |
| 004 / duplicate and restart | ADD | Replay report and restart coordinator; original accepted assignment remains unique | Existing report delivery and native session lifecycle | ace-herdr/test/fast/molecules/herdr_executor_test.rb |
| 004 / worker failure, source loss, missing runtime | ADD | Each independently initialized fault gives explicit blocked/retry behavior; no false done or source fallback | VM fixture fault injection; public start/status/observe | ace-lab/test/fast/auth/session_command_test.rb |
| 004 / local HITL | ADD | Exact case is answered locally, accepted once, closed only after applied effect | ace-hitl ask/reply/lifecycle; local operator fixture | ace-lab/test/fast/auth/session_configuration_test.rb |
| 004 / lease expiry and issuer crash | ADD | Real Forgejo token works before expiry and is rejected after cleanup; sessions/commands are contained; no cross-session access | ace-lab auth request/status/exec/revoke; systemd fault injection | ace-lab/test/fast/auth/session_launcher_test.rb |

Primary oracles are project/Forgejo state plus actual task, assignment, review,
lease and model-turn records. Launch/unit existence is not readiness. Each case
must preserve exact source SHA, VM image, manifest digest and artifact hashes;
raw credentials and raw secret-bearing transcripts stay private and must not
enter the report. Shared state remains with existing owners.

Acceptance capture is bounded by a declared scenario deadline. On failure,
stop the test VM and retain/export its diagnostic evidence; do not reset it
silently. Before reset export the previous VM using the existing helper. The
second complete run must use the identical manifest and start with no prior
tasks, sessions, permissions or credentials. A product or manifest change
invalidates earlier complete-run acceptance.

Registration update (2026-11-04): TS-MONO-003 and TS-MONO-004 now have
scenario setup and runner/verifier case files. Public isolated start/dispatch,
project-owner observation and installed issuer convergence are implemented.
003 creates a fresh owned VM and fixture; 004 binds to that same current fixture.
The host-only guest helper supplies inspection/fault control, never agent work.
Case stdout/stderr/exit, actual owner/native state and redacted session records
are declared evidence. Raw sessions/credentials remain private. Bound bootstrap
and issue delivery at45/90minutes; idle is300seconds. Failure stops/preserves the
owned VM after evidence capture. Registration is not acceptance: no clean full
pair has passed yet. The diagnostic96 run proved healthy combined observation
and wake on a local HITL reply, then found a standalone Herdr require defect;
that defect is fixed with a fresh-process regression in source2fbe5cb60.
