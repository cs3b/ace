---
id: 8wq.t.1qb
status: in-progress
priority: medium
created_at: "2026-09-27 01:09:15"
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: []
  commands: []
tags: [ace-review, review-rounds, observability]
github_issue: 335
---

# Improve ace-review round efficiency and usage observability

## Objective

Reviewing PR cs3b/st-nervus-chat#171 took 14 review rounds across 13 heads (~1h39m of
model time on pi/glm-5.3) plus 13 release-check runs (~2h), and a ~3.9M-token cycle went
entirely unmeasured because the pi client does not surface token usage. Rounds 3–10
reviewed nearly unchanged diffs, and format/docs-only deltas still consumed full model
reports. This family makes review rounds cheaper (delta rounds, exempt-path scopes),
makes oversized-diff behavior real or honest (chunk strategies), and makes token cost
visible (pi usage reporting). Source: cs3b/ace#335 §2–§5 (adoption blocker §1 shipped
separately as ace-git-worktree v0.23.0).

## Expected Behavior

After this family lands, an operator reviewing an evolving PR experiences:

- Review rounds can be scoped to what changed since a known head, with prior review
  sessions carried forward as evidence instead of re-reviewing unchanged files.
- Trivial deltas (format-only, docs-only) can be accepted as review-exempt evidence
  without spending a model call.
- Reviewing a large PR behaves as documented: either the diff is split into
  budget-sized packets with findings merged, or the system refuses oversized diffs
  loudly and the dead configuration is gone.
- Session reports show real per-model token usage (input/output/cached) instead of
  "usage unavailable" estimates when running through pi.

## Vertical Slice Decomposition (task/subtask model)

Orchestrator `8wq.t.1qb` owns the umbrella outcome and decomposition map only.

| Slice | Outcome (end cap) | Size | Notes |
|---|---|---|---|
| `8wq.t.1qb.0` | Delta review mode scopes a round to diffs since a reference head with carry-forward evidence | medium | Highest time savings (~40 min on PR 171); independent of other slices |
| `8wq.t.1qb.1` | Exempt-path deltas are accepted as no-op review evidence without model calls | small | Builds on session/evidence model used by .0 |
| `8wq.t.1qb.2` | Oversized diffs are either chunked into budget-sized packets or refused honestly; dead config removed | medium | Decision (wire vs remove) is part of the slice |
| `8wq.t.1qb.3` | pi-sourced sessions record real per-model token usage | small | Touches pi client integration; independent |

Ordering: `.0` first (validates the riskiest path — session carry-forward), then `.1`
(reuses its evidence model). `.2` and `.3` are independent and may proceed in any order.

## Success Criteria

- Each subtask independently delivers its observable end cap on main.
- A PR review loop like PR 171 completes with measurably fewer full-diff model rounds
  and the token cost of the loop is visible in session reports.
- No slice leaves documented-but-unreachable configuration behind.

## Out of Scope

- Implementation details: file layout, class design, library choices (decided at
  replan/work time per slice).
- Issue §1 (gem compatibility) — resolved by the ace-git-worktree v0.23.0 release.
- Any change to review verdict semantics (what counts as Critical/High).

## References

- GitHub issue: https://github.com/cs3b/ace/issues/335 (§2–§5)
- Context motivating the family: PR cs3b/st-nervus-chat#171 retro (170 extracted
  findings, ~62% repeats/polish, ~28% converted to changes)
