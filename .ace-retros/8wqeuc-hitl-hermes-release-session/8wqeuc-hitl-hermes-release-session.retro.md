---
id: 8wqeuc
title: hitl-hermes-release-session
type: standard
tags: [release, review, rubygems, publisher, macos]
created_at: "2026-09-27 09:53:43"
status: active
---

# hitl-hermes-release-session

Date: 2026-09-27. Context: end-to-end delivery of the ace-hitl 0.10.0 + ace-hitl-hermes 0.1.0 release (Forgejo PRs #29/#30 → single worktree integration → GitHub PR #336 → merge → publish → propagation proof → task-tree closure), executed in one agent session alongside a concurrently active second session.

## What Went Well

- **Verification-first onboarding:** every claim from the task brief was checked against live state before acting — Forgejo PR content recovered via `git ls-remote fg refs/pull/N/head` after the head branches vanished from `refs/heads`, and the referenced release task `8wq.t.1c9` turned out not to exist locally, so an equivalent (`8wq.t.1zy`) was created instead of guessing.
- **Merge gate executed honestly:** both PRs combined in one worktree with zero file overlap, full monorepo suite + independent reviewer verdict before declaring ready-to-merge; PR #336 merged with full history preserved (admin merge per standing practice).
- **Two-tier review paid off:** the codex astra high round found 9 correctness defects that the earlier fast review had APPROVED (TOCTOU in delivery, creation/projection race, shell invocation via single-string argv, symlink traversal in poll, process-group escape on timeout, literal-substitution, UTF-8 bounds, publish byte gate, schema parity). All 10 valid findings fixed with per-item commits; 9 executable probes reproduced the bugs before fixing and were ported into package regression suites (ace-hitl 167→174 tests, ace-hitl-hermes 65→68).
- **Platform bug caught pre-release:** lifecycle tests used Linux-only `/bin/true`//`/bin/false`; on macOS the real spawn escalated with ENOENT and one test passed "for the wrong reason". Fixed with `[RbConfig.ruby, "-e", "exit N"]` and now guarded by regression tests.
- **Publisher UX improved by captain's request and used in anger:** `--interactive` (silent TTY OTP prompt), `--otp <value>`, and the prepared-queue manifest. The live publish was one command, 2 gems in 2 dependency waves, 3.8s, OTP never in argv/chat.
- **Honest propagation proof:** TS-MONO-001 blocked by the known macOS sandbox leak; classification SAFE earned via the documented clean-room bundle proof (exact-version resolution of both gems on clean Ruby 3.2.2), artifact written, primary scenario explicitly recorded as locally unverified.
- **Task hygiene completed without being asked twice:** release tree (`8wm.t.vs1`, `8wm.t.y21`, `8wq.t.1zy`) closed and archived, three stale tasks closed with verified evidence (`8wq.t.3e2` — ace-llm 0.41.0 already shipped; `8vt.t.rtr` — superseded; `8w3.t.1vd` — GLM 5.3 verified in `pi.yml`), done-only archive sweep.

## What Could Be Improved

1. **Two self-inflicted state mistakes mid-session:** a "baseline" test run executed in the worktree instead of the main checkout (persistent `cd` in the shell), and fix commit #2 landed with a `NameError` and needed an amend. Both caught within a turn, but each cost time inside a live session; a pre-commit probe/verification pass would have prevented the amend.
2. **Severity calibration of the fast review was too soft:** the first (Explore-based) review correctly *spotted* two concurrency families (hermes atomic-writer rename-overwrite, poll/ack ENOENT windows) but rated them non-blocking; the deep review's probes proved real correctness impact. The hermes writer TOCTOU is STILL deferred (to `8wm.t.vs2`) — that decision deserves a fresh look with the probe technique.
3. **Forgejo-side closure has no owner:** after the rebase flattened merge topology, Forgejo PRs #29/#30 cannot auto-close when #336 lands; they still need an explicit UI merge/close (content identical, plus hardening). Nothing in the session flow owned this — it survives only as a chat note.
4. **Publisher manifest shipped with a symbol-key YAML bug the captain hit on first live use:** the validation battery covered option guards and prepare, but never exercised a live-mode manifest read (safe_load round-trip). One negative-path test would have caught it before the operator saw it.
5. **Concurrent-session near-misses were handled ad-hoc:** origin/main moved twice under the working branch (once mid-rebase-preparation), and remote-tracking refs updated mid-command by the second session's fetch. Coordination relied on the captain relaying; the fix commits after "wait with commit" still raced his instruction (one commit had already pushed).

## Key Learnings

- Forgejo PRs are fully inspectable over git alone: `refs/pull/N/head` persists after the source branch is deleted; fetch it to a local ref for inspection/merge. No API token or `tea` needed for merge planning.
- macOS process semantics: no `/bin/true`//`/bin/false`; `Process.spawn` with a single-string argv uses shell command-string semantics — `[cmd, argv0]` forces exec; `kill(-pgid)` raises EPERM (not just ESRCH) when the group's remaining members are zombies.
- `YAML.safe_load_file` rejects Symbol keys — any serialized manifest must be string-keyed; test the round-trip, not just the write.
- Host tooling resolves from INSTALLED gems (this session's `ace-bundle wfi://git/rebase` loaded from ace-git 0.23.0 while the repo carried newer code) — repo-side workflow/doc changes are invisible to host runs until released or `bin/`-wrapped.
- Installed ace-task has no `done` command: `ace-task update <id> --set status=done --move-to archive`; `docs/tools.md` table is stale on this point.
- Review cycle analysis (11 findings, codex astra high): 10 valid → all fixed; 1 valid-deferred (task `8wq.t.34i`); 0 false positives among the 9 executed probes (9/9 reproduced pre-fix). Deep-model-with-probes found qualitatively different issues (reproduceable races) than the fast review (style-adjacent + two correctly-spotted-but-misranked concurrency items).

### Tool Proposals

- Promote `.ace-bin/ace-rubygems-publish --interactive` to the documented default publish path in `as-release-rubygems-publish` examples (env-var dance remains the fallback); consider wrapping the readiness-only HITL path around it.
- Add a negative-path publisher test: live mode with manifest present and empty/invalid OTP must abort before any push and keep artifacts (would have caught the symbol-key bug).

## Action Items

### Stop Doing

- Running comparison/baseline suites without pinning the checkout explicitly in the same command (`cd <checkout> && ace-test ...`), and committing mid-fix sequences before the verification probe confirms the fix.

### Continue Doing

- Two-tier review for concurrency/security-sensitive code: fast triage pass, then a deep model run WITH executable probes before merge; port surviving probes into package regression suites.
- Clean-room propagation proof per release (per `ace-handbook/docs/release-rubygems-proof.md`) with honest classification when TS-MONO-001 is sandbox-blocked.

### Start Doing

- Draft the task for the macOS TS-MONO-001 sandbox fix (gate `BwrapSandboxBackend` on `supported?`; self-healing `ensure_no_global_ace_gems!` message) — retro 8wqe8b lists it, still undrafted.
- Close Forgejo PRs #29/#30 explicitly (merge or close-with-pointer to #336) once the captain decides the fg-side mechanism; record the decision in `[[ace-remote-sync-layout]]`.
- Before declaring a UX-facing script change done, exercise its failure paths once (manifest read, missing OTP, stale artifact) — the operator should never be the first to hit them.
