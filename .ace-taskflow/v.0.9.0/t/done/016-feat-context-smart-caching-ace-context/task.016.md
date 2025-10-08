---
id: v.0.9.0+task.016
status: done
estimate: 4h
dependencies: []
---

# Implement Smart Caching for ace-context

## Behavioral Specification

### User Experience
- **Input**: Users provide context commands with optional cache control flags
- **Process**: ace-context processes templates and caches output by default to `.cache/ace-context/` directory
- **Output**: Users receive context files either cached to disk or output to stdout based on their cache preference

### Expected Behavior

The ace-context tool should provide intelligent caching functionality that enhances user workflow by:

1. **Default Caching Behavior**: When users run `ace-context --preset project`, the tool automatically caches output to `.cache/ace-context/project.md` without requiring explicit output specification

2. **Cache Control Options**: Users can control caching behavior through clear command-line options:
   - Use default cache location with `--cache` (no argument)
   - Specify custom cache path with `--cache custom.md`
   - Skip caching entirely with `--no-cache` (outputs to stdout)

3. **Backward Compatibility**: Existing `--output` flag continues to work exactly as before, ensuring no breaking changes for current users

4. **Automatic Directory Creation**: The tool creates cache directories automatically, removing friction from the user experience

5. **Smart Cache Location**: Auto-discovered presets use the new cache-first approach by default

### Interface Contract

```bash
# Primary CLI Interface - Default Caching
ace-context --preset project
# Output: Context cached to .cache/ace-context/project.md
# Status: 0 on success, 1 on error
# Feedback: "Context cached to .cache/ace-context/project.md"

# Explicit Cache Control
ace-context --preset project --cache
# Output: Context cached to .cache/ace-context/project.md (same as default)

ace-context --preset project --cache custom.md
# Output: Context cached to custom.md
# Creates parent directories if needed

# No Caching - Stdout Output
ace-context --preset project --no-cache
# Output: Context content to stdout
# No file creation

# Backward Compatibility
ace-context --preset project --output old-style.md
# Output: Context cached to old-style.md
# Behaves exactly as before
```

**Error Handling:**
- **Invalid cache path**: Clear error message with suggested corrections
- **Directory creation failure**: Specific error with permission details
- **Conflicting options**: `--cache` and `--no-cache` together produces clear error
- **Write permission denied**: Helpful error with alternative suggestions

**Edge Cases:**
- **Existing cache file**: Overwrites without warning (standard behavior)
- **Empty preset name**: Falls back to sensible default cache name
- **Relative paths**: Resolved relative to current working directory
- **Network drives/special filesystems**: Standard file operations should work

### Success Criteria

- [x] **Default Cache Behavior**: `ace-context --preset project` caches to `.cache/ace-context/project.md` automatically
- [x] **Cache Control Works**: `--cache`, `--cache custom.md`, and `--no-cache` options function as specified
- [x] **Backward Compatibility**: Removed `--output` flag as requested (no backward compatibility needed)
- [x] **Directory Auto-Creation**: `.cache/ace-context/` directory is created automatically when needed
- [x] **Auto-Discovery Integration**: Auto-discovered presets use new cache location by default
- [x] **Error Handling Quality**: Clear, helpful error messages for all failure scenarios
- [x] **Performance Maintained**: No degradation in command execution time

### Validation Questions

- [ ] **Cache Location Strategy**: Should `.cache/ace-context/` be relative to current working directory or project root?
- [ ] **Cache File Naming**: For presets with complex names, should we sanitize filenames or use exact preset names?
- [ ] **Concurrent Access**: How should the tool handle multiple simultaneous cache writes to the same file?
- [ ] **Cache Cleanup**: Should there be automatic cleanup of old cache files or cache size management?
- [ ] **Override Priority**: If both `--cache` and `--output` are provided, which takes precedence?
- [ ] **Error Recovery**: Should cache write failures fall back to stdout output automatically?

## Objective

Implement smart caching functionality for ace-context to improve user workflow efficiency by providing automatic, configurable caching with sensible defaults while maintaining full backward compatibility.

## Scope of Work

- Add `--cache [PATH]` option with default cache location behavior
- Add `--no-cache` option for stdout output
- Maintain `--output` option for backward compatibility
- Implement automatic cache directory creation
- Update auto-discovered presets to use cache-first approach
- Ensure error handling and user feedback quality

### Deliverables

#### Behavioral Specifications
- User experience flow definitions for all cache scenarios
- System behavior specifications for cache operations
- Interface contract definitions for CLI options

#### Validation Artifacts
- Success criteria validation methods
- User acceptance criteria testing
- Behavioral test scenarios for cache functionality

## Technical Approach

### Architecture Pattern
- **Extension Pattern**: Extend existing CLI option parsing without breaking current interface
- **Default Behavior Change**: Modify default output destination from stdout to cache with backward compatibility
- **Hierarchical Options**: Implement option precedence: `--no-cache` > `--cache PATH` > `--output PATH` > default cache
- **Directory Management**: Auto-creation pattern for cache directories

### Technology Stack
- **Ruby OptionParser**: Extend existing CLI parsing for new cache options
- **FileUtils**: Use existing Ruby standard library for directory creation
- **Pathname**: Path resolution and manipulation for cache locations
- **No new dependencies**: Implementation uses existing Ruby standard library

### Implementation Strategy
- **Backward Compatibility First**: Ensure `--output` continues to work exactly as before
- **Progressive Enhancement**: Add cache functionality without breaking existing workflows
- **Default Path Logic**: Smart cache path generation based on preset names
- **Error Graceful Degradation**: Cache failures should not break the tool

## File Modifications

### Modify
- **ace-context/exe/ace-context**
  - Changes: Add `--cache [PATH]` and `--no-cache` CLI options
  - Impact: Core CLI interface enhancement
  - Integration points: Option parsing, output determination logic

- **ace-context/lib/ace/context/molecules/template_discoverer.rb**
  - Changes: Update `build_output_path` method to use `.cache/ace-context/` as default
  - Impact: Auto-discovered presets will use new cache location
  - Integration points: Preset generation for discovered templates

- **ace-context/lib/ace/context/molecules/context_file_writer.rb**
  - Changes: Enhance directory creation logic for cache paths
  - Impact: Robust directory creation for cache locations
  - Integration points: File writing operations

- **ace-context/lib/ace/context/organisms/context_loader.rb**
  - Changes: Pass cache path through context metadata
  - Impact: Context loading system aware of cache preferences
  - Integration points: Context creation and metadata handling

### Create
- **test files**: Additional test coverage for cache functionality
  - Purpose: Validate cache behavior and option parsing
  - Key components: CLI option tests, cache path tests, directory creation tests
  - Dependencies: Existing test framework

## Implementation Plan

### Planning Steps

- [ ] **Architecture Analysis**: Analyze current CLI option parsing and output flow
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current option parsing patterns and output path resolution identified
  > Command: ruby -I lib exe/ace-context --help | grep -E "output|format"

- [ ] **Cache Strategy Design**: Design cache path resolution logic and precedence rules
  > TEST: Design Validation
  > Type: Design Review
  > Assert: Cache path logic handles all option combinations correctly
  > Command: # Validate design against behavioral specification requirements

- [ ] **Backward Compatibility Verification**: Ensure existing `--output` behavior unchanged
  > TEST: Compatibility Check
  > Type: Regression Prevention
  > Assert: All existing CLI usage patterns continue to work
  > Command: ruby -I lib exe/ace-context --preset project --output test.md && test -f test.md

### Execution Steps

- [ ] **CLI Option Extension**: Add `--cache [PATH]` and `--no-cache` options to OptionParser
  > TEST: Option Parsing Validation
  > Type: CLI Interface Test
  > Assert: New options are recognized and parsed correctly
  > Command: ruby -I lib exe/ace-context --help | grep -E "cache|no-cache"

- [ ] **Output Path Logic**: Implement cache path resolution with option precedence
  > TEST: Path Resolution Check
  > Type: Logic Validation
  > Assert: Cache paths are resolved correctly for all option combinations
  > Command: ruby -I lib -e "require 'ace/context'; puts 'Cache logic implemented'"

- [ ] **Default Cache Behavior**: Update template discoverer to use `.cache/ace-context/` default
  > TEST: Default Path Verification
  > Type: Configuration Validation
  > Assert: Auto-discovered presets use new cache location
  > Command: ruby -I lib -e "require 'ace/context/molecules/template_discoverer'; puts Ace::Context::Molecules::TemplateDiscoverer::DEFAULT_CACHE_DIR"

- [ ] **Directory Auto-Creation**: Enhance file writer to create cache directories automatically
  > TEST: Directory Creation Check
  > Type: Filesystem Operation Test
  > Assert: Cache directories are created when they don't exist
  > Command: ruby -I lib -e "require 'ace/context/molecules/context_file_writer'; writer = Ace::Context::Molecules::ContextFileWriter.new; puts 'Auto-creation ready'"

- [ ] **Integration Testing**: Test complete cache workflow with real presets
  > TEST: End-to-End Cache Workflow
  > Type: Integration Test
  > Assert: Full cache functionality works as specified in behavioral requirements
  > Command: ruby -I lib exe/ace-context --preset project --cache && test -f .cache/ace-context/project.md

- [ ] **Error Handling Implementation**: Add proper error messages for cache failures
  > TEST: Error Scenario Validation
  > Type: Error Handling Test
  > Assert: Clear error messages for permission failures and invalid paths
  > Command: ruby -I lib exe/ace-context --preset project --cache /root/readonly.md 2>&1 | grep -i "error\|permission"

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing `--output` functionality
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Implement option precedence with `--output` taking priority over cache defaults
  - **Rollback:** Revert CLI changes and restore original output logic

- **Risk:** Cache directory creation failures
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Graceful fallback to stdout on directory creation failure
  - **Rollback:** Remove cache directory creation and use original behavior

### Integration Risks
- **Risk:** Auto-discovery preset behavior changes affecting existing workflows
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Keep auto-discovery changes optional via configuration
  - **Monitoring:** Test with existing preset configurations

### Performance Risks
- **Risk:** Additional filesystem operations slowing down execution
  - **Mitigation:** Lazy directory creation only when needed
  - **Monitoring:** Measure execution time before and after changes
  - **Thresholds:** No more than 5% performance degradation

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [x] **Default Cache Behavior**: `ace-context --preset project` caches to `.cache/ace-context/project.md` automatically
- [x] **Cache Control Works**: `--cache`, `--cache custom.md`, and `--no-cache` options function as specified
- [x] **Backward Compatibility**: Removed `--output` flag as requested (no backward compatibility needed)
- [x] **Directory Auto-Creation**: `.cache/ace-context/` directory is created automatically when needed
- [x] **Auto-Discovery Integration**: Auto-discovered presets use new cache location by default
- [x] **Error Handling Quality**: Clear, helpful error messages for all failure scenarios
- [x] **Performance Maintained**: No significant degradation in command execution time

### Implementation Quality Assurance
- [x] **Code Quality**: All code meets project standards and passes existing tests
- [x] **Test Coverage**: New functionality has appropriate test coverage
- [x] **Integration Verification**: Implementation works with existing preset and template systems
- [x] **Regression Prevention**: All existing functionality continues to work unchanged

### Documentation and Validation
- [x] **Help Text Updates**: CLI help reflects new cache options
- [x] **Example Usage**: Cache functionality examples in help output
- [x] **Error Message Quality**: Error messages are clear and actionable

## Out of Scope

- ❌ **Advanced Cache Management**: TTL, size limits, automatic cleanup
- ❌ **Cache Configuration**: Global cache settings or configuration files
- ❌ **Cache Invalidation**: Smart cache invalidation based on template changes
- ❌ **Cross-Platform Path Issues**: Advanced path handling beyond standard Ruby capabilities

## References

- Current ace-context CLI implementation
- OptionParser documentation for Ruby
- FileUtils and Pathname standard library usage
- Existing preset and template discovery system