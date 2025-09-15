---
id: v.0.5.0+task.040
status: done
priority: high
estimate: 2h
dependencies: []
---

# Complete ideas_manager to capture-it refactoring

## Behavioral Specification

### User Experience
- **Input**: Users interact with capture-it command and documentation
- **Process**: Consistent naming throughout all project materials
- **Output**: Clear, unambiguous references to capture-it functionality

### Expected Behavior
Users and developers experience consistent naming across all touchpoints - documentation, code, tests, and examples. The system responds to "capture-it" commands without any legacy "ideas_manager" references causing confusion or errors. All documentation, workflow instructions, and templates use the current "capture-it" naming convention.

### Interface Contract
```bash
# CLI Interface
capture-it [options] "idea description"
# All documentation and code references use "capture-it"
# No "ideas_manager" or "ideas-manager" references remain in active files

# File naming
spec/integration/capture_it_integration_spec.rb  # Test file renamed
```

**Error Handling:**
- Missing references: System should not fail due to outdated naming
- Test coverage: All tests should reference correct naming

**Edge Cases:**
- Historical files: Completed task/reflection files retain historical context
- Git metadata: Binary git files not modified

### Success Criteria
- [x] **Zero legacy references**: No "ideas_manager" in active code/documentation
- [x] **Test file renamed**: Integration test uses capture_it_integration_spec.rb
- [x] **Documentation consistency**: All workflows/templates reference capture-it

### Validation Questions
- [x] **Test naming convention**: Use underscore (capture_it) for Ruby file naming? Yes
- [x] **Historical scope**: Leave completed tasks/reflections unchanged? Yes
- [x] **Documentation standard**: Always use hyphenated "capture-it" in text? Yes
- [x] **Git history**: Preserve original context in past commits? Yes

## Implementation Plan

### Planning Steps
* [x] Analyze current state - identify all remaining "ideas_manager" references
* [x] Confirm scope - active files only, preserve historical context
* [x] Verify Ruby naming conventions for test files (use underscores)

### Execution Steps
- [x] Rename integration test file from ideas_manager_integration_spec.rb to capture_it_integration_spec.rb
- [x] Rename unit test file from ideas_manager_spec.rb to capture_it_spec.rb
- [x] Update internal test references (lines 13, 319, 369, 395, 567 in integration spec)
- [x] Update draft-task.wf.md to reference capture-it instead of ideas-manager
- [x] Update capture-idea.wf.md to reference capture-it tool
- [x] Update task.draft.template.md to reference capture-it
- [x] Run tests to verify renaming doesn't break anything
- [x] Create grep report confirming zero "ideas_manager" in active files

## Objective

Complete the refactoring from "ideas_manager" to "capture-it" ensuring consistent naming throughout the codebase, tests, and documentation for improved maintainability and clarity.

## Scope of Work

- **User Experience Scope**: All user-facing documentation, help text, and workflow instructions
- **System Behavior Scope**: Test files, internal code references, and templates
- **Interface Scope**: CLI command interface (already complete as capture-it)

### Deliverables

#### Behavioral Specifications
- Consistent "capture-it" naming across all active documentation
- Renamed test file following Ruby conventions
- Updated workflow instructions and templates

#### Validation Artifacts
- Grep report showing zero "ideas_manager" in active files
- All integration tests passing with new naming
- Documentation review confirming consistency

## Out of Scope

- ❌ **Historical records**: Changing references in completed task/reflection files
- ❌ **Git history**: Rewriting commit messages or git history
- ❌ **Binary files**: Modifying git metadata or log files
- ❌ **External systems**: References outside project repositories

## Acceptance Criteria

- [x] Test file renamed to capture_it_integration_spec.rb
- [x] All workflow documentation references capture-it
- [x] All templates reference capture-it
- [x] Tests pass with new naming
- [x] Zero "ideas_manager" references in active code/docs

## References

- Source idea: dev-taskflow/current/v.0.5.0-insights/docs/ideas/040-017-filesystem-capture-improvements.md
- Related idea: dev-taskflow/current/v.0.5.0-insights/docs/ideas/040-018-filesystem-search-enhancements.md
- Current implementation: dev-tools/exe/capture-it
- Test file to rename: dev-tools/spec/integration/ideas_manager_integration_spec.rb