---
id: v.0.6.0+task.002
status: draft
priority: high
estimate: 4h
dependencies: []
release: v.0.6.0-unified-claude
---

# Implement Claude CLI namespace in handbook

## Behavioral Specification

### User Experience
- **Input**: Developer types `handbook claude` or `handbook claude --help`
- **Process**: System displays available Claude-related subcommands with descriptions
- **Output**: Clear command listing with usage examples and descriptions

### Expected Behavior
When developers invoke `handbook claude`, they should see a helpful overview of all available Claude integration commands. Each subcommand should be clearly described with its purpose. The command structure should follow the established patterns of other handbook subcommands, providing a consistent and intuitive experience.

### Interface Contract
```bash
# Main command
handbook claude
# Output:
Usage: handbook claude [SUBCOMMAND]

Subcommands:
  generate-commands  Generate missing Claude commands from workflows
  update-registry    Update commands.json registry
  integrate          Copy commands to .claude/ directory
  validate           Validate command coverage
  list               List all commands and their status

# Help command
handbook claude --help
# Same output as above

# Invalid subcommand
handbook claude invalid-command
# Output:
Error: Unknown subcommand 'invalid-command'
Usage: handbook claude [SUBCOMMAND]
[... rest of help output ...]
```

**Error Handling:**
- Unknown subcommand: Display error and show help
- No subcommand provided: Display help information
- Missing dependencies: Clear error about what's missing

**Edge Cases:**
- Called from non-project directory: Graceful error with guidance
- Incomplete installation: Detect and report missing components

### Success Criteria
- [ ] **Command Registration**: `handbook claude` is recognized and executable
- [ ] **Help System**: Help information displays correctly
- [ ] **Subcommand Structure**: All planned subcommands are registered
- [ ] **Error Messages**: Clear, actionable error messages for common issues

### Validation Questions
- [ ] **Command Aliases**: Should we support short aliases like `handbook cl`?
- [ ] **Output Format**: Should help output be colorized or plain text?
- [ ] **Subcommand Loading**: Should subcommands be lazy-loaded or eager-loaded?
- [ ] **Backward Compatibility**: How to handle users expecting old claude-integrate script?

## Objective

Establish the Claude namespace within the handbook CLI to provide a unified, discoverable interface for all Claude Code integration operations.

## Scope of Work

- **User Experience Scope**: Command discovery and help system
- **System Behavior Scope**: Command registration and routing
- **Interface Scope**: CLI command structure and output format

### Deliverables

#### Behavioral Specifications
- Command hierarchy documentation
- Help text specifications
- Error message catalog

#### Validation Artifacts
- Command registration tests
- Help output validation
- Subcommand routing tests

## Out of Scope
- ❌ **Implementation Details**: Ruby class structure, dry-cli specifics
- ❌ **Technology Decisions**: Command parsing library choices
- ❌ **Performance Optimization**: Command loading optimization
- ❌ **Future Enhancements**: Additional namespaces or command restructuring

## References

- Existing handbook CLI structure
- dry-cli documentation for subcommand patterns
- Current handbook command implementations (sync-templates)