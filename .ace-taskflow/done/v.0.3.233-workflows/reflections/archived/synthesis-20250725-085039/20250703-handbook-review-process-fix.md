# Reflection: Handbook Review Process Fix

**Date**: 2025-07-03
**Context**: Fixed system prompt handling and output formatting in handbook review workflow
**Author**: Claude Code Session

## What Went Well

- **Clear problem identification**: User provided specific feedback about broken prompt construction and incorrect llm-query usage
- **Systematic approach**: Followed a structured plan to address each issue (system prompt separation, output flags, header compatibility)
- **Multi-repo workflow**: Successfully used `bin/gc` multi-repository commit process for atomic changes across submodules
- **Comprehensive validation**: Verified that system prompts don't expect specific headers from user input, ensuring compatibility
- **Documentation consistency**: Updated both workflow instructions and command implementations to maintain consistency

## What Could Be Improved

- **Initial testing**: Should have tested the handbook-review process before considering it complete
- **Shell redirection patterns**: Using `> file.md 2>&1` instead of proper `--output` flag showed lack of familiarity with llm-query best practices
- **System prompt embedding**: Initially tried to embed system prompts in user prompts rather than using the proper `--system` flag separation

## Key Learnings

- **llm-query architecture**: System prompts should always be passed via `--system` flag, not embedded in user content
- **Output handling**: Use `--output` flag instead of shell redirection for better error handling and file management
- **Header format standards**: User prompts should use clean headers like "PROJECT CONTEXT" and "FOCUS REVIEW" without contamination from system prompt artifacts
- **Multi-repo commits**: The `bin/gc -i "intention"` command handles all repositories automatically and generates appropriate commit messages for each repo
- **Template compatibility**: System prompt templates are designed to accept unstructured input, not specific header formats

## Action Items

### Stop Doing

- Embedding system prompts directly in user prompt files
- Using shell redirection for llm-query output
- Assuming system prompts expect specific header formats from users

### Continue Doing

- Using structured todo lists to track multi-step fixes
- Validating changes across all related files
- Following the established workflow instruction patterns
- Using multi-repo commit commands for atomic changes

### Start Doing

- Testing handbook commands immediately after implementation
- Verifying llm-query flag usage against help documentation
- Checking system prompt compatibility when changing user prompt structure
- Using proper `--output` and `--system` flags consistently

## Technical Details

**Files Modified:**

- `.ace/handbook/workflow-instructions/review-code.wf.md`: Added system prompt parameter handling and --output flag usage
- `.claude/commands/handbook-review.md`: Fixed prompt construction and updated llm-query calls

**Key Changes:**

- Separated system prompts from user prompts using `--system` flag
- Updated prompt headers to use "PROJECT CONTEXT" and "FOCUS REVIEW"
- Replaced shell redirection with `--output` flag
- Added system prompt path parameter handling for combined reviews

## Additional Context

This fix addresses the fundamental architecture of how system prompts and user prompts interact in the review workflow, establishing a clean separation that will benefit all future review implementations.
