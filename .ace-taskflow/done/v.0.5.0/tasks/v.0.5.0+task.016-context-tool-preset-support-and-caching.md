---
id: v.0.5.0+task.016
status: done
priority: high
estimate: 8h
dependencies: []
---

# Context Tool Preset Support and Caching

## Behavioral Specification

### User Experience
- **Input**: Simple preset names or traditional YAML templates, optional output paths
- **Process**: Tool loads configuration, processes templates, provides progress feedback, handles large files automatically
- **Output**: Formatted context saved to files or stdout, with automatic chunking for large contexts

### Expected Behavior
Users can efficiently load project context using named presets that encapsulate template sources, output paths, and processing options. The tool remembers common configurations through presets, eliminating repetitive command arguments. When using presets, context automatically saves to configured cache locations, making it easy to reload or reference. For large contexts exceeding tool limits (e.g., Claude Code's 150K lines), the system automatically splits output into manageable chunks with an index file.

The experience is streamlined: `context --preset project` loads everything needed to understand the project, saving it to a predictable location. Users can override any preset setting with command-line options for flexibility. The tool maintains full backward compatibility, allowing traditional usage patterns to continue working.

### Interface Contract
```bash
# CLI Interface
context --preset <name>                  # Load preset, auto-save to configured path
context --preset <name> --output <path>  # Load preset, save to custom path
context --list-presets                   # Show available presets with descriptions
context --yaml <template>                # Traditional mode (stdout, backward compatible)
context --yaml <template> --output <path> # Manual mode with file output

# Expected outputs
$ context --preset project
Loading preset: project
Processing template: docs/context/project.md
Saving to: docs/context/cached/project.md
✓ Context saved (2496 lines, 95.8 KB)

$ context --list-presets
Available presets:
  project      - Main project context (docs/context/cached/project.md)
  .ace/tools    - Dev-tools submodule context (docs/context/cached/.ace/tools.md)
  .ace/handbook - Dev-handbook submodule context (docs/context/cached/.ace/handbook.md)

# Large file handling (automatic)
$ context --preset large-project
Loading preset: large-project
Processing template: docs/context/large.md
Output exceeds 150000 lines, creating chunks...
✓ Created 4 chunks:
  - docs/context/cached/large-project.md (index)
  - docs/context/cached/large-project_chunk1.md (150000 lines)
  - docs/context/cached/large-project_chunk2.md (150000 lines)
  - docs/context/cached/large-project_chunk3.md (150000 lines)
  - docs/context/cached/large-project_chunk4.md (87234 lines)
```

**Error Handling:**
- Unknown preset: List available presets with helpful message
- Missing template file: Clear error with file path and suggestion
- Write permission denied: Suggest alternative output location
- Malformed configuration: Show validation errors with line numbers
- Command execution failure: Display command output and continue processing

**Edge Cases:**
- Empty preset configuration: Use sensible defaults
- Circular template references: Detect and prevent infinite loops
- Extremely large files (>1GB): Process in streaming mode
- Concurrent access: Use file locking for cache writes
- Missing .coding-agent directory: Fall back to docs/context/ location

### Success Criteria
- [ ] **Behavioral Outcome 1**: Users can load project context with single command using presets
- [ ] **User Experience Goal 2**: Context loads and saves in under 2 seconds for typical projects
- [ ] **System Performance 3**: Large contexts (>150K lines) automatically chunk without user intervention
- [ ] **Compatibility Goal 4**: All existing context tool usage patterns continue working unchanged
- [ ] **Discovery Goal 5**: Users can easily discover available presets and their purposes

### Validation Questions
- [ ] **Requirement Clarity**: Should presets support parameterization (e.g., depth, exclude patterns)?
- [ ] **Edge Case Handling**: What happens when preset source file is missing - fail or skip?
- [ ] **User Experience**: Should presets support inheritance or composition for complex scenarios?
- [ ] **Success Definition**: How do we measure "efficient" context loading - time, size, or completeness?
- [ ] **Configuration Location**: Should we support both .coding-agent/context.yml and docs/context/ locations?
- [ ] **Preset Override**: How are conflicts resolved between CLI arguments and preset configuration?

## Objective

Enable efficient project context loading through named presets that eliminate repetitive configuration, automatically handle caching and chunking, while maintaining full backward compatibility with existing context tool usage patterns. This improves developer and AI agent productivity by making project understanding faster and more consistent.

## Scope of Work

### User Experience Scope
- Preset-based context loading with single commands
- Automatic output path resolution and caching
- Large file chunking for tool compatibility
- Preset discovery and listing capabilities
- Full backward compatibility with existing usage

### System Behavior Scope
- Configuration loading from .coding-agent/context.yml
- Template processing with file includes and commands
- Automatic directory creation for output paths
- Intelligent chunking based on line count limits
- Progress reporting during processing

### Interface Scope
- New CLI options: --preset, --list-presets, --output
- Configuration file format and schema
- Chunk file naming conventions
- Error message standards

### Deliverables

#### Behavioral Specifications
- Preset loading and resolution behavior
- Output path determination logic
- Chunking algorithm requirements
- Error handling strategies

#### Validation Artifacts
- Preset configuration examples
- Test scenarios for chunking
- Performance benchmarks
- Backward compatibility test cases

## Out of Scope

- ❌ **Implementation Details**: ATOM architecture decisions, specific Ruby modules
- ❌ **Technology Decisions**: Choice of YAML parser, file system libraries
- ❌ **Performance Optimization**: Specific caching strategies or parallel processing
- ❌ **Future Enhancements**: Remote preset repositories, preset sharing mechanisms
- ❌ **Migration Tools**: Automated conversion of existing templates to presets

## Technical Approach

### Architecture Pattern
Following the ATOM architecture pattern in .ace/tools:
- **Atoms**: Configuration loader for `.coding-agent/context.yml`
- **Molecules**: Preset manager, file writer with chunking support
- **Organism**: Enhanced ContextLoader with preset capabilities
- **CLI**: Updated Context command with new options

Integration with existing patterns:
- Reuse `ProjectRootDetector` atom for finding project root
- Follow `PathConfigLoader` pattern for configuration loading
- Extend existing `ContextLoader` organism rather than replace

### Technology Stack
- **Configuration**: YAML parsing (already in use)
- **File Operations**: Ruby File/FileUtils (standard library)
- **Path Resolution**: Existing ProjectRootDetector atom
- **Chunking**: Line-based splitting with index generation
- **CLI Framework**: dry-cli (already integrated)

## Tool Selection

| Criteria | Custom Implementation | External Library | Selected |
|----------|----------------------|------------------|----------|
| Performance | Excellent | Good | Custom |
| Integration | Excellent | Fair | Custom |
| Maintenance | Good | Fair | Custom |
| Flexibility | Excellent | Limited | Custom |

**Selection Rationale:** Custom implementation using existing ATOM components provides best integration with current architecture and allows precise control over chunking and caching behavior.

## File Modifications

### Create
- `lib/coding_agent_tools/atoms/context/context_config_loader.rb`
  - Purpose: Load and validate `.coding-agent/context.yml`
  - Key components: YAML parsing, schema validation, default merging
  - Dependencies: ProjectRootDetector, YAML library

- `lib/coding_agent_tools/molecules/context/context_preset_manager.rb`
  - Purpose: Manage preset configurations and resolution
  - Key components: Preset loading, path resolution, validation
  - Dependencies: ContextConfigLoader atom

- `lib/coding_agent_tools/molecules/context/context_file_writer.rb`
  - Purpose: Write context to files with directory creation
  - Key components: File writing, directory creation, progress reporting
  - Dependencies: FileUtils, SecurityLogger

- `lib/coding_agent_tools/molecules/context/context_chunker.rb`
  - Purpose: Split large contexts into chunks with index
  - Key components: Line counting, chunk splitting, index generation
  - Dependencies: None (pure Ruby)

- `spec/coding_agent_tools/atoms/context/context_config_loader_spec.rb`
  - Purpose: Test configuration loading behavior
  - Key components: YAML parsing tests, validation tests
  - Dependencies: RSpec

- `spec/coding_agent_tools/molecules/context/context_preset_manager_spec.rb`
  - Purpose: Test preset management
  - Key components: Preset resolution, validation tests
  - Dependencies: RSpec

- `spec/coding_agent_tools/molecules/context/context_file_writer_spec.rb`
  - Purpose: Test file writing behavior
  - Key components: Directory creation, file writing tests
  - Dependencies: RSpec, temp directories

- `spec/coding_agent_tools/molecules/context/context_chunker_spec.rb`
  - Purpose: Test chunking algorithm
  - Key components: Large file splitting, index generation tests
  - Dependencies: RSpec

### Modify
- `lib/coding_agent_tools/cli/commands/context.rb`
  - Changes: Add --preset, --list-presets, --output options
  - Impact: New command-line interface capabilities
  - Integration points: Calls preset manager for preset loading

- `lib/coding_agent_tools/organisms/context_loader.rb`
  - Changes: Add preset support, output handling, chunking integration
  - Impact: Core functionality enhancement
  - Integration points: Uses new molecules for preset and file operations

- `spec/coding_agent_tools/cli/commands/context_spec.rb`
  - Changes: Add tests for new CLI options
  - Impact: Test coverage for new features
  - Integration points: CLI testing with Aruba

- `spec/coding_agent_tools/organisms/context_loader_spec.rb`
  - Changes: Add tests for preset loading and output handling
  - Impact: Comprehensive test coverage
  - Integration points: Organism testing

### Configuration
- `.coding-agent/context.yml` (in project root, not .ace/tools)
  - Purpose: Define presets for context loading
  - Format: YAML with preset definitions
  - Example content provided in implementation

## Test Case Planning

### Happy Path Scenarios
- Load preset successfully and save to configured path
- Override preset output with --output flag
- List available presets with descriptions
- Process traditional YAML template (backward compatibility)

### Edge Case Scenarios
- Unknown preset name → Show available presets
- Missing preset source file → Clear error message
- Output > 150K lines → Automatic chunking
- Missing .coding-agent directory → Fall back to defaults
- Concurrent writes → File locking protection

### Error Condition Scenarios
- Malformed YAML configuration → Validation error with line number
- Write permission denied → Suggest alternative location
- Command execution failure in template → Continue processing
- Circular template references → Detection and prevention

### Integration Point Scenarios
- Integration with existing context tool functionality
- Compatibility with current CLI options
- File system operations with security validation
- Progress reporting during long operations

## Implementation Plan

### Planning Steps

* [x] Research existing configuration patterns in .ace/tools
  - PathConfigLoader implementation
  - TreeConfigLoader patterns
  - Security validation approaches

* [x] Design configuration schema for `.coding-agent/context.yml`
  - Preset structure definition
  - Default values and inheritance
  - Validation rules

* [x] Analyze chunking requirements for large files
  - Line counting vs byte counting
  - Index file format
  - Chunk naming conventions

### Execution Steps

- [x] Step 1: Create ContextConfigLoader atom
  - Implement YAML loading with schema validation
  - Add project root detection using existing atom
  - Handle missing configuration gracefully
  > TEST: Configuration Loading
  > Type: Unit Test
  > Assert: Valid configuration loaded from .coding-agent/context.yml
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/context/context_config_loader_spec.rb

- [x] Step 2: Create ContextPresetManager molecule
  - Implement preset resolution logic
  - Add path resolution for source and output
  - Include preset listing functionality
  > TEST: Preset Resolution
  > Type: Unit Test
  > Assert: Preset correctly resolved with paths
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/context/context_preset_manager_spec.rb

- [x] Step 3: Create ContextFileWriter molecule
  - Implement file writing with directory creation
  - Add progress reporting
  - Include atomic write operations
  > TEST: File Writing
  > Type: Integration Test
  > Assert: Files written to correct locations
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/context/context_file_writer_spec.rb

- [x] Step 4: Create ContextChunker molecule
  - Implement line-based chunking algorithm
  - Generate index file with chunk references
  - Handle edge cases (empty content, single line)
  > TEST: Chunking Algorithm
  > Type: Unit Test
  > Assert: Large content correctly split into chunks
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/context/context_chunker_spec.rb

- [x] Step 5: Update Context CLI command
  - Add --preset option with preset loading
  - Add --list-presets for preset discovery
  - Add --output for manual output specification
  - Maintain backward compatibility
  > TEST: CLI Options
  > Type: CLI Test
  > Assert: New options work correctly
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/context_spec.rb

- [x] Step 6: Enhance ContextLoader organism
  - Integrate preset manager for configuration
  - Add output handling with file writer
  - Integrate chunker for large outputs
  - Preserve existing functionality
  > TEST: Organism Integration
  > Type: Integration Test
  > Assert: All components work together
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/context_spec.rb

- [x] Step 7: Create example configuration
  - Add .coding-agent/context.yml to project root
  - Define presets for project, .ace/tools, .ace/handbook
  - Document configuration format
  > TEST: Example Configuration
  > Type: Manual Test
  > Assert: Example presets load successfully
  > Command: context --preset project

- [x] Step 8: Add comprehensive test coverage
  - Unit tests for each new component
  - Integration tests for complete workflow
  - CLI tests with Aruba
  - Edge case and error scenario tests
  > TEST: Full Test Suite
  > Type: Test Coverage
  > Assert: >95% code coverage achieved
  > Command: bundle exec rspec

- [x] Step 9: Update documentation
  - Add preset usage to context tool documentation
  - Create configuration reference
  - Update workflow instructions
  > TEST: Documentation Validation
  > Type: Manual Review
  > Assert: Documentation complete and accurate
  > Command: markdownlint docs/**/*.md

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing context tool functionality
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Comprehensive backward compatibility tests
  - **Rollback:** Git revert with immediate fix

- **Risk:** Performance degradation for large contexts
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Streaming processing for >1GB files
  - **Rollback:** Disable chunking temporarily

### Integration Risks
- **Risk:** Configuration conflicts with existing .coding-agent patterns
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Use separate context.yml file
  - **Monitoring:** Check for file conflicts

### Performance Risks
- **Risk:** Slow chunking for very large files
  - **Mitigation:** Line-based processing with buffering
  - **Monitoring:** Time measurements in tests
  - **Thresholds:** <5 seconds for 1M lines

## Acceptance Criteria

- [ ] AC 1: All preset functionality working as specified
- [ ] AC 2: Backward compatibility maintained for existing usage
- [ ] AC 3: Automatic chunking for files >150K lines
- [ ] AC 4: All tests passing with >95% coverage
- [ ] AC 5: Performance targets met (<2 seconds typical load)

## References

- User feedback: .ace/taskflow/current/v.0.5.0-insights/docs/feedback-to-bin/load-context.md
- Current context tool documentation
- Claude Code file size limitations research
- Existing .coding-agent configuration patterns in .ace/tools
- ATOM architecture documentation: docs/architecture-tools.md