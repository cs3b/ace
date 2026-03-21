---
doc-type: template
title: Goal {N} - {Goal Title}
purpose: Documentation for ace-test-runner-e2e/handbook/templates/tc-file.template.md
ace-docs:
  last-updated: 2026-02-25
  last-checked: 2026-03-21
---

# Goal {N} - {Goal Title}

## Goal

{Outcome to achieve}

## Workspace

- Working directory: {sandbox-root}
- Output directory: `results/tc/{NN}/`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions)
- Keep artifacts under `results/tc/{NN}/`
- Do not write outside sandbox
- Execute actions only; do not assign PASS/FAIL in runner file

<!--
Companion verifier file (`TC-{NNN}-{slug}.verify.md`) example:

# Goal {N} - {Goal Title}

## Expectations

- Impact Checks:
  - {Sandbox/project impact expectation}
- Artifact Checks:
  - {Artifact expectation}
- Debug Fallback:
  - {Optional stdout/stderr/exit evidence when needed}

## Verdict

- Pass when impact and artifact checks are satisfied from sandbox evidence.
-->
