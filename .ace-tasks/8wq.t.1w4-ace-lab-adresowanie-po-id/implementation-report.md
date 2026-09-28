# Implementation report: 8wq.t.1w4 (2026-09-28)

Implemented in worktree `.ace-wt/8wq-t-1w4-ace-lab`, branch `8wq-t-1w4-ace-lab`.
Status: plan complete (STEP-01..06), all SCs pass, task left `in-progress` for
final delivery.

## Evidence

- `ace-test ace-lab all`: 100 tests, 347 assertions, 0 failures, 0 errors
  (last run 8wrsyy).
- `standardrb lib test exe Rakefile`: clean; `ace-lint` markdown/yaml: no
  errors (Keep-a-Changelog link-definition warnings are the repo baseline).
- Fresh install (SC2/SC3): `gem build ace-lab.gemspec` → install into isolated
  `GEM_HOME` → packaged `bin/ace-lab` serves `resolve`/`route` from an
  isolated project using `test/fixtures/lab/sanitized_topology.yml`; packaged
  lib contains no `/usr/local/bin/lab` reference; endpoint secrets never
  appear in output; pane replacement (`instance_id` swap) keeps stable ID
  `atlas-planner` and classifies the replaced binding `stale` until
  re-attested, then `available`.
- SC1: duplicate IDs (across and within categories), missing project refs,
  stale/mismatched attestation facts, and multiple capable services are
  covered in `test/atoms/topology_schema_test.rb`,
  `test/molecules/topology_loader_test.rb`, and
  `test/molecules/capability_router_test.rb`.

## Commits

- ceeb8b636 STEP-01 skeleton + schema contract
- 115cde4c8 STEP-02 models + validated loader
- 8ffd76858 STEP-03 authorization, redaction, freshness
- b72c01f6a STEP-04 inventory + exact-ID resolution commands
- 52da69acf STEP-05 capability routing
- 7232a8f80 STEP-06 fresh-install coverage + docs

ceeb8b636 and 115cde4c8 also sit on local `main` (created before the worktree
move; main was not rewritten because unrelated concurrent commits landed on
top). All later commits are exclusive to the task branch.

## Scope notes

- No changes to `ace-overseer` `lab_client.rb`, `ace-herdr`
  `delivery_record.rb`, or `lab-config` (deployed values remain `8wl.t.gad`).
- Independent current-head review still gates delivery per the spec.
