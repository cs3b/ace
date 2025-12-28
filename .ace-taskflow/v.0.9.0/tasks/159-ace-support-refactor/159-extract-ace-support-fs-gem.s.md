---
id: v.0.9.0+task.159
status: in-progress
priority: medium
estimate: 1d
dependencies: []
worktree:
  branch: 159-extract-ace-support-fs-gem-pathexpander-projectrootfinder-directorytraverser
  path: "../ace-task.159"
  created_at: '2025-12-28 20:59:52'
  updated_at: '2025-12-28 20:59:52'
---

# Extract ace-support-fs gem (PathExpander, ProjectRootFinder, DirectoryTraverser)

## Description

Create a new `ace-support-fs` gem to consolidate filesystem operations currently duplicated across `ace-config` and `ace-support-core`. This addresses PR #101 feedback about unifying project root detection and path expansion.

**Problem**: Duplicate filesystem utilities exist in both packages:
- `PathExpander` - path expansion, env vars, protocols
- `ProjectRootFinder` - project root detection with markers
- `DirectoryTraverser` - config directory discovery

12 packages currently depend on `Ace::Core::Molecules::ProjectRootFinder`.

## Acceptance Criteria

- [ ] New `ace-support-fs` gem created with merged implementations
- [ ] Backward compatibility layer in `ace-support-core` (re-exports)
- [ ] `ace-config` updated to use `ace-support-fs` instead of duplicating
- [ ] All 166 ace-config tests pass
- [ ] All consuming packages still work (no breaking changes)
- [ ] Tests migrated/merged from both source packages

## Implementation Notes

### Proposed Structure

```
ace-support-fs/
├── lib/ace/support/fs.rb
├── lib/ace/support/fs/
│   ├── atoms/
│   │   └── path_expander.rb
│   ├── molecules/
│   │   ├── project_root_finder.rb
│   │   └── directory_traverser.rb
│   └── version.rb
├── test/
│   ├── atoms/path_expander_test.rb
│   ├── molecules/project_root_finder_test.rb
│   └── molecules/directory_traverser_test.rb
├── ace-support-fs.gemspec
└── README.md
```

### Files to Extract

**From ace-support-core:**
- `lib/ace/core/atoms/path_expander.rb` (254 lines)
- `lib/ace/core/molecules/project_root_finder.rb` (138 lines)
- `lib/ace/core/molecules/directory_traverser.rb` (116 lines)

**From ace-config:**
- `lib/ace/config/atoms/path_expander.rb` (307 lines)
- `lib/ace/config/molecules/project_root_finder.rb` (152 lines)

### Migration Strategy

1. Create `ace-support-fs` gem with merged implementations
2. Add `ace-support-fs` as dependency to `ace-support-core`
3. Re-export from `ace-support-core` for backward compatibility
4. Update `ace-config` to depend on `ace-support-fs`
5. Update consuming packages (optional with backward compat layer)

### Affected Packages

- ace-docs (2 files)
- ace-prompt (5 files)
- ace-context (1 file)
- ace-search (1 file)
- ace-review (2 files)
- ace-test-runner (1 file)

### Complications

- Circular dependency: `PathExpander.for_file` lazy-loads `ProjectRootFinder`
- Thread-safety differences between implementations (both safe, different patterns)
- Protocol resolver integration differs (one raises, one returns hash)

## References

- PR #101 comment threads #1 and #5
- Plan: `/Users/mc/.claude/plans/zippy-sauteeing-rossum.md`