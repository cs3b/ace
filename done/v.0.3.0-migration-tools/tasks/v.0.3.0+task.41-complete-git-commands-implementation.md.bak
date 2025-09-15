---
id: v.0.3.0+task.41
status: done
priority: medium
estimate: 3h
dependencies: [v.0.3.0+task.19]
---

# Complete Git Commands Implementation (mv, rm, restore)

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-tools/lib/coding_agent_tools/cli/commands/git/ | sed 's/^/    /'
```

_Result excerpt:_

```
    total 64
    drwxr-xr-x  10 user  staff   320 Jan  8 12:00 .
    drwxr-xr-x  15 user  staff   480 Jan  8 12:00 ..
    -rw-r--r--   1 user  staff  1234 Jan  8 12:00 add.rb
    -rw-r--r--   1 user  staff  2156 Jan  8 12:00 commit.rb
    -rw-r--r--   1 user  staff  1089 Jan  8 12:00 diff.rb
    -rw-r--r--   1 user  staff   987 Jan  8 12:00 fetch.rb
    -rw-r--r--   1 user  staff  1456 Jan  8 12:00 log.rb
    -rw-r--r--   1 user  staff  1123 Jan  8 12:00 pull.rb
    -rw-r--r--   1 user  staff  1234 Jan  8 12:00 push.rb
    -rw-r--r--   1 user  staff  1567 Jan  8 12:00 status.rb
    # Missing: mv.rb, rm.rb, restore.rb
```

## Objective

Complete the git module implementation by adding the 3 missing standard git commands (mv, rm, restore) that were identified as incomplete in task v.0.3.0+task.19. This ensures the git CLI suite provides complete coverage of essential git operations across multi-repository environments.

## Scope of Work

- Implement the 3 missing git CLI commands following established patterns
- Add multi-repository support with intelligent path resolution
- Update CLI registration and binstub configuration
- Create comprehensive tests for the new commands
- Ensure consistency with existing git command implementations

### Deliverables

#### Create

- lib/coding_agent_tools/cli/commands/git/mv.rb
- lib/coding_agent_tools/cli/commands/git/rm.rb
- lib/coding_agent_tools/cli/commands/git/restore.rb
- spec/coding_agent_tools/cli/commands/git/mv_spec.rb
- spec/coding_agent_tools/cli/commands/git/rm_spec.rb
- spec/coding_agent_tools/cli/commands/git/restore_spec.rb

#### Modify

- lib/coding_agent_tools/cli.rb (register new commands)
- dev-tools/config/binstub-aliases.yml (add gmv, grm, grestore aliases)

#### Delete

- None

## Phases

1. **Analysis**: Review existing git command patterns and identify reusable components
2. **Implementation**: Create the 3 new git command classes
3. **Integration**: Update CLI registration and binstub configuration
4. **Testing**: Add comprehensive tests for new commands
5. **Validation**: Verify multi-repo functionality and path intelligence

## Implementation Plan

### Planning Steps

* [x] Analyze existing git command implementations for pattern consistency
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Understand common structure and reusable components across git commands
  > Command: find lib/coding_agent_tools/cli/commands/git/ -name "*.rb" | head -3 | xargs grep -l "dry/cli"
* [x] Review git mv/rm/restore command specifications and multi-repo requirements
  > TEST: Command Specification Review
  > Type: Pre-condition Check
  > Assert: Understand git command behavior and required options/arguments
  > Command: git mv --help && git rm --help && git restore --help
* [x] Plan CLI option structures and path resolution requirements for each command
  > TEST: CLI Design Planning
  > Type: Pre-condition Check
  > Assert: Option structures designed consistently with existing commands
  > Command: echo "CLI options planned" # Manual validation

### Execution Steps

- [x] Implement git-mv command with source/destination path resolution and multi-repo support
  > TEST: Git MV Command
  > Type: CLI Test
  > Assert: Moves files within and across repositories with correct path grouping
  > Command: cd dev-tools && bundle exec exe/git-mv old-file.rb new-file.rb --dry-run
- [x] Implement git-rm command with path intelligence and recursive directory support
  > TEST: Git RM Command
  > Type: CLI Test
  > Assert: Removes files with proper path resolution and multi-repo coordination
  > Command: cd dev-tools && bundle exec exe/git-rm test-file.rb --dry-run
- [x] Implement git-restore command with staging and working tree restoration options
  > TEST: Git Restore Command
  > Type: CLI Test
  > Assert: Restores files with proper path grouping and repository context
  > Command: cd dev-tools && bundle exec exe/git-restore --staged test-file.rb --dry-run
- [x] Update CLI module registration to include new git commands
- [x] Add binstub aliases (gmv, grm, grestore) to binstub-aliases.yml configuration
- [x] Create comprehensive test suites for all 3 new commands with multi-repo scenarios
  > TEST: Complete Test Coverage
  > Type: Unit Test
  > Assert: All new commands have full test coverage including multi-repo scenarios
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/git/ -v
- [x] Verify integration with existing git orchestrator and multi-repo coordinator
  > TEST: Integration Verification
  > Type: Integration Test
  > Assert: New commands work seamlessly with existing git infrastructure
  > Command: cd dev-tools && bundle exec exe/git-status && bundle exec exe/git-mv --help

## Acceptance Criteria

**Complete Git Command Suite:**
* [x] All 3 missing commands implemented: git-mv, git-rm, git-restore
* [x] Commands follow exact same patterns as existing git commands (add, commit, status, etc.)
* [x] Each command supports standard git options and arguments

**Multi-Repository Support:**
* [x] All new commands work across submodules automatically with path intelligence
* [x] Path grouping works correctly (e.g., `git-mv dev-handbook/old.md dev-handbook/new.md` uses `git -C dev-handbook mv`)
* [x] Multi-repo coordinator integration functional for all commands

**CLI Integration:**
* [x] Commands registered in main CLI module alongside existing git commands
* [x] Binstub aliases configured: `gmv` → `git-mv`, `grm` → `git-rm`, `grestore` → `git-restore`
* [x] Help system provides clear usage documentation for all commands

**Testing and Quality:**
* [x] Complete test coverage for all 3 new commands
* [x] Multi-repository test scenarios passing
* [x] All existing tests continue to pass (no regressions)
* [x] Code follows StandardRB linting rules

**Integration Verification:**
* [x] New commands integrate seamlessly with git orchestrator
* [x] Path dispatcher handles all command types correctly
* [x] Directory-agnostic operation works from any project depth

## Out of Scope

- ❌ Adding new git functionality beyond standard git mv/rm/restore behavior
- ❌ Modifying existing git command implementations
- ❌ Creating custom git workflows or shortcuts
- ❌ Adding git hooks or advanced git automation
- ❌ Performance optimizations for large repositories

## References

**Dependencies:**
* v.0.3.0+task.19 (main git module implementation - provides foundation)

**Pattern References:**
* lib/coding_agent_tools/cli/commands/git/add.rb (file operation pattern)
* lib/coding_agent_tools/cli/commands/git/status.rb (basic command pattern)
* lib/coding_agent_tools/cli/commands/git/commit.rb (complex option handling)

**Integration Points:**
* lib/coding_agent_tools/organisms/git/git_orchestrator.rb (main orchestration)
* lib/coding_agent_tools/molecules/git/multi_repo_coordinator.rb (multi-repo logic)
* lib/coding_agent_tools/molecules/git/path_dispatcher.rb (path intelligence)

**Testing References:**
* spec/coding_agent_tools/cli/commands/git/ (existing test patterns)
* Current test suite: 1689 examples, 0 failures (maintain this status)