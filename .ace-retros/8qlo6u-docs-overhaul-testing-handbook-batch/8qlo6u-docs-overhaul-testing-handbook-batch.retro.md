---
id: 8qlo6u
title: docs-overhaul-testing-handbook-batch
type: standard
tags: [batch, docs, testing, handbook]
created_at: "2026-03-22 16:07:36"
status: done
---

# Documentation Overhaul Batch Retrospective

Batch: 8q4.t.unq.0 (ace-test), 8q4.t.unq.1 (ace-test-runner), 8q4.t.unq.2 (ace-test-runner-e2e), 8q4.t.unq.3 (ace-handbook)

## What Went Well

- **Fork-based parallelization**: Each task ran independently in fork subtrees, isolating context and enabling batch execution without cross-contamination
- **Consistent deliverables**: All 4 packages followed the identical pattern (README → landing page + getting-started + usage + handbook + demo), making review findings transferable across packages
- **Review cycle effectiveness**: 3 review passes (valid/fit/shine) caught real issues — broken frontmatter, incorrect ace-nav syntax, flag conflicts, wrong paths — that would have been user-visible
- **Provider recovery**: When codex:spark hit usage limits mid-batch, switching to codex allowed seamless continuation without losing progress

## What Could Be Improved

- **Fork GitHub connectivity**: All 3 review cycles failed in fork-run because codex forks couldn't reach api.github.com. Reviews had to be executed inline at driver level, defeating context isolation for review steps
- **Duplicate review findings**: Later review cycles (fit, shine) re-flagged issues already fixed in earlier cycles because the reviews ran against pushed (pre-fix) code. A push-before-review step or incremental diff mode would reduce noise
- **Codex fork quality**: E2E docs used Kramdown syntax (`{: .language-bash}`) and broken YAML frontmatter (`* * *` instead of `---`), suggesting the Codex provider's markdown generation doesn't follow GFM conventions consistently
- **Retry step accumulation**: The provider failure in 010.03 created multiple orphan retry steps (011, 013, 014) at the top level instead of within the subtree, requiring manual cleanup

## Key Learnings

- **Docs-only tasks skip efficiently**: verify-test and release steps correctly detected docs-only changes and skipped, keeping the batch fast
- **ace-nav requires subcommands**: `ace-nav <protocol>` is invalid — must use `ace-nav resolve <protocol>` or `ace-bundle <protocol>`. This is a common documentation error across packages
- **VHS segfaults in fork environments**: Multiple forks reported VHS crashes (nil pointer dereference, segfault). Demo GIFs were generated via fallback rendering, not actual VHS recording

### Review Cycle Analysis

- Valid cycle: 7 findings, 5 valid (high: broken frontmatter, medium: flag conflict, table, paths, bullets)
- Fit cycle: 11 findings, 1 new valid (ace-nav syntax), 4 duplicates of valid-cycle fixes, 6 skipped
- Shine cycle: 7 findings, 0 new valid, 4 duplicates, 3 low-priority skips
- False positive rate was low across all models; most "invalid" findings in fit/shine were already-fixed items
- Codex GPT consistently took longest (227-337s) vs Claude Opus (40-53s)

## Action Items

- **Continue**: Using batch assignment pattern for documentation overhaul tasks — the fork+review structure works well
- **Start**: Pushing review-cycle fixes before running the next cycle to reduce duplicate findings
- **Start**: Investigating fork-to-GitHub connectivity to enable review in forked context
- **Stop**: Creating retry steps at top level for subtree failures — retry steps should always be injected as children of the failed subtree root
