# Retro: ace-review and ace-llm-query Integration Fix

**Date**: 2025-10-07
**Context**: Fixed ace-review's integration with ace-llm-query after API changes in ace-llm v0.9.1+
**Author**: Claude Code Session
**Type**: Conversation Analysis

## What Went Well

- **Systematic debugging approach**: Identified the issue by running ace-review with --auto-execute and capturing the error message
- **Quick root cause identification**: Found the problematic code in `llm_executor.rb` within a few searches
- **Comprehensive fix**: Not only fixed the immediate `--file` → `--prompt` issue, but also added proper timeout, output, and format flags
- **Documentation discipline**: Updated CHANGELOG, README, and version files immediately after the fix
- **End-to-end testing**: Verified the fix worked by running ace-review --auto-execute and checking the generated report
- **User-driven feature additions**: User provided clear requirements for timeout (600s), output location, and format (markdown)

## What Could Be Improved

- **Initial ace-review failure investigation**: The first attempt to use `--auto-execute` failed with `--model` error, but we discovered this was actually a different issue (missing `--prompt` flag) after user implemented it
- **Manual LLM execution workaround**: Had to manually construct and run `ace-llm-query` command as a workaround before the proper fix
- **Multiple error iterations**: Encountered both `--model` and `--file` errors sequentially rather than identifying all issues upfront

## Key Learnings

- **API integration requires careful flag mapping**: When integrating CLI tools, it's critical to audit all flags being used against the actual help output
- **Command construction patterns**: Using array syntax with `Open3.capture3` prevents command injection and makes flag management clearer
- **Output file naming conventions**: Extracting model short name from `PROVIDER:MODEL` format (`google:gemini-2.5-flash` → `gemini-2.5-flash`) provides cleaner filenames
- **Timeout considerations**: Review operations need longer timeouts (600s) than typical CLI operations due to LLM processing time
- **Version coordination**: When one gem's API changes (ace-llm), dependent gems (ace-review) need synchronized updates

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Incomplete API audit**: ace-review was using `--file` flag that never existed in ace-llm-query
  - Occurrences: 1 (single point of failure in `llm_executor.rb`)
  - Impact: Complete failure of `--auto-execute` functionality
  - Root Cause: ace-review implementation predated the actual ace-llm-query flag implementation, creating an assumption mismatch

- **Missing required positional argument**: Command construction omitted PROVIDER:MODEL as first argument
  - Occurrences: 1 (same location)
  - Impact: Command syntax error even after flag fixes
  - Root Cause: Misunderstanding of ace-llm-query's required argument structure

#### Medium Impact Issues

- **Missing output control**: Reviews were going to stdout instead of session directory files
  - Occurrences: 1
  - Impact: Workflow required manual output capture and file management
  - Root Cause: ace-review didn't leverage `--output` flag capability

- **No timeout configuration**: Default timeout insufficient for LLM processing
  - Occurrences: Potential issue not yet manifested
  - Impact: Could cause failures on large reviews
  - Root Cause: Lack of timeout consideration in integration design

### Improvement Proposals

#### Process Improvements

- **Integration testing protocol**: Before marking integration complete, verify actual command execution with `--dry-run` and live execution
- **API contract documentation**: Document expected CLI signature between interdependent gems (e.g., ace-review → ace-llm-query interface)
- **Flag audit checklist**: When integrating CLI tools, create explicit mapping between caller's needs and callee's available flags

#### Tool Enhancements

- **ace-llm-query flag validation**: Consider adding a `--validate-args` mode that reports unrecognized flags before attempting execution
- **ace-review integration tests**: Add integration tests that verify ace-llm-query command construction (mock execution, check command array)
- **Documentation cross-references**: Update ace-llm README with "Integration Guide" section showing correct usage patterns for tool authors

#### Communication Protocols

- **Earlier API review**: When implementing new flags (`--prompt`, `--model`), proactively check dependent gems for usage patterns
- **Flag migration guide**: When adding/changing flags, provide explicit "for tool integrators" section in CHANGELOG

### Token Limit & Truncation Issues

- **Large Output Instances**: 1 - Initial ace-context review report was truncated when displayed
- **Truncation Impact**: Couldn't see full review on first attempt, but file-based output resolved this
- **Mitigation Applied**: Used `--output` flag to save directly to file, then read file in chunks
- **Prevention Strategy**: Always use file-based output for LLM responses that may be lengthy

## Action Items

### Stop Doing

- Assuming flag names without checking actual tool help output
- Implementing integration code before verifying the integrated tool's actual API
- Using backticks for command execution (security risk)

### Continue Doing

- Using `Open3.capture3` with array syntax for safe command execution
- Immediate documentation updates after code changes
- End-to-end testing of fixed functionality
- User-driven requirement gathering for comprehensive fixes

### Start Doing

- Create explicit integration contracts between interdependent gems
- Add integration tests that verify command construction (not just mocked results)
- Document "for integrators" sections in README files for CLI tools
- Proactively audit dependent code when making API changes

## Technical Details

### Code Changes

**ace-review/lib/ace/review/molecules/llm_executor.rb:**
- Updated `execute` method signature to require `session_dir:` parameter
- Fixed command construction:
  ```ruby
  cmd = [
    "ace-llm-query",
    model,                      # PROVIDER:MODEL format
    "--prompt", temp_file.path, # Replaced --file
    "--output", output_file,    # Added output control
    "--timeout", "600",         # Added 10-minute timeout
    "--format", "markdown"      # Added format specification
  ]
  ```
- Added model short name extraction: `model.split(":", 2).last`
- Output filename pattern: `review-report-{model-short}.md`

**ace-review/lib/ace/review/organisms/review_manager.rb:**
- Updated `execute_with_llm` to pass `session_dir`
- Simplified result handling (LlmExecutor now writes directly)

### Version Bumps

- ace-review: 0.9.6 → 0.9.7
- Documented in CHANGELOG.md and README.md

## Additional Context

- Related ace-llm changes: v0.9.1 added `--prompt` flag, `--model` flag
- Session output: `.ace-taskflow/v.0.9.0/reviews/review-20251007-145033/review-report-gemini-2.5-flash.md`
- Review succeeded with 25K input tokens, 3.9K output tokens
