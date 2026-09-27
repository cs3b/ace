---
id: 8wq.t.k84
status: draft
priority: high
created_at: "2026-09-27 13:29:01"
estimate: TBD
dependencies: [8wm.t.vs0]
tags: [ace-herdr, ace-tmux, parity, cli]
bundle:
  presets: ["project"]
  files:
    - ace-tmux/lib/ace/tmux/cli.rb
    - ace-tmux/lib/ace/tmux/organisms/control_surface.rb
    - ace-tmux/lib/ace/tmux/molecules/preset_loader.rb
    - ace-herdr/lib/ace/herdr/cli.rb
    - ace-herdr/lib/ace/herdr/molecules/herdr_executor.rb
    - ace-herdr/docs/usage.md
    - .ace-tasks/8wm.t.vs0-ace-herdr-push-delivery-agent/8wm.t.vs0-ace-herdr-push-delivery-agent-bootstrap-deliver.s.md
  commands: []
---

# ace-herdr: match ace-tmux CLI and API intents (list, send, capture, wait, presets)

## Behavioral Specification

### User Experience

- **Input**: users and agents run `ace-herdr` commands with the same intent
  vocabulary they already know from `ace-tmux` (`list`, `send`, `capture`,
  `wait`, preset-driven creation) plus herdr-native targets (pane ids from
  `HERDR_PANE`/JSON output, `--workspace`).
- **Process**: each command resolves its target, calls the corresponding
  native herdr capability, and reports one deterministic JSON line (existing
  vs0 convention); `--quiet` suppresses success chatter; failures surface
  herdr's machine error codes.
- **Output**: parity of INTENT and FLAG VOCABULARY — not byte-format parity
  with ace-tmux's human tables. ace-herdr keeps one-line JSON; ace-tmux keeps
  its tables. Explicit default, see Validation Questions.

### Expected Behavior

Every common terminal-control intent available through `ace-tmux` is
available through `ace-herdr`, backed by the native herdr capability
(parity matrix, herdr 0.9.1):

1. **`ace-herdr list`** — inspect live state.
   `--panes` (default; `pane list --workspace`), `--tabs` (`tab list`,
   ≈ tmux `--windows`), `--workspaces` (`workspace list`, ≈ tmux
   `--sessions` under the mapping tmux session → herdr workspace; herdr
   *sessions* are an orthogonal server-persistence concept and are NOT
   exposed here). `--workspace <id>` scopes tabs/panes. Full-tree listing
   may be served by a single `api snapshot`.
2. **`ace-herdr send`** — `--cmd <text>` → `pane run` (atomic text+Enter),
   `--msg <text>` (repeatable) → `pane send-text`, `--key <name>`
   (repeatable) → `pane send-keys`. **Agent-aware rule**: when the target
   pane hosts a live agent, text sends route to `agent prompt` semantics
   (pre-send `agent_blocked` rejection, `agent_prompt_stalled` activity
   gate) instead of raw keystrokes — herdr-native, replacing ace-tmux's
   INTERACTIVE_CLI_COMMANDS/busy-pattern heuristics.
3. **`ace-herdr capture`** — `--pane`, `--lines` (default 40), `--source
   visible|recent` (≈ ace-tmux's interactive-CLI capture vs history tail)
   → `pane read`. Raw pane text out; `--source recent` default for shells.
4. **`ace-herdr wait`** — existing agent-state wait unchanged; adds
   `--for output --pattern <text|regex>` → `pane wait-output`
   (`--timeout` seconds, gem converts to ms). Output is checked against
   existing content immediately, then polled — same observable contract as
   `ace-tmux wait --for output`.
5. **Preset-driven creation** — declare a workspace or tab layout in YAML
   (`.ace-defaults/herdr/{workspaces,tabs}/*.yml` gem defaults, overridden
   via the ADR-022 cascade `.ace/herdr/`, `~/.ace/herdr/`); one command
   creates it (`ace-herdr workspace <preset>` / `ace-herdr tab <preset>`,
   mirroring `ace-tmux start`/`window`); `--list-presets [type]` lists
   available presets. Presets compose (`preset:` refs, deep-merge) and
   may declare pane splits, `--cwd`, labels, focus, per-pane commands,
   and agent kinds (an agent pane in a preset = `agent start` after
   readiness, reusing vs0 bootstrap behavior).
6. Existing `deliver` / `dispatch` / `close` semantics are unchanged.

### Interface Contract

```bash
ace-herdr list [--panes|--tabs|--workspaces] [--workspace ID] [--quiet]
# {"panes":[{"id":"w1:p1","tab":"w1:t1","workspace":"w1","title":...},...]}

ace-herdr send (--cmd TEXT | --msg TEXT... | --key NAME...) --pane ID [--quiet]
# {"pane":"w1:p3","sent":"cmd"} — agent pane: {"pane":...,"sent":"prompt"}

ace-herdr capture --pane ID [--lines N] [--source visible|recent]
# raw pane text on stdout

ace-herdr wait --pane ID (--for output --pattern PATTERN | --for agent [--until idle,done,blocked]) [--timeout S] [--quiet]
# {"pane":"w1:p3","state":"ready"} (agent form keeps existing output)

ace-herdr workspace <preset> [--cwd PATH] [--quiet]   # ≈ ace-tmux start
ace-herdr tab <preset> [--workspace ID] [--cwd PATH] [--quiet]  # ≈ ace-tmux window
ace-herdr --list-presets [workspaces|tabs]
```

**Error Handling:**
- Unknown pane/tab/workspace: CLI error carrying herdr's code (e.g. `pane_not_found`), exit non-zero.
- herdr binary/socket unavailable: explicit CLI error, no partial output.
- Unknown preset: CLI error listing available presets (ace-tmux `--list-presets` parity).
- `send` to a blocked agent: terminal CLI error carrying `agent_blocked` (never silently dropped).

**Edge Cases:**
- Repeatable `--msg`/`--key` sent in declaration order (ace-tmux parity).
- `capture` on an agent pane: `--source visible` shows the agent screen; text routing rules do not apply (read-only).
- Empty workspace (`list --panes` with no panes): success with empty array, not an error (explicit empty state).
- Preset referencing a missing nested preset: fail closed with the missing name.

### Success Criteria

- [ ] **Intent coverage**: every parity-matrix common intent (list ×3 scopes, send ×3 modes, capture, wait output) is runnable via an `ace-herdr` command with the ace-tmux flag vocabulary.
- [ ] **Agent-aware send**: text sent to a plain pane uses pane transport; the same flags against an agent pane use agent-prompt semantics — both observable in output `sent` field and covered by tests.
- [ ] **Preset cascade**: gem defaults deep-merged with project `.ace/herdr/` overrides; `--list-presets` reflects the merged set.
- [ ] **Failure paths**: unknown target, unavailable binary, blocked agent, unknown preset each produce the specified errors.
- [ ] **No regressions**: `deliver`/`dispatch`/`wait`(agent)/`close` behavior and output unchanged; whole-package suite green.
- [ ] **Published parity table**: `docs/usage.md` gains the tmux-intent ↔ herdr-command mapping table.

### Validation Questions

- [ ] **Requirement Clarity**: confirm this task absorbs the "wrapper" half of 8wq.t.1w0 (rescoped to tidy-only) — no duplicate wrapper work.
- [ ] **Output format**: confirm JSON-lines stance (intent parity, not format parity); flag if consumers need `--format table`.
- [ ] **Preset naming**: `workspaces`/`tabs` (herdr-native) vs `sessions`/`windows` (tmux-parity naming) — default herdr-native.
- [ ] **Success Definition**: is `api snapshot` acceptable as the backing call for `list`, or must each scope use its dedicated subcommand?

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Standalone task (one capability family: grow the ace-herdr CLI to intent parity; consumer integration is Task 8wq.t.k86).
- **Slice Outcome**: the full common-intent vocabulary works over herdr, documented and tested.
- **Advisory Size**: medium
- **Context Dependencies**: bundle.files above (read-only references to ace-tmux's surface as the parity oracle).

### Verification Plan

#### Unit / Component Validation
- [ ] Per-intent scenarios via fake executor (vs0 pattern): argv construction, JSON shape, target resolution.
- [ ] Agent-aware routing: plain pane vs agent pane with identical flags.
- [ ] Preset cascade: defaults + override deep-merge; unknown nested preset fails closed.

#### Integration / E2E Validation (if cross-boundary behavior exists)
- [ ] Live-herdr smoke of each new command (manual/scripted; full e2e scenarios remain a declared follow-up).

#### Failure / Invalid-Path Validation
- [ ] `pane_not_found`, unavailable binary, `agent_blocked`, unknown preset — one per command family.

#### Verification Commands
- [ ] `ace-test ace-herdr` — whole package green (single-file mode unsupported).
- [ ] `ace-herdr --list-presets` after adding a project preset — merged set listed.

## Objective

Make `ace-herdr` a complete wrapper over the herdr runtime — the same
position `ace-tmux` holds for tmux — so agents and developers can operate
either terminal runtime with one learned intent vocabulary. This is the
foundation for 8wq.t.k86 (runtime-switchable consumers), which requires
these intents to exist on both sides before assign/overseer/demo can
choose herdr as an equal partner.

## Scope of Work

- **User Experience Scope**: list/send/capture/wait/output-wait intents; preset-driven workspace/tab creation; unchanged vs0 commands.
- **System Behavior Scope**: agent-aware send routing; preset cascade; deterministic JSON output; typed error surfacing.
- **Interface Scope**: `ace-herdr` CLI additions only (public Ruby API normalization is 8wq.t.k86's contract, not this task's).

### Deliverables

#### Behavioral Specifications
- Command/flag contract per intent (above)
- tmux-intent ↔ herdr-command parity table in `docs/usage.md`

#### Validation Artifacts
- Test scenarios per intent incl. failure paths
- Draft usage scenarios in `ux/usage.md`

## Out of Scope

- ❌ **Implementation Details**: executor method shapes, snapshot-vs-dedicated-subcommand choice, preset YAML schema internals (replan decides).
- ❌ **attach/detach**: no herdr automation equivalent; human-facing.
- ❌ **tmux layout strings** and `select-layout` presets (herdr has split/resize only).
- ❌ **Consumer integration** (assign/overseer/demo switching) — Task 8wq.t.k86.
- ❌ **Output byte-parity** with ace-tmux tables.
- ❌ **e2e scenario suite** against live herdr (follow-up task).

## References

- Usage documentation: `ux/usage.md` (draft usage scenarios)
- Parity source: ace-tmux `cli.rb`, `organisms/control_surface.rb`, `molecules/preset_loader.rb`
- Foundation: 8wm.t.vs0 (ace-herdr push delivery + bootstrap, delivered surface: deliver/dispatch/wait/close)
- Sibling tasks (coordinate, different concerns): 8wm.t.y23 (queue migration), 8wm.t.vs2 (provider=lab integration)
