# Goal 2 — Auto-Completion

## Goal

Prove parent auto-completion behavior for single-level and multi-level hierarchies
using explicit completion commands and status/report evidence.

## Workspace

Save output to `results/tc/02/`.

## Constraints

- Derive each assignment ID from the `Assignment: ... (<id>)` line in that goal's
  own `create-*.stdout` artifact. Never reuse IDs from fixture filenames,
  prior goals, examples, or previous runs.
- Save derived IDs as `assignment-single-id.txt` and `assignment-multi-id.txt`.
- Select the created assignment after each create and capture
  `select-*.stdout`, `select-*.stderr`, and `select-*.exit`; the runner must not
  continue that flow if selection exits non-zero.
- Use `--assignment <id>` to target cross-assignment commands, but do not pass a
  positional `STEP` together with `--assignment`. For cross-assignment finish,
  call `ace-assign finish --assignment <id> --message <report-file>` so the
  currently active step inside that assignment is completed.
- Use `add --yaml ... --assignment <id>` when injecting child steps into the
  non-latest assignment.
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
- Capture command evidence with stable names:
  - single-level: `create-single.*`, `select-single.*`, `add-single.*`,
    `status-single-00.*`, `finish-single-1.*`, `status-single-01.*`,
    `finish-single-2.*`, `status-single-02.*`
  - multi-level: `create-multi.*`, `select-multi.*`, `add-multi.*`,
    `status-multi-00.*`, `finish-multi-1.*`, `status-multi-01.*`

## Evidence Guidance

- Prefer status and generated report artifacts proving completion cascades.
- Debug captures are fallback evidence only.
- Failure artifacts from invalid CLI usage are not acceptable completion
  evidence; correct the public command shape and rerun the intended command.
