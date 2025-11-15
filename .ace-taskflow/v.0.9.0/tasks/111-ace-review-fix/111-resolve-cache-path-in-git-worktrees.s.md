---
id: v.0.9.0+task.111
status: pending
priority: medium
estimate: 2-3 days
dependencies: []
---

# Fix ace-review cache path resolution in git worktrees

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-review --preset pr` from within a git worktree created by `ace-git-worktree`
- **Process**: Tool resolves project root correctly, creates cache in predictable location, executes review workflow
- **Output**: Review session cache created at `.cache/ace-review/sessions/` relative to the correct project root (either worktree root or main repo root)

### Expected Behavior
When a developer works in a git worktree and runs ace-review:
1. The tool correctly identifies the project context (worktree or main repo)
2. Cache directories are created in a predictable, consistent location
3. Review sessions function identically whether run from main repo or worktree
4. The cache path follows the standard ACE pattern: `.cache/ace-review/sessions/`
5. Review results and session data are accessible in subsequent runs

Currently, the tool creates caches in deeply nested, incorrect paths like:
`/Users/mc/Ps/ace-meta/.ace-wt/task.094/ace-context/.cache/ace-review/sessions/`

The expected path should be either:
- `.cache/ace-review/sessions/` relative to worktree root, OR
- `.cache/ace-review/sessions/` relative to main repo root (configurable)

### Interface Contract
```bash
# CLI Interface - should work consistently in any context
ace-review --preset pr --model codex --subject "commands: ['ghrc pr 18 diff']"

# Expected output format (from worktree):
✓ Review session prepared: <project-root>/.cache/ace-review/sessions/review-YYYYMMDD-HHMMSS
  Prompt: ...

# Expected output format (from main repo):
✓ Review session prepared: .cache/ace-review/sessions/review-YYYYMMDD-HHMMSS
  Prompt: ...
```

**Error Handling:**
- Invalid worktree detection: Fall back to standard git repository detection
- Missing .ace configuration: Use sensible defaults for cache location
- Permission issues: Clear error message with suggested fix

**Edge Cases:**
- Nested worktrees: Resolve to the immediate worktree root
- Symlinked directories: Follow symlinks to actual project root
- Detached HEAD state: Continue to function with standard cache resolution

### Success Criteria
- [ ] **Consistent Path Resolution**: ace-review creates cache in predictable location regardless of execution context
- [ ] **Worktree Compatibility**: Tool functions correctly when run from within ace-git-worktree created worktrees
- [ ] **Configuration Respect**: Cache path respects .ace/ configuration cascade with sensible defaults
- [ ] **No Breaking Changes**: Existing ace-review functionality remains unchanged for main repo usage
- [ ] **Test Coverage**: Integration tests verify correct behavior in worktree context

### Validation Questions
- [ ] **Cache Location Strategy**: Should worktrees use their own cache or share with main repo?
- [ ] **Configuration Override**: Should users be able to configure different cache strategies per worktree?
- [ ] **Migration Path**: How to handle existing incorrect cache locations from previous runs?
- [ ] **Other Affected Tools**: Do other ace-* tools have similar worktree path resolution issues?

## Objective

Enable developers to use ace-review reliably within git worktrees, maintaining the seamless development workflow provided by ace-git-worktree. This fix ensures predictable tool behavior across different git contexts, crucial for both human developers and AI agents.

## Scope of Work

- **User Experience Scope**: All ace-review commands and presets when executed from worktrees
- **System Behavior Scope**: Path resolution logic for cache directories in worktree contexts
- **Interface Scope**: Maintaining existing CLI interface while fixing underlying behavior

### Deliverables

#### Behavioral Specifications
- Clear definition of expected cache path resolution behavior
- Documentation of worktree vs main repo cache strategies
- User-facing error messages for edge cases

#### Validation Artifacts
- Integration test scenarios for worktree execution
- Validation of cache creation in correct locations
- Verification of review session continuity

## Out of Scope
- ❌ **Implementation Details**: Specific code changes to ace-support-core or ace-context
- ❌ **Technology Decisions**: Which path resolution library or method to use
- ❌ **Performance Optimization**: Cache access speed improvements
- ❌ **Future Enhancements**: General worktree support improvements beyond cache paths

## References

- Source idea: .ace-taskflow/v.0.9.0/ideas/20251106-152442-ace-review-fix/resolve-cache-path-in-git-worktrees.s.md
- Related bug report showing incorrect cache path in worktree
- ace-git-worktree documentation for worktree creation patterns
- ace-support-core configuration cascade documentation

## Technical Research

### Root Cause Analysis
The issue appears to stem from how ace-review (via ace-context or ace-support-core) determines the project root when running in a git worktree. The deeply nested path suggests the tool is incorrectly traversing or combining paths, possibly confusing the worktree's .git file with the main repository's .git directory.

### Architecture Investigation
- **ace-review**: Uses `Ace::Core.config` for cache path configuration
- **ace-context**: Provides `project_root` detection via `Ace::Context::Molecules::ProjectRootFinder`
- **ace-support-core**: Handles configuration cascade and path resolution
- **Git worktree structure**: Contains `.git` file (not directory) pointing to main repo

### Key Components to Examine
1. `ace-context/lib/ace/context/molecules/project_root_finder.rb` - Root detection logic
2. `ace-review/lib/ace/review/molecules/session_manager.rb` - Cache path construction
3. `ace-support-core/lib/ace/core/molecules/config_resolver.rb` - Config path resolution

## Implementation Plan

### Planning Steps

* [ ] **Debug Current Behavior**
  - Set up test worktree using `ace-git-worktree create --task test`
  - Run ace-review with verbose/debug output to trace path resolution
  - Document exact call chain leading to incorrect path

* [ ] **Analyze Path Resolution Logic**
  - Review `ProjectRootFinder` implementation for worktree awareness
  - Check if `.git` file vs directory detection is handled correctly
  - Verify `ace-support-core` config cascade behavior in worktrees

* [ ] **Research Git Worktree Detection**
  - Study how git identifies worktree vs main repository
  - Review Ruby's `git` gem or command-line git for worktree detection
  - Identify reliable method to detect worktree context

* [ ] **Design Solution Approach**
  - Determine if fix belongs in ace-context, ace-support-core, or ace-review
  - Define clear rules for cache location in worktrees
  - Plan configuration options for cache strategy

### Execution Steps

- [ ] **Fix Root Detection in ace-context**
  - Modify `ProjectRootFinder#find` to handle `.git` file (worktree marker)
  - When `.git` is a file, read it to find actual git directory
  - Ensure correct project root is returned for worktrees
  > TEST: Worktree Root Detection
  > Type: Unit Test
  > Assert: ProjectRootFinder returns worktree root when run from worktree
  > Command: cd ace-context && ace-test molecules/project_root_finder_test.rb

- [ ] **Update Cache Path Resolution in ace-review**
  - Modify `SessionManager` to use corrected project root
  - Ensure cache path uses `.cache/ace-review/sessions/` pattern
  - Add fallback for legacy incorrect paths if needed
  > TEST: Cache Path in Worktree
  > Type: Integration Test
  > Assert: Review session cache created at correct location
  > Command: cd ace-review && ace-test integration/worktree_cache_test.rb

- [ ] **Add Worktree Detection Helper**
  - Create `Ace::Core::Atoms::WorktreeDetector` if needed
  - Implement `in_worktree?` and `worktree_root` methods
  - Use protected method pattern for ENV/git command access
  > TEST: Worktree Detection
  > Type: Unit Test
  > Assert: Correctly identifies worktree vs main repo
  > Command: cd ace-support-core && ace-test atoms/worktree_detector_test.rb

- [ ] **Implement Configuration Options**
  - Add `cache_strategy` option to ace-review config
  - Support "worktree-local" vs "shared" cache modes
  - Document configuration in .ace.example/review/config.yml
  > TEST: Config Override
  > Type: Unit Test
  > Assert: Cache strategy configuration is respected
  > Command: cd ace-review && ace-test molecules/config_test.rb

- [ ] **Create Integration Tests**
  - Write test that creates actual worktree (or mocks it)
  - Run ace-review and verify cache location
  - Test both main repo and worktree contexts
  - Use protected method pattern to avoid subprocess spawning
  > TEST: Full Integration
  > Type: End-to-End Test
  > Assert: ace-review works correctly in both contexts
  > Command: bundle exec rake test:integration

- [ ] **Update Documentation**
  - Document worktree support in ace-review README
  - Add cache strategy options to usage.md
  - Update ace-git-worktree docs to mention ace-review compatibility

- [ ] **Handle Edge Cases**
  - Test nested worktrees (worktree within worktree)
  - Verify behavior with symlinked directories
  - Test detached HEAD state in worktree
  > TEST: Edge Cases
  > Type: Integration Test
  > Assert: Handles nested worktrees and symlinks correctly
  > Command: cd ace-review && ace-test integration/edge_cases_test.rb

- [ ] **Migration for Existing Caches**
  - Check for caches in old incorrect locations
  - Provide migration command or automatic migration
  - Clean up orphaned cache directories
  > TEST: Cache Migration
  > Type: Integration Test
  > Assert: Old caches are discovered and handled
  > Command: cd ace-review && ace-test integration/migration_test.rb

## Test Planning

### Unit Tests
- `ProjectRootFinder` correctly identifies worktree root
- `WorktreeDetector` (if created) accurately detects worktree context
- Cache path configuration respects settings
- Path resolution handles `.git` file vs directory

### Integration Tests
- ace-review creates cache in correct location from worktree
- Cache persists and is accessible across sessions
- Configuration overrides work as expected
- Migration handles legacy cache locations

### Edge Cases
- Nested worktrees resolve to immediate worktree root
- Symlinked directories are handled correctly
- Detached HEAD doesn't break functionality
- Missing .git doesn't cause crashes

## Risk Analysis

### Technical Risks
- **Breaking existing functionality**: Changes to core path resolution could affect other tools
- **Cache fragmentation**: Different cache strategies might confuse users
- **Performance impact**: Additional git operations for worktree detection

### Mitigation Strategies
- Comprehensive test coverage before changes
- Feature flag for new behavior initially
- Clear migration path for existing users
- Performance profiling of path resolution

## Rollback Plan
1. Revert changes to ace-context and ace-review
2. Document known issue with worktrees
3. Provide manual workaround (environment variable override)
4. Plan incremental fix approach
