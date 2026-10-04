---
doc-type: user
title: ace-overseer Usage
purpose: Full CLI reference for ace-overseer commands and options.
ace-docs:
  last-updated: 2026-08-30
  last-checked: 2026-08-30
---

# Usage

## Command Surface

- `ace-overseer work-on`
- `ace-overseer status`
- `ace-overseer prune`
- `ace-overseer projects`
- `ace-overseer agents`
- `ace-overseer prepare`
- `ace-overseer prompt`
- `ace-overseer review`
- `ace-overseer stop`

## `ace-overseer work-on`

Create or reuse task worktrees, open tmux windows, and prepare assignments.

Invocation: `ace-overseer work-on --task <task-ref>`.

Options:

- `--task`, `-t` (required for tmux): task reference(s); repeatable and comma-separated values supported
- `--preset`, `-p`: assignment preset name
- `--runtime`: `tmux` (default) or `lab`
- `--work`: existing Lab Work ID; required with `--runtime lab`
- `--agent`: configured Lab agent ID; required with `--runtime lab`
- `--quiet`, `-q`: suppress non-essential output
- `--debug`, `-d`: show debug output
- `--help`, `-h`: show help

Internally, `work-on` now routes assignment creation through `ace-assign create --task ...`, so direct `ace-assign` and `ace-overseer` task flows use the same preset expansion behavior.

## `ace-overseer status`

Show status for active task worktrees.

Invocation: `ace-overseer status [--format table|json] [--watch]`.

Options:

- `--format`: output format (`table`, `json`)
- `--watch`, `-w`: auto-refresh dashboard
- `--runtime`: `tmux` (default) or `lab`
- `--project`: filter Lab Works by project
- `--quiet`, `-q`: suppress non-essential output
- `--debug`, `-d`: show debug output
- `--help`, `-h`: show help

## `ace-overseer prune`

Remove stale or completed task worktrees.

Invocation: `ace-overseer prune [TARGETS] [OPTIONS]`.

Arguments:

- `TARGETS`: optional task refs or folder names to prune

Options:

- `--assignment`, `-a`: prune a specific assignment by ID
- `--force`, `-f`: skip the interactive confirmation for already-safe candidates; never bypasses preservation, dirtiness, lifecycle or revalidation blocks
- `--yes`, `-y`: skip interactive confirmation
- `--dry-run`: run the same proof classification as apply, changing no worktrees, refs, assignment state or metadata (a dry-run receipt is not reusable authorization)
- `--preservation FILE`: YAML manifest (`version: 1`, `candidates:`) declaring cross-repository destinations for migrated work; a claim to verify, never proof by itself
- `--runtime`: `tmux` (default) or `lab`
- `--quiet`, `-q`: suppress progress output; blocked/failed results still print and signal through the exit code
- `--debug`, `-d`: show debug output
- `--help`, `-h`: show help

### Prune safety (enforced)

Every candidate is deleted only after executed proofs; missing, failed or
ambiguous evidence preserves the candidate, and `--force`/`--yes` never
override a block:

- Preservation: source HEAD is contained in the surviving accepted base branch, or a declared destination is verified -- accepted on its surviving destination branch -- with full-tree equality or an exact content transition (paths, modes, symlinks, binary content) across separate bases. Patch-range proofs additionally require the independently recorded attempt baseline, and that baseline itself must survive on an accepted ref.

- No active writer: recorded attempts must be terminal (active or uncertain attempts block; unreadable attempt state blocks); assignment/driver/start paths and prune share a durable exclusion that survives removal of the target, so no second writer can enter during deletion; dirty tracked or untracked files are work and block deletion, even with `--force`.

- Assignment cache: cleanup removes only the assignment cache directory after the durable journal evidence (`refs/ace/execution`, never deleted) confirms every attempt terminal; the journal checkout is never removed.

- Exit codes: dry-run always exits 0 (blocked candidates are listed); apply exits nonzero when any selected candidate is blocked or removal fails, while independent safe candidates still complete.

- Unmatched explicit targets are errors; empty automatic selection is a no-op; cancelled confirmation deletes nothing.

## Example Flows

Start task work: `ace-overseer work-on --task 8q4.t.umu.1`.

Check dashboard: `ace-overseer status`.

Preview then prune: `ace-overseer prune --dry-run`, then `ace-overseer prune --yes`.

## Terminal Runtime Configuration

Work-on opens the task's terminal window and prune closes it through the
runtime-neutral `ace-runtime` contract. Select the terminal runtime in
`.ace/overseer/config.yml`:

```yaml
# tmux | herdr | auto (default) — auto detects tmux first, then herdr;
# ACE_RUNTIME env wins over this key; nothing detected fails explicitly
runtime: auto
window_presets:
  "work-on-task": "work-on-task"   # preset applied to the opened window/tab
```

The preset key is `window_presets` (renamed from `tmux_window_presets`
pre-1.0; there is no legacy alias). The same configured runtime closes a
worktree's window during accepted prunes.

Prune migrated work with a declared destination:

```bash
mkdir -p .ace-local/prune
cat > .ace-local/prune/destinations.yml <<'YAML'
version: 1
candidates:
  - worktree_path: /abs/path/.ace-wt/task.230
    source_repo: /abs/path
    source_base: <base-sha>
    source_head: <head-sha>
    destination_repo: /abs/successor
    destination_base: <dest-base-sha>
    destination_head: <accepted-head-sha>
    destination_branch: refs/heads/main
YAML
ace-overseer prune task.230 --preservation .ace-local/prune/destinations.yml --dry-run
```

## Lab Runtime

Lab commands are available only where `/usr/local/bin/lab` is installed. ACE
does not read Lab credentials and does not call Podman or Herdr directly.

- `ace-overseer projects`: list registered Lab projects.
- `ace-overseer agents`: list registered Lab agents and concurrency limits.
- `ace-overseer prepare --runtime lab --project PROJECT --source KIND:ID --work WORK --planner AGENT --title TITLE`: create a reviewed Work and its isolated worktree.
- `ace-overseer work-on --runtime lab --work WORK --agent AGENT`: reserve the agent, create or reuse its Herdr workspace, and dispatch it.
- `ace-overseer status --runtime lab [--project PROJECT] [--format table|json]`: show Lab Work state. Continuous status lives in each project Herdr session, so `--watch` is intentionally rejected for Lab.
- `ace-overseer prompt --work WORK --file PATH`: forward prompt text from a file to the Work pane. Piped stdin is also supported; prompt text is never passed as a process argument.
- `ace-overseer review --work WORK --pr NUMBER`: prepare an exact-head admin review checkout and pane.
- `ace-overseer stop --work WORK`: stop the assigned process without destroying Work state.
- `ace-overseer prune WORK... --runtime lab --dry-run`: classify each Work -- documented terminal state, no in-flight work, and preservation data (`repo`/`head`/`branch`) provable in the hosted repository. Apply with `--yes` re-verifies state immediately before delegating each destruction to `lab work destroy WORK --confirm`; blocked Works are never destroyed and the run exits nonzero. The raw Lab CLI cannot make the state check and the destruction atomic, so this adapter reports the path unsupported and preserves the Work; only a Lab surface with an atomic guarded destroy delegates.

Example:

```bash
ace-overseer prepare --runtime lab --project nervus \
  --source nervus-thread:67611c0b-f44c-4ac4-ae4e-55773b175617 \
  --work W321 --planner admin-agy --title "Reviewed task title"
ace-overseer work-on --runtime lab --work W321 --agent builder-codex
ace-overseer prompt --work W321 --file .ace-local/prompts/W321.md
ace-overseer status --runtime lab --project nervus --format json
```

## Public Verification Paths

Use these user-visible checks when validating behavior end-to-end:

- Preset override path:

  1. `ace-overseer work-on --task <task-ref> --preset <preset-name>`
  2. `ace-git-worktree list` (confirm worktree exists for `<task-ref>`)
  3. `ace-overseer status --format json` (confirm the task appears with assignment/preset details)

- Idempotent rerun oracle:

  1. Run `ace-overseer work-on --task <task-ref>` twice
  2. Verify one task entry remains in `ace-overseer status --format json`
  3. Verify only one matching worktree exists in `ace-git-worktree list`

- Prune lifecycle minimal flow:

  1. `ace-task done <task-ref>`
  2. `ace-overseer prune --dry-run`
  3. `ace-overseer prune --yes`
  4. `ace-git-worktree list` to confirm removed vs retained task worktrees
  5. `ace-overseer prune --dry-run` to confirm no remaining safe candidates

Assignment JSON includes `recovery`: current liveness, recovery decision/reason, last verified observation, exact attempt identities, checkpoints and unresolved effect/inbox references. Unreadable evidence is explicitly unknown; dashboard rows needing reconciliation use a question mark instead of a success indicator. An older verified observation remains audit history and does not make a current unknown observation live.
