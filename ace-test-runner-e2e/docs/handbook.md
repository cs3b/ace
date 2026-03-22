---
doc-type: user
title: Ace::Test::EndToEndRunner Handbook Reference
purpose: Package-local skills, workflows, and source map for ace-test-runner-e2e
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Ace::Test::EndToEndRunner Handbook Reference

## Skills and workflows

| Skill | What it does |
| --- | --- |
| `as-e2e-run` | Run one scenario or package-level E2E scope |
| `as-e2e-create` | Create a new TS-format E2E scenario |
| `as-e2e-review` | Review E2E coverage quality and scenario fidelity |
| `as-e2e-plan-changes` | Plan scenario updates from review output |
| `as-e2e-rewrite` | Rewrite scenario files according to change plan |
| `as-e2e-fix` | Diagnose and repair failing E2E scenarios |
| `as-e2e-manage` | Orchestrate review -> plan -> rewrite lifecycle |
| `as-e2e-setup-sandbox` | Prepare and validate E2E sandbox environment |

## Workflow protocols

| Protocol | Purpose |
| --- | --- |
| `wfi://e2e/run` | Run E2E scenarios for a package or test ID |
| `wfi://e2e/create` | Scaffold and author new TS scenarios |
| `wfi://e2e/review` | Produce structured E2E review findings |
| `wfi://e2e/plan-changes` | Convert findings into executable change plan |
| `wfi://e2e/rewrite` | Apply change plan to scenario/test files |
| `wfi://e2e/fix` | Triage and fix failing E2E tests |
| `wfi://e2e/manage` | Coordinate review/plan/rewrite pipeline |
| `wfi://e2e/setup-sandbox` | Standardized sandbox preparation |
| `wfi://e2e/execute` | Execute prepared scenarios in existing sandbox contexts |
| `wfi://e2e/analyze-failures` | Analyze recurring failure surfaces and patterns |

## Source paths

- `lib/ace/test/end_to_end_runner/cli/commands/run_test.rb` (runtime and CLI)
- `lib/ace/test/end_to_end_runner/cli/commands/run_suite.rb` (runtime and CLI)
- `lib/ace/test/end_to_end_runner/organisms/test_orchestrator.rb` (core orchestration)
- `lib/ace/test/end_to_end_runner/organisms/suite_orchestrator.rb` (core orchestration)
- `lib/ace/test/end_to_end_runner/molecules/test_discoverer.rb` (discovery and loading)
- `lib/ace/test/end_to_end_runner/molecules/scenario_loader.rb` (discovery and loading)
- `.ace-defaults/e2e-runner/config.yml` (package defaults)
- `docs/getting-started.md` (tutorial)
- `docs/usage.md` (CLI reference)
- `docs/handbook.md` (handbook index)
