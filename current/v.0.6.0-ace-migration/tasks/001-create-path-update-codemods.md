---
id: v.0.6.0+task.001
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Create Path Update Codemods

## Objective

Create Ruby codemods to systematically update all references from old `dev-*` directory structure to new `.ace/*` structure across the entire codebase.

## Scope of Work

- Create Ruby script for path substitution
- Handle all variations of path references (quoted, unquoted, in comments)
- Support all file types (Ruby, Markdown, YAML, etc.)
- Include dry-run mode for testing

### Deliverables

#### Create

- `codemods/update_paths.rb` - Main path update codemod
- `codemods/path_mappings.yml` - Configuration for path mappings

#### Modify

- None (new files only)

#### Delete

- None

## Implementation Plan

### Planning Steps

* [ ] Analyze all path variations in the codebase
* [ ] Identify edge cases (paths in strings, comments, documentation)
* [ ] Design regex patterns for safe substitution

### Execution Steps

- [ ] Create `codemods/` directory structure
- [ ] Implement `update_paths.rb` with the following features:
  - Path mapping configuration
  - File type detection
  - Backup creation before modification
  - Dry-run mode
  - Progress reporting
  - Detailed logging
- [ ] Test codemod on sample files
  > TEST: Verify Path Updates
  > Type: Unit Test
  > Assert: Sample files have paths correctly updated
  > Command: ruby codemods/update_paths.rb --dry-run --test
- [ ] Create path_mappings.yml with all conversions:
  ```yaml
  mappings:
    "dev-tools/": ".ace/tools/"
    "dev-handbook/": ".ace/handbook/"
    "dev-taskflow/": ".ace/taskflow/"
    "dev-local/": ".ace/local/"
  ```

## Acceptance Criteria

- [ ] Codemod handles all file types correctly
- [ ] Dry-run mode shows changes without modifying files
- [ ] Backup functionality works correctly
- [ ] All path variations are handled (quoted, unquoted, in URLs, etc.)

## Out of Scope

- ❌ Ruby module renaming (separate task)
- ❌ File/directory renaming (separate task)
- ❌ Actual execution of the codemod (separate task)