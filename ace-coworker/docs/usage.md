---
doc-type: usage
title: ace-coworker Usage
purpose: full command reference, role presets, and the start-config contract
ace-docs:
  last-updated: 2026-10-18
  last-checked: 2026-10-18
---

# ace-coworker Usage

`ace-coworker` is the prepared executor of the file-based lab. The planner
(L4) writes the run configuration; `ace-coworker` reads, validates, and
renders what the executor agent must drive. This document is the single
source for the start-config format.

## Start config — `.ace-local/coworker/config.yml`

```yaml
role: worker                          # required, non-empty role name
instructions: "roles/worker.md"       # required: file path relative to the
                                      # project root, or wfi:// prompt:// tmpl://
start_prompt: "Drive assignment <id> for task <ref> as worker."
                                      # required (or start_prompt_file: path
                                      # relative to the project root, whose
                                      # content becomes the prompt; the two
                                      # are mutually exclusive)
task: "8xg.t.sbz.2"                   # required: task ref that must resolve
                                      # in this worktree
assignment: "abc123"                  # required: assignment id that must exist
                                      # under .ace-local/assign/ and whose
                                      # task_id matches `task`
overseer: "overseer@machine"          # required: reporting address (opaque
                                      # string until the L2 addressing scheme
                                      # is integrated)
reporting:
  channel: hitl                       # optional, default hitl
errors:
  on_failure: report                  # optional: report | stop (default report)
```

Validation is field-specific: every missing or invalid field produces its own
error, and no substitute commission is guessed. The config never copies
assignment steps — the plan stays solely with `ace-assign`.

## Roles and presets

`ace-coworker` ships role presets — static YAML assets, not a role allowlist.
The catalog lives in the gem's `.ace-defaults/coworker/roles/*.yml`; a project
overrides or extends it via `.ace/coworker/roles/*.yml` (same filename wins,
project beats gem). Every preset file is validated on load; the `role` field
of a config is never checked against the catalog (ADR-034: the overseer
decides roles).

```yaml
---
name: worker                            # required, non-empty
description: Implements and verifies    # optional, non-empty when present
instructions: wfi://coworker/worker     # required: same sources as the config
start_prompt: "Drive {{assignment}}…"   # required template; placeholders:
                                        # {{task}} {{assignment}} {{role}} {{overseer}}
reporting: {channel: hitl}              # optional, ConfigSchema value sets
errors: {on_failure: report}            # optional, ConfigSchema value sets
```

Shipped presets: `worker` (implement and verify; failed required tests block
success) and `spec` (complete behavior-first specification; significant
unresolved gaps are reported, never guessed). Their instruction workflows are
`wfi://coworker/worker` and `wfi://coworker/spec`.

### `ace-coworker roles`

```
ace-coworker roles [--format table|json] [-q] [-d]
```

Lists the catalog (name, source `gem`|`project`, description, instruction
source). Read-only; always exit 0; an empty catalog renders an explicit empty
state.

### `ace-coworker commission`

```
ace-coworker commission --role NAME --task REF --assignment ID --overseer ADDR
                        [--start-prompt TEXT] [--config PATH] [--force]
                        [--dry-run] [--format table|json] [-q] [-d]
```

The role-instantiation primitive consumed by the planner (L4.2/L4.3 seam):
expand a role preset plus the commission identity into the documented
`.ace-local/coworker/config.yml` (target from the config cascade, or
`--config PATH` root-relative). `commission` is a single-role writer for the
location ace-coworker already owns — no sequencing, no active-driver
detection, no role policies; those belong to the planner, which decides role
order and guards against overwriting an active driver.

Procedure:

1. fetch and validate the preset (`unknown role '<name>' (available: …)`);
2. render the preset's `start_prompt` template with the commission identity
   (`{{task}}`, `{{assignment}}`, `{{role}}`, `{{overseer}}`; unknown
   placeholders stay literal; an explicit `--start-prompt` wins over the
   template; `start_prompt_file` is not accepted here — write that config
   variant by hand);
3. run the same identity checks as `start`: the task must resolve in this
   worktree and the assignment must exist under `.ace-local/assign/` with a
   matching `task_id` (same message vocabulary as `start`);
4. validate the assembled config through the start-grade schema
   (round-trip guarantee: what `commission` writes, `start` accepts);
5. write atomically (temp file + rename in the target directory), creating
   parent directories; an existing target is refused without `--force`
   (`refusing to overwrite '<path>'; use --force`);
6. `--dry-run` resolves and renders the config without writing anything.

Result JSON (table renders the same fields): role, task, assignment,
overseer, config_path, preset_source (`gem`|`project`), dry_run, written, and
the resolved config mapping.

## Commands

### `ace-coworker start`

```
ace-coworker start [--config PATH] [--format table|json] [-q] [-d]
```

Reads the config (default `.ace-local/coworker/config.yml`), then:

1. resolves the task ref in this worktree via `ace-task`;
2. verifies the assignment exists under `.ace-local/assign/` and its
   `task_id` matches the config task;
3. reads assignment truth from `ace-assign status --assignment <id> --format json`;
4. resolves the instruction source (file relative to the project root, or
   protocol URI via `ace-nav resolve`);
5. prints the executor brief: role, resolved instruction source, start
   prompt, task ref + path, the pinned `--assignment <id>` drive target,
   overseer address, error rules, and current assignment state.

`start` writes nothing. Exit codes: `0` ready; `1` with a specific message
(`not ready: …`, `invalid config …: …`, `task '<ref>' not found in this
worktree`, `assignment '<id>' not found …`, `assignment '<id>' belongs to task
'<other>', not '<ref>'`, `instruction file '<path>' not found in this
worktree`).

### `ace-coworker status`

```
ace-coworker status [--config PATH] [--assignment ID] [--format table|json] [-q] [-d]
```

Readiness query — always exit `0`. Absent config renders
`not ready: .ace-local/coworker/config.yml not found`. Otherwise renders the
resolved role/task/assignment/overseer, the assignment progress, and the
completion verdict with remaining-work reasons (empty plan, failed steps,
pending/active steps).

The completion verdict is deterministic: `complete` iff the assignment state
is `completed`, the step plan is non-empty, and every step is `done`. Process
or session end never implies completion.

### `ace-coworker report`

```
ace-coworker report [--config PATH] [--assignment ID] [--result success|error]
                    [--message TEXT] [--step N] [--no-send] [--dry-run]
                    [--format table|json] [-q] [-d]
```

Records the assignment outcome and reports it through `ace-hitl`:

1. derives the outcome from the ace-assign verdict (`--result` optional;
   forcing `success` on an incomplete assignment is refused before anything
   is written; an error outcome requires a cause — `--message` or the failed
   step's recorded `error:` — and lists the unfinished steps);
2. writes the durable record into the task's own folder
   (`<task>/coworker/<assignment>.md`) — the contract-sanctioned per-task
   progress location;
3. keeps helper state in `.ace-local/coworker/reports/<assignment>.json`;
4. creates a HITL report event (`ace-hitl create --type report --result …
   --task/--assignment/--step --to <overseer>`) and delivers it
   (`ace-hitl send <id>`).

Outcome and delivery are separated: an undelivered report keeps the recorded
outcome and exits 1 with an explicit delivery error; a rerun with the same
result resends the existing event instead of duplicating it (retrying
delivery never retries the assignment). `--no-send` creates the event
without delivering; `--dry-run` derives the outcome with zero writes;
`errors.on_failure: stop` records errors locally without any HITL
subprocess. The `overseer` config field is the configured `ace-hitl`
recipient name (resolved via `--to`).

### `ace-coworker resume`

```
ace-coworker resume [--config PATH] [--assignment ID] [--dry-run] [--format table|json] [-q] [-d]
```

After an interruption: reads the existing assignment, task, and the REAL
state of the same worktree, and renders the resume path. Same task,
assignment, and worktree — never a new one; local changes are never reset;
resume itself never drives assignment steps (the executor does, via
ace-assign).

Dispositions:

- `continue` — the assignment is incomplete: preserved done steps,
  remaining work, the in-flight step (active, else failed) with its recorded
  cause and report plus verify-before-repeat guidance, and the preserved
  local-change list. Steps named like external effects
  (merge/publish/deploy/release/push) add an effect-caution block: check the
  actual state with existing tools (e.g. `ace-git status`, PR evidence) or
  report a blocker — never replay blindly, never a new task/worktree.
- `report` — the assignment is complete but the report delivery is missing:
  delegates to the report flow, resending the SAME HITL event ID (retrying
  delivery never retries the assignment).
- `complete` — complete and delivered: informational, nothing to resume.

`--dry-run` derives the plan with zero writes. There is no journal or
checkpoint store: the worktree git state, the ace-assign step files, and
the report helper state ARE the checkpoint (ADR-034).

### `ace-coworker prepare`

```
ace-coworker prepare --task REF --roles worker,reviewer [--to overseer@addr]
                     [--config PATH] [--dry-run] [--format table|json] [-q] [-d]
```

The planner side of the commission: accept a preparation commission (task
reference + expected role sequence) and find or prepare exactly ONE proper
worktree for that task. Re-preparing the same task reuses its existing
worktree with zero writes — work and the task association are preserved.
Assignments for the role sequence (L4.2), start configs in
`.ace-local/coworker/` (L4.3), and the readiness report (L4.4) are later
leaves; this command leaves those seams via the echoed `roles` and the JSON
result.

Deterministic decision procedure (no new state; ace-git-worktree stays the
worktree owner):

1. Resolve the project root and the task via ace-task; an unresolvable ref
   fails with `task '<ref>' not found in this worktree` (invalid commission,
   no HITL event).
2. Find the task's worktree (association-aware `ace-git-worktree` switch):
   a resolved worktree for this task is reused; a resolved worktree for
   another task is a `mismatched_worktree` conflict; stale metadata (an
   association whose directory is missing — detected via the association
   inventory, since the owner's switch never resolves a missing directory)
   recovers via prune + recreate, reattaching the surviving branch so its
   committed work is never orphaned behind a freshly minted branch.
3. Otherwise create the task worktree (idempotent owner call). A creation
   failure while the expected location is occupied — on either the miss path
   or the stale-recovery retry — is a `mismatched_worktree`
   conflict; any other failure exits 1 with the structured error and its
   recovery hint (operational error, no HITL event).
4. Probe the resolved worktree for an active executor: the worktree's
   `.ace-local/coworker/config.yml` names a commissioned assignment whose
   state is anything other than `completed` (including unparseable/unknown —
   never overwrite), or any uncommissioned assignment is `running`/`stalled`,
   is an `active_executor` conflict — a completed commission falls through
   to the uncommissioned scan, so it never masks another running/stalled
   assignment. Pending/never-started assignments never block (the up-front
   role sequence of L4.2 must not self-conflict); uncommissioned `failed`
   assignments are surfaced as context only. On an `active_executor`
   conflict the rule evidence (`assignment`, `state`, `source`) is emitted
   structurally in `active_executor`.
5. Reuse performs zero writes: no git effects, no task frontmatter rewrite,
   no config change.

Conflicts mutate nothing: a decision-type HITL question for the overseer is
created and sent (`--type question --kind decision`, title
`Preparation conflict - <task>/<worktree-dir>`). The overseer fallback
reads the `overseer` field of `--config` leniently, so a partial
(planner-side) config still names its recipient; a config that fails full
validation AND supplies no overseer surfaces the load error alongside the
explicit `cannot report conflict: no overseer address` note. If the
ace-hitl CLI itself is unavailable, the structured conflict result is still
rendered with the failure folded into its detail. Without any escalation
recipient the conflict still exits 1. An undeliverable event keeps the
event id in the output for a later
`ace-hitl send <id>` retry — retrying delivery never retries preparation.

Result JSON (table renders the same fields):

```json
{
  "task": "8xg.t.sbz.3",
  "task_path": "/abs/.ace-tasks/8xg.t.sbz-lab…/",
  "roles": ["worker", "reviewer"],
  "worktree": { "path": "/abs/.ace-wt/t.8xg-t-sbz-3", "branch": "8xg-…", "disposition": "created" },
  "active_executor": null,
  "worktree_assignments": [{"id": "abc123", "state": "paused", "progress": "0/2"}],
  "conflict": null
}
```

`disposition` is `created` / `recovered` (stale metadata recovered) / `reused`
or, with `--dry-run`, `would_create` / `would_recover` (stale metadata that
the real run would recover). A non-null `conflict`
(with `kind`, `detail`, `hitl_event`) replaces `worktree`. `--dry-run`
performs the full resolution and conflict detection with zero writes (no
create, no prune-recovery, no HITL events); the exit code reflects the
would-be outcome.

## Exit codes

| Command | 0 | 1 |
|---|---|---|
| `start` | config valid, task+assignment verified, brief rendered | missing/invalid/mismatched input |
| `status` | query rendered any state (including not-ready) | — |
| `report` | success outcome recorded (and delivered, or `--no-send`/`--dry-run`) | error outcome; delivery/create failure (outcome still recorded); refused input |
| `resume` | continue/complete rendered; report redelivered | delegated report failure keeps its exit 1 (plan still rendered) |
| `prepare` | worktree created/recovered/reused (dry-run: would_create/would_recover) | conflict (active_executor / mismatched_worktree); invalid commission; operational preparation failure |
| `roles` | catalog rendered any state (including empty) | — |
| `commission` | config written (dry-run: resolved, nothing written) | unknown role; invalid commission; task/assignment mismatch; refused overwrite; invalid assembly |

## Boundaries

- `.ace-local/coworker/` is owned by `ace-coworker`; `.ace-local/assign/` by
  `ace-assign`; `.ace-local/hitl/` by `ace-hitl`; `.ace-tasks/` by `ace-task`.
- No journal, queue, daemon, or second plan store (ADR-034).
- Delegation to `ace-assign` / `ace-nav` uses argv subprocess calls with an
  explicit working directory (ADR-031).
- Reporting via `ace-hitl` and resume-after-interruption ship with
  `ace-coworker` 0.4.0+; role presets resolve their `wfi://` instruction
  sources through `ace-nav` (runtime dependency since 0.5.0).
