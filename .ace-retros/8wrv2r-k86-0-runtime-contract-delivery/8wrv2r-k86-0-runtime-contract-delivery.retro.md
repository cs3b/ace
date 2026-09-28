---
id: 8wrv2r
title: k86-0-runtime-contract-delivery
type: standard
tags: [ace-runtime, delivery, k86]
created_at: "2026-09-28 20:43:04"
status: active
---

# k86-0-runtime-contract-delivery

Retro for task 8wq.t.k86.0 (ace-runtime contract gem, 2026-09-28): implemented in worktree `k86.0-runtime-intent-contract`, reviewed (code-valid/codex, 3 findings fixed), rebased onto a moving origin/main, PR #343 created and updated, full suite run, merged to local main (eb2d3c0be). Gems unpublished; remotes unpushed by instruction.

## What Went Well

- **Oracle-driven contract design.** Reading the bundle.files consumer call sites (`ControlSurface#send_sequence`, `TmuxControlSurfaceRunner#fork_window_name`, `ForkSessionLauncher#resolve_launch_mode`, `TmuxWindowOpener#open`) before writing code kept the 11-op API honest — ordered send items, 40-line capture default, seconds-based waits, and the four lifecycle conditions all map 1:1 to what consumers use today. No speculative operations.
- **The packaged acceptance bar paid for itself immediately.** `Testing::AdapterContract` + `ScriptedRuntime` proved the send matrix on both profiles in-gem, and the independent review (code-valid preset, codex model) then caught three real defects pre-merge: the High lazy-load issue (a broken installed adapter's LoadError was swallowed and misreported as `UnknownRuntimeError`), typed-error leaks from `focus`/`close_window`/`wait_agent`, and `AdapterContract#setup` skipping `super`. All fixed and re-verified in one session.
- **PR scoping against a moving base.** Local main carried undelivered sibling lines (ace-lab 1w4, test-runner hermetic). The first PR was rebuilt from origin/main + cherry-picks to keep scope clean; when origin/main later absorbed those lines, a plain `git rebase origin/main` auto-dropped the upstreamed commits (verified patch-equivalent outside `.ace-tasks`), and `--force-with-lease` updated PR #343 safely.
- **Mistakes surfaced by guards, not by users, mostly.** The suite-config guard (`test_suite_config_includes_all_testable_packages`) caught the unregistered new gem; the agent-pane send matrix caught a hard-coded delivery count in the stall test that was wrong for the agent profile.

## What Could Be Improved

- **Checkout discipline failed twice in one session.** Repo-mutating commands (`ace-task update`, `ace-retro create`) ran from a stale cwd still cd'd into the worktree: the parent-task in-progress flag landed on the PR branch instead of main (the user had to report it), and the first retro file was created in the wrong checkout and had to be removed. Root cause: long command chains leave the shell wherever the last `cd` put it, and `ace-*` commands operate on whatever checkout they find.
- **New-gem onboarding has an invisible step.** Nothing in the gem scaffolding path (gemspec, Rakefile, test helper) hints that a new testable gem must be registered in `.ace/test/suite.yml`; it was discovered only because ace-test-runner's guard test went red, and until then `ace-test-suite` silently ran 47 packages without the new one.
- **Verification loops burned turns on environment quirks.** A throwaway `/tmp` worktree had broken bundler config (ace-review tests wouldn't even load), and the primary checkout's bare `ace-test ace-test-runner` failed with `NameError: EnvironmentPolicy` because the host-installed 0.27.0 gem shadows workspace sources. Both dead ends produced no signal before being identified as environmental.
- **Guessing tool names instead of checking.** `ace-review --preset code-deep` (from the plan text) does not exist in this project's config — the available presets live in `.ace/review/presets/`. Also `ace-review` takes `--subject`, not a positional package argument. Gemini reviewer is dead at CLI auth level, so reviews ran single-model.

## Key Learnings

- **Every new testable gem must be registered in `.ace/test/suite.yml`** (name/path/group/priority). It is enforced by `test_suite_config_includes_all_testable_packages` in ace-test-runner, and until registered the gem is silently absent from full-suite runs.
- **Bare `ace-test <pkg>` is not trustworthy on this host** — host-installed gems can shadow workspace sources (NameError mysteries like `EnvironmentPolicy`). Use `bundle exec ace-test <pkg>` or the hermetic `ace-test-suite`; do comparison runs in `.ace-wt` worktrees, never `/tmp` (bundler config does not follow).
- **A plain `git rebase origin/main` after upstream moved is the cherry-pick killer**: git skips patch-identical commits automatically. Capture the pre-rebase merge-base and diff first, then verify patch-equivalence after; treat `.ace-tasks` drift from upstream spec edits as expected merge content, not corruption.
- **`ace-task update --set status=done --move-to archive` on a subtask defers the archive move** while sibling subtasks are non-terminal (correct orchestration behavior for the k86 chain — k86.0 is done, archive waits for k86.1–.3).
- **Adapters must expose `send_profile` and normalize through `SendContract` before transport** — this division (central validation, duck-typed adapters, contract suite as the enforcement bar) is the shape k86.1/k86.2 should copy from `test/support/fake_runtime_adapter.rb`.

## Action Items

- **Stop** running `ace-task`/`ace-retro`/`ace-git-commit` without a preceding `git branch --show-current` check (or an explicit `cd <primary>` prefix) when worktrees exist.
- **Start** adding "register in `.ace/test/suite.yml`" to the gem-scaffolding checklist (`docs/ace-gems.g.md` new-gem guidance) so the next gem doesn't surface this via a red guard test.
- **File a follow-up task** for the environmental ace-review suite failure (`test_exempt_paths_are_excluded_from_full_round_subject` → `GhAuthenticationError` from a real `gh` subprocess under the hermetic runner); the test should not depend on ambient gh credentials. → Filed as **8wr.t.v3k**.
- **Continue** the review→fix→re-verify loop (code-valid preset, `.ace/review/presets/` is the source of truth for preset names) and the capture-verify-push sequence (`--force-with-lease`, patch-equivalence) for PR updates.
