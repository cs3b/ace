---
status: done
completed_at: 2026-01-10 02:57:56.000000000 +00:00
id: 8o93va
title: Idea
tags: []
created_at: '2026-01-10 02:34:45'
---

# Idea

Extract shared CLI routing module to ace-support-core

---
Captured: 2026-01-10 02:34:46

## Context

During PR #145 (Task 200) code review, multiple LLM models noted that the CLI routing logic is duplicated across 12+ ace-* gems.

## Current State

Each CLI gem implements identical routing logic:
- `REGISTERED_COMMANDS`, `BUILTIN_COMMANDS`, `KNOWN_COMMANDS` constants
- `known_command?(arg)` method
- `CLI.start(args)` with default command injection

## Proposal

Create `Ace::Core::CLI::DryCli::Routing` module in ace-support-core:

```ruby
module Ace::Core::CLI::DryCli::Routing
  def self.route(args, default:, known_commands:)
    return [default] + args if args.empty? || !known_commands.include?(args.first)
    args
  end
end
```

## Benefits

- DRY: Single implementation across all gems
- Consistent: Same behavior guaranteed
- Testable: One set of comprehensive tests
- Maintainable: Updates propagate automatically

## Affected Gems

- ace-docs, ace-prompt, ace-git-commit (updated in Task 200)
- ace-search, ace-lint, ace-nav, ace-context
- ace-review, ace-taskflow, ace-test-runner
- And ~5 more

## Estimate

2-3 hours