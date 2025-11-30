## Summary

- The changes introduce a well-factored `TaskIDExtractor` atom and `TaskPusher` molecule in `ace-git-worktree`, improve subtask handling, and add robust tests.
- A new `ace-prompt` gem is added with a clean ATOM layout (atoms/molecules/organisms), CLI, tests, and mono-repo binstub wiring.
- Main risks are: automatic git pushing on worktree creation by default, CLI `exit` usage contrary to ACE testing patterns, and a README link that violates documented path standards.

## Deep Diff Analysis

- **Intent**
  - `ace-git-worktree`: Centralize hierarchical task ID parsing, integrate with `ace-taskflow`’s higher-level APIs, and optionally push task-status commits so PRs see updates.
  - `ace-prompt`: Provide a small prompt workspace tool that reads a single “active” prompt file, archives it with timestamp, maintains a `_previous.md` symlink, and outputs content.
  - Task docs/ideas: Capture architectural ideas (i10t integration modules, review subject presets) and record subtask-ID bugfix context.

- **Impact**
  - Task ID handling is now consistent and subtask-aware across worktree listing, creation, status updates, and removal (e.g., `121` vs `121.01`).
  - `ace-git-worktree` can now auto-push task commits, which is a behavioral change that affects git remotes and CI flows.
  - `ace-prompt` becomes a first-class gem wired into the mono-repo and Gemfile, with a new CLI entry (`ace-prompt` and `bin/ace-prompt`).

- **Alternatives**
  - For task-ID extraction, an alternative would be to fully depend on `TaskReferenceParser` and fail hard if `ace-taskflow` is missing, instead of regex fallbacks.
  - For pushing, a safer default would be “no auto-push” with an explicit `--push` or config opt-in rather than enabled by default.
  - For `ace-prompt`’s CLI, following the “return status code from commands, exit only in `exe/`” pattern would align better with existing ACE CLI guidance.

## Code Quality Assessment

- **Complexity / Maintainability**
  - `TaskIDExtractor` is small and cohesive; its single responsibility improves maintainability (`ace-git-worktree/lib/ace/git/worktree/atoms/task_id_extractor.rb:1`).
  - Task orchestration logic in `TaskWorktreeOrchestrator` is growing but still readable; the step list and `workflow_result` structure are explicit (`task_worktree_orchestrator.rb:51-210`).
  - `TaskFetcher` is clear but now depends on an organism-level API from another gem, which slightly blurs ATOM layering (`task_fetcher.rb:58-75`).

- **Style / Ruby idioms**
  - Generally matches existing style: frozen string literals, namespaced modules, predicate methods (`auto_push_task?`, `auto_commit_task?`) and keyword arguments.
  - The CLI code for `ace-prompt` uses Thor idiomatically, but the explicit `exit` calls deviate from ACE’s recommended command patterns (`ace-prompt/lib/ace/prompt/cli.rb:42-77`).

- **Test Coverage Delta**
  - New tests for `TaskIDExtractor`, `TaskPusher`, and a subtask integration workflow significantly increase coverage for task/worktree behavior.
  - `ace-prompt` has tests across atoms, molecules, organisms, and CLI presence, but misses an end-to-end CLI test path that verifies `process` behavior and exit codes.

## Architectural Analysis

- **Pattern Compliance**
  - `TaskIDExtractor` correctly lives under `atoms/` and is reused by molecules and organisms (e.g., `WorktreeConfig`, `TaskStatusUpdater`, `WorktreeManager`, `RemoveCommand`).
  - `TaskPusher` is a molecule that wraps `GitCommand` atom correctly (`task_pusher.rb:1-147`).
  - `ace-prompt` follows ATOM: `atoms/`, `molecules/`, `organisms/`, `cli.rb` and `version.rb` under `lib/ace/prompt/`.

- **Dependency Changes**
  - `TaskFetcher` now requires `Ace::Taskflow::Organisms::TaskManager` instead of `TaskLoader` (`task_fetcher.rb:5-8`), moving to a higher-level integration which is more stable but increases cross-gem coupling at the molecule layer.
  - `TaskWorktreeOrchestrator` now depends on `Molecules::TaskPusher` (`task_worktree_orchestrator.rb:27-32`).
  - Root Gemfile and Gemfile.lock add `ace-prompt` as a path dependency and bump `ace-git-worktree` to `0.4.1`.

- **Component Boundaries**
  - The integration between `ace-git-worktree` and `ace-taskflow` is still ad-hoc; the new idea doc promotes an `i10t` module pattern, but this diff does not implement such a layer.
  - `ace-prompt` uses `Ace::Core::Molecules::ProjectRootFinder` for project-root awareness, which aligns with configuration and path patterns.

## Security Review

- *No critical security issues found.*

- `TaskFetcher#valid_task_reference?` includes explicit checks against shell metacharacters and control characters before invoking `ace-taskflow` via `Open3.capture3` (`task_fetcher.rb:103-115`), which is good defense-in-depth.
- `TaskPusher` shells out via `Atoms::GitCommand.execute`; assuming `GitCommand` builds argument arrays and does not invoke a shell directly, command injection risk is minimal (`task_pusher.rb:43-52`).
- `PromptReader` and `PromptArchiver` operate on paths derived from `ProjectRootFinder` and known `.cache` locations, which keeps effects within the project (`prompt_reader.rb:12-26`, `prompt_archiver.rb:18-30`).
- For safety, the new auto-push default should be treated as a behavioral/security-adjacent concern: it transmits state to remotes without explicit user confirmation.

## Performance Review

- *No major performance regressions apparent.*

- `TaskIDExtractor` and `TaskPusher` are lightweight and only run per operation; regex parsing cost is negligible compared to git operations.
- `TaskFetcher` still uses `Open3.capture3` as a fallback; since that existed previously, the performance profile is similar (though note that always running from `Dir.pwd` now may interact differently with large repos).
- `ace-prompt`’s archiving and symlink management are simple filesystem operations; timestamp collision handling via incremented suffix is efficient (`prompt_archiver.rb:40-57`).

## Testing & Coverage

- **ace-git-worktree**
  - `TaskIDExtractor` is extensively tested with diverse ID formats: parent tasks, subtasks, orchestrator subtasks, backlog IDs, invalid formats (`ace-git-worktree/test/atoms/task_id_extractor_test.rb`).
  - `SubtaskWorkflowTest` exercises directory naming, distinct paths for parent/subtasks, normalized task references, and branch/commit message formatting (`test/integration/subtask_workflow_test.rb`), which is strong integration coverage.
  - `TaskPusherTest` stubs `GitCommand.execute` appropriately and covers success/failure paths, branch/remote detection, upstream detection, and timeout configuration (`test/molecules/task_pusher_test.rb`).

- **ace-prompt**
  - Atoms (`TimestampGenerator`, `ContentHasher`) and molecules (`PromptReader`, `PromptArchiver`) have solid coverage including large/unicode content and timestamp collision.
  - `PromptProcessorTest` validates the read→archive flow including symlink behavior and custom input paths.
  - `CLITest` only checks presence of commands/options and version output; it does not assert behavior of `process` under success/failure, nor does it validate exit codes or writing to `--output` files.

- **Gaps / Suggestions**
  - Add integration tests for `ace-git-worktree` covering:
    - `create` with `--no-push` and `--push-remote` flags.
    - The interaction between `TaskWorktreeOrchestrator` and `TaskPusher`, especially error handling when pushes fail.
  - Add CLI integration tests for `ace-prompt` that:
    - Run `CLI.start(["process"])` with a temp project root and verify that content is printed, archive created, and `_previous.md` updated.
    - Exercise `--output` to file, and test error paths (missing prompt file, unwritable output).

## Documentation Review

- New idea docs under `.ace-taskflow/v.0.9.0/ideas/...` are clear and consistent with project architecture concepts; they don’t introduce technical risk.
- Root `CHANGELOG.md` and `ace-git-worktree/CHANGELOG.md` entries correctly document version bumps and behavioral changes; this is very good for traceability.
- `ace-prompt/CHANGELOG.md` succinctly documents the initial release.
- `ace-prompt/README.md` is concise and practical, but:
  - The link `../../.ace-taskflow/v.0.9.0/tasks/121-ace-prompt/ux/usage.md` (`ace-prompt/README.md:36`) uses `../` and points into `.ace-taskflow`, which conflicts with ADR-004 on path standards and makes the README less portable when the gem is used outside this mono-repo.

## Detailed File-by-File Feedback

### `.ace-taskflow` idea/task files

- *No issues found* (content is descriptive and does not affect runtime behavior).

### `ace-git-worktree/lib/ace/git/worktree/atoms/task_id_extractor.rb`

- ✅ Centralizing task ID parsing here is a strong improvement; the combination of `TaskReferenceParser` and regex fallback is robust (`task_id_extractor.rb:33-61`).
- 💡 Consider logging (or at least allowing optional debug logging) when the regex fallback is used instead of `TaskReferenceParser`, to make it observable when cross-gem parsing fails.

### `ace-git-worktree/lib/ace/git/worktree/molecules/task_fetcher.rb`

- ✅ Switching to `Ace::Taskflow::Organisms::TaskManager` gives a cleaner, higher-level integration (`task_fetcher.rb:58-65`).
- ⚠️ **Regression risk**: CLI fallback now always runs in `Dir.pwd` instead of a discovered project root (`fetch_via_cli` at `task_fetcher.rb:131-145`). Previously, `root_path` was configurable and could be tied to repository root/`PROJECT_ROOT_PATH`.
  - **Suggestion**: Reintroduce a `project_root` parameter (defaulting via `ProjectRootFinder`) and use it as `chdir:` for `Open3.capture3`, keeping behavior consistent with other components.
- 💡 The molecule directly depends on an organism-level API, which slightly violates ATOM layering:
  - **Suggestion**: As the new “i10t” pattern is developed, consider moving `TaskManager` integration into an `ace-git-worktree` integration module or organism, and let `TaskFetcher` depend on that abstraction.

### `ace-git-worktree/lib/ace/git/worktree/molecules/task_pusher.rb`

- ✅ Implementation is clear and testable; timeouts and helpers (`current_branch`, `has_upstream?`, `get_upstream`) are nicely contained (`task_pusher.rb:21-132`).
- 💡 `push` always uses `-u` (set upstream) by default (`task_pusher.rb:47-52`); in repos where upstream is already configured this is harmless but redundant. Consider:
  - Defaulting `set_upstream` based on `has_upstream?` (only set upstream when missing), or
  - Documenting clearly that `TaskPusher` assumes control of tracking config.

### `ace-git-worktree/lib/ace/git/worktree/models/worktree_config.rb`

- ✅ Adding `auto_push_task` and `push_remote` into `DEFAULT_CONFIG` is well integrated with other task settings (`worktree_config.rb:33-41`).
- ⚠️ **Behavior change**: Pushing is enabled by default (`auto_push_task` defaulting to `true`), which means `ace-git-worktree create --task` will now push commits to `origin` without the user explicitly opting in (`worktree_config.rb:33-41`, `task_worktree_orchestrator.rb:146-166`).
  - **Suggestion**: Strongly consider defaulting `auto_push_task` to `false` and documenting how to opt in via `.ace/git/worktree.yml`. This avoids surprising users with unexpected pushes to remotes.

### `ace-git-worktree/lib/ace/git/worktree/organisms/task_worktree_orchestrator.rb`

- ✅ Reordering metadata addition to occur before committing is correct: it ensures status + metadata live in the same commit (`task_worktree_orchestrator.rb:84-99`).
- ✅ Dry-run reporting includes push-related steps, which improves transparency (`task_worktree_orchestrator.rb:188-208`).
- ⚠️ Because auto-push is now part of the main workflow, a failed push only populates `workflow_result[:warnings]` and still reports overall success (`task_worktree_orchestrator.rb:131-139`).
  - **Suggestion**: Decide whether push failure should:
    - Fail the workflow for certain cases (e.g., when a remote is configured but unreachable), or
    - Be clearly surfaced at CLI level (e.g., printing a prominent warning).
- 💡 `push_task_changes` currently uses the current branch, not necessarily the task branch (`task_worktree_orchestrator.rb:437-444` via `TaskPusher#current_branch`). If the user has a detached HEAD or is not on the task branch when invoking the command, this might push the wrong branch.
  - **Suggestion**: Pass the branch name determined for the worktree into `push_task_changes` so `TaskPusher` pushes the intended branch explicitly.

### `ace-git-worktree/lib/ace/git/worktree/commands/create_command.rb`

- ✅ New options `--no-push` and `--push-remote` are parsed and wired through to the orchestrator correctly (`create_command.rb:90-98`, `create_command.rb:312-322`, `create_command.rb:532-557`).
- 💡 There are no tests in this diff for these new flags.
  - **Suggestion**: Add CLI-level tests that assert:
    - Dry-run output includes “Would push to: <remote>” when applicable.
    - `--no-push` suppresses push even when config enables it.
    - `--push-remote upstream` overrides config.

### Other `ace-git-worktree` files using `TaskIDExtractor`

- ✅ Replacements in `RemoveCommand`, `WorktreeConfig`, `WorktreeInfo`, `TaskStatusUpdater`, and `WorktreeManager` simplify and unify task ID handling.
- 💡 In `WorktreeConfig#extract_task_number`, returning `"unknown"` for invalid data is a safe default, but consider whether raising or logging would make misconfigured tasks easier to detect at runtime.

### `ace-prompt/lib/ace/prompt/cli.rb`

- ✅ The CLI surface is small and clear, with a sensible default command (`process`) and a `version` command (`cli.rb:14-86`).
- ❌ **Pattern violation / Testing impact**: `process` calls `exit 1` on errors and `exit_on_failure?` returns `true` (`cli.rb:10-12`, `cli.rb:42-49`, `cli.rb:69-77`). This conflicts with the documented ACE testing pattern that commands should return status codes and only `exe/` should call `exit`.
  - **Suggestion**:
    - Change `exit_on_failure?` to `false`.
    - Have `process` return `0` on success and `1` on failure (no `exit`).
    - Update `exe/ace-prompt` to capture the return value, e.g.:
      ```ruby
      # exe/ace-prompt
      require "ace/prompt"
      exit_code = Ace::Prompt::CLI.start(ARGV)
      exit(exit_code || 0)
      ```
    - Add tests asserting the returned status code.
- 💡 There’s currently no CLI test that drives `process` end-to-end. Adding one using a temp project root and prompt file would verify the full user journey.

### `ace-prompt` atoms/molecules/organisms

- ✅ `TimestampGenerator` and `ContentHasher` are small, pure atoms returning hashes and are well-tested.
- ✅ `PromptReader` and `PromptArchiver` correctly use `ProjectRootFinder` and handle symlinks, timestamp collisions, and unicode.
- 💡 `PromptArchiver.update_symlink` takes a `base_dir` parameter but does not use it (`prompt_archiver.rb:68-88`).
  - **Suggestion**: Remove the parameter or use it to compute the relative path, to avoid confusion.
- 💡 `PromptReader.call` ignores the `project_root` when a custom `path` is provided (`prompt_reader.rb:18-26`).
  - This is probably fine (explicit path overrides root), but you may want to document that behavior or, for relative paths, resolve relative to `project_root` instead of `Dir.pwd`.

### `ace-prompt/README.md`

- ✅ Quick start and behavior description are clear and match the implementation (the default path and archive behavior are correct).
- ⚠️ The usage link uses a path starting with `../` and points into `.ace-taskflow` (`README.md:36`), which:
  - Conflicts with ADR-004 (“Never use paths starting with ./ or ../; all document paths must be relative to project root”).
  - Makes the gem README non-portable when the gem is used outside this mono-repo.
  - **Suggestion**: Either:
    - Point to a gem-local `docs/usage.md` within `ace-prompt`, or
    - Use a repo-root-relative path string like `.ace-taskflow/v.0.9.0/tasks/121-ace-prompt/ux/usage.md` in a mono-repo-specific doc, not the gem README.

### `ace-prompt/test` files

- ✅ Test coverage is broad, with attention to edge cases (unicode, large content, timestamp collisions, symlinks).
- 💡 `PromptArchiverTest#setup` stubs `ProjectRootFinder.find_or_current` but doesn’t need that stub for directory creation (`prompt_archiver_test.rb:8-19`); the real stubbing happens inside each test. Not harmful, but can be simplified.
- 💡 `CLITest` currently only asserts presence of commands and `exit_on_failure?` (`cli_test.rb:6-48`); it does not validate behavior or return codes.

## Prioritised Action Items

1. 🔴 **High** – Rework `ace-prompt` CLI to avoid `exit` calls in command methods (`ace-prompt/lib/ace/prompt/cli.rb:10-12`, `42-77`), returning status codes instead and letting `exe/ace-prompt` handle exiting.
2. 🟡 **High** – Reconsider the default of `auto_push_task: true` in `WorktreeConfig` (`worktree_config.rb:33-41`); either default to `false` or clearly document and test the behavior so users aren’t surprised by automatic pushes.
3. 🟢 **Medium** – Restore project-root-aware behavior in `TaskFetcher`’s CLI fallback by using `ProjectRootFinder` or a `project_root` parameter and passing it as `chdir:` to `Open3.capture3` (`task_fetcher.rb:131-145`).
4. 🟢 **Medium** – Ensure `TaskWorktreeOrchestrator#push_task_changes` pushes the correct branch explicitly (likely the task branch), not just `current_branch` (`task_worktree_orchestrator.rb:437-444`).
5. 🟢 **Medium** – Update `ace-prompt/README.md` to avoid `../` paths and `.ace-taskflow` references, pointing instead to a gem-local usage doc or a repo-root-relative path appropriate for this mono-repo (`README.md:36`).
6. 🔵 **Low** – Add CLI-level tests for `ace-git-worktree` create options (`--no-push`, `--push-remote`) and for `ace-prompt`’s `process` command to validate both success and failure flows.
7. 🔵 **Low** – Clean up minor code smells (unused `base_dir` parameter in `PromptArchiver.update_symlink`, redundant stub in `PromptArchiverTest#setup`).

## Refactoring Opportunities

- Introduce an integration module (early `i10t` pattern) within `ace-git-worktree` to encapsulate `ace-taskflow` dependencies (currently in `TaskFetcher` and `TaskStatusUpdater`), making it easier to stub and evolve cross-gem integrations.
- Consider centralizing git push behavior (remote resolution, upstream handling) in a higher-level abstraction that both `TaskPusher` and any future push-related molecules/organisms can use, especially once PR-based workflows expand.
- For `ace-prompt`, as functionality grows, you may later introduce a small model object representing “PromptSession” (content + archive paths + metadata hash), to keep `PromptProcessor` from becoming a large hash-manipulating orchestrator.