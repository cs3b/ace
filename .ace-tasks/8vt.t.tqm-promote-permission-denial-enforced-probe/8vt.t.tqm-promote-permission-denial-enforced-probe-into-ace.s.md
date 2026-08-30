---
id: 8vt.t.tqm
status: pending
priority: medium
created_at: "2026-08-30 19:49:35"
estimate:
dependencies: []
tags: [ace-support-test-helpers, ace-support-config, testing, containers]
---

# Promote permission_denial_enforced? probe into ace-support-test-helpers

## Objective

Extract the empirical `permission_denial_enforced?` probe (added in PR #9 /
commit 75a338742 for task `8vt.t.rtr.2`) from
`ace-support-config/test/feat/config_cascade_edge_test.rb` into
`ace-support-test-helpers`, and adopt it everywhere chmod-based permission
tests exist.

## Background

Clean-context review of `8vt.t.rtr.2` (W404) observed that
`ace-support-config/test/fast/molecules/project_config_scanner_test.rb`
still guards its permission test with the weaker `Process.uid.zero?` check.
UID-only guards miss non-root processes granted `CAP_DAC_OVERRIDE` (common
in hardened CI containers) and vacuously pass where denial cannot be
produced. The empirical probe (temp file, `chmod 0000`, attempt read, with
`NotImplementedError`/`SystemCallError` treated as untestable) is strictly
more correct.

## Scope of Work

- Move `permission_denial_enforced?` into `ace-support-test-helpers`
  (e.g. a `TestCase` assertion/helper module) with the same semantics as
  the probe merged in PR #9.
- Replace the `Process.uid.zero?` guard in
  `ace-support-config/test/fast/molecules/project_config_scanner_test.rb`
  with the shared probe.
- Sweep other packages for `chmod(0o000)`-based permission tests using
  UID-only guards (e.g. `ace-git-worktree/test/fast/atoms/path_expander_test.rb`)
  and adopt the shared probe.

## Out of Scope

- Any production (`lib/`) behavior change; error taxonomy unchanged.

## References

- Origin: clean-context review finding, task `8vt.t.rtr.2` (Work W404)
- Precedent guards: `ace-git-worktree/test/fast/atoms/path_expander_test.rb:98`,
  `ace-support-config/test/fast/molecules/project_config_scanner_test.rb:316`
