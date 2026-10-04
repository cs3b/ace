# Implementation step report — 8wq.t.k86.3

Generated 2026-10-04. `ace-task plan` stalled twice with no provider progress
(warning about missing `ace-overseer/test/e2e`, then silence; both attempts
killed). Proceeding under the documented fallback: task spec + reviewed
decisions + this step report. Planner stall follow-up recorded separately.

Ground truth studied before implementation: ace-runtime contract
(registry/selector/detector/errors/testing), tmux `RuntimeAdapter` +
`NativeRuntimeBackend`, herdr `RuntimeAdapter` public surface, consumer
sources (assign runner/launcher/fork_run, overseer opener/orchestrators,
demo recorder/executor, git-worktree create_command config, e2e
setup_executor), drive.wf.md callback rule, consumer gemspecs.

## Steps

1. **ace-assign** — contract-backed runner + launch modes
   - Rename `TmuxControlSurfaceRunner` → `RuntimeControlSurfaceRunner`
     delegating to an `Ace::Runtime` adapter (no direct `Ace::Tmux` calls).
   - Launch modes `auto|headless|tmux|herdr`; unknown value fails closed
     naming the valid list; `auto` = `Ace::Runtime.detect` (tmux first),
     headless only when nothing detected (assign-only rule).
   - Fork window naming via `Ace::Runtime.sanitize_name` (`-fs` suffix kept).
   - ensure/prepare/send/capture through the adapter; metadata becomes
     runtime-neutral (`launch_mode`, `runtime`, `session`, `window`,
     `window_id`, `pane`, `callback_pane`); tmux_* keys removed (ADR-024).
   - Subprocess env: `ACE_RUNTIME` + caller target context replaces
     `ACE_TMUX_SESSION` propagation (herdr children inherit HERDR_*).
   - `--callback` works under herdr (pane from adapter context).
   - drive.wf.md callback rule → `ace-runtime send --pane "$ACE_ASSIGN_CALLBACK_PANE" …`.
   - gemspec: + `ace-runtime`, keep `ace-tmux` (installs the adapter).
   - Tests: launch-mode matrix, both-runtime runner behavior over
     ScriptedRuntime-backed fake, callback pane resolution, metadata shape.

2. **ace-overseer** — contract window open/close + neutral config key
   - `TmuxWindowOpener` → `WindowOpener` using adapter `ensure_window`
     (sanitized worktree basename, worktree root, preset passthrough).
   - Runtime selection: explicit `runtime:` config key (`tmux|herdr|auto`);
     `auto`/unset detects via the contract detector; nothing detected →
     explicit error (overseer has no headless fallback).
   - `tmux_window_presets` → `window_presets` (no legacy alias) in config
     default, orchestrator dig, docs.
   - Prune closes the worktree window via contract `close_window`; terminal
     cleanup failure never fails the prune (rescue preserved).
   - "Opening tmux window..." → runtime-neutral text.
   - gemspec: + `ace-runtime`, keep `ace-tmux`.
   - Tests: window open/close via contract on fake adapters for both
     runtimes; preset key; error paths.

3. **ace-demo** — contract directive execution
   - `TmuxDirectiveExecutor` → `RuntimeDirectiveExecutor`: `wait` maps the
     four lifecycle conditions to `wait_lifecycle`; `send` maps
     command/key to adapter send; YAML envelope key unchanged (spec does
     not rename demo YAML; attach/detach stay tmux-local).
   - Runtime per directive (`runtime:` key) > `ACE_RUNTIME` env > detect;
     attach/detach under non-tmux runtime → explicit unsupported error.
   - gemspec: + `ace-runtime`, keep `ace-tmux`.
   - Tests: four lifecycle conditions against BOTH adapters (shared
     examples), send shapes, attach/detach guard.

4. **ace-git-worktree** — neutral terminal open
   - Config key `tmux` → `terminal` (boolean, no alias; ADR-024) in
     worktree_config, config provenance, defaults/docs.
   - `launch_tmux_or_display_cd` → `open_terminal_or_display_cd`: resolve
     runtime (ACE_RUNTIME > ace-runtime config > detect), inside a runtime
     open a window/tab rooted at the worktree via contract `ensure_window`;
     outside any runtime → cd hint. Herdr explicit never launches tmux.
   - gemspec: + `ace-runtime`, keep `ace-tmux`.
   - Tests: config rename, runtime resolution, root/cwd preservation,
     herdr-explicit negative control.

5. **ace-test-runner-e2e** — runtime-aware setup step
   - `tmux-session` step → `runtime-session` (tmux: detached session as
     today exporting ACE_TMUX_SESSION; herdr: requires live HERDR_* env,
     fails explicitly when absent — no scripted stand-in). Scenario YAML +
     template + orchestrator transient-step list updated. No gemspec
     change: this package only plumbs environment, it never loads the
     contract itself; scenario sandboxes resolve runtimes through the
     installed consumer gems.
   - Tests: step behavior for both runtimes + absent-backend failure.

6. **Verification** — `ace-test` on all five packages, then `ace-test-suite`;
   tmux regression gate (zero behavior change) + both-runtime fixture
   matrix (absent/unknown backend, callback exactly once, context
   propagation, worktree tab open, accepted prune).

7. **Delivery** — independent review, version bumps, PR. Acceptance/merge
   gated on 8x1.t.hym per the 2026-10-04 spec note; live-herdr consumer
   acceptance is a Lab gate, not a unit gate.

## Out of scope (spec)
- Contract/adapter changes (k86.0–k86.2 done; hym owns the herdr repair).
- Forge behavior in git-worktree (qk1.0), runtime=lab engine removal (qk0).
- No backward-compat shims anywhere (ADR-024).
