---
id: 8wqfy9
title: ace-pi-loop-delivery-and-release
type: standard
tags: [ace-pi, release, overseer]
created_at: "2026-09-27 10:38:04"
status: active
---

# ace-pi-loop-delivery-and-release

Date: 2026-09-27
Context: Delivery of task 8wq.t.1vz (ace-pi /loop -- in-process overseer loop) end-to-end: plan generation unblock, implementation across ace-handbook + ace-handbook-integration-pi, version bumps, publisher fix, RubyGems publish, propagation proof, task closure.
Author: agent session (ZCode) + Captain
Type: Standard

## What Went Well

- **Owner-layer re-planning paid off.** The generated plan assumed a nonexistent `ace-pi` Ruby gem; STEP-01 inspection corrected the surface (pi = external coding-agent CLI; `/loop` = pi prompt template in `.pi/prompts/`) and the feature was delivered through the canonical→projection pipeline (ADR-027) instead of inventing a parallel gem. The plan artifact was corrected in place, keeping the checklist honest.
- **Workflow-mandated stop points worked.** Leaving the task `in-progress` for final delivery, and stopping at the OTP operator boundary, both produced clean handoffs -- the Captain ran one `--interactive` command and the agent resumed with verification.
- **Publisher no-OTP-echo contract is now actually enforced.** The pre-existing `feat` failure was diagnosed (reproduced on a clean tree via stash) as a real leak in the publisher's rejection message and fixed (`4fd5ca3fa`) *before* the tool was used for a live publish.
- **Release ran through the tested publisher end-to-end**: dry-run → fresh `--prepare` → operator `--interactive` burst → cleanroom propagation proof classified **SAFE** (both `bundle install` and `--full-index` in mise ruby@3.2.2, empty GEM_HOME; released pi gem verifiably ships `handbook/prompts/loop.md`).

## What Could Be Improved

- **`ace-task plan` provider breakage cost ~4 failed attempts.** Codex presets in the *installed* ace-llm (0.38.4) still passed `--full-auto` (removed in codex-cli 0.156.1); gemini (revoked tier) and claude (expired OAuth) fallbacks were also dead. A sibling memory suggested `--model zai:glm-4.7` but wasn't consulted first. Follow-up filed: 8wq.t.3e2 (publish ace-llm 0.40.0); interim user-level preset overrides in `~/.ace/llm/presets/codex/`.
- **`--prepare` silently reuses a stale `pending-queue.yml`.** The first prepare rebuilt the *morning's* already-published ace-hitl gems instead of the new queue -- a live run would have been a silent no-op. Only caught by reading the queue contents. (The memory note claiming a "graceful fresh-resolve fallback" was wrong; corrected.)
- **Plan-vs-reality mismatch is systematic for Kapitan backlog items.** Backlog names (`ace-pi`, `ace-herdr`) reference runtime integrations, not monorepo gems, but nothing in the task spec warns the planner; the LLM plan encoded the wrong target and had to be corrected by inspection.
- **A changelog edit was silently dropped from a commit** (Edit failed on unread file, the commit proceeded without it; caught only during the bump). Commit-then-verify would have caught it immediately.

## Action Items

- Start: before any `--prepare` for a new release, check/remove `.ace-local/rubygems-publish/pending-queue.yml` and read the printed queue before proceeding to OTP. (Done manually this session; make it a habit.)
- Start: consult existing memory/retro notes for known-broken toolchains (e.g. `ace-task plan` fallbacks) *before* burning attempts on the default path.
- Continue: verify commits with `git show --stat` right after `ace-git-commit` -- it splits multi-package changes into per-scope commits with its own messages.
- Consider: teach `ace-task plan` (or the backlog spec template) to name the real integration surface for runtime-named backlog items, so generated plans stop assuming monorepo gems (candidate spec-template note or 8wq.t.3e2 follow-up).
- Consider: make `--prepare` warn loudly (or refuse) when a queue file predates the current session / when all queued versions already exist remotely -- cheap guard inside `.ace-bin/ace-rubygems-publish` (candidate follow-up task).
