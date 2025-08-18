---
id: v.0.5.0+task.018
status: done
priority: high
estimate: 4h
dependencies: []
---

# Support multiple presets and input files in context tool

## Behavioral Context

**Key Behavioral Requirements**:
- Users can specify multiple presets with comma-separated syntax: `--preset project,dev-tools`
- Users can pass multiple input files as arguments: `context file1.md file2.md`
- Contexts from multiple sources are intelligently merged with deduplication
- Output path is resolved intelligently based on conflict rules
- All commands and errors are preserved with source attribution

## Objective

Enable the context tool to combine multiple presets and/or multiple input files into a single merged context output. This allows users to compose contexts from various sources flexibly, supporting complex development workflows that need information from multiple project components.

## Scope of Work

- Extend command definition to accept array inputs for presets and files
- Implement context merging functionality with smart deduplication
- Add intelligent output path resolution with conflict handling
- Preserve source attribution for debugging and transparency
- Maintain backward compatibility with single preset/file usage

### Deliverables

#### Create

- lib/coding_agent_tools/cli/commands/context/merger.rb
- spec/integration/context_multiple_sources_spec.rb

#### Modify

- lib/coding_agent_tools/cli/commands/context.rb
- spec/coding_agent_tools/cli/commands/context_spec.rb

## Phases

1. Audit existing context tool architecture and preset handling
2. Design context merging module with deduplication logic
3. Implement multiple preset support with output resolution
4. Implement multiple input file support
5. Add comprehensive testing for all combinations

## Technical Approach

### Architecture Pattern
- [ ] **Composer Pattern**: Create a Context::Merger class that composes multiple contexts into one
- [ ] **Strategy Pattern**: Different merging strategies for presets vs files with output resolution
- [ ] **Integration**: Extend existing Context command class without breaking current functionality
- [ ] **Impact**: Minimal system design impact, additive enhancement

### Technology Stack
- [ ] **Ruby Standard Library**: Array and Hash manipulation for merging
- [ ] **Dry-CLI**: Extend existing command parameter handling for arrays  
- [ ] **YAML**: Maintain current YAML processing for presets
- [ ] **File I/O**: Standard Ruby file operations for multiple file handling
- [ ] **Performance**: In-memory merging for reasonable context sizes
- [ ] **Security**: No additional security considerations beyond existing validation

### Implementation Strategy
- [ ] **Backward compatibility first**: All existing single preset/file usage continues working
- [ ] **Incremental rollout**: Multiple presets first, then multiple files
- [ ] **Testing strategy**: Unit tests for merger, integration tests for end-to-end scenarios
- [ ] **Performance monitoring**: Track context merge time and memory usage

## Tool Selection

| Criteria | String Split | Dry-CLI Arrays | Custom Parser | Selected |
|----------|--------------|----------------|---------------|----------|
| Performance | High | High | Medium | Dry-CLI Arrays |
| Integration | Low | High | Medium | Dry-CLI Arrays |
| Maintenance | Medium | High | Low | Dry-CLI Arrays |
| Security | Medium | High | Low | Dry-CLI Arrays |
| Learning Curve | High | Low | High | Dry-CLI Arrays |

**Selection Rationale:** Dry-CLI already supports array parameters, provides built-in validation, and integrates seamlessly with existing command infrastructure.

### Dependencies
- [ ] **No new dependencies required**: Using existing Dry-CLI array parameter support
- [ ] **YAML gem**: Already available for preset processing
- [ ] **File utilities**: Ruby standard library sufficient
- [ ] Compatibility verification completed with existing codebase

## File Modifications

### Create
- **lib/coding_agent_tools/cli/commands/context/merger.rb**
  - Purpose: Handle merging multiple contexts with deduplication and source attribution
  - Key components: Context merging logic, file deduplication, command aggregation, error collection
  - Dependencies: YAML processing, file I/O utilities

- **spec/integration/context_multiple_sources_spec.rb**
  - Purpose: End-to-end integration tests for multiple preset and file scenarios
  - Key components: Test scenarios for all combinations, output validation, error handling
  - Dependencies: Test fixtures, context command, RSpec integration helpers

### Modify
- **lib/coding_agent_tools/cli/commands/context.rb**
  - Changes: Update parameter definitions to accept arrays, integrate merger for multiple sources
  - Impact: Enhanced functionality while maintaining backward compatibility
  - Integration points: Dry-CLI parameter handling, preset loading, file processing

- **spec/coding_agent_tools/cli/commands/context_spec.rb**
  - Changes: Add unit tests for array parameter handling and merger integration
  - Impact: Comprehensive test coverage for new functionality
  - Integration points: Mock contexts, array parameter validation, merger behavior testing

## Implementation Plan

<!-- This section details the specific steps required to implement the behavioral requirements -->
<!-- Clear distinction between planning/analysis activities and concrete implementation work -->

### Planning Steps
<!-- Research, analysis, and design activities that clarify the technical approach -->
<!-- Use asterisk markers (* [ ]) for activities that don't change system state -->
<!-- Focus on understanding, designing, and preparing for implementation -->

- [x] **System Analysis**: Analyze current context.rb command structure and preset handling mechanism
  > TEST: Understanding Check
  > Type: Code Review
  > Assert: Current parameter handling, preset loading, and output resolution are understood
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/context_spec.rb
- [x] **Architecture Design**: Design Context::Merger class with deduplication and merging strategies
  > TEST: Design Validation
  > Type: Design Review
  > Assert: Merger interface supports both preset and file merging with output resolution
  > Command: Review design document and interface contracts
- [x] **Implementation Strategy**: Plan incremental implementation starting with multiple presets
- [x] **Dependency Analysis**: Verify Dry-CLI array parameter support and existing YAML processing
- [x] **Risk Assessment**: Analyze backward compatibility risks and performance implications

### Execution Steps  
<!-- Concrete implementation actions that modify code, create files, or change system state -->
<!-- Use hyphen markers (- [ ]) for actions that result in tangible system changes -->
<!-- Each step should be verifiable and move toward behavioral requirement fulfillment -->

- [x] **Foundation Setup**: Create Context::Merger class with basic structure and interface
  > TEST: Foundation Verification
  > Type: Structural Validation
  > Assert: Merger class exists with merge_contexts and resolve_output methods
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/context/merger_spec.rb --tag foundation
- [x] **Core Implementation**: Implement context merging with file deduplication and command aggregation
  > TEST: Core Functionality Check
  > Type: Functional Validation
  > Assert: Multiple contexts merge correctly with deduplication by file path
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/context/merger_spec.rb --tag core
- [x] **Multiple Presets Support**: Update context command to handle comma-separated presets
  > TEST: Multiple Presets Validation
  > Type: Integration Test
  > Assert: `context --preset project,dev-tools` works with intelligent output resolution
  > Command: bundle exec rspec spec/integration/context_multiple_sources_spec.rb --tag presets
- [x] **Multiple Files Support**: Update context command to handle multiple file arguments
  > TEST: Multiple Files Validation
  > Type: Integration Test
  > Assert: `context file1.md file2.md` works with stdout default output
  > Command: bundle exec rspec spec/integration/context_multiple_sources_spec.rb --tag files
- [x] **Output Resolution Logic**: Implement smart output path resolution with conflict handling
  > TEST: Output Resolution Check
  > Type: Edge Case Validation
  > Assert: Output conflicts resolve to stdout, matching outputs use that path
  > Command: bundle exec rspec spec/integration/context_multiple_sources_spec.rb --tag output
- [x] **Integration Validation**: Ensure backward compatibility and full integration
  > TEST: System Integration Check
  > Type: End-to-End Validation
  > Assert: All existing single preset/file scenarios continue working unchanged
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/context_spec.rb

## Risk Assessment

### Technical Risks
- **Risk:** Backward compatibility breakage with existing single preset/file usage
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Comprehensive regression testing and careful parameter handling design
  - **Rollback:** Feature flag to disable multiple source support

### Integration Risks
- **Risk:** Output path conflicts between multiple presets causing unexpected behavior
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Clear conflict resolution rules defaulting to stdout
  - **Monitoring:** Integration tests covering all output resolution scenarios

### Performance Risks
- **Risk:** Memory usage increase when merging large contexts
  - **Mitigation:** In-memory processing with reasonable limits, warn on large contexts
  - **Monitoring:** Track context merge time and memory usage in tests
  - **Thresholds:** 100MB total context size, 5 second merge time limits

## Acceptance Criteria

<!-- Define conditions that signify successful implementation of behavioral requirements -->
<!-- These should directly map to success criteria from the behavioral specification -->
<!-- Focus on verifying that behavioral requirements are met, not just implementation completed -->

### Behavioral Requirement Fulfillment
- [x] **Multiple Presets Support**: `context --preset project,dev-tools` works with comma-separated syntax
- [x] **Multiple Files Support**: `context file1.md file2.md` accepts and processes multiple file arguments  
- [x] **Context Merging**: Multiple contexts merge intelligently with file deduplication by path
- [x] **Output Resolution**: Smart output path handling based on conflict resolution rules
- [x] **Source Attribution**: Commands and errors preserve source information for debugging

### Implementation Quality Assurance  
- [x] **Backward Compatibility**: All existing single preset/file usage continues working unchanged
- [ ] **Test Coverage**: All implementation plan tests pass, including foundation, core, and integration tests
- [x] **Code Quality**: Ruby linting passes, follows project conventions and ATOM architecture
- [x] **Performance Requirements**: Context merging completes within 5 seconds for reasonable sizes

### Example Usage Validation
- [x] **Multiple Presets**: `context --preset project,dev-tools` generates merged context
- [x] **Multiple Files**: `context docs/project.md docs/dev-tools.md` outputs to stdout
- [x] **Output Override**: `context --preset project,dev-tools --output combined.md` respects explicit output
- [x] **Conflict Resolution**: Different preset outputs default to stdout automatically
- [x] **Error Handling**: Missing presets/files report errors with source attribution

## Out of Scope

- ❌ **Advanced merging strategies**: Complex priority or ordering rules beyond deduplication
- ❌ **GUI interface**: Command-line only, no graphical preset selection interface  
- ❌ **Remote preset support**: Only local file-based presets, no URL or remote fetching
- ❌ **Context validation**: No semantic validation of merged context content
- ❌ **Preset dependencies**: No automatic resolution of preset chains or dependencies
- ❌ **Performance optimization**: No caching or streaming for very large contexts (future enhancement)

## References

- **Current context tool implementation**: `lib/coding_agent_tools/cli/commands/context.rb`
- **Existing preset system**: Configuration files in project context directories
- **Dry-CLI documentation**: Array parameter handling and command definition patterns
- **Related task**: v.0.5.0+task.016 (Context tool preset support and caching) - provides foundation
- **ATOM Architecture**: Project follows ATOM pattern for class organization and responsibilities

```