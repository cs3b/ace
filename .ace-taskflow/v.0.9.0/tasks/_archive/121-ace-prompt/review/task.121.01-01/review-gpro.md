An excellent set of changes that introduces a new, well-structured gem and delivers a critical bug fix and refactoring for an existing one. The adherence to project patterns is strong, and the new `TaskIDExtractor` is a fantastic example of creating a single source of truth to fix a recurring problem.

### Architectural Analysis
- ✅ **ATOM Pattern Adherence**: Both the new `ace-prompt` gem and the refactored `ace-git-worktree` gem demonstrate strong adherence to the ATOM architecture.
  - The new `TaskIDExtractor` in `ace-git-worktree` is correctly placed as a pure-function `atom`.
  - The new `TaskPusher` is a `molecule` with a clear, single responsibility.
  - The change in `TaskFetcher` to use the `TaskManager` organism instead of the `TaskLoader` molecule is a significant architectural improvement, respecting the established layering by having one gem's molecule interact with another gem's high-level organism API.
- ✅ **Centralized Logic**: The creation of `TaskIDExtractor` is a major win. It replaces duplicated, inconsistent regex patterns across at least 6 files with a single, robust, and well-tested implementation. This significantly reduces technical debt and prevents future bugs related to subtask ID handling.
- ✅ **Modularity and Reusability**: The new `ace-prompt` gem is a great example of a focused, reusable capability, fitting perfectly into the project's "everything is a gem" philosophy. It correctly leverages `ace-support-core` for common utilities like `ProjectRootFinder`.

### Security Review
*No issues found*. The changes primarily involve file system operations within controlled project directories and git command execution. The use of `Open3.capture3` with an array of command arguments prevents command injection vulnerabilities. Input validation on task references is present, though it could be slightly more robust.

### Detailed File-by-File Feedback

#### `ace-git-worktree/`

##### 🎯 `lib/ace/git/worktree/atoms/task_id_extractor.rb` (New File)
- ✅ **Excellent Abstraction**: This new atom is the highlight of the refactoring. It correctly centralizes task ID parsing logic, supports subtasks, and includes a robust fallback mechanism for when `ace-taskflow` is not available.
- 💡 **Suggestion**: The fallback regex patterns are good, but could be slightly more anchored to improve specificity and avoid accidental matches in unusual strings.
  - **L86-90**: `elsif match = ref.match(/(?:^|task\.)(\d{3})(?:\b|$)/)` is good.
  - **L91-93**: `elsif match = ref.match(/\b(\d{3})\b/)` could potentially match a 3-digit number in the middle of an unrelated string. While unlikely for this tool's input, anchoring it would be safer.
  ```ruby
  # Suggested change for L91
  elsif match = ref.match(/\A(\d{3})\z/) # Match only if the string IS a 3-digit number
  ```

##### 🎯 `lib/ace/git/worktree/molecules/task_fetcher.rb`
- ✅ **Architectural Improvement**: Switching from `TaskLoader` (molecule) to `TaskManager` (organism) is the correct approach for inter-gem communication. It respects architectural boundaries and simplifies this molecule by delegating path resolution to `ace-taskflow`.
- 📝 **Note**: The removal of `root_path` dependency in the initializer is a direct and positive consequence of this change, making the component cleaner.

##### 🎯 `lib/ace/git/worktree/organisms/task_worktree_orchestrator.rb`
- ✅ **Logical Flow**: The updated workflow to add metadata *before* committing is a solid logic fix. The addition of the "push" step is also well-integrated.
- 💡 **Suggestion**: The `normalize_task_id_for_matching` method is now just a wrapper around the new atom. Consider using the atom directly or aliasing it to improve clarity and reduce indirection.
  - **L353-355**:
  ```ruby
  # Current
  def normalize_task_id_for_matching(task_ref)
    Atoms::TaskIDExtractor.normalize(task_ref) || task_ref
  end

  # Suggestion: Use the atom directly in calling methods for clarity, e.g., in `get_task_status_for_worktrees`
  # L275:
  task_ids = Array(task_refs).map { |ref| Atoms::TaskIDExtractor.normalize(ref) }.compact
  ```

##### 🎯 `lib/ace/git/worktree.rb`
- ✅ **Bug Fix**: The added `require_relative "worktree/molecules/task_pusher"` fixes the uninitialized constant error reported in the changelog. The placement is correct.

##### 🎯 `test/atoms/task_id_extractor_test.rb` & `test/integration/subtask_workflow_test.rb` (New Files)
- ✅ **Thorough Testing**: The tests for the new atom are comprehensive, covering simple tasks, subtasks, various ID formats, and edge cases. The new integration test file is excellent, verifying that the subtask ID is handled consistently across different components, which is critical for ensuring the fix is complete.

---

#### `ace-prompt/` (New Gem)

##### 🎯 `ace-prompt.gemspec`
- ✅ **Good Structure**: The gemspec is well-formed, follows project conventions, and correctly declares dependencies on `ace-support-core` and `thor`.

##### 🎯 `lib/ace/prompt/molecules/prompt_archiver.rb`
- ✅ **Robust Logic**: The file and symlink handling logic is solid. It correctly creates the archive directory, handles timestamp collisions, and updates the `_previous.md` symlink.
- 📝 **Note**: The relative path calculation for the symlink (`relative_target = "archive/#{target_basename}"`) is correct for the given directory structure. This is often a tricky area, and it's handled well here.

##### 🎯 `lib/ace/prompt/cli.rb`
- ✅ **Clear CLI**: The Thor CLI is well-implemented. It provides a default task, clear help text, and handles file output gracefully, including directory creation.
- 💡 **Suggestion**: The file output logic can be slightly simplified.
  - **L48-56**:
  ```ruby
  # Current
  output_dir = File.dirname(output_mode)
  FileUtils.mkdir_p(output_dir) unless output_dir == "." || File.directory?(output_dir)
  # ...
  File.write(output_mode, result[:content], encoding: "utf-8")

  # Suggested simplification
  # FileUtils.mkdir_p handles the case where the directory exists,
  # and File.write can create the file directly.
  begin
    FileUtils.mkdir_p(File.dirname(output_mode))
    File.write(output_mode, result[:content], encoding: "utf-8")
    # ...
  # ...
  ```

##### 🎯 `test/**/*_test.rb`
- ✅ **Good Coverage**: The new gem is introduced with a solid test suite covering atoms, molecules, organisms, and the CLI. Using `Minitest::Test` and `tmpdir` for file system interactions is a best practice and is implemented correctly.

---

#### Documentation & Configuration

##### 🎯 `CHANGELOG.md` & `ace-git-worktree/CHANGELOG.md`
- ✅ **Clear & Correct**: The changelog entries are excellent. They are clear, detailed, and correctly formatted. The version bumps (`0.4.0` for features/fixes, `0.4.1` for a patch) adhere to semantic versioning.

##### 🎯 `.ace-taskflow/`
- ✅ **Good Practice**: The creation of new "idea" files for future architectural improvements is a great way to capture strategic thinking. The task file updates correctly reflect the status of the work.

### Prioritised Action Items

1.  🔴 **Critical**: None.
2.  🟡 **High**: None.
3.  🟢 **Medium**:
    - **File**: `ace-git-worktree/lib/ace/git/worktree/atoms/task_id_extractor.rb`
    - **Suggestion**: Consider anchoring the fallback regex for bare 3-digit task IDs (`/\b(\d{3})\b/`) to `\A(\d{3})\z` to prevent it from matching numbers inside other strings. This improves robustness.
4.  🔵 **Low**:
    - **File**: `ace-prompt/lib/ace/prompt/cli.rb`
    - **Suggestion**: Simplify the file output logic by removing redundant directory checks, as `FileUtils.mkdir_p` handles them.
    - **File**: `ace-git-worktree/lib/ace/git/worktree/organisms/task_worktree_orchestrator.rb`
    - **Suggestion**: Consider removing the `normalize_task_id_for_matching` wrapper method and calling `Atoms::TaskIDExtractor.normalize` directly for better code clarity.