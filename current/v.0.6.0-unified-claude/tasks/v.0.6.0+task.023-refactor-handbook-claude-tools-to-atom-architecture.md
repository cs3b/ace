---
id: v.0.6.0+task.023
status: in-progress
priority: high
estimate: 8h
dependencies: []
---

# Refactor handbook claude tools to ATOM architecture

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents invoke handbook claude commands (`handbook claude generate-commands`, `handbook claude list`, etc.)
- **Process**: Commands execute efficiently with clear feedback, leveraging reusable ATOM components
- **Output**: Same outputs as current implementation but with improved performance, maintainability, and consistency

### Expected Behavior
The refactored handbook claude tools should maintain all existing functionality while following the ATOM architecture pattern. The system should:

1. **Maintain Current Interface**: All existing commands continue to work with the same CLI interface
2. **Improve Code Organization**: Separate concerns into Atoms, Molecules, and Organisms layers
3. **Enhance Reusability**: Extract common functionality into reusable components
4. **Ensure Testability**: Each component should be independently testable
5. **Follow ATOM Principles**: Adhere to the house rules defined in ADR-011

### Interface Contract
```bash
# CLI Interface (unchanged)
handbook claude generate-commands [--dry-run] [--force] [--workflow PATTERN]
handbook claude list [--verbose] [--type TYPE] [--format FORMAT]
handbook claude integrate [OPTIONS]
handbook claude validate [OPTIONS]

# Expected outputs remain the same
# Error handling remains consistent with current implementation
```

**Error Handling:**
- [Missing workflow files]: Report which workflows are missing
- [Invalid YAML frontmatter]: Warn about invalid YAML but continue processing
- [File system errors]: Clear error messages with recovery suggestions

**Edge Cases:**
- [Empty workflow directory]: Gracefully handle with informative message
- [Concurrent command execution]: Ensure file operations are safe
- [Large number of workflows]: Maintain performance with hundreds of workflows

### Success Criteria
- [ ] **Behavioral Outcome 1**: All existing handbook claude commands work exactly as before
- [ ] **User Experience Goal 2**: Command execution time remains the same or improves
- [ ] **System Performance 3**: Memory usage is reduced through better component design

### Validation Questions
- [ ] **Requirement Clarity**: Which specific components can be extracted as reusable Atoms?
- [ ] **Edge Case Handling**: How should the system handle partial command generation failures?
- [ ] **User Experience**: Should we add progress indicators for long-running operations?
- [ ] **Success Definition**: What performance benchmarks should we measure?

## Objective

Refactor the handbook claude tools implementation to follow the ATOM architecture pattern, improving code maintainability, testability, and reusability while maintaining all existing functionality and interfaces.

## Scope of Work

- Analyze current implementation to identify reusable components
- Extract common functionality into Atoms (indivisible utilities)
- Create Molecules for behavior-oriented helpers
- Refactor Organisms to use new Atoms and Molecules
- Ensure all tests continue to pass
- Maintain backward compatibility for all CLI commands

### Deliverables

#### Behavioral Specifications
- Analysis of current implementation patterns
- Identification of reusable components
- ATOM architecture mapping for claude tools

#### Validation Artifacts
- Test coverage for all refactored components
- Performance benchmarks before and after refactoring
- Integration test scenarios

## Out of Scope

- ❌ Changing the CLI interface or command structure
- ❌ Adding new features or functionality
- ❌ Modifying other handbook commands (only claude subcommands)
- ❌ Performance optimizations beyond ATOM refactoring benefits
- ❌ Integration with external services or APIs

## Technical Approach

### Architecture Pattern
- ATOM architecture pattern with clear separation between Atoms (indivisible utilities), Molecules (behavior-oriented helpers), and Organisms (business logic orchestration)
- Leverage existing Atoms for common operations (file I/O, path resolution, YAML parsing)
- Extract reusable components from current Organisms into appropriate layers
- Maintain backward compatibility for all CLI interfaces

### Technology Stack
- Ruby (>= 3.2) with existing ATOM framework
- dry-cli for command structure (unchanged)
- RSpec for comprehensive test coverage
- Existing atoms: ProjectRootDetector, YamlReader, TableRenderer, FileSystemScanner
- Existing molecules: FileIOHandler, MetadataNormalizer, PathResolver

### Implementation Strategy
1. Analyze current implementation to identify reusable components
2. Extract common functionality into Atoms and Molecules
3. Refactor Organisms to use new components
4. Ensure all tests continue to pass
5. Maintain CLI interface compatibility

## Tool Selection

| Criteria | Current Monolithic | ATOM Refactored | Selected |
|----------|-------------------|-----------------|----------|
| Maintainability | Fair - Logic mixed in Organisms | Excellent - Clear separation | ATOM |
| Testability | Good - Integration tests | Excellent - Unit testable | ATOM |
| Reusability | Poor - Duplicated code | Excellent - Shared components | ATOM |
| Performance | Good | Good - Minimal overhead | ATOM |
| Learning Curve | Low | Low - Follows existing patterns | ATOM |

**Selection Rationale:** ATOM architecture provides better maintainability, testability, and reusability without performance penalties while following established project patterns.

## File Modifications

### Create

#### Atoms (Indivisible Utilities)
- dev-tools/lib/coding_agent_tools/atoms/claude/workflow_scanner.rb
  - Purpose: Scan workflow directory for .wf.md files
  - Key components: Directory traversal, file filtering
  - Dependencies: None (pure utility)

- dev-tools/lib/coding_agent_tools/atoms/claude/command_existence_checker.rb
  - Purpose: Check if a command file exists in various locations
  - Key components: Path checking logic
  - Dependencies: None

- dev-tools/lib/coding_agent_tools/atoms/claude/yaml_frontmatter_validator.rb
  - Purpose: Validate YAML frontmatter in generated commands
  - Key components: YAML parsing and validation
  - Dependencies: None

#### Molecules (Behavior-Oriented Helpers)
- dev-tools/lib/coding_agent_tools/molecules/claude/command_metadata_inferrer.rb
  - Purpose: Infer metadata from workflow names (description, allowed-tools, etc.)
  - Key components: Pattern matching, metadata generation
  - Dependencies: None

- dev-tools/lib/coding_agent_tools/molecules/claude/command_template_renderer.rb
  - Purpose: Render command templates with metadata
  - Key components: Template processing, YAML generation
  - Dependencies: command_metadata_inferrer

- dev-tools/lib/coding_agent_tools/molecules/claude/command_inventory_builder.rb
  - Purpose: Build unified inventory of commands from multiple sources
  - Key components: Directory scanning, command categorization
  - Dependencies: workflow_scanner, command_existence_checker

- dev-tools/lib/coding_agent_tools/molecules/claude/command_validator.rb
  - Purpose: Validate command coverage and consistency
  - Key components: Coverage checking, outdated detection
  - Dependencies: command_template_renderer, workflow_scanner

#### Models (Data Carriers)
- dev-tools/lib/coding_agent_tools/models/claude_command.rb
  - Purpose: Represent a Claude command with all its attributes
  - Key components: name, type, path, installed status, validity
  - Dependencies: None

- dev-tools/lib/coding_agent_tools/models/claude_validation_result.rb
  - Purpose: Carry validation results data
  - Key components: missing, outdated, duplicates, orphaned commands
  - Dependencies: None

### Modify
- dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb
  - Changes: Refactor to use new atoms/molecules, remove duplicated logic
  - Impact: Cleaner code, better testability
  - Integration points: Uses workflow_scanner, command_metadata_inferrer, command_template_renderer

- dev-tools/lib/coding_agent_tools/organisms/claude_command_lister.rb
  - Changes: Refactor to use command_inventory_builder, remove scanning logic
  - Impact: Simplified orchestration, reusable inventory building
  - Integration points: Uses command_inventory_builder, existing TableRenderer

- dev-tools/lib/coding_agent_tools/organisms/claude_validator.rb
  - Changes: Refactor to use command_validator molecule, simplify orchestration
  - Impact: Cleaner separation of validation logic
  - Integration points: Uses command_validator, validation result model

### Delete
- None - All existing files will be refactored, not deleted

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing CLI interfaces
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Comprehensive integration tests, no changes to CLI command classes
  - **Rollback:** Git revert if issues detected

- **Risk:** Performance degradation from additional abstraction layers
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Benchmark before/after, optimize hot paths
  - **Rollback:** Revert specific performance-impacting changes

### Integration Risks
- **Risk:** Missing edge cases in refactored logic
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Maintain all existing tests, add unit tests for new components
  - **Monitoring:** Run full test suite after each component extraction

## Implementation Plan

### Planning Steps

* [x] Analyze current organisms to identify all reusable components and patterns
  > TEST: Component Analysis Complete
  > Type: Pre-condition Check
  > Assert: All reusable logic identified and categorized by ATOM layer
  > Command: grep -r "def" dev-tools/lib/coding_agent_tools/organisms/claude*.rb | wc -l

* [x] Design atom interfaces for indivisible utilities
* [x] Design molecule interfaces for behavior-oriented helpers
* [x] Plan test strategy for new components

### Execution Steps

#### Phase 1: Create Atoms (Indivisible Utilities)

- [x] Create workflow_scanner atom for scanning .wf.md files
  > TEST: Workflow Scanner Functionality
  > Type: Unit Test
  > Assert: Scanner correctly finds all workflow files
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/claude/workflow_scanner_spec.rb

- [x] Create command_existence_checker atom for checking command presence
  > TEST: Command Existence Checker
  > Type: Unit Test
  > Assert: Correctly checks all possible command locations
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/claude/command_existence_checker_spec.rb

- [x] Create yaml_frontmatter_validator atom for YAML validation
  > TEST: YAML Validator
  > Type: Unit Test
  > Assert: Validates YAML frontmatter correctly
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/claude/yaml_frontmatter_validator_spec.rb

#### Phase 2: Create Models (Data Carriers)

- [x] Create claude_command model for command representation
- [x] Create claude_validation_result model for validation results

#### Phase 3: Create Molecules (Behavior Helpers)

- [x] Create command_metadata_inferrer molecule
  > TEST: Metadata Inference
  > Type: Unit Test
  > Assert: Correctly infers metadata from workflow names
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/claude/command_metadata_inferrer_spec.rb

- [ ] Create command_template_renderer molecule
  > TEST: Template Rendering
  > Type: Unit Test
  > Assert: Renders valid command files with metadata
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/claude/command_template_renderer_spec.rb

- [ ] Create command_inventory_builder molecule
  > TEST: Inventory Building
  > Type: Unit Test
  > Assert: Builds complete inventory from all sources
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/claude/command_inventory_builder_spec.rb

- [ ] Create command_validator molecule
  > TEST: Command Validation
  > Type: Unit Test
  > Assert: Validates coverage and consistency correctly
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/claude/command_validator_spec.rb

#### Phase 4: Refactor Organisms

- [ ] Refactor ClaudeCommandGenerator to use new components
  > TEST: Generator Integration
  > Type: Integration Test
  > Assert: All existing generator tests pass
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_generator_spec.rb

- [ ] Refactor ClaudeCommandLister to use new components
  > TEST: Lister Integration
  > Type: Integration Test
  > Assert: All existing lister tests pass
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_lister_spec.rb

- [ ] Refactor ClaudeValidator to use new components
  > TEST: Validator Integration
  > Type: Integration Test
  > Assert: All existing validator tests pass
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_validator_spec.rb

#### Phase 5: Integration Testing

- [ ] Run full integration test suite
  > TEST: Full CLI Integration
  > Type: Integration Test
  > Assert: All handbook claude commands work as before
  > Command: bundle exec rspec spec/integration/handbook_claude_*_spec.rb

- [ ] Test CLI commands manually
  > TEST: Manual CLI Verification
  > Type: Manual Test
  > Assert: Commands produce identical output
  > Command: bin/handbook claude list --verbose

- [ ] Run performance benchmarks
  > TEST: Performance Benchmark
  > Type: Performance Test
  > Assert: No significant performance degradation
  > Command: bundle exec ruby benchmark/claude_tools_benchmark.rb

## Acceptance Criteria

- [ ] All existing handbook claude commands maintain identical CLI interfaces and outputs
- [ ] All existing tests continue to pass without modification
- [ ] New ATOM components follow ADR-011 classification rules:
  - Atoms are pure utilities with no dependencies
  - Molecules compose atoms for focused behaviors
  - Models are pure data carriers
  - Organisms orchestrate molecules and atoms
- [ ] Code duplication is eliminated between the three claude organisms
- [ ] Each new component has appropriate unit tests
- [ ] Performance remains comparable (within 5% of original)
- [ ] Documentation is updated to reflect new architecture

## References

- Original feedback item: "Refactor handbook claude tools to ATOM - Check the whole implementation of handbook claude <tool> and check if anything should be refactored at lower level of the ATOM architecture, is there anything that can be reused between commands"
- ADR-011: ATOM Architecture House Rules
- Current implementation files:
  - dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb
  - dev-tools/lib/coding_agent_tools/organisms/claude_command_lister.rb
  - dev-tools/lib/coding_agent_tools/organisms/claude_validator.rb
- Related test files:
  - dev-tools/spec/integration/handbook_claude_list_spec.rb
  - dev-tools/spec/integration/handbook_claude_cli_spec.rb