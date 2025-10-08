---
id: v.0.9.0+task.059
status: in-progress
estimate: 2 days
dependencies: []
tags:
  - migration
  - ace-gem
  - search
  - refactoring
---

# Task 059: Migrate search tool to ace-search gem

## Core Requirements

Migrate the legacy search tool from dev-tools/exe/search to a new ace-search gem following ACE framework patterns while preserving 100% CLI compatibility.

### Behavioral Specification

The system should provide a search capability packaged as an ace-search Ruby gem that:

1. Maintains exact CLI interface compatibility with dev-tools/exe/search (except editor integration)
2. Follows ACE gem architecture patterns (ATOM structure)
3. Leverages ace-core for configuration and shared utilities
4. Provides clean separation between search logic and output concerns
5. Supports all existing search modes (file, content, hybrid)
6. Improves file search to match paths and filenames (not just names)
7. Supports comprehensive configuration defaults and preset system

### User Experience

Users will continue using the search command with identical syntax and behavior:

```bash
# These commands should work exactly as before
search "pattern" --type content
search --preset code "TODO"
search --fzf "function"

# Improved file search matches paths and names
search --files "controller" # matches paths like app/controllers/user_controller.rb
```

Key improvements:

- File search now matches full paths, not just filenames
- Configuration supports all CLI flags as defaults
- Presets organized in separate files for better maintainability

### Interface Contract

#### Inputs

- Pattern: Search string or regex pattern (for files: matches paths and names)
- Options: All existing CLI flags must be preserved (except editor-related)
  - Type flags: `-t`, `-f`, `-c`, `--files`, `--content`
  - Pattern flags: `-i`, `-w`, `-U`, `--hidden`
  - Context flags: `-A`, `-B`, `-C`
  - Filter flags: `-g`, `--include`, `--exclude`, `--max-results`
  - Scope flags: `--staged`, `--tracked`, `--changed`
  - Output flags: `--json`, `--yaml`, `-l`, `--files-with-matches`
  - Interactive flags: `--fzf`
  - All flags can be set as defaults in configuration

#### Outputs

- Search results in text, JSON, or YAML format
- File paths with clickable terminal links (file:line format)
- Configuration status (when using config subcommand)

#### Processing

1. Parse command-line arguments
2. Apply presets and configuration
3. Execute search using ripgrep/fd
4. Format and aggregate results
5. Handle editor integration if requested
6. Output results in requested format

## Planning Steps

- [x] Analyze existing search tool structure (695 lines in exe/search)
- [x] Identify all dependencies and components to migrate
- [x] Map current structure to ACE gem patterns
- [x] Define migration strategy preserving CLI compatibility

## Execution Steps

- [x] Create ace-search gem structure
  - [x] Initialize gem with `bundle gem ace-search`
  - [x] Set up ATOM directory structure (atoms/, molecules/, organisms/, models/)
  - [x] Create .ace.example/search/config.yml
  - [x] Configure gemspec with ace-core dependency

- [x] Migrate search components
  - [x] Port atoms (ripgrep_executor, fd_executor, pattern_analyzer, result_parser, tool_checker)
  - [x] Port molecules (preset_manager, git_scope_filter, dwim_analyzer, time_filter, fzf_integrator)
  - [x] Port organisms (unified_searcher, result_formatter, result_aggregator)
  - [x] Port models (search_result, search_options, search_preset)

- [x] Create executable with compatibility wrapper
  - [x] Create exe/ace-search with full CLI compatibility
  - [x] Add bin/ace-search binstub for development (no symlink needed in dev-tools)
  - [x] Ensure all flags and options work identically
  - [x] Preserve output format with clickable terminal links

- [x] Integrate with ace-core
  - [x] Use ace-core for configuration cascade
  - [x] Use ace-core's ConfigDiscovery for project root detection
  - [x] Use ace-core atoms (YamlParser, DeepMerger) in preset_manager

- [x] Set up configuration
  - [x] Create .ace.example/search/config.yml template with default flags
  - [x] Create .ace.example/search/presets/ directory structure
  - [x] Support presets as separate YAML files in presets/ directory
  - [x] Allow any CLI flag as a configuration default
  - [x] Ensure configuration cascade: defaults → config → preset → CLI flags

- [ ] Create comprehensive tests
  - [ ] Port existing tests from dev-tools/spec
  - [ ] Add integration tests for CLI compatibility
  - [ ] Test all option combinations
  - [ ] Verify output format matches exactly
  - [ ] Use ace-test-support for test infrastructure

- [x] Create usage documentation
  - [x] Write comprehensive usage.md following ace-gems patterns (in ux/usage.md)
  - [x] Include migration guide from old to new
  - [x] Document all commands and options
  - [x] Add troubleshooting section

- [x] Implement transition strategy
  - [x] Add ace-search to root Gemfile
  - [x] Create bin/ace-search binstub for development use
  - [x] Manual testing verified functionality
  - [ ] (Future) Create symlink for production deployment if needed

## Acceptance Criteria

- [x] All existing search commands work without modification (except editor integration)
- [x] File search improved to match full paths, not just filenames
- [x] Output format identical to current implementation (with clickable terminal links)
- [x] Performance equal or better than current version (direct rg/fd calls)
- [x] Configuration supports all CLI flags as defaults
- [x] Presets organized in .ace/search/presets/ directory
- [ ] All tests passing with ace-test-support (tests not yet ported)
- [x] Usage documentation complete and accurate
- [x] Can be installed as standalone gem
- [x] Follows ACE gem architecture patterns exactly

## Dependencies

- ace-core (for configuration and utilities)
- ace-test-support (for testing infrastructure)
- ripgrep (external dependency)
- fd (external dependency)
- fzf (optional external dependency)

## Technical Approach

### Architecture Pattern

The migration follows the ACE gem architecture with ATOM pattern:

**Pattern Selection**: Standard ATOM architecture (Atoms → Molecules → Organisms → Models)

- **Atoms**: Pure functions for ripgrep/fd execution, pattern parsing, result parsing
- **Molecules**: Preset management, git scope filtering, DWIM analysis, time filtering, fzf integration
- **Organisms**: Unified searcher orchestration, result formatting, result aggregation
- **Models**: SearchResult, SearchOptions, SearchPreset data structures

**Integration with Existing Architecture**:

- Leverages ace-core for configuration cascade (.ace/search/)
- Uses ace-core atoms (YamlParser, FileReader, DeepMerger) where applicable
- Follows same directory structure as other ace-* gems
- Integrates with ace-test-support for testing

**Impact on System Design**:

- Enables standalone installation (`gem install ace-search`)
- Provides reusable search components for other gems
- Maintains backward compatibility via executable naming
- Supports future MCP integration

### Technology Stack

**Core Dependencies**:

- ace-core (~> 0.9) - Configuration cascade and utilities
- Ruby standard library (json, yaml, optparse, set)
- No additional gem dependencies beyond ace-core

**External Tools** (runtime dependencies):

- ripgrep (rg) - Content search backend
- fd - File search backend
- git - For git scope filtering
- fzf (optional) - Interactive selection

**Development Dependencies**:

- ace-test-support (~> 0.9) - Testing infrastructure
- minitest - Test framework (via ace-test-support)

**Version Compatibility**:

- Ruby >= 2.7 (matches ace-core requirement)
- Works with Ruby 3.0, 3.1, 3.2, 3.3

**Performance Implications**:

- No performance regression - still uses ripgrep/fd directly
- Configuration caching via ace-core improves startup time
- Modular structure allows selective loading

**Security Considerations**:

- Input validation via ace-core path validation
- Command injection prevention in executor atoms
- Safe YAML loading via ace-core

### Implementation Strategy

**Step-by-step Approach**:

1. Create gem skeleton with proper structure
2. Port atoms layer (pure functions, no dependencies)
3. Port molecules layer (composed operations)
4. Port organisms layer (business orchestration)
5. Port models layer (data structures)
6. Create executable with CLI compatibility
7. Integrate configuration system
8. Create comprehensive tests
9. Document and validate

**Rollback Considerations**:

- Legacy search tool remains in dev-tools during transition
- Symlink can be removed if issues arise
- No data migration required (stateless tool)
- Easy to revert by removing ace-search from Gemfile

**Testing Strategy**:

- Unit tests for all atoms (pure functions, 100% coverage target)
- Integration tests for molecules (file I/O, external commands)
- End-to-end CLI tests (full command execution)
- VCR cassettes for external command outputs
- Test matrix across Ruby versions in CI

**Performance Monitoring**:

- Benchmark against legacy tool (must be equal or better)
- Monitor startup time (target < 100ms)
- Track search execution time (should match ripgrep/fd directly)
- Memory usage profiling for large result sets

## Tool Selection

### Search Backends

| Criteria | ripgrep | ag (silver-searcher) | grep | Selected |
|----------|---------|---------------------|------|----------|
| Performance | Excellent | Good | Fair | ripgrep |
| Regex Support | Excellent | Good | Good | ripgrep |
| Unicode Handling | Excellent | Fair | Poor | ripgrep |
| Maintenance | Active | Moderate | Legacy | ripgrep |
| Adoption | Widespread | Moderate | Universal | ripgrep |

| Criteria | fd | find | locate | Selected |
|----------|-----|------|--------|----------|
| Performance | Excellent | Good | Excellent | fd |
| User Experience | Excellent | Poor | Fair | fd |
| Regex Support | Excellent | Fair | None | fd |
| Integration | Good | Excellent | Poor | fd |
| Hidden Files | Smart | Complex | N/A | fd |

**Selection Rationale**: ripgrep and fd are already used by the legacy tool and provide superior performance and user experience. Both are widely adopted, actively maintained, and provide the exact feature set needed.

### Configuration System

| Criteria | ace-core cascade | Custom YAML | Environment vars | Selected |
|----------|------------------|-------------|------------------|----------|
| Consistency | Excellent | Poor | Fair | ace-core |
| Flexibility | Excellent | Good | Poor | ace-core |
| Integration | Native | Manual | Manual | ace-core |
| Maintenance | Minimal | High | Medium | ace-core |

**Selection Rationale**: ace-core provides a proven configuration cascade system that all ace-* gems use, ensuring consistency and reducing maintenance burden.

### Dependencies

New dependencies:

- ace-core ~> 0.9 - Required for configuration and utilities
- ace-test-support ~> 0.9 - Development only, for testing

Compatibility verification:

- Both gems are part of the ACE ecosystem and follow same versioning
- No conflicts with existing dependencies
- Ruby 2.7+ requirement aligns with ecosystem

## File Modifications

### Create

**Gem Structure**:

- ace-search/ace-search.gemspec
  - Purpose: Gem specification and metadata
  - Key components: Dependencies, executables, version
  - Dependencies: ace-core, ace-test-support (dev)

- ace-search/lib/ace/search.rb
  - Purpose: Main entry point and module definition
  - Key components: Version constant, configuration loading
  - Dependencies: ace-core

- ace-search/lib/ace/search/version.rb
  - Purpose: Version constant (0.1.0 initial)
  - Key components: VERSION constant
  - Dependencies: None

**Atoms Layer** (pure functions):

- ace-search/lib/ace/search/atoms/ripgrep_executor.rb
  - Purpose: Execute ripgrep commands safely
  - Key components: Command building, safe execution, output capture
  - Migrated from: dev-tools/lib/coding_agent_tools/atoms/search/ripgrep_executor.rb

- ace-search/lib/ace/search/atoms/fd_executor.rb
  - Purpose: Execute fd commands for file search
  - Key components: Command building, pattern handling, output parsing
  - Migrated from: dev-tools/lib/coding_agent_tools/atoms/search/fd_executor.rb

- ace-search/lib/ace/search/atoms/pattern_analyzer.rb
  - Purpose: Analyze search patterns for DWIM mode
  - Key components: Pattern type detection, complexity analysis
  - Migrated from: dev-tools/lib/coding_agent_tools/atoms/search/pattern_analyzer.rb

- ace-search/lib/ace/search/atoms/result_parser.rb
  - Purpose: Parse ripgrep/fd output into structured data
  - Key components: Line parsing, format detection, data extraction
  - Migrated from: dev-tools/lib/coding_agent_tools/atoms/search/result_parser.rb

- ace-search/lib/ace/search/atoms/tool_checker.rb
  - Purpose: Check availability of external tools (rg, fd, fzf)
  - Key components: Command existence check, version detection
  - Migrated from: dev-tools/lib/coding_agent_tools/atoms/search/tool_availability_checker.rb

**Molecules Layer** (composed operations):

- ace-search/lib/ace/search/molecules/preset_manager.rb
  - Purpose: Load and manage search presets from .ace/search/presets/
  - Key components: Preset loading, validation, merging with options
  - Migrated from: dev-tools/lib/coding_agent_tools/molecules/search/preset_manager.rb

- ace-search/lib/ace/search/molecules/git_scope_filter.rb
  - Purpose: Filter files by git status (staged, tracked, changed)
  - Key components: Git command execution, file enumeration
  - Migrated from: dev-tools/lib/coding_agent_tools/molecules/search/git_scope_enumerator.rb

- ace-search/lib/ace/search/molecules/dwim_analyzer.rb
  - Purpose: Do-What-I-Mean search type detection
  - Key components: Heuristic analysis, pattern type detection
  - Migrated from: dev-tools/lib/coding_agent_tools/molecules/search/dwim_heuristics_engine.rb

- ace-search/lib/ace/search/molecules/time_filter.rb
  - Purpose: Filter files by modification time
  - Key components: Time parsing, file enumeration with time checks
  - Migrated from: dev-tools/lib/coding_agent_tools/molecules/search/time_filter.rb

- ace-search/lib/ace/search/molecules/fzf_integrator.rb
  - Purpose: Interactive result selection with fzf
  - Key components: fzf command building, result formatting, selection parsing
  - Migrated from: dev-tools/lib/coding_agent_tools/molecules/search/fzf_integrator.rb

**Organisms Layer** (business logic):

- ace-search/lib/ace/search/organisms/unified_searcher.rb
  - Purpose: Main search orchestration
  - Key components: Search execution, result aggregation, format handling
  - Migrated from: dev-tools/lib/coding_agent_tools/organisms/search/unified_searcher.rb

- ace-search/lib/ace/search/organisms/result_formatter.rb
  - Purpose: Format results for text/JSON/YAML output
  - Key components: Format conversion, clickable link generation
  - Migrated from: Extracted from dev-tools/exe/search CLI code

- ace-search/lib/ace/search/organisms/result_aggregator.rb
  - Purpose: Aggregate and deduplicate search results
  - Key components: Result merging, counting, metadata extraction
  - Migrated from: dev-tools/lib/coding_agent_tools/organisms/search/result_aggregator.rb

**Models Layer** (data structures):

- ace-search/lib/ace/search/models/search_result.rb
  - Purpose: Represent a single search result
  - Key components: file, line, column, text attributes
  - Migrated from: dev-tools/lib/coding_agent_tools/models/search/search_result.rb

- ace-search/lib/ace/search/models/search_options.rb
  - Purpose: Encapsulate search configuration
  - Key components: Pattern, type, filters, scope attributes
  - Migrated from: dev-tools/lib/coding_agent_tools/models/search/search_options.rb

- ace-search/lib/ace/search/models/search_preset.rb
  - Purpose: Represent a search preset configuration
  - Key components: Name, description, options hash
  - Migrated from: dev-tools/lib/coding_agent_tools/models/search/search_preset.rb

**Executable**:

- ace-search/exe/ace-search
  - Purpose: Main CLI entry point with full compatibility
  - Key components: Argument parsing, command dispatch, output formatting
  - Migrated from: dev-tools/exe/search (simplified, editor integration removed)

**Configuration**:

- ace-search/.ace.example/search/config.yml
  - Purpose: Example configuration showing all supported defaults
  - Key components: defaults section, preset directory configuration
  - Dependencies: None (example file)

- ace-search/.ace.example/search/presets/code.yml
  - Purpose: Example preset for code search
  - Key components: glob patterns, exclusions for common code search
  - Dependencies: None (example preset)

**Tests**:

- ace-search/test/test_helper.rb
  - Purpose: Test setup and shared utilities
  - Key components: AceTestCase inheritance, common fixtures
  - Dependencies: ace-test-support

- ace-search/test/ace/search/atoms/*_test.rb
  - Purpose: Test all atoms in isolation
  - Key components: Pure function tests with various inputs
  - Dependencies: test_helper

- ace-search/test/ace/search/molecules/*_test.rb
  - Purpose: Test composed operations
  - Key components: File I/O tests, external command tests with VCR
  - Dependencies: test_helper, VCR for external commands

- ace-search/test/ace/search/organisms/*_test.rb
  - Purpose: Test business logic orchestration
  - Key components: Integration tests, end-to-end scenarios
  - Dependencies: test_helper, fixtures

- ace-search/test/cli_test.rb
  - Purpose: Test CLI interface end-to-end
  - Key components: Full command execution, output format validation
  - Dependencies: test_helper, run_subprocess from ace-test-support

**Documentation**:

- ace-search/README.md
  - Purpose: Comprehensive usage guide
  - Key components: Installation, usage examples, configuration guide
  - Dependencies: None

- ace-search/CHANGELOG.md
  - Purpose: Version history and changes
  - Key components: Release notes, migration notes
  - Dependencies: None

### Modify

- Gemfile (root)
  - Changes: Add `gem 'ace-search', path: './ace-search'` to development group
  - Impact: Enables development and testing of ace-search
  - Integration points: Works with existing ace-* gems

- dev-tools/exe/search
  - Changes: Update to symlink or wrapper pointing to ace-search
  - Impact: Maintains backward compatibility during transition
  - Integration points: Calls ace-search executable

### Delete (Post-Migration)

After successful migration and validation:

- dev-tools/lib/coding_agent_tools/atoms/search/ (entire directory)
  - Reason: Migrated to ace-search atoms
  - Dependencies: Only used by search tool
  - Migration strategy: Verify all tests passing before deletion

- dev-tools/lib/coding_agent_tools/molecules/search/ (entire directory)
  - Reason: Migrated to ace-search molecules
  - Dependencies: Only used by search tool
  - Migration strategy: Verify all functionality preserved

- dev-tools/lib/coding_agent_tools/organisms/search/ (entire directory)
  - Reason: Migrated to ace-search organisms
  - Dependencies: Only used by search tool
  - Migration strategy: Validate through comprehensive testing

- dev-tools/lib/coding_agent_tools/organisms/editor/ (entire directory)
  - Reason: Editor integration removed (terminal handles file:line)
  - Dependencies: Only used by search tool
  - Migration strategy: Document alternative (terminal emulator links)

- dev-tools/lib/coding_agent_tools/models/search/ (entire directory)
  - Reason: Migrated to ace-search models
  - Dependencies: Only used by search tool
  - Migration strategy: Ensure no external references

- dev-tools/spec/search/ (test files, if any)
  - Reason: Replaced by ace-search/test/
  - Dependencies: None
  - Migration strategy: Port all test cases to new structure

## Risk Assessment

### Technical Risks

- **Risk**: CLI compatibility break during migration
  - **Probability**: Low
  - **Impact**: High
  - **Mitigation**: Comprehensive integration tests covering all CLI flags, side-by-side testing
  - **Rollback**: Keep legacy tool, remove symlink

- **Risk**: Performance regression from added abstraction
  - **Probability**: Low
  - **Impact**: Medium
  - **Mitigation**: Benchmark against legacy tool, profile hot paths
  - **Rollback**: Optimize or revert to direct tool calls

- **Risk**: Configuration cascade complexity
  - **Probability**: Medium
  - **Impact**: Low
  - **Mitigation**: Follow ace-core patterns exactly, comprehensive config tests
  - **Rollback**: Simplify to single config file if needed

- **Risk**: Missing edge cases from legacy tool
  - **Probability**: Medium
  - **Impact**: Medium
  - **Mitigation**: Port all existing tests, manual testing of edge cases
  - **Rollback**: Document differences, fix incrementally

### Integration Risks

- **Risk**: ace-core dependency issues
  - **Probability**: Low
  - **Impact**: High
  - **Mitigation**: Use stable ace-core version, test dependency resolution
  - **Monitoring**: CI matrix testing across Ruby versions

- **Risk**: External tool (rg/fd) version incompatibility
  - **Probability**: Low
  - **Impact**: Medium
  - **Mitigation**: Version detection in tool_checker, document minimum versions
  - **Monitoring**: Test with multiple tool versions

- **Risk**: Breaking changes for Claude Code integration
  - **Probability**: Low
  - **Impact**: Medium
  - **Mitigation**: Maintain output format compatibility, test agent workflows
  - **Monitoring**: Validate with actual agent usage

### Performance Risks

- **Risk**: Slow startup time from gem loading
  - **Mitigation**: Profile load time, use lazy loading where possible
  - **Monitoring**: Benchmark startup time (target < 100ms)
  - **Thresholds**: Startup must be < 150ms, search execution within 5% of ripgrep direct

## Notes

This migration represents a significant architectural improvement, moving from a monolithic dev-tools structure to a modular gem-based approach.

### Key Changes from Original

1. **Removed editor integration**: Terminal already handles file:line clicking, making in-tool editor integration redundant. Users can rely on their terminal emulator's ability to open files at specific lines.
2. **Improved file search**: Now matches full paths (e.g., "controller" matches `app/controllers/user_controller.rb`), not just filenames.
3. **Better configuration**: Any CLI flag can be set as a default in config (e.g., `case_insensitive: true`, `max_results: 100`).
4. **Organized presets**: Moved from single config file to separate files in `.ace/search/presets/` directory for better maintainability.

### Benefits of migration

1. **Modularity**: Clean separation of concerns following ATOM pattern
2. **Reusability**: Can be installed as standalone gem
3. **Maintainability**: Better test coverage with ace-test-support
4. **Configuration**: Leverages ace-core's configuration cascade with comprehensive defaults
5. **Standards**: Follows established ACE gem patterns

The migration should be done incrementally with careful testing at each step to ensure no functionality is lost (except intentionally removed editor integration).

