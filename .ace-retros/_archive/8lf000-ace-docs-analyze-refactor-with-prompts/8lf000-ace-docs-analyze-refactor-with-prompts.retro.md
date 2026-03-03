---
id: 8lf000
title: 'Retro: ace-docs Analyze Refactor with Prompt Externalization'
type: conversation-analysis
tags: []
created_at: '2025-10-16 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8lf000-ace-docs-analyze-refactor-with-prompts.md"
---

# Retro: ace-docs Analyze Refactor with Prompt Externalization

**Date**: 2025-10-16
**Context**: Major refactor of ace-docs analyze command based on user feedback - replaced misleading diff/analyze commands with unified analyze, added real LLM analysis, and externalized prompts using ace-nav protocol
**Author**: Claude with user guidance
**Type**: Conversation Analysis

## What Went Well

- **User-driven architecture improvement**: User immediately identified that analysis.md should contain actual analysis, not just formatted diff
- **Iterative refinement**: User caught missing protocol configuration (prompt-sources example and .ace copy) after initial implementation
- **Clean refactor**: Net code reduction (-254 lines) while adding significant new features
- **Protocol consistency**: Successfully aligned with existing ace-review and ace-git-commit patterns for prompt management
- **Comprehensive testing**: Both automated tests and manual validation confirmed functionality

## What Could Be Improved

- **Initial oversight on protocol setup**: Didn't proactively create prompt-sources configuration and .ace installation - had to be reminded by user
- **File extension question**: User had to ask why `.patch` vs `.diff` - could have proactively explained or documented the decision
- **Incomplete planning**: Initial plan didn't include saving prompts to cache - user had to explicitly request this

## Key Learnings

- **User feedback is critical for architecture decisions**: The insight that "analysis.md should be analysis, not formatted diff" completely changed the approach
- **Protocol infrastructure matters**: ace-nav protocol support requires both the code integration AND the discovery configuration files
- **Complete implementation checklist**:
  1. Code changes (prompts, commands)
  2. Protocol configuration (.ace.example)
  3. Installation to project root (.ace)
  4. Testing discovery (`ace-nav prompt://...`)

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Incomplete Protocol Setup (1 occurrence)**
  - **Impact**: Prompts not discoverable via ace-nav after initial implementation
  - **Root Cause**: Didn't follow complete pattern from other gems (ace-review, ace-git-commit)
  - **Resolution**: User caught this and asked about protocol configuration

#### Medium Impact Issues

- **Missing transparency features (1 occurrence)**
  - **Impact**: Initial implementation didn't save prompts to cache for debugging
  - **User correction**: "save the base prompt and system prompt you have used in the analyze folder"
  - **Resolution**: Added prompt-system.md and prompt-user.md to cache

- **File naming conventions (1 occurrence)**
  - **Impact**: User questioned `.patch` vs `.diff` extension choice
  - **User feedback**: "not sure why do we .patch instead of .diff extensions - ?"
  - **Resolution**: Renamed to `.diff` for clarity

#### Low Impact Issues

- **Plan mode interruptions (multiple occurrences)**
  - **Impact**: User had to interrupt ExitPlanMode tool calls to clarify direction
  - **Pattern**: Plan presentation happened before user finished explaining requirements
  - **Learning**: Wait for complete requirements before presenting plans

### Improvement Proposals

#### Process Improvements

- **Protocol integration checklist**: When integrating with ace-nav protocols:
  1. Create code integration (load via ace-nav)
  2. Create .ace.example/nav/protocols/[protocol]-sources/[gem].yml
  3. Copy to .ace/nav/protocols/[protocol]-sources/[gem].yml
  4. Test with `ace-nav [protocol]://... --list` and `--content`
  5. Document user override paths

- **Proactive pattern following**: When user mentions existing patterns (wfi:// example), immediately check other gems for complete implementation examples

- **Complete feature matrix**: When implementing "save X", think about full transparency:
  - Input (what was sent)
  - Output (what was received)
  - Configuration (what controlled the behavior)
  - Metadata (context about the operation)

#### Tool Enhancements

- **Protocol discovery helper**: Could add `ace-taskflow protocol check [gem]` to verify:
  - .ace.example configuration exists
  - .ace installation exists
  - ace-nav can discover resources
  - Example: `ace-taskflow protocol check ace-docs --protocol prompt`

#### Communication Protocols

- **Wait for complete context**: Before ExitPlanMode, ensure user has:
  - Stated the goal completely
  - Provided all relevant examples
  - Confirmed the approach
  - Example pattern: "Before I present the plan, is there anything else about X?"

- **Proactive questioning about patterns**: When user mentions existing implementations:
  - "I see ace-review has prompt-sources. Should I follow the same pattern including .ace.example and project root installation?"

### Token Limit & Truncation Issues

- **Large Output Instances**: None in this session (well-managed context)
- **Truncation Impact**: No truncation occurred
- **Mitigation Applied**: Focused reads with offset/limit parameters
- **Prevention Strategy**: Continue using targeted reads for large files

## Action Items

### Stop Doing

- Presenting plans before gathering complete requirements
- Implementing partial patterns (code without infrastructure)
- Assuming file naming conventions without user input

### Continue Doing

- Following user's architectural insights (analysis.md should contain analysis)
- Testing implementations thoroughly (both automated and manual)
- Checking other gems for consistent patterns (ace-review, ace-git-commit)
- Net code reduction while adding features (quality over quantity)

### Start Doing

- **Protocol integration checklist** when adding ace-nav support
- **Proactive pattern verification** by checking all similar implementations
- **Complete transparency features** (save all inputs/outputs/config for debugging)
- **Wait for confirmation** before ExitPlanMode when user is mid-explanation

## Technical Details

### Implementation Summary

**Phase 1: Task 073 Completion**
- Added ace-docs namespace accessors to Document model
- Implemented subject diff filtering with backward compatibility
- Implemented semantic validation with ace-llm-query
- Version: 0.3.3

**Phase 2: Analyze Command Refactor**
- Deleted old diff_command.rb and analyze_command.rb
- Created new unified AnalyzeCommand with real LLM analysis
- Renamed .patch → .diff extensions
- Direct Ace::LLM::QueryInterface integration (no subprocess)

**Phase 3: Prompt Externalization**
- Created handbook/prompts/document-analysis.system.md
- Split prompts: system (role/instructions) + user (data/context)
- Load via ace-nav with fallback
- Save both prompts to cache (prompt-system.md, prompt-user.md)

**Phase 4: Protocol Configuration**
- Created .ace.example/nav/protocols/prompt-sources/ace-docs.yml
- Copied to .ace/nav/protocols/prompt-sources/ace-docs.yml
- Verified ace-nav discovery working
- Version: 0.4.0

### Cache Structure Evolution

**Before:**
```
.cache/ace-docs/diff-{timestamp}/
  ├── repo-diff.patch     # Raw diff
  └── analysis.md         # Formatted diff (misleading name!)
```

**After:**
```
.cache/ace-docs/analyze-{timestamp}/
  ├── repo-diff.diff      # Filtered raw diff
  ├── prompt-system.md    # System prompt sent
  ├── prompt-user.md      # User prompt sent
  ├── analysis.md         # REAL LLM analysis
  └── metadata.yml        # Full session context
```

### User Override Support

Users can now customize at three levels:
1. **Gem default**: `ace-docs/handbook/prompts/document-analysis.system.md`
2. **Project override**: `.ace/handbook/prompts/document-analysis.system.md`
3. **User override**: `~/.ace/handbook/prompts/document-analysis.system.md`

Priority: User > Project > Gem

## Additional Context

**Related Commits:**
- `3be1921d` - feat(ace-docs): Complete subject diff filtering and semantic validation (task.073)
- `70c00f7b` - refactor(ace-docs): Replace diff/analyze with unified analyze command
- `c2164578` - feat(ace-docs): Add ace-nav prompt protocol support and save prompts to cache
- `f024524f` - feat(ace-docs): Add ace-nav prompt protocol configuration
- `dbd2acb6` - chore(ace-docs): bump minor version to 0.4.0

**Version Impact:** Minor bump (0.3.3 → 0.4.0) due to 3 new features

**Net Code Change:** +307 insertions, -561 deletions = **-254 lines** (25% reduction)

**Key User Quotes:**
- "ok, 1. diff is perfect (not sure why do we .patch instead of .diff extensions - ? )"
- "2. analysis.md should be already a analysis - a compact, but detailed list of what have changed"
- "save the base prompt and system prompt you have used in the analyze folder"
- "did you add example for protocol prompt, similar to wfi (/Users/mc/Ps/ace-meta/ace-docs/.ace.example/nav/protocols/wfi-sources/ace-docs.yml)"