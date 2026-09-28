# Implementation report: 8wq.t.1w4 (2026-09-28)

Implemented in worktree `.ace-wt/8wq-t-1w4-ace-lab`, branch `8wq-t-1w4-ace-lab`.
PR: https://github.com/cs3b/ace/pull/341 (branch `8wq-t-1w4-pr`, also pushed to
`fg`). Task left `in-progress` for final delivery.

## Evidence

- `ace-test ace-lab all`: 146 tests, 488 assertions, 0 failures, 0 errors,
  1 skipped (last run 8wrvwd). The skip is the root-gated installed-CLI
  success scenario (`ACE_LAB_TEST_SYSTEM_GRANTS=1` on a disposable root host).
- `standardrb lib test exe`: clean; `ace-lint` markdown/yaml: no errors
  (Keep-a-Changelog link-definition warnings are the repo baseline).
- Fresh install (SC2/SC3): builds the gem plus the full workspace dependency
  closure (BFS over gemspec runtime deps), installs into an isolated
  `GEM_HOME`, probes that the packaged code — not workspace code — serves
  the CLI, and asserts host-state-tolerant contracts (one JSON document,
  exit-status correlation, redaction) plus deterministic
  `invalid_configuration` for a deliberately broken topology. The packaged
  lib contains no `/usr/local/bin/lab` reference.
- SC1: duplicate IDs (across and within categories), missing project refs,
  stale/mismatched attestation facts, and multiple capable services covered
  in schema/loader/router tests.

## Independent review (codex:astra:high, 17 rounds, converged)

PR #341 was reviewed with `ace-review --preset code-valid --model
codex:astra:high` in an iterative loop; every round's findings were fixed
with regression tests until round 18 returned zero findings. Security-relevant
hardening that came out of the loop:

- Authorization grants come ONLY from the deployment-controlled file at the
  fixed path `/etc/lab/ace-lab/authorization.yml` (root-owned, not
  group/world-writable — every traversed element verified per hop, symlinks
  ownership-checked, O_NOFOLLOW open, per-query reload). Cascade documents
  carrying an `authorization` section are rejected. (Rounds 4-9)
- Hidden and nonexistent IDs are indistinguishable (`missing`); unauthorized
  resolution discloses nothing. (Rounds 3, 6)
- Configuration defects are value-free, positional-field error messages;
  malformed collections/URLs/ports/binding kinds are rejected at schema
  load. (Rounds 2, 3, 4, 9)
- Exactly one `default_for` may win; conflicting defaults classify
  `ambiguous`. Granted-but-absent projects classify `missing`, never an
  empty inventory. (Rounds 1, 17)
- Model strings are defensively frozen element-wise; grants re-derive per
  query (revocation applies to reused services). (Rounds 6, 15, 16)

## Commits

Task branch (authoring history): ceeb8b636, 115cde4c8, 8ffd76858, b72c01f6a,
52da69acf, 7232a8f80, 3e81b5451 + review-fix commits b51a6e949, 91ded63c0,
d3fa1b38f, 5d6f1c999, a435ba271, 7df22a1de, 54d78daa0, 01714a0a3, f76b2299b,
81b060001, 5ba844e77, 3a8babf6c, 4688bac09, dd7dded31, 965b7f1b8, 346d7d4e3,
e64f792f2. PR branch `8wq-t-1w4-pr` carries cherry-picked equivalents off
`origin/main` (no unrelated commits). ceeb8b636/115cde4c8 also sit on local
`main` (created before the worktree move; main was not rewritten because
unrelated concurrent commits landed on top).

## Scope notes

- No changes to `ace-overseer` `lab_client.rb`, `ace-herdr`
  `delivery_record.rb`, or `lab-config` (deployed values remain `8wl.t.gad`).
- Contract note: the grants channel (trusted fixed-path file) is a
  security-driven refinement of the plan's example schema; deployed topology
  ownership stays with lab-config, which will provision the grants file.
