# Goal 2 — Auto-Completion

## Goal

Prove parent auto-completion behavior for single-level and multi-level hierarchies
using explicit completion commands and status/report evidence.

## Workspace

Save output to `results/tc/02/`.

## Constraints

- Use positional `finish <step-number> --message <report-file>` for explicit child completions.
- Select active assignment after each create.
- Use scratch YAML files under `.ace-local/e2e-inputs/tc02/` for `add --yaml`.
- Single-level flow must show:
  - parent blocked while children incomplete,
  - sequential child completion,
  - parent auto-completion report/state,
  - advancement to next top-level step.
- Multi-level flow must show:
  - grandchild completion,
  - ancestor cascade auto-completion,
  - advancement to next top-level step.
- If a scratch YAML input is invalid, correct it and rerun the intended command.

## Evidence Guidance

- Prefer status and generated report artifacts proving completion cascades.
- Debug captures are fallback evidence only.
