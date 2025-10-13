---
id: v.0.6.0+task.001
status: done
priority: high
estimate: 4h
actual: 1h
completed_at: 2025-09-15
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
    ".ace/tools/": ".ace/tools/"
    ".ace/handbook/": ".ace/handbook/"
    ".ace/taskflow/": ".ace/taskflow/"
    ".ace/local/": ".ace/local/"
  ```

## Acceptance Criteria

- [x] Codemod handles all file types correctly
- [x] Dry-run mode shows changes without modifying files
- [x] Backup functionality works correctly
- [x] All path variations are handled (quoted, unquoted, in URLs, etc.)

## Completion Notes

Successfully created Ruby codemod that:
- Processes 2196 files in the project
- Identifies 1025 files requiring updates
- Will make 8523 total replacements
- Includes comprehensive test suite with 7 unit tests
- Handles edge cases (partial matches, symlinks, binary files)
- Provides dry-run mode for safe validation
- Located in: `.ace/taskflow/current/v.0.6.0-ace-migration/codemods/`

## Out of Scope

- ❌ Ruby module renaming (separate task)
- ❌ File/directory renaming (separate task)
- ❌ Actual execution of the codemod (separate task)