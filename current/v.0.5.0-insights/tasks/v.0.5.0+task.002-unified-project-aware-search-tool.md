---
id: v.0.5.0+task.002
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Unified Project-Aware Search Tool

## Behavioral Specification

### User Experience
- **Input**: Search patterns/globs with optional flags from any project subdirectory
- **Process**: Automatic project root detection, DWIM mode selection, git-aware file enumeration, multi-repository coordination
- **Output**: Editor-friendly results with context lines, interactive fzf selection, or structured JSON for automation

### Expected Behavior
Users experience a single, intelligent search command that seamlessly handles both file name and content searches across their entire project, including submodules and nested repositories. The tool automatically detects the project root from any subdirectory, making search behavior consistent regardless of where it's invoked. Smart DWIM heuristics determine whether users want to search file names, file contents, or both based on the pattern and flags provided. Git-aware scopes allow focusing searches on tracked, staged, changed, or recent files with time-based filtering.

The system provides immediate visual feedback with streaming results, context lines around matches, and syntax highlighting. Interactive mode with fzf enables real-time preview and selection, while the `--open` flag allows direct navigation to matches in the user's preferred editor. For automation needs, structured JSON output conforms to a documented schema.

### Interface Contract
```bash
# CLI Interface
search [FLAGS] [--] <pattern>
search --files [FLAGS] [--] <glob>...  
search --preset <name> [--var k=v ...] [FLAGS] [--] <pattern?>

# Key flags
-C, --context <N>         # Lines of context (default: 2)
-n, --name <glob>         # Include only matching files
-t, --type <types>        # File types (rb, js, ts, etc.)
--tracked/--staged        # Git-aware scopes
--changed [<range>]       # Changed files in range
--since <time>           # Files changed since time
--fzf                    # Interactive mode
--open                   # Open in $EDITOR
--json                   # Machine-readable output
```

**Error Handling:**
- Missing dependencies: Actionable install instructions
- Invalid git ranges: Clear error messages with examples
- No matches: Exit code 1 (distinguishable from errors)
- Conflicting flags: Helpful explanations with corrections

**Edge Cases:**
- Empty pattern: Show usage help
- Massive result sets: Respect --max-results limit
- Binary files: Skip with notification
- Symlinks: Follow with cycle detection
- Large files: Stream results efficiently

### Success Criteria
- [ ] **Project Root Detection**: Tool finds root from any subdirectory within 50ms
- [ ] **DWIM Accuracy**: Mode selection matches user intent 90%+ of the time
- [ ] **Multi-Repository Support**: Seamless search across submodules and nested repos
- [ ] **Editor Integration**: --open flag works with VS Code, Vim, Sublime
- [ ] **Performance**: Startup ≤ 200ms, results begin streaming immediately
- [ ] **Git Integration**: Scopes correctly enumerate files across all repositories
- [ ] **JSON Schema**: Output validates against documented schema
- [ ] **Preset System**: User-defined presets merge correctly with CLI flags

### Validation Questions
- [ ] **Requirement Clarity**: Should binary file handling be configurable or always skip?
- [ ] **Edge Case Handling**: How should the tool handle repositories with no commits?
- [ ] **User Experience**: Should --fzf mode support multi-select for batch operations?
- [ ] **Success Definition**: What constitutes acceptable performance for 100k+ file repos?

## Objective

Provide developers and AI agents with a unified, intelligent search tool that eliminates the complexity of choosing between `fd`, `rg`, `grep`, and `git grep`. Enable efficient code discovery and navigation across complex multi-repository projects with smart defaults and powerful customization options.

## Scope of Work

- **User Experience Scope**: All search interactions from simple pattern matching to complex multi-repository queries
- **System Behavior Scope**: File enumeration, content searching, git integration, result formatting
- **Interface Scope**: CLI with comprehensive flags, configuration files, preset system, editor integrations

### Deliverables

#### Behavioral Specifications
- Complete DWIM heuristics definition
- Git-aware scope enumeration algorithms
- Multi-repository coordination logic
- Interactive mode user flows

#### Validation Artifacts
- Performance benchmarks for various repository sizes
- DWIM accuracy test suite
- Editor integration test scenarios
- JSON schema validation tests

## Out of Scope

- ❌ **Implementation Details**: Ruby gem structure, ATOM architecture specifics
- ❌ **Technology Decisions**: Specific Faraday configurations, caching strategies
- ❌ **Performance Optimization**: Detailed threading models, memory management
- ❌ **Future Enhancements**: Language server integration, Windows support

## References

- Source idea: dev-taskflow/backlog/ideas/20250809-1022-unified-project-aware-search-spec.md
- Similar tools: ripgrep, fd, git grep, ack, ag
- Integration examples: fzf.vim, telescope.nvim
