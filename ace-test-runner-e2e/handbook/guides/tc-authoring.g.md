---
guide-id: g-tc-authoring
title: Test Case Authoring Guide
description: Guide for writing standalone TC runner/verifier files for TS-format E2E scenarios
version: "2.0"
source: ace-test-runner-e2e
---

# Test Case Authoring Guide

## Overview

TC (Test Case) files are the individual execution units in TS-format E2E scenarios.

Only one authoring format is supported:
- Standalone runner/verifier pairs:
  - `TC-*.runner.md`
  - `TC-*.verify.md`

Inline `.tc.md` and frontmatter `mode` values are no longer supported.

## Canonical Conventions

- Scenario IDs: `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Standalone pair files:
  - `TC-{NNN}-{slug}.runner.md`
  - `TC-{NNN}-{slug}.verify.md`
- Scenario-level config files:
  - `runner.yml.md`
  - `verifier.yml.md`
- TC artifacts write to `results/tc/{NN}/`
- Summary counters use `tcs-passed`, `tcs-failed`, and `tcs-total`

## File Naming

- `TC-{NNN}` — test case number (e.g., TC-001)
- `{slug}` — descriptive kebab-case identifier

Examples:
- `TC-001-help-survey.runner.md`
- `TC-001-help-survey.verify.md`
- `TC-002-error-handling.runner.md`
- `TC-002-error-handling.verify.md`

## Location

TC files are placed in the scenario directory alongside `scenario.yml`:

```text
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
├── scenario.yml
├── runner.yml.md
├── verifier.yml.md
├── TC-001-{slug}.runner.md
├── TC-001-{slug}.verify.md
└── fixtures/
```

## Runner File Structure (`TC-*.runner.md`)

Required sections:
- `# Goal N - Title`
- `## Goal`
- `## Workspace`
- `## Constraints`

Example:

```markdown
# Goal 1 - Generate report

## Goal

Run `ace-lint` and produce report artifacts for a valid file.

## Workspace

- Root: sandbox directory
- Output: `results/tc/01/`

## Constraints

- Use only sandbox paths
- Keep evidence under `results/tc/01/`
```

## Verifier File Structure (`TC-*.verify.md`)

Required sections:
- `# Goal N - Title`
- `## Expectations`
- `## Verdict`

Example:

```markdown
# Goal 1 - Generate report

## Expectations

- `results/tc/01/report.json` exists
- report indicates pass status

## Verdict

Pass only when all expectations are satisfied by on-disk evidence.
```

## Scenario-Level Configuration

- `tags` in `scenario.yml` control discovery-time filtering via `--tags`/`--exclude-tags`. Tags are not set per-TC; they apply to the entire scenario.
- `runner.yml.md` bundles execution context for the runner agent (tool paths, sandbox conventions, environment setup).
- `verifier.yml.md` bundles validation criteria for the independent verifier agent (artifact expectations, verdict rules).
- TCs execute sequentially within a scenario. The runner agent accumulates context across TCs (e.g., files created in TC-001 are available in TC-002).

## Best Practices

- Keep each TC focused on one coherent behavior path.
- Ensure goal numbers and TC numbers remain aligned (`TC-001` -> Goal 1).
- Make verifier expectations evidence-based and deterministic.
- Keep all artifacts under `results/tc/{NN}/` to avoid cross-goal contamination.
- Record why each scenario remains E2E via `e2e-justification` and `unit-coverage-reviewed` in `scenario.yml`.

## Related

- [scenario.yml Reference](scenario-yml-reference.g.md)
- [E2E Testing Guide](e2e-testing.g.md)
