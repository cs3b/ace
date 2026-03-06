---
id: 8q4s4z
status: done
title: Composable Review Architecture
tags: [ace-review, architecture, composability]
created_at: "2026-03-05 17:15:00"
---

# Composable Review Architecture

## Problem

Current ace-review presets duplicate 20-30 lines of instruction config each. `code-valid.yml`, `code-fit.yml`, `code-shine.yml` all repeat the same format/tone/icons/context boilerplate -- only the focus-specific prompt references differ. Reviewers are coupled to LLM model strings with no way to configure thinking level, output limits, or reuse provider configs. The `focus` field on `Reviewer` is metadata-only -- it never influences the system prompt sent to the LLM.

## Solution

Split presets into composable parts so that **what to review** (focus), **who reviews it** (provider), and **how to compose a review run** (preset) are independent, reusable units.

### Directory Layout

```
.ace/review/
  reviewers/           # Focus + default providers (what to look for)
    correctness.yml    # -> prompt://focus/phase/correctness
    quality.yml        # -> prompt://focus/phase/quality + security + perf + ...
    polish.yml         # -> prompt://focus/phase/polish + docs
    security.yml       # -> prompt://focus/quality/security
    docs.yml           # -> prompt://focus/scope/docs
    tests.yml          # -> prompt://focus/scope/tests
    lint.yml           # type: tool, command: ace-lint
    github-pr.yml      # type: human, source: pr-comments

  providers/           # Reusable LLM configs (how to call it)
    cc-opus.yml        # model: claude:opus
    cx-codex.yml       # model: codex:codex
    cx-max.yml         # model: codex:max

  presets/             # Composition layer (thin: reviewers + subject + context)
    code-valid.yml     # reviewers: [correctness], subject: pr
    code-fit.yml       # reviewers: [quality]
    code-shine.yml     # reviewers: [polish]
    code-multi.yml     # reviewers: [correctness, quality, security]
    code.yml           # base shared_sections (format, tone, icons, context)

  config.yml           # Global defaults (unchanged)
```

## Success Criteria

- Reviewer definitions are standalone YAML files with focus URIs and default providers
- Provider definitions are standalone YAML files with model config and params
- Presets become thin composition layers referencing reviewers by name
- `shared_sections` in base presets eliminate boilerplate duplication across presets
- `Reviewer.enhance_system_prompt` (existing dead code) is wired into `MultiModelExecutor`
- Old presets with inline `instructions:` + `models:` keep working (backward compatible)

## Schemas

### Reviewer definition (`.ace/review/reviewers/correctness.yml`)

```yaml
name: correctness
description: "Logic errors, bugs, missing functionality"
type: llm                           # llm | tool | human | agent

focus:
  - "prompt://focus/phase/correctness"

weight: 1.0
critical: false

file_patterns:
  exclude: []

default_providers:
  - cc-opus
```

### Provider definition (`.ace/review/providers/cc-opus.yml`)

```yaml
name: cc-opus
model: "claude:opus"
description: "Deep reasoning, architecture analysis"
params:
  timeout: 600
  # Future: thinking_level, max_output_tokens, cli_args
```

### Preset (thin composition)

```yaml
# .ace/review/presets/code-valid.yml
description: "Correctness review"
presets: [code]                      # inherits shared_sections from code.yml
reviewers:
  - reviewer: correctness           # references reviewers/correctness.yml
bundle: "project"
```

```yaml
# .ace/review/presets/code.yml (base)
description: "Base code review configuration"
shared_sections:
  format:
    title: "Format Guidelines"
    files: ["prompt://format/detailed"]
  communication:
    title: "Communication Style"
    files: ["prompt://guidelines/tone"]
  visual_indicators:
    title: "Visual Indicators"
    files: ["prompt://guidelines/icons"]
  project_context:
    title: "Project Context"
    presets: ["project"]
```

## Backward Compatibility

Detection is key-based -- no breaking changes:

| `reviewers:` entry has | Resolution path |
|---|---|
| `reviewer: correctness` (string ref) | NEW: load from `reviewers/correctness.yml` |
| `model: "claude:opus"` (inline) | EXISTING: `Reviewer.from_preset_config` |
| `models: [a, b]` (legacy array) | EXISTING: wrap in default Reviewers |

## Resolution Flow

```
PresetManager.load_preset("code-valid")
  -> resolve presets: [code] -> inherits shared_sections
  -> detect reviewers: [{reviewer: "correctness"}]
  -> ReviewerResolver.resolve(entry, shared_sections)
       -> load reviewers/correctness.yml
       -> resolve providers: [cc-opus] -> load providers/cc-opus.yml
       -> build per-reviewer instructions: shared_sections + focus URIs
       -> return Reviewer(name, model, focus, system_prompt_additions, weight, critical)

MultiModelExecutor.execute_single_model
  -> system_prompt = reviewer.enhance_system_prompt(base_prompt)
```

## Two-Level Synthesis

**Level 1 -- within reviewer** (multiple providers, same focus):
`correctness` runs on cc-opus AND cx-max -> same instructions -> merge findings -> confidence = provider agreement

**Level 2 -- across reviewers** (multiple focuses):
correctness + quality + security -> different instructions -> deduplicate across focuses -> weight by reviewer importance -> order critical first

Existing `FeedbackSynthesizer` handles Level 2 via `reviewer_weight_map`, `derive_metadata`, `order_items`. Level 1 needs: tag reports by reviewer name (not model string) when multiple providers serve the same reviewer.

## Implementation Phases

### Phase 1: Reviewer definitions + per-reviewer prompts

New files:
- `ace-review/lib/ace/review/molecules/reviewer_resolver.rb`
- `ace-review/lib/ace/review/atoms/provider_resolver.rb`
- `.ace/review/reviewers/{correctness,quality,polish,security,docs,tests}.yml`
- `.ace/review/providers/{cc-opus,cx-max,cx-codex}.yml`

Modify:
- `models/reviewer.rb` -- detect `reviewer:` ref in `from_preset_config`, delegate to `ReviewerResolver`
- `molecules/multi_model_executor.rb:170` -- call `reviewer.enhance_system_prompt(system_prompt)`
- `molecules/preset_manager.rb` -- detect `shared_sections`, pass to reviewer resolution

### Phase 2: Slim presets + shared_sections

- Add `shared_sections` merging in PresetManager
- Convert code-valid/fit/shine to thin reviewer-reference format
- Old format still works

### Phase 3: Advanced

- Provider params (thinking level, output limits, cli_args)
- `model@preset` syntax in ace-llm
- Tool-type reviewers (ace-lint)
- Human-type reviewers (GitHub PR comments)
- Within-focus multi-provider synthesis

---

## Origin

Emerged from task-069 (weighted multi-dimensional synthesis) analysis of preset duplication and reviewer/provider coupling in ace-review.
