# Retro: ace-idea Polish After Initial Migration

**Date**: 2026-02-28
**Context**: Polish work done after the initial task.291 implementation was complete — fixing
archive layout bugs, classifying ideas by origin, and moving non-release ideas to `_maybe/`.
**Type**: Self-Review

## What Went Well

- **Dry-run discipline**: Running `--dry-run` before every codemod execution caught all classification
  mistakes before any files were touched. Pattern held across all three codemods.
- **Codemod-per-problem approach**: Keeping each fix as a small, focused script (fix_archive_week_partitions,
  classify_and_move_ideas) made the intent clear and kept the changes reversible.
- **Git log as classification oracle**: Using `git log --diff-filter=A` to determine which commit
  added each idea folder was a clean, deterministic way to identify migration-origin vs user-created ideas.
- **Incremental iteration on classification logic**: The dry-run output made regex mistakes immediately
  visible — each fix was one tight loop.

## What Could Be Improved

- **Initial migration was too coarse**: `migrate_ideas.rb` moved everything without tagging origin or
  enforcing any structure. This required two additional codemods to clean up what could have been
  handled upfront.
- **B36TS pattern definition was underspecified**: Three iterations were needed before the regex
  correctly excluded legacy English-word folder names (`output-line-limit`, `preset-template-reuse`)
  and legacy date prefixes (`2025111-`). The B36TS format should be documented explicitly.
- **Container folders (group folders) not accounted for**: `2025111-ace-packages-review/` contained
  sub-idea folders rather than a direct `.idea.s.md` file. The codemod had to special-case this.
  IdeaLoader's scanning rules for container folders were not reflected in the migration tooling.
- **Backlog idea format was inconsistent**: Loose `.idea.s.md` files in `_backlog/ideas/` had
  LLM cost-tracking YAML as their frontmatter block rather than standard `status:`/`id:` fields.
  Frontmatter parsing still worked but the `source:` field ended up appended after cost data.

## Key Learnings

- **B36TS IDs always start with a digit**: All real B36TS-named idea folders encountered start with
  a digit (e.g. `8ktby7`, `8pozex`). Requiring `\A[0-9][0-9a-z]{5}-` is the right discriminator,
  ruling out both English-word names and 7-digit date prefixes.
- **Migration tasks need a "classify on arrival" step**: When moving ideas from a scoped directory
  (release ideas) to a shared pool, tagging origin at migration time avoids a separate pass later.
  Adding `source:` in `migrate_ideas.rb` would have been one step instead of three.
- **`git log --diff-filter=A` is reliable for tracing provenance**: When ideas were added in the
  same commit batch, a short-SHA prefix comparison against known migration commits is enough.
- **Container/group folders break flat-scan assumptions**: A folder named like a legacy collection
  (`2025111-*`) containing sub-idea folders requires either recursive handling or explicit skipping
  in any codemod that expects a flat idea-per-folder layout.

## Action Items

### Stop Doing

- Migrating files without tagging origin metadata at migration time.
- Assuming every folder in an ideas directory directly contains a `.idea.s.md` spec file.

### Continue Doing

- Writing codemods with `--dry-run` support from the start.
- Keeping codemods in the task's `codemods/` folder as a permanent audit trail.
- Validating classification logic against real folder names before executing.

### Start Doing

- Add `source:` field (and optionally `migrated_from:`) to ideas at the point of migration, not
  as a follow-up pass.
- Document the B36TS naming convention in the ace-idea gem (what constitutes a valid ID vs a legacy
  name) so codemods and IdeaLoader share the same definition.
- Before writing migration codemods, scan the source directory for structural outliers (container
  folders, files vs dirs, missing spec files) and handle them explicitly.

## Technical Details

**B36TS discriminator pattern (final):**
```ruby
# Requires exactly 6 chars starting with a digit — excludes English words and date prefixes
B36TS_PATTERN = /\A[0-9][0-9a-z]{5}-/
```

**Codemods produced (in order):**
1. `migrate_ideas.rb` — initial bulk move from `v.0.9.0/ideas/` to `.ace-ideas/`
2. `fix_archive_week_partitions.rb` — rename raw digit week dirs (1-5) to base36 (v-z)
3. `migrate_backlog_ideas.rb` — move backlog ideas to `_maybe/`
4. `classify_and_move_ideas.rb` — add `source:` frontmatter; move non-release ideas to `_maybe/`

**Source values assigned:**
- `"taskflow:v.0.9.0"` — 30 ideas (migration origin, stay in root)
- `"user"` — 6 ideas (post-migration B36TS IDs, moved to `_maybe/`)
- `"legacy"` — 4 folders (non-B36TS names, moved to `_maybe/`)
- `"backlog"` — 3 loose files (from `_backlog/ideas/`, moved to `_maybe/`)

## Additional Context

- Task: `v.0.9.0+task.291.04` — Migrate Ideas Data to `.ace-ideas/` (One-Time Codemod)
- Codemods: `.ace-taskflow/v.0.9.0/tasks/_archive/291-feat-idea-ace/codemods/`
