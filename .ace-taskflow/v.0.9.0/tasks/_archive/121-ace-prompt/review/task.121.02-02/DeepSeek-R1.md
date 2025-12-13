<think>
We are given a set of code changes to review. The changes span multiple files and include:

1. New idea files for architectural improvements and enhancements to `ace-review`.
2. A retrospective document on a subtask workflow.
3. Updates to task statuses in `.ace-taskflow` task files.
4. New tasks for addressing review feedback.
5. Review reports from multiple AI models for different tasks.
6. Changes to `ace-git-worktree` and `ace-prompt` gems, including new files and modifications.

Given the scope of the changes, we will focus on the critical aspects and ensure they align with the project's standards and architecture.

## Review Approach

We will:
- Check for adherence to ATOM architecture and project patterns.
- Verify that changes are consistent with existing code and documentation.
- Look for potential issues in code quality, security, and performance.
- Ensure that tests are updated or added as needed.
- Validate that documentation is updated appropriately.

## Critical Issues (Blocking)

### 1. CLI Exit Pattern Violation in `ace-prompt`

**File**: `ace-prompt/lib/ace/prompt/cli.rb`

The CLI for `ace-prompt` uses `exit 1` in several places, which violates the ACE testing pattern (as documented in `docs/testing-patterns.md`). This pattern requires that commands return status codes (0/1) and that the `exe/` script handles exiting. This violation prevents tests from running to completion and reporting correctly.

**Solution**:
- Change `exit_on_failure?` to return `false`.
- Replace `exit 1` with `return 1` in the `process` method.
- Ensure the `exe/ace-prompt` script captures the return value and exits appropriately.

### 2. Missing CLI Integration Tests for `ace-prompt`

**File**: `ace-prompt/test/`

The `ace-prompt` gem lacks end-to-end tests for the CLI commands, especially the `process` command. Without these tests, we cannot verify the correct behavior of the CLI in real-world scenarios.

**Solution**:
- Add `test/integration/cli_integration_test.rb` to test:
  - Successful processing and output to stdout.
  - File output with `--output`.
  - Error handling (e.g., missing prompt file).

## High Priority Issues

### 3. README Path Violation (ADR-004)

**File**: `ace-prompt/README.md:36`

The README contains a path with `../` which violates ADR-004 (all paths must be relative to the project root). This reduces portability and may break when the gem is used outside the mono-repo.

**Solution**:
- Remove the external path reference or replace it with a gem-local documentation reference.

### 4. Unused Parameter in `PromptArchiver`

**File**: `ace-prompt/lib/ace/prompt/molecules/prompt_archiver.rb:69`

The `update_symlink` method takes a `base_dir` parameter but does not use it. This dead code should be removed to maintain clarity.

**Solution**:
- Remove the unused `base_dir` parameter from the method signature and update call sites.

## Medium Priority Issues

### 5. Simplify File Output Logic

**File**: `ace-prompt/lib/ace/prompt/cli.rb:60-61`

The file output logic can be simplified by removing redundant checks. The `FileUtils.mkdir_p` method can handle existing directories and relative paths.

**Solution**:
- Replace:
  ```ruby
  output_dir = File.dirname(output_mode)
  FileUtils.mkdir_p(output_dir) unless output_dir == "." || File.directory?(output_dir)
  ```
  with:
  ```ruby
  FileUtils.mkdir_p(File.dirname(output_mode))
  ```

### 6. Default Push Behavior in `ace-git-worktree`

**File**: `ace-git-worktree/lib/ace/git/worktree/models/worktree_config.rb:39`

The `auto_push_task` configuration option defaults to `true`, which means worktree creation will automatically push to a remote. This could surprise users and should be an opt-in feature.

**Solution**:
- Change the default to `false` and document how to enable it.

## Code Quality and Best Practices

### 7. Test Coverage

The `ace-prompt` gem has good unit test coverage but lacks integration tests for the CLI. The `ace-git-worktree` changes include comprehensive tests.

### 8. Documentation

- The `ace-prompt` README needs to be fixed (see above).
- The `ace-git-worktree` changes are well-documented in the CHANGELOG.

## Detailed File-by-File Feedback

### `.ace-taskflow/v.0.9.0/ideas/20251128-110638-integration-feat/standardize-modules-for-external-dependencies.s.md`

- **Content**: Good idea to centralize external interactions. Aligns with project's modular design.
- **Recommendation**: Proceed to implementation as per the plan.

### `.ace-taskflow/v.0.9.0/ideas/20251128-124510-review-enhance/add-unified-subject-definition-and-composable-presets.s.md`

- **Content**: Excellent enhancement for `ace-review`. The unified subject and presets will improve usability.
- **Recommendation**: Implement as described.

### `.ace-taskflow/v.0.9.0/retros/2025-11-28-subtask-12101-workflow-learnings.md`

- **Content**: Valuable insights into the workflow process. The proposed improvements (commit step in subagent, automated review task creation) are sound.
- **Recommendation**: Implement the action items.

### `ace-git-worktree` Changes

The changes to `ace-git-worktree` (introducing `TaskIDExtractor` and fixing subtask handling) are well-implemented and tested. The code follows ATOM architecture and the tests are comprehensive.

### `ace-prompt` Gem

The `ace-prompt` gem is a good addition. However, the CLI issues and lack of integration tests need to be addressed.

## Conclusion

The changes are generally of high quality and align with the project's architecture. The critical issues in `ace-prompt` must be fixed before merging. Other issues should be addressed to maintain code quality and consistency.

## Prioritised Action Items

1. **Critical**: Fix CLI exit pattern in `ace-prompt` (return status codes, update `exe/`).
2. **Critical**: Add CLI integration tests for `ace-prompt`.
3. **High**: Fix README path violation in `ace-prompt`.
4. **High**: Remove unused parameter in `PromptArchiver`.
5. **High**: Change default push behavior in `ace-git-worktree` to `false`.
6. **Medium**: Simplify file output logic in `ace-prompt` CLI.
</think>
Here's a structured review of the code changes with a focus on critical issues, architecture, and best practices:

### 🛑 Critical Issues (Blocking)

#### 1. CLI Exit Pattern Violation in `ace-prompt`
- **File**: `ace-prompt/lib/ace/prompt/cli.rb`
- **Issue**: Direct calls to `exit` prevent test completion
- **Solution**:
  ```ruby
  # Before
  exit 1 if error

  # After
  return 1 if error
  return 0 # on success
  ```
- **Fix**: Update `exe/ace-prompt` to handle exit codes:
  ```ruby
  exit_code = Ace::Prompt::CLI.start(ARGV)
  exit(exit_code || 0)
  ```
- **Impact**: Required to prevent test runner termination

#### 2. Missing CLI Integration Tests
- **File**: `ace-prompt/test/`
- **Issue**: No end-to-end CLI tests
- **Solution**: Add `test/integration/cli_integration_test.rb` covering:
  - Success/failure exit codes
  - File output behavior
  - Archive creation
  - Symlink updates

### ⚠️ High Priority Issues

#### 3. README Path Violation (ADR-004)
- **File**: `ace-prompt/README.md:36`
- **Issue**: Uses `../` paths violating ADR-004
- **Solution**: Remove external path reference
- **Recommended Fix**:
  ```diff
  - See: ../../.ace-taskflow/...
  + See gem's handbook/ directory
  ```

#### 4. Unused Parameter
- **File**: `ace-prompt/lib/ace/prompt/molecules/prompt_archiver.rb`
- **Issue**: `base_dir` parameter unused
- **Solution**:
  ```ruby
  def self.update_symlink(symlink_path, target_path) # Remove base_dir
  ```

### ✅ Strengths

- **Excellent ATOM adherence**: Clear separation of atoms/molecules/organisms
- **Robust testing**: 135 tests for `TaskIDExtractor` with edge cases
- **Security**: Proper input validation and path handling
- **Documentation**: Detailed CHANGELOG entries and task documentation

### 🔍 Detailed File-by-File Feedback

#### `ace-git-worktree/atoms/task_id_extractor.rb`
- ✅ Centralized ID handling with regex fallback
- 💡 **Improvement**: Anchor regex for bare IDs:
  ```ruby
  /\A(\d{3})\z/ # Instead of /\b(\d{3})\b/
  ```

#### `ace-prompt