---

id: v.0.3.0+task.16
status: done
priority: high
estimate: 16h
dependencies: [v.0.3.0+task.06]
---

# Implement Template Synchronizer with CLI Command

## 0. Directory Audit ✅

_Command run:_

```bash
wc -l dev-tools/exe-old/markdown-sync-embedded-documents | sed 's/^/    /'
```

_Result excerpt:_

```
    442 dev-tools/exe-old/markdown-sync-embedded-documents
```

## Objective

Implement the complete template synchronization system including the TemplateSynchronizer organism and CLI command to handle complex markdown template synchronization functionality, supporting both `<templates>` and `<documents>` XML formats with dry-run and auto-commit capabilities. This replaces the 442-line `markdown-sync-embedded-documents` tool with a proper ATOM architecture implementation.

## Scope of Work

* Implement template_synchronizer.rb organism
* Port markdown-sync-embedded-documents logic (442 lines)
* Support XML parsing for both `<templates>` and `<documents>` formats including `<guide>` tags
* Implement dry-run mode with diff preview
* Add auto-commit functionality
* Handle complex file synchronization with security validation
* Implement `handbook sync-templates` CLI command
* Update binstub with modernized interface
* Create handbook CLI namespace structure

### Deliverables

#### Create

* lib/coding_agent_tools/organisms/task_management/template_synchronizer.rb
* lib/coding_agent_tools/molecules/task_management/xml_template_parser.rb
* lib/coding_agent_tools/molecules/task_management/file_synchronizer.rb
* lib/coding_agent_tools/cli/commands/handbook/ (directory)
* lib/coding_agent_tools/cli/commands/handbook/sync_templates.rb
* dev-tools/exe/handbook (executable)
* Corresponding spec files for all components

#### Modify

* bin/markdown-sync-embedded-documents (update to use gem)
* lib/coding_agent_tools/cli/commands.rb (add handbook command registration)
* lib/coding_agent_tools/cli.rb (register handbook commands)

#### Delete

* dev-taskflow/current/v.0.3.0-migration/tasks/v.0.3.0+task.17-implement-sync-templates-command.md

## Phases

1. Analyze complex synchronization logic and XML format requirements
2. Create handbook CLI namespace structure
3. Implement XML parsing molecules with comprehensive format support
4. Implement file synchronization logic with security integration
5. Implement TemplateSynchronizer organism
6. Create CLI command with ExecutableWrapper pattern
7. Create handbook-sync-templates executable
8. Update binstub for backward compatibility
8. Comprehensive testing with XML edge cases

## Implementation Plan

### Planning Steps

* [x] Deep dive into 442-line synchronization logic and XML format analysis
  > TEST: Logic Analysis
  > Type: Pre-condition Check
  > Assert: XML formats and sync logic understood, including guide tags
  > Command: grep -E "templates|documents|guide" dev-tools/exe-old/markdown-sync-embedded-documents | wc -l
* [x] Analyze existing CLI patterns (task-manager, code-review, nav-path)
  > TEST: Pattern Analysis
  > Type: Research Check
  > Assert: ExecutableWrapper pattern and project namespace approach understood
  > Command: find dev-tools/lib/coding_agent_tools/cli/commands -name "*.rb" | head -5
* [x] Review security integration patterns from FileIOHandler
  > TEST: Security Integration
  > Type: Research Check
  > Assert: Security validation patterns understood
  > Command: grep -n "SecurePathValidator\|FileOperationConfirmer" dev-tools/lib/coding_agent_tools/molecules/file_io_handler.rb
* [x] Design extensible XML parser architecture for current and future formats
* [x] Plan file synchronization strategy with security validation
* [x] Design CLI command structure with handbook namespace

### Execution Steps

- [x] Create handbook CLI namespace directory structure
- [x] Create xml_template_parser.rb molecule with comprehensive XML format support
  > TEST: XML Format Support
  > Type: Unit Test
  > Assert: Parses current formats and supports extensible format registration
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/task_management/xml_template_parser_spec.rb -e "format_support"
- [x] Create file_synchronizer.rb molecule with security integration
  > TEST: Security Integration
  > Type: Unit Test
  > Assert: Uses SecurePathValidator and FileOperationConfirmer
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/task_management/file_synchronizer_spec.rb -e "security"
- [x] Implement TemplateSynchronizer organism structure
  > TEST: Basic Structure
  > Type: Unit Test
  > Assert: Organism initializes correctly and coordinates molecules
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/organisms/task_management/template_synchronizer_spec.rb -e "initialize"
- [x] Port XML parsing logic for all formats (templates, documents, guide tags)
  > TEST: XML Parsing Edge Cases
  > Type: Unit Test
  > Assert: Handles malformed XML, missing files, empty content gracefully
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/task_management/xml_template_parser_spec.rb -e "edge_cases"
- [x] Implement file extraction and synchronization with security validation
- [x] Add dry-run mode with diff preview
  > TEST: Dry Run Mode
  > Type: Integration Test
  > Assert: Dry-run shows changes without applying, respects security constraints
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/organisms/task_management/template_synchronizer_spec.rb -e "dry_run"
- [x] Implement auto-commit functionality
- [x] Create handbook sync-templates CLI command using ExecutableWrapper pattern
  > TEST: CLI Command Options
  > Type: CLI Test
  > Assert: Supports dry-run, commit, path options matching original tool
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools handbook sync-templates --help
- [x] Create handbook executable using ExecutableWrapper pattern
  > TEST: Direct Executable
  > Type: CLI Test
  > Assert: Direct executable works with all options, follows code-review pattern
  > Command: cd dev-tools && exe/handbook sync-templates --help
- [x] Update bin/markdown-sync-embedded-documents binstub
  > TEST: Binstub Compatibility
  > Type: Integration Test
  > Assert: Binstub maintains backward compatibility with original options
  > Command: bin/markdown-sync-embedded-documents --help 2>&1 | grep -E "dry-run|commit|path"
- [x] Add comprehensive error handling for all failure modes
- [x] Create extensive test coverage for XML parsing, file operations, and CLI scenarios

## Acceptance Criteria

* [x] Parses both `<templates>` and `<documents>` XML formats including `<guide>` tags
* [x] Extracts embedded content to correct file paths with security validation
* [x] Dry-run mode shows diffs without changes and respects security constraints
* [x] Auto-commit creates proper git commits when changes are made
* [x] Handles missing directories and files gracefully with clear error messages
* [x] CLI command uses modern option design while maintaining core functionality
* [x] Direct executable (handbook) provides convenient access
* [x] File path arguments are handled correctly with security validation
* [x] Binstub provides modernized interface (backward compatibility not required)
* [x] Maintains core functionality of original tool with modernized interface
* [x] Integrates with existing security framework (SecurePathValidator, FileOperationConfirmer)
* [x] Follows established ATOM architecture patterns
* [x] Comprehensive test coverage including edge cases and error scenarios

## Out of Scope

* ❌ Adding new XML formats beyond templates, documents, and guide tags
* ❌ Modifying synchronization behavior beyond exact port from original
* ❌ Integration with other template systems
* ❌ Performance optimizations beyond what original tool provided
* ❌ Adding new CLI options beyond original tool's functionality
* ❌ Refactoring task-manager to use ExecutableWrapper (should be separate task)

## References

* Dependency: v.0.3.0+task.06 (molecules implementation)
* Original tool: dev-tools/exe-old/markdown-sync-embedded-documents (442 lines)
* Most complex tool in the migration
* XML format examples in workflow documentation
* Merged task: v.0.3.0+task.17 (CLI command implementation)
* Similar patterns: code-review command (ExecutableWrapper), nav-path (handbook structure)
* Executable pattern: handbook-sync-templates should use ExecutableWrapper like code-review (not manual registration like task-manager)
* Note: task-manager should be refactored to use ExecutableWrapper pattern for consistency
* Security patterns: FileIOHandler molecule (security integration)
* CLI patterns: task-manager executable (direct CLI registration)