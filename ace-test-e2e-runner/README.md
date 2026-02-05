# ace-test-e2e-runner

End-to-end test runner infrastructure for agent-executed testing.

## Core Principles

- **Workflow-First**: Agents can follow workflow instructions or use the CLI
- **Transparent**: Test scenarios are readable markdown with clear steps
- **Reproducible**: Documented setup, execution, and cleanup for consistent results
- **Package-Local**: Test scenarios stored with the code they test

## Architecture

This package provides both workflow infrastructure and CLI commands:

```
handbook/
├── workflow-instructions/   # How to execute tests
├── templates/               # Test scenario templates
└── guides/                  # Convention documentation
```

Tests themselves live in individual packages: `{package}/test/e2e/*.mt.md`

## Overview

This package provides the "HOW" for end-to-end testing and a CLI runner for tests that are:

- **NOT run by regular test runner** (`ace-test`)
- **Executed by an AI agent** who sets up environment and runs tests
- **Very slow** and excluded from regular test suite
- **Documented as workflow instructions** for reproducibility

## Structure

```
ace-test-e2e-runner/
├── .ace-defaults/
│   └── e2e-runner/
│       └── config.yml           # Default configuration
├── handbook/
│   ├── workflow-instructions/
│   │   └── run-e2e-test.wf.md    # How to execute an E2E test
│   ├── templates/
│   │   └── test-e2e.template.md      # Template for new test scenarios
│   └── guides/
│       └── e2e-testing.g.md          # Convention documentation
└── lib/
    └── ace/test/end_to_end_runner/
        └── version.rb
```

## Convention

Test scenarios are stored in individual packages:

```
{package}/test/e2e/*.mt.md
```

For example:
- `ace-lint/test/e2e/MT-LINT-001-ruby-validator-fallback.mt.md`
- `ace-review/test/e2e/MT-REVIEW-001-pr-analysis.mt.md`

## Usage

### Running an E2E Test (CLI)

```bash
ace-e2e-test <package> [test-id]
```

Example:
```bash
ace-e2e-test ace-lint MT-LINT-001
```

### Running an E2E Test (Workflow)

```
/ace:run-e2e-test <package> <test-id>
```

Example:
```
/ace:run-e2e-test ace-lint MT-LINT-001
```

### Creating a New Test Scenario

Use the template:
```
ace-bundle tmpl://test-e2e
```

### Discovery

Find all E2E tests in a package:
```bash
find {package}/test/e2e -name "*.mt.md"
```

## Test ID Format

Test IDs follow the pattern: `MT-{AREA}-{NNN}`

- `MT` - Test prefix (legacy: "Manual Test")
- `{AREA}` - Area code (e.g., LINT, REVIEW, BUILD)
- `{NNN}` - Sequential number

## License

MIT
