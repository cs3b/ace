---
id: v.0.3.0+task.111
status: done
priority: high
estimate: 4h
dependencies: []
---

# Remove install_binstubs Legacy Feature

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools | sed 's/^/    /'
```

_Result excerpt:_

```
.ace/tools/
├── bin/
├── config/
├── docs/
├── exe/
├── lib/
└── spec/
```

## Objective

Remove the legacy `install_binstubs` feature from the .ace/tools Ruby gem. This functionality was designed to generate shell wrapper scripts but is no longer used in the current project architecture. The feature includes CLI commands, business logic, configuration, and comprehensive test coverage that needs to be cleanly removed.

## Scope of Work

- Remove all binstub-related implementation files (CLI, organisms, molecules)
- Delete comprehensive test coverage for binstub functionality
- Remove configuration files and documentation references
- Clean up CLI command registration
- Ensure no orphaned dependencies remain

### Deliverables

#### Delete

- .ace/tools/lib/coding_agent_tools/cli/commands/install_binstubs.rb
- .ace/tools/lib/coding_agent_tools/organisms/binstub_installer.rb
- .ace/tools/lib/coding_agent_tools/molecules/binstub_generator.rb
- .ace/tools/config/binstub-aliases.yml
- .ace/tools/spec/coding_agent_tools/cli/commands/install_binstubs_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/binstub_installer_spec.rb
- .ace/tools/spec/coding_agent_tools/molecules/binstub_generator_spec.rb

#### Modify

- .ace/tools/lib/coding_agent_tools/cli.rb (remove CLI registration)
- .ace/tools/docs/user/task-manager.md (remove binstub references if any)

## Phases

1. Audit current binstub implementation and dependencies
2. Remove CLI command registration
3. Delete implementation files (commands, organisms, molecules)
4. Delete test files
5. Remove configuration files
6. Clean up documentation references
7. Verify no broken dependencies remain

## Implementation Plan

### Planning Steps

- [x] Analyze current binstub functionality to understand full scope
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All binstub-related files and their relationships are identified
  > Command: grep -r "install_binstubs\|binstubs" .ace/tools/
- [x] Research binstub feature usage and dependencies
- [x] Plan systematic removal approach following ATOM architecture

### Execution Steps

- [x] Remove CLI command registration from main CLI registry
- [x] Delete CLI command implementation file
  > TEST: Verify CLI Command Removed
  > Type: Action Validation
  > Assert: install_binstubs command is no longer available and file is deleted
  > Command: ls .ace/tools/lib/coding_agent_tools/cli/commands/install_binstubs.rb
- [x] Delete organism layer implementation (BinstubInstaller)
- [x] Delete molecule layer implementation (BinstubGenerator)  
- [x] Delete configuration file with binstub aliases
  > TEST: Verify Configuration Removed
  > Type: Action Validation
  > Assert: Configuration file is deleted and no references remain
  > Command: ls .ace/tools/config/binstub-aliases.yml
- [x] Delete all test files for binstub functionality
- [x] Clean up any documentation references to binstub installation
- [x] Run tests to ensure no broken dependencies
  > TEST: Verify No Broken Dependencies
  > Type: Integration Test
  > Assert: All tests pass and no references to removed binstub functionality remain
  > Command: cd .ace/tools && bin/test

## Acceptance Criteria

- [x] AC 1: All binstub-related files are deleted from the codebase.
- [x] AC 2: CLI no longer registers or provides install-binstubs command.
- [x] AC 3: All tests pass with no references to removed functionality.
- [x] AC 4: No orphaned dependencies or broken imports remain.
- [x] AC 5: Documentation is updated to remove binstub references.

## Out of Scope

- ❌ Removing any functionality that might still be using binstub concepts elsewhere
- ❌ Modifying the fundamental ATOM architecture patterns
- ❌ Changes to other CLI commands or tools

## References

Based on analysis of:
- .ace/tools/lib/coding_agent_tools/cli/commands/install_binstubs.rb
- .ace/tools/lib/coding_agent_tools/organisms/binstub_installer.rb  
- .ace/tools/lib/coding_agent_tools/molecules/binstub_generator.rb
- .ace/tools/config/binstub-aliases.yml
- Associated test files and CLI registration