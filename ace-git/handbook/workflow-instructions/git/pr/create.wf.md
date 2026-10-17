---
doc-type: workflow
title: Create a draft pull request
purpose: Create or reconcile a forge-neutral draft for the exact candidate
---

# Create a draft pull request

## Goal

Create one draft PR on the selected forge and record its exact source/base identity in the assignment report.

## Prerequisites

A reviewed task or explicit implementation scope, a committed candidate, and a pushed source ref. Credentials permit transport only; they grant no integration permission.

## Inputs

Use `forge_server` or `forge_default: true`, mutually exclusive. Neither means resolve this repository's configured remote. Provide `pr_provenance` containing `mode` (`fork` or `canonical`), `head_repository_url`, `head_ref`, `base_repository_url`, and `base_ref`. Canonical repositories must match; fork mode explicitly names its source even when owners coincide. Inputs contain no credentials.

```json
{"forge_server":"forge-lab","pr_provenance":{"mode":"canonical","head_repository_url":"https://forge.example/team/repo","head_ref":"feature","base_repository_url":"https://forge.example/team/repo","base_ref":"main"}}
```

## Steps

1. Read the task and actual committed diff; prepare a concrete title and description explaining behavior and executed validation. Save the description as a local file.
2. When this work belongs to an assignment, use its actual ID and record the PR identity in the assignment report. The execution boundary supplies actor identity; do not impersonate a reviewer or integrator.
3. Verify the pushed source ref resolves to the candidate SHA. The pushed ref must equal the candidate.
4. Create the draft with the configured forge command; drafts are the default:

   ```sh
   ace-git pr create --server NAME --head HEAD-REF --head-repo HEAD-REPOSITORY-URL --base BASE-REF --expected-head CANDIDATE-SHA --title TITLE --body-file DESCRIPTION --format json
   ```

   Use the retained default/remote selection instead of `--server NAME` when applicable. In this repository invoke the source `bin/ace-git` entrypoint.
5. Read the structured result. Verify the retained server/provider/base and head repository/ref, draft PR number/URL, candidate SHA and base head. Record the PR identity and observed candidate head in the assignment report.
6. On interruption or an unknown create outcome, repeat the same command with the same selectors: the implementation re-reads open PRs and adopts one matching draft at the exact head without a second create. Adoption does not compare or rewrite the remote title/body, so verify the remote content explicitly before relying on it, and use `wfi://git/pr/update` if the description differs. Zero matches remain unresolved; multiple matches conflict. Never bypass an uncertain read with a different provider command.

## Success criteria

The assignment report records exact identity and the proven draft outcome. A report or shell exit alone proves nothing. Continue with actual tests and independent current-head review; keep the PR draft until those results are accepted. CI is visible and advisory. Publication is a separate authorized operation and is not required for delivery.
