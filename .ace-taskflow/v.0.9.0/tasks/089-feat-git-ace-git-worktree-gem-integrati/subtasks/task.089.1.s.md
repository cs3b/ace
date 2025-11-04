---
id: v.0.9.0+task.089.1
status: pending
priority: high
estimate: 8 hours
dependencies:
- v.0.9.0+task.089
parent: v.0.9.0+task.089
---

# Implement feedback and improvements for ace-git-worktree

> **Note**: This is a subtask of task.089 (Create ace-git-worktree gem) to implement feedback from PR reviews and ensure the gem meets ACE ecosystem standards.

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents using ace-git-worktree to manage task-based worktrees
- **Process**: Create, list, switch, remove worktrees with robust error handling and validation
- **Output**: Reliable worktree management with clear error messages and consistent behavior

### Expected Behavior
The system should provide a production-ready git worktree management tool that:
- Validates all user inputs before executing operations
- Provides clear, actionable error messages when operations fail
- Follows ACE ecosystem standards for configuration and testing
- Caches task metadata to improve performance
- Supports dry-run mode consistently across all commands
- Handles edge cases gracefully (long task titles, special characters, multiple worktrees)

### Interface Contract
```bash
# All commands should support dry-run
ace-git-worktree create --task 081 --dry-run
ace-git-worktree remove 081 --dry-run

# Clear error messages
ace-git-worktree create --task 999
# Error: Task 999 not found. Run 'ace-taskflow tasks' to see available tasks.

# Performance (with caching)
ace-git-worktree create --task 081  # First call: fetches metadata
ace-git-worktree list --show-tasks  # Uses cached metadata (< 100ms)
```

### Success Criteria
- [ ] All user inputs validated with clear error messages
- [ ] Test coverage ≥90% for atoms/molecules, ≥80% for organisms/commands
- [ ] Gemspec metadata matches ACE ecosystem standards
- [ ] Rakefile follows modern ace-* gem patterns
- [ ] Dry-run mode works consistently across all commands
- [ ] Task metadata caching improves performance
- [ ] Security vulnerabilities addressed (path traversal, command injection)
- [ ] All task.089 checkboxes marked as completed

## Objective

Implement all feedback from PR #13 review and PR #14 comments to ensure ace-git-worktree is production-ready and follows ACE ecosystem standards. This ensures the gem is robust, performant, and maintainable.

## Scope of Work

### Phase 1: Quick Fixes (30 minutes)
- Update task.089.s.md checkboxes to reflect completed work
- Fix Gemfile to use eval_gemfile pattern
- Update gemspec metadata (authors, email, homepage)
- Modernize Rakefile to match other ace-* gems
- Remove Gemfile.lock from ace-git-worktree/

### Phase 2: Core Improvements (2 hours)
- Add input validation across all user inputs
- Implement configuration validation in WorktreeConfig
- Add rollback mechanism for failed operations
- Ensure dry-run support is consistent

### Phase 3: Test Coverage (3-4 hours)
- Add integration tests for all CLI commands
- Add security tests (path traversal, command injection)
- Add edge case tests (long slugs, special characters)
- Add error condition tests

### Phase 4: Performance & Features (2 hours)
- Implement metadata caching with TTL
- Add progress indicators for long operations
- Optimize git command batching

### Phase 5: Documentation (1 hour)
- Update README with non-task worktree usage
- Document all changes in CHANGELOG
- Add inline documentation for complex methods

## Technical Approach

### Architecture Pattern
- Maintain ATOM architecture separation
- Use dependency injection for testability
- Implement caching as a decorator pattern

### Technology Stack
- Ruby 3.0+ (existing)
- Minitest for testing
- SimpleCov for coverage reporting
- Memory cache for metadata (no external dependencies)

### Implementation Strategy

**Caching Implementation:**
- Use in-memory hash with TTL timestamps
- Cache key: "task:#{task_id}"
- TTL: 5 minutes (configurable)
- Clear cache on task update operations

**Validation Strategy:**
- Create Validator modules for each input type
- Centralize error messages in Constants
- Use early returns for validation failures

**Testing Strategy:**
- Use test doubles for external dependencies
- Create test fixtures for git repositories
- Mock ace-taskflow responses consistently

## File Modifications

### Create
- `lib/ace/git/worktree/validators/` - Input validation modules
- `lib/ace/git/worktree/cache/` - Metadata caching
- `test/integration/` - Integration test files
- `test/security/` - Security test files
- `test/fixtures/` - Test fixtures

### Modify
- `.ace-taskflow/v.0.9.0/tasks/089-*/task.089.s.md` - Update checkboxes
- `ace-git-worktree/Gemfile` - Fix eval_gemfile pattern
- `ace-git-worktree/ace-git-worktree.gemspec` - Update metadata
- `ace-git-worktree/Rakefile` - Modernize structure
- All atom/molecule/organism files - Add validation
- All command files - Ensure dry-run support

### Delete
- `ace-git-worktree/Gemfile.lock` - Should be gitignored

## Test Case Planning

### Happy Path Scenarios
- Create task worktree with valid ID
- List worktrees with task associations
- Switch to existing worktree
- Remove worktree without changes
- Dry-run shows operations without executing

### Edge Case Scenarios
- Task title > 100 characters (slug truncation)
- Special characters in task title (/, \, :, @)
- Multiple worktrees for same task (counter suffix)
- Empty task title (fallback to ID)
- Cached metadata expiry during operation

### Error Condition Scenarios
- Task not found (clear error message)
- ace-taskflow not installed (helpful error)
- Git repository not found (validation)
- Worktree already exists (suggest removal)
- Permission denied on worktree path

### Security Test Scenarios
- Path traversal attempts (../../etc)
- Command injection in task titles
- Symlink attack prevention
- Input sanitization validation

## Risk Assessment

### Technical Risks
- **Caching complexity**: Keep simple with in-memory hash
- **Test coverage target**: Focus on critical paths first
- **Breaking changes**: Ensure backward compatibility

### Mitigation Strategies
- Incremental implementation with tests
- Feature flags for new behaviors
- Comprehensive error handling

## Implementation Plan

### Planning Steps
* [ ] Review all feedback from PR #13 and PR #14 comments
* [ ] Analyze test coverage gaps in current implementation
* [ ] Research caching patterns in Ruby without external dependencies
* [ ] Study validation patterns from other ace-* gems

### Execution Steps

#### Phase 1: Quick Fixes
- [ ] Update task.089.s.md checkboxes
  > TEST: Checkbox Update Validation
  > Type: File Content
  > Assert: All completed items have checked checkboxes
  > Command: grep "class=\"task-list-item-checkbox\" disabled=\"disabled\" checked=\"checked\"" task.089.s.md | wc -l

- [ ] Fix ace-git-worktree/Gemfile structure
  ```ruby
  # frozen_string_literal: true
  source "https://rubygems.org"
  gemspec
  eval_gemfile(File.expand_path("../Gemfile", __dir__))
  ```

- [ ] Update gemspec metadata
  - Authors: ["Miguel Czyz"]
  - Email: ["mc@cs3b.com"]
  - Homepage: "https://github.com/cs3b/ace-meta"

- [ ] Modernize Rakefile
  ```ruby
  require "bundler/gem_tasks"
  require "minitest/test_task"

  desc "Run tests using ace-test"
  task :test do
    sh "ace-test"
  end

  desc "Run tests directly (CI mode)"
  Minitest::TestTask.create(:ci)

  task default: :test
  ```

- [ ] Remove ace-git-worktree/Gemfile.lock
- [ ] Add Gemfile.lock to ace-git-worktree/.gitignore

#### Phase 2: Core Improvements
- [ ] Create input validators
  - PathValidator (path traversal protection)
  - SlugValidator (special character handling)
  - TaskIdValidator (format validation)

- [ ] Add configuration validation
  ```ruby
  def validate!
    raise ConfigError, "Invalid root_path" unless valid_path?(@root_path)
    raise ConfigError, "Invalid template" unless valid_template?(@directory_format)
  end
  ```

- [ ] Implement rollback mechanism
  - Track operations in transaction log
  - Rollback on failure
  - Clean up partial state

- [ ] Ensure dry-run consistency
  - Add @dry_run instance variable to all commands
  - Skip destructive operations when true
  - Show what would be done

#### Phase 3: Test Coverage
- [ ] Add integration tests for each command
  > TEST: Integration Test Coverage
  > Type: Test Execution
  > Assert: All 6 commands have integration tests
  > Command: ls test/integration/*_command_test.rb | wc -l

- [ ] Add security tests
  - Path traversal prevention
  - Command injection protection
  - Symlink attack prevention

- [ ] Add edge case tests
  - Long task titles
  - Special characters
  - Multiple worktrees

- [ ] Add error condition tests
  - Task not found
  - Git errors
  - Permission errors

#### Phase 4: Performance & Features
- [ ] Implement metadata caching
  ```ruby
  class MetadataCache
    def initialize(ttl: 300)
      @cache = {}
      @ttl = ttl
    end

    def get(key)
      entry = @cache[key]
      return nil unless entry
      return nil if Time.now - entry[:time] > @ttl
      entry[:value]
    end

    def set(key, value)
      @cache[key] = { value: value, time: Time.now }
    end
  end
  ```

- [ ] Add progress indicators
  - Show "Fetching task metadata..."
  - Show "Creating worktree..."
  - Show "Running mise trust..."

- [ ] Optimize git operations
  - Batch git commands where possible
  - Use git plumbing commands for performance

#### Phase 5: Documentation
- [ ] Update README
  - Add section on non-task worktrees
  - Document caching behavior
  - Add troubleshooting section

- [ ] Update CHANGELOG
  - Document all improvements
  - Note breaking changes (if any)
  - Credit PR reviewers

- [ ] Add inline documentation
  - Document complex methods
  - Add usage examples
  - Document error conditions

### Verification
- [ ] Run full test suite: `ace-test`
  > TEST: Full Test Suite
  > Type: Test Execution
  > Assert: All tests pass with >90% coverage
  > Command: cd ace-git-worktree && rake test

- [ ] Verify gemspec: `ruby ace-git-worktree.gemspec`
- [ ] Test all CLI commands manually
- [ ] Run security tests
- [ ] Check performance improvements

## Acceptance Criteria

### Functionality
- [x] Task.089 checkboxes updated to reflect completion
- [ ] Gemspec metadata matches ACE standards
- [ ] Rakefile modernized to match other gems
- [ ] All commands support --dry-run consistently
- [ ] Input validation prevents invalid operations
- [ ] Rollback mechanism handles failures gracefully

### Quality
- [ ] Test coverage ≥90% for atoms/molecules
- [ ] Test coverage ≥80% for organisms/commands
- [ ] No security vulnerabilities (path traversal, injection)
- [ ] All edge cases handled gracefully
- [ ] Clear, actionable error messages

### Performance
- [ ] Task metadata cached with 5-minute TTL
- [ ] List command completes in <2s with 50 worktrees
- [ ] Create command shows progress indicators

### Documentation
- [ ] README updated with complete usage examples
- [ ] CHANGELOG documents all changes
- [ ] Inline documentation for complex code

## References

- Parent task: v.0.9.0+task.089 (Create ace-git-worktree gem)
- PR #13: feat: Implement ace-git-worktree gem with task integration
- PR #14: feat(ace-git-worktree): Complete implementation with fixes
- ace-* gem patterns: ace-taskflow, ace-search, ace-lint