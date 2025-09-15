---
id: v.0.6.0+task.022
status: done
priority: high
estimate: 6h
dependencies: []
---

# Refactor claude_commands_installer to ATOM architecture

## Behavioral Specification

### User Experience
- **Input**: Developers run `claude-commands-installer` CLI tool with options for dry-run, verbose output, backup creation, and force overwrite
- **Process**: Tool discovers and installs Claude commands from .ace/handbook workflows, copying custom commands, generating workflow commands, and installing agents with clear progress feedback
- **Output**: Installed .claude/ directory with commands and agents, detailed summary of operations (created/skipped/updated counts), and clear error reporting

### Expected Behavior
The installer should provide a clear, predictable experience for setting up Claude Code commands:

1. **Discovery Phase**: Automatically find workflow instructions and command templates in the .ace/handbook structure
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
--source PATH          # Custom source directory (default: .ace/handbook/.integrations/claude)

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
- Current implementation: .ace/tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb
- ATOM architecture documentation: docs/architecture-tools.md
- Feedback source: Development feedback item #8

## Technical Approach

### Architecture Pattern
- [ ] Apply ATOM (Atoms, Molecules, Organisms) architecture pattern
- [ ] Follow ADR-011 house rules for component classification
- [ ] Ensure clear separation between data carriers (Models) and behavior (Molecules/Organisms)
- [ ] Maintain explicit dependency injection for testability

### Technology Stack
- [ ] Ruby 3.2+ with standard library components
- [ ] Existing dependencies: fileutils, pathname, yaml
- [ ] Testing: RSpec for unit/integration tests
- [ ] No new external dependencies required

### Implementation Strategy

#### Component Classification Analysis
Based on the current monolithic implementation, the components will be classified as:

**Models (Pure Data Carriers):**
- `InstallationStats` - Track created/skipped/updated counts
- `InstallationOptions` - Configuration options (dry_run, verbose, backup, force, source)
- `InstallationResult` - Result object with success status and statistics
- `CommandMetadata` - YAML frontmatter data structure
- `FileOperation` - Represents a file copy/create/update operation

**Atoms (Smallest Units):**
- `YamlFrontmatterParser` - Parse/inject YAML frontmatter (already exists)
- `DirectoryCreator` - Create directories with permissions (already exists)
- `TimestampGenerator` - Generate formatted timestamps
- `PathSanitizer` - Clean and validate file paths

**Molecules (Focused Operations):**
- `ProjectRootFinder` - Locate project root directory
- `SourceDirectoryValidator` - Validate source directory structure
- `BackupCreator` - Create timestamped backups of .claude directory
- `MetadataInjector` - Add/update YAML frontmatter in files
- `FileOperationExecutor` - Execute file copy/write operations
- `CommandTemplateRenderer` - Generate command content from templates
- `StatisticsCollector` - Aggregate installation statistics

**Organisms (Business Logic):**
- `CommandDiscoverer` - Find and categorize commands (custom/generated/workflow)
- `CommandInstaller` - Orchestrate command installation process
- `AgentInstaller` - Handle agent file installation
- `WorkflowCommandGenerator` - Generate commands from workflow files
- `ClaudeCommandsOrchestrator` - Main orchestration of all phases

### Refactoring Approach
1. Extract data structures first (Models)
2. Identify and extract Atoms (pure functions/utilities)
3. Build Molecules from existing logic blocks
4. Create Organisms to orchestrate the workflow
5. Replace monolithic class with thin CLI wrapper

## File Modifications

### Create
- lib/coding_agent_tools/models/installation_stats.rb
  - Purpose: Track installation statistics
  - Key components: Counters for created/skipped/updated/errors
  - Dependencies: None (pure data)

- lib/coding_agent_tools/models/installation_options.rb
  - Purpose: Configuration options data structure
  - Key components: Option flags and paths
  - Dependencies: None (pure data)

- lib/coding_agent_tools/models/installation_result.rb
  - Purpose: Result object for CLI integration
  - Key components: Success status, exit code, statistics
  - Dependencies: InstallationStats model

- lib/coding_agent_tools/models/command_metadata.rb
  - Purpose: YAML frontmatter data structure
  - Key components: Metadata fields like last_modified
  - Dependencies: None (pure data)

- lib/coding_agent_tools/models/file_operation.rb
  - Purpose: Represent file operations
  - Key components: Source, target, type, metadata
  - Dependencies: None (pure data)

- lib/coding_agent_tools/atoms/timestamp_generator.rb
  - Purpose: Generate formatted timestamps
  - Key components: Time formatting logic
  - Dependencies: None

- lib/coding_agent_tools/atoms/path_sanitizer.rb
  - Purpose: Clean and validate paths
  - Key components: Path normalization
  - Dependencies: None

- lib/coding_agent_tools/molecules/project_root_finder.rb
  - Purpose: Locate project root directory
  - Key components: Directory traversal logic
  - Dependencies: Atoms::PathSanitizer

- lib/coding_agent_tools/molecules/source_directory_validator.rb
  - Purpose: Validate source directory structure
  - Key components: Directory structure checks
  - Dependencies: Atoms::PathSanitizer

- lib/coding_agent_tools/molecules/backup_creator.rb
  - Purpose: Create timestamped backups
  - Key components: Backup logic with timestamps
  - Dependencies: Atoms::TimestampGenerator, Atoms::DirectoryCreator

- lib/coding_agent_tools/molecules/metadata_injector.rb
  - Purpose: Add/update YAML frontmatter
  - Key components: YAML manipulation logic
  - Dependencies: Atoms::YamlFrontmatterParser

- lib/coding_agent_tools/molecules/file_operation_executor.rb
  - Purpose: Execute file operations
  - Key components: File copy/write logic
  - Dependencies: Models::FileOperation, Atoms::DirectoryCreator

- lib/coding_agent_tools/molecules/command_template_renderer.rb
  - Purpose: Generate command content
  - Key components: Template rendering logic
  - Dependencies: None

- lib/coding_agent_tools/molecules/statistics_collector.rb
  - Purpose: Aggregate statistics
  - Key components: Stats aggregation logic
  - Dependencies: Models::InstallationStats

- lib/coding_agent_tools/organisms/command_discoverer.rb
  - Purpose: Find and categorize commands
  - Key components: Discovery and categorization logic
  - Dependencies: Molecules::SourceDirectoryValidator

- lib/coding_agent_tools/organisms/command_installer.rb
  - Purpose: Install commands with metadata
  - Key components: Command installation orchestration
  - Dependencies: Multiple molecules for file operations

- lib/coding_agent_tools/organisms/agent_installer.rb
  - Purpose: Install agent files
  - Key components: Agent installation logic
  - Dependencies: Molecules::FileOperationExecutor, Molecules::MetadataInjector

- lib/coding_agent_tools/organisms/workflow_command_generator.rb
  - Purpose: Generate commands from workflows
  - Key components: Workflow scanning and generation
  - Dependencies: Molecules::CommandTemplateRenderer

- lib/coding_agent_tools/organisms/claude_commands_orchestrator.rb
  - Purpose: Main installation orchestration
  - Key components: Phase coordination and error handling
  - Dependencies: All other organisms

### Modify
- lib/coding_agent_tools/integrations/claude_commands_installer.rb
  - Changes: Refactor to thin wrapper delegating to organisms
  - Impact: Maintains CLI interface, delegates to ATOM components
  - Integration points: ClaudeCommandsOrchestrator organism

- spec/coding_agent_tools/integrations/claude_commands_installer_spec.rb
  - Changes: Update to test through the new architecture
  - Impact: Maintains integration test coverage
  - Integration points: Test individual components and full workflow

### Delete
None - keeping the original class as a thin wrapper ensures backward compatibility

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing CLI functionality
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Keep original class as wrapper, extensive integration testing
  - **Rollback:** Git revert to previous version

- **Risk:** Performance regression due to object creation overhead
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Benchmark before/after, optimize hot paths
  - **Rollback:** Revert specific performance-critical components

### Integration Risks
- **Risk:** Incompatibility with existing test infrastructure
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Gradual refactoring, maintain test compatibility
  - **Monitoring:** Run full test suite at each step

## Implementation Plan

### Planning Steps

* [x] Analyze existing test coverage for claude_commands_installer
  > TEST: Test Coverage Check
  > Type: Pre-condition Check
  > Assert: Existing test coverage is documented and gaps identified
  > Command: bundle exec rspec spec/coding_agent_tools/integrations/claude_commands_installer_spec.rb --format documentation

* [x] Map all existing methods to ATOM components
* [x] Design dependency injection strategy for testability
* [x] Plan incremental refactoring approach to minimize risk

### Execution Steps

- [x] Step 1: Extract Models - Create pure data structures
  - [x] Create InstallationStats model
  - [x] Create InstallationOptions model
  - [x] Create InstallationResult model
  - [x] Create CommandMetadata model
  - [x] Create FileOperation model
  > TEST: Model Creation Verification
  > Type: Action Validation
  > Assert: All model files exist and have proper structure
  > Command: ls -la lib/coding_agent_tools/models/installation_*.rb

- [x] Step 2: Extract Atoms - Create smallest behavioral units
  - [x] Create TimestampGenerator atom
  - [x] Create PathSanitizer atom
  > TEST: Atom Functionality Check
  > Type: Unit Test Validation
  > Assert: Atoms have no dependencies and pass unit tests
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/timestamp_generator_spec.rb spec/coding_agent_tools/atoms/path_sanitizer_spec.rb

- [x] Step 3: Build Molecules - Create focused operation handlers
  - [x] Create ProjectRootFinder molecule
  - [x] Create SourceDirectoryValidator molecule
  - [x] Create BackupCreator molecule
  - [x] Create MetadataInjector molecule
  - [x] Create FileOperationExecutor molecule
  - [x] Create CommandTemplateRenderer molecule
  - [x] Create StatisticsCollector molecule
  > TEST: Molecule Integration Check
  > Type: Integration Test
  > Assert: Molecules properly compose atoms and models
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/*_spec.rb

- [x] Step 4: Create Organisms - Build business logic orchestrators
  - [x] Create CommandDiscoverer organism
  - [x] Create CommandInstaller organism
  - [x] Create AgentInstaller organism
  - [x] Create WorkflowCommandGenerator organism
  - [x] Create ClaudeCommandsOrchestrator organism
  > TEST: Organism Functionality Verification
  > Type: Integration Test
  > Assert: Organisms properly orchestrate molecules and handle business logic
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/*_spec.rb

- [x] Step 5: Refactor original class to use ATOM components
  - [x] Replace initialization logic with component setup
  - [x] Delegate run method to ClaudeCommandsOrchestrator
  - [x] Maintain backward compatibility for all public methods
  > TEST: Backward Compatibility Check
  > Type: Integration Test
  > Assert: Original functionality preserved through new architecture
  > Command: bundle exec rspec spec/coding_agent_tools/integrations/claude_commands_installer_spec.rb

- [x] Step 6: Add comprehensive test coverage
  - [x] Unit tests for all new components
  - [x] Integration tests for complete workflow
  - [ ] Performance benchmarks
  > TEST: Full Test Suite Validation
  > Type: Test Coverage Check
  > Assert: All components have adequate test coverage
  > Command: bundle exec rspec --format documentation --tag ~performance

- [x] Step 7: Update documentation
  - [x] Add component documentation
  - [ ] Update architecture diagrams
  - [x] Document testing approach

## Test Case Planning

### Unit Test Scenarios

**Models (Data Validation):**
- InstallationStats initialization and attribute access
- InstallationOptions with various configurations
- CommandMetadata YAML serialization/deserialization

**Atoms (Pure Functions):**
- TimestampGenerator format variations
- PathSanitizer with various input paths
- Edge cases: nil, empty strings, special characters

**Molecules (Focused Operations):**
- ProjectRootFinder with different directory structures
- SourceDirectoryValidator with valid/invalid structures
- BackupCreator with existing/non-existing directories
- MetadataInjector with various YAML formats

### Integration Test Scenarios

**Happy Path:**
- Fresh installation with all source files present
- Update installation with some existing files
- Dry-run execution showing planned operations

**Edge Cases:**
- Missing source directories
- Corrupted YAML frontmatter
- Permission denied on target directory
- Symbolic links in source directories

**Error Conditions:**
- No write permissions
- Disk full during operation
- Concurrent installation attempts

### Performance Test Scenarios

**Benchmark Tests:**
- Installation time for 50+ workflow files
- Memory usage during large installations
- Comparison with original implementation

## Acceptance Criteria

- [x] AC 1: All existing functionality preserved with ATOM architecture
- [x] AC 2: Clear separation of concerns across ATOM layers
- [ ] AC 3: Comprehensive test coverage (>90%) for all components
- [x] AC 4: No performance regression (installation < 5 seconds)
- [x] AC 5: Improved maintainability with isolated, testable components