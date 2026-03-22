---
id: 8ql.t.q9b
status: done
priority: medium
created_at: "2026-03-22 17:30:22"
estimate: TBD
dependencies: []
tags: [ace-docs, ace-lint, frontmatter, readme, dx]
review_completed: 2026-03-22
bundle:
  presets: [project]
  files: [ace-docs/lib/ace/docs/molecules/document_loader.rb, ace-docs/lib/ace/docs/atoms/type_inferrer.rb, ace-docs/lib/ace/docs/models/document.rb, ace-docs/lib/ace/docs/organisms/document_registry.rb, ace-docs/lib/ace/docs/molecules/change_detector.rb, ace-docs/lib/ace/docs/cli/commands/update.rb, ace-docs/lib/ace/docs/cli/commands/status.rb, ace-docs/.ace-defaults/docs/config.yml, ace-lint/lib/ace/lint/molecules/frontmatter_validator.rb, ace-lint/lib/ace/lint/organisms/lint_orchestrator.rb, ace-lint/lib/ace/lint/atoms/type_detector.rb]
  commands: []
needs_review: false
worktree:
  branch: q9b-frontmatter-free-readmemd-support-in-ace-docs
  path: ../ace-t.q9b
  created_at: "2026-03-22 19:50:01"
  updated_at: "2026-03-22 19:50:01"
  target_branch: main
---

## Review Questions (Resolved)

### [RESOLVED] ace-docs update behavior for frontmatter-free READMEs

- **Original Priority**: HIGH
- **Decision**: Option (a) — skip writing frontmatter entirely. Files matching `frontmatter_free` glob patterns are treated as special documents with inferred-only metadata. `ace-docs update` skips frontmatter writes for these files.
- **Rationale**: Simplest approach. README.md is a special document type where all metadata is derivable. Making this configurable via glob patterns in the YAML config (`frontmatter_free` key) allows extending the pattern to other file types in the future without code changes.
- **Implementation Notes**:
  - Add `frontmatter_free` config key to `ace-docs/.ace-defaults/docs/config.yml` with default `["**/README.md"]`
  - All hardcoded `README.md` basename checks should instead consult this glob list
  - `ace-docs update` skips frontmatter writes for matching files
  - `ace-lint` skips frontmatter validation for matching files
  - DocumentLoader infers metadata for matching files without frontmatter
- **Resolved by**: Project owner
- **Date**: 2026-03-22

# Frontmatter-Free README.md Support in ace-docs

## Objective

GitHub renders YAML frontmatter in README.md files as a raw code block, degrading the primary user-facing documentation experience. All 39 package-level READMEs currently require frontmatter (`doc-type`, `purpose`, `ace-docs.last-updated`) to be recognized as managed documents. But for README.md files, all metadata is fully derivable — doc-type is always "user", purpose comes from the parent directory, title from the H1 heading, and last-updated from git history.

This task introduces a configurable `frontmatter_free` glob list in ace-docs config. Files matching these patterns are treated as managed documents with inferred metadata — no frontmatter required, no frontmatter written. The default pattern is `**/README.md`, but the mechanism is extensible to other file types.

## Behavioral Specification

### User Experience

- **Input**: Users create or maintain README.md files without any YAML frontmatter — just plain markdown
- **Process**: ace-docs automatically recognizes README.md files as managed documents, inferring all metadata from the file path, content, and git history
- **Output**: README.md files appear in `ace-docs status`, `ace-docs discover`, and `ace-docs update` exactly as they do today — with correct doc-type, purpose, title, freshness tracking — but without requiring frontmatter

### Expected Behavior

1. **Configurable globs**: A `frontmatter_free` key in ace-docs config defines glob patterns for files managed without frontmatter. Default: `["**/README.md"]`
2. **Discovery**: Files matching `frontmatter_free` globs are automatically recognized as managed documents, even without frontmatter
3. **Metadata inference**: For README.md: doc-type → "user", purpose → "User-facing introduction for {parent_dir}", title → from H1 heading or parent dir name, last-updated → from git history
4. **Frontmatter coexistence**: Files matching `frontmatter_free` globs that DO have explicit frontmatter continue to work — frontmatter values take precedence over inference
5. **Lint exemption**: ace-lint does not flag `frontmatter_free` files for missing frontmatter fields
6. **Update skip**: `ace-docs update` skips writing frontmatter to `frontmatter_free` files — metadata is inferred-only
7. **Freshness tracking**: Uses git commit date as last-updated, with update_frequency "on-change"
8. **Status display**: `ace-docs status` shows these files with correct freshness, type, and purpose

### Interface Contract

```yaml
# Config: ace-docs/.ace-defaults/docs/config.yml (or .ace/docs/config.yml override)
frontmatter_free:
  - "**/README.md"
  # Users can add more patterns, e.g.:
  # - "**/CONTRIBUTING.md"
```

```bash
# Before: README.md requires frontmatter to appear
ace-docs status
# README.md files without frontmatter are invisible

# After: README.md files are auto-discovered via frontmatter_free config
ace-docs status
# Shows: ace-bundle/README.md  user  current  "User-facing introduction for ace-bundle"

# Lint passes without frontmatter
ace-lint README.md
# No "Missing required field" errors for README.md

# ace-docs update skips frontmatter writes for frontmatter_free files
ace-docs update README.md --set last-updated=today
# Skips — README.md is frontmatter-free, metadata is inferred

# README with explicit frontmatter still works (no regression)
# Frontmatter values override inferred values
```

Error Handling:
- README.md in a directory with no git history → last-updated is nil, freshness_status is :unknown
- README.md with no H1 heading → title falls back to parent directory name
- README.md with explicit frontmatter → frontmatter values take full precedence (existing behavior)

Edge Cases:
- Nested README.md files (e.g., `ace-docs/docs/feature/README.md`) → purpose derived from immediate parent ("feature")
- Root `README.md` → purpose derived from repo root directory name
- README.md in ignored paths (vendor/, node_modules/) → still excluded by ignore rules

### Success Criteria

1. `frontmatter_free` config key exists with default `["**/README.md"]` and is respected by all ace-docs/ace-lint operations
2. All `**/README.md` files (not in ignored paths) appear as managed documents in `ace-docs status` without frontmatter
3. `ace-lint` passes on `frontmatter_free` files without frontmatter (no missing-field errors)
4. `ace-docs update` skips writing frontmatter to `frontmatter_free` files
5. Frontmatter removed from all ~39 package-level README.md files
6. GitHub rendering of README.md files no longer shows raw YAML block
7. Files matching `frontmatter_free` globs with explicit frontmatter continue to work (backward compatible)
8. `ace-test` passes in both ace-docs and ace-lint packages
9. `ace-test-suite` passes across the monorepo

### Validation Questions

- None — requirements are clear from the plan discussion.

## Vertical Slice Decomposition (task/subtask model)

Single flat task — this is one coherent feature touching two packages (ace-docs, ace-lint) with tightly coupled changes. Splitting into subtasks would create artificial boundaries.

- **Slice**: Frontmatter-free README support (standalone task)
- **Outcome**: README.md files work as managed ace-docs documents without frontmatter
- **Advisory size**: medium (new atoms, molecule modification, lint exemption, config-driven glob matching, update skip, ~39 file cleanups, tests)
- **Context dependencies**: ace-docs ATOM layers, ace-lint frontmatter validation, git history access

## Verification Plan

### Unit/Component Validation

- `frontmatter_free` config key is read from config and defaults to `["**/README.md"]`
- FrontmatterFreeResolver (or equivalent) correctly matches paths against glob patterns
- ReadmeMetadataInferrer returns correct hash for README.md path with H1 content
- ReadmeMetadataInferrer returns nil for non-matching paths
- ReadmeMetadataInferrer falls back to parent dir name when no H1 heading
- GitDateResolver returns Date from git log output
- GitDateResolver returns nil for files with no git history
- TypeInferrer.resolve returns "user" for README.md basename
- TypeInferrer.resolve still returns frontmatter type when present (precedence preserved)

### Integration/E2E Validation

- DocumentLoader.load_file returns managed Document for frontmatter_free files without frontmatter
- DocumentLoader.managed_document? returns true for frontmatter_free files without frontmatter
- DocumentRegistry discovers frontmatter_free files without frontmatter
- `ace-docs status` shows README files after frontmatter removal
- `ace-docs update` on a frontmatter_free file does NOT write frontmatter to disk

### Failure/Invalid Path Validation

- FrontmatterValidator.lint returns success for frontmatter_free files without frontmatter
- FrontmatterValidator.lint still validates non-matching .md files (no regression)
- README.md with empty content still loads (doc-type inferred, title from dir name)
- Custom `frontmatter_free` pattern (e.g., `**/CONTRIBUTING.md`) is respected when configured

### Verification Commands

- `cd ace-docs && ace-test` → all tests pass
- `cd ace-lint && ace-test` → all tests pass
- `ace-test-suite` → full monorepo green
- `ace-docs status` → README files visible as managed documents

## Scope of Work

- **User experience scope**: README.md files work seamlessly in ace-docs without frontmatter; GitHub rendering improves
- **System behavior scope**: ace-docs discovery, status, and update commands; ace-lint frontmatter validation
- **Interface scope**: No new CLI commands or flags; existing commands gain README awareness

## Deliverables

### Behavioral Specifications
- README.md auto-discovery and metadata inference in ace-docs
- Lint exemption for README.md files in ace-lint
- Config-driven README document type definition

### Validation Artifacts
- New atom tests (ReadmeMetadataInferrer, GitDateResolver)
- Modified molecule tests (DocumentLoader, FrontmatterValidator)
- Manual verification via `ace-docs status`

## Out of Scope

- Metadata inference for non-README `frontmatter_free` patterns (only `**/README.md` inference is implemented now; adding new patterns would need corresponding inferrers)
- Changes to how other document types (guides, workflows, templates) handle frontmatter

## References

- Plan: `.claude/plans/velvety-seeking-whale.md`
- ace-docs DocumentLoader: `ace-docs/lib/ace/docs/molecules/document_loader.rb`
- ace-docs Document model: `ace-docs/lib/ace/docs/models/document.rb`
- ace-lint FrontmatterValidator: `ace-lint/lib/ace/lint/molecules/frontmatter_validator.rb`
