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

Without `--project`, create/reuse local worktrees and prepare assignments.
With `--project`, prepare exactly one reviewed leaf and retain its original
foreground protected launcher; no local fallback occurs on protected refusal.

- `--task`, `-t`: local repeatable/comma-separated task refs; protected mode requires one leaf.
- `--preset`, `-p`: local assignment preset; forbidden in protected mode.
- `--runtime`: terminal backend `auto`, `tmux` or `herdr`; overrides existing config. Protected tmux refuses before allocation.
- `--project`: explicit protected project ID.
- `--agent`: exact visible protected mapping ID, requiring project. Automatic selection is ordered and advances only after attributable readonly preflight denial.
- `--mutation`: stable invocation ID; otherwise generated once and printed before effects.
- `--base-head`: optional explicit reviewed code HEAD; must match the captured source HEAD, which is rechecked after preparation and before fork.
- `--dependency-report`: repeatable `task:assignment:step` identities for selected dependency reports; omission is an explicit empty selection.
- `--recover-request FILE`: readonly original canonical attribution from retained inputs; rejects all launch/mode overrides.
- `--quiet`, `-q`: suppress nonessential output; retained input identity and original child observation remain visible.
- `--debug`, `-d`, `--help`, `-h`: diagnostics/help.

Fresh protected start exclusively publishes private request JSON, derived exact
definition sidecar and original prepared Git bundle, then prints their paths and
hashes before any child. Missing/corrupt input or changed code HEAD refuses.
The living coordinator retains and observes the same original child through
readiness/uncertainty without a lifetime timeout, replacement or cancellation.
The fixed launch driver uses one 30-second phase budget; each protocol call
receives only the remaining time. The parent separately retains its earlier
30-second total readiness deadline, including CLI input reads and canonical
ready verification; neither deadline refreshes. Late readiness preserves the
same original child as uncertain, without a retry or replacement.

Use independent status/steering while it remains foreground. Reap is local
observation, never canonical terminal/release or physical cleanup permission.
Recovery reports absent/mismatched local inputs separately from original canonical
reservation attribution, without upload, reconstruction or retry.

## `ace-overseer status`

Show status for active task worktrees.

Invocation: `ace-overseer status [--format table|json] [--watch]`.

Options:

- `--format`: output format (`table`, `json`)
- `--watch`, `-w`: auto-refresh dashboard
- `--runtime`: local backend selection; protected inventory is runtime-independent
- `--project`: select protected canonical assignment inventory for this explicit project
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

## Protected execution and review

The existing Assign authority and installed mapping grant admit execution. Public
topology supplies visible IDs only. Runtime names and charter selection cannot
change OS credentials, grants or reviewer identity.

```bash
ace-overseer work-on --task TASK --project ace --agent builder --runtime herdr
ace-overseer status --project ace --agent builder --format json
ace-overseer work-on --recover-request .ace-local/overseer/launch-requests/INVOCATION.json
```

Retain the printed input paths/hashes and original mapping/invocation. Missing
readiness, lost output, child exit or pane state never authorize replacement or
physical cleanup. Recovery is strictly read-only. Protected physical cleanup
requires its designated preservation/no-writer owner.

- `ace-overseer review --project PROJECT --agent AGENT --assignment A --attempt T --head HEAD --candidate-generation N --expected-generation G --mutation REQUEST --accept-mutation ACCEPT`: request independent review of the exact canonical candidate and submit its executed receipt. Run under the installed reviewer principal. `accepted` means the authority accepted that receipt; `uncertain` requires explicit status inspection.
- `ace-overseer review --status --project PROJECT --agent AGENT --assignment A --attempt T --mutation REQUEST`: inspect the original request without rerunning review or uploading anything.
- `ace-overseer review --cancel --project PROJECT --agent AGENT --assignment A --attempt T --head HEAD --candidate-generation N --review-event EVENT --expected-generation G --mutation CANCEL`: revoke the exact reservation using its status-provided event. Cancellation does not terminate the old reviewer. After cancellation, start a new review explicitly with new mutation IDs and the observed generation.

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
