---
id: 8nf000
title: Unified Subject Resolution - Wrong Approaches Analysis
type: conversation-analysis
tags: []
created_at: "2025-12-16 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8nf000-unified-subject-resolution-wrong-approaches.md
---
# Reflection: Unified Subject Resolution - Wrong Approaches Analysis

**Date**: 2025-12-16
**Context**: Task 145.02 - Implementing unified subject syntax (type:value) in ace-review and fixing PR config duplication
**Author**: Claude Code Agent
**Type**: Conversation Analysis

## What Went Well

- Typed subject syntax (`pr:77`, `files:*.rb`, `diff:HEAD~3`) provides clean, unambiguous input
- Test-driven approach caught issues early with comprehensive test coverage
- Incremental commits allowed easy identification of which change broke what
- User feedback loop was fast - problems identified immediately after implementation

## What Could Be Improved

- Initial implementation had multiple code path issues that weren't caught until manual testing
- Removed code without fully tracing all call sites (process_template_config vs process_preset vs load_template)
- Assumed config would flow through single path when multiple entry points existed

## Key Learnings

- **Critical**: When removing functionality from a shared function, trace ALL callers to ensure alternative handling exists
- Context-loader has THREE distinct entry paths: `load_preset`, `load_template`, and `load_inline_yaml` - each needs consideration
- Config structure transformations (top-level vs nested) create hidden coupling between components

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Incomplete Code Path Analysis**: Removed PR handling from `process_template_config` without adding to `load_template`
  - Occurrences: 1 (but caused complete feature breakage)
  - Impact: `pr:77` subject produced empty output - feature completely non-functional
  - Root Cause: Assumed all config flows through `process_preset` which has `process_pr_config` call, but `load_template` calls `process_template_config` directly

- **Config Structure Mismatch**: First approach used top-level `pr:` key which duplicated existing context-nested handling
  - Occurrences: 1 (identified by user during review)
  - Impact: Two code paths doing same thing - maintenance burden and confusion
  - Root Cause: Didn't analyze existing config structure before adding new handling

#### Medium Impact Issues

- **Missing Integration Test**: Unit tests passed but end-to-end flow was broken
  - Occurrences: 1
  - Impact: Required manual testing to discover issue
  - Root Cause: Tests mocked ace-context calls, didn't test actual file → context → output flow

### Improvement Proposals

#### Process Improvements

- **Call Site Analysis Checklist**: Before removing code from shared functions, document ALL callers and verify each has alternative handling
- **Config Flow Diagram**: Maintain diagram showing how configs flow through ace-context entry points
- **Manual Smoke Test**: After structural changes, always run actual command (not just tests)

#### Tool Enhancements

- Add integration test that exercises `user.context.md → ace-context → user.prompt.md` flow
- Consider adding a "config flow tracer" that shows which processing functions handle a given config

#### Communication Protocols

- When user reports "nothing to review" or empty output, immediately check the intermediate files (user.context.md, user.prompt.md) to identify where the pipeline breaks

### Token Limit & Truncation Issues

- **Large Output Instances**: None significant in this session
- **Truncation Impact**: Previous context was summarized but key files were noted for re-reading
- **Mitigation Applied**: Read specific files as needed rather than relying on summarized context
- **Prevention Strategy**: Keep active working set small, use targeted reads

## Action Items

### Stop Doing

- Removing shared function code without tracing all callers
- Assuming single code path when multiple entry points exist
- Trusting unit tests alone for structural refactoring

### Continue Doing

- Incremental commits with clear descriptions
- Fast user feedback loop to catch issues early
- Using todo list to track multi-step changes

### Start Doing

- Create "code path analysis" before removing shared functionality
- Add integration test for full pipeline after structural changes
- Document config flow through ace-context entry points

## Technical Details

### The Three Entry Points

1. **`load_preset`** (line ~500): Loads from preset configs, calls `process_pr_config` at line 584
2. **`load_template`** (line ~395): Loads files with frontmatter, calls `process_template_config` → NOW calls `process_pr_config` at line 436
3. **`load_inline_yaml`** (line ~379): Parses inline YAML strings, calls `process_template_config` → NOW calls `process_pr_config` at line 386

### Config Structure Decision

Unified on context-nested pattern:
```yaml
# Valid (processed by process_pr_config)
context:
  pr: 77

# Invalid (removed from process_template_config)
pr: 77
```

### Files Changed

- `ace-context/lib/ace/context/organisms/context_loader.rb`: Removed top-level PR handling, added `process_pr_config` to `load_template` and `load_inline_yaml`
- `ace-review/lib/ace/review/molecules/subject_extractor.rb`: Changed `parse_typed_subject` to return context-nested config
- `ace-review/test/molecules/subject_extractor_test.rb`: Updated tests for context-nested expectations

## Additional Context

- Task: 145.02 - Unified Subject Resolution
- Related: Task 145.01 added initial pr: support at top-level (the duplication we removed)
- Commits: c960cb04, 8c23581f, 78a8eec1
