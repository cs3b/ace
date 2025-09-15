# v.0.6.0 ACE Migration

## Release Overview

This release completes the comprehensive migration from the old naming conventions to the new ACE-based structure, including renaming all submodule paths from `dev-*` to `.ace/*` and renaming the Ruby gem from `CodingAgentTools` to `AceTools`.

## Release Information

- **Type**: Major (Breaking changes to module and path names)
- **Start Date**: 2025-01-15
- **Target Date**: 2025-01-31
- **Status**: Planning

## Collected Notes

### User Requirements
- Update all hardcoded paths from `dev-*` directories to `.ace/*` structure
- Rename Ruby module from `CodingAgentTools` to `AceTools`
- Rename gem from `coding-agent-tools` to `ace-tools`
- Use codemods for systematic text substitution
- Ensure complete coverage using search commands

### Migration Scope Analysis
- **Path changes**: 5,796 occurrences across 967 files
- **Module/gem changes**: 2,991 occurrences across 645 files
- **Total affected files**: ~1,000+ files

### Path Mappings
- `.ace/tools/` → `.ace/tools/`
- `.ace/handbook/` → `.ace/handbook/`
- `.ace/taskflow/` → `.ace/taskflow/`
- `.ace/local/` → `.ace/local/`

### Module/Gem Mappings
- `CodingAgentTools` → `AceTools`
- `coding_agent_tools` → `ace_tools`
- `coding-agent-tools` → `ace-tools`
- Gem executable: `coding-agent-tools` → `ace-tools`

## Goals & Requirements

### Primary Goals

- [x] Complete migration of all path references from `dev-*` to `.ace/*`
- [x] Rename Ruby module and gem to AceTools
- [x] Ensure zero breaking changes for end users through proper migration strategy
- [x] Maintain full test coverage throughout migration

### Dependencies

- Ruby 3.2+ for running codemods
- All existing tests must pass after migration
- Documentation must be updated to reflect new structure

### Risks & Mitigation

- **Risk 1**: Breaking existing installations | **Mitigation**: Provide migration guide and compatibility layer
- **Risk 2**: Missing some path references | **Mitigation**: Use comprehensive search verification after each codemod
- **Risk 3**: Test failures due to hardcoded paths | **Mitigation**: Run test suite after each migration phase

## Implementation Plan

### Core Components

1. **Codemod Development**
   - [ ] Create path update codemod for all file types
   - [ ] Create Ruby module renaming codemod
   - [ ] Create file/directory renaming scripts
   - [ ] Create verification scripts

2. **Migration Execution**
   - [ ] Phase 1: Update all path references
   - [ ] Phase 2: Rename Ruby modules and gem
   - [ ] Phase 3: Update configuration files
   - [ ] Phase 4: Verify complete migration

3. **Testing & Validation**
   - [ ] Run full test suite after each phase
   - [ ] Verify all CLI tools functionality
   - [ ] Test installation process
   - [ ] Validate documentation accuracy

## Quality Assurance

### Test Coverage

- [ ] Unit Tests (maintain >80% coverage)
- [ ] Integration Tests for all CLI commands
- [ ] End-to-end tests for key workflows
- [ ] Manual testing of installation process

### Documentation

- [ ] Update README with new gem name
- [ ] Update installation instructions
- [ ] Create migration guide for existing users
- [ ] Update all workflow instructions
- [ ] Update CHANGELOG.md

## Release Checklist

- [ ] All codemods developed and tested
- [ ] All path references updated (verified with search)
- [ ] All Ruby modules renamed (verified with search)
- [ ] All tests passing
- [ ] Documentation completely updated
- [ ] Installation process tested on clean system
- [ ] Migration guide published
- [ ] Version numbers updated in relevant files
- [ ] Backward compatibility verified or breaking changes documented
- [ ] Release notes drafted

## Notes

This is a major infrastructure change that affects the entire codebase. The migration must be done systematically using codemods to ensure consistency and completeness. The use of search commands for verification is critical to ensure no references are missed.

The renaming from CodingAgentTools to AceTools aligns with the new project structure and creates a more concise, memorable name for the toolkit.