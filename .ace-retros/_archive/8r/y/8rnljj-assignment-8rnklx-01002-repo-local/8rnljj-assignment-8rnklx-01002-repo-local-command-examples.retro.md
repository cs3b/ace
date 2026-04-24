---
id: 8rnljj
title: Assignment 8rnklx 010.02 - repo-local command examples
type: standard
tags: [assignment, docs, quick-start, 8rl.t.ks9.1]
created_at: "2026-04-24 14:21:42"
status: done
---

# Assignment 8rnklx 010.02 - repo-local command examples

## What Went Well
- Updated `README.md` and `docs/quick-start.md` in the same pass, which kept the repo-local setup flow aligned.
- Narrowed the change to post-install commands only, so `bundle add` and other pre-install instructions stayed correct.
- Added explicit rationale for `bundle exec`, making the docs clearer about why repo-local installs should prefer the project bundle.
- Verification stayed lightweight and deterministic with `ace-lint`, which matched the docs-only scope.

## What Could Be Improved
- `ace-task plan 8rl.t.ks9.1` generated prompt artifacts but did not return a usable plan artifact in this environment, forcing a manual plan handoff.
- The pre-commit review fallback still reports the full file warning set, which adds noise for small documentation edits.
- The release workflow required manual no-op reasoning for a docs-only subtree because it is still package-centric by default.

## Action Items
- Investigate why `ace-task plan` can stall or fail to emit a path artifact even when prompt files are generated.
- Add a narrower review fallback mode for docs-only subtrees so non-blocking lint noise is easier to interpret.
- Add an explicit docs-only no-release branch to the subtree release workflow to avoid repeated manual justification.
