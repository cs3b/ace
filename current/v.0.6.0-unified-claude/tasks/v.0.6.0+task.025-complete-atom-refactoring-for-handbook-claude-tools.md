---
id: v.0.6.0+task.025
status: in-progress
priority: high
estimate: 6h
dependencies: [v.0.6.0+task.023]
---

# Complete ATOM Refactoring for Handbook Claude Tools

## Behavioral Specification

### User Experience
- **Input**: Developers use handbook claude commands (list, validate, generate-commands)
- **Process**: Commands execute with improved performance and maintainability
- **Output**: Same functionality as before but with better reliability and speed

### Expected Behavior
Users continue to experience the same handbook claude functionality:
- `handbook claude list` displays available Claude commands
- `handbook claude validate` checks command file validity
- `handbook claude generate-commands` creates command files from workflows

The commands should execute faster, be more maintainable, and have clearer error messages. From the user's perspective, the interface remains unchanged while the underlying architecture provides better reliability.

### Interface Contract
```bash
# List commands - unchanged interface
handbook claude list
# Expected: Lists all available Claude commands

# Validate commands - unchanged interface
handbook claude validate
# Expected: Validates all command files, reports issues

# Generate commands - unchanged interface
handbook claude generate-commands
# Expected: Generates command files from workflow specifications

# All commands maintain existing options and flags
handbook claude list --format json
handbook claude validate --path specific/path
handbook claude generate-commands --dry-run
```

**Error Handling:**
- File not found: Clear error message with suggested paths
- Invalid YAML: Detailed parsing error with line numbers
- Missing dependencies: List of required files or components

**Edge Cases:**
- Empty directories: Graceful handling with informative messages
- Malformed files: Specific error details for debugging
- Large file sets: Efficient processing without timeouts

### Success Criteria
- [ ] **Backward Compatibility**: All existing CLI interfaces work identically
- [ ] **Code Quality**: 60% reduction in code duplication across organisms
- [ ] **Performance**: Commands execute at least as fast as before refactoring
- [ ] **Maintainability**: Clear separation of concerns with ATOM architecture

### Validation Questions
- [ ] **Architecture Alignment**: Does the ATOM structure follow project patterns?
- [ ] **Performance Impact**: Will the refactoring improve or maintain speed?
- [ ] **Testing Strategy**: How to ensure no regression during refactoring?
- [ ] **Migration Path**: Should we refactor incrementally or all at once?

## Objective

Complete the ATOM architecture refactoring started in task 023, eliminating code duplication and improving maintainability while preserving all existing functionality and interfaces.

## Scope of Work

- **User Experience Scope**: All handbook claude command functionality remains unchanged
- **System Behavior Scope**: Internal architecture improvements for all three organisms
- **Interface Scope**: Public CLI interfaces and command outputs stay identical

### Deliverables

#### Behavioral Specifications
- Maintained command interfaces
- Consistent error handling
- Performance benchmarks

#### Validation Artifacts
- All existing tests continue passing
- Performance comparison reports
- Code duplication metrics

## Out of Scope

- ❌ **Implementation Details**: Specific class hierarchies or module structures
- ❌ **Technology Decisions**: Framework changes or library replacements
- ❌ **Performance Optimization**: Algorithm improvements beyond refactoring
- ❌ **Future Enhancements**: New features or additional commands

## References

- Task 023 partial implementation and analysis
- ATOM architecture documentation
- Existing handbook claude command specs

## Technical Approach

### Architecture Pattern
- Complete ATOM architecture implementation following ADR-011 house rules
- Build on existing atoms/molecules from task 023
- Extract remaining reusable components from organisms
- Ensure clear separation of concerns across all layers

### Technology Stack
- Ruby (>= 3.2) with existing ATOM framework
- dry-cli for command structure (unchanged)
- RSpec for comprehensive test coverage
- Existing atoms: WorkflowScanner, CommandExistenceChecker, YamlFrontmatterValidator
- Existing molecules: CommandMetadataInferrer, CommandTemplateRenderer (already exists)
- New molecules: CommandInventoryBuilder, CommandValidator

### Implementation Strategy
1. Create missing molecules (CommandInventoryBuilder, CommandValidator)
2. Refactor organisms to use all ATOM components
3. Eliminate code duplication between organisms
4. Ensure backward compatibility and test coverage
5. Performance verification and optimization

## Tool Selection

| Criteria | Task 023 Partial | Complete ATOM | Selected |
|----------|------------------|---------------|----------|
| Code Duplication | Reduced 40% | Reduced 60%+ | Complete |
| Component Reuse | Some atoms/molecules | Full component set | Complete |
| Test Coverage | Good | Excellent | Complete |
| Maintainability | Improved | Optimal | Complete |
| Performance | No degradation | No degradation | Complete |

**Selection Rationale:** Completing the ATOM refactoring will eliminate remaining code duplication, improve maintainability, and provide a comprehensive set of reusable components.

## File Modifications

### Create

#### Molecules (Behavior-Oriented Helpers)
- dev-tools/lib/coding_agent_tools/molecules/claude/command_inventory_builder.rb
  - Purpose: Build unified inventory of commands from multiple sources
  - Key components: Directory scanning, command categorization, installation status
  - Dependencies: WorkflowScanner, CommandExistenceChecker atoms

- dev-tools/lib/coding_agent_tools/molecules/claude/command_validator.rb
  - Purpose: Validate command coverage and consistency
  - Key components: Coverage checking, outdated detection, duplicate finding
  - Dependencies: CommandTemplateRenderer, WorkflowScanner, CommandInventoryBuilder

### Modify

- dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb
  - Changes: Remove infer_metadata (use CommandMetadataInferrer), remove workflow scanning (use WorkflowScanner), remove template rendering (use CommandTemplateRenderer)
  - Impact: Cleaner orchestration-only code
  - Integration points: WorkflowScanner, CommandMetadataInferrer, CommandTemplateRenderer, YamlFrontmatterValidator

- dev-tools/lib/coding_agent_tools/organisms/claude_command_lister.rb
  - Changes: Remove all inventory building logic (use CommandInventoryBuilder)
  - Impact: Simplified to orchestration only
  - Integration points: CommandInventoryBuilder, TableRenderer

- dev-tools/lib/coding_agent_tools/organisms/claude_validator.rb
  - Changes: Remove validation logic (use CommandValidator molecule)
  - Impact: Focus on orchestration and reporting
  - Integration points: CommandValidator, CommandInventoryBuilder

### Delete
- None - All existing files will be refactored, not deleted

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing CLI functionality during refactoring
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Run full test suite after each component extraction
  - **Rollback:** Git revert to previous working state

### Integration Risks
- **Risk:** Performance degradation from additional abstraction
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Benchmark key operations before/after
  - **Monitoring:** Time command execution in tests

- **Risk:** Missing edge cases when extracting shared logic
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Comprehensive unit tests for each new component
  - **Rollback:** Targeted fixes for specific issues

## Implementation Plan

### Planning Steps

* [ ] Analyze code duplication patterns across the three organisms
  > TEST: Duplication Analysis Complete
  > Type: Pre-condition Check
  > Assert: All duplicated code segments identified and categorized
  > Command: grep -n "def" dev-tools/lib/coding_agent_tools/organisms/claude*.rb | sort

* [ ] Review existing atoms/molecules to understand integration patterns

* [ ] Design interfaces for new molecules ensuring consistency

### Execution Steps

#### Phase 1: Create Missing Molecules

- [ ] Create CommandInventoryBuilder molecule
  > TEST: Inventory Builder Creation
  > Type: Unit Test
  > Assert: Molecule correctly builds command inventory from all sources
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/claude/command_inventory_builder_spec.rb

- [ ] Create CommandValidator molecule
  > TEST: Command Validator Creation
  > Type: Unit Test
  > Assert: Molecule validates coverage and detects issues correctly
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/claude/command_validator_spec.rb

#### Phase 2: Refactor ClaudeCommandGenerator Organism

- [ ] Extract workflow scanning to use WorkflowScanner atom
  > TEST: Workflow Scanning Integration
  > Type: Integration Test
  > Assert: Generator uses WorkflowScanner for all workflow discovery
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_generator_spec.rb -e "workflow"

- [ ] Replace infer_metadata with CommandMetadataInferrer molecule
  > TEST: Metadata Inference Integration
  > Type: Integration Test
  > Assert: Generator uses molecule for all metadata generation
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_generator_spec.rb -e "metadata"

- [ ] Use CommandTemplateRenderer for all template operations
  > TEST: Template Rendering Integration
  > Type: Integration Test
  > Assert: All template rendering goes through molecule
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_generator_spec.rb -e "template"

- [ ] Integrate YamlFrontmatterValidator for validation
  > TEST: YAML Validation Integration
  > Type: Integration Test
  > Assert: All YAML validation uses the atom
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_generator_spec.rb -e "yaml"

#### Phase 3: Refactor ClaudeCommandLister Organism

- [ ] Replace inventory building with CommandInventoryBuilder molecule
  > TEST: Inventory Builder Integration
  > Type: Integration Test
  > Assert: Lister delegates all inventory building to molecule
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_lister_spec.rb -e "inventory"

- [ ] Remove duplicated command scanning logic
  > TEST: No Direct Scanning
  > Type: Code Analysis
  > Assert: No direct file scanning in organism
  > Command: grep -n "Dir.glob" dev-tools/lib/coding_agent_tools/organisms/claude_command_lister.rb || echo "✓ No direct scanning"

- [ ] Simplify to pure orchestration logic
  > TEST: Orchestration Focus
  > Type: Integration Test
  > Assert: All existing lister tests pass
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_lister_spec.rb

#### Phase 4: Refactor ClaudeValidator Organism

- [ ] Replace validation logic with CommandValidator molecule
  > TEST: Validator Integration
  > Type: Integration Test
  > Assert: Organism uses molecule for all validation
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_validator_spec.rb -e "validation"

- [ ] Use CommandInventoryBuilder for command discovery
  > TEST: Inventory Usage
  > Type: Integration Test
  > Assert: Validator uses inventory builder
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_validator_spec.rb -e "inventory"

- [ ] Focus on orchestration and reporting only
  > TEST: Simplified Validator
  > Type: Integration Test
  > Assert: All validator tests pass
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_validator_spec.rb

#### Phase 5: Integration and Performance Testing

- [ ] Run full handbook claude command test suite
  > TEST: Full Integration Suite
  > Type: Integration Test
  > Assert: All CLI commands work identically
  > Command: bundle exec rspec spec/integration/handbook_claude*_spec.rb

- [ ] Test all CLI commands manually
  > TEST: Manual CLI Verification
  > Type: Manual Test
  > Assert: Commands produce identical output
  > Command: handbook claude list && handbook claude validate && handbook claude generate-commands --dry-run

- [ ] Measure performance impact
  > TEST: Performance Benchmark
  > Type: Performance Test
  > Assert: No significant degradation (< 5%)
  > Command: time handbook claude list --verbose > /dev/null

- [ ] Verify code duplication reduction
  > TEST: Duplication Metrics
  > Type: Code Analysis
  > Assert: 60%+ reduction in duplicated code
  > Command: flay dev-tools/lib/coding_agent_tools/organisms/claude*.rb

## Acceptance Criteria

- [x] All existing handbook claude commands maintain identical CLI interfaces
- [ ] All integration tests pass without modification
- [ ] Code duplication reduced by at least 60% across organisms
- [ ] Each new molecule has comprehensive unit tests
- [ ] Performance remains within 5% of original implementation
- [ ] All ATOM components follow ADR-011 classification rules