# Reflection: Handbook Review Workflow - System Prompt Improvements

**Date**: 2025-07-05
**Context**: Execution of handbook-review command for all 20 workflow instruction files with GPRO analysis
**Author**: Development Session
**Type**: Conversation Analysis

## What Went Well

- Successfully executed comprehensive review of all 20 workflow instruction files (309KB content)
- Generated structured session directory with organized outputs (`docs-handbook-workflows-20250705-173751`)
- Produced meaningful GPRO analysis (12KB structured report) with extended timeout handling
- Proper project context loading from documentation files
- Effective session management with metadata tracking and file organization

## What Could Be Improved

- **System Prompt Handling**: Currently including system prompt content in combined prompt file instead of using proper `--system` flag
- **Tool Parameter Knowledge**: Missing awareness of `--system` parameter for llm-query tool
- **User Guidance Requirements**: Required multiple user corrections for basic implementation details
- **Initial Implementation Approach**: Made assumptions about tool usage without checking available parameters

## Key Learnings

- **LLM Query Tool Capabilities**: The `llm-query` tool supports `--system` parameter for proper system prompt separation
- **Combined Prompt Optimization**: System prompts should be handled separately to avoid bloating combined prompts
- **User Feedback Integration**: Real-time user corrections are critical for proper workflow execution
- **Timeout Handling**: Extended timeout (`--timeout 500`) is essential for large content analysis

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **System Prompt Architecture Flaw**: Including system prompt in combined prompt file
  - Occurrences: 1 major implementation error
  - Impact: Unnecessary prompt bloat, incorrect tool usage pattern
  - Root Cause: Lack of knowledge about `--system` parameter in llm-query tool

#### Medium Impact Issues

- **User Corrections Required**: Multiple instances where user had to correct approach
  - Occurrences: 3 corrections (head -10 limitation, wrong model name, missing timeout)
  - Impact: Workflow interruptions, multiple iterations needed
  - Root Cause: Making assumptions without validation

#### Low Impact Issues

- **Tool Parameter Discovery**: Learning tool capabilities through trial and error
  - Occurrences: Multiple small adjustments
  - Impact: Minor inefficiencies in execution flow

### Improvement Proposals

#### Process Improvements

- **System Prompt Separation**: Modify review workflow to use `--system` flag instead of including in combined prompt
- **Tool Parameter Documentation**: Better understanding of available llm-query parameters
- **Validation Steps**: Check tool capabilities before implementation

#### Tool Enhancements

- **Review Workflow Update**: Modify `review-code.wf.md` to use proper system prompt handling
- **Combined Prompt Optimization**: Remove system prompt from combined prompt generation
- **Parameter Documentation**: Document all available llm-query parameters and usage patterns

#### Communication Protocols

- **User Confirmation**: Confirm approach before executing complex workflows
- **Parameter Validation**: Verify tool parameters before implementation
- **Real-time Feedback**: Incorporate user corrections immediately

### Token Limit & Truncation Issues

- **Large Output Instances**: None encountered in this session
- **Truncation Impact**: No truncation issues with current approach
- **Mitigation Applied**: Successfully used `--timeout 500` for large content processing
- **Prevention Strategy**: Continue using extended timeouts for comprehensive reviews

## Action Items

### Stop Doing

- Including system prompt content in combined prompt files
- Assuming tool parameter knowledge without verification
- Using arbitrary limitations (like `head -10`) without user confirmation

### Continue Doing

- Structured session directory creation with metadata
- Comprehensive content aggregation for review
- Extended timeout usage for large content processing
- Real-time user feedback integration

### Start Doing

- Use `--system` flag for proper system prompt separation in llm-query
- Validate tool parameters before implementation
- Document proper usage patterns for future reference
- Create system prompt optimization in review workflow

## Technical Details

**Current Implementation Issue:**
```bash
# WRONG: Including system prompt in combined prompt
cat system-prompt.md >> combined-prompt.md
dev-tools/exe/llm-query gpro "$(cat combined-prompt.md)"
```

**Corrected Implementation:**
```bash
# CORRECT: Using --system flag for proper separation
dev-tools/exe/llm-query gpro --system system-prompt.md --timeout 500 "$(cat content-prompt.md)"
```

**Key Files Modified:**
- Session directory: `dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/`
- Review output: `gpro-review.md` (12KB structured analysis)
- Input content: `input.md` (309KB workflow content)

## Additional Context

- **Session Reference**: `docs-handbook-workflows-20250705-173751`
- **Workflow Files Reviewed**: 20 files in `dev-handbook/workflow-instructions/`
- **Review Focus**: Documentation quality and consistency
- **Analysis Method**: GPRO only (no synthesis as requested)

**Next Steps:**
1. Update `review-code.wf.md` to use proper system prompt handling
2. Document llm-query parameters and usage patterns
3. Test corrected implementation with future reviews