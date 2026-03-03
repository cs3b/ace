---
id: 8o8vs8
title: 'Retro: Wrapper Pattern Oversight During dry-cli Migration'
type: self-review
tags: []
created_at: '2026-01-09 21:11:21'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8o8vs8-dry-cli-wrapper-pattern-oversight.md"
---

# Retro: Wrapper Pattern Oversight During dry-cli Migration

**Date**: 2026-01-09
**Context**: Why the wrapper pattern was not eliminated during the initial dry-cli migration (Task 179)
**Author**: Claude Code Agent
**Type**: Self-Review

## What Went Well

- Successfully migrated all ACE gems from Thor to dry-cli
- Maintained CLI behavior parity throughout migration
- Created reusable infrastructure in ace-support-core
- Comprehensive test coverage for new infrastructure

## What Could Be Improved

- **Scope definition**: The original migration task (179) was scoped as "migrate CLI framework" rather than "modernize CLI architecture"
- **Pattern recognition**: Did not recognize the wrapper pattern as tech debt during migration
- **Reference pattern timing**: The ace-llm-models-dev pattern (direct dry-cli commands without wrappers) existed but was not referenced during migration planning

## Root Cause Analysis

### Why Was the Wrapper Pattern Overlooked?

1. **Migration vs Refactoring Mindset**
   - Task 179 was framed as a "migration" - swap Thor for dry-cli
   - The goal was behavioral parity, not architectural improvement
   - "Don't change what isn't broken" approach preserved existing patterns

2. **Wrapper Pattern Was Pre-Existing**
   - The `CommandClass` + `wrapper.rb` pattern existed before dry-cli
   - It was a Thor-era convention: thin CLI wrapper → business logic class
   - Migration preserved this 1:1 without questioning its necessity

3. **Different Gem Origins**
   - Some gems (ace-llm-models-dev) were built fresh with dry-cli
   - Other gems (ace-context, ace-review, etc.) were migrated from Thor
   - Migrated gems kept their legacy patterns; new gems used cleaner patterns

4. **Risk Aversion During Migration**
   - Combining framework change + refactoring would increase risk
   - Preserving structure made migration validation easier
   - "One thing at a time" principle was correctly applied

5. **No Explicit Pattern Audit**
   - Migration checklist focused on: CLI works? Tests pass? User behavior unchanged?
   - Did not include: "Is this the optimal pattern for the new framework?"

### The Wrapper Pattern's Origin

The wrapper pattern likely emerged from Thor's class-based design:
```ruby
# Thor-era: CLI class IS the command class
class Ace::Context::CLI < Thor
  desc "load INPUT", "Load context"
  def load(input)
    # Business logic mixed with CLI
  end
end
```

When complexity grew, developers extracted business logic:
```ruby
# Extracted pattern
class Load < Thor::Command
  def call
    LoadCommand.new(options).execute  # Wrapper → Business logic
  end
end
```

This was reasonable for Thor. But dry-cli's design makes the wrapper unnecessary - the command class can cleanly contain all logic.

## Key Learnings

- **Migration preserves patterns by default**: Framework migrations naturally carry over existing patterns unless explicitly scoped otherwise
- **New code sets the standard**: ace-llm-models-dev (built fresh with dry-cli) showed the ideal pattern; migrated code should be refactored to match
- **Technical debt accrues invisibly**: The wrapper pattern wasn't "wrong" - it just became unnecessary overhead after dry-cli adoption
- **Separate concerns**: Migration (behavioral parity) and refactoring (architectural improvement) should be distinct phases

## Action Items

### Stop Doing

- Treating framework migrations as purely mechanical find-and-replace
- Assuming pre-existing patterns are optimal for new frameworks

### Continue Doing

- Separating large changes into distinct phases (migrate first, refactor second)
- Using spike projects to establish patterns before broad rollout
- Creating dedicated refactoring tasks after major migrations

### Start Doing

- Including "pattern audit" step in migration workflows
- Documenting target patterns BEFORE migration begins
- Creating explicit follow-up tasks for pattern alignment after migrations
- Reference new-build examples when migrating legacy code

## Technical Details

### The Wrapper Pattern (to be eliminated)

```ruby
# wrapper.rb - thin CLI definition
class Load < Dry::CLI::Command
  def call(**options)
    LoadCommand.new(options).execute  # Delegation
  end
end

# load_command.rb - business logic
class LoadCommand
  def initialize(options)
    @options = options
  end

  def execute
    # Actual work
  end
end
```

### Target Pattern (direct dry-cli)

```ruby
# load.rb - unified command
class Load < Dry::CLI::Command
  def call(**options)
    # Business logic directly here
    result = Ace::Context.load_auto(options[:input])
    display_result(result, options)
  end

  private

  def display_result(result, options)
    # Helper methods as needed
  end
end
```

## Impact Assessment

- **9 packages affected**: ace-context, ace-nav, ace-git, ace-git-commit, ace-lint, ace-llm, ace-review, ace-search, ace-test-runner
- **Estimated cleanup effort**: ~18h total across all tasks (189-197)
- **Benefit**: Reduced file count, simpler architecture, easier maintenance, consistent patterns across monorepo

## Additional Context

**Related Tasks:**
- Task 179: Original dry-cli migration (completed)
- Tasks 189-197: Wrapper pattern elimination (planned)

**Reference Implementation:**
- `ace-llm-models-dev/lib/ace/llm/models_dev/cli/` - Shows correct pattern

**Previous Retro:**
- `8o6000-dry-cli-migration-task-179.md` - Migration learnings (didn't identify wrapper pattern as tech debt)