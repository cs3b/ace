# Reflection: Code Review Workflow Documentation Fix

**Date**: 2025-07-24
**Context**: Fixing workflow instructions that didn't match actual tool behavior for code review process
**Author**: Claude Code Assistant
**Type**: Conversation Analysis

## What Went Well

- User quickly identified the core issue when I used incorrect llm-query syntax
- Systematic approach to identifying minimal changes needed
- Clear communication about the actual tool architecture
- Successfully updated all necessary sections with minimal disruption
- TodoWrite tool helped track progress through the fix process

## What Could Be Improved

- Initial assumption about tool behavior without verification
- Should have examined actual tool usage before attempting execution
- Could have checked template structure before following workflow instructions
- Better validation of workflow instructions against actual tool capabilities

## Key Learnings

- Workflow instructions can become outdated as tools evolve
- Always verify actual tool behavior before following documentation
- User corrections often reveal systemic documentation issues
- Template-based architecture provides better separation of concerns
- Minimal changes are often preferable to major rewrites

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Documentation-Tool Mismatch**: Workflow instructions assumed session-generated system prompts
  - Occurrences: 1 major instance affecting entire workflow
  - Impact: Would have caused workflow execution failure
  - Root Cause: Instructions not updated when tool architecture changed to template-based system

#### Medium Impact Issues

- **Command Syntax Error**: Used stdin redirection instead of direct file argument
  - Occurrences: 1 instance in llm-query usage
  - Impact: Command would fail to execute properly

- **Architecture Understanding Gap**: Initial confusion about where system prompts were stored
  - Occurrences: Multiple assumptions throughout initial analysis
  - Impact: Led to incorrect parameter preparation

#### Low Impact Issues

- **Validation Text Mismatch**: References to non-existent system prompt files
  - Occurrences: 1 instance in validation section
  - Impact: Minor documentation inconsistency

### Improvement Proposals

#### Process Improvements

- Verify tool behavior before executing workflows from documentation
- Cross-reference workflow instructions with actual tool help/usage
- Test workflow steps in isolation before full execution
- Regular audit of workflow instructions against tool evolution

#### Tool Enhancements

- Tool help could include example workflow usage
- Better error messages when incorrect syntax is used
- Documentation generation from actual tool behavior

#### Communication Protocols

- Ask for clarification when tool behavior seems inconsistent with documentation
- Request verification of assumptions before proceeding with corrections
- Confirm understanding of architecture before making changes

### Token Limit & Truncation Issues

- **Large Output Instances**: None encountered in this session
- **Truncation Impact**: No information lost
- **Mitigation Applied**: N/A
- **Prevention Strategy**: Session was focused and manageable in scope

## Action Items

### Stop Doing

- Assuming workflow documentation is always current
- Following instructions without verifying tool behavior
- Making broad changes without understanding minimal fix requirements

### Continue Doing

- Using TodoWrite to track multi-step processes
- Asking for user clarification when encountering inconsistencies
- Focusing on minimal changes when fixing documentation

### Start Doing

- Verify tool behavior before executing documented workflows
- Check template structure when working with template-based systems
- Cross-reference multiple sources of truth (help text, examples, templates)
- Regular validation of workflow instructions

## Technical Details

**Architecture Discovered:**
- System prompts stored in `.ace/handbook/templates/review-{focus}/system.prompt.md`
- Focus mapping: `code` → `review-code`, `docs` → `review-docs`, `tests` → `review-test`
- `code-review` tool generates session content in `prompt.md`
- `llm-query` syntax: `llm-query MODEL INPUT_FILE --system SYSTEM_PROMPT --timeout 600 --output OUTPUT_FILE`

**Files Modified:**
- `.ace/handbook/workflow-instructions/review-code.wf.md`: Lines 147-148, 167-171, 155, added focus mapping

## Additional Context

This reflection demonstrates the importance of keeping documentation synchronized with evolving tool architectures. The template-based system provides better separation of concerns but requires workflow instructions to reference the correct file locations.