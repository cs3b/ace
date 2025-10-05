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

* [x] Analyze existing search tool structure (695 lines in exe/search)
* [x] Identify all dependencies and components to migrate
* [x] Map current structure to ACE gem patterns
* [x] Define migration strategy preserving CLI compatibility

## Execution Steps

- [ ] Create ace-search gem structure
  - [ ] Initialize gem with `bundle gem ace-search`
  - [ ] Set up ATOM directory structure (atoms/, molecules/, organisms/, models/)
  - [ ] Create .ace.example/search/config.yml
  - [ ] Configure gemspec with ace-core dependency

- [ ] Migrate search components
  - [ ] Port atoms (ripgrep_executor, fd_executor, path_matcher)
  - [ ] Port molecules (preset_manager, git_scope_filter, dwim_analyzer, time_filter, fzf_integrator)
  - [ ] Port organisms (unified_searcher, result_formatter, result_aggregator)
  - [ ] Port models (search_result, search_options, search_preset)

- [ ] Create executable with compatibility wrapper
  - [ ] Create exe/ace-search with full CLI compatibility
  - [ ] Add exe/search as alias/symlink
  - [ ] Ensure all flags and options work identically
  - [ ] Preserve output format exactly

- [ ] Integrate with ace-core
  - [ ] Use ace-core for configuration cascade
  - [ ] Replace custom project_root_detector with ace-core's
  - [ ] Use ace-core atoms where applicable (file_reader, yaml_parser)

- [ ] Set up configuration
  - [ ] Create .ace.example/search/config.yml template with default flags
  - [ ] Create .ace.example/search/presets/ directory structure
  - [ ] Support presets as separate YAML files in presets/ directory
  - [ ] Allow any CLI flag as a configuration default
  - [ ] Ensure configuration cascade: defaults → config → preset → CLI flags

- [ ] Create comprehensive tests
  - [ ] Port existing tests from dev-tools/spec
  - [ ] Add integration tests for CLI compatibility
  - [ ] Test all option combinations
  - [ ] Verify output format matches exactly
  - [ ] Use ace-test-support for test infrastructure

- [ ] Create usage documentation
  - [ ] Write comprehensive usage.md following ace-gems patterns
  - [ ] Include migration guide from old to new
  - [ ] Document all commands and options
  - [ ] Add troubleshooting section

- [ ] Implement transition strategy
  - [ ] Add ace-search to root Gemfile
  - [ ] Test side-by-side with original
  - [ ] Create symlink: dev-tools/exe/search → ../ace-search/exe/ace-search
  - [ ] Document deprecation timeline

## Acceptance Criteria

- [ ] All existing search commands work without modification (except editor integration)
- [ ] File search improved to match full paths, not just filenames
- [ ] Output format identical to current implementation (with clickable terminal links)
- [ ] Performance equal or better than current version
- [ ] Configuration supports all CLI flags as defaults
- [ ] Presets organized in .ace/search/presets/ directory
- [ ] All tests passing with ace-test-support
- [ ] Usage documentation complete and accurate
- [ ] Can be installed as standalone gem
- [ ] Follows ACE gem architecture patterns exactly

## Dependencies

- ace-core (for configuration and utilities)
- ace-test-support (for testing infrastructure)
- ripgrep (external dependency)
- fd (external dependency)
- fzf (optional external dependency)

## Metadata

- **ID**: v.0.9.0+task.059
- **Status**: draft
- **Priority**: P2
- **Estimate**: 2 days
- **Dependencies**: None
- **Tags**: #migration #ace-gem #search #refactoring

## Notes

This migration represents a significant architectural improvement, moving from a monolithic dev-tools structure to a modular gem-based approach.

### Key Changes from Original:
1. **Removed editor integration**: Terminal already handles file:line clicking, making in-tool editor integration redundant. Users can rely on their terminal emulator's ability to open files at specific lines.
2. **Improved file search**: Now matches full paths (e.g., "controller" matches `app/controllers/user_controller.rb`), not just filenames.
3. **Better configuration**: Any CLI flag can be set as a default in config (e.g., `case_insensitive: true`, `max_results: 100`).
4. **Organized presets**: Moved from single config file to separate files in `.ace/search/presets/` directory for better maintainability.

### Benefits of migration:
1. **Modularity**: Clean separation of concerns following ATOM pattern
2. **Reusability**: Can be installed as standalone gem
3. **Maintainability**: Better test coverage with ace-test-support
4. **Configuration**: Leverages ace-core's configuration cascade with comprehensive defaults
5. **Standards**: Follows established ACE gem patterns

The migration should be done incrementally with careful testing at each step to ensure no functionality is lost (except intentionally removed editor integration).