---
id: 8wqe8b
title: release-proof-sandbox-blockers
type: standard
tags: [release, e2e, macos, rubygems]
created_at: "2026-09-27 09:29:14"
status: active
---

# release-proof-sandbox-blockers

Date: 2026-09-27
Context: Post-publish verification of the coordinated six-gem release from the 8wq.t.1qb review-round-efficiency work (ace-review 0.56.0, ace-llm 0.41.0, ace-llm-providers-cli 0.35.0, ace-task 0.37.5, ace-git-worktree 0.23.0, ace-git-github 0.1.2). The standard proof command `ace-test-e2e ace-monorepo-e2e TS-MONO-001` failed at sandbox setup, twice, for local tooling reasons; classification SAFE was earned through the independent clean-room bundle proof. Also captured: a task-lifecycle miss in final delivery.

## What Went Well

- The publisher itself worked exactly as designed: 6 gems in 3 dependency waves, 7.9s live burst, prepared artifacts reused with no rebuilds, and the credential/OTP separation held end to end (readiness-only HITL path; the operator ran the live push out of band with the OTP never entering chat or HITL).
- A documented precedent existed for exactly this failure: the 2026-09-24 proof artifact (`.ace-local/release/rubygems-proof-20260924183844.md`) recorded the same scenario blockage and the independent clean-Ruby bundle proof as the fallback. Reusing that pattern made this release's verification fast and legitimate instead of improvised.
- Root-causing was surgical: the sandbox guard's exit-42 listing localized the problem, and only `ace-*` gems were uninstalled from the sandbox ruby@3.4.9 default gem dir — the user's host Ruby and its installed CLI were left untouched.
- Classification discipline held: SAFE was claimed only on exact-version clean-room resolution, and the artifact honestly records that the primary scenario itself remains locally unverified.

## What Could Be Improved

1. **The primary release-proof command is not runnable on macOS (systemic, recurring).** Two consecutive releases were blocked at sandbox setup: 2026-09-24 (dedicated ruby 3.4.8 exposed global ace-* gems) and 2026-09-27 (same leak in ruby@3.4.9, plus a new blocker: `TestOrchestrator` constructs `BwrapSandboxBackend` unconditionally and its `capture3` → `ensure_available!` raises on any non-Linux platform). Every coordinated release therefore burns release-window time on an ad-hoc workaround, and the actual E2E scenario never validates locally. Impact: time pressure inside the OTP window, repeated archaeology, and risk of misreading a local tooling failure as a registry failure (or vice versa).
2. **Sandbox-Ruby gem pollution recurs because nothing prevents or repairs it.** The leak lives in the Ruby install's default gem dir, which `GEM_HOME`/`GEM_PATH` redirection cannot hide — the `ensure_no_global_ace_gems!` guard detects it but only as a dead end, and whatever installs ace gems into the sandbox rubies is still unidentified. The next sandbox Ruby (3.4.10+) will hit the same wall.
3. **Task lifecycle completion was missed in final delivery.** Orchestrator 8wq.t.1qb stayed `in-progress` after all four subtasks were done, everything shipped, and the release was verified; the user had to ask. Closing the task tree (orchestrator done + archive + commit) is part of delivering an `/as-task-work` task, not an afterthought.

## Key Learnings

- RubyGems path semantics: setting `GEM_HOME`/`GEM_PATH` does not exclude the Ruby install's own default gem dir (`<ruby>/lib/ruby/gems/<ver>`). Pollution there leaks through any env isolation, including the e2e sandbox runtime env — that is why the guard saw gems despite a fully redirected environment.
- mise ships a `rubygems_plugin.rb` in each Ruby's site_ruby that shells out to `mise reshim` after gem installs. A clean-room `bundle install` with a stripped PATH fails with `Errno::ENOENT - mise` unless mise's bin dir (`/opt/homebrew/bin` here) stays on PATH; in the agent harness `mise` also resolves as a shell function, so the absolute binary path is needed.
- `BwrapSandboxBackend.supported?` checks the platform correctly, but nothing at the construction or wrapping call sites consults it — a correct guard that nobody calls is equivalent to no guard.
- Host tooling runs from installed gems, not the repo: `ace-bundle wfi://…` resolved workflow instructions from ace-assign 0.56.0 in the host Ruby, and the host ruby@3.4.8 currently carries 40 ace gems including stale versions. Stale global installs can serve outdated workflow instructions and mask repo-side fixes.

## Action Items

### Stop Doing

- Treating sandbox-Ruby pollution as a one-off cleanup; it has now recurred across two releases and two Ruby versions.
- Running TS-MONO-001 for the first time inside the post-publish window; pre-flight it before the publish burst so sandbox prerequisites are fixed before OTP pressure starts.

### Continue Doing

- The independent clean-Ruby bundle proof (clean ruby, empty `GEM_HOME`/`GEM_PATH`, exact pinned versions, mise on PATH) as the documented macOS fallback, with the proof artifact written per `ace-handbook/docs/release-rubygems-proof.md` every release.
- Honest classification: record the scenario blockage in the proof artifact instead of claiming the scenario passed.

### Start Doing

- Fix `ace-test-runner-e2e` for non-Linux platforms: gate sandbox-backend construction and command wrapping on `BwrapSandboxBackend.supported?` (or fall back to a platform-neutral no-op backend on macOS) so TS-MONO-001 actually runs here. Draft a task from this item.
- Make the sandbox guard actionable or self-healing: include the exact repair command in the `ensure_no_global_ace_gems!` failure message (`gem uninstall --all --executables --ignore-dependencies <names>` under ruby@<ver>), and identify what installs ace gems into the sandbox Ruby in the first place to cut the leak at its source.
- Add "close the task tree" (mark orchestrator done, archive, commit) to the `/as-task-work` final-delivery checklist so completion is verified as part of delivery, not discovered later.
