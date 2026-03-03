---
id: 8o4000
title: CLI Standardization - Why So Much Fixing?
type: conversation-analysis
tags: []
created_at: '2026-01-05 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8o4000-cli-standardization-scope-creep.md"
---

# Reflection: CLI Standardization - Why So Much Fixing?

**Date**: 2026-01-05
**Context**: Task 150 - Standardizing CLI parameter configuration and output summary across 15+ ACE CLI gems
**Author**: Claude Code
**Type**: Conversation Analysis | Process Reflection

## What Went Well

- Systematic approach: Breaking work into 150.13, 150.14, 150.15 subtasks made progress trackable
- Pattern identification: Once `Ace::Core::CLI::Base` was established, applying it across CLIs was mechanical
- Test coverage: Existing tests caught issues quickly (like the ace-git `-v` test needing removal)
- Clear decision points: User decisions on `-v` semantics, ace-git-secrets inclusion, and task structure prevented ambiguity

## What Could Be Improved

- **Initial scope estimation**: PR review identified 13 CLIs needing changes, but actual count was 15 (ace-git-secrets and ace-docs were special cases)
- **Incremental debt**: Each CLI had slightly different patterns, requiring individual analysis
- **Missing centralization earlier**: The `Ace::Core::CLI::Base` should have existed from the first CLI, not as a retrofit
- **Documentation gaps**: No single source documented the expected CLI conventions

## Key Learnings

- **Technical debt compounds**: Each CLI added its own `exit_on_failure?`, version mapping, and help patterns. 15 implementations means 15 sources of inconsistency
- **Convention > Configuration > Code**: Having a base class with conventions eliminates repeated decisions
- **Special cases accumulate**: ace-git's magic routing, ace-git-secrets' thread safety, ace-lint's default command routing - each "special" case needs documentation
- **Retrofit is expensive**: Standardizing 15 CLIs after the fact required reading/understanding each one vs. using a template from the start

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Organic Growth Without Standards**: 15 CLI gems evolved independently
  - Occurrences: Every CLI had unique patterns
  - Impact: Required individual analysis and migration for each
  - Root Cause: No CLI template or base class existed at project inception

- **Flag Semantic Conflicts**: `-v` meant "version" in some CLIs, "verbose" in others
  - Occurrences: Found in ace-taskflow, ace-git, and others
  - Impact: Inconsistent UX, user confusion
  - Root Cause: No upfront decision on flag semantics

#### Medium Impact Issues

- **Duplicate Code**: `exit_on_failure?`, `class_options`, `respond_to_missing?` repeated in each CLI
  - Occurrences: Present in all 15 CLIs before standardization
  - Impact: Maintenance burden, inconsistent implementations

- **Missing Help Documentation**: Only some CLIs had `self.help` overrides
  - Occurrences: 4 CLIs missing custom help sections
  - Impact: Users couldn't discover CLI-specific features

#### Low Impact Issues

- **ace-docs Not Using Base**: One CLI (ace-docs) was still using plain Thor
  - Occurrences: 1
  - Impact: Inconsistent option handling

### Improvement Proposals

#### Process Improvements

- **Create CLI template**: New CLIs should start from `ace-cli-template` generator
- **Convention document**: Document CLI standards in `dev-handbook/guides/cli-conventions.md`
- **Pre-commit check**: Lint rule to verify CLIs inherit from Base

#### Tool Enhancements

- **ace-lint rule**: Check that `class CLI < Ace::Core::CLI::Base` pattern is used
- **Template generator**: `ace-gen cli my-new-cli` should scaffold properly

#### Communication Protocols

- **Architecture Decision Record**: ADR for CLI conventions (flag semantics, help patterns)
- **PR checklist item**: "If adding a CLI, does it follow CLI conventions?"

## Action Items

### Stop Doing

- Creating CLIs by copying and modifying existing ones (copy-paste inheritance)
- Adding `-v` as version shortcut (reserve for verbose)
- Defining `exit_on_failure?` in individual CLIs

### Continue Doing

- Using `Ace::Core::CLI::Base` for all new CLIs
- Adding `self.help` overrides for CLI-specific features
- Comprehensive `long_desc` with examples for each command

### Start Doing

- Create ADR documenting CLI conventions
- Add CLI generator to dev-tools
- Add lint rule enforcing Base class usage
- Document special cases (magic routing, custom start overrides) in comments

## Technical Details

**Pattern established in this work:**
```ruby
require "ace/core/cli/base"

class CLI < Ace::Core::CLI::Base
  # class_options :quiet, :verbose, :debug inherited from Base

  def self.help(shell, subcommand = false)
    super
    shell.say ""
    shell.say "Feature-Specific Section:"
    shell.say "  ..."
  end

  desc "command", "Description"
  long_desc <<~DESC
    Detailed description with EXAMPLES section
  DESC
  def command
    # ...
  end

  map "--version" => :version
  # Note: -v reserved for --verbose, version only via --version
end
```

## Root Cause Analysis: Why So Much Fixing?

The answer to "why do we have to fix so much" boils down to:

1. **No template existed**: Each CLI was created ad-hoc
2. **No conventions documented**: Developers made local decisions
3. **No enforcement mechanism**: Nothing prevented inconsistency
4. **Growth outpaced governance**: 15 CLIs grew faster than standards could be established

**Prevention for future projects:**
- Establish conventions BEFORE the second implementation
- Create templates and generators early
- Add automated enforcement (lint rules, pre-commit hooks)
- Document decisions in ADRs

## Additional Context

- PR #123 initial review identified the pattern
- Subtasks: 150.13 (prerequisites), 150.14 (Base adoption), 150.15 (help documentation)
- Commits: `e00643f0`, `b0b529e8`, `586fbda2`