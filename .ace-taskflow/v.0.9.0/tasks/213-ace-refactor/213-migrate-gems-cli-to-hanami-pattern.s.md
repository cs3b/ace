---
id: v.0.9.0+task.213
status: in-progress
priority: low
estimate: 8h
dependencies: []
worktree:
  branch: 213-migrate-ace-gems-cli-to-hanami-pattern
  path: "../ace-task.213"
  created_at: '2026-01-14 17:36:18'
  updated_at: '2026-01-14 17:36:18'
  target_branch: main
---

# Migrate ACE gems CLI to Hanami pattern

## Behavioral Specification

### User Experience

- **Input**: Developer wants consistent CLI organization across all ACE gems
- **Process**: Review each gem's CLI structure, migrate to Hanami pattern where needed
- **Output**: All ACE gems follow unified `cli/commands/` structure

### Expected Behavior

Standardize CLI organization across all ACE gems to follow the Hanami pattern (the authoritative dry-cli source). This ensures:

1. Consistent directory structure: `lib/ace/gem/cli/commands/`
2. Consistent module naming: `Ace::Gem::CLI::Commands::*`
3. Registry in `cli.rb` extending `Dry::CLI::Registry`
4. No wrapper pattern (direct Dry::CLI::Command inheritance)

### Interface Contract

**Target Pattern (Hanami Standard)**:
```
ace-gem/
├── lib/ace/gem/
│   ├── cli.rb                      # module CLI extend Dry::CLI::Registry
│   └── cli/
│       └── commands/               # All commands here
│           ├── process.rb          # CLI::Commands::Process < Dry::CLI::Command
│           └── subcommand/
│               └── action.rb       # CLI::Commands::Subcommand::Action
```

```ruby
# lib/ace/gem/cli.rb
module Ace
  module Gem
    module CLI
      extend Dry::CLI::Registry

      register "process", Commands::Process
      register "subcommand action", Commands::Subcommand::Action
    end
  end
end

# lib/ace/gem/cli/commands/process.rb
module Ace
  module Gem
    module CLI
      module Commands
        class Process < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          # ...
        end
      end
    end
  end
end
```

### Success Criteria

- [ ] **Documentation Updated**: `docs/ace-gems.g.md` reflects Hanami pattern
- [ ] **All CLI gems reviewed**: Each gem checked against target pattern
- [ ] **Migrations completed**: Gems not matching pattern are migrated
- [ ] **Tests pass**: All gem test suites pass after migration
- [ ] **No wrapper pattern**: Eliminate cli/ wrappers that delegate to commands/

### Validation Questions

- [x] **Pattern confirmed**: Hanami pattern selected as standard (from research)
- [ ] **Scope clarity**: Should shared CLI infrastructure (ace-support-core) change?
- [ ] **Breaking changes**: Are there external consumers that depend on current paths?

## Objective

Establish consistent CLI organization across ACE gems based on Hanami (dry-cli maintainers) conventions. This eliminates confusion between `cli/` and `commands/` directories and provides a single authoritative pattern for new gems.

## Scope of Work

### Package Audit

Review and categorize all 16 CLI-enabled packages:

| Package | Current Pattern | Status | Action Required |
|---------|-----------------|--------|-----------------|
| ace-context | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-docs | `cli/` + `commands/` wrapper | 🔴 Migrate | Merge into `cli/commands/` |
| ace-git | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-git-commit | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-git-secrets | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-git-worktree | `cli/` + `commands/` wrapper | 🔴 Migrate | Merge into `cli/commands/` |
| ace-lint | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-llm | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-llm-providers-cli | `cli/` (special) | ✅ Review | Provider implementations - verify |
| ace-prompt | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-review | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-search | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-support-core | `cli/` (shared infra) | ✅ Skip | Shared CLI infrastructure |
| ace-support-models | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-support-nav | `commands/` only | ⚠️ Review | Move to `cli/commands/` |
| ace-support-timestamp | `cli/` + `commands/` | 🔴 Migrate | Merge into `cli/commands/` |
| ace-taskflow | `cli/` + `commands/` hybrid | 🔴 Migrate | Merge into `cli/commands/` |
| ace-test-runner | `commands/` only | ⚠️ Review | Move to `cli/commands/` |

### Legend

- ✅ **Skip/OK**: Already correct or special case
- ⚠️ **Review**: Has commands/, may need restructure to cli/commands/
- 🔴 **Migrate**: Has wrapper pattern, needs consolidation

### Deliverables

#### Documentation
- Update `docs/ace-gems.g.md` CLI Framework section
- Update DO/DON'T lists for new pattern

#### Migrations (4 packages with wrapper pattern)
- ace-docs: Merge `cli/*.rb` + `commands/*.rb` → `cli/commands/*.rb`
- ace-git-worktree: Merge `cli/*.rb` + `commands/*.rb` → `cli/commands/*.rb`
- ace-support-timestamp: Merge `cli/*.rb` + `commands/*.rb` → `cli/commands/*.rb`
- ace-taskflow: Merge `cli/*.rb` + `commands/*.rb` → `cli/commands/*.rb`

#### Restructures (12 packages with commands/ only)
- Move `commands/` → `cli/commands/` for Hanami alignment
- Update module namespacing from `Commands::` to `CLI::Commands::`
- Update `cli.rb` requires

## Out of Scope

- ❌ **Functionality changes**: Only structural reorganization
- ❌ **ace-support-core changes**: Shared CLI infrastructure stays as-is
- ❌ **New features**: This is purely organizational

## References

- [Hanami CLI source](https://github.com/hanami/cli/blob/main/lib/hanami/cli/commands/)
- [dry-cli documentation](https://dry-rb.org/gems/dry-cli/main/)
- [Hanami Mastery Episode 37](https://hanamimastery.com/episodes/37-dry-cli)
- Claude Code plan: `/Users/mc/.claude/plans/ancient-zooming-forest.md`

## Implementation Plan

### Planning Steps

* [x] Research Hanami CLI pattern (authoritative dry-cli source)
* [x] Audit all ACE gems for current CLI structure
* [x] Categorize packages by migration complexity
* [ ] Review ace-support-core shared infrastructure for impact

### Execution Steps

#### Phase 1: Documentation Update
- [ ] **1.1** Update `docs/ace-gems.g.md` CLI Framework section
  - Change directory guidance from `commands/` to `cli/commands/`
  - Update module naming from `Commands::` to `CLI::Commands::`
  - Add Hanami pattern example
- [ ] **1.2** Update DO/DON'T lists in ace-gems.g.md
  > TEST: Documentation Consistency
  > Type: Content Validation
  > Assert: CLI pattern documentation matches Hanami standard
  > Command: grep -A5 "Commands::" docs/ace-gems.g.md

#### Phase 2: Reference Implementation (ace-search)
- [ ] **2.1** Create `lib/ace/search/cli/commands/` directory
- [ ] **2.2** Move `lib/ace/search/commands/search.rb` → `lib/ace/search/cli/commands/search.rb`
- [ ] **2.3** Update module from `Commands::Search` to `CLI::Commands::Search`
- [ ] **2.4** Update `lib/ace/search/cli.rb` requires
- [ ] **2.5** Update test file paths to match new structure
- [ ] **2.6** Run tests: `ace-test ace-search`
  > TEST: Reference Implementation
  > Type: Regression Test
  > Assert: All ace-search tests pass
  > Command: ace-test ace-search

#### Phase 3: Migrate Wrapper Pattern Packages (4 packages)

##### ace-docs
- [ ] **3.1** Merge `lib/ace/docs/cli/*.rb` with `lib/ace/docs/commands/*.rb`
- [ ] **3.2** Create unified `lib/ace/docs/cli/commands/` structure
- [ ] **3.3** Update module namespacing to `CLI::Commands::`
- [ ] **3.4** Delete old `cli/` and `commands/` directories
- [ ] **3.5** Run tests: `ace-test ace-docs`

##### ace-taskflow
- [ ] **3.6** Merge `lib/ace/taskflow/cli/*.rb` with `lib/ace/taskflow/commands/*.rb`
- [ ] **3.7** Preserve nested command structure (task/, idea/, etc.)
- [ ] **3.8** Update module namespacing
- [ ] **3.9** Run tests: `ace-test ace-taskflow`

##### ace-git-worktree
- [ ] **3.10** Merge wrapper and command classes
- [ ] **3.11** Update structure and namespacing
- [ ] **3.12** Run tests: `ace-test ace-git-worktree`

##### ace-support-timestamp
- [ ] **3.13** Merge wrapper and command classes
- [ ] **3.14** Update structure and namespacing
- [ ] **3.15** Run tests: `ace-test ace-support-timestamp`

#### Phase 4: Migrate Direct Pattern Packages (12 packages)
- [ ] **4.1** For each package: Move `commands/` → `cli/commands/`
- [ ] **4.2** Update module namespacing from `Commands::` to `CLI::Commands::`
- [ ] **4.3** Update `cli.rb` requires
- [ ] **4.4** Run package tests after each migration

Packages to migrate:
- ace-context
- ace-git
- ace-git-commit
- ace-git-secrets
- ace-lint
- ace-llm
- ace-prompt
- ace-review
- ace-support-models
- ace-support-nav
- ace-test-runner

#### Phase 5: Verification
- [ ] **5.1** Run full test suite: `ace-test-suite`
- [ ] **5.2** Verify all CLI commands work: `ace-* --help` for each
- [ ] **5.3** Update any remaining documentation references

## Acceptance Criteria

- [ ] **Documentation**: `docs/ace-gems.g.md` shows Hanami pattern (`cli/commands/`)
- [ ] **Structure**: All gems have `cli/commands/` directory (not `commands/` at gem level)
- [ ] **Namespacing**: All commands use `CLI::Commands::*` module
- [ ] **No wrappers**: Eliminated `cli/` + `commands/` wrapper pattern
- [ ] **Tests pass**: `ace-test-suite` passes
- [ ] **Special cases**: ace-support-core, ace-llm-providers-cli unchanged (shared infra)