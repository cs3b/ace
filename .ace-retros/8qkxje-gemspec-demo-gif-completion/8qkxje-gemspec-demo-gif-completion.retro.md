---
id: 8qkxje
title: gemspec-demo-gif-completion
type: standard
tags: [docs, gemspec, demo]
created_at: "2026-03-21 22:21:33"
status: active
task_ref: 8q4.t.ums
---

# Gemspec + Demo GIF Completion (t.ums final pass)

## Context

Final pass on 8q4.t.ums documentation overhaul: updated gemspec metadata for 4 core packages (ace-task, ace-bundle, ace-review, ace-git-commit) and recorded demo GIFs committed to docs/demo/. Also updated 28 upcoming task specs (8 orchestrators + 20 subtasks) with the proven template from t.ums.

Commits: `97f667469`, `8efef4f34`, `7bb90e4c0`, `cd606b230`, `ec59fe85c`

## What Went Well

- **ace-demo record works reliably now** — all 4 GIFs recorded without the VHS `randomPort()` segfault that blocked the earlier batch run
- **`--output` flag** on `ace-demo record` cleanly redirects GIF output to `docs/demo/`, bypassing the tape's Output line
- **Gemspec taglines align with READMEs** — summary/description now read well on RubyGems without internal jargon
- **Task spec update caught major drift** — original specs said "delete usage.md" but we actually created usage.md + handbook.md; 28 specs corrected before next batch

## What Could Be Improved

- **Tape Output line is misleading** — `ace-demo record` ignores the tape's `Output` directive entirely, using its own `.ace-local/demo/` default. We updated tapes to say `docs/demo/` but still need `--output` flag. Consider making ace-demo honor the tape's Output path, or document this clearly.
- **Gemspec jargon not caught until review** — initial drafts used "ACE" and "B36TS" in summaries, which are meaningless to first-time RubyGems visitors. The user caught this: gemspec text should be self-explanatory to strangers.
- **Spec drift accumulated silently** — the template evolved significantly during t.ums (added usage.md, handbook.md, gemspec, handbook audit) but the 28 downstream specs still referenced the original "delete usage.md" pattern. Without explicit spec refresh, future batches would have repeated the wrong template.
- **GIF path coupling** — README references `docs/demo/*.gif` (relative), tape says `docs/demo/` (relative from package root), but `ace-demo record` writes to `.ace-local/` by default. Three different path conventions for the same artifact.

## Key Learnings

- **Gemspec is part of the docs surface** — RubyGems visitors see summary/description before README. Treat gemspec metadata as the first line of documentation, not an afterthought.
- **Task spec refresh is a required step** — when a template evolves during execution, all downstream specs must be updated before the next batch starts. This is not optional cleanup; stale specs produce wrong deliverables.
- **Demo GIF commit path**: record with `ace-demo record <tape> --output docs/demo/<name>.gif`, commit to git, reference in README as `![demo](docs/demo/<name>.gif)`.

## Action Items

- **Continue**: Updating gemspec summary/description alongside every README rewrite
- **Continue**: Recording GIFs with `--output docs/demo/` and committing them to git
- **Start**: Refreshing downstream task specs whenever the template evolves during a batch
- **Stop**: Using "ACE" or internal acronyms in gemspec summaries — write for RubyGems strangers

