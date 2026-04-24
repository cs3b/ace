---
id: 8rnmbt
title: 8rl.t.ks9.3 first-setup commit recovery
type: standard
tags: [task, docs, release]
created_at: "2026-04-24 14:53:08"
status: active
---

# 8rl.t.ks9.3 first-setup commit recovery

## What Went Well
- The task stayed tightly scoped to documentation and workflow guidance, which kept the user-facing first-setup commit story aligned with the already-shipped runtime fallback from `8rl.t.k5a.3`.
- Verifying the exact task contract (`ace-lint` for the required docs plus `ace-test` and `ace-test-e2e` for `ace-git-commit`) caught drift early and gave the release step concrete evidence instead of assumptions.
- Splitting the implementation into root quick-start guidance, package docs, workflow wording, and task usage notes made it easier to keep `git status`, `--only-staged`, `--no-split`, and readiness sequencing consistent across surfaces.

## What Could Be Improved
- The fallback pre-commit review path (`ace-lint`) still reports workflow-file structural issues that are not severity-ranked, so it takes manual judgment to separate real regressions from non-blocking handbook lint expectations.
- The release workflow's branch-wide auto-detect rules are too broad for subtree execution on a branch that already contains other task work, so the package selection had to be narrowed manually to `ace-git-commit`.
- The initial release pass left the package changelog entry under `Unreleased`; the release closeout would be safer with an explicit package-changelog sanity check before the release step is marked done.

## Key Learnings
- For first-use setup tasks, the clearest contract is to make the deterministic `-m` path the default recommendation and treat LLM-backed generation as an optional next step after readiness is confirmed.
- Docs-only package tasks still need full release discipline when the shipped surface includes package docs, workflow text, version metadata, and root changelog entries.
- Scoped `ace-git-commit` release commits work well with unrelated dirty files in the tree, but the operator still needs to verify the emitted split commits cover only the intended release paths.

## Action Items
- Consider tightening subtree release execution so `release-minor` can pass explicit package names instead of depending on branch-wide diff auto-detection.
- Improve lint fallback reporting for handbook workflow files so pre-commit review can summarize non-blocking issues more clearly.
- Add a release checklist item or automation guard that confirms package changelog entries move into a versioned section before the release step completes.
