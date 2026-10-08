---
doc-type: workflow
title: Create an attempt-bound draft pull request
purpose: Create or reconcile a forge-neutral draft for the exact candidate
---

# Create an attempt-bound draft pull request

## Goal

Create one draft PR on the selected forge and retain its exact source/base identity in the assignment attempt journal.

## Prerequisites

A reviewed task, managed assignment, active delivery attempt, committed candidate, and pushed source ref. Credentials permit transport only; they grant no integration authority.

## Inputs

Use `forge_server` or `forge_default: true`, mutually exclusive. Neither means resolve this repository's configured remote. Provide `pr_provenance` containing `mode` (`fork` or `canonical`), `head_repository_url`, `head_ref`, `base_repository_url`, and `base_ref`. Canonical repositories must match; fork mode explicitly names its source even when owners coincide. Inputs contain no credentials.

```json
{"forge_server":"forge-lab","pr_provenance":{"mode":"canonical","head_repository_url":"https://forge.example/team/repo","head_ref":"feature","base_repository_url":"https://forge.example/team/repo","base_ref":"main"}}
```

## Protected worker boundary

The steps below are ordinary managed delivery only. An installed protected
participant cannot use caller-local delivery or direct provider commands as a
fallback. Protected create/update/ready authorization ordering remains unresolved;
report the exact policy/capability blocker without performing those effects.
For an already selected reviewed PR, use the protected merge/status section of
`wfi://handbook/perform-delivery`: the original worker requests the configured
receiver with full original selectors and consumes only its canonical completed
result. Local test/review reference files cannot authorize that protected route.
Credentials, charter selection and a service acknowledgement do not prove merge.

## Steps

1. Read the task and actual committed diff; prepare a concrete title and description explaining behavior and executed validation. Save the description as a local file.
2. Use the existing managed assignment and active delivery attempt IDs. If needed, start the delivery step with `ace-assign attempt start --assignment ID --step STEP --project PROJECT` (numeric step scope). The execution boundary supplies actor identity; do not impersonate a reviewer or integrator.
3. Supply the assignment source's `delivery` mapping, or save the explicit input JSON and pass `--parameters FILE`. For task-mode creation, `ace-assign create --task TASK --delivery-parameters FILE` retains these inputs in the generated job.
4. Execute `ace-assign delivery --assignment ID --attempt ATTEMPT --operation create --title TITLE --body-file DESCRIPTION`. Add `--parameters FILE` only when supplying an explicit file. In this repository invoke the source `bin/ace-assign` entrypoint.
5. Read the structured result. Verify the retained server/provider/base and head repository/ref, draft PR number/URL, candidate SHA, base_head, evidence_git_ref, and separate journal_commit. The pushed ref must equal the candidate; journal commits never advance it.
6. On interruption or unknown create outcome, repeat the delivery command to perform exact-selector reconciliation reads. One matching draft at the exact head is adopted without a second create. Zero remains unresolved; multiple matches conflict. Never bypass uncertainty with a direct provider command.

## Success criteria

The journal records exact identity, intent before the write, and proven draft outcome afterward. A report or shell exit alone proves nothing. Continue with actual tests and independent current-head review; keep the PR draft until those receipts are accepted. CI is visible and advisory. Publication is a separate authorized operation and is not required for delivery.
