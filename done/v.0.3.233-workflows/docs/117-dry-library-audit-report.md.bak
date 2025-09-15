# Dry Library Usage Audit Report - Task 117

## Executive Summary

Comprehensive audit of 29 executables in `dev-tools/exe/` directory to assess dry library usage patterns and identify standardization needs.

## Audit Results

### Executable Inventory

Total executables found: **29**

Complete list:
- code-lint
- code-review  
- code-review-prepare
- code-review-synthesize
- coding_agent_tools
- create-path
- git-add, git-checkout, git-commit, git-diff, git-fetch, git-log, git-mv, git-pull, git-push, git-restore, git-rm, git-status, git-switch
- handbook
- llm-models, llm-query, llm-usage-report
- nav-ls, nav-path, nav-tree
- reflection-synthesize
- release-manager
- task-manager

## Classification by Pattern Usage

### Category 1: ExecutableWrapper Pattern (COMPLIANT)
**Count: 19 executables**

Uses `CodingAgentTools::Molecules::ExecutableWrapper` which internally uses dry-cli:

- code-lint
- code-review
- code-review-prepare  
- code-review-synthesize
- create-path
- All git-* commands (12 total): git-add, git-checkout, git-commit, git-diff, git-fetch, git-log, git-mv, git-pull, git-push, git-restore, git-rm, git-status, git-switch
- handbook
- llm-models, llm-query, llm-usage-report
- reflection-synthesize

**Pattern Structure:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true (sometimes)

lib_path = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

require "coding_agent_tools/molecules/executable_wrapper"

CodingAgentTools::Molecules::ExecutableWrapper.new(
  command_path: ["command", "subcommand"],
  registration_method: :register_xxx_commands,  # optional
  executable_name: "executable-name"            # optional
).call
```

### Category 2: Direct Dry::CLI Usage (COMPLIANT)
**Count: 3 executables**

- coding_agent_tools
- release-manager  
- task-manager

**Pattern Structure:**
```ruby
#!/usr/bin/env ruby

# Setup load paths
lib_path = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

# For coding_agent_tools:
require "coding_agent_tools/cli"
Dry::CLI.new(CodingAgentTools::Cli::Commands).call

# For release-manager/task-manager:
# Custom module with Dry::CLI::Registry
# Register commands
# Dry::CLI.new(CustomCommands).call
```

### Category 3: Manual ARGV Parsing (NON-COMPLIANT)
**Count: 3 executables**  

- nav-ls
- nav-path
- nav-tree

**Current Pattern:**
- Uses manual `ARGV` parsing
- Custom help/version handling
- Direct argument extraction and option parsing

**Issues with Current Approach:**
- Inconsistent with project standards
- Manual argument parsing is error-prone
- No unified help system
- Duplicate code across similar executables

## Detailed Non-Compliant Analysis

### nav-ls
- **Lines of manual parsing**: ~30 lines
- **Features**: --help, --version, --long, --all, --autocorrect/--no-autocorrect
- **Current complexity**: Moderate

### nav-path  
- **Lines of manual parsing**: ~25 lines
- **Features**: --help, --version, commands (task-new, task, file), --title
- **Current complexity**: Moderate with positional args

### nav-tree
- **Lines of manual parsing**: ~30 lines  
- **Features**: --help, --version, --context, --depth, --autocorrect
- **Current complexity**: Moderate

## Standardization Strategy

### Recommended Approach

**Option 1: ExecutableWrapper Pattern (RECOMMENDED)**
- Migrate nav-* commands to use ExecutableWrapper
- Maintain existing CLI interface
- Leverage existing dry-cli infrastructure

**Option 2: Direct Dry::CLI Implementation**
- Create custom command classes for nav commands
- Register in main CLI system
- More work but better integration

### Implementation Priority

1. **nav-ls** - Simplest interface, good starting point
2. **nav-tree** - Similar to nav-ls
3. **nav-path** - Most complex due to positional arguments

## Required Changes

### For Each Non-Compliant Executable:

1. **Create corresponding CLI command class** in `lib/coding_agent_tools/cli/commands/nav/`
2. **Update executable** to use ExecutableWrapper pattern  
3. **Register command** in CLI system if needed
4. **Test compatibility** with existing interfaces
5. **Update documentation** if interface changes

### Standard Template Needed

Create `docs/executable-template.rb` with the standard ExecutableWrapper pattern for future executables.

## Testing Strategy

1. **Before/after CLI testing** for each executable
2. **Help output verification** 
3. **Argument parsing compatibility**
4. **Integration testing** with existing workflows

## Risks and Considerations

- **Interface compatibility**: Ensure existing usage patterns continue to work
- **Error handling**: Maintain current error behavior
- **Performance**: ExecutableWrapper may add minimal overhead
- **Dependencies**: Ensure all required CLI classes exist

## Effort Estimation

- **nav-ls**: 1 hour
- **nav-tree**: 1 hour  
- **nav-path**: 1.5 hours (more complex positional args)
- **Template creation**: 0.5 hours
- **Total**: ~4 hours (matches task estimate)

## Success Criteria

- ✅ All 29 executables use dry-cli (directly or via ExecutableWrapper)
- ✅ No manual ARGV parsing in any executable
- ✅ Consistent error handling patterns
- ✅ Standard executable template available
- ✅ All existing CLI interfaces continue to work
- ✅ Help system is unified across all commands

---

*Audit completed: All patterns identified and migration strategy defined*