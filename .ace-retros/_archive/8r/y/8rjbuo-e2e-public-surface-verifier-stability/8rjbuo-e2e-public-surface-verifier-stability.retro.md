---
id: 8rjbuo
title: e2e-public-surface-verifier-stability
type: standard
tags: []
created_at: "2026-04-20 07:54:05"
status: active
---

# e2e-public-surface-verifier-stability

Context: follow-up E2E fix/release batch for PR 295 after suite report `8rjb31c` showed `ace-git-secrets/TS-SECRETS-001` and `ace-support-nav/TS-NAV-001` failures. The work released `ace-git-secrets v0.15.5` and `ace-support-nav v0.28.2`, with targeted checkpoints passing: `TS-SECRETS-001` 7/7 and `TS-NAV-001` 5/5.

## What Went Well

- The failure analysis correctly separated product behavior from E2E contract problems. Both tools were functioning; the failures came from verifier or runner artifact expectations.
- The public-surface rule worked well. For `ace-git-secrets`, docs/help already exposed `check-release`, scan formatting flags, and config-based whitelist behavior, so the fix stayed in scenario/verifier contracts instead of changing product code.
- Targeted reruns were useful and cost-aware. The loop focused on `ace-test-e2e ace-git-secrets TS-SECRETS-001` and `ace-test-e2e ace-support-nav TS-NAV-001` rather than repeatedly rerunning the full suite.
- `ace-support-nav` was fixed cleanly by renaming the stale `priority-and-exact-match` TC to `discovery-listing` and making the canonical `list.*` capture contract explicit.
- The release workflow kept the final state clean: versions, package changelogs, root changelog, and `Gemfile.lock` were updated and committed.

## What Could Be Improved

- The `ace-git-secrets` scenario needed several reruns because different brittle verifier assumptions failed one at a time: observation line count, duplicate saved-report copy, config override interpretation, and post-removal scan capture location.
- Some verifier expectations still treated a missing preferred artifact as failure even when a later real artifact proved the user-visible impact. This conflicts with the intended impact-first verification model.
- Runner instructions need stronger completion contracts. One run stopped after Goal 4 while later goals were still required, and another omitted a rescan artifact. Scenario runners should record blocker artifacts explicitly instead of silently skipping evidence.
- The report metadata still listed accepted fallback artifacts under `missing-required-artifacts` in a passing run. That is confusing and can make green reports look suspect.
- Passing suite reports lack runner observations and verifier notes. The nav suite passed, but the report still highlighted that we have little visibility into subtle UX friction, latency, or confusing flows when everything is green.

## Key Learnings

- E2E verifiers should test the user outcome first, then required artifacts, then debug captures. Required artifacts are useful, but they should not override stronger real evidence from the same scenario.
- Minimum line counts are poor quality gates for observations. Explicit required facts are more stable and easier for runners and verifiers to satisfy.
- Duplicate artifact requirements are risky when goals intentionally share state. If Goal 4 creates the saved report and Goal 5 uses it, the verifier should accept the canonical Goal 4 artifact unless the duplicate copy is itself the product behavior under test.
- Naming matters for agent behavior. A TC file named `priority-and-exact-match` was conceptually stale after the scenario moved to public-surface listing behavior; renaming it made the intended contract clearer.
- Rerun evidence can reveal harness/scenario weakness even when the first classification is right. The initial bug was a test issue, but the repeated failures showed the scenario also needed stronger runner completion guidance.

## Action Items

- Continue replacing arbitrary quality thresholds in E2E verifiers with explicit fact-based criteria.
- Add a runner-completion checklist to complex multi-goal scenarios: every listed goal must either produce its required artifacts or a `blocker.md` explaining the missing evidence.
- Improve E2E report generation so accepted fallback artifacts are not still displayed as missing required artifacts in passing reports.
- Add lightweight runner observations for passing scenarios so friction and timing issues can be captured even when verdicts are green.
- Prefer renaming stale TC files when the behavioral contract changes; do not leave implementation-era names attached to public-surface scenarios.
