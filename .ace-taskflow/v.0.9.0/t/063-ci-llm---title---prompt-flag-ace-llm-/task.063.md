---
id: v.0.9.0+task.063
status: pending
priority: medium
estimate: 1.5h
dependencies: []
---

# Add --prompt Flag to ace-llm-query for Flexible Prompt Specification

## Behavioral Specification

### User Experience
- **Input**: Users provide prompt text via `--prompt PROMPT` flag or traditional positional argument
- **Process**: System resolves prompt from flag (highest priority) or positional argument, validates presence
- **Output**: Query executes with specified prompt, or returns clear error if no prompt provided from either source

### Expected Behavior

Users can specify the prompt in two ways (priority order):
1. Via `--prompt` flag (highest priority)
2. Via positional argument (fallback)

The `--prompt` flag provides flexibility for:
- Scripting and automation (clearer named parameters)
- Avoiding shell escaping issues with complex prompts
- More explicit command syntax with many options
- Consistency with other named parameters (--model, --output, etc.)

When both are provided, the flag takes precedence (documented behavior).

### Interface Contract

```bash
# CLI Interface Enhancement
ace-llm-query PROVIDER[:MODEL] [PROMPT] [options]
ace-llm-query PROVIDER[:MODEL] --prompt PROMPT [options]

# New Option
--prompt PROMPT    Prompt text (overrides positional PROMPT if both present)

# Usage Scenarios

## Scenario 1: Flag overrides positional prompt
ace-llm-query google "ignored text" --prompt "What is Ruby?"
# Uses: "What is Ruby?" from flag (flag wins)

## Scenario 2: Flag only (no positional)
ace-llm-query google --prompt "What is Ruby?"
# Uses: "What is Ruby?" from flag

## Scenario 3: Positional only (existing behavior)
ace-llm-query google "What is Ruby?"
# Uses: "What is Ruby?" from positional arg

## Scenario 4: Neither specified
ace-llm-query google
# Error: No prompt specified

## Scenario 5: File path with flag
ace-llm-query google --prompt prompt.txt
# Reads prompt from file (FileIoHandler behavior preserved)

## Scenario 6: Complex prompt with shell metacharacters
ace-llm-query google --prompt 'Query with "quotes" and $vars'
# Flag avoids quoting/escaping issues in scripts
```

**Expected Success Output:**
```
[Normal LLM response text]
```

**Error Handling:**
- **No prompt available**: "No prompt specified. Use positional PROMPT or --prompt PROMPT"
- **Both specified**: Flag takes precedence (no error, documented behavior)
- **Empty flag value**: Treated as if flag not provided
- **File path handling**: Both syntaxes work with file paths (FileIoHandler resolves)

**Edge Cases:**
- **Both positional and flag specified**: Flag takes precedence (documented behavior)
- **Empty string in flag**: Treated as not provided, falls back to positional
- **File paths**: Work identically with both syntaxes
- **Whitespace-only prompt**: Validation error

### Success Criteria

- [ ] **Flag Parsing**: `--prompt PROMPT` option added to CLI OptionParser
- [ ] **Prompt Resolution**: Flag value overrides positional argument when both present
- [ ] **Positional Fallback**: Uses positional argument when flag not specified
- [ ] **Validation**: Clear error when neither flag nor positional prompt provided
- [ ] **File Support**: FileIoHandler works correctly with both syntaxes
- [ ] **Ruby API Parity**: `QueryInterface.query()` supports prompt override parameter
- [ ] **Backward Compatibility**: Existing positional usage patterns continue to work unchanged
- [ ] **Help Documentation**: Banner and examples updated to show dual syntax

### Validation Questions

- [ ] **Priority Clarity**: Should help text explicitly document that flag overrides positional?
- [ ] **API Naming**: Should Ruby API parameter be `prompt_override:` or keep positional with new kwarg?
- [ ] **Empty Handling**: Should empty string in flag be error or fall back to positional?
- [ ] **File Detection**: Should we distinguish file paths from text, or keep current behavior?

## Objective

Enable users to specify prompts via `--prompt` flag for improved flexibility, particularly in scripting scenarios where named parameters are clearer and avoid shell escaping complexity.

## Scope of Work

- **User Experience Scope**: CLI flag parsing and prompt resolution behavior
- **System Behavior Scope**: Priority-based prompt selection (flag > positional)
- **Interface Scope**: CLI option parsing, Ruby QueryInterface API parameter

### Deliverables

#### Behavioral Specifications
- Prompt resolution priority rules defined
- Error message formats specified
- Edge case behaviors documented

#### Validation Artifacts
- Usage scenario examples
- Error condition specifications
- Backward compatibility validation

## Out of Scope

- ❌ **Implementation Details**: Specific code structure or refactoring approaches
- ❌ **Stdin Support**: Reading prompt from stdin (e.g., `--prompt -` for piping)
- ❌ **Prompt Templates**: Template expansion or variable substitution in prompts
- ❌ **Multi-line Prompts**: Special handling for multi-line prompts beyond file reading

## References

- Similar pattern implemented in task.062 for `--model` flag
- Existing FileIoHandler for prompt file reading
- OptionParser-based CLI in ace-llm/exe/ace-llm-query
- QueryInterface Ruby API for parameter patterns

## Technical Approach

### Architecture Pattern
- **Pattern**: Extend existing CLI option parsing with priority-based prompt resolution
- **Integration**: Minimal changes to existing flow; add resolution logic in `parse_arguments` method
- **Impact**: Zero breaking changes; additive enhancement to existing interface

### Technology Stack
- **Existing Stack**: Ruby stdlib OptionParser, FileIoHandler molecule for file/text resolution
- **No New Dependencies**: Feature requires no additional gems or libraries
- **Compatibility**: Works with existing file path resolution and all provider clients

### Implementation Strategy
- **Incremental Changes**: Add flag → add resolution logic → update documentation
- **Backward Compatibility**: All existing usage patterns continue to work unchanged
- **Testing**: Manual testing with multiple scenarios; consider automated tests later

## File Modifications

### Modify
- **ace-llm/exe/ace-llm-query** (lines 26-37, 66-95, 96-170)
  - Changes:
    - Add `prompt: nil` to `@options` hash initialization
    - Add `opts.on("--prompt PROMPT", ...)` to OptionParser after `--model` option
    - Update banner to show dual syntax for prompt: `[PROMPT]` and `--prompt PROMPT`
    - Add prompt resolution logic in `parse_arguments`:
      - Extract positional args: `positional_prompt = remaining_args.join(" ")`
      - Resolve: `@prompt = @options[:prompt] || positional_prompt`
      - Validate: error if `@prompt` is nil/empty
    - Add `--prompt` examples to help text
  - Impact: Central CLI logic enhancement; no impact on other components
  - Integration points: FileIoHandler already handles prompt resolution from `@prompt`

- **ace-llm/lib/ace/llm/query_interface.rb** (lines 13-42)
  - Changes:
    - Add `prompt_override: nil` keyword parameter to `query` method signature
    - Keep existing positional `prompt` parameter for backward compatibility
    - Add prompt resolution logic after parser initialization:
      - `final_prompt = prompt_override || prompt`
      - Validate: error if `final_prompt` is nil/empty
    - Update docstring to document new parameter
  - Impact: Provides Ruby API parity with CLI flag
  - Integration points: Same resolution logic as CLI for consistency

- **ace-llm/README.md** (lines 48-69)
  - Changes:
    - Add `--prompt` flag examples in Advanced Options section
    - Document use cases: scripting, escaping, explicit syntax
    - Show priority order in examples
  - Impact: User-facing documentation
  - Integration points: None (documentation only)

- **ace-llm/docs/migration-from-llm-query.md** (lines 17-29)
  - Changes:
    - Add `--prompt` to options comparison table
    - Note version availability (v0.9.2+)
  - Impact: Migration guide completeness
  - Integration points: None (documentation only)

### Create (Optional - Testing)
- **ace-llm/test/test_prompt_resolution.rb** (new file, ~80 lines)
  - Purpose: Automated test coverage for --prompt flag behavior
  - Key components: Test flag override, positional only, both specified, neither specified
  - Note: Can be created later; manual testing sufficient for initial implementation

## Implementation Plan

### Planning Steps

* [ ] Review existing code patterns in task.062 (--model flag)
  - Focus areas: OptionParser setup, resolution flow, error handling patterns
  - Files: ace-llm/exe/ace-llm-query, query_interface.rb
  - Understand parse_arguments method structure and flow

* [ ] Design prompt resolution precedence logic
  - Priority: --prompt flag > positional argument > (error if neither)
  - Edge cases: empty flag value, both specified, neither specified, whitespace only
  - Error scenarios: no prompt from any source, whitespace-only prompt
  - Integration with FileIoHandler: ensure file reading works for both syntaxes

### Execution Steps

- [ ] Add `prompt: nil` to `@options` hash initialization
  - Location: `ace-llm/exe/ace-llm-query` `QueryCLI#initialize` method (line ~26)
  - Add alongside other option defaults (after `model: nil`)

- [ ] Add `--prompt` option to CLI OptionParser
  - Location: `ace-llm/exe/ace-llm-query` `create_option_parser` method
  - Add after `--model` option (line ~130-133)
  - Store in `@options[:prompt]`
  - Description: "Prompt text (overrides positional PROMPT if both present)"
  > TEST: Help Text Verification
  > Type: Manual Check
  > Assert: `ace-llm-query --help` shows `--prompt PROMPT` option
  > Command: # Run: ace-llm-query --help | grep -A1 "prompt"

- [ ] Implement prompt resolution logic in `parse_arguments`
  - Location: After extracting provider_model from remaining_args (line ~83-90)
  - Extract positional prompt: `positional_prompt = remaining_args.join(" ")`
  - Resolve: `@prompt = @options[:prompt] || positional_prompt`
  - Validate: error if `@prompt` is nil/empty after resolution
  - Remove old error check for empty positional (lines 87-90)
  - Error message: "No prompt specified. Use positional PROMPT or --prompt PROMPT"
  > TEST: Prompt Resolution Priority
  > Type: Integration Test
  > Assert: Flag overrides positional prompt
  > Command: # Run: ace-llm-query google "ignored" --prompt "used" (verify "used" is sent)

- [ ] Update CLI banner for dual syntax
  - Location: `create_option_parser` banner (line ~99-100)
  - Change from: `PROVIDER[:MODEL] PROMPT [options]`
  - Change to: Show both syntaxes (like --model banner)
  - Format: Multi-line banner showing optional positional prompt

- [ ] Add `--prompt` usage examples to help text
  - Location: Examples section in `create_option_parser` (line ~157-165)
  - Add 2-3 examples showing flag usage
  - Example 1: Basic flag usage
  - Example 2: Combining with --model and --output
  - Example 3: Complex prompt avoiding shell escaping
  > TEST: Example Accuracy
  > Type: Documentation Validation
  > Assert: Examples use correct syntax and are executable
  > Command: # Manually verify examples work

- [ ] Add `prompt_override:` parameter to `QueryInterface.query` method
  - Location: `ace-llm/lib/ace/llm/query_interface.rb:29-38`
  - Add keyword parameter with default `nil` after `model:` parameter
  - Keep positional `prompt` parameter for backward compatibility
  - Implement same resolution logic as CLI after parser init
  - Update docstring to document new parameter
  > TEST: Ruby API Compatibility
  > Type: Unit Test
  > Assert: Both syntaxes work: query(provider, prompt) and query(provider, nil, prompt_override: text)
  > Command: # Test in IRB or create simple test script

- [ ] Test all usage scenarios manually
  - Scenario 1: Flag overrides positional prompt
  - Scenario 2: Flag only (no positional)
  - Scenario 3: Positional only (regression test)
  - Scenario 4: Error case - neither specified
  - Scenario 5: File path with flag
  - Scenario 6: Complex prompt with shell metacharacters
  > TEST: End-to-End Scenarios
  > Type: Manual Testing
  > Assert: All 6 scenarios produce expected behavior
  > Command: # Run each scenario from behavioral spec

- [ ] Update ace-llm/README.md with `--prompt` documentation
  - Location: Advanced Options section (after --model examples)
  - Add 2-3 examples with use cases
  - Document priority order and rationale
  - Show scripting/automation benefits

- [ ] Update ace-llm/docs/migration-from-llm-query.md
  - Add `--prompt` to options comparison table
  - Note version (v0.9.2+)
  - Mark as new feature (not in original llm-query)

## Risk Assessment

### Technical Risks
- **Risk**: Prompt resolution logic inconsistency between CLI and Ruby API
  - **Probability**: Low
  - **Impact**: Medium
  - **Mitigation**: Use identical resolution pattern in both interfaces
  - **Rollback**: Revert single commit

- **Risk**: Breaking change to positional argument behavior
  - **Probability**: Very Low
  - **Impact**: High
  - **Mitigation**: Extensive manual testing of existing patterns; flag only adds override
  - **Rollback**: Revert flag option, restore original logic

- **Risk**: FileIoHandler incompatibility with flag syntax
  - **Probability**: Very Low
  - **Impact**: Low
  - **Mitigation**: FileIoHandler operates on resolved `@prompt` variable (unchanged)
  - **Monitoring**: Test file path reading with both syntaxes

### Integration Risks
- **Risk**: Confusion about which prompt source is used
  - **Probability**: Medium
  - **Impact**: Low
  - **Mitigation**: Clear documentation and help text about priority
  - **Monitoring**: User feedback on clarity of flag behavior

## Acceptance Criteria

- [ ] `--prompt PROMPT` flag added to CLI and shows in help text
- [ ] Flag value overrides positional prompt when both specified
- [ ] Uses positional prompt when flag not specified (backward compatibility)
- [ ] Clear error message when no prompt available from any source
- [ ] FileIoHandler works correctly with both flag and positional syntaxes
- [ ] `QueryInterface.query()` accepts `prompt_override:` parameter with same behavior
- [ ] All existing positional usage patterns continue to work unchanged
- [ ] Help text includes `--prompt` examples and documents priority
- [ ] README.md updated with flag documentation and use cases
- [ ] Migration guide updated with new option
