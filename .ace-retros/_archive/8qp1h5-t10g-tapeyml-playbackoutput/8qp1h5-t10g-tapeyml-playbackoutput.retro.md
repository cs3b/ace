---
id: 8qp1h5
title: t.10g tape.yml playback/output
type: standard
tags: [ace-demo, t.10g]
created_at: "2026-03-26 00:59:03"
status: active
---

# t.10g tape.yml playback/output

## What Went Well
- Implemented parser, recorder, and CLI precedence changes in one vertical slice so behavior stayed coherent across tape-mode entry points.
- Added coverage at three layers (atom, organism, command) for speed-only, output-only, combined retime-only mode, and CLI override precedence.
- Completed release coordination in the same assignment subtree (`ace-demo` version bump, package/root changelog updates, lockfile refresh).

## What Could Be Improved
- Package-level verification still contains an unrelated baseline failure in `GettingStartedTapesSmokeTest` (task demo `git-init` expectation drift), which creates noise for task-level verification.
- Pre-commit review fallback (`ace-lint`) surfaced warnings only in task metadata; lint hygiene could be tightened earlier during task authoring.

## Action Items
- Add/fix follow-up for `ace-demo/test/organisms/getting_started_tapes_smoke_test.rb` vs `ace-task/docs/demo/ace-task-getting-started.tape.yml` expectation mismatch.
- Consider documenting the YAML combined-mode output semantics in command help text in addition to docs pages.
