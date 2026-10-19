# ace-coworker

Prepared executor for the file-based ACE lab: `ace-coworker` reads the run
configuration under `.ace-local/coworker/`, validates it against the real task
and assignment in the current worktree, and renders the executor brief that
pins the assignment to drive. It is a composition tool in the spirit of
`ace-overseer`: it owns **only** `.ace-local/coworker/` and composes the
existing owners (`ace-task` ref resolution, `ace-assign` lifecycle via its CLI,
`ace-hitl` reporting via its CLI) without copying their state or adding a
second queue, journal, or daemon (ADR-034).

This is the new L3 file-based coworker; the historical `ace-coworker` gem was
renamed to `ace-assign` at v0.6.0 and there is no compatibility with old
`.cache/ace-coworker` paths (ADR-024).

## Commands

```
ace-coworker start [--config PATH] [--format table|json]
ace-coworker status [--config PATH] [--assignment ID] [--format table|json]
ace-coworker report [--result success|error] [--message TEXT] [--no-send] [--dry-run]
ace-coworker resume [--dry-run]                # Resume interrupted work in this worktree
ace-coworker prepare --task REF --roles worker,reviewer [--to ADDR] [--dry-run]
ace-coworker roles                             # List role presets (gem + project)
ace-coworker commission --role worker --task REF --assignment ID --overseer ADDR
ace-coworker gate --candidate-head SHA --review-head SHA --review-verdict accept
                 --tests executed,passed --dep LEAF=integrated
```

- `prepare` — the planner side: accept a preparation commission (task +
  expected role sequence) and find or prepare exactly one proper worktree for
  the task. Re-preparation reuses the existing worktree with zero writes; an
  active executor or a mismatched worktree escalates a decision question to
  the overseer via `ace-hitl` instead of overwriting work.

- `roles` / `commission` — role presets and the role-instantiation primitive
  consumed by the planner (L4.2/L4.3 seam). Shipped presets: `worker`
  (implement and verify; failed required tests block success), `spec`
  (complete behavior-first specification; significant unresolved gaps are
  reported via `ace-hitl`, never guessed), and `reviewer` (independent
  review that fixes confirmed defects itself inside its own assignment,
  checks each fix diff, and returns to full review rounds under the 3/2/10
  convergence rule — escalating instead of marking unresolved High/Critical
  as success), and `integrator` (result-dependent integration: merges only
  candidates whose dependencies are integrated, whose head matches the
  reviewed head, whose tests were executed and passed, and whose fresh
  independent review verdict accepts the exact candidate; withheld merges
  are blocked and escalated, never merged past the gate), backed by the
  self-contained workflows `wfi://coworker/worker` / `wfi://coworker/spec` /
  `wfi://coworker/reviewer` / `wfi://coworker/integrator`. `roles` lists
  the catalog (gem defaults + project overrides in `.ace/coworker/roles/`);
  `commission` expands a preset plus the commission identity into
  `.ace-local/coworker/config.yml` — start-grade identity checks, atomic
  write, overwrite refused without `--force`, `--dry-run` renders without
  writing. Sequencing and active-driver guards stay with the planner.

- `gate` — the integrator role's deterministic pre-merge check
  (`Ace::Coworker::Atoms::IntegrationGate`): evaluates candidate head vs
  reviewed head (stale review), executed+passing tests, review verdict, and
  per-dependency integration states, and prints `ready` or `blocked` with
  per-check reasons. Pure and stateless — it decides readiness only; the
  integrator role drives git/ace-git. `blocked` is a legitimate gate outcome
  (exit 0); only invalid input fails.

- `start` — validate the prepared config (role, instructions, start prompt,
  task, assignment, overseer, error rules), verify the task resolves in this
  worktree and the assignment exists and matches the task, resolve the
  instruction source, and print the executor brief. Writes nothing. Missing or
  mismatched input fails with a specific `not ready:` / `invalid config:` /
  mismatch error — it never guesses another commission and never creates a
  substitute assignment or worktree.
- `status` — readiness query. Renders `not ready: .ace-local/coworker/config.yml
  not found` (exit 0) when unprepared, otherwise the resolved identity,
  assignment progress from `ace-assign status --format json`, and the
  completion verdict (`complete` only when the assignment state is completed,
  the plan is non-empty, and every step is done).

The config format consumed by the planner (L4) is documented in
[docs/usage.md](docs/usage.md).

## Development

Tests: `bin/ace-test ace-coworker all` from the repository root. See
[CONTRIBUTING](../docs/ace-gems.g.md) for gem conventions (ATOM architecture,
ADR-022 config cascade, dry-cli commands).

## License

MIT — see [LICENSE](../LICENSE).
