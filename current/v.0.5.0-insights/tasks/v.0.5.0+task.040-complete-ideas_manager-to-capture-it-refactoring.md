---
id: v.0.5.0+task.040
status: draft
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
- [ ] **Zero legacy references**: No "ideas_manager" in active code/documentation
- [ ] **Test file renamed**: Integration test uses capture_it_integration_spec.rb
- [ ] **Documentation consistency**: All workflows/templates reference capture-it

### Validation Questions
- [ ] **Test naming convention**: Use underscore (capture_it) for Ruby file naming?
- [ ] **Historical scope**: Leave completed tasks/reflections unchanged?
- [ ] **Documentation standard**: Always use hyphenated "capture-it" in text?
- [ ] **Git history**: Preserve original context in past commits?

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

## References

- Source idea: dev-taskflow/backlog/ideas/017-filesystem-capture-improvements.md
- Related idea: dev-taskflow/backlog/ideas/018-filesystem-search-enhancements.md
- Current implementation: dev-tools/exe/capture-it
- Test file to rename: dev-tools/spec/integration/ideas_manager_integration_spec.rb