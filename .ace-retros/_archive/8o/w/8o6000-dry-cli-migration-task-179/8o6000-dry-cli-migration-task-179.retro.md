---
id: 8o6000
title: "Retro: dry-cli Migration - Task 179"
type: self-review
tags: []
created_at: "2026-01-07 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8o6000-dry-cli-migration-task-179.md
---
# Retro: dry-cli Migration - Task 179

**Date**: 2026-01-07
**Context**: Migrating CLI framework from Thor to dry-cli across all ACE gems
**Author**: Claude Code Agent
**Type**: Self-Review

## What Went Well

- **Spike-first approach**: Successfully used ace-search as a proof-of-concept, establishing patterns for remaining migrations
- **Infrastructure creation**: Built reusable dry-cli base modules in ace-support-core before migrating individual gems
- **Pattern establishment**: Identified key patterns early (numeric type conversion, positional arguments, unused arguments handling)
- **Test coverage**: Added comprehensive tests for new infrastructure (26+ tests)
- **User-facing parity**: Maintained complete CLI behavior compatibility - no breaking changes for users

## What Could Be Improved

- **Test environment issues**: CLI routing tests hung when run via ace-test due to Minitest/capture_io interaction issues
- **Type conversion discovery**: Had to learn through debugging that dry-cli returns strings for numeric options (unlike Thor)
- **Documentation gaps**: dry-cli documentation is sparse; had to read source code to understand API
- **Registry vs Command confusion**: Initially misunderstood that `register` takes classes, not instances
- **Test adaptation**: Had to update test helper methods from `CLI.start(args)` to `Dry::CLI.new(CLI).call(arguments: args)`

## Key Learnings

- **dry-cli numeric options**: Unlike Thor, dry-cli/OptionParser returns all option values as strings. Must convert integer options (`max_results`, `context`, etc.) explicitly
- **Positional arguments in options hash**: In dry-cli, positional arguments are merged into the options hash, not passed as separate parameters
- **Unused arguments handling**: dry-cli adds unused positional arguments to `args:` key in options hash
- **Registry API**: Commands are registered as classes (e.g., `register "search", Commands::Search`), not instances
- **Default command routing**: Thor's `default_task` pattern requires manual implementation in dry-cli using exe wrapper or `start` class method
- **Testability improvement**: Moving default routing logic into `CLI.start` method makes it testable from Ruby code, not just shell

## Technical Details

### Numeric Option Type Conversion Pattern
```ruby
# In Commands::Search#call
numeric_options = %i[max_results context after_context before_context]
numeric_options.each do |key|
  clean_options[key] = clean_options[key].to_i if clean_options[key]
end
```

### Positional Arguments Pattern
```ruby
# dry-cli merges arguments into options hash
def call(**options)
  pattern = options[:pattern]
  search_path = options[:search_path]
  # Remove dry-cli's unused arguments key
  clean_options = options.reject { |k, _| k == :args }
end
```

### Default Command Routing Pattern
```ruby
# In CLI module
KNOWN_COMMANDS = %w[search version help list --help -h --version].freeze
DEFAULT_COMMAND = "search"

def self.start(args)
  if args.any? && !KNOWN_COMMANDS.include?(args.first)
    args = [DEFAULT_COMMAND] + args
  end
  Dry::CLI.new(self).call(arguments: args)
end
```

### Test Adaptation Pattern
```ruby
# Old (Thor)
Ace::Search::CLI.start(["version"])

# New (dry-cli)
Dry::CLI.new(Ace::Search::CLI).call(arguments: ["version"])
```

## Action Items

### Stop Doing

- Assuming Thor and dry-cli have identical option parsing behavior
- Running complex CLI tests without manual verification first
- Expecting dry-cli documentation to have complete examples

### Continue Doing

- Spike-first approach for framework migrations
- Creating reusable infrastructure before individual gem migrations
- Manual CLI verification as part of testing strategy
- Comprehensive test coverage for new infrastructure

### Start Doing

- Documenting type conversion requirements in workflow instructions
- Creating cookbook entries for common dry-cli patterns
- Adding dry-cli API quirks to ADR documentation
- Running tests both via ace-test and direct execution for verification

## Additional Context

**Completed Subtasks:**
- 179.01: Create dry-cli Base Infrastructure ✅
- 179.02: Migrate ace-search to dry-cli (Spike) ✅

**Remaining Subtasks (179.03-179.16):**
- 11 simple CLI gems to migrate
- 2 complex CLI gems (ace-git-worktree, ace-taskflow)
- 1 cleanup phase (remove Thor dependency)

**Pull Request:** https://github.com/cs3b/ace-meta/pull/135

**Key Files Created:**
- `ace-support-core/lib/ace/core/cli/dry_cli/base.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/config_summary_mixin.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/version_command.rb`
- `ace-search/lib/ace/search/commands/search.rb`

**Key Files Modified:**
- `ace-support-core/ace-support-core.gemspec` - Added dry-cli ~> 1.1
- `ace-search/ace-search.gemspec` - Replaced thor with dry-cli
- `ace-search/exe/ace-search` - Updated for dry-cli
- `ace-search/lib/ace/search/cli.rb` - Converted from Thor class to Registry
