---
doc-type: guide
title: Test Case Authoring Guide
purpose: Guide for writing standalone TC runner/verifier files for TS-format E2E scenarios
ace-docs:
  last-updated: 2026-02-25
  last-checked: 2026-03-21
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
- TC outcome artifacts write to `results/tc/{NN}/`
- Summary counters use `tcs-passed`, `tcs-failed`, and `tcs-total`

## TC Styles

- **Public-surface**: prove a documented user job from docs/usage/`--help` and the CLI.
- **Retained-contract**: pin an integrated behavior with deterministic, explicitly declared supporting evidence when end-state checks alone are insufficient.

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
- Outcome artifacts: `results/tc/01/`

## Constraints

- Use only sandbox paths
- Keep only declared verifier-dependent evidence under `results/tc/01/`
- Declare exact paths for any verifier-dependent captures, for example ``results/tc/01/help.stdout`, `.stderr`, `.exit``
- Do not place helper inputs, manifests, PASS/FAIL summaries, or reflections under `results/tc/01/`
- Execute actions only; do not assign PASS/FAIL or final verdicts
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

- **Impact Checks**: target sandbox/project state changed as expected
- **Artifact Checks**: `results/tc/01/report.json` exists and is valid
- **Runner Observations**: use harness-provided end-of-run observations only as supporting context
- **Debug Fallback**: inspect `stdout`/`stderr`/`*.exit` only when primary checks are inconclusive

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
- Choose the TC style up front: `public-surface` or `retained-contract`.
- Keep runner files execution-only and verifier files verdict-only.
- Make verifier expectations deterministic with impact-first ordering.
- Keep `results/tc/{NN}/` for declared verifier-dependent evidence only.
- Declare every verifier-dependent path in the runner or setup. Do not rely on verifier-only references.
- Grouped capture shorthand is valid only for exact sibling files, for example ``foo.stdout`, `.stderr`, `.exit``.
- Do not use wildcard artifact paths.
- Use harness-provided runner observations as the only non-filesystem secondary evidence source.
- Prefer final sandbox state and real product output over raw debug captures.
- Do not ask the runner to write setup inputs, audit manifests, verifier-facing summaries, or final reflections for the verifier.
- Do not teach the runner hidden recipes or workaround sequences; if the path is not discoverable from docs/usage/`--help`, the TC is wrong or the public surface needs improvement.
- Use runner observations to record friction and workaround pressure, not to normalize it.
- For watch/live-output flows, use a bounded-session pattern with explicit shutdown and captured exit code.
- Record why each scenario remains E2E via `e2e-justification` and `unit-coverage-reviewed` in `scenario.yml`.

## Related

- [scenario.yml Reference](scenario-yml-reference.g.md)
- [E2E Testing Guide](e2e-testing.g.md)
