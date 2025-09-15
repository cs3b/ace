---

id: v.0.3.0+task.13
status: near-completion
priority: medium
estimate: 16h
time_spent: 14h
dependencies: [v.0.3.0+task.06]
---

# Implement Module-Based CLI Commands

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/cli/commands | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/cli/commands
    ├── llm
    └── (other command directories)
```

## Objective

Implement intelligent navigation CLI commands that provide sophisticated path resolution, autocorrection, and configuration-driven tree filtering. This includes nav-path for intelligent path generation/resolution and nav-tree with .coding-agent/tree.yml configuration support. Git module implementation is handled in task 19, and code quality validation is handled in task 36.

## Status Update - December 7, 2024

### ✅ COMPLETED
- **nav-path, nav-tree, nav-ls commands**: All three navigation commands implemented with standalone executables
- **Smart Path Prioritization**: Automatically selects best match from multiple results, shows alternatives
- **Enhanced Fuzzy Matching**: Pattern matching with autocorrect mappings and path traversal cleanup
- **Simplified Security Model**: Project root sandboxing with forbidden patterns (no complex allowed patterns)
- **Configuration Files**: .coding-agent/tree.yml and .coding-agent/path.yml with autocorrect mappings
- **Project Root Detection**: Uses existing ProjectRootDetector atom for multi-repository support
- **Path Normalization**: Handles complex paths like `../../../lib` and autocorrects common typos

### 🔄 IN PROGRESS  
- **Fuzzy Search Architecture**: Core fuzzy matching works but needs architectural fix for search pattern validation

### 📝 REMAINING
- **Binstub aliases**: Add np/nt shortcuts 
- **Final fuzzy search fix**: Resolve search pattern vs. results validation issue

## Scope of Work

* Create intelligent navigation module with path resolution capabilities
* Implement `nav-path` with intelligent path generation and autocorrection:
  - `nav-path task-new --title ""` - generate new task paths without creating files
  - `nav-path task $task-id` - resolve existing task paths
  - `nav-path docs-new --title ""` - generate documentation paths
  - `nav-path reflection-new --title ""` - generate reflection paths
  - `nav-path file $path` - autocorrect incomplete paths to full project paths
* Implement `nav-tree` with configuration-driven filtering using .coding-agent/nav-tree.yml
* Support path autocorrection across all 4 repositories in project root
* Use .coding-agent/nav-path.yml for scan ordering and ignore patterns
* Return full absolute paths for agent directory awareness
* Display multiple path matches as selectable list for user/agent decision
* Integrate with fzf for fuzzy search when available
* Sandbox all operations to project root subtree (security boundary)
* Integrate with existing multi-repository tooling (bin/rc, bin/tnid)

### Deliverables

#### Create

* lib/coding_agent_tools/cli/commands/nav.rb (nav module namespace)
* lib/coding_agent_tools/cli/commands/nav/tree.rb (parameter parsing, path filtering, delegates to system tree)
* lib/coding_agent_tools/cli/commands/nav/path.rb (intelligent path resolution with autocorrection)
* lib/coding_agent_tools/molecules/nav_tree_config_loader.rb (nav-tree.yml configuration loader)
* lib/coding_agent_tools/molecules/nav_path_config_loader.rb (nav-path.yml configuration loader)
* lib/coding_agent_tools/molecules/path_resolver.rb (path resolution logic)
* lib/coding_agent_tools/molecules/path_autocorrector.rb (fuzzy path matching with fzf integration)
* lib/coding_agent_tools/molecules/project_sandbox.rb (project root security boundary)
* .coding-agent/nav-tree.yml (tree filtering configuration for nav commands)
* .coding-agent/nav-path.yml (path scanning configuration for nav commands)
* Corresponding spec files for all new components

#### Modify

* lib/coding_agent_tools/cli.rb (register nav module namespace) - already updated
* dev-tools/config/binstub-aliases.yml (add np/nt shortcuts for nav commands)

#### Delete

* None

## Phases

1. Create nav-specific configuration files (.coding-agent/nav-tree.yml and nav-path.yml)
2. Implement path resolution molecules with security validation
3. Create nav module namespace and basic command structure
4. Implement nav-path with intelligent path generation and resolution
5. Implement nav-tree with param parsing, path filtering, and delegation to system tree command
6. Add comprehensive testing including security and performance tests
7. Integration testing with existing multi-repository tooling

## Implementation Plan

### Planning Steps

* [x] Design nav-tree.yml and nav-path.yml configuration schemas for nav-specific settings
  > TEST: Configuration Schema Design
  > Type: Pre-condition Check
  > Assert: Nav-specific configuration schemas designed for parameter parsing and path filtering
  > Command: echo "Nav configuration schemas designed"
* [x] Analyze show-directory-tree options (116 lines) for nav-tree integration
  > TEST: Tree Options Analysis
  > Type: Pre-condition Check
  > Assert: Tree command options understood
  > Command: grep -E "depth|exclude|include" dev-tools/exe-old/show-directory-tree | wc -l
* [x] Research path resolution security requirements (project root sandbox)
  > TEST: Security Requirements Analysis
  > Type: Pre-condition Check
  > Assert: Project root sandboxing strategy prevents path traversal
  > Command: echo "Security analysis complete"
* [x] Research fzf integration for fuzzy search performance optimization
  > TEST: FZF Integration Analysis
  > Type: Pre-condition Check
  > Assert: FZF availability detection and fallback strategy planned
  > Command: which fzf || echo "FZF fallback strategy needed"
* [x] Plan integration with existing bin/rc and bin/tnid commands for path generation
  > TEST: Integration Planning
  > Type: Pre-condition Check
  > Assert: Integration points with existing tooling identified
  > Command: ls -la bin/rc bin/tnid | wc -l

### Execution Steps

- [x] Create .coding-agent/tree.yml and .coding-agent/path.yml configuration files
  > TEST: Nav Configuration Files Creation
  > Type: File Test
  > Assert: Nav-specific configuration files exist and are valid YAML
  > Command: test -f .coding-agent/nav-tree.yml && test -f .coding-agent/nav-path.yml && ruby -ryaml -e "YAML.load_file('.coding-agent/nav-tree.yml'); YAML.load_file('.coding-agent/nav-path.yml')"
- [x] Implement config loader molecules for tree.yml and path.yml parsing
  > TEST: Nav Config Loaders
  > Type: Unit Test
  > Assert: Nav configuration loaders parse YAML files correctly
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/nav_tree_config_loader_spec.rb spec/coding_agent_tools/molecules/nav_path_config_loader_spec.rb
- [x] Implement project_sandbox molecule for project root security boundary
  > TEST: Project Sandbox Security
  > Type: Security Test
  > Assert: All path operations stay within project root
  > Command: cd dev-tools && bundle exec rspec spec/molecules/project_sandbox_spec.rb --tag security
- [x] Implement path_resolver molecule with sandbox integration
  > TEST: Path Resolver Security
  > Type: Security Test
  > Assert: Path resolver works within project sandbox
  > Command: cd dev-tools && bundle exec rspec spec/molecules/path_resolver_spec.rb --tag security
- [x] Implement path_autocorrector molecule with fzf integration and fallback
  > TEST: Path Autocorrector with FZF
  > Type: Unit Test
  > Assert: Path autocorrector uses fzf when available, fallback otherwise
  > Command: cd dev-tools && bundle exec rspec spec/molecules/path_autocorrector_spec.rb
- [x] Add multiple match handling with selectable list output
  > TEST: Multiple Match Selection
  > Type: CLI Test
  > Assert: Multiple matches displayed as numbered list for selection
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools nav path file "test" | grep -E "^[0-9]+\)"
- [x] Create nav.rb module namespace with intelligent path resolution
- [x] Implement nav-path with task-new, task, docs-new, reflection-new, and file subcommands
  > TEST: Nav Path Intelligent Resolution
  > Type: CLI Test
  > Assert: Nav path resolves and generates paths correctly
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools nav path task-new --title "test-task"
- [x] Implement nav-tree with parameter parsing, path filtering, and system tree delegation
  > TEST: Nav Tree Implementation
  > Type: CLI Test
  > Assert: Nav tree parses parameters, filters paths, and delegates to system tree command
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools nav tree
- [x] Add integration with bin/rc and bin/tnid for path generation across all 4 repositories
  > TEST: Multi-Repository Integration
  > Type: Integration Test
  > Assert: Nav commands scan all 4 repositories using path.yml ordering
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools nav path task-new --title "integration-test"
- [x] Register nav module namespace in CLI module
- [ ] Update binstub-aliases.yml to add nav command shortcuts (np for nav-path, nt for nav-tree)
  > TEST: Binstub Integration
  > Type: Configuration Test
  > Assert: Binstub aliases are properly configured for nav commands
  > Command: grep -E "(np|nt):" dev-tools/config/binstub-aliases.yml
- [x] Create comprehensive CLI tests using Aruba including security and performance tests
  > TEST: Comprehensive CLI Testing
  > Type: Integration Test
  > Assert: All nav commands work correctly with edge cases
  > Command: cd dev-tools && bundle exec rspec spec/cli/nav_integration_spec.rb

## Acceptance Criteria

* [ ] Nav-path generates correct paths for task-new, docs-new, reflection-new without creating files
* [ ] Nav-path resolves existing task paths by ID correctly
* [ ] Nav-path autocorrects incomplete file paths to full project paths
* [ ] Nav-path handles multiple path matches by displaying numbered selection list
* [ ] Nav-path returns full absolute paths for agent directory awareness
* [ ] Nav-path scans all 4 repositories according to .coding-agent/nav-path.yml ordering
* [ ] Nav-path uses fzf for fuzzy search when available, with graceful fallback
* [ ] Nav-tree uses .coding-agent/nav-tree.yml for parameter parsing and path filtering
* [ ] Nav-tree delegates filtered parameters to system tree command for actual tree display
* [ ] All path operations stay within project root sandbox (no path traversal outside)
* [ ] Project sandbox molecule prevents access outside project root subtree
* [ ] Integration with bin/rc and bin/tnid works correctly for path generation
* [ ] Performance is optimized using fzf when available for fuzzy searching
* [ ] Fallback path matching performs acceptably on large codebases
* [ ] Module-based help system works correctly with examples
* [ ] All commands follow consistent error handling and output formatting

## Out of Scope

* ❌ Implementing markdown module commands (separate task needed)
* ❌ Implementing git module commands (handled in task 19)
* ❌ Implementing code quality validation (handled in task 36)
* ❌ Full filesystem indexing or database-backed path resolution
* ❌ Cross-repository file synchronization or modification
* ❌ Real-time file watching or change detection
* ❌ Integration with external IDEs or editors
* ❌ Path operations outside project root (strict sandboxing enforced)
* ❌ Complex fuzzy search algorithms (rely on fzf when available)
* ❌ Global configuration files (all configs are repository-specific)

## References

* Dependency: v.0.3.0+task.06 (molecules for shell operations and path handling) - ✅ COMPLETED
* Tree tool: dev-tools/exe-old/show-directory-tree (116 lines) - reference for parameter parsing patterns
* Current tree wrapper: bin/tree - simple eza wrapper that nav-tree complements (different use case)
* System tree command: nav-tree will parse parameters, filter paths, then delegate to system `tree` command
* Nav-specific configs: .coding-agent/nav-tree.yml and .coding-agent/nav-path.yml (new files for nav commands)
* Multi-repo context: bin/rc - release context command for path generation
* Task ID generation: bin/tnid - task ID generator for path building
* Git module: See v.0.3.0+task.19 for git-log implementation
* Code module: See v.0.3.0+task.36 for code-lint implementation
* Security considerations: Project root sandboxing prevents path traversal outside project
* Performance optimization: fzf integration for fast fuzzy search with graceful fallback
* Configuration approach: Repository-specific .coding-agent/ configs (tree.yml, path.yml)
* Multi-repository scanning: All 4 repos (tools-meta, dev-tools, dev-taskflow, dev-handbook)
* XDG compliance: Follow existing patterns from XDGDirectoryResolver atom