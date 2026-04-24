---
id: 8rnm21
title: 8rl.t.ks9.2 setup-readiness guidance
type: standard
tags: [task, docs, release]
created_at: "2026-04-24 14:42:17"
status: active
---

# 8rl.t.ks9.2 setup-readiness guidance

## What Went Well
- The task stayed constrained to the documentation contract instead of drifting into runtime `ace-config doctor` changes.
- Running the docs update and the two package verification targets inside the subtree kept the release step grounded in evidence instead of assumption.
- Splitting the work into quick-start docs, package docs, and release updates made it easy to keep the provider-discovery versus readiness distinction consistent across surfaces.

## What Could Be Improved
- The subtree release workflow auto-detect guidance looks at `origin/main...HEAD`, which is too broad for long-lived task branches and needed manual narrowing back to the packages touched by this task.
- `ace-git-commit` split the coordinated release into scope-based commits, which is acceptable here but makes retro summaries and release tracing slightly noisier.
- The lint pass reports many non-blocking warnings without severity structure, so the pre-commit-review fallback still requires human interpretation.

## Key Learnings
- The quickest way to avoid setup confusion was to define a single sentence boundary everywhere: `ace-llm --list-providers` is discovery, `ace-config doctor` is readiness.
- For docs-only package work, package releases still need deliberate handling because package changelogs, versions, and the root changelog are part of the shipped surface.
- Keeping the task usage artifact updated alongside the public docs helps preserve the assignment acceptance story and prevents later drift between task specs and user-facing guidance.

## Action Items
- Consider tightening scoped release workflows so subtree release steps can pass explicit package lists instead of relying on branch-wide diff detection.
- Improve lint fallback reporting so warning output can be summarized by severity or file without manual interpretation.
- Keep future quick-start tasks anchored to the doctor contract owner task when wording changes touch setup readiness again.
