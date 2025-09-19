---
id: v.0.2.0+task.4 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
status: done # See [Project Management Guide](project-management.md) for all possible values
priority: medium
estimate: 3h
dependencies: [v.0.2.0+task.3]
---

# Add Model Override Flag Support

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `llm-lmstudio-query` commands to allow users to override default models. Default models: Gemini uses "gemini-2.0-flash-lite" and LM Studio uses "mistralai/devstral-small-2505". Additionally, implement separate model listing commands `exe/llm-gemini-models` and `exe/llm-lmstudio-models` with fuzzy search filtering capability. This provides flexibility for users to select specific models based on their needs or availability.

## Scope of Work

- Add `--model` flag to both llm-gemini-query and llm-lmstudio-query commands
- Implement separate model listing commands with fuzzy search filtering
- Implement model validation and error handling for invalid models
- Update client classes to support dynamic model selection
- Add configuration for default model settings
- Update help documentation and examples

### Deliverables

#### Create

- lib/coding_agent_tools/cli/commands/llm/models.rb
- lib/coding_agent_tools/cli/commands/lms/models.rb
- exe/llm-gemini-models (executable CLI script)
- exe/llm-lmstudio-models (executable CLI script)
- spec/coding_agent_tools/cli/commands/llm/models_spec.rb
- spec/coding_agent_tools/cli/commands/lms/models_spec.rb

#### Modify

- lib/coding_agent_tools/cli/commands/llm/query.rb (✅ already has --model flag)
- lib/coding_agent_tools/cli/commands/lms/query.rb (add --model flag, from Task 3)
- lib/coding_agent_tools/organisms/gemini_client.rb (✅ already supports model parameter)
- lib/coding_agent_tools/organisms/lm_studio_client.rb (support model parameter)
- exe/llm-gemini-query (update help text)
- exe/llm-lmstudio-query (update help text)

## Phases

1. Design & Analysis
2. Model Listing Commands Implementation
3. CLI Flag Implementation (partially done for Gemini)
4. Client Integration
5. Testing & Documentation

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [x] Research available Gemini models and their identifiers (reference gemini-query.fish)
  > TEST: Model Research
  > Type: Pre-condition Check
  > Assert: Understand valid model names for Gemini and LM Studio
  > Command: Manual review of API documentation and Fish implementations
- [x] Analyze current CLI argument parsing patterns in existing commands
- [x] Design model validation strategy and error messages
- [x] Plan default model configuration approach
- [x] Design fuzzy search filtering mechanism for model listing
- [x] Plan model listing data structure and API integration approach

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [x] Add --model flag to llm-gemini-query command parser (✅ already implemented)
  > TEST: Verify Gemini Model Flag
  > Type: Action Validation
  > Assert: llm-gemini-query accepts --model flag
  > Command: exe/llm-gemini-query --help | grep -i model
- [x] Add --model flag to llm-lmstudio-query command parser
  > TEST: Verify LM Studio Model Flag
  > Type: Action Validation
  > Assert: llm-lmstudio-query accepts --model flag  
  > Command: exe/llm-lmstudio-query --help | grep -i model
- [x] Update GeminiClient to accept model parameter in constructor (✅ already implemented)
  > TEST: Verify Gemini Client Model Support
  > Type: Action Validation
  > Assert: GeminiClient accepts model parameter
  > Command: ruby -e "require './lib/coding_agent_tools/organisms/gemini_client'; puts CodingAgentTools::Organisms::GeminiClient.new(model: 'test').respond_to?(:generate_text)"
- [x] Update LMStudioClient to accept model parameter in constructor
- [x] Create llm-gemini-models command with fuzzy search filtering
  > TEST: Verify Gemini Models Command
  > Type: Action Validation
  > Assert: llm-gemini-models command exists and supports filtering
  > Command: exe/llm-gemini-models --help
- [x] Create llm-lmstudio-models command with fuzzy search filtering
  > TEST: Verify LM Studio Models Command
  > Type: Action Validation
  > Assert: llm-lmstudio-models command exists and supports filtering
  > Command: exe/llm-lmstudio-models --help
- [x] Implement model validation with helpful error messages
  > TEST: Verify Model Validation
  > Type: Action Validation
  > Assert: Commands show helpful error for invalid models
  > Command: exe/llm-gemini-query --model invalid_model "test" 2>&1 | grep -i "invalid model"
- [x] Add model override tests to existing integration test files
  > TEST: Verify Model Override in Gemini Integration Tests
  > Type: Action Validation
  > Assert: Gemini integration tests include model override scenarios (test with gemini-1.5-flash)
  > Command: grep -n "model.*gemini-1.5-flash" spec/integration/llm_gemini_query_integration_spec.rb
  > TEST: Verify Model Override in LM Studio Integration Tests
  > Type: Action Validation
  > Assert: LM Studio integration tests include model override scenarios (test with mistralai/devstral-small-2505)
  > Command: grep -n "model.*mistralai/devstral-small-2505" spec/integration/llm_lmstudio_query_integration_spec.rb

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [x] AC 1: Gemini command accepts --model flag with proper argument parsing (✅ completed)
- [x] AC 1b: LM Studio command accepts --model flag with proper argument parsing
- [x] AC 2: Model parameter is passed through to GeminiClient (✅ completed)
- [x] AC 2b: Model parameter is passed through to LMStudioClient
- [x] AC 3: Invalid model names produce clear error messages
- [x] AC 4: Default models work when --model flag is not specified (gemini-2.0-flash-lite for Gemini, ✅ completed)
- [x] AC 4b: Default model works for LM Studio (mistralai/devstral-small-2505)
- [x] AC 5: Help text documents available models and usage examples
- [x] AC 6: Model listing commands work with fuzzy search filtering
- [x] AC 7: Model override functionality is tested in existing integration tests (llm_gemini_query_integration_spec.rb and llm_lmstudio_query_integration_spec.rb)
- [x] AC 8: All unit and integration tests pass

## Out of Scope

- ❌ Dynamic model discovery from remote APIs (will use manual/hardcoded lists)
- ❌ Model capability validation or compatibility checking
- ❌ Performance benchmarking between different models
- ❌ Model-specific parameter tuning (temperature, top-k, etc.)
- ❌ Configuration file settings for preferred models
- ❌ Model switching during runtime or conversations

## References

- Fish implementations: 
  - docs-project/backlog/v.0.2.0-synapse/docs/gemini-query.fish
  - docs-project/backlog/v.0.2.0-synapse/docs/lms-query.fish
- Default models:
  - Gemini: gemini-2.0-flash-lite (✅ implemented)
  - LM Studio: mistralai/devstral-small-2505
- Current implementation: lib/coding_agent_tools/cli/commands/llm/query.rb already has --model flag
- Architecture: Model listing commands follow same CLI pattern as query commands
- Fuzzy search: Use simple string matching for model name filtering
- Integration testing: Add model override tests to existing integration specs rather than separate file
- Test models: Use gemini-1.5-flash for Gemini tests and mistralai/devstral-small-2505 for LM Studio tests in VCR cassettes


```
