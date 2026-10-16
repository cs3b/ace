---
doc-type: workflow
name: design-explore
description: Generate comparable mockups through preset-driven coding agents
allowed-tools:
  - Bash(ace-design:*)
  - Bash(ace-bundle:*)
  - Bash(bin/ace-design:*)
  - Bash(bin/ace-bundle:*)
  - Read
purpose: Reach an explicit user-selected direction through the CLI runner
title: Explore design directions
---

# Explore design directions

Reach an explicit user-selected visual direction quickly. The invoking skill binds `surface=site` or `surface=app`; retain it. Native interfaces are outside this workflow.

## Prepare a small brief

Use the user's request, relevant brand/tokens and the entry screen context. Do not scan the whole repository or start a code review. Infer audience, primary action and one language; ask only blocking questions. Select a few relevant knowledge cards if useful. No external account is required for references.

## Choose intent and preset

Use `ace-design explore --surface SURFACE --prompt BRIEF` for new directions, `ace-design recreate --surface SURFACE --from SOURCE` for faithful reproduction, or `ace-design reimagine --surface SURFACE --from SOURCE` for the same functions with a new appearance. SOURCE accepts an image, HTTP(S) URL or `session:TOKEN/VARIANT`. Do not replace faithful reproduction with creative redesign. Images and URLs cannot establish every interaction; label assumptions.

For a session source, inherit its effective brief unless the user requests a replacement via `--prompt`. Use repeatable `--prompt-append TEXT` for global additions in order, and `--variant-prompt ID=TEXT` for a single variant. Check the composed brief in dry-run.

Choose `--kind view|component` and optional `--profile SURFACE/KIND/NAME`. Read effective assumptions through `ace-design profile show`; use the matching adjust skill when project intent changes. The runner freezes the effective design.md. Pass small relevant references through repeatable `--input`; do not automatically load the whole project. Use `--fixtures FILE` for existing common data.

Read `ace-design preset list` and `ace-design preset show NAME` when choosing an external process. The catalog is the source of truth for source revisions, strengths, compatibility, tools, limitations and verification. `candidate` is not evidence of successful integration. Use `--preset NAME_OR_FILE` to select a process or a comparison. Do not silently adapt unsupported external skills or skip their original checks. Default `fast` is lightweight ACE design; external processes retain their requirements and may take longer or produce images/remote results.

Single-process presets create three directions for explore/reimagine, one for recreate; comparison presets declare their own list. The runner launches one coding worker per variant; no extra chat subagent is needed. `--model` overrides preparation and all worker models. Guide slots with repeatable `--variant-prompt 'ID=TEXT'` or `--variant-prompt-file 'ID=PATH'`; preserve intent and shared data. Use `--dry-run --json` to inspect resolved inputs without model calls or creating a session. Execute by rerunning without dry-run.

The runner saves a Base36 session with frozen source, actual image files, shared functional analysis, original pinned skill resources, exact prompts, fixtures and attempts. For ACE fast, keep plain HTML/CSS/JS, one language and local mocked interactions. External presets follow their original workflow; do not impose ACE's fast-process constraints on them. Production integration remains a separate user request.

## Show and collect feedback

Run `ace-design preview SESSION`, open the loopback URL, and perform one quick render check for broken/empty content. Preview needs Node, not Playwright. Present ready directions with one sentence each. Use `ace-design status SESSION` for exact worker status; incomplete runs retain successful variants. `ace-design resume SESSION` retries only unfinished workers using saved inputs.

Interpret user feedback and call `ace-design revise SESSION --variant b --prompt 'Less dense; preserve the hierarchy'`. For combining directions, describe the desired borrowed details in the targeted prompt. The runner retains prior versions and records feedback; failed revisions preserve the usable publication. It does not modify other variants or shared fixtures. Changed shared content requires a new session. Do not hand-edit runner-owned publications or saved shared inputs.

## Select and hand off

Only after the user chooses, run `ace-design select SESSION --variant b --decision 'Keep split layout' --decision 'Replace mocked records during implementation'`. Selection is bound to the exact variant and shared-fixture hashes. Successful revision of the selected variant invalidates that selection; ask for a new explicit choice.

Hand off to the matching site/app implementation skill only when implementation is requested. A pending choice is a normal checkpoint. Production engineering handles actual data, states, languages, integrations, tests and independent review after selection.

## Failure handling

Use the saved per-worker error and attempt path. Preserve completed mockups; do not regenerate everything to retry one failure. Configure a suitable coding CLI provider through ace-llm if the model is unavailable. Do not bypass provider execution policy. Working-directory separation is an organizational boundary, not a security sandbox. Missing Node prevents preview, not generation. Incomplete generation is reported as incomplete, never as three successful directions.
