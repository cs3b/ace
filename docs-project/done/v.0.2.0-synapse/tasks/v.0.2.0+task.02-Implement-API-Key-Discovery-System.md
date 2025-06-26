---
id: v.0.2.0+task.2 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
status: done # See [Project Management Guide](project-management.md) for all possible values
priority: high
estimate: 4h
dependencies: [v.0.2.0+task.1]
---

# Implement API Key Discovery System

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

Implement API key discovery system (R-LLM-2) that supports finding Gemini API keys via configuration file `~/.gemini/config` and environment variable `GEMINI_API_KEY`. Configuration file takes precedence over environment variable. This enables secure and flexible authentication for the Gemini LLM integration.

## Scope of Work

- Create API key discovery mechanism supporting multiple sources
- Implement environment variable lookup for `GEMINI_API_KEY`
- Implement config file reader for `~/.gemini/config`
- Add validation and error handling for missing or invalid keys
- Integrate with GeminiClient from task 1

### Deliverables

#### Create

- ✅ lib/coding_agent_tools/molecules/api_credentials.rb (COMPLETED - implements multi-source API key discovery)
- ✅ lib/coding_agent_tools/atoms/env_reader.rb (COMPLETED - handles environment variable and .env file reading)
- ✅ spec/coding_agent_tools/molecules/api_credentials_spec.rb (COMPLETED - comprehensive test coverage)

#### Modify

- ✅ lib/coding_agent_tools/organisms/gemini_client.rb (COMPLETED - integrates with APICredentials via constructor)
- ✅ lib/coding_agent_tools.rb (COMPLETED - modules auto-loaded via Zeitwerk)

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

- [x] Create APICredentials molecule with multi-source discovery
  > TEST: Verify APICredentials Class
  > Type: Action Validation
  > Assert: APICredentials class exists with api_key method
  > Command: ruby -e "require './lib/coding_agent_tools/molecules/api_credentials'; puts CodingAgentTools::Molecules::APICredentials.new(env_key_name: 'GEMINI_API_KEY').respond_to?(:api_key)"
- [x] Implement environment variable lookup for GEMINI_API_KEY
  > TEST: Verify Environment Variable Lookup
  > Type: Action Validation
  > Assert: APICredentials finds key from environment variable
  > Command: GEMINI_API_KEY=test_key ruby -e "require './lib/coding_agent_tools/molecules/api_credentials'; puts CodingAgentTools::Molecules::APICredentials.new(env_key_name: 'GEMINI_API_KEY').api_key"
- [x] Create EnvReader atom for .env file parsing and environment access
- [x] Implement .env file reader with automatic discovery and error handling
  > TEST: Verify Config File Reading
  > Type: Action Validation
  > Assert: EnvReader loads .env files correctly
  > Command: ruby -e "require './lib/coding_agent_tools/atoms/env_reader'; puts CodingAgentTools::Atoms::EnvReader.load_env_file('.env')"
- [x] Integrate key discovery into GeminiClient initialization
- [x] Add comprehensive unit tests for all discovery scenarios
  > TEST: Verify Test Coverage
  > Type: Action Validation
  > Assert: All molecules have corresponding test files
  > Command: find spec -name "*api_credentials*" -o -name "*env_reader*"

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [x] AC 1: System successfully discovers API key from GEMINI_API_KEY environment variable
- [x] AC 2: System successfully reads API key from .env files (implemented via EnvReader atom)
- [x] AC 3: Priority order is enforced (singleton config > ENV variable > error)
- [x] AC 4: Clear error messages when API key is not found or invalid
- [x] AC 5: GeminiClient integrates seamlessly with APICredentials molecule
- [x] AC 6: All unit tests pass with comprehensive coverage

## Out of Scope

- ❌ Interactive API key prompting or setup wizard
- ❌ Key encryption or secure storage (beyond file permissions)
- ❌ Multiple API key profiles or workspace-specific configs
- ❌ Automatic API key validation against Gemini service
- ❌ Integration with system keychain or credential managers

## References

- Fish implementation: docs-project/backlog/v.0.2.0-synapse/docs/gemini-query.fish (shows .env file loading pattern)
- Implemented Priority: Singleton config > GEMINI_API_KEY environment variable > .env file > error
- Architecture: APICredentials molecule composes EnvReader atom for multi-source key discovery
- Integration: GeminiClient organism uses APICredentials for authentication

```
