---
id: 8oa1ev
title: ace-context Chunking Improvements
type: conversation-analysis
tags: []
created_at: "2026-01-11 00:56:30"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8oa1ev-ace-context-chunking-improvements.md
---
# Reflection: ace-context Chunking Improvements

**Date**: 2026-01-11
**Context**: Refactoring ace-context chunking - moved ContextChunker from ace-support-core, renamed config keys, improved CLI output
**Author**: Claude Opus 4.5
**Type**: Conversation Analysis

## What Went Well

- **Thorough codebase exploration**: Used grep/read to fully understand the chunk_limit usage before making changes
- **Atomic commits**: Each logical change got its own commit (rename, move, output improvement, header fix)
- **Quick iteration on UX**: User feedback on CLI output led to two quick improvement iterations
- **Proper version bumping**: Used the release workflow correctly for both packages affected

## What Could Be Improved

- **Misleading documentation caught late**: The `chunk_limit` was documented as "characters" but actually counted lines - this mismatch existed for a while before being noticed
- **Two patches for one feature**: The chunked output improvement required 0.28.1 and 0.28.2 because the header was forgotten initially
- **Plan mode confusion**: Plan mode kept activating during execution, causing friction

## Key Learnings

- **Naming matters**: `chunk_limit` was confusing because it didn't indicate units (lines vs bytes vs characters). `max_lines` is immediately clear
- **Component placement**: If only one package uses a component, that component should live in that package, not in a shared library
- **Agent-friendly output**: When outputting file paths for agents to read, include all necessary paths directly rather than requiring agents to discover them via index files

## Action Items

### Stop Doing

- Documenting config values with wrong units (chunk_limit was "characters" but counted lines)

### Continue Doing

- Atomic commits for each logical change
- Quick UX iteration based on user feedback
- Proper release workflow with both package and main CHANGELOGs

### Start Doing

- Double-check output format for agent consumption before releasing
- Consider agent workflow when designing CLI output (direct paths > discovery patterns)

## Technical Details

**Key changes made:**
1. `chunk_limit` → `max_lines` rename (clarifies it's line-based, not byte-based)
2. Default changed from 150000 to 2000 lines (more practical)
3. ContextChunker moved from ace-support-core to ace-context (single consumer principle)
4. CLI output now shows chunk paths directly instead of index file path
5. Added stats header: "Context saved (2952 lines, 109.63 KB) in 2 chunks:"

**Files modified:**
- `ace-context/lib/ace/context/molecules/context_chunker.rb` (moved from ace-support-core)
- `ace-context/lib/ace/context/atoms/boundary_finder.rb` (moved from ace-support-core)
- `ace-context/lib/ace/context/commands/load.rb` (output formatting)
- `ace-context/.ace-defaults/context/config.yml` (max_lines config)
- `ace-support-core/lib/ace/core/atoms/template_parser.rb` (updated valid keys)

**Versions released:**
- ace-support-core: 0.19.1 → 0.20.0 (ContextChunker removed)
- ace-context: 0.27.1 → 0.28.2 (ContextChunker added, output improvements)
