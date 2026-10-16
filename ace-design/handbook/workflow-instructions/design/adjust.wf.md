---
doc-type: workflow
name: design-adjust
description: Personalize and refresh inherited project design assumptions
purpose: Preserve user intent while updating installed design defaults
allowed-tools:
  - Bash(ace-design:*)
  - Bash(ace-bundle:*)
  - Bash(bin/ace-design:*)
  - Bash(bin/ace-bundle:*)
  - Read
  - Edit
  - Write
---

# Adjust project design assumptions

## Goal

Compose effective design assumptions from library defaults and explicit user decisions, preserving project intent across library updates.

## Prerequisites

The invoking skill binds `surface=site` or `surface=app`. Work from the intended project directory. Determine whether the task concerns a view or a component; preserve that kind and any explicitly named context. Existing ace-llm coding-provider configuration supplies execution permissions and the default model.

## Project Context Loading

Read only the relevant `.ace-config/design/` context chain, the user's requested changes and any explicitly supplied brand references. Each context has `defaults.md`, `user.md` and generated `design.md`. Use `ace-design profile show --surface SURFACE --kind KIND --profile ID` to read the currently effective assumptions when available. Do not audit the repository or generate mockups as part of adjustment.

## High-Level Execution Plan

- [ ] Bind the surface, task kind and intended context.
- [ ] Compose or refresh, then inspect the diff and conflict report.
- [ ] Verify effective context resolution and report stale dependents.

## Process Steps

1. **Choose the context.** For a branch-wide change use `ace-design profile adjust --surface SURFACE`. For a named task use `--kind view|component --profile SURFACE/KIND/NAME`. Without an explicit context the prompt belongs to the surface node and affected contexts in the surface branch are recomposed; fresh ancestors remain byte-identical. The shared project node is inherited; the other surface can become stale if shared assumptions change.
2. **Apply an explicit preference.** Pass the user's decision using `--prompt TEXT`. The command appends that exact decision to the target's user history; the composer interprets explicit newer overrides while retaining the original text. Existing user-authored text is never rewritten by the model. Use `--propose` to invoke the composer and save an unpublished proposal. `--dry-run` only resolves inputs; it performs no model calls or writes.
3. **Refresh installed guidance.** For a library update use `ace-design profile refresh --surface SURFACE`. Do not combine refresh with a prompt. Refresh updates the local defaults from the installed package and preserves all existing user.md bytes. It does not install packages or fetch remote code.
4. **Read the report.** Inspect the printed report directory: report.md, changes.diff and worker/result.json. Explain added rules, preserved exceptions and omitted defaults. The effective design includes both synthesis and verbatim authoritative user decisions. Check that the user's intent survived; hashes establish provenance, not semantic correctness.
5. **Resolve ambiguity.** A conflict leaves the current tree active. Ask the specific reported question and rerun with the user's explicit clarification. For a manually edited generated design.md, first preserve the desired change in user.md and restore the generated file from version control or the prior adjustment's candidate/previous evidence; never silently discard manual edits or update its hash to bypass detection.
6. **Verify consumption.** Read the effective document with `ace-design profile show`. Recompose any reported stale dependent contexts before generating from them. Do not regenerate existing mockups: their saved design.md remains fixed for resume/revise.

## Success Criteria

The requested contexts are published coherently or the previous complete tree remains active with a concrete conflict/failure report. User decisions remain present, refresh preserves user bytes, changes are inspectable and effective context resolution succeeds. Source profiles may be committed through the project's normal workflow; adjustment itself never commits, selects a design or starts engineering.

## Error Handling

Invalid context/type: correct the ID to match the bound surface and kind. Stale local sources: run adjust; do not regenerate from stale design.md. Concurrent edits: retain them and rerun against the new inputs. Interrupted publication: the next context operation recovers the previous tree under the context lock. Provider failure: keep the report and retry explicitly; do not bypass provider policy.
