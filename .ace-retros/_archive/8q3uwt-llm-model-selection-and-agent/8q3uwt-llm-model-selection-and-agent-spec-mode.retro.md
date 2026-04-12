---
id: 8q3uwt
title: llm-model-selection-and-agent-spec-mode
type: standard
tags: [llm, planning, review, workflow, agent]
created_at: "2026-03-04 20:36:28"
status: active
task_ref: 8c0.t.05p
---

# llm-model-selection-and-agent-spec-mode

## What Went Well
- Running the same planning task (`05p`) across `gemini:pro-latest`, `codex:codex`, and `claude:opus` exposed concrete provider behavior differences instead of relying on assumptions.
- Prompt-contract tightening (required headings, anti-permission/status-only rules) improved plan output quality for Gemini and Codex.
- Using provider-specific plan CLI args (`task.plan.cli_args`) gave a clear mechanism to enforce planning-only execution constraints.

## What Could Be Improved
- Provider choice by task type was not explicit enough up front; review and planning used mixed defaults before evidence was gathered.
- Review presets still included Gemini/GPro even after evidence showed weaker review signal for this task set.
- We only have `agent/plan-mode`; there is no equivalent spec-only mode to prevent implementation output when the goal is writing a specification.

## Key Learnings
- Model performance is task-dependent in this repo:
  - `gemini:pro-latest` performed best for plan artifact generation.
  - `codex:codex` and `claude:opus` produced stronger review feedback than Gemini for the same change set.
- Prompt composition via `tmpl://` + `wfi://` + `ace-bundle` is effective, but strict output contracts are still required to prevent mode drift.
- "Planning mode" and "spec drafting mode" are distinct operating modes and should have separate templates/contracts.

## Action Items
- [ ] Create ADR proposal for `tmpl://agent/spec-mode` with explicit "spec artifact only" constraints and anti-implementation rules.
- [ ] Add `wfi://task/spec` (or equivalent) workflow output contract aligned with `agent/spec-mode`.
- [ ] Add regression tests validating required headings/sections for both plan-mode and future spec-mode templates.
- [ ] Keep default provider routing explicit by intent:
  - Planning default: `gemini:pro-latest`
  - Review defaults/presets: Codex/Claude set, no Gemini unless explicitly opted in
- [ ] Add a short provider-selection matrix to docs (`planning`, `review`, `spec drafting`) so mode/model choices are intentional.
