---
id: v.0.2.0+task.2 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see .ace/handbook/guides/project-management.md#task-id-convention.
status: pending # See [Project Management Guide](project-management.md) for all possible values
priority: high
estimate: 4h
dependencies: [v.0.2.0+task.1]
---

# Implement API Key Discovery System

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

Implement API key discovery system (R-LLM-2) that supports finding Gemini API keys via configuration file `~/.gemini/config` and environment variable `GEMINI_API_KEY`. Configuration file takes precedence over environment variable. This enables secure and flexible authentication for the Gemini LLM integration.

## Scope of Work

- Create API key discovery mechanism supporting multiple sources
- Implement environment variable lookup for `GEMINI_API_KEY`
- Implement config file reader for `~/.gemini/config`
- Add validation and error handling for missing or invalid keys
- Integrate with GeminiClient from task 1

### Deliverables

#### Create

- lib/coding_agent_tools/config/api_key_resolver.rb
- lib/coding_agent_tools/config/gemini_config.rb
- spec/config/api_key_resolver_spec.rb
- spec/config/gemini_config_spec.rb
- spec/fixtures/gemini_config_sample

#### Modify

- lib/coding_agent_tools/llm/gemini_client.rb (integrate key discovery)
- lib/coding_agent_tools.rb (require new modules)

## Phases

1. Design & Architecture
2. Environment Variable Discovery
3. Config File Discovery
4. Integration & Testing

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Research secure API key storage best practices
  > TEST: Security Review
  > Type: Pre-condition Check
  > Assert: Understand secure key handling patterns
  > Command: Manual review of security documentation
- [ ] Design config file format and structure for ~/.gemini/config
- Plan priority order for key discovery (config file > ENV variable > error)
- [ ] Design error handling for missing or invalid configurations

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Create ApiKeyResolver class with multi-source discovery
  > TEST: Verify ApiKeyResolver Class
  > Type: Action Validation
  > Assert: ApiKeyResolver class exists with resolve method
  > Command: ruby -e "require './lib/coding_agent_tools/config/api_key_resolver'; puts CodingAgentTools::Config::ApiKeyResolver.new.respond_to?(:resolve)"
- [ ] Implement environment variable lookup for GEMINI_API_KEY
  > TEST: Verify Environment Variable Lookup
  > Type: Action Validation
  > Assert: Resolver finds key from environment variable when no config file exists
  > Command: rm -f ~/.gemini/config && GEMINI_API_KEY=test_key ruby -e "require './lib/coding_agent_tools/config/api_key_resolver'; puts CodingAgentTools::Config::ApiKeyResolver.new.resolve"
- [ ] Create GeminiConfig class for ~/.gemini/config file parsing
- [ ] Implement YAML/JSON config file reader with error handling
  > TEST: Verify Config File Reading
  > Type: Action Validation
  > Assert: Config reader parses sample config file
  > Command: ruby -e "require './lib/coding_agent_tools/config/gemini_config'; puts CodingAgentTools::Config::GeminiConfig.from_file('spec/fixtures/gemini_config_sample').api_key"
- [ ] Integrate key discovery into GeminiClient initialization
- [ ] Add comprehensive unit tests for all discovery scenarios
  > TEST: Verify Test Coverage
  > Type: Action Validation
  > Assert: All config classes have corresponding test files
  > Command: find spec -name "*config*" -o -name "*api_key*"

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: System successfully discovers API key from GEMINI_API_KEY environment variable
- [ ] AC 2: System successfully reads API key from ~/.gemini/config file
- [ ] AC 3: Priority order is enforced (config file takes precedence over ENV variable)
- [ ] AC 4: Clear error messages when API key is not found or invalid
- [ ] AC 5: GeminiClient integrates seamlessly with key discovery system
- [ ] AC 6: All unit tests pass with >95% code coverage

## Out of Scope

- ❌ Interactive API key prompting or setup wizard
- ❌ Key encryption or secure storage (beyond file permissions)
- ❌ Multiple API key profiles or workspace-specific configs
- ❌ Automatic API key validation against Gemini service
- ❌ Integration with system keychain or credential managers

## References

- Fish implementation: .ace/taskflow/backlog/v.0.2.0-synapse/docs/gemini-query.fish (shows .env file loading pattern)
- Priority: ~/.gemini/config > GEMINI_API_KEY environment variable

```
