# ace-test-e2e-runner

End-to-end test runner infrastructure for agent-executed testing.

## Core Principles

- **Transparent**: Test scenarios are readable markdown with clear steps
- **Reproducible**: Documented setup, execution, and cleanup for consistent results
- **Package-Local**: Test scenarios stored with the code they test
- **Dual-Format**: Supports both MT-format (single file) and TS-format (per-TC directory)

## Architecture

Full ATOM architecture with CLI, models, and workflow instructions:

```
lib/ace/test/end_to_end_runner/
├── atoms/          # Parsers, prompt builders, display helpers
├── molecules/      # Orchestration components (executor, loader, config, setup)
├── organisms/      # TestOrchestrator, SuiteOrchestrator
├── models/         # TestScenario, TestCase, TestResult
└── cli/            # CLI commands (run_test, run_suite, setup)
```

## Overview

This package provides the "HOW" for end-to-end testing - workflows, templates, and conventions for tests that are:

- **NOT run by regular test runner** (`ace-test`)
- **Executed by an AI agent** who sets up environment and runs tests
- **Very slow** and excluded from regular test suite
- **Documented as workflow instructions** for reproducibility

## Structure

```
ace-test-e2e-runner/
├── .ace-defaults/
│   └── e2e-runner/
│       └── config.yml                          # Default configuration
├── exe/
│   ├── ace-test-e2e                            # Main CLI entry point
│   ├── ace-test-e2e-sh                         # Sandbox command executor
│   └── ace-test-suite-e2e                      # Suite runner
├── handbook/
│   ├── workflow-instructions/
│   │   ├── run-e2e-test.wf.md                  # Full test workflow (locate, setup, execute)
│   │   ├── execute-e2e-test.wf.md              # Focused execution (pre-populated sandbox)
│   │   ├── run-e2e-tests.wf.md                 # Parallel multi-test orchestrator
│   │   ├── setup-e2e-sandbox.wf.md             # Sandbox pre-setup workflow
│   │   ├── create-e2e-test.wf.md               # New test creation
│   │   ├── manage-e2e-tests.wf.md              # Test management
│   │   └── review-e2e-tests.wf.md              # Test review
│   ├── templates/
│   │   ├── test-e2e.template.md                # Template for new test scenarios
│   │   ├── test-report.template.md             # Pass/fail results template
│   │   ├── metadata.template.yml               # Run context template
│   │   ├── agent-experience-report.template.md # Friction/learnings template
│   │   └── ace-taskflow-fixture.template.md    # Task fixture template
│   ├── skills/
│   │   ├── ace_run-e2e-test/SKILL.md           # Single test skill
│   │   └── ace_run-e2e-tests/SKILL.md          # Multi-test parallel skill
│   └── guides/
│       └── e2e-testing.g.md                    # Convention documentation
└── lib/
    └── ace/test/end_to_end_runner/
        ├── atoms/          # 7 components
        ├── molecules/      # 15 components
        ├── organisms/      # 2 orchestrators
        ├── models/         # 3 models
        └── cli/            # 3 commands
```

## Convention

Test scenarios are stored in individual packages in two formats:

### MT-Format (Single File)

```
{package}/test/e2e/MT-{AREA}-{NNN}-{slug}.mt.md
```

Examples:
- `ace-review/test/e2e/MT-REVIEW-001-pr-analysis.mt.md`
- `ace-git-commit/test/e2e/MT-COMMIT-001-basic-commit.mt.md`

### TS-Format (Per-TC Directory)

```
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
    scenario.yml                              # Metadata + setup config
    TC-NNN-{slug}.tc.md                       # Individual test cases
    fixtures/                                 # Shared test fixtures
```

Examples:
- `ace-lint/test/e2e/TS-LINT-001-ruby-validator-fallback/`
- `ace-lint/test/e2e/TS-LINT-002-json-report-generation/`

## Test ID Format

- `MT-{AREA}-{NNN}` — Single-file format (e.g., `MT-LINT-001`)
- `TS-{AREA}-{NNN}` — Per-TC directory format (e.g., `TS-LINT-001`)

Where:
- `{AREA}` — Area code (uppercase, e.g., LINT, REVIEW, BUILD)
- `{NNN}` — Three-digit sequential number

## Usage

### Running a Single E2E Test

```
/ace:run-e2e-test <package> <test-id>
```

Example:
```
/ace:run-e2e-test ace-lint MT-LINT-001
```

### Running with Test Case Filtering

```
/ace:run-e2e-test <package> <test-id> TC-001,TC-003
```

### Running with Pre-Populated Sandbox

When the sandbox is already set up (via Ruby `SetupExecutor`):

```
/ace:run-e2e-test <package> <test-id> --sandbox <path> --run-id <id>
```

### Running Multiple Tests (Parallel)

```
/ace:run-e2e-tests <package>
/ace:run-e2e-tests <package> --sequential
/ace:run-e2e-tests --all
```

### Setup Only (No Execution)

```
ace-test-e2e setup <package> <test-id>
```

### Creating a New Test Scenario

Use the template:
```
ace-bundle tmpl://test-e2e
```

### Discovery

Find all E2E tests in a package:
```bash
find {package}/test/e2e -name "*.mt.md" -o -name "scenario.yml"
```

## License

MIT
