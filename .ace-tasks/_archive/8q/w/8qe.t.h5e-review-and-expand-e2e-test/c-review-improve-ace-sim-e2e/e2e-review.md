## E2E Coverage Review: ace-sim
**Reviewed:** 2026-03-20T23:15:49Z  
**Scope:** package-wide  
**Workflow version:** 2.1

### Summary
| Metric | Count |
|--------|-------|
| Package features | 6 |
| Unit test files | 7 |
| Unit assertions (command-surface subset) | 110 |
| E2E scenarios | 1 |
| E2E test cases | 4 |
| TCs with decision evidence | 4/4 |

### Feature Inventory
| Feature | Command | External Tools | Description |
|--------|---------|----------------|-------------|
| CLI discovery/help surface | `ace-sim --help`, `ace-sim run --help` | none | Exposes run command and preset/simulation flags |
| Default preset run contract (`validate-idea`) | `ace-sim run --preset validate-idea ...` | `ace-bundle`, `ace-llm` | Executes draft/plan/work chain and records artifacts |
| Explicit CLI override behavior | `ace-sim run ... --steps draft --synthesis-*` | `ace-bundle`, `ace-llm` | CLI overrides preset defaults for step/synthesis options |
| Full-chain synthesis aggregation | `ace-sim run ... --synthesis-workflow wfi://task/review` | `ace-bundle`, `ace-llm` | Aggregates draft/plan/work outputs into final synthesis input/output |
| Alternate shipped preset path (`validate-task`) | `ace-sim run --preset validate-task ...` | `ace-bundle`, `ace-llm` | Plan/work-oriented preset behavior and synthesis defaults |
| Input validation guard | `ace-sim run --synthesis-provider ...` (without workflow) | none | Rejects invalid synthesis option combinations deterministically |

### Coverage Matrix
| Feature | Unit Tests | E2E Tests | Status |
|--------|------------|-----------|--------|
| CLI discovery/help surface | `test/commands/cli_test.rb`, `test/commands/run_command_test.rb` | `TC-001-help-survey` | Covered |
| Default preset run contract (`validate-idea`) | `test/commands/run_command_test.rb`, `test/organisms/simulation_runner_test.rb` | `TC-002-preset-contract` | Covered |
| Explicit CLI override behavior | `test/commands/run_command_test.rb` | `TC-003-run-chain-artifacts` | Covered |
| Full-chain synthesis aggregation | `test/molecules/final_synthesis_executor_test.rb`, `test/organisms/simulation_runner_test.rb` | `TC-004-full-chain-synthesis` | Covered |
| Alternate shipped preset path (`validate-task`) | `test/commands/run_command_test.rb` | none | Unit-only |
| Input validation guard (`synthesis_provider` requires workflow) | `test/commands/run_command_test.rb`, `test/models/simulation_session_test.rb` | none | Unit-only |

### Overlap Analysis
TCs with overlap against unit tests still have E2E value because they validate real CLI execution, artifact materialization, and chain wiring.

| TC ID | Feature | Overlapping Unit Tests | Recommendation |
|------|---------|------------------------|----------------|
| TC-001 | help survey | `test/commands/cli_test.rb` | Keep — validates live binary help surface |
| TC-002 | default preset run | `test/commands/run_command_test.rb`, `test/organisms/simulation_runner_test.rb` | Keep — validates real run directory and file contract |
| TC-003 | CLI override behavior | `test/commands/run_command_test.rb` | Modify — tighten deterministic one-step assertions |
| TC-004 | full-chain synthesis | `test/organisms/simulation_runner_test.rb` | Keep — validates end-to-end aggregation and recorded final-stage outcome |

**Candidates for removal:** 0

### E2E Decision Record Coverage
| TC ID | Evidence Status | Missing Fields |
|------|------------------|----------------|
| TS-SIM-001 | complete | none |

### Gap Analysis
| Feature | External Tools | Unit Coverage | E2E Needed? |
|--------|----------------|---------------|-------------|
| `validate-task` preset contract under real run | `ace-bundle`, `ace-llm` | yes | yes — validates shipped preset wiring and run artifacts through CLI |
| invalid synthesis option pairing rejection | none | yes | yes — low-cost deterministic CLI validation path in real invocation |

### Health Status
| TC ID | Last Verified | Status |
|------|---------------|--------|
| TC-001 | not recorded | Never verified |
| TC-002 | not recorded | Never verified |
| TC-003 | not recorded | Never verified |
| TC-004 | not recorded | Never verified |

**Outdated (>30 days):** 0  
**Never verified:** 4

### Consolidation Opportunities
No immediate consolidation needed; current split is clear and keeps diagnostics local.

### Recommendations
1. Add one TC for `validate-task` preset behavior to cover the second shipped preset path.
2. Add one deterministic validation TC for `synthesis_provider` without `synthesis_workflow`.
3. Tighten TC-001 and TC-003 verification assertions to reduce ambiguity and regressions.

### Next Step
Run Stage 2 planning to produce a concrete KEEP/MODIFY/REMOVE/CONSOLIDATE/ADD change plan.
