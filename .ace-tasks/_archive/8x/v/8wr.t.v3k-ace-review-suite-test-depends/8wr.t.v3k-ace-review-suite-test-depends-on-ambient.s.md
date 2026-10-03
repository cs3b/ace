---
id: 8wr.t.v3k
status: skipped
priority: medium
created_at: "2026-09-28 20:43:58"
estimate: 
dependencies: []
tags: []
title: Reconcile the repaired ambient gh review fixture
needs_review: false
---

# ace-review suite test depends on ambient gh credentials (hermetic runner)

## Reconciled duplicate — 2026-10-04

The actual ambient gh fixture call was removed in e7986bff4b065e394e2de813621c0a6d8bdc84f4: review_manager_test.rb explicitly disables comment fetching in the exempt-path fixture. The broader hermetic remediation owner is ACE 8wr.t.tp0 (already delivered), and the later qk1.1 migration removes the GitHub-specific consumer surface. Current source retains opt-out fixture behavior; October 4 review all passed 941 tests and the default suite passed 10,944 (recorded in lq1 reconciliation evidence). Those are regression observations, not proof of every unrelated isolation property.

Disposition: skipped as duplicate of delivered tp0/e7986bff4; no new product implementation. Original title preserved above/in Git history. ibk owns the distinct managed-evidence isolation issue; do not merge that into this duplicate.
