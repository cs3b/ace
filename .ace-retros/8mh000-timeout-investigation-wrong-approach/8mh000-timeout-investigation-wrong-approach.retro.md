---
id: 8mh000
title: "Retro: Timeout Investigation - How We Broke Working Code"
type: conversation-analysis
tags: []
created_at: "2025-11-18 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8mh000-timeout-investigation-wrong-approach.md
---
# Retro: Timeout Investigation - How We Broke Working Code

**Date**: 2025-11-18
**Context**: Investigation of ace-review timeout issues that led to overcomplicating a working system
**Author**: Claude & MC
**Type**: Conversation Analysis

## What Went Well

- Identified the actual problem correctly initially (timeout 30s vs 600s needed)
- User provided clear reproduction case with exact error messages
- Direct testing with `ace-llm-query --timeout 600` showed it worked
- Good collaboration - user caught the overcomplification early

## What Could Be Improved

- **Jumped to complex solution without understanding the problem domain**
  - Assumed we needed to implement config-based fallback in ace-review
  - Didn't realize ace-llm already HAD fallback with `max_total_timeout`
  - Modified 10+ files across 2 gems before testing
- **Ignored the working evidence**
  - User's direct `ace-llm-query` worked fine (39s with `--timeout 600`)
  - Should have investigated WHY it worked instead of assuming we needed new config
- **Didn't check what ace-llm fallback was doing**
  - Fallback had `max_total_timeout: 30s` default
  - ace-review was calling ace-llm WITH fallback enabled
  - Simple `fallback: false` would have solved it immediately

## Key Learnings

### The Real Problem
- ace-llm has built-in fallback mechanism with `max_total_timeout` (default 30s)
- ace-review was using ace-llm's fallback by default
- Fallback orchestrator was limiting total time to 30s regardless of individual request timeout (600s)
- **Root cause**: Two timeout mechanisms fighting each other
  - HTTP client timeout: 600s (correct)
  - Fallback max_total_timeout: 30s (blocking)

### What We Should Have Done
1. Check ace-llm QueryInterface parameters - see `fallback:` parameter exists
2. Try `fallback: false` in ace-review immediately
3. Test before implementing complex solutions

### What We Actually Did
1. Implemented full fallback_config hash passing through 2 gems
2. Added CLI options
3. Added config file sections
4. Modified 10+ files
5. Then discovered it still didn't work because we didn't pass timeout to HTTP client
6. User caught us: "Why do we need fallback in ace-review if ace-llm has it?"

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Over-engineering Without Testing**: Implemented complex solution across 10+ files without verifying the simplest fix first
  - Occurrences: Throughout entire session
  - Impact: 2+ hours wasted, complicated codebase unnecessarily
  - Root Cause: Assumed we understood the problem without investigating ace-llm's actual behavior

- **Ignored Working Evidence**: User showed `ace-llm-query --timeout 600` worked fine
  - Occurrences: Initial problem statement
  - Impact: Missed the obvious clue that ace-llm already supported what we needed
  - Root Cause: Focused on implementing config instead of understanding why direct call worked

#### Medium Impact Issues

- **Didn't Read ace-llm Code First**: Jumped into ace-review implementation
  - Occurrences: Throughout planning phase
  - Impact: Implemented wrong solution in wrong place
  - Root Cause: Assumed ace-review needed to configure something that ace-llm already handled

- **Config File Over-emphasis**: Created elaborate config structure for simple parameter
  - Occurrences: Multiple iterations of config design
  - Impact: Unnecessary complexity in config files and code
  - Root Cause: Treating every problem as requiring config-file solution

### Improvement Proposals

#### Process Improvements

- **Test Simplest Solution First**:
  ```ruby
  # Before implementing 10 files, try:
  fallback: false  # 1 line change
  # Test it
  # If it works, done!
  ```

- **Understand Dependencies Before Modifying**:
  - Read ace-llm QueryInterface signature FIRST
  - Check what parameters are already available
  - Test existing parameters before adding new ones

- **Follow Evidence**:
  - When user shows "X works directly", investigate WHY it works
  - Don't dismiss working examples as different use cases

#### Tool Enhancements

- **Better Parameter Discovery**: Document all QueryInterface parameters clearly
- **Fallback Documentation**: Explain when to use/disable fallback
- **Integration Patterns**: Document how ace-review should call ace-llm

#### Communication Protocols

- **Ask "Why does direct call work?"**: When user shows working command, understand it
- **Confirm Understanding**: "Let me check ace-llm's existing fallback before implementing new config"
- **Test Before Full Implementation**: "Let me try `fallback: false` first before building config system"

## Action Items

### Stop Doing

- Implementing complex solutions without testing simple ones first
- Ignoring working examples as "different use cases"
- Building config systems without understanding if they're needed
- Modifying multiple gems simultaneously without incremental testing

### Continue Doing

- Collaborating with user for validation
- Using ace-context to understand project structure
- Following ACE architecture patterns
- Creating retros to learn from mistakes

### Start Doing

- **Always test the 1-line solution first** before implementing complex systems
- **Read dependency source code** before assuming what's needed
- **Ask "What does the working example tell us?"** when user provides one
- **Incremental implementation with testing** - add complexity only after simple fails
- **Question assumptions** - "Do we really need config for this?"

## Technical Details

### The Simple Fix That Worked

```ruby
# ace-review/lib/ace/review/molecules/llm_executor.rb
Ace::LLM::QueryInterface.query(
  model,
  user_prompt,
  system: system_prompt,
  output: output_file,
  format: "text",
  timeout: 600,        # Individual request timeout
  force: true,
  fallback: false      # ✅ This one line fixed it
)
```

### The Complex Solution We Built (And Rolled Back)

- Modified ace-llm QueryInterface to accept `fallback_config:` hash
- Modified ace-review to read fallback config from files
- Added CLI option `--max-total-timeout`
- Added ReviewOptions attribute
- Added config file sections in 2 places
- Added default_config fallback section
- Total: 10+ files modified across 2 gems
- **Result**: Still didn't work because we STILL had the fallback timeout issue
- **Cleanup**: Reverted all changes, added `fallback: false`, done

### Why Fallback Was The Problem

```ruby
# ace-llm fallback orchestrator checks elapsed time
if Time.now - @start_time >= @config.max_total_timeout  # 30s
  report_status("⚠ Total timeout exceeded")
  break  # Gives up even though HTTP timeout is 600s
end
```

## Additional Context

- Issue: ace-review timing out at ~2 minutes with gpro model
- User's working command: `ace-llm-query gpro ... --timeout 600` (worked in 39s)
- Lesson: The simplest explanation is usually correct
- Occam's Razor: Don't multiply entities without necessity

## Reflection

This retro captures a classic over-engineering mistake: implementing a complex solution without understanding the problem. The user's direct `ace-llm-query` command working should have been the biggest clue - it meant ace-llm already supported everything we needed. We just had to figure out how to call it correctly from ace-review.

The irony: We spent 2+ hours implementing config-based fallback control when the answer was already in the QueryInterface signature: `fallback: false`. One parameter. One line of code.

**Key Takeaway**: When the direct API call works but the wrapper doesn't, the problem is in how the wrapper calls the API, not in missing API features.
