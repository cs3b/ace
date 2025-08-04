# Release v.0.6.0-unified-claude

## Release Information

- **Version**: v.0.6.0
- **Codename**: unified-claude
- **Type**: Minor Release (new features, backwards compatible)
- **Status**: backlog
- **Start Date**: 2025-01-30
- **Target Date**: 2025-02-15

## Collected Notes

From user requirements:
- Improve Claude Code integration script (dev-handbook/.integrations/claude/install-prompts.md)
- Move from auto-generated commands only to a mix of agents, custom commands, and auto-generated
- Unify Claude commands under handbook CLI:
  - `handbook claude generate-commands`
  - `handbook claude update-registry`
  - `handbook claude integrate`
  - `handbook claude validate`
  - `handbook claude list`
- Create static command management with version control
- Implement meta workflow for command validation and coverage
- Support both custom and generated commands with clear separation
- Simplify installation to copy/link operation

## Goals & Requirements

### Primary Goals

1. **Unify Claude Integration**: Move all Claude-related commands under the handbook CLI for better discoverability and consistency
2. **Static Command Management**: Version control all Claude commands within dev-handbook for better maintenance
3. **Hybrid Command System**: Support both custom hand-crafted commands and auto-generated ones with clear separation
4. **Validation Framework**: Ensure complete coverage of all workflow instructions with corresponding Claude commands

### Dependencies

- Existing handbook CLI infrastructure in dev-tools
- Current Claude integration script functionality
- Workflow instruction files in dev-handbook

### Risks & Mitigation

- **Risk**: Breaking existing Claude integrations
  - **Mitigation**: Keep legacy script functional during transition period
- **Risk**: Complex command structure might confuse users
  - **Mitigation**: Clear documentation and helpful command output

## Implementation Plan

### Core Components

1. **Claude Command Structure** - Create organized directory structure for commands
2. **CLI Integration** - Add Claude subcommands to handbook CLI
3. **Command Generation** - Implement smart command generation from workflows
4. **Registry Management** - Handle commands.json updates automatically
5. **Validation System** - Ensure coverage and consistency
6. **Installation Process** - Simplify to copy/link operation
7. **Documentation** - Update all relevant documentation

### Phase Breakdown

**Phase 1: Foundation**
- Create directory structure for static commands
- Implement basic Claude namespace in handbook CLI

**Phase 2: Core Functionality**
- Implement generate-commands functionality
- Create update-registry command
- Build validation system

**Phase 3: Integration**
- Implement integrate command for installation
- Create list command for status overview
- Update meta workflow

**Phase 4: Migration**
- Migrate existing commands to new structure
- Deprecate old installation script
- Update documentation

## Quality Assurance

### Test Coverage

- Unit tests for all new CLI commands
- Integration tests for command generation
- Validation tests for coverage checking
- Installation tests for integrate command

### Documentation

- Update install-prompts.md with new process
- Create comprehensive command reference
- Add examples and troubleshooting guide
- Update meta workflow documentation

## Release Checklist

- [ ] All tasks completed and tested
- [ ] Documentation updated
- [ ] Tests passing with good coverage
- [ ] Legacy script deprecated gracefully
- [ ] User migration guide created
- [ ] Release notes prepared

## Notes

This release focuses on improving the developer experience for Claude Code integration by unifying all commands under a single, discoverable interface. The hybrid approach allows for both automated command generation and custom hand-crafted commands, giving us flexibility while maintaining consistency.