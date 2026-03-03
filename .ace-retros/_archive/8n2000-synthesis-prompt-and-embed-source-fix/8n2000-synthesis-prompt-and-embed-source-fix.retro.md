---
id: 8n2000
title: Synthesis Prompt Loading and Model Selection
type: conversation-analysis
tags: []
created_at: '2025-12-03 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8n2000-synthesis-prompt-and-embed-source-fix.md"
---

# Reflection: Synthesis Prompt Loading and Model Selection

**Date**: 2025-12-03
**Context**: Debugging synthesis prompt loading issues and comparing synthesis models
**Author**: Development Session
**Type**: Conversation Analysis

## What Went Well

- Systematic debugging approach: evaluated synthesis output, traced to empty system prompt, found root cause
- Comparative testing of 3 synthesis models (gflash, sonnet, opus) with same inputs
- Quick iteration using `ace-review synthesize --session` to test prompt changes without re-running full reviews
- User identified the empty prompt file quickly, accelerating diagnosis

## What Could Be Improved

- Initial synthesis prompt updates didn't take effect because the prompt wasn't being loaded correctly
- Ran full multi-model reviews multiple times before discovering `--session` option for faster iteration
- Test files accumulated during debugging (17 files) - should clean up more proactively

## Key Learnings

### ace-context `embed_source` Option

**Critical Discovery**: When using `Ace::Context.load_file()` with files that have `presets:` in frontmatter, the `embed_source: true` option is REQUIRED to include the source file content in the output.

```ruby
# Without embed_source - only processes presets, source content is LOST
result = Ace::Context.load_file(context_file)  # Returns nearly empty content

# With embed_source - includes source content + preset processing
result = Ace::Context.load_file(context_file, embed_source: true)  # Works correctly
```

**Root Cause**: The synthesis prompt file had:
```yaml
context:
  presets:
    - project-base
```

This caused ace-context to process the preset but not include the actual prompt content.

### Synthesis Model Comparison

Tested 3 models on identical inputs:

| Model | Format Compliance | Detail Level | Empty Report Handling |
|-------|-------------------|--------------|----------------------|
| gemini-2.5-flash | Good | Moderate | Missed |
| claude:sonnet | Excellent | High (12 unique insights) | Correctly noted |
| claude:opus | Good | Good (10 unique insights) | Noted |

**Conclusion**: claude:sonnet is best for synthesis - most thorough, correctly identifies anomalies (empty reports), and resolves conflicts explicitly.

### Prompt Strengthening Techniques

What worked to improve LLM format compliance:
1. "DO NOT" instructions at the top with explicit prohibitions
2. "REQUIRED OUTPUT STRUCTURE" with exact section headers
3. "WHAT NOT TO DO" section with specific anti-patterns
4. Making it clear this is a one-shot generation task, not a conversation

## Action Items

### Stop Doing

- Calling `Ace::Context.load_file()` without `embed_source: true` when the file uses presets

### Continue Doing

- Using `ace-review synthesize --session` for rapid iteration
- Comparative model testing before selecting defaults
- Checking intermediate files (`.prompt.md`) when output is unexpected

### Start Doing

- Document `embed_source` requirement in ace-context usage patterns
- Consider adding a warning when preset files are processed without `embed_source`

## Technical Details

Files modified:
- `ace-review/lib/ace/review/molecules/report_synthesizer.rb` - Added `embed_source: true` to both `prepare_system_prompt` and `prepare_user_prompt`
- `ace-review/handbook/prompts/synthesis-review-reports.system.md` - Strengthened format requirements
- `.ace/review/config.yml` and `ace-review/.ace.example/review/config.yml` - Changed synthesis model to `claude:sonnet`

## Additional Context

- Task: 126.02 - Report Synthesis
- Branch: 126.02-report-synthesis
- Related commit: fix(ace-review): Fix synthesis prompt loading with embed_source option