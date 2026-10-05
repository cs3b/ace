---
id: 8ws.t.ibl
status: done
priority: medium
created_at: "2026-09-29 12:12:54"
estimate: small
dependencies: []
tags: [ace-docs, test-isolation]
bundle:
  presets: [project]
  files: [ace-docs/test/fast/molecules/frontmatter_manager_test.rb, ace-docs/lib/ace/docs/molecules/frontmatter_manager.rb]
  commands: []
needs_review: false
title: Stabilize document update counts in full suite runs
position: 6o0007
---

# Stabilize document update counts in full suite runs

## Behavioral specification

A developer executes document bulk-update verification standalone or in the monorepo suite and receives the same correct count for the same test-owned files. Two successfully updated documents yield count 2, and invalid paths remain failed updates.

### Evidence and current limits

The unrestricted suite on main dbb9bde1e returned expected 2 / actual 0 in `FrontmatterManagerTest#test_update_documents_returns_count` (frontmatter_manager_test.rb:255); 49/50 packages passed. Immediately running `bin/ace-test ace-docs all` passed 213 tests. Both reports are retained under `evidence/`. Root cause is not yet proven. A concrete hypothesis is fixture lifetime: create_test_document returns a Tempfile path after closing and dropping its object; garbage collection can unlink that file before the bulk update. Verify this hypothesis before changing code; a passing rerun alone does not settle it.

### Expected behavior and scope

- Test fixture files remain present for the entire assertion and are cleaned deterministically only after the test finishes. No dependence on garbage-collection timing, sibling test state or ambient files.
- Preserve assertions for bulk count, actual persisted frontmatter and invalid/missing paths. Do not hide the failure with retries, sleeps or a weakened count assertion.
- Preserve existing product bulk-update semantics; do not change successful/failed classification merely to obtain green tests.

### Success criteria and verification

- [x] SC1: Reproduce the failure mechanism deterministically (include collection after fixture creation when testing the lifetime hypothesis) and retain pre-fix evidence.
- [x] SC2: Two fixture documents persist through update and both contain the requested values; mixed valid/invalid inputs return only the successful count.
- [x] SC3: `bin/ace-test ace-docs all` and the full suite pass this case with the reproducing conditions; record seeds, exact SHA and independent verdict. A green rerun without a proven fix does not close the task.

Owner: ace-docs tests. Single observable slice; small. Independent of the Lab feature dependency graph and not a blocker for starting second-wave implementation. No CLI/API/config change; no separate usage file required. Draft awaiting review; no product implementation performed.

## Delivery reconciliation — 2026-10-04

The GC lifetime repair is already in main: 7c043ebd21a591650aae9961b8ca142b806edcf5. R1's archived reports/implementation-report.md and test-failure-analysis.md retain the failed bulk count, GC mechanism, Tempfile.create ownership, forced GC, targeted 15/55, docs all 213/579 and subsequent full-suite evidence. SC1 is supported; do not reimplement this fix.

Remaining SC2 is concrete: the current bulk test asserts count 2, but does not read back both updated documents or exercise mixed valid/invalid inputs in one bulk call. Keep this task open for that regression evidence and independent closure mapped to SC2/SC3; no product redesign is needed. The earlier hypothesis paragraph is historical, superseded by this proven diagnosis. No fresh product tests were run during this spec reconciliation.

## Final acceptance — 2026-10-05

Delivered remaining SC2/SC3 at source 1e868bf84a68cc2edffe6023b0702ab742d25980, integrated with unchanged source. Independent APPROVE and exact docs target/all/suite receipts are retained in independent-source-review.md and verification-2026-10-05.md. Full default target set passed with explicit --timeout 300; this does not claim the configured 120-second budget passed. Terminal suite aggregate is not an independently reconciled unique-invocation inventory: the old runner reused a timestamp directory for duplicate Lab entries (47 distinct saved reports). Task bt0 owns that attribution/allocation defect; exact docs receipts remain unique. No product behavior or Lab installation acceptance is claimed.
