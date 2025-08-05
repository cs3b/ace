---
id: v.0.6.0+task.022
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Refactor claude_commands_installer to ATOM architecture

## Behavioral Specification

### User Experience
- **Input**: Developers run `claude-commands-installer` CLI tool with options for dry-run, verbose output, backup creation, and force overwrite
- **Process**: Tool discovers and installs Claude commands from dev-handbook workflows, copying custom commands, generating workflow commands, and installing agents with clear progress feedback
- **Output**: Installed .claude/ directory with commands and agents, detailed summary of operations (created/skipped/updated counts), and clear error reporting

### Expected Behavior
The installer should provide a clear, predictable experience for setting up Claude Code commands:

1. **Discovery Phase**: Automatically find workflow instructions and command templates in the dev-handbook structure
2. **Validation Phase**: Check source directories exist and validate the project structure
3. **Installation Phase**: Copy commands and agents to the .claude/ directory with appropriate metadata injection
4. **Reporting Phase**: Provide detailed summary of what was installed, skipped, or failed

The system should handle edge cases gracefully:
- Missing source directories should provide helpful error messages
- Existing files should be skipped unless --force flag is used
- Backup creation should be atomic and timestamped
- Dry-run mode should show exactly what would happen without making changes

### Interface Contract

```bash
# CLI Interface
claude-commands-installer [OPTIONS]

# Options:
--dry-run              # Show what would be done without making changes
--verbose              # Show detailed progress information
--backup               # Create timestamped backup of existing .claude/ directory
--force                # Overwrite existing files without prompting
--source PATH          # Custom source directory (default: dev-handbook/.integrations/claude)

# Expected outputs:
# Success: Exit code 0, summary statistics printed
# Failure: Exit code 1, error messages printed
```

**Error Handling:**
- Missing source directory: "Error: No command directories found at [path]"
- Permission denied: "Error: Cannot write to [path]: Permission denied"
- Invalid project structure: "Warning: No agents directory found at [path]"

**Edge Cases:**
- Empty source directories: Continue with warning, report 0 items installed
- Corrupted YAML frontmatter: Skip file with warning, continue installation
- Concurrent installations: Use file locking to prevent corruption

### Success Criteria

- [ ] **Behavioral Outcome 1**: Installer correctly discovers and installs all Claude commands from workflow instructions
- [ ] **User Experience Goal 2**: Clear, actionable feedback provided at each phase of installation
- [ ] **System Performance 3**: Installation completes in under 5 seconds for typical project (50+ workflows)

### Validation Questions

- [ ] **Requirement Clarity**: Should the installer support partial installations (only commands, only agents)?
- [ ] **Edge Case Handling**: How should installer handle symbolic links in source directories?
- [ ] **User Experience**: Should verbose mode show file-by-file progress or just phase summaries?
- [ ] **Success Definition**: Should installation verify command syntax or just copy files?

## Objective

Refactor the existing `claude_commands_installer.rb` to follow ATOM architecture principles, improving maintainability, testability, and separation of concerns while maintaining all current functionality and user experience.

## Scope of Work

- Decompose monolithic ClaudeCommandsInstaller class into ATOM components
- Extract pure data structures into Models
- Create focused Molecules for file operations, metadata handling, and validation
- Build Organisms for orchestrating the installation workflow
- Maintain backward compatibility with existing CLI interface
- Improve test coverage and component isolation

### Deliverables

#### Behavioral Specifications
- Clear separation of concerns following ATOM principles
- Maintainable component structure with explicit dependencies
- Comprehensive test coverage for all components

#### Validation Artifacts
- Unit tests for each ATOM component
- Integration tests for the complete installation workflow
- Performance benchmarks showing no regression

## Out of Scope

- ❌ **Implementation Details**: Specific file structures, code organization patterns
- ❌ **Technology Decisions**: Testing framework choices, mocking strategies
- ❌ **Performance Optimization**: Caching strategies, parallel processing
- ❌ **Future Enhancements**: Plugin system, remote command sources

## References

- ADR-011: ATOM Architecture House Rules (.t.md)
- Current implementation: dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb
- ATOM architecture documentation: docs/architecture-tools.md
- Feedback source: Development feedback item #8