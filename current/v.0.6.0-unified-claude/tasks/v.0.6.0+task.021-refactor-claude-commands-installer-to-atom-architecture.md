---
id: v.0.6.0+task.021
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Refactor Claude Commands Installer to ATOM Architecture

## Behavioral Specification

### User Experience
- **Input**: Users execute `handbook claude integrate` command with optional flags
- **Process**: System scans workflow instructions, generates commands, copies custom/generated commands and agents with progress feedback
- **Output**: Installed Claude commands in `.claude/` directory with summary statistics

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

The Claude commands installer provides a seamless experience for installing Claude Code integration commands. When users run the installation command, the system:

1. Validates the project structure and source directories
2. Creates necessary target directories if they don't exist  
3. Optionally backs up existing installations when requested
4. Scans workflow instructions to identify required commands
5. Generates command files from workflow templates
6. Copies custom commands and agents with metadata injection
7. Provides clear progress feedback throughout the process
8. Reports installation statistics and any errors encountered

The entire process maintains backward compatibility with existing workflows while providing enhanced reliability and maintainability through ATOM architecture.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface
handbook claude integrate [OPTIONS]
  --dry-run         # Show what would be installed without modifying files
  --verbose         # Show detailed installation information  
  --backup          # Backup existing installation before proceeding
  --force           # Overwrite existing files without prompting
  --source PATH     # Use custom source directory instead of default

# Expected outputs
Installing Claude commands...
Project root: /path/to/project

Copying commands:
  ✓ Created: commit.md
  ✓ Created: draft-task.md
  ✗ Skipped: existing-command.md (already exists)

Copying agents:
  ✓ Created: code-review.md

Creating command files...
Found 19 workflow files
  ✓ Created: create-adr.md
  ✓ Created: fix-tests.md

==================================================
Installation complete:
  Location: /path/to/project/.claude/
  Commands: 25
  Agents: 2

Run 'claude code' to use the new commands
==================================================

# Exit codes
0 - Success
1 - Failure (with error details)
```

**Error Handling:**
- Missing source directory: Clear error message with path information
- Permission denied: Suggest running with appropriate permissions
- Disk space issues: Report available space and requirements
- Invalid YAML: Warning with file name and continue installation

**Edge Cases:**
- Empty workflow directory: Complete successfully with warning
- Circular dependencies: Detect and report without failing
- Large installations: Show progress for operations over 10 files
- Interrupted installation: Leave system in consistent state

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Behavioral Outcome 1**: Users can install Claude commands using the same CLI interface without learning new commands
- [ ] **User Experience Goal 2**: Installation provides real-time progress feedback and completes within 5 seconds for typical projects
- [ ] **System Performance 3**: All installed commands function identically to previous implementation with improved error handling

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [x] **Requirement Clarity**: Should the installer support multiple source directories or just one custom source?
- [x] **Edge Case Handling**: How should the system handle corrupted or invalid workflow files during scanning?
- [x] **User Experience**: Should dry-run mode show file sizes and modification times for better decision making?
- [x] **Success Definition**: Is maintaining exact output format important for scripts that parse the output?

## Objective

Refactor the existing Claude commands installer to follow ATOM architecture principles, improving code maintainability, testability, and separation of concerns while maintaining complete backward compatibility with the current user interface and behavior.

## Scope of Work

- **User Experience Scope**: All existing CLI commands and options must work identically
- **System Behavior Scope**: Installation process, file operations, and error handling remain unchanged from user perspective
- **Interface Scope**: `handbook claude integrate` command with all existing flags

### Deliverables

#### Behavioral Specifications
- Maintained user experience with existing CLI interface
- Enhanced error handling and progress reporting
- Consistent installation behavior across environments

#### Validation Artifacts
- Comprehensive test suite validating ATOM architecture
- Integration tests ensuring backward compatibility
- Performance benchmarks showing no regression

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: Specific ATOM component organization and file structures
- ❌ **Technology Decisions**: Choice of specific Ruby patterns or internal APIs
- ❌ **Performance Optimization**: Internal optimization strategies beyond user-visible performance
- ❌ **Future Enhancements**: Additional features not currently in the installer

## References

- Feedback item #8 from task review
- Current implementation: dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb
- ATOM architecture examples: dev-tools/lib/coding_agent_tools/organisms/
- Integration tests: dev-tools/spec/integrations/claude_commands_installer_spec.rb