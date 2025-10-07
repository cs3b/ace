---
id: v.0.9.0+task.062
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Add --model Flag to ace-llm-query for Flexible Model Specification

## Behavioral Specification

### User Experience
- **Input**: Users provide model name via `--model MODEL` flag, optionally alongside positional `PROVIDER[:MODEL]` syntax
- **Process**: System resolves model from flag (highest priority), then positional arg, then default; validates against provider
- **Output**: Query executes with the specified model, or returns clear error if model invalid/unavailable

### Expected Behavior

Users can specify the LLM model in three ways (priority order):
1. Via `--model` flag (highest priority)
2. Via positional `PROVIDER:MODEL` syntax
3. Via provider default (fallback)

The `--model` flag provides flexibility for:
- Overriding positional model specifications
- Working with provider-only syntax (e.g., `google --model gemini-flash`)
- Quick model switching without changing the full provider:model string
- Scripting and automation scenarios

### Interface Contract

```bash
# CLI Interface Enhancement
ace-llm-query PROVIDER[:MODEL] PROMPT [options]
ace-llm-query PROVIDER PROMPT --model MODEL [options]

# New Option
--model MODEL    Model name (overrides PROVIDER[:MODEL] if both present)

# Usage Scenarios

## Scenario 1: Flag overrides positional model
ace-llm-query google:gemini-pro "What is Ruby?" --model gemini-2.0-flash-lite
# Uses: gemini-2.0-flash-lite (flag wins)

## Scenario 2: Flag with provider-only syntax
ace-llm-query google "What is Ruby?" --model gemini-2.0-flash-lite
# Uses: gemini-2.0-flash-lite from flag

## Scenario 3: Alias with flag override
ace-llm-query gflash "What is Ruby?" --model gemini-pro
# Resolves: gflash → google:gemini-2.0-flash-lite, then overrides with gemini-pro

## Scenario 4: Positional model only (existing behavior)
ace-llm-query google:gemini-pro "What is Ruby?"
# Uses: gemini-pro from positional arg

## Scenario 5: Provider only, no flag, has default
ace-llm-query google "What is Ruby?"
# Uses: provider's default model

## Scenario 6: Neither specified, no default
ace-llm-query someprovider "What is Ruby?"
# Error: No model specified and no default available for someprovider
```

**Expected Success Output:**
```
[Normal LLM response text]
```

**Error Handling:**
- **No model available**: "No model specified and no default available for {provider}"
- **Invalid model**: Provider-specific validation error (handled by client)
- **Missing provider**: "Unknown provider: {provider}. Supported providers: {list}"

**Edge Cases:**
- **Both positional and flag specified**: Flag takes precedence (documented behavior)
- **Alias with flag**: Alias resolves to provider, flag supplies model
- **Empty flag value**: Treated as if flag not provided
- **Provider-only with no flag and no default**: Clear error message with guidance

### Success Criteria

- [x] **Flag Parsing**: `--model MODEL` option added to CLI OptionParser
- [x] **Model Resolution**: Flag value overrides positional model when both present
- [x] **Provider-only Compatibility**: Works with provider-only syntax (e.g., `google --model gemini-flash`)
- [x] **Alias Integration**: Works correctly with alias resolution
- [x] **Default Fallback**: Uses provider default when neither flag nor positional model specified
- [x] **Error Messaging**: Clear error when no model available from any source
- [x] **Ruby API Parity**: `QueryInterface.query()` supports `model:` parameter
- [x] **Backward Compatibility**: Existing usage patterns continue to work unchanged
- [x] **Help Documentation**: Banner and examples updated to show dual syntax

### Validation Questions

- [ ] **Priority Clarity**: Should help text explicitly document that flag overrides positional?
- [ ] **API Consistency**: Should Ruby API parameter be `model:` or `model_override:`?
- [ ] **Error Detail**: Should invalid model errors suggest available models for the provider?
- [ ] **Flag Naming**: Is `--model` the most intuitive flag name, or consider `--override-model`?

## Objective

Enable users to specify LLM models via `--model` flag for improved flexibility, particularly in scripting scenarios where overriding a default provider:model string is more convenient than string manipulation.

## Scope of Work

- **User Experience Scope**: CLI flag parsing and model resolution behavior
- **System Behavior Scope**: Priority-based model selection (flag > positional > default)
- **Interface Scope**: CLI option parsing, Ruby QueryInterface API parameter

### Deliverables

#### Behavioral Specifications
- Model resolution priority rules defined
- Error message formats specified
- Edge case behaviors documented

#### Validation Artifacts
- Usage scenario examples
- Error condition specifications
- Backward compatibility validation

## Out of Scope

- ❌ **Implementation Details**: Specific code structure or refactoring approaches
- ❌ **Model Validation Logic**: Provider-specific model validation (already handled by clients)
- ❌ **Alias Resolution Changes**: Alias resolution mechanism modifications
- ❌ **Provider Discovery**: Adding new providers or changing provider registration

## References

- Implementation plan provided in chat context
- Existing ace-llm-query CLI implementation
- ProviderModelParser molecule for provider:model parsing
- QueryInterface Ruby API for parameter patterns

## Technical Approach

### Architecture Pattern
- **Pattern**: Extend existing CLI option parsing with priority-based model resolution
- **Integration**: Minimal changes to existing flow; add override logic in `execute_query` method
- **Impact**: Zero breaking changes; additive enhancement to existing interface

### Technology Stack
- **Existing Stack**: Ruby stdlib OptionParser, ace-llm molecules (ProviderModelParser, ClientRegistry)
- **No New Dependencies**: Feature requires no additional gems or libraries
- **Compatibility**: Works with existing provider clients and alias resolution

### Implementation Strategy
- **Incremental Changes**: Add flag → add resolution logic → update documentation
- **Backward Compatibility**: All existing usage patterns continue to work unchanged
- **Testing**: Manual testing with multiple scenarios; consider automated tests later

## File Modifications

### Modify
- **ace-llm/exe/ace-llm-query** (lines 26-37, 96-161, 182-237)
  - Changes:
    - Add `model: nil` to `@options` hash initialization
    - Add `opts.on("--model MODEL", ...)` to OptionParser
    - Update banner to show dual syntax
    - Add model resolution logic in `execute_query` (flag > positional > default)
    - Pass resolved model to `create_client` method
    - Add `--model` examples to help text
  - Impact: Central CLI logic enhancement; no impact on other components
  - Integration points: Calls to ProviderModelParser and ClientRegistry unchanged

- **ace-llm/lib/ace/llm/query_interface.rb** (lines 28-36, 44-56)
  - Changes:
    - Add `model: nil` parameter to `query` method signature
    - Add model override logic after `parse_result` (same as CLI)
    - Pass resolved model to `registry.get_client`
  - Impact: Provides Ruby API parity with CLI flag
  - Integration points: Same resolution logic as CLI for consistency

### Create (Optional - Testing)
- **ace-llm/test/test_query_cli.rb** (new file, ~100 lines)
  - Purpose: Automated test coverage for --model flag behavior
  - Key components: Test flag override, provider-only + flag, alias + flag, error cases
  - Note: Can be created later; manual testing sufficient for initial implementation

## Implementation Plan

### Planning Steps

* [x] Review existing code patterns in ace-llm-query CLI
  - Focus areas: OptionParser setup, model resolution flow, error handling patterns
  - Files: ace-llm/exe/ace-llm-query, query_interface.rb, provider_model_parser.rb

* [x] Design model resolution precedence logic
  - Priority: --model flag > positional :MODEL > provider default
  - Edge cases: empty flag value, both specified, neither specified
  - Error scenarios: no model from any source

### Execution Steps

- [x] Add `--model` option to CLI OptionParser
  - Location: `ace-llm/exe/ace-llm-query:` `create_option_parser` method
  - Add after `--max-tokens` option
  - Store in `@options[:model]`
  > TEST: Help Text Verification
  > Type: Manual Check
  > Assert: `ace-llm-query --help` shows `--model MODEL` option
  > Command: # Run: ace-llm-query --help | grep -A1 "model"

- [x] Initialize `model: nil` in `@options` hash
  - Location: `QueryCLI#initialize` method (line ~26)
  - Add alongside other option defaults

- [x] Implement model resolution logic in `execute_query`
  - Location: After `parse_result` validation (line ~190)
  - Logic: `final_model = @options[:model] || parse_result.model`
  - Add validation: error if `final_model` is nil/empty
  - Pass `final_model` to `create_client(parse_result.provider, final_model)`
  > TEST: Model Resolution Priority
  > Type: Integration Test
  > Assert: Flag overrides positional model
  > Command: # Run: ace-llm-query google:gemini-pro "test" --model gemini-flash --dry-run

- [x] Update `create_client` method signature
  - Change from using `parse_result.model` to accepting model parameter
  - Pass model to `@registry.get_client(provider, model: model, ...)`

- [x] Update CLI banner for dual syntax
  - Location: `create_option_parser` banner (line ~98)
  - Show both: `PROVIDER[:MODEL]` and `PROVIDER --model MODEL`

- [x] Add `--model` usage examples to help text
  - Location: Examples section in `create_option_parser` (line ~152)
  - Add 2-3 examples showing flag usage
  > TEST: Example Accuracy
  > Type: Documentation Validation
  > Assert: Examples use correct syntax and are executable
  > Command: # Manually verify examples work

- [x] Add `model:` parameter to `QueryInterface.query` method
  - Location: `ace-llm/lib/ace/llm/query_interface.rb:28`
  - Add to method signature with default `nil`
  - Implement same resolution logic as CLI
  - Update docstring to document new parameter

- [x] Test all usage scenarios manually
  - Scenario 1: Flag overrides positional model
  - Scenario 2: Flag with provider-only syntax
  - Scenario 3: Alias with flag override
  - Scenario 4: Positional model only (regression test)
  - Scenario 5: Provider only, no flag (default model)
  - Scenario 6: Error case - no model available
  > TEST: End-to-End Scenarios
  > Type: Manual Testing
  > Assert: All 6 scenarios produce expected behavior
  > Command: # Run each scenario from behavioral spec

- [x] Update ace-llm/README.md with `--model` documentation
  - Add section showing flag usage
  - Document priority order
  - Include examples with common use cases

## Risk Assessment

### Technical Risks
- **Risk**: Model resolution logic inconsistency between CLI and Ruby API
  - **Probability**: Low
  - **Impact**: Medium
  - **Mitigation**: Use identical resolution pattern in both interfaces
  - **Rollback**: Revert single commit

- **Risk**: Breaking change to positional argument behavior
  - **Probability**: Very Low
  - **Impact**: High
  - **Mitigation**: Extensive manual testing of existing patterns; flag only adds override
  - **Rollback**: Revert flag option, restore original logic

### Integration Risks
- **Risk**: Conflict with provider-specific model validation
  - **Probability**: Low
  - **Impact**: Low
  - **Mitigation**: Model validation happens at client level (existing behavior)
  - **Monitoring**: Test with multiple providers (google, openai, anthropic)

## Acceptance Criteria

- [x] `--model MODEL` flag added to CLI and shows in help text
- [x] Flag value overrides positional model when both specified
- [x] Works with provider-only syntax (e.g., `google --model gemini-flash`)
- [x] Works with alias resolution (e.g., `gflash --model gemini-pro`)
- [x] Falls back to provider default when neither flag nor positional model specified
- [x] Clear error message when no model available from any source
- [x] `QueryInterface.query()` accepts `model:` parameter with same behavior
- [x] All existing usage patterns continue to work (backward compatibility)
- [x] Help text includes `--model` examples and documents priority
- [x] README.md updated with flag documentation
