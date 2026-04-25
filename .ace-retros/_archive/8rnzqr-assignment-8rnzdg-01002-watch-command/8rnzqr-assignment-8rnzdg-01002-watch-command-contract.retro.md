---
id: 8rnzqr
title: Assignment 8rnzdg 010.02 - watch command contract
type: standard
tags: [assignment, ace-assign, watch, 8rn.t.z5k.1]
created_at: "2026-04-24 23:49:45"
status: done
---

# Assignment 8rnzdg 010.02 - watch command contract

## What Went Well
- Tightened the `8rn.t.z5k.1` task artifact into a decision-complete watch contract without drifting into runtime implementation detail.
- Kept the contract aligned with shipped `ace-assign` behavior by grounding it in status-first continuation, scoped subtree boundaries, and existing fork metadata semantics.
- Expanded the task-local `ux/usage.md` with concrete wait, recovery, invalid-input, and `Errno::EPERM` scenarios, which makes the later implementation and verification tasks more direct.
- The fallback pre-commit review path caught formatting drift early, and the lint cleanup stayed small and local to the task artifact.

## What Could Be Improved
- The subtree review fallback still depends on `ace-lint`, so docs/spec slices do not get semantic review when native `/review` is unavailable.
- The verify-test and release steps both required explicit no-op reasoning because the subtree changed only task artifacts and no `ace-*` package files.
- The release shim still points to a package-oriented workflow even for task-only subtrees, which creates avoidable closeout overhead.

## Action Items
- Add a clearer docs/task-artifact branch to subtree verification and release workflows so no-package changes can short-circuit without manual explanation.
- Improve the pre-commit review fallback so task/spec subtrees can report semantic findings separately from markdown formatting noise.
- Preserve the wait-versus-recover and `EPERM` wording when the later implementation task turns this contract into runtime code and tests.
