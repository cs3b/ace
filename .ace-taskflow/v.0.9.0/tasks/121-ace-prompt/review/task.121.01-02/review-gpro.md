An excellent set of changes that delivers a critical refactoring for `ace-git-worktree` and introduces the new, well-structured `ace-prompt` gem. The centralization of logic in `TaskIDExtractor` is a significant improvement, and the new gem adheres well to the project's ATOM architecture.

My review focuses on aligning the new `ace-prompt` CLI with established testing patterns and reconsidering a default behavior in `ace-git-worktree` to ensure predictability for users.

### Architectural Analysis

-   ✅ **Excellent Refactoring**: The creation of `ace-git-worktree/lib/ace/git/worktree/atoms/task_id_extractor.rb` is a standout improvement. It successfully centralizes complex logic for handling hierarchical task IDs, eliminating duplication and fixing a critical bug where operations on subtasks could affect parent tasks. This significantly improves the robustness and maintainability of `ace-git-worktree`.
-   ✅ **Strong Pattern Adherence**: The new `ace-prompt` gem is a great example of the project's standards in action. It correctly follows the ATOM architecture, leverages `ace-support-core` for common utilities, and is well-integrated into the mono-repo.
-   ⚠️ **Behavioral Change in Defaults**: The change in `ace-git-worktree` to enable auto-pushing by default (`auto_push_task: true`) is a significant behavioral shift. While configurable, defaults that perform network operations with side effects can be surprising to users. It's generally safer for such features to be opt-in.
-   ⚠️ **CLI Pattern Violation**: The new `ace-prompt` CLI calls `exit` directly from within its command logic. This violates the established testing pattern described in `docs/testing-patterns.md`, which states that commands should return status codes and only the top-level executable (`exe/`) should handle exiting. This makes the CLI difficult to test at an integration level and prevents composition.

### Detailed File-by-File Feedback

#### 🔴 Critical

##### `ace-prompt/lib/ace/prompt/cli.rb`

-   **L10-12, L48, L71, L76**: 🔴 **Pattern Violation**: The `process` command calls `exit 1` on failure, and `exit_on_failure?` is not overridden to return `false`. This prevents the test suite from catching failures and reporting correctly, as it terminates the entire test process. Per `docs/testing-patterns.md`, commands should return status codes.

    **Suggestion**: Refactor the CLI to return status codes.

    ```ruby
    # ace-prompt/lib/ace/prompt/cli.rb

    # ...
    module Ace
      module Prompt
        class CLI < Thor
          # This allows the exe/ wrapper to handle the exit code
          def self.exit_on_failure?
            false
          end

          # ...
          def process
            # ...
            unless result[:success]
              warn "Error: #{result[:error]}"
              return 1 # Return status code instead of exiting
            end

            if output_mode == "-"
              puts result[:content]
              return 0 # Return 0 on success
            else
              # ...
              begin
                File.write(...)
                # ...
                return 0 # Return 0 on success
              rescue StandardError => e
                warn "Error writing output file: #{e.message}"
                return 1 # Return status code instead of exiting
              end
            end
          rescue Ace::Prompt::Error => e
            warn "Error: #{e.message}"
            return 1 # Return status code instead of exiting
          end
          # ...
        end
      end
    end
    ```

    The executable `ace-prompt/exe/ace-prompt` already correctly handles the exit code, so only `cli.rb` needs this change.

#### 🟡 High

##### `ace-git-worktree/lib/ace/git/worktree/models/worktree_config.rb`

-   **L39**: 🟡 **Potentially Surprising Default**: Setting `auto_push_task` to `true` by default means that creating a worktree will now push commits to a remote without explicit user action on the command line. This could lead to unexpected changes being pushed.

    **Suggestion**: Change the default to `false` to make this an opt-in feature. This follows the principle of least surprise.

    ```ruby
    # ace-git-worktree/lib/ace/git/worktree/models/worktree_config.rb:39
    # ...
                  "auto_mark_in_progress" => true,
                  "auto_commit_task" => true,
                  "auto_push_task" => false, # Change default to false
                  "push_remote" => "origin",
    # ...
    ```

#### 🟢 Medium

##### `ace-prompt/README.md`

-   **Issue**: The task files (`121.07-address-review-feedback-for-prompt-generation.s.md`) indicate that the README contains a path like `../../.ace-taskflow/...`. This violates [ADR-004](docs/decisions.md), which prohibits `../` in paths to ensure documentation is self-contained and portable.

    **Suggestion**: Remove the relative path. If necessary, refer to concepts or usage patterns in a general way without linking to a file outside the gem's own directory. A good pattern is to have a `docs/usage.md` within the gem itself for more detailed documentation.

#### 💡 Suggestions

##### `ace-prompt/test/`

-   **Gap**: There are no integration tests for the CLI's behavior. Unit tests for the CLI's structure exist, but there's no test to confirm that running `ace-prompt process` actually creates an archive and outputs content correctly, or that it returns the correct status code on failure.

    **Suggestion**: Add a new test file `ace-prompt/test/integration/cli_integration_test.rb`. This test should:
    1.  Set up a temporary project root with a mock prompt file.
    2.  Invoke `Ace::Prompt::CLI.start([...])`.
    3.  Assert that the returned exit code is `0` on success and `1` on failure (e.g., when the prompt file is missing).
    4.  Verify that the archive file and `_previous.md` symlink are created correctly on success.

##### `ace-prompt/lib/ace/prompt/molecules/prompt_archiver.rb`

-   **L69**: 🔵 **Code Hygiene**: The `update_symlink` method signature includes a `base_dir` parameter that is not used within the method body.

    **Suggestion**: Remove the unused `base_dir` parameter from the method definition and its call site to improve code clarity.

    ```ruby
    # ace-prompt/lib/ace/prompt/molecules/prompt_archiver.rb
    # ...
          # At the call site (around line 50)
          update_symlink_result = update_symlink(symlink_path, archive_path)

    # ...

        # In the method definition (around line 69)
        def self.update_symlink(symlink_path, target_path)
          # ...
        end
    # ...
    ```

### Prioritised Action Items

1.  🔴 **Critical**: Refactor `ace-prompt/lib/ace/prompt/cli.rb` to return status codes (`0` or `1`) instead of calling `exit`, aligning with the project's testing patterns.
2.  🟡 **High**: Change the default for `auto_push_task` in `ace-git-worktree` to `false` to prevent unexpected pushes to remote repositories.
3.  🟢 **Medium**: Correct the path in `ace-prompt/README.md` to comply with ADR-004 and remove `../` references.
4.  💡 **Suggestion**: Add a CLI integration test for `ace-prompt` to verify end-to-end functionality and exit codes.
5.  🔵 **Low**: Remove the unused `base_dir` parameter from `PromptArchiver.update_symlink` in `ace-prompt`.