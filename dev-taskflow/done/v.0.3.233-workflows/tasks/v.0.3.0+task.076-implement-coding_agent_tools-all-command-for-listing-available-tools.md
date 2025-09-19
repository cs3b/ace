---
id: v.0.3.0+task.76
status: done
priority: medium
estimate: 4h
dependencies: []
---

# Implement coding_agent_tools all Command for Listing Available Tools

## Objective

Implement a `coding_agent_tools all` command that provides a comprehensive list of all available tools to users, with blacklisting capabilities to exclude internal/development tools. Update the SETUP.md documentation to reference this command instead of directing users to multiple locations for tool discovery.

## Scope of Work

- Implement `coding_agent_tools all` CLI command in the CAT gem
- Add blacklist functionality to exclude internal/development tools from the listing
- Provide detailed tool information (name, description, category)
- Update SETUP.md to use the new command for tool discovery
- Ensure the command follows ATOM architecture patterns

### Deliverables

#### Create

- `.ace/tools/lib/coding_agent_tools/cli/all.rb` - CLI command implementation
- `.ace/tools/lib/coding_agent_tools/organisms/tool_lister.rb` - Core tool listing logic
- `.ace/tools/spec/coding_agent_tools/cli/all_spec.rb` - CLI command tests
- `.ace/tools/spec/coding_agent_tools/organisms/tool_lister_spec.rb` - Tool lister tests

#### Modify

- `.ace/tools/lib/coding_agent_tools/cli.rb` - Register new command
- `.ace/tools/docs/development/SETUP.md` - Update tool discovery documentation
- `.ace/tools/docs/tools.md` - Add reference to new command

## Implementation Plan

### Planning Steps

- [x] Research existing CLI command structure in CAT gem to understand patterns
  > TEST: Command Structure Analysis
  > Type: Pre-condition Check
  > Assert: Understanding of existing CLI patterns and ATOM architecture usage
  > Command: find .ace/tools/lib/coding_agent_tools/cli -name "*.rb" | head -5
- [x] Design tool discovery mechanism (scan exe/ directory, read command metadata)
- [x] Define blacklist structure and default entries (internal/dev tools to exclude)
- [x] Plan output format (table, categories, descriptions, usage examples)

### Execution Steps

- [x] Implement ToolLister organism following ATOM architecture
  - Scan .ace/tools/exe/ directory for available executables
  - Read command descriptions from --help output or metadata
  - Apply blacklist filtering
  - Categorize tools (LLM, Git, Navigation, Task Management, etc.)
- [x] Implement All CLI command class
  - Register with dry-cli framework
  - Handle output formatting options (table, json, plain text)
  - Integrate with ToolLister organism
- [x] Add comprehensive test coverage
  - Unit tests for ToolLister organism
  - CLI integration tests for All command
  - Test blacklist functionality
- [x] Update documentation
  - Modify SETUP.md Development Tools section (line ~290) to replace Blueprint reference with `coding_agent_tools all`
  - Remove reference to unimplemented `bin/help` command
  - Add command documentation to tools.md
  - Update any other references to manual tool discovery
- [x] Verify command integration and functionality
  > TEST: Command Integration
  > Type: Action Validation
  > Assert: `coding_agent_tools all` command works and shows expected tools
  > Command: cd .ace/tools && bundle exec exe/coding_agent_tools all | wc -l

## Acceptance Criteria

- [x] AC 1: `coding_agent_tools all` command lists all available tools with descriptions
- [x] AC 2: Blacklist functionality excludes internal/development tools from output
- [x] AC 3: Tools are categorized appropriately (LLM, Git, Navigation, etc.)
- [x] AC 4: SETUP.md updated to use new command instead of manual references
- [x] AC 5: Command follows ATOM architecture patterns and has test coverage
- [x] AC 6: Output is well-formatted and user-friendly

## Technical Requirements

### Blacklist Default Entries
```yaml
# Example blacklist entries to exclude
blacklist:
  - "coding_agent_tools"  # Main wrapper command
  - "*-dev"               # Development tools
  - "*-debug"             # Debug utilities
  - "test-*"              # Test utilities
```

### Output Format
```
Available Coding Agent Tools:

LLM Integration:
  llm-query              - Unified LLM query interface for multiple providers
  
Git Operations:
  git-add               - Enhanced git add with multi-repo support
  git-commit            - Enhanced git commit with intention-based messages
  git-status            - Enhanced git status across all repositories
  
Task Management:
  task-manager          - Project task management and navigation
  release-manager       - Release coordination and reporting
  
Navigation:
  nav-ls               - Enhanced directory listing with filtering
  nav-path             - Intelligent path navigation and resolution
  nav-tree             - Enhanced project tree with context filtering

Total: 25+ tools available
```

## Out of Scope

- ❌ Implementing tools that don't exist yet
- ❌ Changing existing tool functionality or interfaces
- ❌ Adding new tool categories beyond current organization
- ❌ Implementing shell completion (separate future task)

## Documentation Changes Required

### Current SETUP.md Section (lines ~287-292):
```markdown
## Development Tools

The project includes various `bin/` scripts to automate development tasks, testing, and common workflows. For a comprehensive list and description of all available `bin/` and `.ace/tools/exe/` commands, refer to the [Project Blueprint](docs/blueprint.md#entry-points).

You can also run `bin/help` (once implemented) or `bin/<command> --help` for specific command usage.
```

### Proposed Replacement:
```markdown
## Development Tools

The project includes 25+ CLI tools for development automation, LLM integration, and workflow management. To see all available tools with descriptions:

```bash
# List all available tools with descriptions and categories
coding_agent_tools all

# Get help for specific commands
<command> --help
```

For detailed documentation, see [Tools Reference](docs/tools.md).
```

## References

- CAT gem CLI architecture in `.ace/tools/lib/coding_agent_tools/cli/`
- ATOM architecture patterns in CAT gem
- Existing tool documentation in `.ace/tools/docs/tools.md`
- Current SETUP.md tool discovery section (lines 287-292)