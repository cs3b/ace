---
id: v.0.2.0+task.4 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see .ace/handbook/guides/project-management.md#task-id-convention.
status: pending # See [Project Management Guide](project-management.md) for all possible values
priority: medium
estimate: 3h
dependencies: [v.0.2.0+task.1, v.0.2.0+task.3]
---

# Add Model Override Flag Support

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-studio-query` commands to allow users to override default models. Default models: Gemini uses "gemini-2.0-flash-lite" and LM Studio uses "mistral-small-24b-instruct-2501@8bit". This provides flexibility for users to select specific models based on their needs or availability.

## Scope of Work

- Add `--model` flag to both llm-gemini-query and lms-studio-query commands
- Implement model validation and error handling for invalid models
- Update client classes to support dynamic model selection
- Add configuration for default model settings
- Update help documentation and examples

### Deliverables

#### Create

- spec/integration/model_override_spec.rb

#### Modify

- lib/coding_agent_tools/commands/llm_gemini_query.rb (add --model flag)
- lib/coding_agent_tools/commands/lms_studio_query.rb (add --model flag)
- lib/coding_agent_tools/llm/gemini_client.rb (support model parameter)
- lib/coding_agent_tools/llm/lm_studio_client.rb (support model parameter)
- bin/llm-gemini-query (update help text)
- bin/lms-studio-query (update help text)

## Phases

1. Design & Analysis
2. CLI Flag Implementation
3. Client Integration
4. Testing & Documentation

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Research available Gemini models and their identifiers (reference gemini-query.fish)
  > TEST: Model Research
  > Type: Pre-condition Check
  > Assert: Understand valid model names for Gemini and LM Studio
  > Command: Manual review of API documentation and Fish implementations
- [ ] Analyze current CLI argument parsing patterns in existing commands
- [ ] Design model validation strategy and error messages
- [ ] Plan default model configuration approach

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Add --model flag to llm-gemini-query command parser
  > TEST: Verify Gemini Model Flag
  > Type: Action Validation
  > Assert: llm-gemini-query accepts --model flag
  > Command: bin/llm-gemini-query --help | grep -i model
- [ ] Add --model flag to lms-studio-query command parser
  > TEST: Verify LM Studio Model Flag
  > Type: Action Validation
  > Assert: lms-studio-query accepts --model flag  
  > Command: bin/lms-studio-query --help | grep -i model
- [ ] Update GeminiClient to accept model parameter in constructor
  > TEST: Verify Gemini Client Model Support
  > Type: Action Validation
  > Assert: GeminiClient accepts model parameter
  > Command: ruby -e "require './lib/coding_agent_tools/llm/gemini_client'; puts CodingAgentTools::LLM::GeminiClient.new(model: 'test').respond_to?(:generate_text)"
- [ ] Update LMStudioClient to accept model parameter in constructor
- [ ] Implement model validation with helpful error messages
  > TEST: Verify Model Validation
  > Type: Action Validation
  > Assert: Commands show helpful error for invalid models
  > Command: bin/llm-gemini-query --model invalid_model "test" 2>&1 | grep -i "invalid model"
- [ ] Add integration tests for model override functionality
  > TEST: Verify Integration Tests
  > Type: Action Validation
  > Assert: Integration test file exists and tests model overrides
  > Command: find spec -name "*model_override*"

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: Both commands accept --model flag with proper argument parsing
- [ ] AC 2: Model parameter is passed through to respective client classes
- [ ] AC 3: Invalid model names produce clear error messages
- [ ] AC 4: Default models work when --model flag is not specified (gemini-2.0-flash-lite for Gemini, mistral-small-24b-instruct-2501@8bit for LM Studio)
- [ ] AC 5: Help text documents available models and usage examples
- [ ] AC 6: All unit and integration tests pass

## Out of Scope

- ❌ Dynamic model discovery or listing from services
- ❌ Model capability validation or compatibility checking
- ❌ Performance benchmarking between different models
- ❌ Model-specific parameter tuning (temperature, top-k, etc.)
- ❌ Configuration file settings for preferred models
- ❌ Model switching during runtime or conversations

## References

- Fish implementations: 
  - .ace/taskflow/backlog/v.0.2.0-synapse/docs/gemini-query.fish
  - .ace/taskflow/backlog/v.0.2.0-synapse/docs/lms-query.fish
- Default models:
  - Gemini: gemini-2.0-flash-lite
  - LM Studio: mistral-small-24b-instruct-2501@8bit


```
