---
id: 8qm9s9
title: readme-refresh-ace-prompt-prep
type: standard
tags: []
created_at: "2026-03-23 06:31:24"
status: active
task_ref: 8qm.t.5nx.l
---

# readme-refresh-ace-prompt-prep

## What Went Well
- Followed assignment scope pinning (`8qm5rt@010.22`) and completed every sub-step in order without queue drift.
- Used a consistent README refresh pattern from recently updated packages, which made section rewrites fast and coherent.
- Kept release discipline intact: docs change, task-state update, package release bump, root changelog update, and clean working tree at each gate.

## What Could Be Improved
- `ace-task plan 8qm.t.5nx.l` had delayed output; the workflow guard was useful, but we should proactively note expected latency in task reports.
- The pre-commit native review step depended on `/review`, which was unavailable in shell mode; this causes repetitive skip-with-evidence handling.
- Task spec had minimal acceptance criteria (title-only), so plan quality relied on inferred README conventions from sibling packages.

## Key Learnings
- For docs-only package tasks, `release-minor` should still run as a patch release when package changelog and versioning policy require a publish entry.
- Keeping commits path-scoped (`ace-git-commit <paths>`) prevents unrelated assignment changes from leaking into task-level work.
- When session metadata for the current subtree is missing, adjacent session metadata can provide a usable provider fallback for policy checks.

## Action Items
- Add explicit README refresh acceptance criteria to generated readme-refresh task specs (required section order, required quick-link trio, demo policy).
- Add a shell-detectable native review capability check helper to avoid manual `/review` command-not-found probing.
- Add a short note in planning steps when `ace-task plan` latency is observed, including fallback path-mode behavior.
