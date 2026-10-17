---
name: as-release-rubygems-publish
description: Publish ACE gems to RubyGems.org in dependency order
# bundle: wfi://release/rubygems-publish
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(bundle:*)
  - Bash(gem:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[gem-name...] [--dry-run|--prepare]"
last_modified: 2026-10-17
source: ace-handbook
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers:
    claude:
      frontmatter:
        context: fork
        model: haiku
skill:
  kind: workflow
  execution:
    workflow: wfi://release/rubygems-publish
---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

None

## Execution

- You are working in the current project.
- Run `ace-bundle wfi://release/rubygems-publish` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- When the workflow requires edits, tests, or commits, perform them in this project.
- OTP timing: build every pending `.gem` first, then ask for one OTP (~30–45s), then push in ≤5-concurrent dependency waves aiming to finish within ~30s; verify metadata only after the burst.
- Last-mile handoff: the agent shell is not the operator shell. Missing `GEM_HOST_API_KEY` / `~/.gem/credentials` (or no TTY) in the agent's subprocesses never means the operator is unconfigured — do not request credential setup. Finish the dry-run, state the wave plan, and hand off exactly `.ace-bin/ace-rubygems-publish --interactive` for the operator terminal (`--prepare` is optional; the live run re-resolves a stale prepared queue). If the operator explicitly authorizes agent-driven publishing, request one fresh OTP via `ace-hitl`/chat, wait for it, then run the publisher with `GEM_HOST_OTP_CODE` in the environment and never persist the OTP.
- Never re-run the publisher to confirm a completed release, and never replace the `TS-MONO-001` propagation proof with hand-rolled `bundle install` runs; if the agent runner is unavailable, report the blocked command and hand it off.

- After live publishing, recommend running `ace-test-e2e ace-monorepo-e2e TS-MONO-001` for installation verification.
