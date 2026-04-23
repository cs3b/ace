# Goal 2 — Auto-Completion

## Goal

Prove parent auto-completion behavior for single-level and multi-level hierarchies
using explicit completion commands and status/report evidence.

## Workspace

Save output to `results/tc/02/`.

Required captures:
- `results/tc/02/create-single.stdout`, `results/tc/02/create-single.stderr`, `results/tc/02/create-single.exit`
- `results/tc/02/assignment-single-id.txt`
- `results/tc/02/select-single.stdout`, `results/tc/02/select-single.stderr`, `results/tc/02/select-single.exit`
- `results/tc/02/add-single.stdout`, `results/tc/02/add-single.stderr`, `results/tc/02/add-single.exit`
- `results/tc/02/status-single-00.stdout`, `results/tc/02/status-single-00.stderr`, `results/tc/02/status-single-00.exit`
- `results/tc/02/start-single-1.stdout`, `results/tc/02/start-single-1.stderr`, `results/tc/02/start-single-1.exit`
- `results/tc/02/finish-single-1.stdout`, `results/tc/02/finish-single-1.stderr`, `results/tc/02/finish-single-1.exit`
- `results/tc/02/status-single-01.stdout`, `results/tc/02/status-single-01.stderr`, `results/tc/02/status-single-01.exit`
- `results/tc/02/start-single-2.stdout`, `results/tc/02/start-single-2.stderr`, `results/tc/02/start-single-2.exit`
- `results/tc/02/finish-single-2.stdout`, `results/tc/02/finish-single-2.stderr`, `results/tc/02/finish-single-2.exit`
- `results/tc/02/status-single-02.stdout`, `results/tc/02/status-single-02.stderr`, `results/tc/02/status-single-02.exit`
- `results/tc/02/create-multi.stdout`, `results/tc/02/create-multi.stderr`, `results/tc/02/create-multi.exit`
- `results/tc/02/assignment-multi-id.txt`
- `results/tc/02/select-multi.stdout`, `results/tc/02/select-multi.stderr`, `results/tc/02/select-multi.exit`
- `results/tc/02/add-multi.stdout`, `results/tc/02/add-multi.stderr`, `results/tc/02/add-multi.exit`
- `results/tc/02/status-multi-00.stdout`, `results/tc/02/status-multi-00.stderr`, `results/tc/02/status-multi-00.exit`
- `results/tc/02/start-multi-1.stdout`, `results/tc/02/start-multi-1.stderr`, `results/tc/02/start-multi-1.exit`
- `results/tc/02/finish-multi-1.stdout`, `results/tc/02/finish-multi-1.stderr`, `results/tc/02/finish-multi-1.exit`
- `results/tc/02/status-multi-01.stdout`, `results/tc/02/status-multi-01.stderr`, `results/tc/02/status-multi-01.exit`

## Constraints

- Derive each assignment ID from the `Assignment: ... (<id>)` line in that goal's
  own `create-*.stdout` artifact. Never reuse IDs from fixture filenames,
  prior goals, examples, or previous runs.
- Save derived IDs as `assignment-single-id.txt` and `assignment-multi-id.txt`.
- Select the created assignment after each create and capture
  `select-*.stdout`, `select-*.stderr`, and `select-*.exit`; the runner must not
  continue that flow if selection exits non-zero.
- Use `--assignment <id>` to target cross-assignment commands, but do not pass a
  positional `STEP` together with `--assignment`.
- For cross-assignment execution, explicitly start work with
  `ace-assign start --assignment <id>` before each `ace-assign finish --assignment <id> --message <report-file>`.
  Do not rely on create/add/select implicitly activating descendants.
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
- Persist the required capture files listed above using those exact filenames.

## Evidence Guidance

- Prefer status and generated report artifacts proving completion cascades.
- Debug captures are fallback evidence only.
- Failure artifacts from invalid CLI usage are not acceptable completion
  evidence; correct the public command shape and rerun the intended command.
