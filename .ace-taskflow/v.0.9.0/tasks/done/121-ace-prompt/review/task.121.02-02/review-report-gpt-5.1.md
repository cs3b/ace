## Deep Diff Analysis

- The `ace-git-worktree` changes introduce a centralized `TaskIDExtractor` atom plus a new `TaskPusher` molecule, then thread the atom through multiple models/organisms/molecules to correctly preserve hierarchical task IDs (e.g., `121.01`) across create/remove/status workflows. This directly fixes the prior bug where subtasks were treated as their parent tasks and is a clear net improvement.
- `TaskFetcher` is refactored to use `Ace::Taskflow::Organisms::TaskManager` instead of `TaskLoader`, simplifying its configuration (no `root_path` argument) but also changing behavior: the CLI fallback now runs in `Dir.pwd` rather than a discovered project root, which could be a subtle regression if commands are invoked outside the repo root.
- `WorktreeConfig` gains `auto_push_task` and `push_remote` settings with a new default of automatically pushing task commits to a remote; this is a meaningful behavior change that may surprise users, as creating a worktree can now trigger network activity and remote state changes by default.
- The new `ace-prompt` gem is added with full ATOM structure, a Thor-based CLI, a `PromptProcessor` organism orchestrating read→archive, and a `PromptInitializer` organism handling template-based setup. The intent is to provide a standardized “prompt workspace” with archiving and template management, and the implementation aligns with that.
- The `ace-prompt` CLI has already been refactored to follow the ACE testing pattern (commands return status codes, `exit_on_failure?` is false, and `exe/ace-prompt` is the only place that calls `exit`), addressing the earlier critical review feedback.
- `TemplateResolver` now uses the `ace-nav` Ruby API (`Ace::Nav::Organisms::NavigationEngine`) instead of shelling out, which significantly improves security and testability. It supports both short-form (`bug`) and full `tmpl://` URIs, with a fallback to bundled templates under `ace-prompt/handbook/templates`.
- A large set of `.ace-taskflow` idea, task, retro, and review documents are added to capture the subtask-ID bug context, review feedback for `ace-prompt`, and future directions (integration “i10t” modules, `ace-review` subject presets). These are non-runtime but help clarify intent and future work.

## Code Quality Assessment

- The `TaskIDExtractor` atom (`ace-git-worktree/lib/ace/git/worktree/atoms/task_id_extractor.rb`) is well-scoped and substantially improves maintainability by centralizing logic that was previously duplicated with slightly different regexes. The separation into `extract` (from task hashes) and `normalize` (from references) is clear.
- The fallback regex in `TaskIDExtractor.normalize` that matches bare task IDs (`/\b(\d{3})\b/`) is a bit permissive and could accidentally catch stray three-digit numbers in unexpected strings. Tightening this to something like `/\A(\d{3})\z/` would make the atom more robust without affecting normal usage.
- `TaskPusher` (`ace-git-worktree/lib/ace/git/worktree/molecules/task_pusher.rb`) is clean, uses `GitCommand` consistently, and returns structured hashes. Its API is coherent and tests are thorough. From a complexity standpoint it’s small and easy to reason about.
- `TaskWorktreeOrchestrator` (`organisms/task_worktree_orchestrator.rb`) has grown more complex—metadata addition, commit, push, worktree creation, and hooks—but the step tracking and `workflow_result` data structure still keep it readable. If it grows further, extracting smaller orchestrators (e.g., “task status + commit + push”) would reduce cognitive load.
- `ace-prompt` atoms/molecules/organisms are nicely factored: `TimestampGenerator`, `ContentHasher`, `PromptReader`, `PromptArchiver`, `TemplateResolver`, `TemplateManager`, `PromptProcessor`, and `PromptInitializer` each have a single responsibility and return consistent result hashes.
- In `PromptReader.call` (`ace-prompt/lib/ace/prompt/molecules/prompt_reader.rb`), when a custom `path:` is given it is expanded relative to `Dir.pwd`, not the project root, while the default path is rooted via `ProjectRootFinder`. This is reasonable but worth documenting; alternatively, relative custom paths could be interpreted relative to project root for consistency.
- The tests for both gems are extensive and high quality: `TaskIDExtractorTest`, `TaskPusherTest`, `SubtaskWorkflowTest`, and the many `ace-prompt` tests (atoms, molecules, organisms, CLI, integration) give strong confidence in correctness and guard against regressions.

## Architectural Analysis

- ATOM compliance is strong throughout:
  - `TaskIDExtractor` is a pure atom consumed by molecules (`TaskFetcher`, `WorktreeCreator`, `TaskStatusUpdater`) and organisms (`TaskWorktreeOrchestrator`, `WorktreeManager`, `WorktreeInfo`), which is exactly the intended pattern.
  - `TaskPusher` is correctly placed as a molecule, invoked from `TaskWorktreeOrchestrator` to perform side-effectful git pushes.
  - `ace-prompt` follows the documented ATOM layout and uses `Ace::Core::Molecules::ProjectRootFinder` for path derivation, aligning with shared infrastructure.
- `TaskFetcher` and `TaskStatusUpdater` now integrate with `Ace::Taskflow::Organisms::TaskManager` instead of a lower-level molecule, which is architecturally preferable for cross-gem integration but does mean a molecule depends on an organism in another gem. The “integration module” (i10t) idea in the new docs is a good future direction to formalize this boundary.
- The introduction of automatic push behavior (via `WorktreeConfig#auto_push_task?` and `TaskWorktreeOrchestrator#push_task_changes`) weaves network side effects into the standard worktree-creation workflow. Architecturally, this is a reasonable feature, but the choice to enable it by default blurs the line between local and remote operations and should be carefully surfaced in config and documentation.
- `TaskWorktreeOrchestrator#push_task_changes` currently delegates to `TaskPusher.push` without explicitly specifying the branch, relying on `TaskPusher#current_branch`. This is acceptable in typical workflows but leaves a potential edge case if commands are invoked from a non-task branch; passing the intended branch explicitly would make the orchestrator more deterministic.
- `TemplateResolver`’s use of the `ace-nav` Ruby API rather than shell calls is a solid architectural move, aligning with the broader principle of using internal APIs for cross-gem integration and keeping side effects in molecules rather than atoms or organisms.
- The new `.ace/nav/protocols/tmpl-sources/ace-prompt.yml` and `.ace.example/nav/...` configs match the established pattern for protocol discovery and are consistent with `ace-nav`’s architecture.

## Documentation Impact Assessment

- Root `CHANGELOG.md` and `ace-git-worktree/CHANGELOG.md` are updated correctly with new versions (`0.9.141`, `0.9.142`, `0.9.143` and `0.4.0`, `0.4.1` respectively), clearly describing added features, fixes, and behavioral changes (including subtask handling and TaskPusher loading). This is compliant with the project’s semantic versioning and Keep-a-Changelog requirements.
- `ace-prompt/CHANGELOG.md` documents both the initial `0.1.0` release and the `0.2.0` additions (setup command, template support, CLI exit code handling) in a clear, user-facing way.
- `ace-prompt/README.md` is concise, easy to follow, and no longer references paths using `../` or `.ace-taskflow`, respecting ADR-004’s path standards and making the README portable outside this mono-repo. It does, however, refer vaguely to “task directory” for additional docs; cross-linking to `ace-prompt/docs/usage.md` would make navigation clearer.
- `ace-prompt/docs/usage.md` provides a very good, gem-local usage guide, clearly explaining `setup`, `process`, file locations, template behavior, and exit codes. This fills the gap previously handled by task docs and aligns with the “gem-local docs” guidance in the architecture docs.
- The `.ace-taskflow` idea/task/retro/review files are well-written and consistent with the project’s documentation style, especially the retrospectives and review syntheses for task 121.01/121.02 and task 123. They don’t require changes but do a good job of explaining context and decisions.
- One likely missing piece is explicit documentation in `ace-git-worktree`’s own README (outside this diff) describing the new `auto_push_task` and `push_remote` configuration options and the `create` CLI flags `--no-push` / `--push-remote`. The changelog mentions them, but a user-focused section would better communicate the behavior change.

## Quality Assurance Requirements

- Add CLI-level tests in `ace-git-worktree` for the new `create` options:
  - Verify that `--no-push` suppresses the push step even when config `auto_push_task` is true.
  - Verify that `--push-remote <name>` overrides the configured `push_remote`.
  - In dry-run mode, assert that the “Would push to: …” line appears only when a push is planned.
- Consider a focused test for `TaskWorktreeOrchestrator#push_task_changes` that confirms:
  - Successful push marks the `task_pushed` step and sets `workflow_result[:pushed_to]`.
  - Failed push records a warning but does not mark the overall workflow as failed.
- For `TaskFetcher`, add a regression test around the CLI fallback (`fetch_via_cli`) to ensure it behaves correctly when run from a non-repo directory, or validate that running from `Dir.pwd` is acceptable and documented. If you reintroduce project-root awareness, tests should pin that behavior.
- `ace-prompt`’s test suite is already very strong (unit and integration), but one additional TemplateResolver test that simulates a successful `ace-nav` resolution (by stubbing `NavigationEngine#resolve`) would round out coverage of the “happy path” for that integration.
- As the integration “i10t” modules are introduced in future work, plan for dedicated test doubles and integration tests around those modules, in line with the ideas captured in `.ace-taskflow/v.0.9.0/ideas/20251128-110638-...i10t...s.md`.

## Security Review

- `TaskFetcher` and `TaskStatusUpdater` use `Open3.capture3` with argument arrays (for the CLI fallback) and validate task references via `valid_task_reference?`, which restricts characters in task refs. This avoids command injection and is consistent with prior security guidance.
- `TaskPusher` delegates to `Atoms::GitCommand.execute` with argument arrays (`["push", "-u", remote, branch]`) and does not construct shell strings, which is safe from injection as long as `GitCommand` remains array-based.
- The move from shell-based TemplateResolver to using `Ace::Nav::Organisms::NavigationEngine` (with exceptions caught and treated as failures) significantly reduces the attack surface and removes the earlier command injection risk.
- File operations in `ace-prompt` (`PromptReader`, `PromptArchiver`, `TemplateManager`, `PromptInitializer`) operate under either the project root (`ProjectRootFinder.find_or_current`) or a known `.cache/ace-prompt/prompts` subdirectory. There is no evidence of unvalidated user-supplied paths being used directly, which minimizes directory traversal risk.
- No password, token, or credential handling is introduced in this diff; external interactions are limited to git and `ace-taskflow`/`ace-nav` APIs, making overall security risk low.
- If/when configuration is added for prompt/archive paths, ensure that any user-configurable paths are validated to avoid writing outside intended project boundaries.

## Refactoring Opportunities

- In `TaskIDExtractor.normalize`, tighten the fallback regex for bare task IDs from `/\b(\d{3})\b/` to something like `/\A(\d{3})\z/` to avoid accidentally matching unrelated numbers and to encode the 3-digit task-ID convention more explicitly.
- Consider changing `WorktreeConfig#auto_push_task?`’s default from true to false and clearly documenting the behavior in `ace-git-worktree`’s README. This would better follow the principle of least surprise for operations that have network/remote side effects.
- In `TaskWorktreeOrchestrator#push_task_changes`, accept a branch argument and pass the resolved task branch through to `TaskPusher.push`, rather than relying on `TaskPusher#current_branch`. This would make pushes robust even if commands are invoked from a detached HEAD or a different branch.
- For `TaskFetcher`, revisit the removal of the `root_path`/`ProjectRootFinder` integration in the CLI fallback. If commands are expected to be runnable from arbitrary directories, reinstating a project-root-aware `chdir:` for `Open3.capture3` would improve predictability.
- In `PromptReader.call`, consider treating relative custom `path:` values as relative to project root (computed via `ProjectRootFinder`) rather than `Dir.pwd`, or document the current behavior explicitly in `docs/usage.md` so expectations are clear.
- Over time, as the integration (“i10t”) pattern is implemented, move cross-gem and external interactions (TaskManager, ace-taskflow CLI, ace-nav) behind dedicated integration modules for each gem. This will make dependencies easier to stub in tests and keep molecules/organisms focused on their domain logic.