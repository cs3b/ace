---
id: 8ql.t.q9b
status: draft
priority: medium
created_at: "2026-03-22 17:30:22"
estimate: TBD
dependencies: []
tags: [ace-docs, ace-lint, frontmatter, readme, dx]
bundle:
  presets: ["project"]
  files:
    - ace-docs/lib/ace/docs/molecules/document_loader.rb
    - ace-docs/lib/ace/docs/atoms/type_inferrer.rb
    - ace-docs/lib/ace/docs/models/document.rb
    - ace-docs/lib/ace/docs/organisms/document_registry.rb
    - ace-docs/lib/ace/docs/molecules/change_detector.rb
    - ace-docs/lib/ace/docs/cli/commands/update.rb
    - ace-docs/.ace-defaults/docs/config.yml
    - ace-lint/lib/ace/lint/molecules/frontmatter_validator.rb
    - ace-lint/lib/ace/lint/atoms/type_detector.rb
  commands: []
---

# Frontmatter-Free README.md Support in ace-docs

## Objective

GitHub renders YAML frontmatter in README.md files as a raw code block, degrading the primary user-facing documentation experience. All 39 package-level READMEs currently require frontmatter (`doc-type`, `purpose`, `ace-docs.last-updated`) to be recognized as managed documents. But for README.md files, all metadata is fully derivable — doc-type is always "user", purpose comes from the parent directory, title from the H1 heading, and last-updated from git history. Removing frontmatter from READMEs improves GitHub rendering while keeping ace-docs management intact.

## Behavioral Specification

### User Experience

- **Input**: Users create or maintain README.md files without any YAML frontmatter — just plain markdown
- **Process**: ace-docs automatically recognizes README.md files as managed documents, inferring all metadata from the file path, content, and git history
- **Output**: README.md files appear in `ace-docs status`, `ace-docs discover`, and `ace-docs update` exactly as they do today — with correct doc-type, purpose, title, freshness tracking — but without requiring frontmatter

### Expected Behavior

1. **Discovery**: Any `**/README.md` file is automatically recognized as a managed `user` document, even without frontmatter
2. **Metadata inference**: doc-type → "user", purpose → "User-facing introduction for {parent_dir}", title → from H1 heading or parent dir name, last-updated → from git history
3. **Frontmatter coexistence**: README.md files WITH explicit frontmatter continue to work — frontmatter values take precedence over inference
4. **Lint exemption**: ace-lint does not flag README.md files for missing frontmatter fields
5. **Freshness tracking**: Uses git commit date as last-updated, with update_frequency "on-change"
6. **Status display**: `ace-docs status` shows README files with correct freshness, type, and purpose

### Interface Contract

```bash
# Before: README.md requires frontmatter to appear
ace-docs status
# README.md files without frontmatter are invisible

# After: README.md files are auto-discovered
ace-docs status
# Shows: ace-bundle/README.md  user  current  "User-facing introduction for ace-bundle"

# Lint passes without frontmatter
ace-lint README.md
# No "Missing required field" errors for README.md

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

1. All `**/README.md` files (not in ignored paths) appear as managed documents in `ace-docs status` without frontmatter
2. `ace-lint` passes on README.md files without frontmatter (no missing-field errors)
3. Frontmatter removed from all ~39 package-level README.md files
4. GitHub rendering of README.md files no longer shows raw YAML block
5. README.md files with explicit frontmatter continue to work identically (backward compatible)
6. `ace-test` passes in both ace-docs and ace-lint packages
7. `ace-test-suite` passes across the monorepo

### Validation Questions

- None — requirements are clear from the plan discussion.

## Vertical Slice Decomposition (task/subtask model)

Single flat task — this is one coherent feature touching two packages (ace-docs, ace-lint) with tightly coupled changes. Splitting into subtasks would create artificial boundaries.

- **Slice**: Frontmatter-free README support (standalone task)
- **Outcome**: README.md files work as managed ace-docs documents without frontmatter
- **Advisory size**: medium (new atoms, molecule modification, lint exemption, config update, ~39 file cleanups, tests)
- **Context dependencies**: ace-docs ATOM layers, ace-lint frontmatter validation, git history access

## Verification Plan

### Unit/Component Validation

- ReadmeMetadataInferrer returns correct hash for README.md path with H1 content
- ReadmeMetadataInferrer returns nil for non-README paths
- ReadmeMetadataInferrer falls back to parent dir name when no H1 heading
- GitDateResolver returns Date from git log output
- GitDateResolver returns nil for files with no git history
- TypeInferrer.resolve returns "user" for README.md basename
- TypeInferrer.resolve still returns frontmatter type when present (precedence preserved)

### Integration/E2E Validation

- DocumentLoader.load_file returns managed Document for README.md without frontmatter
- DocumentLoader.managed_document? returns true for README.md without frontmatter
- DocumentRegistry discovers README.md files without frontmatter
- `ace-docs status` shows README files after frontmatter removal

### Failure/Invalid Path Validation

- FrontmatterValidator.lint returns success for README.md without frontmatter
- FrontmatterValidator.lint still validates non-README .md files (no regression)
- README.md with empty content still loads (doc-type inferred, title from dir name)

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

- Frontmatter-free support for non-README markdown documents (future work if needed)
- Changes to ace-docs update workflow for writing frontmatter to READMEs
- Changes to how other document types (guides, workflows, templates) handle frontmatter

## References

- Plan: `.claude/plans/velvety-seeking-whale.md`
- ace-docs DocumentLoader: `ace-docs/lib/ace/docs/molecules/document_loader.rb`
- ace-docs Document model: `ace-docs/lib/ace/docs/models/document.rb`
- ace-lint FrontmatterValidator: `ace-lint/lib/ace/lint/molecules/frontmatter_validator.rb`
