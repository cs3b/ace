---
doc-type: user
title: ace-assign Usage Guide
purpose: Complete command reference for ace-assign queue orchestration, hierarchy,
  and fork execution.
ace-docs:
  last-updated: '2026-04-23'
  last-checked: '2026-04-23'
---

# ace-assign Usage Guide

`ace-assign` manages assignment queues with explicit step states and optional hierarchy.

## Command Integrity

When documenting or automating `ace-*` flows, prefer direct commands and explicit report files.

Recommended:


```bash
ace-assign finish --message report.md
```

## Testing Contract

Use package-scoped test commands with explicit layers:

```bash
ace-test ace-assign
ace-test ace-assign feat
ace-test ace-assign all
ace-test-e2e ace-assign
```

For assignment verification, `verify-test-suite` is the standard gate:

```bash
ace-test <package> all --profile 6
ace-test-suite --target all
```

## Core Lifecycle


```bash
ace-assign create --yaml job.yaml
ace-assign status
ace-assign start
ace-assign step
ace-assign finish --message step-010.md
ace-assign status
```

Use scoped targeting when needed:


```bash
ace-assign status --assignment abc123@010.01
ace-assign start --assignment abc123@010.01
ace-assign finish --message done.md --assignment abc123@010.01
```

## Hierarchical Steps

### Numbering

- Top-level: `010`, `020`, `030`
- Child: `010.01`, `010.02`
- Grandchild: `010.01.01`

### Rules

- Parents auto-complete when all descendants are done.
- Queue traversal works deepest actionable step first.
- Inserted siblings can renumber later siblings (and descendants).

Create child/sibling steps:


```bash
ace-assign add --step update-docs --after 020
ace-assign add --step review-pr --after 100 --child
ace-assign add --yaml .ace-local/assign/jobs/add-task.yml --after 010 --child
```

## Attempt Evidence

Execution evidence lives in assignment attempts, not in reports. An attempt binds an immutable ID to an assignment, step/subtree scope, project, boundary-derived actor/role/runtime, source task, and `base_head`; the deliverable `candidate_head` is pinned only when accepted evidence is submitted, and the evidence journal commit is tracked separately from both.

### Attempt lifecycle

```bash
ace-assign attempt start --assignment ASSIGNMENT --step STEP --project PROJECT
ace-assign attempt status --assignment ASSIGNMENT --format json
ace-assign attempt finish --attempt ATTEMPT --receipt receipt.json
ace-assign attempt reconcile --attempt ATTEMPT --receipt receipt.json
```

- `attempt start` returns a JSON projection of the attempt (ID, state, binding facts, evidence references, digests). A repeated identical start returns the same attempt; a conflicting start exits 5 without launching a second writer.
- `attempt status` exposes only state, binding, references, and digests -- never credentials or receipt bytes.
- `attempt finish` accepts a structured receipt: operation, attributed producer, exact tested/reviewed head, verdict, artifact paths with SHA-256 digests, executed checks, and -- for review operations -- an executed independent reviewer verdict for that head.
- `attempt reconcile` classifies interrupted attempts (`stopped` before process start, `uncertain` when an effect cannot be proven either way, still `running` only for verifiably live processes) and resolves uncertainty only against a verified receipt attributed to the recorded execution boundary. Merge, publish, and deploy effects are never replayed automatically.

### State machine

`reserved -> running -> succeeded | failed | stopped | uncertain`; reconciliation may resolve `uncertain -> succeeded | failed`. Terminal attempts accept no new effects, and accepted history is append-only.

### Read accepted execution authority

`attempt evidence` reads a managed coordinator-accepted receipt from immutable journal history without transitions, cache writes, or audit checkout creation. Supply the accepted attempt ID and exact canonical receipt digest. The trusted local operator or OS-enforced service verifies the actual executed outcome before accepting its receipt; worker-authored success claims cannot accept themselves. This reader consumes that attestation and does not execute a test or model.

```sh
ace-assign attempt evidence --attempt ATTEMPT --receipt-digest SHA256 --format json \
  --kind check --check-name tests
ace-assign attempt evidence --attempt ATTEMPT --receipt-digest SHA256 --format json \
  --kind review-collection
ace-assign attempt evidence --attempt ATTEMPT --receipt-digest SHA256 --format json \
  --kind review-collection --historical-head EXACT_RECORDED_HEAD
ace-assign attempt evidence --attempt ATTEMPT --receipt-digest SHA256 --format json \
  --kind review-approval
```

A check proof requires the live candidate head, intact accepted artifacts, and the matching executed operation: `tests` uses `test`, other explicit check names use that operation name. Review collection requires an accepted `review-collect` operation with a passed `review-execution` outcome and the retained metadata/report/prompt artifacts. Review approval requires an ordinary accepted `review` operation with the approved independent reviewer verdict, exact head and retained report artifacts; collection proof cannot substitute for approval. Both collection and approval support an exact `--historical-head`. Historical review validation exposes `historical: true` and the recorded head; it preserves accepted source authority across head drift and cannot certify live checks. Unknown receipts, changed artifacts, unaccepted/unmanaged history, wrong purposes and stale current queries fail closed. Retain the configured evidence ref alongside durable review campaigns.

### Service effect claims

External service operations (driven through `ace-lab service request`) claim their effect on the assignment journal before dispatch, so a retried or crashed request can never duplicate a side effect. The coordinator owns the trusted surface; callers never append journal events directly.

- `Ace::Assign::Organisms::AttemptCoordinator#claim_service_request(binding)` records the claim and its attempt event atomically under a journal-wide request-ID index: the same request ID cannot be claimed twice, by another assignment, or against a stale candidate head. External-effect operations additionally require accepted review evidence at the current head, like `merge`.
- `#service_request_status(request_id)` reads the authoritative claim state, including after local cache loss.
- `#transition_service_request(request_id, state:, receipt:)` moves a claim to `succeeded` or `failed` only with a bound, non-secret receipt (exact request/attempt/project/operation/input digest/target fields, non-negative executor UID, and SHA-256 evidence references); rejected receipts never become approvals.
- `#reject_service_request(binding, reason:)` durably records an auditable rejection without inventing a valid attempt.
- Journal commits advance `journal_commit` only; they never change or authorize `candidate_head`, and `base_head` stays fixed at attempt start.

### Evidence storage and recovery modes

- Task-attached (managed) attempts journal accepted evidence to the configured evidence Git ref (default `refs/ace/execution`) through an isolated, disposable audit checkout, outside the deliverable candidate branch. Journal commits never advance or exempt the reviewed candidate.
- Taskless assignments persist attempts under `.ace-local/assign` with `recovery_mode: local_only`. This path never claims Git-backed recovery and cannot record external effects (`merge`, `publish`, `deploy`, `release`); attach the assignment to a source task before managed delivery.
- Actor identity always comes from the execution boundary (OS login for local use, or the trusted service executor's identity). Unknown identity fails closed; flags never grant identity or authority.

### status integration

`ace-assign status --format json` includes the active attempt, `base_head`, `candidate_head`, `evidence_git_ref`, `journal_commit`, and unresolved effects. Feedback state is derived from accepted current-head evidence: `terminal` (accepted evidence at the current head), `open` (attempts without a terminal outcome), `uncertain` (unresolved interruptions), or `unknown` (no attempts). Merge authorization requires an executed independent review verdict for the current head plus an independent release receipt when relevant; report files, exit codes, and prose never authorize a merge.

## Commands

### `ace-assign create`

Create a new assignment from YAML or from task refs expanded through an assignment preset.

Options:

- `--yaml FILE`
- `--task, -t <taskref[,taskref...]>` (repeatable)
- `--preset, -p NAME`
- `--quiet, -q`
- `--debug, -d`

Exactly one mode is required: `--yaml` or `--task`.

### `ace-assign status`

Show queue status for active or explicitly targeted assignment.

Options:

- `--flat, -f`
- `--mode compact|progress|full`
- `--format table|json`
- `--assignment <id>`
- `--all, -a`
- `--quiet, -q`
- `--debug, -d`

Text modes:

- `compact` (default) prints a short summary, hidden-step stats, and up to 5 upcoming step lines
- `progress` prints a single summary line
- `full` prints the full tree/table without step instructions
- JSON emits `active_steps` for all active steps in scope and `next_step` only when no step is active in that scope

HITL stall behavior:

- Canonical contract lives in `wfi://hitl` (`ace-hitl` package workflow).
- If a step is failed with canonical message format `HITL: <id> <path>`, `ace-assign status` prints operator guidance with the matching `ace-hitl show <id>` command and available path hint.
- Recommended resume flow:

  - `ace-hitl show <id>`
  - requester path (default): `ace-hitl wait <id>`
  - fallback path (when waiter inactive): `ace-hitl update <id> --answer "<decision>" --resume`
  - `ace-assign retry <failed-step> --assignment <assignment-id>`

- Completion-attention flow:

  - When assignment work is complete but explicit user action is needed, create an approval HITL event (`kind=approval`) and include the resume instruction for `/as-assign-drive <assignment-id>`.

### `ace-assign step [STEP]`

Show instructions for the deepest active step in scope, the next workable pending step when nothing is active, or an explicit step number.

Options:

- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign start [STEP]`

Mark the next workable pending step active, or mark an explicit pending step active in the targeted assignment or subtree.

Options:

- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign finish [STEP] --message VALUE`

Complete the current active step (or explicit active step in the active assignment) with report content.
Use positional `STEP` only for the active assignment. When targeting another
assignment or a scoped subtree, pass `--assignment <id>` or
`--assignment <id@step>` without a positional `STEP`; the command finishes the
deepest active step in that target.

`--message` accepts:

- Inline text
- File path

Options:

- `--message, -m` (required)
- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign fail --message TEXT`

Mark current step as failed.

Options:

- `--message, -m` (required)
- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign add`

Insert new step(s) dynamically.

Options:

- `--yaml FILE`
- `--step NAME[,NAME...]`
- `--task TASKREF`
- `--preset NAME`
- `--after, -a NUMBER`
- `--child, -c`
- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

Exactly one mode is required: `--yaml`, `--step`, or `--task`.

### `ace-assign retry STEP_REF`

Create a linked retry step for a failed step.

Options:

- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign fork-run`

Execute a fork-enabled subtree in an isolated process.

Options:

- `--root <step-number>`
- `--assignment <id>`
- `--provider <provider:model>`
- `--cli-args <args>`
- `--timeout <seconds>`
- `--launch-mode auto|headless|tmux|herdr`
- `--callback`
- `--quiet, -q`
- `--debug, -d`

Launch modes:

- `auto` (default): use the detected terminal runtime — tmux when the current process is inside tmux or `ACE_TMUX_SESSION` is set (tmux wins when both are live), herdr when `HERDR_SESSION` + `HERDR_PANE` are live; with no runtime detected, use the headless subprocess path (assign is the only consumer with a headless fallback)
- `headless`: force the existing provider subprocess path and never create terminal panes
- `tmux`: require a live tmux context, create or reuse `<origin-window>-fs` through the `ace-runtime` contract, start a real interactive agent in a prepared pane via `ace-llm --interactive`, and send the scoped `/as-assign-drive <assignment>@<root>` handoff automatically
- `herdr`: the same flow through the Herdr adapter — the fork opens as a tab in the caller's live Herdr workspace and the child inherits `HERDR_*` plus `ACE_RUNTIME=herdr`

  - All terminal targeting, pane dispatch, and capture go through the runtime-neutral `ace-runtime` contract; the fork window name uses the shared `ace-runtime` safe-name policy, so punctuation in the base window is replaced with `-`.
  - Fork windows/panes and herdr tabs are created detached, so the current focus stays where the user left it.
  - Assignment step state remains the source of truth for subtree completion or failure; pane capture is diagnostic support only.

Callback mode:

- `--callback`: terminal-only fork mode (requires `tmux` or `herdr` launch mode) that captures the pane where `fork-run` was started and passes it into the child fork session as `ACE_ASSIGN_CALLBACK_PANE`
- In callback mode the child agent is instructed to send one final status sentence back to the origin pane with `ace-runtime send` before stopping
- Callback mode is intended for interactive parent/child agent flows where the parent stays idle until the child sends the final message back

Launch-mode precedence for fork execution:

1. CLI `--launch-mode`
2. Step frontmatter `fork.mode`
3. Config `execution.launch_mode`
4. Built-in default `auto`

Provider resolution precedence for fork execution:

1. CLI `--provider`
2. Step frontmatter `fork.provider`
3. Config `execution.provider`
4. Built-in default provider

Step-level example:

```yaml
---
name: research
status: pending
context: fork
fork:
  provider: "claude:sonnet@yolo"
  mode: "tmux"
---
```

### `ace-assign list`

List assignments.

Options:

- `--all, -a`
- `--task, -t <taskref>`
- `--tree`
- `--format table|json`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign select [ID]`

Select active assignment or clear selection.

Options:

- `--clear`
- `--quiet, -q`
- `--debug, -d`

## Workflow Patterns

### `work-on-task` Input Filtering (Prepare/Create Workflows)

When using preset-backed assignment creation (`ace-assign create --task ...`, `/as-assign-prepare`, or `/as-assign-create`):

- Requested refs are resolved first (single, comma list, range, pattern).
- Terminal refs (`done`, `skipped`, `cancelled`) are skipped before queue expansion.
- Mixed sets continue with remaining non-terminal refs and report skipped terminal refs.
- If all requested refs are terminal, assignment creation stops with:

  - `All requested tasks are already terminal (done/skipped/cancelled): <refs>`
  - `No assignment created.`

### Scoped Subtree Execution


```bash
ace-assign status --assignment abc123@010.01
ace-assign fork-run --assignment abc123@010.01
```

### Recovery from Failure


```bash
ace-assign fail --message "Lint failed in docs"
ace-assign retry 040 --assignment abc123
```

### Multi-assignment Management


```bash
ace-assign list --all
ace-assign select abc123
ace-assign select --clear
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Assignment error |
| 3 | Configuration not found |
| 4 | Step not found |
| 130 | Interrupted (SIGINT) |

See [exit-codes.md](exit-codes.md) for complete descriptions.

## Resume accepted assignment state

```bash
ace-assign resume --assignment ID --dry-run
ace-assign resume --assignment ID
ace-assign inbox-reconcile --attempt ID --event ID --receipt proof.json
```

Both commands return JSON with task goal, checkpoint, attempts, pending HITL references and unresolved effect/inbox references. Each attempt reports `adopt`, `restart-required` or `reconcile-required`, liveness, recovery reason and its last verified observation. Dry-run writes nothing. Actual resume journals a bounded observation; unproven running attempts become uncertain and keep their writer slot. It never launches a new process or resends a payload. Restart goes through a new `attempt start` only after the previous attempt ends with accepted evidence.

Managed agents invoking attempt start inside tmux/Herdr obtain a runtime-owned process binding. Recovery compares PID, UID, OS start time, host, exact pane/native session and Herdr terminal/native thread. A surviving shell is not the agent. Missing, unreadable or reused identity remains unknown. A plain local CLI establishes its actor through the OS login boundary but supplies no durable agent identity; trusted service executors may supply `process_pid` in their configured identity JSON. Process observation never grants service privilege or effect authority.

Pending HITL references retain their exact scope/attempt and are not rebound by resume. Uncertain external claims require existing effect receipt reconciliation. Delivery consumption is separate from business success. Herdr owns signed inbox verification (`ace-herdr inbox reconcile --event ID --receipt FILE`); the assignment `inbox-reconcile` command uses that same configured verifier and additionally records the accepted observation references. `AttemptCoordinator#bind_inbox` records only the event reference, and `#reconcile_inbox` delegates that same verifier and journals only the verified proof digest/path and native observation reference. A consumed receipt settles transport once. A superseded receipt requeues the same event for an explicit retry, without succeeding the attempt. Exact signed replay recovers a crash between Herdr settlement and the assignment journal write; changed key, target, payload or generation fails closed. Retain the matching protected key pair for unresolved events or postpone rotation.

Installed Herdr/Pi compaction and writing-child stop/close acceptance must be recorded separately from deterministic fixture coverage before Lab cutover.
