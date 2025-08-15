---
id: 016
status: draft
priority: high
estimate: TBD
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
  dev-tools    - Dev-tools submodule context (docs/context/cached/dev-tools.md)
  dev-handbook - Dev-handbook submodule context (docs/context/cached/dev-handbook.md)

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

## References

- User feedback: dev-taskflow/current/v.0.5.0-insights/docs/feedback-to-bin/load-context.md
- Current context tool documentation
- Claude Code file size limitations research
- Existing .coding-agent configuration patterns in dev-tools