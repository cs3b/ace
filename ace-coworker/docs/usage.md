---
doc-type: usage
title: ace-coworker Usage
purpose: full command reference, role presets, and the start-config contract
ace-docs:
  last-updated: 2026-10-19
  last-checked: 2026-10-19
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
project beats gem). Every preset file is validated on load — including that
the `name` field matches the file's basename — so a project file `worker.yml`
must declare `name: worker`; the `role` field
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
success), `spec` (complete behavior-first specification; significant
unresolved gaps are reported, never guessed), and `reviewer` (independent
review of the delivered change; fixes confirmed defects itself inside its own
assignment, checks each fix diff, and returns to full review rounds under the
3/2/10 convergence rule - deterministically enforced by
`Ace::Coworker::Atoms::RoundRule` (:continue | :accept | :escalate) with the
persisted round history in `.ace-local/coworker/review-rounds/<assignment>.json`
(`Molecules::ReviewRoundStore`; rounds are recorded through
`ace-coworker rounds record`, and a restart reloads the counters instead of
resetting them); escalates instead of marking unresolved
High/Critical as success), and `integrator` (result-dependent integration of
ready candidates: before merging it checks that dependencies are integrated
predecessors, the candidate head still matches the reviewed head, tests were
executed and passed, and a fresh independent review verdict accepts the
exact candidate head - deterministically enforced by
`Ace::Coworker::Atoms::IntegrationGate` via `ace-coworker gate`
(:ready | :blocked with per-check reasons); a stale review, unsatisfied
dependency, or missing test evidence withholds the merge and escalates to
the overseer instead of merging past the gate). Their instruction workflows
are `wfi://coworker/worker`, `wfi://coworker/spec`,
`wfi://coworker/reviewer`, and `wfi://coworker/integrator`. Role assignments
are prepared by the planner (L4)
or commissioned ad hoc via `commission`; the reviewer (like the worker)
develops its own assignment through `ace-assign add`, so confirmed-defect
fixes stay inside one assignment without overseer round-trips.

### Start configs per role leg — `.ace-local/coworker/prepare/<role>.yml`

`prepare` writes ONE start config per planned sequence leg, at
`.ace-local/coworker/prepare/<role>.yml` inside the task worktree, in the
same documented format as `config.yml` (above). The next role starts from
its own context with zero ad-hoc setup:

```
ace-coworker start --config .ace-local/coworker/prepare/worker.yml
```

(run inside the task worktree). Ownership split — one writer per file:

- `prepare` owns `.ace-local/coworker/prepare/<role>.yml`. Each leg config
  is expanded through the SAME commission primitive (preset → identity
  checks → schema validation → atomic write), so the round-trip guarantee
  "what commission writes, start accepts" holds by construction; the
  start prompt comes from the role preset's template rendered with the
  leg's task, assignment, role, and overseer.
- `commission` remains the single writer of the default config target
  (`config.yml` or the cascade's `config_path`). `prepare` never writes
  it and never overwrites an active driver — the active-executor and
  mismatched-worktree conflicts are detected before any config write.

Leg configs carry no secrets and no assignment steps — only the documented
config fields with the composed assignment id as the ace-assign reference.
An overseer address is required for every leg (`--to`, or the coworker
config's `overseer` read leniently); without one, prepare ends with a
`missing_overseer` gap — `preparation conflict: missing_overseer - no
overseer address for the start configs (--to or coworker config)` — and
writes no leg config. Error precedence is deliberate:
role-validation errors (unknown role, missing process definition) win
over the missing-address check, and the check runs AFTER assignment
composition — the worktree and the L4.2 assignments are a delivered
artifact at that point; re-running prepare with `--to` idempotently adds
the leg configs. Writes are idempotent: identical
content is reported as `reused` (no write), changed content as `updated`,
`--dry-run` reports `planned` with zero writes. All legs are resolved
and validated before the first file is written, so a late leg failure
cannot leave a partial set of configs behind.

### `ace-coworker roles`

```
ace-coworker roles [--format table|json] [-q] [-d]
```

Lists the catalog (name, source `gem`|`project`, description, instruction
source). Read-only; exit 0 for any valid catalog state, including an empty
catalog (rendered as an explicit empty state); an invalid preset file fails
with a specific error (non-zero exit).

### `ace-coworker rounds record`

```
ace-coworker rounds record --assignment ID --type full|delta
                           --status completed|aborted
                           [--confirmed id:sev[,...]] [--resolved id[,...]]
                           [--format table|json] [-q] [-d]
```

The reviewer role's round-recording surface for the 3/2/10 convergence rule
(8xg.t.sbz.4.2): appends one finished round to the coworker-owned history at
`.ace-local/coworker/review-rounds/<assignment>.json`
(`Molecules::ReviewRoundStore#record!`) and prints the resulting
`Ace::Coworker::Atoms::RoundRule` verdict with its counters
(verdict `continue | accept | escalate`, full rounds, completed full
rounds, consecutive clean, unresolved High/Critical ids). `--confirmed`
takes `id:severity` pairs (e.g. `f-1:high`); `--resolved` takes finding ids
resolved by this round. A corrupt or non-array history file fails with
`corrupt round history at <path>` instead of silently resetting the
counters; the same applies to a malformed record shape (actionable field
errors, non-zero exit).

### `ace-coworker gate`

```
ace-coworker gate --review-verdict accept|continue|escalate
                  [--candidate-head SHA] [--review-head SHA]
                  [--tests executed,passed] [--dep LEAF=integrated|missing ...]
                  [--format table|json] [-q] [-d]
```

The integrator role's pre-merge gate (8xg.t.sbz.4.3): a pure, stateless
evaluation of the four project-defined checks. `--candidate-head` is the
current candidate head (omit it when genuinely unknown - the gate then
blocks on the missing evidence instead of guessing); `--review-head` is the
candidate head the independent review verdict covers; `--tests` takes the
`executed,passed` evidence flags (any other token is an error, not
silent missing evidence); each `--dep NAME=integrated|missing` pair
states one dependency leaf (`missing` or any other value = not
integrated; the pair must contain `=`, and repeating a name is an
error). Empty or omitted `--dep` means the caller enumerated no
dependencies - the gate trusts the caller's dependency enumeration.
Prints `ready` or `blocked` with per-check reasons (dependencies, candidate
drift, review freshness/verdict, executed+passing tests). `blocked` is a
legitimate gate outcome (exit 0) - the role withholds the merge and
escalates; only malformed input (an invalid `--dep` pair, a duplicate
`--dep` name, or an invalid `--tests` token) fails with a non-zero exit.
Heads are recorded and compared as full lowercase SHAs. Nothing is persisted and no git operation is performed: the
gate decides readiness only.

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
order and guards against overwriting an active driver. `prepare` reuses this
primitive internally for its per-leg configs under
`.ace-local/coworker/prepare/`, but the default config target written here
stays `commission`'s alone.

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
   parent directories; the resolved target must stay inside the project root
   (`config path '<path>' escapes the project root`) and must name a file,
   not a directory; an existing target is refused without `--force`
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

Reads the config (default `.ace-local/coworker/config.yml`, or a
planner-prepared leg config via `--config
.ace-local/coworker/prepare/<role>.yml` — same format, same checks), then:

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
worktree for that task, THEN compose the assignments for the WHOLE known
role sequence in one go (L4.2), so after start the roles hand off
sequentially without the overseer re-commissioning preparation per step.
Composition is idempotent: re-preparing the same task reuses its existing
worktree and the already-composed assignments (matching
`<task>-<role>` assignment names with a recorded task_id) with zero
redundant writes; only sequence legs not yet composed are added. Prepare
also writes the per-role executor start configs (L4.3) — one
`.ace-local/coworker/prepare/<role>.yml` per leg (see the section above) —
so `ace-coworker start --config .ace-local/coworker/prepare/<role>.yml`
inside the worktree begins any leg without ad-hoc setup; `commission`
stays the single-role writer of the default `config.yml` target. After
a successful preparation the planner sends the overseer a READINESS
report via ace-hitl (L4.4, see below). Note:
composing multi-leg sequences leaves ace-assign's `.ace-local/assign/.latest`
pointing at the LAST-composed leg (e.g. integrator); drivers must address
legs by the explicit assignment ids from the prepare result, never via
`.latest`-based resolution.

Sequence composition (no new state owner; `ace-assign` stores the plans in
the worktree's `.ace-local/assign/`, ADR-034):

- ONE assignment per role, in dependency order. Each records the task id
  (the `commission` task↔assignment match works unchanged), the expected
  outcome of the leg in its description, and the position
  (`sequence N/M`). Every leg after the first opens with an explicit entry
  condition naming the predecessor assignment and role.
- Each role's process comes from its own sequence definition — shipped
  `.ace-defaults/coworker/sequences/<role>.yml`, project override
  `.ace/coworker/sequences/<role>.yml` (whole-file, project wins; the
  `role` field must match the filename's role). Worker and reviewer get
  DIFFERENT processes matched to the same task: the worker leg requires
  passing `bin/ace-test` per modified package, the reviewer leg embeds the
  3/2/10 round rule (`ace-coworker rounds record`, min 3 completed full
  rounds with the last 2 consecutive clean and no unresolved earlier
  High/Critical, max 10, then escalation), the integrator leg runs the
  `ace-coworker gate` checks before any merge, and the spec leg raises
  material requirement gaps as `ace-hitl` questions instead of guessing.
- A role without a preset (`unknown role '<name>'`) or without its own
  process definition (`role '<name>' has no assignment process … refusing
  to substitute another role's process`) is a `role_sequence` GAP
  reported with exit 1, NOTHING composed (all-or-nothing), and a
  decision question to the overseer when an escalation recipient
  resolves: the planner never substitutes another role's process. The
  worktree itself stays prepared and kept.
- `--dry-run` composes nothing (the would-be worktree does not exist), so
  the result reports `assignments: []` and `start_configs: []` alongside
  `would_create`/`would_recover`.

Start-config composition (L4.3; same owner, new artifact kind under
`.ace-local/coworker/`):

- ONE start config per leg at `.ace-local/coworker/prepare/<role>.yml` in
  the worktree, expanded through the commission primitive from the same
  role preset — role, instruction source, preset-rendered start prompt,
  task, the leg's assignment id, the resolved overseer address, and the
  preset's reporting/error rules. `start --config` accepts it unchanged
  (round-trip guarantee); `commission`/the default `config.yml` target is
  never touched by prepare.
- The overseer address resolves like conflict escalation: `--to` wins,
  else the coworker config's `overseer` (lenient field-only read, so a
  partial planner-side config still names it). No address anywhere: a
  `missing_overseer` GAP — exit 1 with
  `preparation conflict: missing_overseer - no overseer address for the
  start configs (--to or coworker config); the commission is NOT ready -
  no leg config is written…` (followed by the prepared/decision-needed
  detail lines) and no leg config written —
  never a config with an empty overseer and never a ready commission.
  The gap detail states what IS prepared (worktree, assignments) and
  the decision needed (supply `--to` and re-run prepare, idempotent).
- Idempotent: re-preparation reports an identical leg config as `reused`
  without a write; changed content (e.g. a different overseer) is
  rewritten as `updated` — prepare is the single writer of these files.
  Conflict checks (active executor, mismatched worktree) run BEFORE any
  config write, so preparing the next role never disturbs an active
  driver. Leg configs never copy secrets or assignment steps.
- `--dry-run` reports each leg config as `planned` with zero writes (for
  an existing worktree; a not-yet-existing worktree reports
  `start_configs: []`).

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
5. Reuse performs zero redundant writes: no git effects, no task frontmatter
   rewrite, no config change; already-composed sequence assignments are
   reported as `existing` with their original ids, and only sequence legs
   not yet composed are created.

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

Readiness / gap reporting (L4.4; ace-hitl stays the transport and event
owner, no new state):

- Every SUCCESSFUL preparation (created / recovered / reused) ends with
  a READINESS report to the overseer — `--type report --result success`
  (`Preparation ready - <task>/<worktree-dir>`), a report expects no
  reply. The body carries the complete set to run the first step:
  the worktree (path/branch/disposition), every sequence leg
  (`sequence N/M <role>: <assignment>`), every start config, and the
  exact first step (`ace-coworker start --config
  .ace-local/coworker/prepare/<first-role>.yml` in the worktree) — the
  overseer never composes ace-assign details itself. The report is
  delivered immediately; the result JSON carries it under `report`
  (`{"kind": "readiness", "event": <id>, "delivered": …}`). A create or
  delivery failure never undoes the preparation: the failure (or the
  event id plus `ace-hitl send` retry hint) is recorded in `report`
  instead.
- GAPS never pass as ready: `role_sequence` (role preset/process
  errors) and `missing_overseer` join the existing
  `active_executor` / `mismatched_worktree` conflicts — exit 1, nothing
  unprepared is started, and the gap escalates to the overseer as a
  decision question (`--type question --kind decision`) with the
  concrete reasons: what is prepared, what is missing, and the decision
  needed. Without an escalation recipient the gap stays fully visible
  in the conflict detail (an undeliverable report is still recorded,
  never silently dropped).
- `--dry-run` reports nothing: no readiness report, no escalation
  (zero effects includes ace-hitl events).

Result JSON (table renders the same fields):

```json
{
  "task": "8xg.t.sbz.3",
  "task_path": "/abs/.ace-tasks/8xg.t.sbz-lab…/",
  "roles": ["worker", "reviewer"],
  "worktree": { "path": "/abs/.ace-wt/t.8xg-t-sbz-3", "branch": "8xg-…", "disposition": "created" },
  "assignments": [
    {"role": "worker", "position": 1, "of": 2, "assignment": "abc123", "disposition": "created", "steps": 2, "outcome": "…"},
    {"role": "reviewer", "position": 2, "of": 2, "assignment": "def456", "disposition": "created", "steps": 1, "outcome": "…"}
  ],
  "start_configs": [
    {"role": "worker", "assignment": "abc123", "path": ".ace-local/coworker/prepare/worker.yml", "disposition": "created"},
    {"role": "reviewer", "assignment": "def456", "path": ".ace-local/coworker/prepare/reviewer.yml", "disposition": "created"}
  ],
  "active_executor": null,
  "worktree_assignments": [{"id": "abc123", "state": "paused", "progress": "0/2"}],
  "report": {"kind": "readiness", "event": "8xhkep", "delivered": true},
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
| `prepare` | worktree created/recovered/reused with the role-sequence assignments and per-leg start configs composed, readiness report sent (or recorded with its event id / failure); dry-run: would_create/would_recover, nothing composed, nothing reported | conflict (active_executor / mismatched_worktree / role_sequence / missing_overseer); invalid commission; operational preparation failure |
| `roles` | catalog rendered any valid state (including empty) | invalid preset file (specific error) |
| `rounds` | round recorded, verdict rendered (including escalate) | corrupt history; malformed record |
| `gate` | verdict rendered (`ready` or `blocked` - a withheld merge is a legitimate outcome) | malformed input (invalid or duplicate `--dep`, invalid `--tests` token) |
| `commission` | config written (dry-run: resolved, nothing written) | unknown role; invalid commission; task/assignment mismatch; refused overwrite; invalid assembly; config path escaping the project root; directory config target |

## Boundaries

- `.ace-local/coworker/` is owned by `ace-coworker`; `.ace-local/assign/` by
  `ace-assign`; `.ace-local/hitl/` by `ace-hitl`; `.ace-tasks/` by `ace-task`.
- No journal, queue, daemon, or second plan store (ADR-034).
- Delegation to `ace-assign` / `ace-nav` uses argv subprocess calls with an
  explicit working directory (ADR-031).
- Reporting via `ace-hitl` and resume-after-interruption ship with
  `ace-coworker` 0.4.0+; role presets resolve their `wfi://` instruction
  sources through `ace-nav` (runtime dependency since 0.5.0).
