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
- Outcome artifacts only: `results/tc/{NN}/`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions)
- Keep only product outcomes or essential command captures under `results/tc/{NN}/`
- Do not write helper inputs, reflections, manifests, or temp files under `results/tc/{NN}/`
- Do not write outside sandbox
- Execute actions only; do not assign PASS/FAIL in runner file
- Follow the public user path from docs/usage/`--help`; do not embed hidden recipes or workaround branches in the TC

<!--
Companion verifier file (`TC-{NNN}-{slug}.verify.md`) example:

# Goal {N} - {Goal Title}

## Expectations

- Impact Checks:
  - {Sandbox/project impact expectation}
- Artifact Checks:
  - {Outcome artifact expectation}
- Runner Observations:
  - {How final runner observations help disambiguate the result when state alone is not enough, and record friction/workaround pressure if present}
- Debug Fallback:
  - {Optional stdout/stderr/exit evidence when needed}

## Verdict

- Pass when impact and artifact checks are satisfied from sandbox evidence.
-->
