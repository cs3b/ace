# AI Agent Task: Comprehensive Ruby Gem Code Review

You are an expert Ruby developer, software architect, and code quality specialist. Your task is to perform a thorough code review of the provided diff, focusing on Ruby gem best practices, ATOM architecture compliance, and maintaining high standards for CLI-first design.

## Context: Project Standards

This Ruby gem follows:
- **ATOM architecture** pattern (Atoms, Molecules, Organisms, Ecosystems)
- **Test-driven development** with RSpec (100% coverage target)
- **CLI-first design** optimized for both humans and AI agents
- **Documentation-driven development** approach
- **Semantic versioning** with conventional commits
- **Ruby style guide** with StandardRB enforcement

## Input Data

### Code Diff to Review
```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 78ffe00..963dfff 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -5,6 +5,55 @@ All notable changes to this project will be documented in this file.
 The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
 and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
 
+## Unreleased
+
+#### v.0.2.0+task.4 - 2025-06-14 - Add Model Override Flag Support
+
+### Added
+- **Model Override Flags**: Complete implementation of `--model` flag support for both Gemini and LM Studio query commands
+  - Model parameter validation and error handling through APIs
+  - Help text documentation with usage examples
+- **Model Listing Commands**: New CLI commands for discovering available models
+  - `llm-gemini-models` command with fuzzy search filtering (text/JSON output)
+  - `llm-lmstudio-models` command with fuzzy search filtering (text/JSON output)
+  - Updated CLI registration to include models commands
+- **Updated Model Lists**: Accurate model names aligned with v1beta API
+  - Gemini models: gemini-2.0-flash-lite (default), gemini-2.0-flash, gemini-2.5-flash-preview-05-20, gemini-2.5-pro-preview-06-05, gemini-1.5-flash, gemini-1.5-flash-8b, gemini-1.5-pro
+  - LM Studio models: mistralai/devstral-small-2505 (default), deepseek/deepseek-r1-0528-qwen3-8b, and others
+- **Enhanced Testing**: 
+  - Unit tests for model listing commands with comprehensive filter testing
+  - Integration test updates with valid model override scenarios
+  - Fixed test model names to use v1beta compatible models
+
+### Changed
+- Updated Gemini model list to reflect actual v1beta API availability
+- Improved integration tests to use valid model names (gemini-1.5-flash for Gemini tests)
+- Enhanced error handling consistency across commands
+
+#### v.0.2.0+task.3 - 2025-06-14 - Implement LM Studio Query Command
+
+### Added
+- **LM Studio Integration**: Complete implementation of `llm-lmstudio-query` command for offline LLM inference
+  - `LMStudioClient` organism with HTTP REST integration to localhost:1234
+  - CLI command with argument parsing for prompts and file input
+  - Server health check and connection validation
+  - Comprehensive error handling for server unavailable scenarios
+  - Default model support (mistralai/devstral-small-2505) with configurability
+- **Testing Infrastructure**:
+  - Unit tests with mock server scenarios for LMStudioClient
+  - Integration tests using Aruba + VCR pattern
+  - VCR cassettes for LM Studio API interactions
+  - Test coverage for various prompt types and edge cases
+- **CLI Infrastructure**:
+  - LMS command registration in CLI system
+  - Executable script `exe/llm-lmstudio-query`
+  - Proper Zeitwerk inflection for LMStudioClient
+
+### Changed
+- **Module Loading**: Updated Zeitwerk inflector configuration to include `lm_studio_client`
+- **CLI Registration**: Extended CLI system to register LMS commands alongside existing LLM commands
+- **VCR Configuration**: Enhanced VCR setup to handle localhost connections for LM Studio testing
+
 ## [v.0.2.0+tasks.5 - task.16] - CLI Integration Testing, Documentation Updates, and Code Quality Fixes
 
 ### Added
diff --git a/docs-project/current/v.0.2.0-synapse/reflections/20250614-reflections-on-model-override-task.md b/docs-project/current/v.0.2.0-synapse/reflections/20250614-reflections-on-model-override-task.md
new file mode 100644
index 0000000..afd4e36
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/reflections/20250614-reflections-on-model-override-task.md
@@ -0,0 +1,19 @@
+# Reflections Template
+
+## Stop Doing
+
+- **Guessing File Paths:** I incorrectly guessed the path for the VCR cassette when trying to delete it. I should have used `find_path` first to confirm its location before attempting a file operation.
+- **Making Assumptions on Test Failures:** I jumped to the conclusion that the VCR cassette was the problem for the failing integration test, when the root cause was the use of an invalid model name in the test setup. Re-recording the cassette fixed it, but only after I had already corrected the model name. I need to analyze the complete context of a failure before attempting a fix.
+- **Using Hardcoded Lists for Dynamic Data:** The initial implementation for listing models used a static, hardcoded list. It was a correct user suggestion to change this to a dynamic API call. I should default to fetching dynamic data from its source when possible.
+
+## Continue Doing
+
+- **Systematically Following Workflow Instructions:** I successfully followed the steps outlined in `create-reflection-note.wf.md`, which led to the correct creation of the reflection file.
+- **Correcting Tool Usage Errors:** When the `bin/rc -p` command failed, I correctly interpreted the help output and used the right command (`bin/rc`) immediately after.
+- **Refactoring to Better Data Structures:** Adopting the `Molecules::Model` class to represent model data was a significant improvement over using raw hashes. I should continue to embrace creating clear data structures.
+
+## Start Doing
+
+- **Verifying Paths Before Acting:** I will make it a priority to use `find_path` or `list_directory` to confirm a file's existence and exact path before attempting to modify or delete it, to avoid failed tool calls.
+- **Deeper Root Cause Analysis:** When a test fails, I will focus more on identifying the fundamental reason (e.g., "Why did the API call fail?") rather than just fixing the immediate symptom (e.g., "The test failed").
+- **Designing for Dynamism First:** When dealing with data that can change, like a list of API-provided models, my default approach should be to build a dynamic solution from the start, rather than beginning with a hardcoded one.
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/reflections/20250614-task3-lms-studio-query-implementation.md b/docs-project/current/v.0.2.0-synapse/reflections/20250614-task3-lms-studio-query-implementation.md
new file mode 100644
index 0000000..8c1abf9
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/reflections/20250614-task3-lms-studio-query-implementation.md
@@ -0,0 +1,23 @@
+# Reflections Template
+
+## Stop Doing
+
+- Allowing stdout leakage in unit tests - this makes test output noisy and harder to debug
+- Writing integration tests that don't properly use VCR for recording HTTP interactions
+- Using inconsistent parameter handling between CLI arguments and method calls (mixing hash vs keyword arguments)
+- Relying on `exit` calls in CLI commands without proper testing patterns that handle SystemExit exceptions
+
+## Continue Doing
+
+- Using comprehensive VCR cassettes that include both health check and actual API calls for realistic integration testing
+- Following the ATOM architecture pattern (organisms composing molecules) for consistent code organization
+- Writing detailed unit tests with proper mocking to isolate components and test error scenarios
+- Using Aruba for CLI integration testing to properly test the executable behavior
+
+## Start Doing
+
+- Capturing stdout/stderr output in all tests that involve print statements to prevent leakage
+- Using SystemExit exceptions in tests when mocking exit calls to ensure proper test flow control
+- Adding explicit parameter validation and type checking in CLI command methods
+- Creating more comprehensive error handling scenarios in integration tests using WebMock for server unavailability
+- Ensuring VCR cassettes include all necessary HTTP interactions (both GET /models and POST /chat/completions)
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md
index 0eac1f3..5f85a71 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md
@@ -1,6 +1,6 @@
 ---
 id: v.0.2.0+task.12
-status: pending
+status: done
 priority: high
 estimate: 3h
 dependencies: [v.0.2.0+task.1]
@@ -54,18 +54,18 @@ Update the setup and development documentation to reflect the new requirements a
 
 ### Planning Steps
 
-* [ ] Review current SETUP.md and DEVELOPMENT.md to understand existing structure
+* [x] Review current SETUP.md and DEVELOPMENT.md to understand existing structure
   > TEST: Development Docs Structure Analysis
   > Type: Pre-condition Check
   > Assert: Current documentation structure and sections are identified
   > Manual Verification: Manually review `docs/SETUP.md` and `docs/DEVELOPMENT.md` to understand their existing structure and sections.
-* [ ] Review .tool-versions and new dependencies to understand updated requirements
-* [ ] Analyze VCR setup and testing patterns from task.1 implementation
-* [ ] Plan content updates to maintain document flow and usability
+* [x] Review .tool-versions and new dependencies to understand updated requirements
+* [x] Analyze VCR setup and testing patterns from task.1 implementation
+* [x] Plan content updates to maintain document flow and usability
 
 ### Execution Steps
 
-- [ ] Update `docs/SETUP.md` "Prerequisites" section:
+- [x] Update `docs/SETUP.md` "Prerequisites" section:
   - Update Ruby version requirement to 3.4.2 (from .tool-versions)
   - Add "Configuration" section for API keys setup
   - Document GEMINI_API_KEY and .env.example usage for development
@@ -74,15 +74,15 @@ Update the setup and development documentation to reflect the new requirements a
   > Type: Action Validation
   > Assert: SETUP.md reflects all new requirements and configuration
   > Manual Verification: Review `docs/SETUP.md` to confirm it reflects all new requirements, including Ruby version, API key setup instructions, and `.env.example`/`spec/.env` usage.
-- [ ] Update `docs/DEVELOPMENT.md` "Testing Strategy" section:
+- [x] Update `docs/DEVELOPMENT.md` "Testing Strategy" section:
   - Add new subsection for "Integration Tests with VCR"
   - Document VCR usage for API-dependent tests
   - Link to docs/testing-with-vcr.md for detailed VCR information
   - Explain API key setup in spec/ for recording new cassettes
-- [ ] Update DEVELOPMENT.md "Build System Commands" section:
+- [x] Update DEVELOPMENT.md "Build System Commands" section:
   - Document new gem installation verification step in bin/build
   - Explain enhanced build confidence through local gem installation testing
-- [ ] Add new section in DEVELOPMENT.md for "Architectural Patterns":
+- [x] Add new section in DEVELOPMENT.md for "Architectural Patterns":
   - Mention Zeitwerk autoloading adoption
   - Document dry-monitor observability pattern
   - Explain ATOM-based component organization
@@ -90,21 +90,21 @@ Update the setup and development documentation to reflect the new requirements a
   > Type: Action Validation
   > Assert: DEVELOPMENT.md includes all new patterns and testing strategies
   > Manual Verification: Review `docs/DEVELOPMENT.md` to confirm it includes the new "Integration Tests with VCR" section, updated "Build System Commands," and the new "Architectural Patterns" section (Zeitwerk, dry-monitor, ATOM organization).
-- [ ] Add cross-references between SETUP.md and DEVELOPMENT.md for consistency
-- [ ] Ensure all new development dependencies are mentioned with their development purpose
+- [x] Add cross-references between SETUP.md and DEVELOPMENT.md for consistency
+- [x] Ensure all new development dependencies are mentioned with their development purpose
 
 ## Acceptance Criteria
 
-- [ ] SETUP.md "Prerequisites" section specifies Ruby >= 3.4.2
-- [ ] SETUP.md includes "Configuration" section with GEMINI_API_KEY setup instructions
-- [ ] SETUP.md documents .env.example usage and spec/.env setup for VCR
-- [ ] DEVELOPMENT.md "Testing Strategy" includes VCR integration testing section
-- [ ] DEVELOPMENT.md links to docs/testing-with-vcr.md for detailed VCR information
-- [ ] DEVELOPMENT.md "Build System Commands" documents new gem verification step
-- [ ] DEVELOPMENT.md includes new "Architectural Patterns" section covering Zeitwerk, dry-monitor, and ATOM organization
-- [ ] Both documents maintain consistency in terminology and cross-reference appropriately
-- [ ] All new development dependencies are explained with their purpose
-- [ ] Documents follow existing project documentation style and formatting
+- [x] SETUP.md "Prerequisites" section specifies Ruby >= 3.4.2
+- [x] SETUP.md includes "Configuration" section with GEMINI_API_KEY setup instructions
+- [x] SETUP.md documents .env.example usage and spec/.env setup for VCR
+- [x] DEVELOPMENT.md "Testing Strategy" includes VCR integration testing section
+- [x] DEVELOPMENT.md links to docs/testing-with-vcr.md for detailed VCR information
+- [x] DEVELOPMENT.md "Build System Commands" documents new gem verification step
+- [x] DEVELOPMENT.md includes new "Architectural Patterns" section covering Zeitwerk, dry-monitor, and ATOM organization
+- [x] Both documents maintain consistency in terminology and cross-reference appropriately
+- [x] All new development dependencies are explained with their purpose
+- [x] Documents follow existing project documentation style and formatting
 
 ## Out of Scope
 
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md
index aa970f0..54d1193 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md
@@ -1,6 +1,6 @@
 ---
 id: v.0.2.0+task.2 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
-status: pending # See [Project Management Guide](project-management.md) for all possible values
+status: done # See [Project Management Guide](project-management.md) for all possible values
 priority: high
 estimate: 4h
 dependencies: [v.0.2.0+task.1]
@@ -38,16 +38,14 @@ Implement API key discovery system (R-LLM-2) that supports finding Gemini API ke
 
 #### Create
 
-- lib/coding_agent_tools/config/api_key_resolver.rb
-- lib/coding_agent_tools/config/gemini_config.rb
-- spec/config/api_key_resolver_spec.rb
-- spec/config/gemini_config_spec.rb
-- spec/fixtures/gemini_config_sample
+- ✅ lib/coding_agent_tools/molecules/api_credentials.rb (COMPLETED - implements multi-source API key discovery)
+- ✅ lib/coding_agent_tools/atoms/env_reader.rb (COMPLETED - handles environment variable and .env file reading)
+- ✅ spec/coding_agent_tools/molecules/api_credentials_spec.rb (COMPLETED - comprehensive test coverage)
 
 #### Modify
 
-- lib/coding_agent_tools/llm/gemini_client.rb (integrate key discovery)
-- lib/coding_agent_tools.rb (require new modules)
+- ✅ lib/coding_agent_tools/organisms/gemini_client.rb (COMPLETED - integrates with APICredentials via constructor)
+- ✅ lib/coding_agent_tools.rb (COMPLETED - modules auto-loaded via Zeitwerk)
 
 ## Phases
 
@@ -77,39 +75,39 @@ Implement API key discovery system (R-LLM-2) that supports finding Gemini API ke
 
 *Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._
 
-- [ ] Create ApiKeyResolver class with multi-source discovery
-  > TEST: Verify ApiKeyResolver Class
+- [x] Create APICredentials molecule with multi-source discovery
+  > TEST: Verify APICredentials Class
   > Type: Action Validation
-  > Assert: ApiKeyResolver class exists with resolve method
-  > Command: ruby -e "require './lib/coding_agent_tools/config/api_key_resolver'; puts CodingAgentTools::Config::ApiKeyResolver.new.respond_to?(:resolve)"
-- [ ] Implement environment variable lookup for GEMINI_API_KEY
+  > Assert: APICredentials class exists with api_key method
+  > Command: ruby -e "require './lib/coding_agent_tools/molecules/api_credentials'; puts CodingAgentTools::Molecules::APICredentials.new(env_key_name: 'GEMINI_API_KEY').respond_to?(:api_key)"
+- [x] Implement environment variable lookup for GEMINI_API_KEY
   > TEST: Verify Environment Variable Lookup
   > Type: Action Validation
-  > Assert: Resolver finds key from environment variable when no config file exists
-  > Command: rm -f ~/.gemini/config && GEMINI_API_KEY=test_key ruby -e "require './lib/coding_agent_tools/config/api_key_resolver'; puts CodingAgentTools::Config::ApiKeyResolver.new.resolve"
-- [ ] Create GeminiConfig class for ~/.gemini/config file parsing
-- [ ] Implement YAML/JSON config file reader with error handling
+  > Assert: APICredentials finds key from environment variable
+  > Command: GEMINI_API_KEY=test_key ruby -e "require './lib/coding_agent_tools/molecules/api_credentials'; puts CodingAgentTools::Molecules::APICredentials.new(env_key_name: 'GEMINI_API_KEY').api_key"
+- [x] Create EnvReader atom for .env file parsing and environment access
+- [x] Implement .env file reader with automatic discovery and error handling
   > TEST: Verify Config File Reading
   > Type: Action Validation
-  > Assert: Config reader parses sample config file
-  > Command: ruby -e "require './lib/coding_agent_tools/config/gemini_config'; puts CodingAgentTools::Config::GeminiConfig.from_file('spec/fixtures/gemini_config_sample').api_key"
-- [ ] Integrate key discovery into GeminiClient initialization
-- [ ] Add comprehensive unit tests for all discovery scenarios
+  > Assert: EnvReader loads .env files correctly
+  > Command: ruby -e "require './lib/coding_agent_tools/atoms/env_reader'; puts CodingAgentTools::Atoms::EnvReader.load_env_file('.env')"
+- [x] Integrate key discovery into GeminiClient initialization
+- [x] Add comprehensive unit tests for all discovery scenarios
   > TEST: Verify Test Coverage
   > Type: Action Validation
-  > Assert: All config classes have corresponding test files
-  > Command: find spec -name "*config*" -o -name "*api_key*"
+  > Assert: All molecules have corresponding test files
+  > Command: find spec -name "*api_credentials*" -o -name "*env_reader*"
 
 ## Acceptance Criteria
 
 *Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._
 
-- [ ] AC 1: System successfully discovers API key from GEMINI_API_KEY environment variable
-- [ ] AC 2: System successfully reads API key from ~/.gemini/config file
-- [ ] AC 3: Priority order is enforced (config file takes precedence over ENV variable)
-- [ ] AC 4: Clear error messages when API key is not found or invalid
-- [ ] AC 5: GeminiClient integrates seamlessly with key discovery system
-- [ ] AC 6: All unit tests pass with >95% code coverage
+- [x] AC 1: System successfully discovers API key from GEMINI_API_KEY environment variable
+- [x] AC 2: System successfully reads API key from .env files (implemented via EnvReader atom)
+- [x] AC 3: Priority order is enforced (singleton config > ENV variable > error)
+- [x] AC 4: Clear error messages when API key is not found or invalid
+- [x] AC 5: GeminiClient integrates seamlessly with APICredentials molecule
+- [x] AC 6: All unit tests pass with comprehensive coverage
 
 ## Out of Scope
 
@@ -122,6 +120,8 @@ Implement API key discovery system (R-LLM-2) that supports finding Gemini API ke
 ## References
 
 - Fish implementation: docs-project/backlog/v.0.2.0-synapse/docs/gemini-query.fish (shows .env file loading pattern)
-- Priority: ~/.gemini/config > GEMINI_API_KEY environment variable
+- Implemented Priority: Singleton config > GEMINI_API_KEY environment variable > .env file > error
+- Architecture: APICredentials molecule composes EnvReader atom for multi-source key discovery
+- Integration: GeminiClient organism uses APICredentials for authentication
 
 ```
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md
index d2cc25d..7e81164 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md
@@ -1,9 +1,9 @@
 ---
 id: v.0.2.0+task.3 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
-status: pending # See [Project Management Guide](project-management.md) for all possible values
+status: done # See [Project Management Guide](project-management.md) for all possible values
 priority: medium
 estimate: 6h
-dependencies: []
+dependencies: [v.0.2.0+task.2]
 ---
 
 # Implement lms-studio-query Command
@@ -24,11 +24,11 @@ _Result excerpt:_
 
 ## Objective
 
-Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studio on `localhost:1234` using the server's REST protocol for offline inference. Default model should be "mistral-small-24b-instruct-2501@8bit" but configurable. This provides offline LLM capabilities as an alternative to cloud-based services.
+Implement the `llm-lmstudio-query` command (R-LLM-3) that interfaces with LM Studio on `localhost:1234` using the server's REST protocol for offline inference. Default model should be "mistralai/devstral-small-2505" but configurable. This provides offline LLM capabilities as an alternative to cloud-based services.
 
 ## Scope of Work
 
-- Create CLI command `lms-studio-query` with Ruby implementation
+- Create CLI command `llm-lmstudio-query` with Ruby implementation
 - Integrate with LM Studio REST API on localhost:1234
 - Support prompt input from string argument or file path
 - Handle response formatting and error scenarios
@@ -38,17 +38,21 @@ Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studi
 
 #### Create
 
-- lib/coding_agent_tools/commands/lms_studio_query.rb
-- lib/coding_agent_tools/llm/lm_studio_client.rb
-- bin/lms-studio-query (executable CLI script)
-- spec/commands/lms_studio_query_spec.rb
-- spec/llm/lm_studio_client_spec.rb
+- lib/coding_agent_tools/cli/commands/lms/query.rb
+- lib/coding_agent_tools/organisms/lm_studio_client.rb
+- exe/llm-lmstudio-query (executable CLI script)
+- spec/coding_agent_tools/cli/commands/lms/query_spec.rb
+- spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
+- spec/integration/llm_lmstudio_query_integration_spec.rb (Aruba + VCR integration tests)
 
 #### Modify
 
-- lib/coding_agent_tools.rb (require new modules)
 - coding_agent_tools.gemspec (add http client dependencies if needed)
 
+#### Note on Zeitwerk
+
+- lib/coding_agent_tools.rb modifications may not be needed due to Zeitwerk autoloading (ADR-002), as long as proper file naming conventions are followed
+
 ## Phases
 
 1. Research & API Analysis
@@ -64,52 +68,58 @@ Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studi
 
 *Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._
 
-- [ ] Research LM Studio REST API documentation and endpoints (reference lms-query.fish)
+- [x] Research LM Studio REST API documentation and endpoints (reference lms-query.fish)
   > TEST: API Documentation Review
   > Type: Pre-condition Check
   > Assert: Understand LM Studio REST protocol and response formats
   > Command: Manual testing with curl against localhost:1234
-- [ ] Analyze LM Studio server startup and configuration requirements
-- [ ] Design error handling for server unavailable scenarios
-- [ ] Plan consistent interface with Gemini client for future abstraction
+- [x] Analyze LM Studio server startup and configuration requirements
+- [x] Design error handling for server unavailable scenarios
+- [x] Plan consistent interface with Gemini client for future abstraction
 
 ### Execution Steps
 
 *Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._
 
-- [ ] Create LMStudioClient class with HTTP REST integration (based on lms-query.fish)
+- [x] Create LMStudioClient organism with HTTP REST integration (reusing HTTPRequestBuilder and APIResponseParser molecules)
   > TEST: Verify LMStudioClient Class
   > Type: Action Validation
   > Assert: LMStudioClient class exists with generate_text method
-  > Command: ruby -e "require './lib/coding_agent_tools/llm/lm_studio_client'; puts CodingAgentTools::LLM::LMStudioClient.new.respond_to?(:generate_text)"
-- [ ] Implement server health check and connection validation
+  > Command: ruby -e "require './lib/coding_agent_tools/organisms/lm_studio_client'; puts CodingAgentTools::Organisms::LMStudioClient.new.respond_to?(:generate_text)"
+- [x] Implement server health check and connection validation
   > TEST: Verify Server Health Check
   > Type: Action Validation
   > Assert: Client can detect if LM Studio server is running
-  > Command: ruby -e "require './lib/coding_agent_tools/llm/lm_studio_client'; puts CodingAgentTools::LLM::LMStudioClient.new.server_available?"
-- [ ] Implement CLI command class with argument parsing
-- [ ] Create executable bin script that calls the command class
+  > Command: ruby -e "require './lib/coding_agent_tools/organisms/lm_studio_client'; puts CodingAgentTools::Organisms::LMStudioClient.new.server_available?"
+- [x] Implement CLI command class with argument parsing
+- [x] Create executable script in exe/ that calls the CLI command class
   > TEST: Verify CLI Executable
   > Type: Action Validation
-  > Assert: lms-studio-query command is executable and shows help
-  > Command: bin/lms-studio-query --help
-- [ ] Add comprehensive unit tests including mock server scenarios
+  > Assert: llm-lmstudio-query command is executable and shows help
+  > Command: exe/llm-lmstudio-query --help
+- [x] Add comprehensive unit tests including mock server scenarios
   > TEST: Verify Test Coverage
   > Type: Action Validation
   > Assert: All new classes have corresponding test files with mocks
   > Command: find spec -name "*lm_studio*" -o -name "*lms*"
-- [ ] Implement integration test with actual LM Studio instance
+- [x] Integrate APICredentials molecule for authentication (reuse from Task 2)
+- [x] Create integration tests using Aruba + VCR pattern (following llm_gemini_query_integration_spec.rb)
+  > TEST: Verify Integration Test Setup
+  > Type: Action Validation
+  > Assert: Integration test file exists and follows Aruba/VCR pattern
+  > Command: find spec/integration -name "*llm_lmstudio*"
+- [x] Configure VCR cassettes for LM Studio API interactions
 
 ## Acceptance Criteria
 
 *Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._
 
-- [ ] AC 1: `lms-studio-query` command accepts prompts as string arguments and file paths
-- [ ] AC 2: Command successfully interfaces with LM Studio REST API on localhost:1234
-- [ ] AC 3: Response output matches expected format from LM Studio
-- [ ] AC 4: Clear error messages when LM Studio server is not available
-- [ ] AC 5: All unit tests pass with >95% code coverage
-- [ ] AC 6: Integration test successfully calls live LM Studio instance
+- [x] AC 1: `llm-lmstudio-query` command accepts prompts as string arguments and file paths
+- [x] AC 2: Command successfully interfaces with LM Studio REST API on localhost:1234
+- [x] AC 3: Response output matches expected format from LM Studio
+- [x] AC 4: Clear error messages when LM Studio server is not available
+- [x] AC 5: All unit tests pass with >95% code coverage
+- [x] AC 6: Integration test successfully calls live LM Studio instance
 
 ## Out of Scope
 
@@ -124,6 +134,11 @@ Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studi
 
 - Fish implementation: docs-project/backlog/v.0.2.0-synapse/docs/lms-query.fish
 - LM Studio API endpoint: http://localhost:1234/v1/chat/completions
-- Default model: mistral-small-24b-instruct-2501@8bit
+- Default model: mistralai/devstral-small-2505
+- Architecture: Follow ATOM pattern - LMStudioClient organism composes APICredentials, HTTPRequestBuilder, and APIResponseParser molecules
+- Reuse existing molecules: APICredentials (from Task 2), HTTPRequestBuilder, APIResponseParser
+- CLI pattern: Follow same structure as lib/coding_agent_tools/cli/commands/llm/query.rb
+- Integration testing: Use Aruba + VCR pattern similar to llm_gemini_query_integration_spec.rb
+- Zeitwerk: Follow ADR-002 file naming conventions to avoid manual require statements
 
 ```
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md
index be25ce1..03de153 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md
@@ -1,9 +1,9 @@
 ---
 id: v.0.2.0+task.4 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
-status: pending # See [Project Management Guide](project-management.md) for all possible values
+status: done # See [Project Management Guide](project-management.md) for all possible values
 priority: medium
 estimate: 3h
-dependencies: [v.0.2.0+task.1, v.0.2.0+task.3]
+dependencies: [v.0.2.0+task.3]
 ---
 
 # Add Model Override Flag Support
@@ -24,11 +24,12 @@ _Result excerpt:_
 
 ## Objective
 
-Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-studio-query` commands to allow users to override default models. Default models: Gemini uses "gemini-2.0-flash-lite" and LM Studio uses "mistral-small-24b-instruct-2501@8bit". This provides flexibility for users to select specific models based on their needs or availability.
+Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `llm-lmstudio-query` commands to allow users to override default models. Default models: Gemini uses "gemini-2.0-flash-lite" and LM Studio uses "mistralai/devstral-small-2505". Additionally, implement separate model listing commands `exe/llm-gemini-models` and `exe/llm-lmstudio-models` with fuzzy search filtering capability. This provides flexibility for users to select specific models based on their needs or availability.
 
 ## Scope of Work
 
-- Add `--model` flag to both llm-gemini-query and lms-studio-query commands
+- Add `--model` flag to both llm-gemini-query and llm-lmstudio-query commands
+- Implement separate model listing commands with fuzzy search filtering
 - Implement model validation and error handling for invalid models
 - Update client classes to support dynamic model selection
 - Add configuration for default model settings
@@ -38,23 +39,29 @@ Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-
 
 #### Create
 
-- spec/integration/model_override_spec.rb
+- lib/coding_agent_tools/cli/commands/llm/models.rb
+- lib/coding_agent_tools/cli/commands/lms/models.rb
+- exe/llm-gemini-models (executable CLI script)
+- exe/llm-lmstudio-models (executable CLI script)
+- spec/coding_agent_tools/cli/commands/llm/models_spec.rb
+- spec/coding_agent_tools/cli/commands/lms/models_spec.rb
 
 #### Modify
 
-- lib/coding_agent_tools/commands/llm_gemini_query.rb (add --model flag)
-- lib/coding_agent_tools/commands/lms_studio_query.rb (add --model flag)
-- lib/coding_agent_tools/llm/gemini_client.rb (support model parameter)
-- lib/coding_agent_tools/llm/lm_studio_client.rb (support model parameter)
-- bin/llm-gemini-query (update help text)
-- bin/lms-studio-query (update help text)
+- lib/coding_agent_tools/cli/commands/llm/query.rb (✅ already has --model flag)
+- lib/coding_agent_tools/cli/commands/lms/query.rb (add --model flag, from Task 3)
+- lib/coding_agent_tools/organisms/gemini_client.rb (✅ already supports model parameter)
+- lib/coding_agent_tools/organisms/lm_studio_client.rb (support model parameter)
+- exe/llm-gemini-query (update help text)
+- exe/llm-lmstudio-query (update help text)
 
 ## Phases
 
 1. Design & Analysis
-2. CLI Flag Implementation
-3. Client Integration
-4. Testing & Documentation
+2. Model Listing Commands Implementation
+3. CLI Flag Implementation (partially done for Gemini)
+4. Client Integration
+5. Testing & Documentation
 
 ## Implementation Plan
 
@@ -64,60 +71,81 @@ Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-
 
 *Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._
 
-- [ ] Research available Gemini models and their identifiers (reference gemini-query.fish)
+- [x] Research available Gemini models and their identifiers (reference gemini-query.fish)
   > TEST: Model Research
   > Type: Pre-condition Check
   > Assert: Understand valid model names for Gemini and LM Studio
   > Command: Manual review of API documentation and Fish implementations
-- [ ] Analyze current CLI argument parsing patterns in existing commands
-- [ ] Design model validation strategy and error messages
-- [ ] Plan default model configuration approach
+- [x] Analyze current CLI argument parsing patterns in existing commands
+- [x] Design model validation strategy and error messages
+- [x] Plan default model configuration approach
+- [x] Design fuzzy search filtering mechanism for model listing
+- [x] Plan model listing data structure and API integration approach
 
 ### Execution Steps
 
 *Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._
 
-- [ ] Add --model flag to llm-gemini-query command parser
+- [x] Add --model flag to llm-gemini-query command parser (✅ already implemented)
   > TEST: Verify Gemini Model Flag
   > Type: Action Validation
   > Assert: llm-gemini-query accepts --model flag
-  > Command: bin/llm-gemini-query --help | grep -i model
-- [ ] Add --model flag to lms-studio-query command parser
+  > Command: exe/llm-gemini-query --help | grep -i model
+- [x] Add --model flag to llm-lmstudio-query command parser
   > TEST: Verify LM Studio Model Flag
   > Type: Action Validation
-  > Assert: lms-studio-query accepts --model flag  
-  > Command: bin/lms-studio-query --help | grep -i model
-- [ ] Update GeminiClient to accept model parameter in constructor
+  > Assert: llm-lmstudio-query accepts --model flag  
+  > Command: exe/llm-lmstudio-query --help | grep -i model
+- [x] Update GeminiClient to accept model parameter in constructor (✅ already implemented)
   > TEST: Verify Gemini Client Model Support
   > Type: Action Validation
   > Assert: GeminiClient accepts model parameter
-  > Command: ruby -e "require './lib/coding_agent_tools/llm/gemini_client'; puts CodingAgentTools::LLM::GeminiClient.new(model: 'test').respond_to?(:generate_text)"
-- [ ] Update LMStudioClient to accept model parameter in constructor
-- [ ] Implement model validation with helpful error messages
+  > Command: ruby -e "require './lib/coding_agent_tools/organisms/gemini_client'; puts CodingAgentTools::Organisms::GeminiClient.new(model: 'test').respond_to?(:generate_text)"
+- [x] Update LMStudioClient to accept model parameter in constructor
+- [x] Create llm-gemini-models command with fuzzy search filtering
+  > TEST: Verify Gemini Models Command
+  > Type: Action Validation
+  > Assert: llm-gemini-models command exists and supports filtering
+  > Command: exe/llm-gemini-models --help
+- [x] Create llm-lmstudio-models command with fuzzy search filtering
+  > TEST: Verify LM Studio Models Command
+  > Type: Action Validation
+  > Assert: llm-lmstudio-models command exists and supports filtering
+  > Command: exe/llm-lmstudio-models --help
+- [x] Implement model validation with helpful error messages
   > TEST: Verify Model Validation
   > Type: Action Validation
   > Assert: Commands show helpful error for invalid models
-  > Command: bin/llm-gemini-query --model invalid_model "test" 2>&1 | grep -i "invalid model"
-- [ ] Add integration tests for model override functionality
-  > TEST: Verify Integration Tests
+  > Command: exe/llm-gemini-query --model invalid_model "test" 2>&1 | grep -i "invalid model"
+- [x] Add model override tests to existing integration test files
+  > TEST: Verify Model Override in Gemini Integration Tests
+  > Type: Action Validation
+  > Assert: Gemini integration tests include model override scenarios (test with gemini-1.5-flash)
+  > Command: grep -n "model.*gemini-1.5-flash" spec/integration/llm_gemini_query_integration_spec.rb
+  > TEST: Verify Model Override in LM Studio Integration Tests
   > Type: Action Validation
-  > Assert: Integration test file exists and tests model overrides
-  > Command: find spec -name "*model_override*"
+  > Assert: LM Studio integration tests include model override scenarios (test with mistralai/devstral-small-2505)
+  > Command: grep -n "model.*mistralai/devstral-small-2505" spec/integration/llm_lmstudio_query_integration_spec.rb
 
 ## Acceptance Criteria
 
 *Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._
 
-- [ ] AC 1: Both commands accept --model flag with proper argument parsing
-- [ ] AC 2: Model parameter is passed through to respective client classes
-- [ ] AC 3: Invalid model names produce clear error messages
-- [ ] AC 4: Default models work when --model flag is not specified (gemini-2.0-flash-lite for Gemini, mistral-small-24b-instruct-2501@8bit for LM Studio)
-- [ ] AC 5: Help text documents available models and usage examples
-- [ ] AC 6: All unit and integration tests pass
+- [x] AC 1: Gemini command accepts --model flag with proper argument parsing (✅ completed)
+- [x] AC 1b: LM Studio command accepts --model flag with proper argument parsing
+- [x] AC 2: Model parameter is passed through to GeminiClient (✅ completed)
+- [x] AC 2b: Model parameter is passed through to LMStudioClient
+- [x] AC 3: Invalid model names produce clear error messages
+- [x] AC 4: Default models work when --model flag is not specified (gemini-2.0-flash-lite for Gemini, ✅ completed)
+- [x] AC 4b: Default model works for LM Studio (mistralai/devstral-small-2505)
+- [x] AC 5: Help text documents available models and usage examples
+- [x] AC 6: Model listing commands work with fuzzy search filtering
+- [x] AC 7: Model override functionality is tested in existing integration tests (llm_gemini_query_integration_spec.rb and llm_lmstudio_query_integration_spec.rb)
+- [x] AC 8: All unit and integration tests pass
 
 ## Out of Scope
 
-- ❌ Dynamic model discovery or listing from services
+- ❌ Dynamic model discovery from remote APIs (will use manual/hardcoded lists)
 - ❌ Model capability validation or compatibility checking
 - ❌ Performance benchmarking between different models
 - ❌ Model-specific parameter tuning (temperature, top-k, etc.)
@@ -130,8 +158,13 @@ Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-
   - docs-project/backlog/v.0.2.0-synapse/docs/gemini-query.fish
   - docs-project/backlog/v.0.2.0-synapse/docs/lms-query.fish
 - Default models:
-  - Gemini: gemini-2.0-flash-lite
-  - LM Studio: mistral-small-24b-instruct-2501@8bit
+  - Gemini: gemini-2.0-flash-lite (✅ implemented)
+  - LM Studio: mistralai/devstral-small-2505
+- Current implementation: lib/coding_agent_tools/cli/commands/llm/query.rb already has --model flag
+- Architecture: Model listing commands follow same CLI pattern as query commands
+- Fuzzy search: Use simple string matching for model name filtering
+- Integration testing: Add model override tests to existing integration specs rather than separate file
+- Test models: Use gemini-1.5-flash for Gemini tests and mistralai/devstral-small-2505 for LM Studio tests in VCR cassettes
 
 
 ```
diff --git a/exe/llm-gemini-models b/exe/llm-gemini-models
new file mode 100755
index 0000000..3447a04
--- /dev/null
+++ b/exe/llm-gemini-models
@@ -0,0 +1,104 @@
+#!/usr/bin/env ruby
+
+# Only require bundler/setup if it hasn't been loaded already
+# (e.g., via RUBYOPT) and we're in a bundled environment
+unless defined?(Bundler)
+  if ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../Gemfile", __FILE__))
+    begin
+      require "bundler/setup"
+    rescue LoadError
+      # If bundler isn't available, continue without it
+      # This can happen in subprocess calls where Ruby version differs
+    end
+  end
+end
+
+# Set up load paths for development if necessary (e.g., when not installed as a gem)
+# This ensures that `lib` is on the load path.
+# If the gem is installed, this line is not strictly necessary but doesn't hurt.
+# If running from the project's exe directory, it's crucial.
+$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
+
+require "coding_agent_tools"
+require "coding_agent_tools/cli"
+require "coding_agent_tools/error_reporter"
+
+# This executable is a convenience wrapper that calls the main CLI
+# with the 'llm models' command prepended to the arguments
+begin
+  # Prepend 'llm models' to the arguments and call the main CLI
+  modified_args = ["llm", "models"] + ARGV
+
+  # Replace ARGV with our modified arguments
+  ARGV.clear
+  ARGV.concat(modified_args)
+
+  # Ensure LLM commands are registered before calling CLI
+  CodingAgentTools::Cli::Commands.register_llm_commands
+
+  # Capture both stdout and stderr to modify error/help messages
+  original_stdout = $stdout
+  original_stderr = $stderr
+  require "stringio"
+  # Note: Capturing output with StringIO might strip/affect ANSI color codes from the underlying CLI command.
+  captured_stdout = StringIO.new
+  captured_stderr = StringIO.new
+
+  $stdout = captured_stdout
+  $stderr = captured_stderr
+
+  # Call the main CLI
+  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
+
+  # If we get here, the command succeeded without raising SystemExit
+  # Get the captured output and display it
+  stdout_content = captured_stdout.string
+  stderr_content = captured_stderr.string
+
+  # Restore stdout and stderr
+  $stdout = original_stdout
+  $stderr = original_stderr
+
+  # Modify messages to show only 'llm-gemini-models' instead of full path
+  if stdout_content.include?("llm models") || stderr_content.include?("llm models")
+    stdout_content = stdout_content.gsub("llm-gemini-models llm models", "llm-gemini-models")
+    stderr_content = stderr_content.gsub(/"[^"]*llm[^"]*models"/, '"llm-gemini-models"')
+    stderr_content = stderr_content.gsub(/Usage: "[^"]*llm[^"]*models[^"]*"/, 'Usage: "llm-gemini-models"')
+  end
+
+  # Print the output
+  $stdout.print stdout_content unless stdout_content.empty?
+  $stderr.print stderr_content unless stderr_content.empty?
+rescue SystemExit => e
+  # Get the captured output
+  stdout_content = captured_stdout.string
+  stderr_content = captured_stderr.string
+
+  # Restore stdout and stderr
+  $stdout = original_stdout
+  $stderr = original_stderr
+
+  # Modify messages to show only 'llm-gemini-models' instead of full path
+  if stdout_content.include?("llm models") || stderr_content.include?("llm models")
+    stdout_content = stdout_content.gsub("llm-gemini-models llm models", "llm-gemini-models")
+    stderr_content = stderr_content.gsub(/"[^"]*llm[^"]*models"/, '"llm-gemini-models"')
+    stderr_content = stderr_content.gsub(/Usage: "[^"]*llm[^"]*models[^"]*"/, 'Usage: "llm-gemini-models"')
+  end
+
+  # Print the modified output
+  $stdout.print stdout_content unless stdout_content.empty?
+  $stderr.print stderr_content unless stderr_content.empty?
+
+  # Re-raise the SystemExit to preserve the exit code
+  raise e
+rescue => e
+  $stdout = original_stdout if original_stdout
+  $stderr = original_stderr if original_stderr
+  # Handle all errors through the centralized error reporter
+  CodingAgentTools::ErrorReporter.call(e, debug: ENV["DEBUG"] == "true")
+  exit 1
+ensure
+  # Always restore stdout and stderr in case of any unexpected issues
+  $stdout = original_stdout if original_stdout
+  $stderr = original_stderr if original_stderr
+end
diff --git a/exe/llm-lmstudio-models b/exe/llm-lmstudio-models
new file mode 100755
index 0000000..6d507c9
--- /dev/null
+++ b/exe/llm-lmstudio-models
@@ -0,0 +1,104 @@
+#!/usr/bin/env ruby
+
+# Only require bundler/setup if it hasn't been loaded already
+# (e.g., via RUBYOPT) and we're in a bundled environment
+unless defined?(Bundler)
+  if ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../Gemfile", __FILE__))
+    begin
+      require "bundler/setup"
+    rescue LoadError
+      # If bundler isn't available, continue without it
+      # This can happen in subprocess calls where Ruby version differs
+    end
+  end
+end
+
+# Set up load paths for development if necessary (e.g., when not installed as a gem)
+# This ensures that `lib` is on the load path.
+# If the gem is installed, this line is not strictly necessary but doesn't hurt.
+# If running from the project's exe directory, it's crucial.
+$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
+
+require "coding_agent_tools"
+require "coding_agent_tools/cli"
+require "coding_agent_tools/error_reporter"
+
+# This executable is a convenience wrapper that calls the main CLI
+# with the 'lms models' command prepended to the arguments
+begin
+  # Prepend 'lms models' to the arguments and call the main CLI
+  modified_args = ["lms", "models"] + ARGV
+
+  # Replace ARGV with our modified arguments
+  ARGV.clear
+  ARGV.concat(modified_args)
+
+  # Ensure LMS commands are registered before calling CLI
+  CodingAgentTools::Cli::Commands.register_lms_commands
+
+  # Capture both stdout and stderr to modify error/help messages
+  original_stdout = $stdout
+  original_stderr = $stderr
+  require "stringio"
+  # Note: Capturing output with StringIO might strip/affect ANSI color codes from the underlying CLI command.
+  captured_stdout = StringIO.new
+  captured_stderr = StringIO.new
+
+  $stdout = captured_stdout
+  $stderr = captured_stderr
+
+  # Call the main CLI
+  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
+
+  # If we get here, the command succeeded without raising SystemExit
+  # Get the captured output and display it
+  stdout_content = captured_stdout.string
+  stderr_content = captured_stderr.string
+
+  # Restore stdout and stderr
+  $stdout = original_stdout
+  $stderr = original_stderr
+
+  # Modify messages to show only 'llm-lmstudio-models' instead of full path
+  if stdout_content.include?("lms models") || stderr_content.include?("lms models")
+    stdout_content = stdout_content.gsub("llm-lmstudio-models lms models", "llm-lmstudio-models")
+    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*models"/, '"llm-lmstudio-models"')
+    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*models[^"]*"/, 'Usage: "llm-lmstudio-models"')
+  end
+
+  # Print the output
+  $stdout.print stdout_content unless stdout_content.empty?
+  $stderr.print stderr_content unless stderr_content.empty?
+rescue SystemExit => e
+  # Get the captured output
+  stdout_content = captured_stdout.string
+  stderr_content = captured_stderr.string
+
+  # Restore stdout and stderr
+  $stdout = original_stdout
+  $stderr = original_stderr
+
+  # Modify messages to show only 'llm-lmstudio-models' instead of full path
+  if stdout_content.include?("lms models") || stderr_content.include?("lms models")
+    stdout_content = stdout_content.gsub("llm-lmstudio-models lms models", "llm-lmstudio-models")
+    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*models"/, '"llm-lmstudio-models"')
+    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*models[^"]*"/, 'Usage: "llm-lmstudio-models"')
+  end
+
+  # Print the modified output
+  $stdout.print stdout_content unless stdout_content.empty?
+  $stderr.print stderr_content unless stderr_content.empty?
+
+  # Re-raise the SystemExit to preserve the exit code
+  raise e
+rescue => e
+  $stdout = original_stdout if original_stdout
+  $stderr = original_stderr if original_stderr
+  # Handle all errors through the centralized error reporter
+  CodingAgentTools::ErrorReporter.call(e, debug: ENV["DEBUG"] == "true")
+  exit 1
+ensure
+  # Always restore stdout and stderr in case of any unexpected issues
+  $stdout = original_stdout if original_stdout
+  $stderr = original_stderr if original_stderr
+end
diff --git a/exe/llm-lmstudio-query b/exe/llm-lmstudio-query
new file mode 100755
index 0000000..aeeb7ce
--- /dev/null
+++ b/exe/llm-lmstudio-query
@@ -0,0 +1,104 @@
+#!/usr/bin/env ruby
+
+# Only require bundler/setup if it hasn't been loaded already
+# (e.g., via RUBYOPT) and we're in a bundled environment
+unless defined?(Bundler)
+  if ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../Gemfile", __FILE__))
+    begin
+      require "bundler/setup"
+    rescue LoadError
+      # If bundler isn't available, continue without it
+      # This can happen in subprocess calls where Ruby version differs
+    end
+  end
+end
+
+# Set up load paths for development if necessary (e.g., when not installed as a gem)
+# This ensures that `lib` is on the load path.
+# If the gem is installed, this line is not strictly necessary but doesn't hurt.
+# If running from the project's exe directory, it's crucial.
+$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
+
+require "coding_agent_tools"
+require "coding_agent_tools/cli"
+require "coding_agent_tools/error_reporter"
+
+# This executable is a convenience wrapper that calls the main CLI
+# with the 'lms query' command prepended to the arguments
+begin
+  # Prepend 'lms query' to the arguments and call the main CLI
+  modified_args = ["lms", "query"] + ARGV
+
+  # Replace ARGV with our modified arguments
+  ARGV.clear
+  ARGV.concat(modified_args)
+
+  # Ensure LMS commands are registered before calling CLI
+  CodingAgentTools::Cli::Commands.register_lms_commands
+
+  # Capture both stdout and stderr to modify error/help messages
+  original_stdout = $stdout
+  original_stderr = $stderr
+  require "stringio"
+  # Note: Capturing output with StringIO might strip/affect ANSI color codes from the underlying CLI command.
+  captured_stdout = StringIO.new
+  captured_stderr = StringIO.new
+
+  $stdout = captured_stdout
+  $stderr = captured_stderr
+
+  # Call the main CLI
+  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
+
+  # If we get here, the command succeeded without raising SystemExit
+  # Get the captured output and display it
+  stdout_content = captured_stdout.string
+  stderr_content = captured_stderr.string
+
+  # Restore stdout and stderr
+  $stdout = original_stdout
+  $stderr = original_stderr
+
+  # Modify messages to show only 'llm-lmstudio-query' instead of full path
+  if stdout_content.include?("lms query") || stderr_content.include?("lms query")
+    stdout_content = stdout_content.gsub("llm-lmstudio-query lms query", "llm-lmstudio-query")
+    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*query"/, '"llm-lmstudio-query"')
+    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*query[^"]*PROMPT"/, 'Usage: "llm-lmstudio-query PROMPT"')
+  end
+
+  # Print the output
+  $stdout.print stdout_content unless stdout_content.empty?
+  $stderr.print stderr_content unless stderr_content.empty?
+rescue SystemExit => e
+  # Get the captured output
+  stdout_content = captured_stdout.string
+  stderr_content = captured_stderr.string
+
+  # Restore stdout and stderr
+  $stdout = original_stdout
+  $stderr = original_stderr
+
+  # Modify messages to show only 'llm-lmstudio-query' instead of full path
+  if stdout_content.include?("lms query") || stderr_content.include?("lms query")
+    stdout_content = stdout_content.gsub("llm-lmstudio-query lms query", "llm-lmstudio-query")
+    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*query"/, '"llm-lmstudio-query"')
+    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*query[^"]*PROMPT"/, 'Usage: "llm-lmstudio-query PROMPT"')
+  end
+
+  # Print the modified output
+  $stdout.print stdout_content unless stdout_content.empty?
+  $stderr.print stderr_content unless stderr_content.empty?
+
+  # Re-raise the SystemExit to preserve the exit code
+  raise e
+rescue => e
+  $stdout = original_stdout if original_stdout
+  $stderr = original_stderr if original_stderr
+  # Handle all errors through the centralized error reporter
+  CodingAgentTools::ErrorReporter.call(e, debug: ENV["DEBUG"] == "true")
+  exit 1
+ensure
+  # Always restore stdout and stderr in case of any unexpected issues
+  $stdout = original_stdout if original_stdout
+  $stderr = original_stderr if original_stderr
+end
diff --git a/lib/coding_agent_tools.rb b/lib/coding_agent_tools.rb
index afeed44..98a7a7e 100644
--- a/lib/coding_agent_tools.rb
+++ b/lib/coding_agent_tools.rb
@@ -8,7 +8,8 @@ loader.inflector.inflect(
   "http_client" => "HTTPClient",
   "http_request_builder" => "HTTPRequestBuilder",
   "api_credentials" => "APICredentials",
-  "api_response_parser" => "APIResponseParser"
+  "api_response_parser" => "APIResponseParser",
+  "lm_studio_client" => "LMStudioClient"
 )
 loader.setup
 
diff --git a/lib/coding_agent_tools/cli.rb b/lib/coding_agent_tools/cli.rb
index a8f366f..616a612 100644
--- a/lib/coding_agent_tools/cli.rb
+++ b/lib/coding_agent_tools/cli.rb
@@ -27,17 +27,34 @@ module CodingAgentTools
         return if @llm_commands_registered
 
         require_relative "cli/commands/llm/query"
+        require_relative "cli/commands/llm/models"
 
         register "llm", aliases: [] do |prefix|
           prefix.register "query", Commands::LLM::Query
+          prefix.register "models", Commands::LLM::Models
         end
 
         @llm_commands_registered = true
       end
 
+      def self.register_lms_commands
+        return if @lms_commands_registered
+
+        require_relative "cli/commands/lms/query"
+        require_relative "cli/commands/lms/models"
+
+        register "lms", aliases: [] do |prefix|
+          prefix.register "query", Commands::LMS::Query
+          prefix.register "models", Commands::LMS::Models
+        end
+
+        @lms_commands_registered = true
+      end
+
       # Ensure commands are registered when CLI is used
       def self.call(*args)
         register_llm_commands
+        register_lms_commands
         super
       end
     end
diff --git a/lib/coding_agent_tools/cli/commands/llm/models.rb b/lib/coding_agent_tools/cli/commands/llm/models.rb
new file mode 100644
index 0000000..d0022e3
--- /dev/null
+++ b/lib/coding_agent_tools/cli/commands/llm/models.rb
@@ -0,0 +1,184 @@
+# frozen_string_literal: true
+
+require "dry/cli"
+require_relative "../../../organisms/gemini_client"
+require_relative "../../../molecules/model"
+
+module CodingAgentTools
+  module Cli
+    module Commands
+      module LLM
+        # Models command for listing available Google Gemini models
+        class Models < Dry::CLI::Command
+          desc "List available Google Gemini AI models"
+
+          option :filter, type: :string, aliases: ["f"],
+            desc: "Filter models by name (fuzzy search)"
+
+          option :format, type: :string, default: "text", values: %w[text json],
+            desc: "Output format (text or json)"
+
+          option :debug, type: :boolean, default: false, aliases: ["d"],
+            desc: "Enable debug output for verbose error information"
+
+          example [
+            "",
+            "--filter flash",
+            "--filter pro --format json",
+            "--format json"
+          ]
+
+          def call(**options)
+            models = get_available_models
+            filtered_models = filter_models(models, options[:filter])
+            output_models(filtered_models, options)
+          rescue => e
+            handle_error(e, options[:debug])
+          end
+
+          private
+
+          # Get list of available Gemini models dynamically from API
+          def get_available_models
+            client = Organisms::GeminiClient.new
+            models_response = client.list_models
+
+            # Filter to only include generateContent-capable models
+            generate_models = models_response.select do |model|
+              model[:supportedGenerationMethods]&.include?("generateContent")
+            end
+
+            # Convert API response to our model structure
+            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
+            generate_models.map do |model|
+              model_id = model[:name].sub("models/", "")
+              Molecules::Model.new(
+                id: model_id,
+                name: format_model_name(model[:name]),
+                description: model[:description] || "Gemini model",
+                default: model_id == default_model_id
+              )
+            end.sort_by(&:id)
+          rescue
+            # Fallback to hardcoded list if API fails
+            fallback_models
+          end
+
+          # Format model name for display
+          def format_model_name(model_name)
+            name = model_name.sub("models/", "")
+
+            # Convert kebab-case to title case
+            words = name.split("-").map do |word|
+              case word
+              when "gemini" then "Gemini"
+              when "flash" then "Flash"
+              when "pro" then "Pro"
+              when "lite" then "Lite"
+              when "preview" then "Preview"
+              else word.capitalize
+              end
+            end
+
+            words.join(" ")
+          end
+
+          # Fallback models if API call fails
+          def fallback_models
+            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
+            [
+              Molecules::Model.new(
+                id: "gemini-2.0-flash-lite",
+                name: "Gemini 2.0 Flash Lite",
+                description: "Fast and efficient model, good for most tasks",
+                default: default_model_id == "gemini-2.0-flash-lite"
+              ),
+              Molecules::Model.new(
+                id: "gemini-1.5-flash",
+                name: "Gemini 1.5 Flash",
+                description: "Fast multimodal model optimized for speed",
+                default: default_model_id == "gemini-1.5-flash"
+              ),
+              Molecules::Model.new(
+                id: "gemini-1.5-pro",
+                name: "Gemini 1.5 Pro",
+                description: "Mid-size multimodal model for complex reasoning tasks",
+                default: default_model_id == "gemini-1.5-pro"
+              )
+            ]
+          end
+
+          # Filter models based on search term
+          def filter_models(models, filter_term)
+            return models unless filter_term
+
+            filter_term = filter_term.downcase
+            models.select do |model|
+              model.id.downcase.include?(filter_term) ||
+                model.name.downcase.include?(filter_term) ||
+                model.description.downcase.include?(filter_term)
+            end
+          end
+
+          # Output models in the specified format
+          def output_models(models, options)
+            case options[:format]
+            when "json"
+              output_json_models(models)
+            else
+              output_text_models(models)
+            end
+          end
+
+          # Output models as formatted text
+          def output_text_models(models)
+            if models.empty?
+              puts "No models found matching the filter criteria."
+              return
+            end
+
+            puts "Available Gemini Models:"
+            puts "=" * 50
+
+            models.each do |model|
+              puts
+              puts model
+            end
+
+            puts
+            puts "Usage: llm-gemini-query \"your prompt\" --model MODEL_ID"
+          end
+
+          # Output models as JSON
+          def output_json_models(models)
+            default_model = models.find(&:default?)
+            output = {
+              models: models.map(&:to_json_hash),
+              count: models.length,
+              default_model: default_model&.id || Organisms::GeminiClient::DEFAULT_MODEL
+            }
+
+            puts JSON.pretty_generate(output)
+          end
+
+          # Handle errors
+          def handle_error(error, debug_enabled)
+            if debug_enabled
+              error_output("Error: #{error.class.name}: #{error.message}")
+              error_output("\nBacktrace:")
+              error.backtrace.each { |line| error_output("  #{line}") }
+            else
+              error_output("Error: #{error.message}")
+              error_output("Use --debug flag for more information")
+            end
+            exit 1
+          end
+
+          def error_output(message)
+            warn message
+          end
+        end
+      end
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/cli/commands/lms/models.rb b/lib/coding_agent_tools/cli/commands/lms/models.rb
new file mode 100644
index 0000000..7ecf183
--- /dev/null
+++ b/lib/coding_agent_tools/cli/commands/lms/models.rb
@@ -0,0 +1,170 @@
+# frozen_string_literal: true
+
+require "dry/cli"
+require_relative "../../../organisms/lm_studio_client"
+require_relative "../../../molecules/model"
+
+module CodingAgentTools
+  module Cli
+    module Commands
+      module LMS
+        # Models command for listing available LM Studio models
+        class Models < Dry::CLI::Command
+          desc "List available LM Studio AI models"
+
+          option :filter, type: :string, aliases: ["f"],
+            desc: "Filter models by name (fuzzy search)"
+
+          option :format, type: :string, default: "text", values: %w[text json],
+            desc: "Output format (text or json)"
+
+          option :debug, type: :boolean, default: false, aliases: ["d"],
+            desc: "Enable debug output for verbose error information"
+
+          example [
+            "",
+            "--filter mistral",
+            "--filter deepseek --format json",
+            "--format json"
+          ]
+
+          def call(**options)
+            models = get_available_models
+            filtered_models = filter_models(models, options[:filter])
+            output_models(filtered_models, options)
+          rescue => e
+            handle_error(e, options[:debug])
+          end
+
+          private
+
+          # Get list of available LM Studio models
+          def get_available_models
+            client = Organisms::LMStudioClient.new
+            models_response = client.list_models
+
+            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
+            # Convert API response to our model structure
+            models_response.map do |model|
+              model_id = model[:id]
+              Molecules::Model.new(
+                id: model_id,
+                name: format_model_name(model_id),
+                description: "LM Studio model",
+                default: model_id == default_model_id
+              )
+            end.sort_by(&:id)
+          rescue
+            # Fallback to hardcoded list if API/server fails
+            fallback_models
+          end
+
+          # Format model name for display
+          def format_model_name(model_id)
+            # Extract the model name part after the last slash
+            name_part = model_id.split("/").last
+
+            # Convert to title case
+            words = name_part.split(/[-_]/).map(&:capitalize)
+            words.join(" ")
+          end
+
+          # Fallback models if API call fails
+          def fallback_models
+            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
+            [
+              Molecules::Model.new(
+                id: "mistralai/devstral-small-2505",
+                name: "Devstral Small",
+                description: "Specialized coding model, optimized for development tasks",
+                default: default_model_id == "mistralai/devstral-small-2505"
+              ),
+              Molecules::Model.new(
+                id: "deepseek/deepseek-r1-0528-qwen3-8b",
+                name: "DeepSeek R1 Qwen3 8B",
+                description: "Advanced reasoning model with strong performance",
+                default: default_model_id == "deepseek/deepseek-r1-0528-qwen3-8b"
+              )
+            ]
+          end
+
+          # Filter models based on search term
+          def filter_models(models, filter_term)
+            return models unless filter_term
+
+            filter_term = filter_term.downcase
+            models.select do |model|
+              model.id.downcase.include?(filter_term) ||
+                model.name.downcase.include?(filter_term) ||
+                model.description.downcase.include?(filter_term)
+            end
+          end
+
+          # Output models in the specified format
+          def output_models(models, options)
+            case options[:format]
+            when "json"
+              output_json_models(models)
+            else
+              output_text_models(models)
+            end
+          end
+
+          # Output models as formatted text
+          def output_text_models(models)
+            if models.empty?
+              puts "No models found matching the filter criteria."
+              return
+            end
+
+            puts "Available LM Studio Models:"
+            puts "=" * 50
+            puts
+            puts "Note: Models must be loaded in LM Studio before use."
+            puts
+
+            models.each do |model|
+              puts
+              puts model
+            end
+
+            puts
+            puts "Usage: llm-lmstudio-query \"your prompt\" --model MODEL_ID"
+            puts
+            puts "Server: Ensure LM Studio is running at http://localhost:1234"
+          end
+
+          # Output models as JSON
+          def output_json_models(models)
+            default_model = models.find(&:default?)
+            output = {
+              models: models.map(&:to_json_hash),
+              count: models.length,
+              default_model: default_model&.id || Organisms::LMStudioClient::DEFAULT_MODEL,
+              server_url: "http://localhost:1234"
+            }
+
+            puts JSON.pretty_generate(output)
+          end
+
+          # Handle errors
+          def handle_error(error, debug_enabled)
+            if debug_enabled
+              error_output("Error: #{error.class.name}: #{error.message}")
+              error_output("\nBacktrace:")
+              error.backtrace.each { |line| error_output("  #{line}") }
+            else
+              error_output("Error: #{error.message}")
+              error_output("Use --debug flag for more information")
+            end
+            exit 1
+          end
+
+          def error_output(message)
+            warn message
+          end
+        end
+      end
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/cli/commands/lms/query.rb b/lib/coding_agent_tools/cli/commands/lms/query.rb
new file mode 100644
index 0000000..68f28b0
--- /dev/null
+++ b/lib/coding_agent_tools/cli/commands/lms/query.rb
@@ -0,0 +1,170 @@
+# frozen_string_literal: true
+
+require "dry/cli"
+require_relative "../../../organisms/lm_studio_client"
+require_relative "../../../organisms/prompt_processor"
+require_relative "../../../atoms/json_formatter"
+
+module CodingAgentTools
+  module Cli
+    module Commands
+      module LMS
+        # Query command for interacting with LM Studio local server
+        class Query < Dry::CLI::Command
+          desc "Query LM Studio AI with a prompt"
+
+          argument :prompt, required: true, desc: "The prompt text or file path (use --file flag for files)"
+
+          option :file, type: :boolean, default: false, aliases: ["f"],
+            desc: "Treat the prompt argument as a file path"
+
+          option :format, type: :string, default: "text", values: %w[text json],
+            desc: "Output format (text or json)"
+
+          option :debug, type: :boolean, default: false, aliases: ["d"],
+            desc: "Enable debug output for verbose error information"
+
+          option :model, type: :string, default: "mistralai/devstral-small-2505",
+            desc: "Model to use (default: mistralai/devstral-small-2505)"
+
+          option :temperature, type: :float,
+            desc: "Temperature for generation (0.0-2.0)"
+
+          option :max_tokens, type: :integer,
+            desc: "Maximum output tokens (-1 for unlimited)"
+
+          option :system, type: :string,
+            desc: "System instruction/prompt"
+
+          example [
+            '"What is Ruby programming language?"',
+            '"Explain quantum computing" --format json',
+            "prompt.txt --file",
+            "prompt.txt --file --format json --debug",
+            '"Hello" --model mistralai/devstral-small-2505 --temperature 0.5'
+          ]
+
+          def call(prompt:, **options)
+            # Validate prompt argument (now handled by dry-cli, but keep empty check)
+            if prompt.nil? || prompt.to_s.strip.empty?
+              error_output("Error: Prompt is required")
+              exit 1
+            end
+
+            # Process the prompt
+            prompt_text = process_prompt(prompt, options)
+
+            # Initialize and query LM Studio
+            response = query_lm_studio(prompt_text, options)
+
+            # Format and output the response
+            output_response(response, options)
+          rescue => e
+            handle_error(e, options[:debug])
+          end
+
+          private
+
+          def process_prompt(prompt, options)
+            processor = Organisms::PromptProcessor.new
+            # Ensure from_file is explicitly a boolean
+            from_file = options[:file] == true
+            processor.process(prompt, from_file: from_file)
+          rescue CodingAgentTools::Error => e
+            raise e # Re-raise specific CodingAgentTools errors directly
+          rescue => e # Catch other StandardErrors
+            new_error = CodingAgentTools::Error.new("Failed to process prompt: #{e.message}")
+            new_error.set_backtrace(e.backtrace)
+            raise new_error
+          end
+
+          def query_lm_studio(prompt_text, options)
+            client = build_lm_studio_client(options)
+
+            generation_options = build_generation_options(options)
+
+            # Always pass generation_options as keyword arguments, even if empty
+            if generation_options.empty?
+              client.generate_text(prompt_text)
+            else
+              client.generate_text(prompt_text, **generation_options)
+            end
+          rescue => e
+            new_error = CodingAgentTools::Error.new("Failed to query LM Studio: #{e.message}")
+            new_error.set_backtrace(e.backtrace)
+            raise new_error
+          end
+
+          def build_lm_studio_client(options)
+            client_options = {}
+            client_options[:model] = options[:model] if options[:model]
+
+            Organisms::LMStudioClient.new(**client_options)
+          end
+
+          def build_generation_options(options)
+            generation_options = {}
+
+            # Add system instruction if provided
+            generation_options[:system_instruction] = options[:system] if options[:system]
+
+            # Build generation config if temperature or max_tokens provided
+            generation_config = {}
+            generation_config[:temperature] = options[:temperature] if options[:temperature]
+            generation_config[:max_tokens] = options[:max_tokens] if options[:max_tokens]
+
+            generation_options[:generation_config] = generation_config unless generation_config.empty?
+
+            generation_options
+          end
+
+          def output_response(response, options)
+            case options[:format]
+            when "json"
+              output_json_response(response)
+            else
+              output_text_response(response)
+            end
+            response
+          end
+
+          def output_text_response(response)
+            puts response[:text]
+            response
+          end
+
+          def output_json_response(response)
+            # Structure the JSON output
+            output = {
+              text: response[:text],
+              metadata: {
+                finish_reason: response[:finish_reason],
+                usage: response[:usage_metadata]
+              }
+            }
+
+            formatted = Atoms::JSONFormatter.pretty_format(output)
+            puts formatted
+            response
+          end
+
+          def handle_error(error, debug_enabled)
+            if debug_enabled
+              error_output("Error: #{error.class.name}: #{error.message}")
+              error_output("\nBacktrace:")
+              error.backtrace.each { |line| error_output("  #{line}") }
+            else
+              error_output("Error: #{error.message}")
+              error_output("Use --debug flag for more information")
+            end
+            exit 1
+          end
+
+          def error_output(message)
+            warn message
+          end
+        end
+      end
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/molecules/model.rb b/lib/coding_agent_tools/molecules/model.rb
new file mode 100644
index 0000000..d2419af
--- /dev/null
+++ b/lib/coding_agent_tools/molecules/model.rb
@@ -0,0 +1,77 @@
+# frozen_string_literal: true
+
+module CodingAgentTools
+  module Molecules
+    # Model represents an AI model with its metadata
+    # This is a molecule - a simple data structure with behavior
+    class Model
+      attr_reader :id, :name, :description, :default
+
+      # Initialize a new Model
+      # @param id [String] Model identifier (e.g., "gemini-1.5-pro")
+      # @param name [String] Human-readable model name (e.g., "Gemini 1.5 Pro")
+      # @param description [String] Model description
+      # @param default [Boolean] Whether this is the default model
+      def initialize(id:, name:, description:, default: false)
+        @id = id
+        @name = name
+        @description = description
+        @default = default
+      end
+
+      # Check if this is the default model
+      # @return [Boolean]
+      def default?
+        @default
+      end
+
+      # String representation for display
+      # @return [String]
+      def to_s
+        output = []
+        output << "ID: #{@id}"
+        output << "Name: #{@name}"
+        output << "Description: #{@description}"
+        output << "Status: Default model" if default?
+        output.join("\n")
+      end
+
+      # Hash representation
+      # @return [Hash]
+      def to_h
+        {
+          id: @id,
+          name: @name,
+          description: @description,
+          default: @default
+        }
+      end
+
+      # JSON representation
+      # @return [Hash] JSON-compatible hash
+      def to_json_hash
+        to_h
+      end
+
+      # Equality comparison
+      # @param other [Model]
+      # @return [Boolean]
+      def ==(other)
+        return false unless other.is_a?(Model)
+
+        @id == other.id &&
+          @name == other.name &&
+          @description == other.description &&
+          @default == other.default
+      end
+
+      # Hash code for using as hash keys
+      # @return [Integer]
+      def hash
+        [@id, @name, @description, @default].hash
+      end
+
+      alias_method :eql?, :==
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/organisms/gemini_client.rb b/lib/coding_agent_tools/organisms/gemini_client.rb
index 5f0be55..b1334f7 100644
--- a/lib/coding_agent_tools/organisms/gemini_client.rb
+++ b/lib/coding_agent_tools/organisms/gemini_client.rb
@@ -110,6 +110,31 @@ module CodingAgentTools
         end
       end
 
+      # List all available models
+      # @return [Array] List of available models
+      def list_models
+        # Construct path by appending to base URL path to preserve v1beta
+        path_segment = "models"
+        url_obj = Addressable::URI.parse(@base_url)
+
+        # Use File.join-style logic to avoid double slashes
+        base_path = url_obj.path.end_with?("/") ? url_obj.path.chomp("/") : url_obj.path
+        url_obj.path = "#{base_path}/#{path_segment}"
+
+        # Set query parameters
+        url_obj.query_values = {key: @api_key}
+        url = url_obj.to_s
+
+        response_data = @request_builder.get_json(url)
+        parsed = @response_parser.parse_response(response_data)
+
+        if parsed[:success]
+          parsed[:data][:models] || []
+        else
+          handle_error(parsed)
+        end
+      end
+
       # Get information about the model
       # @return [Hash] Model information
       def model_info
diff --git a/lib/coding_agent_tools/organisms/lm_studio_client.rb b/lib/coding_agent_tools/organisms/lm_studio_client.rb
new file mode 100644
index 0000000..35469d0
--- /dev/null
+++ b/lib/coding_agent_tools/organisms/lm_studio_client.rb
@@ -0,0 +1,238 @@
+# frozen_string_literal: true
+
+require_relative "../molecules/api_credentials"
+require_relative "../molecules/http_request_builder"
+require_relative "../molecules/api_response_parser"
+require "json"
+
+module CodingAgentTools
+  module Organisms
+    # LMStudioClient provides high-level interface to LM Studio local server
+    # This is an organism - it orchestrates molecules to achieve business goals
+    class LMStudioClient
+      # LM Studio API base URL (local server)
+      API_BASE_URL = "http://localhost:1234"
+
+      # Default model to use
+      DEFAULT_MODEL = "mistralai/devstral-small-2505"
+
+      # Default generation config
+      DEFAULT_GENERATION_CONFIG = {
+        temperature: 0.7,
+        max_tokens: -1,
+        stream: false
+      }.freeze
+
+      # Initialize LM Studio client
+      # @param model [String] Model to use
+      # @param options [Hash] Additional options
+      # @option options [String] :base_url API base URL
+      # @option options [Hash] :generation_config Default generation config
+      # @option options [Integer] :timeout Request timeout
+      def initialize(model: DEFAULT_MODEL, **options)
+        @model = model
+        @base_url = options.fetch(:base_url, API_BASE_URL)
+        @generation_config = DEFAULT_GENERATION_CONFIG.merge(
+          options.fetch(:generation_config, {})
+        )
+
+        # Initialize components
+        # Note: LM Studio typically doesn't require authentication for localhost
+        begin
+          @credentials = Molecules::APICredentials.new(
+            env_key_name: options.fetch(:api_key_env, "LM_STUDIO_API_KEY")
+          )
+          @api_key = @credentials.api_key if @credentials.api_key_present?
+        rescue KeyError
+          # LM Studio typically doesn't require authentication for localhost
+          @api_key = nil
+        end
+
+        @request_builder = Molecules::HTTPRequestBuilder.new(
+          timeout: options.fetch(:timeout, 180),
+          event_namespace: :lm_studio_api
+        )
+        @response_parser = Molecules::APIResponseParser.new
+      end
+
+      # Check if LM Studio server is available
+      # @return [Boolean] True if server is running and responsive
+      def server_available?
+        url = build_api_url("models")
+        response_data = @request_builder.get_json(url)
+        response_data[:success] && response_data[:status] == 200
+      rescue
+        false
+      end
+
+      # Generate text content from a prompt
+      # @param prompt [String] The prompt text
+      # @param options [Hash] Generation options
+      # @option options [String] :system_instruction System instruction/message
+      # @option options [Hash] :generation_config Override generation config
+      # @return [Hash] Response with generated text
+      def generate_text(prompt, **options)
+        unless server_available?
+          raise Error, "LM Studio server is not available at #{@base_url}. Please ensure LM Studio is running."
+        end
+
+        payload = build_generation_payload(prompt, options)
+        url = build_api_url("chat/completions")
+
+        response_data = @request_builder.post_json(url, payload)
+        parsed = @response_parser.parse_response(response_data)
+
+        if parsed[:success]
+          extract_generated_text(parsed)
+        else
+          handle_error(parsed)
+        end
+      end
+
+      # List available models
+      # @return [Array] List of available models
+      def list_models
+        unless server_available?
+          raise Error, "LM Studio server is not available at #{@base_url}. Please ensure LM Studio is running."
+        end
+
+        url = build_api_url("models")
+        response_data = @request_builder.get_json(url)
+        parsed = @response_parser.parse_response(response_data)
+
+        if parsed[:success]
+          parsed[:data][:data] || []
+        else
+          handle_error(parsed)
+        end
+      end
+
+      # Get information about the current model
+      # @return [Hash] Model information
+      def model_info
+        models = list_models
+        models.find { |model| model[:id] == @model } ||
+          {id: @model, object: "model", owned_by: "local"}
+      end
+
+      private
+
+      # Build API URL for the given endpoint
+      # @param endpoint [String] API endpoint
+      # @return [String] Complete URL
+      def build_api_url(endpoint)
+        "#{@base_url}/v1/#{endpoint}"
+      end
+
+      # Build generation payload
+      # @param prompt [String] The prompt
+      # @param options [Hash] Options
+      # @return [Hash] Request payload
+      def build_generation_payload(prompt, options)
+        messages = []
+
+        # Add system message if provided
+        if options[:system_instruction]
+          messages << {
+            role: "system",
+            content: options[:system_instruction]
+          }
+        end
+
+        # Add user message
+        messages << {
+          role: "user",
+          content: prompt
+        }
+
+        generation_config = @generation_config.merge(
+          options.fetch(:generation_config, {})
+        )
+
+        {
+          model: @model,
+          messages: messages,
+          temperature: generation_config[:temperature],
+          max_tokens: generation_config[:max_tokens],
+          stream: generation_config[:stream]
+        }
+      end
+
+      # Extract generated text from response
+      # @param parsed_response [Hash] Parsed API response
+      # @return [Hash] Extracted text and metadata
+      def extract_generated_text(parsed_response)
+        # 1. Verify parsed_response[:data] is a Hash
+        data = parsed_response[:data]
+        unless data.is_a?(Hash)
+          raise Error, "Failed to extract generated text: Response data is not a Hash, cannot find choices."
+        end
+
+        # 2. Verify data[:choices] is a non-empty Array
+        choices_field = data[:choices]
+        unless choices_field.is_a?(Array)
+          raise Error, "Failed to extract generated text: 'choices' field is not an array."
+        end
+        if choices_field.empty?
+          raise Error, "Failed to extract generated text: 'choices' array is empty."
+        end
+
+        # 3. Verify the first choice data[:choices][0] is a Hash
+        choice = choices_field[0]
+        unless choice.is_a?(Hash)
+          raise Error, "Failed to extract generated text: No valid first choice found in response."
+        end
+
+        # 4. Verify choice[:message] is a Hash
+        message_field = choice[:message]
+        unless message_field.is_a?(Hash)
+          raise Error, "Failed to extract generated text: choice 'message' field is missing or not a Hash."
+        end
+
+        # 5. Verify choice[:message][:content] exists
+        unless message_field.key?(:content)
+          raise Error, "Failed to extract generated text: message does not have a 'content' key."
+        end
+
+        text_content = message_field[:content]
+        if text_content.nil?
+          raise Error, "Failed to extract generated text: message content is nil."
+        end
+
+        {
+          text: text_content,
+          finish_reason: choice[:finish_reason],
+          usage_metadata: data[:usage]
+        }
+      end
+
+      # Handle API errors
+      # @param parsed_response [Hash] Parsed error response
+      # @raise [Error] With formatted error message
+      def handle_error(parsed_response)
+        # Ensure error object and HTTP status are safely accessed, providing defaults
+        error_obj = parsed_response[:error] || {}
+        http_status = error_obj[:status] || "Unknown HTTP Status"
+
+        # Extract primary message components from the error object
+        details_message = error_obj.is_a?(Hash) ? error_obj.dig(:details, :message) : nil
+        error_message = error_obj.is_a?(Hash) ? error_obj[:message] : nil
+        raw_message = error_obj.is_a?(Hash) ? error_obj[:raw_message] : nil
+
+        # Determine the most specific error content available
+        specific_content = if details_message
+          details_message
+        elsif raw_message
+          raw_message
+        elsif error_message
+          error_message
+        else
+          "An unspecified error occurred."
+        end
+
+        final_message = "LM Studio API Error (#{http_status}): #{specific_content}"
+        raise Error, final_message
+      end
+    end
+  end
+end
diff --git a/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml b/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml
index d200cc1..933af15 100644
--- a/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml
+++ b/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml
@@ -2,7 +2,7 @@
 http_interactions:
 - request:
     method: post
-    uri: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=<GEMINI_API_KEY>
+    uri: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=<GEMINI_API_KEY>
     body:
       encoding: UTF-8
       string: '{"contents":[{"role":"user","parts":[{"text":"Hi"}]}],"generationConfig":{"temperature":0.7,"maxOutputTokens":8192}}'
@@ -27,7 +27,7 @@ http_interactions:
       - Referer
       - X-Origin
       Date:
-      - Sun, 08 Jun 2025 09:24:22 GMT
+      - Sat, 14 Jun 2025 22:20:56 GMT
       Server:
       - scaffolding on HTTPServer2
       X-Xss-Protection:
@@ -37,7 +37,7 @@ http_interactions:
       X-Content-Type-Options:
       - nosniff
       Server-Timing:
-      - gfet4t7; dur=598
+      - gfet4t7; dur=531
       Alt-Svc:
       - h3=":443"; ma=2592000,h3-29=":443"; ma=2592000
       Transfer-Encoding:
@@ -57,7 +57,7 @@ http_interactions:
                 "role": "model"
               },
               "finishReason": "STOP",
-              "avgLogprobs": -0.0097825032743540669
+              "avgLogprobs": -0.00036991417238658124
             }
           ],
           "usageMetadata": {
@@ -77,8 +77,8 @@ http_interactions:
               }
             ]
           },
-          "modelVersion": "gemini-2.0-flash-lite",
-          "responseId": "xlZFaJWFJuODsbQPi5CLoQU"
+          "modelVersion": "gemini-1.5-flash",
+          "responseId": "x_VNaK2WO-qvnvgPsq_uwAU"
         }
-  recorded_at: Sun, 08 Jun 2025 09:24:22 GMT
+  recorded_at: Sat, 14 Jun 2025 22:20:56 GMT
 recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/applies_temperature_setting.yml b/spec/cassettes/llm_lmstudio_query_integration/applies_temperature_setting.yml
new file mode 100644
index 0000000..c1f89df
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/applies_temperature_setting.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:40 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:40 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Complete
+        this: The sky is"}],"temperature":"0.1","max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '503'
+      Etag:
+      - W/"1f7-mhgRlJx/W8MwR3mIvjVXwgD8428"
+      Date:
+      - Sat, 14 Jun 2025 19:54:41 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-cggr4w4j63eie7ybfb0xhq",
+          "object": "chat.completion",
+          "created": 1749930880,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "blue."
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1231,
+            "completion_tokens": 2,
+            "total_tokens": 1233
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:41 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/completes_requests_within_reasonable_time.yml b/spec/cassettes/llm_lmstudio_query_integration/completes_requests_within_reasonable_time.yml
new file mode 100644
index 0000000..4fdf850
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/completes_requests_within_reasonable_time.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:31 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:31 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Say
+        hello quickly"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '533'
+      Etag:
+      - W/"215-CbmPtV3G0L5V3rTvC9fqDyvjoXg"
+      Date:
+      - Sat, 14 Jun 2025 19:54:32 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-0j6if1f61hyftdg2wdyei8a",
+          "object": "chat.completion",
+          "created": 1749930871,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Hello! How can I assist you today?"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1228,
+            "completion_tokens": 9,
+            "total_tokens": 1237
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:32 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_multiline_prompts_from_file.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_multiline_prompts_from_file.yml
new file mode 100644
index 0000000..d15b626
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/handles_multiline_prompts_from_file.yml
@@ -0,0 +1,221 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:16 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:16 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"This
+        is a multi-line prompt.\nIt has several lines.\n\nAnd even blank lines.\n\nReply
+        with: \"Multi-line received\""}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '517'
+      Etag:
+      - W/"205-73KPdqIUTGuVscPvD9tgCu1ZxG0"
+      Date:
+      - Sat, 14 Jun 2025 19:54:17 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-2rlyht03z184rmag44isop",
+          "object": "chat.completion",
+          "created": 1749930856,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Multi-line received"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1250,
+            "completion_tokens": 3,
+            "total_tokens": 1253
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:17 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_prompts_with_special_characters.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_prompts_with_special_characters.yml
new file mode 100644
index 0000000..8549efc
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/handles_prompts_with_special_characters.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:29 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:29 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Echo
+        this exactly: Special chars @#$%&*()_+={[}]|\:;\"<,>.?/"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '541'
+      Etag:
+      - W/"21d-lpEm/yvxYhmNJ5p7nl/Q8MEOe38"
+      Date:
+      - Sat, 14 Jun 2025 19:54:31 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-s5gu43s7clc6be01joau0l",
+          "object": "chat.completion",
+          "created": 1749930869,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Special chars @#$%&*()_+={[}]|\:;\"<,>.?/"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1250,
+            "completion_tokens": 21,
+            "total_tokens": 1271
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:31 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_unicode_prompts.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_unicode_prompts.yml
new file mode 100644
index 0000000..354953e
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/handles_unicode_prompts.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:28 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:28 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Translate
+        to English: こんにちは"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '503'
+      Etag:
+      - W/"1f7-JzBhZTgSoY5e5M9bFlytw45Nb30"
+      Date:
+      - Sat, 14 Jun 2025 19:54:28 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-3xs3gw6ii8uo3hycb1yqxo",
+          "object": "chat.completion",
+          "created": 1749930868,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Hello"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1231,
+            "completion_tokens": 1,
+            "total_tokens": 1232
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:28 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_very_long_prompts.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_very_long_prompts.yml
new file mode 100644
index 0000000..9453af0
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/handles_very_long_prompts.yml
@@ -0,0 +1,257 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:17 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:17 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Please
+        summarize this text: Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
+        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
+        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
+        Lorem ipsum dolor sit amet, consectetur adipiscing elit."}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '788'
+      Etag:
+      - W/"314-NM9TkeOHqHCL+mrzf2dj/QlQti8"
+      Date:
+      - Sat, 14 Jun 2025 19:54:27 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-spnwj91kv5et72reyhhpq",
+          "object": "chat.completion",
+          "created": 1749930857,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "The text is a repetition of the phrase \"Lorem ipsum dolor sit amet, consectetur adipiscing elit\" for a total of 40 times. This is commonly used as placeholder text in the publishing and design industries, allowing viewers to focus on layout without being distracted by meaningful content."
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1730,
+            "completion_tokens": 55,
+            "total_tokens": 1785
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:27 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/outputs_clean_text_by_default.yml b/spec/cassettes/llm_lmstudio_query_integration/outputs_clean_text_by_default.yml
new file mode 100644
index 0000000..41ee0a9
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/outputs_clean_text_by_default.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:12 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:12 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Reply
+        with exactly: Hello World"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '509'
+      Etag:
+      - W/"1fd-100/1XGuabJilYawgAq9/gP/mOE"
+      Date:
+      - Sat, 14 Jun 2025 19:54:12 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-05akq4ww7ksi5qczdnbg5c",
+          "object": "chat.completion",
+          "created": 1749930852,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Hello World"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1231,
+            "completion_tokens": 2,
+            "total_tokens": 1233
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:12 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/outputs_json_format.yml b/spec/cassettes/llm_lmstudio_query_integration/outputs_json_format.yml
new file mode 100644
index 0000000..91a50b8
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/outputs_json_format.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:41 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:41 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Say
+        hello"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '532'
+      Etag:
+      - W/"214-w6ruJ3DswtdNjYJTnsUws7wJOgg"
+      Date:
+      - Sat, 14 Jun 2025 19:54:42 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-27rsddqyhd8k82og6ai938",
+          "object": "chat.completion",
+          "created": 1749930881,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Hello! How can I assist you today?"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1227,
+            "completion_tokens": 9,
+            "total_tokens": 1236
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:42 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/outputs_valid_json_with_metadata.yml b/spec/cassettes/llm_lmstudio_query_integration/outputs_valid_json_with_metadata.yml
new file mode 100644
index 0000000..da57f1a
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/outputs_valid_json_with_metadata.yml
@@ -0,0 +1,219 @@
+---
+http_interactions:
+  - request:
+      method: get
+      uri: http://localhost:1234/v1/models
+      body:
+        encoding: US-ASCII
+        string: ""
+      headers:
+        User-Agent:
+          - Faraday v2.13.1
+        Accept:
+          - application/json
+        Accept-Encoding:
+          - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+    response:
+      status:
+        code: 200
+        message: OK
+      headers:
+        X-Powered-By:
+          - Express
+        Access-Control-Allow-Origin:
+          - "*"
+        Access-Control-Allow-Headers:
+          - "*"
+        Content-Type:
+          - application/json; charset=utf-8
+        Content-Length:
+          - "2487"
+        Etag:
+          - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+        Date:
+          - Sat, 14 Jun 2025 19:53:56 GMT
+        Connection:
+          - keep-alive
+        Keep-Alive:
+          - timeout=5
+      body:
+        encoding: UTF-8
+        string: |-
+          {
+            "data": [
+              {
+                "id": "mistralai/devstral-small-2505",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "text-embedding-nomic-embed-text-v1.5",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "phi-4-reasoning-plus-mlx",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "phi-4-reasoning-mlx",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "phi-4-mini-reasoning-mlx",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "qwen3-30b-a3b-mlx",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "mistral-small-3.1-24b-instruct-2503",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "deepseek-r1-distill-qwen-32b",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "sfr-embedding-mistral",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "text-embedding-granite-embedding-278m-multilingual",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "gemma-3-27b-it@q4_k_m",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "gemma-3-27b-it@q8_0",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "gemma-3-4b-it",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "watt-tool-8b",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "gemma-3-12b-it",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "gemma-3-1b-it",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "phi-4-mini-instruct",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "phi-4",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "forgotten-safeword-24b",
+                "object": "model",
+                "owned_by": "organization_owner"
+              },
+              {
+                "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+                "object": "model",
+                "owned_by": "organization_owner"
+              }
+            ],
+            "object": "list"
+          }
+    recorded_at: Sat, 14 Jun 2025 19:53:56 GMT
+  - request:
+      method: post
+      uri: http://localhost:1234/v1/chat/completions
+      body:
+        encoding: UTF-8
+        string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Say hi"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+      headers:
+        User-Agent:
+          - Faraday v2.13.1
+        Accept:
+          - application/json
+        Content-Type:
+          - application/json
+        Accept-Encoding:
+          - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+    response:
+      status:
+        code: 200
+        message: OK
+      headers:
+        X-Powered-By:
+          - Express
+        Access-Control-Allow-Origin:
+          - "*"
+        Access-Control-Allow-Headers:
+          - "*"
+        Content-Type:
+          - application/json; charset=utf-8
+        Content-Length:
+          - "508"
+        Etag:
+          - W/"1fc-abc123def456"
+        Date:
+          - Sat, 14 Jun 2025 19:53:57 GMT
+        Connection:
+          - keep-alive
+        Keep-Alive:
+          - timeout=5
+      body:
+        encoding: UTF-8
+        string: |-
+          {
+            "id": "chatcmpl-abc123def456",
+            "object": "chat.completion",
+            "created": 1749930877,
+            "model": "mistralai/devstral-small-2505",
+            "choices": [
+              {
+                "index": 0,
+                "logprobs": null,
+                "finish_reason": "stop",
+                "message": {
+                  "role": "assistant",
+                  "content": "Hi there! How can I help you today?"
+                }
+              }
+            ],
+            "usage": {
+              "prompt_tokens": 10,
+              "completion_tokens": 12,
+              "total_tokens": 22
+            },
+            "stats": {},
+            "system_fingerprint": "mistralai/devstral-small-2505"
+          }
+    recorded_at: Sat, 14 Jun 2025 19:53:57 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt.yml b/spec/cassettes/llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt.yml
new file mode 100644
index 0000000..79d1a04
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:38 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:38 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"What
+        is 2+2? Reply with just the number."}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '499'
+      Etag:
+      - W/"1f3-ETuAdX3IGsyE3IUMxi6IN52rJVI"
+      Date:
+      - Sat, 14 Jun 2025 19:54:38 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-j1mdqstbj3g5p7yraecs6x",
+          "object": "chat.completion",
+          "created": 1749930878,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "4"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1238,
+            "completion_tokens": 1,
+            "total_tokens": 1239
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:38 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/reads_prompt_from_file.yml b/spec/cassettes/llm_lmstudio_query_integration/reads_prompt_from_file.yml
new file mode 100644
index 0000000..b3c83a0
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/reads_prompt_from_file.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:39 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:39 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"What
+        is the capital of France? Reply with just the city name."}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '503'
+      Etag:
+      - W/"1f7-FXouQXHo9QFwQEFEdapZbVobC1k"
+      Date:
+      - Sat, 14 Jun 2025 19:54:39 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-5bihncxecyjhkgxdzhd4fu",
+          "object": "chat.completion",
+          "created": 1749930879,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Paris"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1239,
+            "completion_tokens": 1,
+            "total_tokens": 1240
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:39 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/respects_max_tokens.yml b/spec/cassettes/llm_lmstudio_query_integration/respects_max_tokens.yml
new file mode 100644
index 0000000..e258c20
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/respects_max_tokens.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:34 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:34 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Write
+        a very long story about a dragon"}],"temperature":0.7,"max_tokens":"50","stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '716'
+      Etag:
+      - W/"2cc-6wJL2n4cm6uj1WVBfN9v6tQqpu8"
+      Date:
+      - Sat, 14 Jun 2025 19:54:37 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-1r7hymjsy8gaac1t4vweh6",
+          "object": "chat.completion",
+          "created": 1749930874,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "length",
+              "message": {
+                "role": "assistant",
+                "content": "Once upon a time, in a land of towering mountains and lush valleys, there lived a dragon named Draconis. Unlike the mythical beasts of legend that breathed fire and devastation, Draconis was a creature of wisdom and"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1233,
+            "completion_tokens": 49,
+            "total_tokens": 1282
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:37 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/uses_custom_model.yml b/spec/cassettes/llm_lmstudio_query_integration/uses_custom_model.yml
new file mode 100644
index 0000000..974c69c
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/uses_custom_model.yml
@@ -0,0 +1,219 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:42 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:42 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Hi"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '532'
+      Etag:
+      - W/"214-kpOBIUNUcO+ftxe1E3wZBWGYLsQ"
+      Date:
+      - Sat, 14 Jun 2025 19:54:43 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-0j3605q4z3vp5drgzsi89s",
+          "object": "chat.completion",
+          "created": 1749930882,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Hello! How can I assist you today?"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1226,
+            "completion_tokens": 9,
+            "total_tokens": 1235
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:43 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/uses_system_instruction.yml b/spec/cassettes/llm_lmstudio_query_integration/uses_system_instruction.yml
new file mode 100644
index 0000000..f40a2f3
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/uses_system_instruction.yml
@@ -0,0 +1,197 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:44 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:44 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"system","content":"You
+        are a helpful assistant. Always respond with enthusiasm."},{"role":"user","content":"Hello"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '601'
+      Etag:
+      - W/"259-FwrbcxkThhavmZ0/zTLGRsknthQ"
+      Date:
+      - Sat, 14 Jun 2025 19:54:46 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: ASCII-8BIT
+      string: !binary |-
+        ewogICJpZCI6ICJjaGF0Y21wbC10cDMxNnIydHM3a3dmMXZ0aHd6cGdjIiwKICAib2JqZWN0IjogImNoYXQuY29tcGxldGlvbiIsCiAgImNyZWF0ZWQiOiAxNzQ5OTMwODg0LAogICJtb2RlbCI6ICJtaXN0cmFsYWkvZGV2c3RyYWwtc21hbGwtMjUwNSIsCiAgImNob2ljZXMiOiBbCiAgICB7CiAgICAgICJpbmRleCI6IDAsCiAgICAgICJsb2dwcm9icyI6IG51bGwsCiAgICAgICJmaW5pc2hfcmVhc29uIjogInN0b3AiLAogICAgICAibWVzc2FnZSI6IHsKICAgICAgICAicm9sZSI6ICJhc3Npc3RhbnQiLAogICAgICAgICJjb250ZW50IjogIkhlbGxvISBJdCdzIGdyZWF0IHRvIGhhdmUgeW91IGhlcmUuIEhvdyBjYW4gSSBhc3Npc3QgeW91IHRvZGF5PyBMZXQncyBtYWtlIHRoaXMgY29udmVyc2F0aW9uIGF3ZXNvbWUhIPCfmIoiCiAgICAgIH0KICAgIH0KICBdLAogICJ1c2FnZSI6IHsKICAgICJwcm9tcHRfdG9rZW5zIjogMTcsCiAgICAiY29tcGxldGlvbl90b2tlbnMiOiAyNywKICAgICJ0b3RhbF90b2tlbnMiOiA0NAogIH0sCiAgInN0YXRzIjoge30sCiAgInN5c3RlbV9maW5nZXJwcmludCI6ICJtaXN0cmFsYWkvZGV2c3RyYWwtc21hbGwtMjUwNSIKfQ==
+  recorded_at: Sat, 14 Jun 2025 19:54:46 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cassettes/llm_lmstudio_query_integration/works_with_default_model.yml b/spec/cassettes/llm_lmstudio_query_integration/works_with_default_model.yml
new file mode 100644
index 0000000..5b083d5
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/works_with_default_model.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '2487'
+      Etag:
+      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
+      Date:
+      - Sat, 14 Jun 2025 19:54:13 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "data": [
+            {
+              "id": "mistralai/devstral-small-2505",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-nomic-embed-text-v1.5",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-plus-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-reasoning-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "qwen3-30b-a3b-mlx",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistral-small-3.1-24b-instruct-2503",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "deepseek-r1-distill-qwen-32b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "sfr-embedding-mistral",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "text-embedding-granite-embedding-278m-multilingual",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q4_k_m",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-27b-it@q8_0",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-4b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "watt-tool-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-12b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "gemma-3-1b-it",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4-mini-instruct",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "phi-4",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "forgotten-safeword-24b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
+              "object": "model",
+              "owned_by": "organization_owner"
+            }
+          ],
+          "object": "list"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:13 GMT
+- request:
+    method: post
+    uri: http://localhost:1234/v1/chat/completions
+    body:
+      encoding: UTF-8
+      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Test
+        default model"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
+    headers:
+      User-Agent:
+      - Faraday v2.13.1
+      Accept:
+      - application/json
+      Content-Type:
+      - application/json
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      X-Powered-By:
+      - Express
+      Access-Control-Allow-Origin:
+      - "*"
+      Access-Control-Allow-Headers:
+      - "*"
+      Content-Type:
+      - application/json; charset=utf-8
+      Content-Length:
+      - '589'
+      Etag:
+      - W/"24d-BrMf4VWfTnAsfl9HiOIv6578XrY"
+      Date:
+      - Sat, 14 Jun 2025 19:54:15 GMT
+      Connection:
+      - keep-alive
+      Keep-Alive:
+      - timeout=5
+    body:
+      encoding: UTF-8
+      string: |-
+        {
+          "id": "chatcmpl-qb9udd29ekpv37run8rbe",
+          "object": "chat.completion",
+          "created": 1749930853,
+          "model": "mistralai/devstral-small-2505",
+          "choices": [
+            {
+              "index": 0,
+              "logprobs": null,
+              "finish_reason": "stop",
+              "message": {
+                "role": "assistant",
+                "content": "Hello! I'm Devstral, a helpful assistant trained by Mistral AI. How can I assist you today?"
+              }
+            }
+          ],
+          "usage": {
+            "prompt_tokens": 1228,
+            "completion_tokens": 23,
+            "total_tokens": 1251
+          },
+          "stats": {},
+          "system_fingerprint": "mistralai/devstral-small-2505"
+        }
+  recorded_at: Sat, 14 Jun 2025 19:54:15 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/coding_agent_tools/cli/commands/llm/models_spec.rb b/spec/coding_agent_tools/cli/commands/llm/models_spec.rb
new file mode 100644
index 0000000..343fc27
--- /dev/null
+++ b/spec/coding_agent_tools/cli/commands/llm/models_spec.rb
@@ -0,0 +1,198 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+require "coding_agent_tools/cli/commands/llm/models"
+
+RSpec.describe CodingAgentTools::Cli::Commands::LLM::Models do
+  subject(:command) { described_class.new }
+
+  let(:output) { StringIO.new }
+
+  before do
+    allow($stdout).to receive(:puts) { |msg| output.puts(msg) }
+    allow($stdout).to receive(:print) { |msg| output.print(msg) }
+  end
+
+  describe "#call" do
+    context "with default options" do
+      it "lists all available models" do
+        command.call
+
+        output_content = output.string
+        expect(output_content).to include("Available Gemini Models:")
+        expect(output_content).to include("Default model")
+        expect(output_content).to include("Usage: llm-gemini-query")
+        # Should contain at least one model
+        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
+        expect(output_content).to match(/Name: Gemini/)
+        expect(output_content).to match(/Description: /)
+      end
+
+      it "shows model descriptions" do
+        command.call
+
+        output_content = output.string
+        # Should have proper structure
+        expect(output_content).to match(/ID: /)
+        expect(output_content).to match(/Name: /)
+        expect(output_content).to match(/Description: /)
+      end
+    end
+
+    context "with filter option" do
+      it "filters models correctly" do
+        # Test with a term that should match at least one model
+        command.call(filter: "gemini")
+
+        output_content = output.string
+        # Should have models since "gemini" should match
+        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
+      end
+
+      it "shows no results message when no matches" do
+        command.call(filter: "nonexistent")
+
+        output_content = output.string
+        expect(output_content).to include("No models found matching the filter criteria")
+      end
+
+      it "is case insensitive" do
+        command.call(filter: "GEMINI")
+
+        output_content = output.string
+        # Should have models since case shouldn't matter
+        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
+      end
+    end
+
+    context "with json format" do
+      it "outputs models in JSON format" do
+        command.call(format: "json")
+
+        output_content = output.string
+        json_output = JSON.parse(output_content)
+
+        expect(json_output).to have_key("models")
+        expect(json_output).to have_key("count")
+        expect(json_output).to have_key("default_model")
+        expect(json_output["default_model"]).not_to be_empty
+        expect(json_output["models"]).to be_an(Array)
+        expect(json_output["models"].length).to be > 0
+      end
+
+      it "includes model details in JSON" do
+        command.call(format: "json")
+
+        output_content = output.string
+        json_output = JSON.parse(output_content)
+
+        first_model = json_output["models"].first
+        expect(first_model).to have_key("id")
+        expect(first_model).to have_key("name")
+        expect(first_model).to have_key("description")
+        expect(first_model).to have_key("default")
+      end
+
+      it "filters work with JSON format" do
+        command.call(format: "json", filter: "gemini-1.5")
+
+        output_content = output.string
+        json_output = JSON.parse(output_content)
+
+        expect(json_output["count"]).to be >= 1
+        json_output["models"].each do |model|
+          expect(model["id"].downcase).to include("gemini-1.5")
+        end
+      end
+    end
+
+    context "error handling" do
+      it "handles exceptions gracefully" do
+        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
+        allow(command).to receive(:warn)
+
+        expect { command.call }.to raise_error(SystemExit)
+        expect(command).to have_received(:warn).with(/Error: Test error/)
+      end
+
+      it "shows debug information when debug flag is set" do
+        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
+        allow(command).to receive(:warn)
+
+        expect { command.call(debug: true) }.to raise_error(SystemExit)
+        expect(command).to have_received(:warn).with(/Error: StandardError: Test error/)
+        expect(command).to have_received(:warn).with(/Backtrace:/)
+      end
+    end
+  end
+
+  describe "private methods" do
+    describe "#get_available_models" do
+      it "returns an array of model hashes" do
+        models = command.send(:get_available_models)
+
+        expect(models).to be_an(Array)
+        expect(models.length).to be > 0
+
+        models.each do |model|
+          expect(model).to respond_to(:id)
+          expect(model).to respond_to(:name)
+          expect(model).to respond_to(:description)
+          expect(model).to respond_to(:default?)
+        end
+      end
+
+      it "includes the default model" do
+        models = command.send(:get_available_models)
+        default_model = models.find(&:default?)
+
+        expect(default_model).not_to be_nil
+        expect(default_model.id).not_to be_empty
+      end
+    end
+
+    describe "#filter_models" do
+      let(:models) do
+        [
+          CodingAgentTools::Molecules::Model.new(id: "model-1", name: "Model One", description: "First model"),
+          CodingAgentTools::Molecules::Model.new(id: "model-2", name: "Model Two", description: "Second model"),
+          CodingAgentTools::Molecules::Model.new(id: "flash-model", name: "Flash Model", description: "Fast model")
+        ]
+      end
+
+      it "returns all models when no filter is provided" do
+        result = command.send(:filter_models, models, nil)
+        expect(result).to eq(models)
+      end
+
+      it "filters by model id" do
+        result = command.send(:filter_models, models, "model-1")
+        expect(result.length).to eq(1)
+        expect(result.first.id).to eq("model-1")
+      end
+
+      it "filters by model name" do
+        result = command.send(:filter_models, models, "Flash")
+        expect(result.length).to eq(1)
+        expect(result.first.name).to eq("Flash Model")
+      end
+
+      it "filters by description" do
+        result = command.send(:filter_models, models, "Fast")
+        expect(result.length).to eq(1)
+        expect(result.first.description).to eq("Fast model")
+      end
+
+      it "is case insensitive" do
+        result = command.send(:filter_models, models, "FLASH")
+        expect(result.length).to eq(1)
+        expect(result.first.name).to eq("Flash Model")
+      end
+
+      it "returns empty array when no matches" do
+        result = command.send(:filter_models, models, "nonexistent")
+        expect(result).to be_empty
+      end
+    end
+  end
+end
diff --git a/spec/coding_agent_tools/cli/commands/lms/models_spec.rb b/spec/coding_agent_tools/cli/commands/lms/models_spec.rb
new file mode 100644
index 0000000..5374e60
--- /dev/null
+++ b/spec/coding_agent_tools/cli/commands/lms/models_spec.rb
@@ -0,0 +1,195 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+require "coding_agent_tools/cli/commands/lms/models"
+
+RSpec.describe CodingAgentTools::Cli::Commands::LMS::Models do
+  subject(:command) { described_class.new }
+
+  let(:output) { StringIO.new }
+
+  before do
+    allow($stdout).to receive(:puts) { |msg| output.puts(msg) }
+    allow($stdout).to receive(:print) { |msg| output.print(msg) }
+  end
+
+  describe "#call" do
+    context "with default options" do
+      it "lists all available models" do
+        command.call
+
+        output_content = output.string
+        expect(output_content).to include("Available LM Studio Models:")
+        expect(output_content).to include("Default model")
+        expect(output_content).to include("Usage: llm-lmstudio-query")
+        # Should contain at least one model
+        expect(output_content).to match(/ID: [\w\/-]+/)
+        expect(output_content).to match(/Name: /)
+        expect(output_content).to match(/Description: /)
+      end
+
+      it "shows server information" do
+        command.call
+
+        output_content = output.string
+        expect(output_content).to include("Note: Models must be loaded in LM Studio before use")
+        expect(output_content).to include("http://localhost:1234")
+      end
+    end
+
+    context "with filter option" do
+      it "filters models correctly" do
+        command.call(filter: "mistral")
+
+        output_content = output.string
+        expect(output_content).to match(/ID: mistralai\/[\w\/-]+/)
+      end
+
+      it "is case insensitive" do
+        command.call(filter: "MISTRAL")
+
+        output_content = output.string
+        expect(output_content).to match(/ID: mistralai\/[\w\/-]+/)
+      end
+
+      it "shows no results message when no matches" do
+        command.call(filter: "nonexistent")
+
+        output_content = output.string
+        expect(output_content).to include("No models found matching the filter criteria")
+      end
+    end
+
+    context "with json format" do
+      it "outputs models in JSON format" do
+        command.call(format: "json")
+
+        output_content = output.string
+        json_output = JSON.parse(output_content)
+
+        expect(json_output).to have_key("models")
+        expect(json_output).to have_key("count")
+        expect(json_output).to have_key("default_model")
+        expect(json_output).to have_key("server_url")
+        expect(json_output["default_model"]).not_to be_empty
+        expect(json_output["server_url"]).to eq("http://localhost:1234")
+        expect(json_output["models"]).to be_an(Array)
+        expect(json_output["models"].length).to be > 0
+      end
+
+      it "includes model details in JSON" do
+        command.call(format: "json")
+
+        output_content = output.string
+        json_output = JSON.parse(output_content)
+
+        first_model = json_output["models"].first
+        expect(first_model).to have_key("id")
+        expect(first_model).to have_key("name")
+        expect(first_model).to have_key("description")
+        expect(first_model).to have_key("default")
+      end
+
+      it "filters work with JSON format" do
+        command.call(format: "json", filter: "mistral")
+
+        output_content = output.string
+        json_output = JSON.parse(output_content)
+
+        expect(json_output["count"]).to be >= 1
+        json_output["models"].each do |model|
+          expect(model["id"]).to include("mistral")
+        end
+      end
+    end
+
+    context "error handling" do
+      it "handles exceptions gracefully" do
+        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
+        allow(command).to receive(:warn)
+
+        expect { command.call }.to raise_error(SystemExit)
+        expect(command).to have_received(:warn).with(/Error: Test error/)
+      end
+
+      it "shows debug information when debug flag is set" do
+        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
+        allow(command).to receive(:warn)
+
+        expect { command.call(debug: true) }.to raise_error(SystemExit)
+        expect(command).to have_received(:warn).with(/Error: StandardError: Test error/)
+        expect(command).to have_received(:warn).with(/Backtrace:/)
+      end
+    end
+  end
+
+  describe "private methods" do
+    describe "#get_available_models" do
+      it "returns an array of model hashes" do
+        models = command.send(:get_available_models)
+
+        expect(models).to be_an(Array)
+        expect(models.length).to be > 0
+
+        models.each do |model|
+          expect(model).to respond_to(:id)
+          expect(model).to respond_to(:name)
+          expect(model).to respond_to(:description)
+          expect(model).to respond_to(:default?)
+        end
+      end
+
+      it "includes the default model" do
+        models = command.send(:get_available_models)
+        default_model = models.find(&:default?)
+
+        expect(default_model).not_to be_nil
+        expect(default_model.id).not_to be_empty
+      end
+    end
+
+    describe "#filter_models" do
+      let(:models) do
+        [
+          CodingAgentTools::Molecules::Model.new(id: "mistralai/model-1", name: "Mistral One", description: "First model"),
+          CodingAgentTools::Molecules::Model.new(id: "deepseek/model-2", name: "DeepSeek Two", description: "Second model"),
+          CodingAgentTools::Molecules::Model.new(id: "qwen/coder-model", name: "Qwen Coder", description: "Coding model")
+        ]
+      end
+
+      it "returns all models when no filter is provided" do
+        result = command.send(:filter_models, models, nil)
+        expect(result).to eq(models)
+      end
+
+      it "filters by model id" do
+        result = command.send(:filter_models, models, "mistralai")
+        expect(result.length).to eq(1)
+        expect(result.first.id).to eq("mistralai/model-1")
+      end
+
+      it "filters by model name" do
+        result = command.send(:filter_models, models, "DeepSeek")
+        expect(result.length).to eq(1)
+        expect(result.first.name).to eq("DeepSeek Two")
+      end
+
+      it "filters by description" do
+        result = command.send(:filter_models, models, "Coding")
+        expect(result.length).to eq(1)
+        expect(result.first.description).to eq("Coding model")
+      end
+
+      it "is case insensitive" do
+        result = command.send(:filter_models, models, "QWEN")
+        expect(result.length).to eq(1)
+        expect(result.first.name).to eq("Qwen Coder")
+      end
+
+      it "returns empty array when no matches" do
+        result = command.send(:filter_models, models, "nonexistent")
+        expect(result).to be_empty
+      end
+    end
+  end
+end
diff --git a/spec/coding_agent_tools/cli/commands/lms/query_spec.rb b/spec/coding_agent_tools/cli/commands/lms/query_spec.rb
new file mode 100644
index 0000000..5389257
--- /dev/null
+++ b/spec/coding_agent_tools/cli/commands/lms/query_spec.rb
@@ -0,0 +1,316 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+require "coding_agent_tools/cli/commands/lms/query"
+
+RSpec.describe CodingAgentTools::Cli::Commands::LMS::Query do
+  let(:command) { described_class.new }
+  let(:mock_lm_studio_client) { instance_double(CodingAgentTools::Organisms::LMStudioClient) }
+  let(:mock_prompt_processor) { instance_double(CodingAgentTools::Organisms::PromptProcessor) }
+
+  before do
+    allow(CodingAgentTools::Organisms::LMStudioClient).to receive(:new).and_return(mock_lm_studio_client)
+    allow(CodingAgentTools::Organisms::PromptProcessor).to receive(:new).and_return(mock_prompt_processor)
+    allow(command).to receive(:exit) # Prevent actual exit calls during tests
+
+    # Default stubs to handle parameter variations
+    allow(mock_prompt_processor).to receive(:process).and_return("default response")
+    allow(mock_lm_studio_client).to receive(:generate_text).and_return({
+      text: "Default response",
+      finish_reason: "stop",
+      usage_metadata: {prompt_tokens: 5, completion_tokens: 10}
+    })
+  end
+
+  describe "#call" do
+    let(:prompt) { "What is Ruby?" }
+    let(:successful_response) do
+      {
+        text: "Ruby is a programming language",
+        finish_reason: "stop",
+        usage_metadata: {prompt_tokens: 10, completion_tokens: 20}
+      }
+    end
+
+    context "with basic prompt" do
+      it "processes prompt and generates response" do
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_return(prompt)
+
+        allow(mock_lm_studio_client).to receive(:generate_text)
+          .with(prompt)
+          .and_return(successful_response)
+
+        expect { command.call(prompt: prompt) }
+          .to output("Ruby is a programming language\n").to_stdout
+      end
+    end
+
+    context "with file input" do
+      let(:file_content) { "Explain quantum computing" }
+
+      it "processes file and generates response" do
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: true)
+          .and_return(file_content)
+
+        allow(mock_lm_studio_client).to receive(:generate_text)
+          .with(file_content)
+          .and_return(successful_response)
+
+        expect { command.call(prompt: prompt, file: true) }
+          .to output("Ruby is a programming language\n").to_stdout
+      end
+    end
+
+    context "with custom model" do
+      it "uses specified model" do
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_return(prompt)
+        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
+          .with(model: "custom-model")
+          .and_return(mock_lm_studio_client)
+
+        allow(mock_lm_studio_client).to receive(:generate_text)
+          .with(prompt)
+          .and_return(successful_response)
+
+        expect { command.call(prompt: prompt, model: "custom-model") }
+          .to output("Ruby is a programming language\n").to_stdout
+      end
+    end
+
+    context "with system instruction" do
+      it "includes system instruction in generation options" do
+        system_instruction = "You are a helpful assistant"
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_return(prompt)
+        allow(mock_lm_studio_client).to receive(:generate_text)
+          .with(prompt, system_instruction: system_instruction)
+          .and_return(successful_response)
+
+        expect { command.call(prompt: prompt, system: system_instruction) }
+          .to output("Ruby is a programming language\n").to_stdout
+      end
+    end
+
+    context "with generation config options" do
+      it "includes temperature and max_tokens in generation config" do
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_return(prompt)
+        allow(mock_lm_studio_client).to receive(:generate_text)
+          .with(prompt, generation_config: {
+            temperature: 0.9,
+            max_tokens: 1000
+          })
+          .and_return(successful_response)
+
+        expect { command.call(prompt: prompt, temperature: 0.9, max_tokens: 1000) }
+          .to output("Ruby is a programming language\n").to_stdout
+      end
+    end
+
+    context "with JSON output format" do
+      it "outputs JSON format" do
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_return(prompt)
+        allow(mock_lm_studio_client).to receive(:generate_text)
+          .with(prompt)
+          .and_return(successful_response)
+
+        expected_json = {
+          text: "Ruby is a programming language",
+          metadata: {
+            finish_reason: "stop",
+            usage: {prompt_tokens: 10, completion_tokens: 20}
+          }
+        }
+
+        expect { command.call(prompt: prompt, format: "json") }
+          .to output(/#{Regexp.escape(expected_json[:text])}/).to_stdout
+      end
+    end
+
+    context "with empty prompt" do
+      it "exits with error" do
+        expect(command).to receive(:error_output).with("Error: Prompt is required")
+        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
+
+        expect { command.call(prompt: "") }.to raise_error(SystemExit)
+      end
+
+      it "exits with error for nil prompt" do
+        expect(command).to receive(:error_output).with("Error: Prompt is required")
+        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
+
+        expect { command.call(prompt: nil) }.to raise_error(SystemExit)
+      end
+    end
+
+    context "when prompt processing fails" do
+      it "handles CodingAgentTools::Error" do
+        error = CodingAgentTools::Error.new("File not found")
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_raise(error)
+
+        expect(command).to receive(:error_output).with("Error: File not found")
+        expect(command).to receive(:error_output).with("Use --debug flag for more information")
+        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
+
+        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
+      end
+
+      it "wraps other errors" do
+        error = StandardError.new("Unexpected error")
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_raise(error)
+
+        expect(command).to receive(:error_output).with("Error: Failed to process prompt: Unexpected error")
+        expect(command).to receive(:error_output).with("Use --debug flag for more information")
+        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
+
+        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
+      end
+    end
+
+    context "when LM Studio query fails" do
+      it "wraps errors" do
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_return(prompt)
+        error = StandardError.new("Server unavailable")
+        allow(mock_lm_studio_client).to receive(:generate_text)
+          .with(prompt)
+          .and_raise(error)
+
+        expect(command).to receive(:error_output).with("Error: Failed to query LM Studio: Server unavailable")
+        expect(command).to receive(:error_output).with("Use --debug flag for more information")
+        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
+
+        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
+      end
+    end
+
+    context "with debug flag" do
+      it "shows detailed error information" do
+        error = StandardError.new("Test error")
+        error.set_backtrace(["line1", "line2"])
+        allow(mock_prompt_processor).to receive(:process)
+          .with(prompt, from_file: false)
+          .and_raise(error)
+
+        expect(command).to receive(:error_output).with("Error: CodingAgentTools::Error: Failed to process prompt: Test error")
+        expect(command).to receive(:error_output).with("\nBacktrace:")
+        expect(command).to receive(:error_output).with("  line1")
+        expect(command).to receive(:error_output).with("  line2")
+        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
+
+        expect { command.call(prompt: prompt, debug: true) }.to raise_error(SystemExit)
+      end
+    end
+  end
+
+  describe "private methods" do
+    describe "#build_lm_studio_client" do
+      it "builds client with default options" do
+        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
+
+        command.send(:build_lm_studio_client, {})
+      end
+
+      it "builds client with model option" do
+        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
+          .with(model: "custom-model")
+
+        command.send(:build_lm_studio_client, {model: "custom-model"})
+      end
+    end
+
+    describe "#build_generation_options" do
+      it "builds empty options by default" do
+        options = command.send(:build_generation_options, {})
+        expect(options).to eq({})
+      end
+
+      it "includes system instruction" do
+        options = command.send(:build_generation_options, {system: "Be helpful"})
+        expect(options[:system_instruction]).to eq("Be helpful")
+      end
+
+      it "includes generation config" do
+        options = command.send(:build_generation_options, {
+          temperature: 0.9,
+          max_tokens: 1000
+        })
+
+        expect(options[:generation_config]).to eq({
+          temperature: 0.9,
+          max_tokens: 1000
+        })
+      end
+
+      it "excludes empty generation config" do
+        options = command.send(:build_generation_options, {})
+        expect(options).not_to have_key(:generation_config)
+      end
+    end
+
+    describe "#output_text_response" do
+      it "outputs text to stdout" do
+        response = {text: "Hello world"}
+
+        expect { command.send(:output_text_response, response) }
+          .to output("Hello world\n").to_stdout
+      end
+
+      it "returns the response" do
+        response = {text: "Hello world"}
+        result = nil
+        expect { result = command.send(:output_text_response, response) }
+          .to output("Hello world\n").to_stdout
+        expect(result).to eq(response)
+      end
+    end
+
+    describe "#output_json_response" do
+      it "outputs formatted JSON" do
+        response = {
+          text: "Hello world",
+          finish_reason: "stop",
+          usage_metadata: {tokens: 10}
+        }
+
+        allow(CodingAgentTools::Atoms::JSONFormatter).to receive(:pretty_format)
+          .and_return('{"formatted": "json"}')
+
+        expect { command.send(:output_json_response, response) }
+          .to output(%({"formatted": "json"}\n)).to_stdout
+      end
+
+      it "returns the response" do
+        response = {text: "Hello world"}
+        allow(CodingAgentTools::Atoms::JSONFormatter).to receive(:pretty_format)
+          .and_return("{}")
+
+        result = nil
+        expect { result = command.send(:output_json_response, response) }
+          .to output("{}\n").to_stdout
+        expect(result).to eq(response)
+      end
+    end
+
+    describe "#error_output" do
+      it "outputs to stderr" do
+        expect { command.send(:error_output, "Error message") }
+          .to output("Error message\n").to_stderr
+      end
+    end
+  end
+end
diff --git a/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb b/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
new file mode 100644
index 0000000..afb2fbc
--- /dev/null
+++ b/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
@@ -0,0 +1,394 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+require "coding_agent_tools/organisms/lm_studio_client"
+
+RSpec.describe CodingAgentTools::Organisms::LMStudioClient do
+  let(:client) { described_class.new }
+  let(:mock_request_builder) { instance_double(CodingAgentTools::Molecules::HTTPRequestBuilder) }
+  let(:mock_response_parser) { instance_double(CodingAgentTools::Molecules::APIResponseParser) }
+
+  before do
+    allow(CodingAgentTools::Molecules::HTTPRequestBuilder).to receive(:new).and_return(mock_request_builder)
+    allow(CodingAgentTools::Molecules::APIResponseParser).to receive(:new).and_return(mock_response_parser)
+  end
+
+  describe "#initialize" do
+    it "initializes with default values" do
+      expect(client.instance_variable_get(:@model)).to eq("mistralai/devstral-small-2505")
+      expect(client.instance_variable_get(:@base_url)).to eq("http://localhost:1234")
+    end
+
+    it "accepts custom model" do
+      custom_client = described_class.new(model: "custom-model")
+      expect(custom_client.instance_variable_get(:@model)).to eq("custom-model")
+    end
+
+    it "accepts custom base URL" do
+      custom_client = described_class.new(base_url: "http://custom:5678")
+      expect(custom_client.instance_variable_get(:@base_url)).to eq("http://custom:5678")
+    end
+
+    it "merges custom generation config" do
+      custom_client = described_class.new(generation_config: {temperature: 0.9})
+      config = custom_client.instance_variable_get(:@generation_config)
+      expect(config[:temperature]).to eq(0.9)
+      expect(config[:max_tokens]).to eq(-1) # Default value preserved
+    end
+  end
+
+  describe "#server_available?" do
+    context "when server is available" do
+      it "returns true" do
+        allow(mock_request_builder).to receive(:get_json)
+          .with("http://localhost:1234/v1/models")
+          .and_return({success: true, status: 200})
+
+        expect(client.server_available?).to be true
+      end
+    end
+
+    context "when server is not available" do
+      it "returns false on connection error" do
+        allow(mock_request_builder).to receive(:get_json)
+          .and_raise(StandardError.new("Connection refused"))
+
+        expect(client.server_available?).to be false
+      end
+
+      it "returns false on non-200 status" do
+        allow(mock_request_builder).to receive(:get_json)
+          .and_return({success: false, status: 500})
+
+        expect(client.server_available?).to be false
+      end
+    end
+  end
+
+  describe "#generate_text" do
+    let(:prompt) { "Hello, world!" }
+    let(:successful_response) do
+      {
+        success: true,
+        data: {
+          choices: [
+            {
+              message: {
+                content: "Hello! How can I help you today?"
+              },
+              finish_reason: "stop"
+            }
+          ],
+          usage: {
+            prompt_tokens: 10,
+            completion_tokens: 20,
+            total_tokens: 30
+          }
+        }
+      }
+    end
+
+    context "when server is available" do
+      before do
+        allow(client).to receive(:server_available?).and_return(true)
+      end
+
+      it "generates text successfully" do
+        expected_payload = {
+          model: "mistralai/devstral-small-2505",
+          messages: [
+            {role: "user", content: prompt}
+          ],
+          temperature: 0.7,
+          max_tokens: -1,
+          stream: false
+        }
+
+        allow(mock_request_builder).to receive(:post_json)
+          .with("http://localhost:1234/v1/chat/completions", expected_payload)
+          .and_return({success: true, status: 200, body: successful_response[:data]})
+
+        allow(mock_response_parser).to receive(:parse_response)
+          .and_return(successful_response)
+
+        result = client.generate_text(prompt)
+
+        expect(result[:text]).to eq("Hello! How can I help you today?")
+        expect(result[:finish_reason]).to eq("stop")
+        expect(result[:usage_metadata]).to eq(successful_response[:data][:usage])
+      end
+
+      it "includes system instruction when provided" do
+        system_instruction = "You are a helpful assistant."
+        expected_payload = {
+          model: "mistralai/devstral-small-2505",
+          messages: [
+            {role: "system", content: system_instruction},
+            {role: "user", content: prompt}
+          ],
+          temperature: 0.7,
+          max_tokens: -1,
+          stream: false
+        }
+
+        allow(mock_request_builder).to receive(:post_json)
+          .with("http://localhost:1234/v1/chat/completions", expected_payload)
+          .and_return({success: true, status: 200, body: successful_response[:data]})
+
+        allow(mock_response_parser).to receive(:parse_response)
+          .and_return(successful_response)
+
+        client.generate_text(prompt, system_instruction: system_instruction)
+      end
+
+      it "applies custom generation config" do
+        expected_payload = {
+          model: "mistralai/devstral-small-2505",
+          messages: [
+            {role: "user", content: prompt}
+          ],
+          temperature: 0.9,
+          max_tokens: 1000,
+          stream: false
+        }
+
+        allow(mock_request_builder).to receive(:post_json)
+          .with("http://localhost:1234/v1/chat/completions", expected_payload)
+          .and_return({success: true, status: 200, body: successful_response[:data]})
+
+        allow(mock_response_parser).to receive(:parse_response)
+          .and_return(successful_response)
+
+        client.generate_text(prompt, generation_config: {temperature: 0.9, max_tokens: 1000})
+      end
+    end
+
+    context "when server is not available" do
+      before do
+        allow(client).to receive(:server_available?).and_return(false)
+      end
+
+      it "raises an error" do
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /LM Studio server is not available/)
+      end
+    end
+
+    context "when API returns an error" do
+      before do
+        allow(client).to receive(:server_available?).and_return(true)
+      end
+
+      it "handles API errors" do
+        error_response = {
+          success: false,
+          error: {
+            status: 400,
+            message: "Bad Request",
+            details: {message: "Invalid model specified"}
+          }
+        }
+
+        allow(mock_request_builder).to receive(:post_json)
+          .and_return({success: false, status: 400, body: {error: "Invalid model"}})
+
+        allow(mock_response_parser).to receive(:parse_response)
+          .and_return(error_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /LM Studio API Error.*Invalid model specified/)
+      end
+    end
+
+    context "when response has invalid structure" do
+      before do
+        allow(client).to receive(:server_available?).and_return(true)
+      end
+
+      it "raises error when data is not a hash" do
+        invalid_response = {success: true, data: "not a hash"}
+
+        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /Response data is not a Hash/)
+      end
+
+      it "raises error when choices is not an array" do
+        invalid_response = {success: true, data: {choices: "not an array"}}
+
+        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /'choices' field is not an array/)
+      end
+
+      it "raises error when choices array is empty" do
+        invalid_response = {success: true, data: {choices: []}}
+
+        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /'choices' array is empty/)
+      end
+
+      it "raises error when first choice is not a hash" do
+        invalid_response = {success: true, data: {choices: ["not a hash"]}}
+
+        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /No valid first choice found/)
+      end
+
+      it "raises error when message is not a hash" do
+        invalid_response = {success: true, data: {choices: [{message: "not a hash"}]}}
+
+        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /choice 'message' field is missing or not a Hash/)
+      end
+
+      it "raises error when content key is missing" do
+        invalid_response = {success: true, data: {choices: [{message: {}}]}}
+
+        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /message does not have a 'content' key/)
+      end
+
+      it "raises error when content is nil" do
+        invalid_response = {success: true, data: {choices: [{message: {content: nil}}]}}
+
+        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
+
+        expect { client.generate_text(prompt) }
+          .to raise_error(CodingAgentTools::Error, /message content is nil/)
+      end
+    end
+  end
+
+  describe "#list_models" do
+    context "when server is available" do
+      before do
+        allow(client).to receive(:server_available?).and_return(true)
+      end
+
+      it "returns list of models" do
+        models_response = {
+          success: true,
+          data: {
+            data: [
+              {id: "model1", object: "model", owned_by: "local"},
+              {id: "model2", object: "model", owned_by: "local"}
+            ]
+          }
+        }
+
+        allow(mock_request_builder).to receive(:get_json)
+          .with("http://localhost:1234/v1/models")
+          .and_return({success: true, status: 200, body: models_response[:data]})
+
+        allow(mock_response_parser).to receive(:parse_response)
+          .and_return(models_response)
+
+        result = client.list_models
+
+        expect(result).to eq(models_response[:data][:data])
+      end
+
+      it "returns empty array when no models data" do
+        models_response = {success: true, data: {}}
+
+        allow(mock_request_builder).to receive(:get_json).and_return({success: true})
+        allow(mock_response_parser).to receive(:parse_response).and_return(models_response)
+
+        result = client.list_models
+
+        expect(result).to eq([])
+      end
+    end
+
+    context "when server is not available" do
+      before do
+        allow(client).to receive(:server_available?).and_return(false)
+      end
+
+      it "raises an error" do
+        expect { client.list_models }
+          .to raise_error(CodingAgentTools::Error, /LM Studio server is not available/)
+      end
+    end
+  end
+
+  describe "#model_info" do
+    it "returns model info from list when model exists" do
+      models = [
+        {id: "mistralai/devstral-small-2505", object: "model", owned_by: "local"},
+        {id: "other-model", object: "model", owned_by: "local"}
+      ]
+
+      allow(client).to receive(:list_models).and_return(models)
+
+      result = client.model_info
+
+      expect(result[:id]).to eq("mistralai/devstral-small-2505")
+      expect(result[:object]).to eq("model")
+    end
+
+    it "returns default info when model not found in list" do
+      allow(client).to receive(:list_models).and_return([])
+
+      result = client.model_info
+
+      expect(result[:id]).to eq("mistralai/devstral-small-2505")
+      expect(result[:object]).to eq("model")
+      expect(result[:owned_by]).to eq("local")
+    end
+  end
+
+  describe "private methods" do
+    describe "#build_api_url" do
+      it "builds correct API URL" do
+        url = client.send(:build_api_url, "chat/completions")
+        expect(url).to eq("http://localhost:1234/v1/chat/completions")
+      end
+    end
+
+    describe "#build_generation_payload" do
+      it "builds basic payload" do
+        payload = client.send(:build_generation_payload, "Hello", {})
+
+        expect(payload[:model]).to eq("mistralai/devstral-small-2505")
+        expect(payload[:messages]).to eq([{role: "user", content: "Hello"}])
+        expect(payload[:temperature]).to eq(0.7)
+        expect(payload[:max_tokens]).to eq(-1)
+        expect(payload[:stream]).to be false
+      end
+
+      it "includes system instruction" do
+        payload = client.send(:build_generation_payload, "Hello", {system_instruction: "Be helpful"})
+
+        expect(payload[:messages]).to eq([
+          {role: "system", content: "Be helpful"},
+          {role: "user", content: "Hello"}
+        ])
+      end
+
+      it "applies custom generation config" do
+        payload = client.send(:build_generation_payload, "Hello", {generation_config: {temperature: 0.9}})
+
+        expect(payload[:temperature]).to eq(0.9)
+      end
+    end
+  end
+end
diff --git a/spec/integration/llm_gemini_query_integration_spec.rb b/spec/integration/llm_gemini_query_integration_spec.rb
index e0ed079..b312c61 100644
--- a/spec/integration/llm_gemini_query_integration_spec.rb
+++ b/spec/integration/llm_gemini_query_integration_spec.rb
@@ -97,7 +97,7 @@ RSpec.describe "llm-gemini-query integration", type: :aruba do
         cassette_name = "llm_gemini_query_integration/uses_custom_model"
         setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)
 
-        run_command("#{ruby_path} #{exe_path} 'Hi' --model gemini-2.0-flash-lite --format json")
+        run_command("#{ruby_path} #{exe_path} 'Hi' --model gemini-1.5-flash --format json")
 
         expect(last_command_started).to have_exit_status(0)
         expect(last_command_started.stderr).to be_empty
diff --git a/spec/integration/llm_lmstudio_query_integration_spec.rb b/spec/integration/llm_lmstudio_query_integration_spec.rb
new file mode 100644
index 0000000..a7ae801
--- /dev/null
+++ b/spec/integration/llm_lmstudio_query_integration_spec.rb
@@ -0,0 +1,403 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+require "aruba/rspec"
+
+RSpec.describe "llm-lmstudio-query integration", type: :aruba do
+  let(:exe_path) { File.expand_path("../../exe/llm-lmstudio-query", __dir__) }
+  let(:ruby_path) { RbConfig.ruby }
+
+  # Helper method to setup VCR environment for Aruba
+  def setup_vcr_env(cassette_name, base_env = {})
+    vcr_setup_path = File.expand_path("../vcr_setup.rb", __dir__)
+    # Include bundler environment to ensure subprocess has access to gems
+    bundler_env = {
+      "BUNDLE_GEMFILE" => ENV["BUNDLE_GEMFILE"],
+      "BUNDLE_PATH" => ENV["BUNDLE_PATH"],
+      "BUNDLE_BIN_PATH" => ENV["BUNDLE_BIN_PATH"],
+      "RACK_ENV" => ENV["RACK_ENV"] || "test",
+      "RUBYOPT" => "-rbundler/setup -r#{vcr_setup_path}",
+      "VCR_CASSETTE_NAME" => cassette_name,
+      # Ensure proper encoding for Unicode handling in CI
+      "LANG" => ENV["LANG"].to_s.empty? ? "en_US.UTF-8" : ENV["LANG"],
+      "LC_ALL" => ENV["LC_ALL"].to_s.empty? ? "en_US.UTF-8" : ENV["LC_ALL"],
+      "LC_CTYPE" => ENV["LC_CTYPE"].to_s.empty? ? "en_US.UTF-8" : ENV["LC_CTYPE"]
+    }.compact # Remove nil values
+
+    env_vars = base_env.merge(bundler_env)
+    env_vars.each { |key, value| set_environment_variable(key, value) }
+  end
+
+  describe "command execution" do
+    it "shows help when requested" do
+      run_command("#{ruby_path} #{exe_path} --help")
+
+      expect(last_command_started).to have_exit_status(0)
+      expect(last_command_started).to have_output(/Query LM Studio AI with a prompt/)
+      expect(last_command_started).to have_output(/--format/)
+      expect(last_command_started).to have_output(/--debug/)
+      expect(last_command_started).to have_output(/--model/)
+      expect(last_command_started).to have_output(/Examples:/)
+    end
+
+    it "requires a prompt argument" do
+      run_command("#{ruby_path} #{exe_path}")
+
+      expect(last_command_started).to have_exit_status(1)
+      expect(last_command_started).to have_output(/ERROR: "llm-lmstudio-query" was called with no arguments/)
+    end
+  end
+
+  describe "API integration" do
+    context "with LM Studio server available" do
+      # Skip these tests if LM Studio server is not running
+      before do
+        # Quick check if LM Studio is available
+        require "net/http"
+        begin
+          uri = URI("http://localhost:1234/v1/models")
+          response = Net::HTTP.get_response(uri)
+          skip "LM Studio server not available at localhost:1234" if response.code != "200"
+        rescue => e
+          skip "LM Studio server not available: #{e.message}"
+        end
+      end
+
+      it "queries LM Studio with a simple prompt", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'What is 2+2? Reply with just the number.'")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started).to have_output(/4/)
+        expect(last_command_started.stderr).to be_empty
+      end
+
+      it "outputs JSON format when requested", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/outputs_json_format"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Say hello' --format json")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+
+        json_output = JSON.parse(last_command_started.stdout)
+        expect(json_output).to have_key("text")
+        expect(json_output).to have_key("metadata")
+        expect(json_output["metadata"]).to have_key("finish_reason")
+        expect(json_output["metadata"]).to have_key("usage")
+      end
+
+      it "reads prompt from file", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/reads_prompt_from_file"
+        setup_vcr_env(cassette_name)
+
+        write_file("prompt.txt", "What is the capital of France? Reply with just the city name.")
+
+        run_command("#{ruby_path} #{exe_path} prompt.txt --file")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+        expect(last_command_started).to have_output(/Paris/i)
+      end
+
+      it "uses custom model when specified", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/uses_custom_model"
+        setup_vcr_env(cassette_name)
+
+        # Use default model for testing model override
+        run_command("#{ruby_path} #{exe_path} 'Hi' --model mistralai/devstral-small-2505 --format json")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+
+        json_output = JSON.parse(last_command_started.stdout)
+        expect(json_output["text"]).not_to be_empty
+      end
+
+      it "applies temperature setting", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/applies_temperature_setting"
+        setup_vcr_env(cassette_name)
+
+        # Low temperature should give more consistent results
+        run_command("#{ruby_path} #{exe_path} 'Complete this: The sky is' --temperature 0.1")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stdout.strip).not_to be_empty
+      end
+
+      it "respects max tokens limit", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/respects_max_tokens"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Write a very long story about a dragon' --max-tokens 50 --format json")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+
+        json_output = JSON.parse(last_command_started.stdout)
+        # The output should be truncated due to token limit
+        expect(json_output["text"].split.size).to be < 100
+      end
+
+      it "uses system instruction", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/uses_system_instruction"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Hello' --system 'You are a helpful assistant. Always respond with enthusiasm.'")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+        # Should contain enthusiastic language
+        expect(last_command_started.stdout).not_to be_empty
+      end
+    end
+
+    context "with LM Studio server unavailable" do
+      it "shows error message when server is not running" do
+        # Mock the server check to return false
+        run_command("#{ruby_path} -e \"
+          require 'webmock'
+          WebMock.enable!
+          WebMock.stub_request(:get, 'http://localhost:1234/v1/models').to_raise(Errno::ECONNREFUSED)
+          load '#{exe_path}'
+        \" 'Test prompt'")
+
+        expect(last_command_started).not_to have_exit_status(0)
+        expect(last_command_started.stderr).to include("Error:")
+        expect(last_command_started.stderr).to match(/LM Studio server.*not available/i)
+      end
+
+      it "shows detailed error with debug flag when server unavailable" do
+        # Mock the server check to return connection refused
+        run_command("#{ruby_path} -e \"
+          require 'webmock'
+          WebMock.enable!
+          WebMock.stub_request(:get, 'http://localhost:1234/v1/models').to_raise(Errno::ECONNREFUSED)
+          load '#{exe_path}'
+        \" 'Test prompt' --debug")
+
+        expect(last_command_started).not_to have_exit_status(0)
+        expect(last_command_started.stderr).to include("Error:")
+        expect(last_command_started.stderr).to include("Backtrace:")
+      end
+    end
+  end
+
+  describe "error handling" do
+    it "handles malformed JSON prompt file gracefully", :vcr do
+      write_file("malformed.json", '{"invalid": json}')
+
+      run_command("#{ruby_path} #{exe_path} malformed.json --file")
+
+      expect(last_command_started).not_to have_exit_status(0)
+      expect(last_command_started.stderr).to include("Error:")
+    end
+
+    it "handles non-existent file" do
+      run_command("#{ruby_path} #{exe_path} /non/existent/file.txt --file")
+
+      expect(last_command_started).not_to have_exit_status(0)
+      expect(last_command_started.stderr).to match(/not found|does not exist/i)
+    end
+
+    it "handles empty file" do
+      write_file("empty.txt", "")
+
+      run_command("#{ruby_path} #{exe_path} empty.txt --file")
+
+      expect(last_command_started).not_to have_exit_status(0)
+      expect(last_command_started.stderr).to match(/empty|blank/i)
+    end
+  end
+
+  describe "output formats" do
+    context "with LM Studio available" do
+      before do
+        # Skip if LM Studio is not available
+        require "net/http"
+        begin
+          uri = URI("http://localhost:1234/v1/models")
+          response = Net::HTTP.get_response(uri)
+          skip "LM Studio server not available" if response.code != "200"
+        rescue => e
+          skip "LM Studio server not available: #{e.message}"
+        end
+      end
+
+      it "outputs clean text by default", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/outputs_clean_text_by_default"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Reply with exactly: Hello World'")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+        expect(last_command_started.stdout.strip).to include("Hello World")
+        # Should not contain JSON formatting
+        expect(last_command_started.stdout).not_to include("{")
+        expect(last_command_started.stdout).not_to include("}")
+      end
+
+      it "outputs valid JSON with metadata when requested", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/outputs_valid_json_with_metadata"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Say hi' --format json")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+
+        # Verify it's valid JSON
+        json_output = JSON.parse(last_command_started.stdout)
+
+        # Check structure
+        expect(json_output).to be_a(Hash)
+        expect(json_output).to have_key("text")
+        expect(json_output).to have_key("metadata")
+
+        # Check metadata structure
+        metadata = json_output["metadata"]
+        expect(metadata).to have_key("finish_reason")
+        expect(metadata).to have_key("usage")
+
+        # Usage should have token counts (if available)
+        usage = metadata["usage"]
+        expect(usage).to be_a(Hash) if usage
+      end
+    end
+  end
+
+  describe "complex prompts" do
+    context "with LM Studio available" do
+      before do
+        # Skip if LM Studio is not available
+        require "net/http"
+        begin
+          uri = URI("http://localhost:1234/v1/models")
+          response = Net::HTTP.get_response(uri)
+          skip "LM Studio server not available" if response.code != "200"
+        rescue => e
+          skip "LM Studio server not available: #{e.message}"
+        end
+      end
+
+      it "handles multi-line prompts from file", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/handles_multiline_prompts_from_file"
+        setup_vcr_env(cassette_name)
+
+        write_file("multiline.txt", <<~PROMPT)
+          This is a multi-line prompt.
+          It has several lines.
+
+          And even blank lines.
+
+          Reply with: "Multi-line received"
+        PROMPT
+
+        run_command("#{ruby_path} #{exe_path} multiline.txt --file")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+        expect(last_command_started.stdout).to include("Multi-line received")
+      end
+
+      it "handles prompts with special characters", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/handles_prompts_with_special_characters"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Echo this exactly: Special chars @#$%&*()_+={[}]|\:;\"<,>.?/'")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+        # LM Studio should handle special characters
+        expect(last_command_started.stdout.strip).not_to be_empty
+      end
+
+      it "handles Unicode prompts", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/handles_unicode_prompts"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Translate to English: こんにちは'")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+        expect(last_command_started.stdout.downcase).to match(/hello|hi|good|translation/)
+      end
+
+      it "handles very long prompts", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/handles_very_long_prompts"
+        setup_vcr_env(cassette_name)
+
+        long_prompt = "Please summarize this text: " + ("Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 50)
+
+        run_command("#{ruby_path} #{exe_path} '#{long_prompt}' --format json")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stderr).to be_empty
+
+        json_output = JSON.parse(last_command_started.stdout)
+        expect(json_output["text"]).not_to be_empty
+      end
+    end
+  end
+
+  describe "performance and reliability" do
+    context "with LM Studio available" do
+      before do
+        # Skip if LM Studio is not available
+        require "net/http"
+        begin
+          uri = URI("http://localhost:1234/v1/models")
+          response = Net::HTTP.get_response(uri)
+          skip "LM Studio server not available" if response.code != "200"
+        rescue => e
+          skip "LM Studio server not available: #{e.message}"
+        end
+      end
+
+      it "completes requests within reasonable time", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/completes_requests_within_reasonable_time"
+        setup_vcr_env(cassette_name)
+
+        start_time = Time.now
+
+        run_command("#{ruby_path} #{exe_path} 'Say hello quickly'")
+
+        duration = Time.now - start_time
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(duration).to be < 180 # 3 minute timeout for local model inference
+        expect(last_command_started.stdout.strip).not_to be_empty
+      end
+    end
+  end
+
+  describe "model management" do
+    context "with LM Studio available" do
+      before do
+        # Skip if LM Studio is not available
+        require "net/http"
+        begin
+          uri = URI("http://localhost:1234/v1/models")
+          response = Net::HTTP.get_response(uri)
+          skip "LM Studio server not available" if response.code != "200"
+        rescue => e
+          skip "LM Studio server not available: #{e.message}"
+        end
+      end
+
+      it "works with default model", :vcr do
+        cassette_name = "llm_lmstudio_query_integration/works_with_default_model"
+        setup_vcr_env(cassette_name)
+
+        run_command("#{ruby_path} #{exe_path} 'Test default model'")
+
+        expect(last_command_started).to have_exit_status(0)
+        expect(last_command_started.stdout.strip).not_to be_empty
+      end
+    end
+  end
+end
diff --git a/spec/vcr_setup.rb b/spec/vcr_setup.rb
index 9652a7a..1db690d 100644
--- a/spec/vcr_setup.rb
+++ b/spec/vcr_setup.rb
@@ -23,7 +23,10 @@ VCR.configure do |config|
   # Configure to handle Gemini API
   config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }
 
-  # Allow localhost connections for tests
+  # Configure to handle LM Studio API (localhost)
+  config.filter_sensitive_data("<LM_STUDIO_API_KEY>") { ENV["LM_STUDIO_API_KEY"] }
+
+  # Allow localhost connections for tests (needed for LM Studio)
   config.ignore_localhost = false
 
   # Configure for test environment
diff --git a/test_prompt.txt b/test_prompt.txt
new file mode 100644
index 0000000..e965047
--- /dev/null
+++ b/test_prompt.txt
@@ -0,0 +1 @@
+Hello

```

### Project Context Documentation
*This section is populated when using the --include-dependencies flag*

#### Project Documentation
Location: `docs-project/*.md` (excluding roadmap)
Current files:
- ### docs-project/architecture.md
```markdown
# Coding Agent Tools Ruby Gem - Architecture

## Overview

This document outlines the architectural design and technical implementation details for the Coding Agent Tools (CAT) Ruby Gem. It provides a structured view of the system for developers and AI agents, explaining how the different components interact to provide automated development workflows. For a more high-level overview of the project structure and organization, refer to the [Project Blueprint](./blueprint.md).

## Technology Stack

### Core Technologies

- **Primary Language**: Ruby
- **Runtime/Framework**: MRI (C Ruby) version 3.2 or later
- **Database**: N/A (Gem does not have a primary database; interacts with Git, files, and external APIs)
- **Package Manager**: Bundler

### Development Tools

- **Build System**: Standard Ruby Gem build (`gemspec`)
- **Testing Framework**: RSpec (for unit and integration tests), Aruba (for CLI integration tests)
- **Linting/Formatting**: RuboCop (likely used for style enforcement)
- **Type System**: Native Ruby (Sorbet not explicitly mentioned in PRD v1)

### Infrastructure & Deployment

- **Containerization**: Optional (e.g., Docker for running LM Studio)
- **Cloud Platform**: N/A (Gem runs locally or in CI environments)
- **CI/CD**: GitHub Actions (used for automated testing and building)
- **Monitoring**: Basic opt-in analytics via Snowplow collector (v1)

## System Architecture

### High-Level Components

The gem's architecture is designed for modularity and testability. The code within `lib/coding_agent_tools/` specifically follows an ATOM-based hierarchy (Atoms, Molecules, Organisms, Ecosystems) inspired by Atomic Design principles for composing functionality. This high-level component breakdown is also reflected in the project's directory structure, as detailed in the [Project Blueprint's Project Organization section](./blueprint.md#project-organization).

```mermaid
flowchart TD
    subgraph Ruby Gem (CAT)
        direction TB
        CLI[Executables / bin/*]
        ServiceObjects[🔧 Service Objects]
        Adapters[🌐 Adapters]
        Models[(Data Models)]
    end
    CLI --> ServiceObjects --> Adapters
    Adapters -->|Gemini REST| GeminiAPI((Google Gemini))
    Adapters -->|LM Studio| LMStudio((Local Model))\n(localhost:1234)
    Adapters -->|Git CLI / GitHub API| GitHub((Git/GitHub))
    ServiceObjects --> Models
    Models -->|Reads from/Writes to| LocalFS[(Local File System)\n(e.g., docs-project tasks)]
```

### Component Descriptions

#### CLI (Action Layer)
- **Purpose**: Provides the command-line interface for user and agent interaction.
- **Technology**: Ruby, potentially using libraries like Thor or Dry-CLI.
- **Key Responsibilities**: Parsing command-line arguments, initial input validation, invoking the appropriate Service Objects.
- **Interfaces**: Communicates with Service Objects.

#### Service Objects (Transformation Layer)
- **Purpose**: Contains the core business logic and orchestrates operations.
- **Technology**: Pure Ruby classes.
- **Key Responsibilities**: Implementing specific workflows (e.g., generating a commit message, finding the next task), transforming data between models and adapters.
- **Interfaces**: Interacts with Adapters and Models. Designed to be testable in isolation.

#### Adapters (Operation Layer)
- **Purpose**: Provides interfaces to external systems or tools (LLMs, Git, file system).
- **Technology**: Ruby classes wrapping external libraries or system calls.
- **Key Responsibilities**: Handling communication protocols (HTTP, system commands), error handling for external interactions, translating external responses into internal data models.
- **Interfaces**: Communicates with external APIs/tools and is used by Service Objects.

#### Models (Model Layer)
- **Purpose**: Represents the data structures used within the gem.
- **Technology**: Plain Old Ruby Objects (POROs) or simple data structures.
- **Key Responsibilities**: Defining the structure of data related to Git objects, task items, API responses, etc.
- **Interfaces**: Used by Service Objects and Adapters.

### ATOM-Based Code Structure in `lib/coding_agent_tools/`

The internal structure of the gem's library code (`lib/coding_agent_tools/`) adheres to an ATOM-based hierarchy, promoting reusability and clear separation of concerns:

-   **Atoms (`lib/coding_agent_tools/atoms/`)**: The smallest, indivisible units of behavior or functionality. They have no dependencies on other parts of this gem and are highly reusable (e.g., `EnvReader` for environment variables, `HTTPClient` for external API calls, `JSONFormatter` for data serialization/deserialization, utility functions for string normalization, basic file readers).
-   **Molecules (`lib/coding_agent_tools/molecules/`)**: Simple compositions of Atoms that form a meaningful, reusable operation (e.g., `APICredentials` for managing authentication details, `HTTPRequestBuilder` for constructing API requests, `APIResponseParser` for handling API responses, configuration loaders using file access and parsing atoms, basic Git clients using command execution atoms).
-   **Organisms (`lib/coding_agent_tools/organisms/`)**: More complex units that perform specific business-related functions or features of the gem. They orchestrate Molecules and Atoms to achieve a distinct goal (e.g., `GeminiClient` for interacting with the Gemini API, `PromptProcessor` for preparing and parsing LLM prompts, LLM queriers, commit message suggesters). These often correspond to Service Objects.
-   **Ecosystems (`lib/coding_agent_tools/ecosystems/`)**: Cohesive groupings of Organisms and other components that deliver a larger, bounded context or subsystem. The overall CLI application, orchestrated by `dry-cli`, can be considered the primary ecosystem.
-   **Models (`lib/coding_agent_tools/models/`)**: Plain Old Ruby Objects (POROs) or simple data structures used across various layers to represent entities and data (e.g., `Task`, `LLMResponse`).
-   **CLI Commands (`lib/coding_agent_tools/cli/` and `lib/coding_agent_tools/cli.rb`)**: These are the entry points for the command-line interface, built using `dry-cli`. Commands typically delegate their core logic to Organisms.
-   **Cross-Cutting Concerns (`lib/coding_agent_tools/`)**: Modules that provide shared functionalities used across different layers, ensuring consistency and centralized handling of aspects like logging, error reporting, and middleware processing (e.g., `middlewares/` for request/response processing, `notifications.rb` for system-wide alerts, `error.rb` for custom error definitions, `cli.rb` for command registration).

## Data Flow

Data typically flows from the CLI (user input) to a Service Object, which uses Adapters to interact with external systems (LLM, Git, file system). The Adapters return data, potentially mapped to internal Models, back to the Service Object for processing. The final result is returned through the Adapter layer back to the Service Object, and finally outputted via the CLI. For task utilities, data might be read from local files (`docs-project/`) via an Adapter/Service Object and formatted for CLI output.

### Request Processing Flow (Example: git-commit-with-message)

1.  **Input**: User/agent invokes `bin/git-commit-with-message` with arguments (`--intention`, `--files`, etc.).
2.  **Processing (CLI)**: The CLI executable parses arguments, calls the relevant Service Object.
3.  **Processing (Service Object)**: Service Object gathers necessary context (diff from Git via Adapter), prepares prompt for LLM.
4.  **External Interaction (Adapter)**: Service Object calls the LLM Adapter (e.g., `GeminiAdapter`) with the prompt.
5.  **External Service**: LLM API processes the prompt and returns a message.
6.  **Processing (Adapter)**: Adapter receives the LLM response, potentially validates/formats it, returns to Service Object.
7.  **Processing (Service Object)**: Service Object takes the generated message, stages files (via Git Adapter), and performs the Git commit (via Git Adapter).
8.  **Output**: CLI confirms the commit or reports errors.

## Command-line Tools (bin/)

The `bin/` directory contains executable scripts that serve as the primary interface for the gem. These are often thin wrappers (binstubs) that invoke the main gem logic.

### Key Commands (as per PRD):

-   `bin/llm-gemini-query`: Query Google Gemini.
-   `bin/lms-studio-query`: Query local LM Studio.
-   `bin/github-repository-create`: Create a GitHub repository.
-   `bin/git-commit-with-message`: Generate and perform a Git commit.
-   `bin/tr`: List recent tasks.
-   `bin/tn`: Find the next actionable task.
-   `bin/rc`: Get current release path and version.
-   `bin/test`: Run the test suite.
-   `bin/lint`: Run code quality checks.
-   `bin/build`: Build the gem.
-   `bin/run`: (Context dependent, potentially runs gem commands or a sample usage).
-   `bin/tree`: Display project directory structure (likely wraps `docs-dev/tools/tree.sh`).

These scripts are intended to be idempotent where possible and provide a consistent, predictable interface for automation.

## File Organization

```
.
├── bin/                   # Executable command-line scripts (binstubs/wrappers)
├── docs-dev/              # Submodule: Development resources, guides, templates, tools
│   ├── guides/            # Best practices, patterns, templates
│   ├── tools/             # Utility scripts (e.g., for task management, tree display)
│   └── workflow-instructions/ # AI workflow definitions
├── docs-project/          # Project-specific documentation and management files
│   ├── backlog/           # Task files for future releases
│   ├── current/           # Task files for the current release
│   ├── done/              # Completed task files
│   ├── decisions/         # Architecture Decision Records (.keep file ensures directory exists)
│   ├── architecture.md    # This document
│   ├── blueprint.md       # Project structure overview and AI guidelines
│   └── what-do-we-build.md # Project vision and goals
├── exe/                   # Gem executables (e.g., coding_agent_tools)
├── lib/                   # Ruby gem source code
│   ├── coding_agent_tools.rb # Main gem file, loads components
│   └── coding_agent_tools/
│       ├── atoms/         # Smallest, indivisible units (utilities, transformations)
│       ├── cli/           # Dry-CLI command definitions and subcommands
│       ├── ecosystems/    # Complete subsystems or major features
│       ├── middlewares/   # Common middleware for request/response processing
│       ├── molecules/     # Simple compositions of atoms
│       ├── models/        # Data structures (POROs)
│       ├── notifications.rb # Global notification and event handling
│       ├── organisms/     # Business logic handlers, orchestrating molecules/atoms
│       ├── cli.rb         # Main Dry-CLI registry
│       ├── error.rb       # Custom gem-specific error classes
│       └── version.rb     # Gem version definition
├── spec/                  # RSpec test files (unit, integration, CLI)
├── .github/               # GitHub specific files (e.g. workflows)
│   └── workflows/
│       └── main.yml       # CI workflow
├── .gitignore             # Specifies intentionally untracked files
├── .rspec                 # RSpec configuration
├── .standard.yml          # StandardRB configuration
├── CHANGELOG.md           # Record of changes
├── Gemfile                # Bundler dependency file
├── LICENSE.txt            # Project license
├── PRD.md                 # Product Requirements Document (primary source of truth)
├── Rakefile               # Rake tasks
├── README.md              # Project overview and quick start guide
└── coding_agent_tools.gemspec # Gem specification file
```

The primary Ruby source code resides in the `lib/coding_agent_tools/` directory, organized according to the ATOM pattern. Tests are located in the `spec/` directory. For a comprehensive overview of the overall project directory structure, refer to the [Project Blueprint's Project Organization section](./blueprint.md#project-organization).

## Development Patterns

-   **ATOM-Based Hierarchy**: The core library implementation (`lib/coding_agent_tools/`) follows an Atoms, Molecules, Organisms, Ecosystems hierarchy to ensure modularity, reusability, testability, and maintainability. This pattern promotes a clear separation of concerns, making components easier to understand, test, and adapt.
-   **Test-Driven Development (TDD)**: A strong emphasis is placed on writing tests (`spec/`) before or alongside implementation code, aiming for high test coverage. This approach ensures code correctness and facilitates refactoring.
-   **Dependency Injection**: Components are designed to accept dependencies (like adapters) via initialization rather than creating them internally. This facilitates easier testing by allowing mock objects to be injected, and promotes flexibility by decoupling components from their concrete implementations.
-   **CLI-First Design**: The architecture prioritizes a robust and predictable command-line interface as the primary interaction method. This allows the gem to be easily integrated into automated workflows and used directly by developers or other agents.
-   **Testing with VCR**: HTTP interactions with external APIs are recorded and replayed using VCR. This ensures tests are fast, reliable, and deterministic, as they do not rely on live external services, making the test suite robust against network issues or API changes.
-   **Observability with dry-monitor**: Key events and operations within the gem are instrumented using `dry-monitor`. This allows for centralized logging, error reporting, and performance monitoring by decoupling the event emitters from their consumers, thus avoiding tightly coupled concerns and promoting a flexible monitoring setup.

## Security Considerations

-   **API Key/Token Handling**: The gem avoids hardcoding secrets. API keys and tokens (e.g., `GEMINI_API_KEY`, `GITHUB_TOKEN`) are read from environment variables or standard configuration locations (`~/.gemini/config`, macOS keychain).
-   **No Plaintext Secrets in Logs**: Logging is designed to avoid exposing sensitive information.
-   **Input Validation**: Basic input validation is performed, particularly at the CLI/Action layer, to prevent command injection or other security vulnerabilities.

## Performance Considerations

-   **Startup Latency**: Target low startup latency (≤ 200 ms for CLI commands) for responsiveness, especially when invoked by agents.
-   **Caching**: Potential for implementing caching strategies (e.g., for LLM responses or frequently accessed data) to improve performance.
-   **Profiling**: Standard Ruby profiling tools can be used to identify performance bottlenecks.

## Deployment Architecture

The gem is deployed as a standard RubyGem.

-   **Installation**: Users install via `gem install coding_agent_tools` or by adding `gem 'coding_agent_tools'` to their `Gemfile` and running `bundle install`.
-   **Binstubs**: Bundler generates binstubs in the project's `bin/` directory (or globally if installed system-wide), providing convenient wrappers for executables.
-   **CI/CD**: GitHub Actions are used to build the gem, run tests, and potentially publish new versions.

## Extension Points

The ATOM architecture provides several extension points:

-   **New Commands**: Add new executables in `bin/` and corresponding Action/Service Object logic in `lib/`.
-   **New Adapters**: Implement new Adapters in `lib/coding_agent_tools/operations/` to integrate with different external APIs, LLM providers, or tools. These can then be used by existing or new Service Objects.
-   **New Models**: Define new data structures in `lib/coding_agent_tools/models/` as needed for new features or data representations.
-   **Custom Scripts**: Users can create their own scripts in the project's `bin/` directory that utilize the gem's internal API or CLI commands.

## Dependencies

### Runtime Dependencies

-   Ruby (>= 3.2)
-   Bundler
-   `faraday`: Flexible HTTP client library.
-   `zeitwerk`: Efficient and thread-safe code loader.
-   `dry-monitor`: Event-based monitoring and instrumentation toolkit.
-   `dry-configurable`: Provides configuration capabilities for Ruby objects.
-   `addressable`: URI manipulation library, replacing Ruby's URI.
-   Standard system **Git CLI**
-   Optional: **LM Studio** for offline LLM support

### Development Dependencies

-   RSpec: Testing framework.
-   RuboCop / StandardRB: Code style linter and formatter.
-   `vcr`: Records and replays HTTP interactions for tests.
-   `webmock`: Stubs and sets expectations on HTTP requests.
-   `docs-dev/tools/*` scripts: Dependencies for certain `bin/` utilities that wrap scripts from the `docs-dev` submodule.
-   **SimpleCov** - Code coverage analysis
-   **Pry** - Interactive debugging

For a comprehensive and up-to-date list of dependencies, refer to the `coding_agent_tools.gemspec` and `Gemfile`, and consult the [Project Blueprint's Dependencies section](./blueprint.md#dependencies) for a complementary overview.

## Decision Records

Significant architectural decisions are documented as Architecture Decision Records (ADRs).

For detailed decision records, see [docs-project/decisions/](../../../coding-agent-tools/docs-project/decisions/).

## Troubleshooting

(This section is a placeholder and should be populated with common issues and their solutions as they are identified.)

-   **Issue**: Command not found after installation.
    -   **Symptoms**: Running `bin/tn` or other commands results in "command not found".
    -   **Solution**: Ensure Bundler binstubs are set up and your PATH includes the project's `bin/` directory. Run `bundle install` if using Bundler.

-   **Issue**: LLM query fails.
    -   **Symptoms**: Commands like `bin/llm-gemini-query` report API errors or connection issues.
    -   **Solution**: Check environment variables (`GEMINI_API_KEY`), network connectivity, and the status of the LM Studio server if using the local model.

## Future Considerations

-   **Multi-language bindings**: Explore providing SDKs or libraries in languages other than Ruby (post v1).
-   **Streaming LLM responses**: Investigate if agents require streaming output from LLMs rather than waiting for a full reply.
-   **Encrypted local storage**: Consider if caching or storing sensitive data locally requires encryption.
-   **Rubocop plugin**: Assess the value of a Rubocop plugin to enforce ATOM directory boundaries and other architectural conventions.
-   **Advanced Task Management Integration**: Explore deeper integrations with external task management systems.
```
- ### docs-project/blueprint.md
```markdown
# Project Blueprint: Coding Agent Tools Ruby Gem

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents

- [What We Build](./what-do-we-build.md) - Project vision and goals
- [Architecture](./architecture.md) - System design and implementation principles

## Project Organization

This project follows a documentation-first approach with these primary directories:

- **docs-dev/** - Development resources and workflows (Git submodule)
  - **guides/** - Best practices and standards for development
  - **tools/** - Utility scripts to support development workflows (e.g., for task management, tree display)
  - **workflow-instructions/** - Structured commands for AI agents
  - **zed/** - Editor integration (if applicable)

- **docs-project/** - Project-specific documentation, task management, and decisions
  - **backlog/** - Pending tasks for future releases
  - **current/** - Active release cycle work
  - **done/** - Completed releases and tasks
  - **decisions/** - Architecture Decision Records (ADRs)

- **bin/** - Executable scripts (binstubs/wrappers) for project automation (e.g., `bin/test`, `bin/tn`)

- **exe/** - Primary gem executables (e.g., `exe/llm-gemini-query`)

- **lib/** - Ruby gem source code, organized by the ATOM architecture pattern with subdirectories for `atoms/`, `molecules/`, `organisms/`, `cli/`, `models/`, and cross-cutting concerns like `middlewares/`.

- **spec/** - RSpec test files (unit, integration, CLI)

<!-- Add your project-specific directories here -->

## View Complete Directory Structure

To see the complete filtered directory structure, run:

```bash
bin/tree
```

This will show all project files while filtering out temporary files, session logs, and other non-essential directories.

## Key Project-Specific Files

- [Product Requirements Document (PRD)](../../PRD.md) - Primary source of truth for project goals and requirements
- [Main README](../../README.md) - Project overview, installation, runtime configuration, and user-facing documentation
- [Development Guide](../../docs/DEVELOPMENT.md) - Development environment setup, testing, build tools, and contributor workflow
- [Workflow Instructions](../../docs-dev/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](../../docs-dev/guides/README.md) - Development standards and best practices
- `coding_agent_tools.gemspec` - Ruby gem definition and dependencies
- `Gemfile` - Bundler dependency management

## Technology Stack

- **Primary Language**: Ruby (>= 3.4.2)
- **Architecture Pattern**: ATOM (Action, Transformation, Operation, Model), Zeitwerk for efficient code loading, and dry-monitor for observability
- **Runtime Dependencies**: Faraday (HTTP client), dry-cli (CLI framework), dry-configurable (configuration management), addressable (URI parsing and manipulation)
- **Development Tools**: RSpec, StandardRB, VCR, WebMock, Aruba, Zeitwerk
- **Integrations**: Google Gemini API, LM Studio (local), Git CLI, GitHub REST API

### Documentation Separation

- **README.md**: Contains runtime information, installation instructions, basic usage, and configuration for end users
- **docs/DEVELOPMENT.md**: Contains development environment setup, testing frameworks, build tools, and contributor guidelines

## Read-Only Paths

AI agents should treat the following paths as read-only unless explicitly instructed to modify them for specific maintenance or update tasks. Modifying these files without careful consideration can break core project workflows or documentation standards.

- `docs-dev/guides/**/*`
- `docs-dev/workflow-instructions/**/*`
- `docs-dev/tools/_binstubs/**/*`
- `docs-dev/guides/initialize-project-templates/**/*`
- `docs-project/decisions/**/*` (Modify only when adding or updating ADRs)
- `docs-project/done/**/*` (Completed tasks should not be modified)
- `lib/**/*` (Treat the core gem implementation as stable unless working on a specific feature or bug fix requiring changes here)
- `spec/**/*` (Treat tests as read-only unless writing new tests or fixing broken ones related to code changes)
- `.gitignore` (Modify carefully when adding/removing ignored patterns)
- `Gemfile.lock` (Manage dependencies via `bundle add`/`remove` or explicit instruction)
- `bin/*` (Modify only when updating binstub templates or adding new project-specific scripts)
- `*.lock` # Dependency lock files (e.g., Gemfile.lock)
- `dist/**/*` # Built artifacts
- `build/**/*` # Build output
- `pkg/**/*` # Gem packages

## Ignored Paths

AI agents should generally ignore the contents of the following paths during tasks such as searching for tasks, summarizing project state, or performing code analysis, unless the task explicitly requires interacting with these directories (e.g., cleaning build artifacts). These paths often contain transient data, dependencies, or build artifacts.

- `docs-project/done/**/*` # Completed tasks (already read-only, but explicitly ignored for general tasks)
- `vendor/**/*` (Bundler dependencies)
- `tmp/**/*`
- `log/**/*`
- `.git/**/*`
- `.bundle/**/*`
- `coverage/**/*` (Test coverage reports)
- `node_modules/**/*` (If applicable for frontend/tooling)
- `.idea/**/*`, `.vscode/**/*` (Editor specific configurations)
- `**/.*.swp`, `**/.*.swo` (Swap files)
- `/.DS_Store` (macOS system files)
- `**/Thumbs.db` (Windows system files)
- `**/.env` # Environment files
- `**/.env.*` # Environment variants
- `*.session.log`
- `*.lock`
- `*.tmp`
- `*~` # Backup files

## Entry Points

### Development

```bash
# Run the test suite
bin/test

# Run code quality checks
bin/lint

# Build the gem
bin/build
```
*(Note: `bin/run` might be used for specific entry points if defined)*

### Common Workflows

- **Find Next Task**: Use `bin/tn` to identify the next unblocked task to work on.
- **Summarize Recent Work**: Use `bin/tr` to see recently completed or updated tasks.
- **Commit Changes**: Use `bin/git-commit-with-message` to stage changes and generate a commit message.
- **Query LLM**: Use `exe/llm-gemini-query` or `bin/lms-studio-query` to interact with language models.
- **Generate Documentation Review**: Use `bin/cr-docs` to create comprehensive documentation update prompts from code diffs.

Refer to the [Architecture document](./architecture.md#command-line-tools-bin) for a more detailed list and description of `bin/` commands.

## Dependencies

### Runtime Dependencies

- **Ruby** (>= 3.2)
- **Bundler** - Dependency management
- **faraday** - Flexible HTTP client library.
- **zeitwerk** - Efficient and thread-safe code loader.
- **dry-monitor** - Event-based monitoring and instrumentation toolkit.
- **dry-configurable** - Provides configuration capabilities for Ruby objects.
- **addressable** - URI manipulation library.

### Development Dependencies

- **RSpec** - Testing framework.
- **RuboCop / StandardRB** - Code style linter and formatter.
- **VCR** - Records and replays HTTP interactions for tests.
- **WebMock** - Stubs and sets expectations on HTTP requests.
- `docs-dev/tools/*` scripts (used by some `bin/` wrappers).

See `coding_agent_tools.gemspec` and `Gemfile` for complete dependency specifications.

## Submodules

### docs-dev

- Path: `docs-dev`
- Repository: [Repository URL - assumed external]
- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
- **Important**: Commits for this submodule must be made from within the submodule directory (`../../docs-dev`).

---

*This blueprint serves as a quick reference and guide for automated agents. It should be updated if the project structure, key technologies, or operational guidelines change significantly.*
```
- ### docs-project/what-do-we-build.md
```markdown
# Coding Agent Tools Ruby Gem

## What We Build 🔍

The **Coding Agent Tools (CAT)** project provides a Ruby gem and associated command-line interface (CLI) tools designed to streamline development workflows for both human developers and autonomous AI coding agents. Its core purpose is to enable seamless interaction with local projects, Git repositories, and task backlogs by offering a predictable and standardized set of commands and a programmable API. By automating routine Dev Ops tasks like querying LLMs, generating commit messages, creating repositories, and navigating task queues, CAT frees up developers and agents to concentrate on higher-value design and coding activities.

## ✨ Key Features

- **LLM Communication**: Implemented CLI commands (`llm-gemini-query`, `lms-studio-query`) for interacting with Google Gemini and local LM Studio models.
- **Git Workflow Automation**: Tools for creating GitHub repositories (`github-repository-create`) and generating intelligent Git commit messages based on diffs and intentions (`git-commit-with-message`).
- **Task Management Utilities**: Commands (`tn`, `tr`, `rc`) to help developers and agents identify the next actionable task, review recent tasks, and manage release directories, often integrating with documentation-based task backlogs.
- **Standardized Interface**: Provides a consistent CLI and API surface for automation, reducing reliance on ad-hoc scripts.
- **Offline Support**: Enables querying local language models via LM Studio.

## Core Design Principles

- **ATOM Architecture**: Structured around the Action, Transformation, Operation, and Model pattern for maintainability, testability, and clear separation of concerns.
- **Test-Driven Development**: High emphasis on testing with a goal of 100% unit and integration test coverage using RSpec.
- **Predictable CLI**: Designing commands with ergonomic flags suitable for both human and agent interaction.
- **Modularity**: Components are designed with explicit boundaries and dependency injection.
- **Ruby Best Practices**: Adhering to standard Ruby conventions and practices.

## Target Use Cases

### Primary Use Cases

- **Automated Development Workflows**: AI coding agents using CAT commands to perform tasks like committing code, querying models, or finding the next work item within CI/CD pipelines or local development environments.
- **Accelerated Project Setup**: Developers quickly initializing Git repositories and setting up remotes with standardized commands.
- **Streamlined Commit Process**: Developers generating informative and consistent commit messages automatically based on their code changes and intent.
- **Efficient Task Navigation**: Developers and agents easily identifying and tracking development tasks within a structured documentation system.

### Secondary Use Cases

- **Offline AI Interaction**: Developers and agents interacting with local language models via LM Studio for rapid iteration or sensitive tasks.
- **Integrating with Documentation**: Utilizing CAT commands to manage task backlogs defined within documentation files.

## User Personas

### Primary Users

**Alex – AI Coding Agent**: An automated system designed to perform coding tasks.
- Needs: A deterministic and stable CLI surface to reliably execute development and operations steps.
- Goals: Successfully complete assigned coding and Dev Ops tasks without manual intervention.
- Pain Points: Brittle and inconsistent ad-hoc shell scripts that cause workflow failures.

**Sam – Senior Dev**: An experienced software engineer focused on efficient development.
- Needs: Rapidly set up new project remotes, easily craft descriptive and atomic commits.
- Goals: Reduce time spent on routine Git and project setup chores; maintain a clean and traceable commit history.
- Pain Points: Forgetting push URLs for new repositories, struggling to write clear and concise commit messages for complex changes.

### Secondary Users

**Priya – DX Engineer**: An engineer focused on improving the developer experience.
- Context: Priya uses CAT as a foundation for building standardized, testable, and extendable developer tools and workflows within their organization. They need a framework that follows Ruby best practices and is easy to integrate and extend.

## Success Metrics

### Primary Metrics
- **Time-to-Commit**: Reduce median time from code change to committed diff by **30%** within the pilot team (Target: ≤ 70% of original time).
- **Agent Adoption**: ≥ **80%** of automated CI runs invoke at least one CAT command.

### Secondary Metrics
- **Support Load**: ≤ **2** support tickets per week related to Git setup or task selection after 1 month post-launch.
- **Reliability**: CLI commands succeed ≥ **99%** over 1,000 automated invocations in testing/monitoring.

## Technology Philosophy

### Core Technology Choices
- **Primary Language**: Ruby - Chosen for its expressiveness, developer productivity, and suitability for scripting and tooling development.
- **Runtime**: MRI (C Ruby) ≥ 3.2 - Standard and widely adopted Ruby implementation.

### Technical Principles
- **ATOM Architecture**: Guiding principle for structuring the codebase into distinct, testable layers.
- **Focus on CLI/API**: Prioritizing a stable and well-documented interface for programmatic and human use.
- **External Dependency Management**: Explicitly managing dependencies and aiming for minimal, well-vetted external libraries.

## Project Boundaries

### What We Build
- A Ruby gem (`coding_agent_tools`) installable via standard Ruby package managers (RubyGems, Bundler).
- A suite of CLI executables (`bin/`) for common Dev Ops and task management workflows, including `exe/llm-gemini-query`.
- Core ATOM components, including:
  - **Atoms**: `EnvReader`, `HTTPClient`, `JSONFormatter`
  - **Molecules**: `APICredentials`, `HTTPRequestBuilder`, `APIResponseParser`
  - **Organisms**: `GeminiClient`, `PromptProcessor`
- An internal API used by the CLI, which can potentially be exposed for programmatic use.
- Integrations with Google Gemini API and local LM Studio API.
- Integrations with Git CLI and GitHub REST API (v3).
- Tools to interact with documentation-based task backlogs (e.g., in `docs-project`).
- Comprehensive unit and integration tests.
- Documentation (`docs-project/`) detailing usage and architecture.

### What We Don't Build (v1)
- SDKs or libraries in languages other than Ruby.
- A full-featured graphical user interface (GUI) for Git or task management.
- Direct integrations with proprietary LLM endpoints other than those specified (e.g., direct OpenAI calls within the gem, although wrappers could be built by users).
- Real-time collaborative editing features.
- A complete replacement for robust ticketing systems (Jira, Asana, etc.), but rather a tool to interact with backlog information potentially stored elsewhere or locally in docs.

## Value Proposition

### Problems We Solve
1. **Inconsistent Automation**: Replaces ad-hoc, project-specific scripts with a standardized, testable, and maintainable toolkit.
2. **Agent Orchestration Gap**: Provides coding agents with reliable, deterministic tools to perform common development and Dev Ops tasks they currently struggle with.
3. **Dev Ops Overhead**: Automates routine tasks like repository creation and commit message generation, reducing manual effort for developers.

### Unique Advantages
- **AI-Native Design**: Built specifically with the needs of AI coding agents in mind, offering a robust and predictable interface.
- **Documentation-Driven**: Designed to integrate with documentation-based workflows and task management.
- **Opinionated but Extendable**: Provides strong conventions while allowing for customization and extension of specific tools and workflows.
- **Offline Capability**: Supports interaction with local LLMs for enhanced privacy and speed.

## Future Vision

### Short-term Goals (Complete by ~Aug 2025 - v1.0.0)
- Finalize and release GitHub repository creation and commit generator tools.
- Implement and stabilize task utility commands (`tn`, `tr`, `rc`).
- Reach ≥ 95% test coverage.
- Publish stable v1.0.0 to RubyGems.

### Medium-term Goals (6-12 months post-v1)
- Gather user feedback and prioritize feature requests.
- Explore integrations with other LLM providers (if needed and not proprietary).
- Enhance task management features, potentially integrating with external systems.
- Improve performance and scalability.

### Long-term Vision (1+ years)
- Become a standard tool in AI-assisted Ruby development workflows.
- Potentially explore mechanisms for cross-language support (e.g., via a shared core or well-defined API boundaries).
- Expand the suite of automated Dev Ops and development tasks supported.

## Dependencies and Ecosystem

### Key Dependencies
- **Ruby ≥ 3.2**: The required runtime environment.
- **Google Gemini API**: Required for online LLM interactions.
- **LM Studio**: Required for local, offline LLM interactions.
- **Git CLI**: Fundamental command-line tool interacted with by the gem.
- **GitHub REST API (v3)**: Used for repository creation.
- **`docs-dev/tools/*` scripts**: Utility scripts assumed to be present in the `docs-dev` submodule for certain operations (like task utilities).

### Ecosystem Integration
- **Git/GitHub**: Deep integration for repository management and commit workflows.
- **Task Backlogs (Docs-based)**: Designed to work with tasks defined in documentation files (`docs-project/`).
- **CI/CD Pipelines**: Intended to be invoked as part of automated workflows.
- **AI Coding Agents**: Primary users and integrators of the tools.

## Submodules

### docs-dev
- Path: `docs-dev`
- Repository: [Repository URL - assumed external]
- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
- **Important**: Commits for this submodule must be made from within the submodule directory.

---

*This document should be updated as the project evolves and new insights are gained about user needs and project direction.*
```

#### Architecture Decision Records (ADRs)
Location: `docs-project/decisions/` and `docs-project/current/*/decisions/*.md`
Current files:
- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-001-CI-Aware-VCR-Configuration.md
```markdown
# ADR-001: CI-Aware VCR Configuration for Integration Tests

## Status

Accepted
Date: 2025-06-07

## Context

The project needed a robust solution for testing the `llm-gemini-query` command's integration with the Google Gemini API. The challenge was to create tests that:

1. **Run consistently** across development and CI environments
2. **Don't require API keys in CI** to avoid security risks and external dependencies
3. **Automatically record new interactions** during development without manual intervention
4. **Maintain simplicity** and use standard Ruby testing patterns
5. **Prevent accidental API costs** from test runs in CI

Initial approaches considered custom test runners and complex environment management, but these added unnecessary complexity and deviated from standard Ruby/RSpec patterns.

The key insight was that VCR already provides powerful configuration options that could be leveraged with minimal custom code.

## Decision

We implemented a CI-aware VCR configuration using VCR's built-in recording mode options with environment-based switching:

```ruby
# CI-aware recording mode
recording_mode = if ENV['CI']
                   :none  # Never record in CI
                 else
                   case ENV['VCR_RECORD']
                   when 'true', '1', 'all'
                     :all
                   when 'new_episodes', 'new'
                     :new_episodes  
                   when 'none', 'false', '0'
                     :none
                   else
                     :once  # Auto-record missing cassettes in development
                   end
                 end

config.default_cassette_options[:record] = recording_mode
```

This configuration automatically:
- **In CI environments** (`ENV['CI']` is set): Uses `:none` mode - only replays existing cassettes, never makes API calls
- **In development**: Uses `:once` mode by default - automatically records missing cassettes, replays existing ones
- **Provides overrides**: Allows explicit control via `VCR_RECORD` environment variable when needed

The solution uses standard `bin/test` command (wrapper around `bundle exec rspec`) with environment variables for control, eliminating the need for custom tooling.

## Consequences

### Positive

- **Zero Configuration**: Works out of the box for developers and CI
- **Standard Ruby Patterns**: Uses familiar `bin/test` commands and RSpec conventions
- **Automatic CI Detection**: No manual configuration needed across different CI platforms
- **Developer Friendly**: Missing cassettes are recorded automatically during development
- **Security**: No API keys required in CI, automatic sensitive data filtering
- **Fast CI Builds**: No external API calls means faster, more reliable test runs
- **Cost Control**: Prevents accidental API usage in CI environments
- **Maintainable**: Any Ruby developer can understand and modify the configuration

### Negative

- **Initial Recording Requires API Key**: Developers need a real API key to record new cassettes (though this is unavoidable)
- **Cassette Maintenance**: Cassettes need to be updated when API responses change (though this provides value by catching API changes)

### Neutral

- **Cassettes in Repository**: VCR cassettes are committed to version control, increasing repository size slightly but providing test reliability
- **Environment Variable Dependency**: Relies on CI platforms setting `ENV['CI']` (which is standard practice)

## Alternatives Considered

### Custom Test Runner Script
- **Why rejected**: Added unnecessary complexity and deviated from standard Ruby patterns
- **Trade-offs**: Would have provided more fine-grained control but at the cost of maintainability and developer experience

### Manual VCR Mode Switching
- **Why rejected**: Required developers to remember to set different modes for different scenarios
- **Trade-offs**: Would have been simpler to implement but error-prone and poor developer experience

### Always Recording in Development
- **Why rejected**: Would make unnecessary API calls and potentially hit rate limits
- **Trade-offs**: Would have been simpler but wasteful of API quota and slower test runs

### Separate Test Suites for CI vs Development
- **Why rejected**: Would create maintenance overhead and potential for CI/development drift
- **Trade-offs**: Might have been cleaner separation but would duplicate test maintenance

## Related Decisions

- Integration test strategy for `llm-gemini-query` command
- API key management and security practices
- Test automation and CI/CD pipeline design

## References

- [VCR Documentation - Recording Modes](https://relishapp.com/vcr/vcr/docs/record-modes)
- [VCR GitHub Repository](https://github.com/vcr/vcr)
- [Ruby CI Environment Detection Patterns](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables)
- [Google Gemini API Documentation](https://ai.google.dev/api/rest)
```
- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-002-Zeitwerk-for-Autoloading.md
```markdown
# ADR-002: Zeitwerk for Autoloading

## Status

Accepted
Date: 2025-06-08

## Context

The project's codebase, initially small, relied on manual `require` statements or simple `require_relative` patterns for loading classes and modules. As the project grew in complexity and size, this manual approach became increasingly cumbersome, prone to errors (e.g., forgotten `require` statements, circular dependencies), and difficult to maintain. There was a clear need for a more robust, standardized, and automated autoloading mechanism to improve developer experience, reduce boilerplate, and align with modern Ruby and Rails development practices.

## Decision

We decided to adopt Zeitwerk as the primary autoloading mechanism for the project. Zeitwerk, known for its performance and strict adherence to file naming conventions, provides an efficient and convention-over-configuration solution for autoloading.

The specific implementation includes:
- Configuring Zeitwerk to manage the project's autoload paths.
- Utilizing Zeitwerk's inflector configuration to handle acronym-based class names (e.g., `CLI`, `HTTP`, `API`) correctly, ensuring that `CLI` is autoloaded from `cli.rb` and not `c_l_i.rb`.

```ruby
# Example (conceptual) Zeitwerk configuration
# This would typically be set up in a central initialization file.
loader = Zeitwerk::Loader.new
loader.push_dir("lib") # Assuming 'lib' is the root of our autoloadable code
loader.inflector.inflect(
  "CLI" => "CLI",
  "HTTP" => "HTTP",
  "API" => "API"
)
loader.setup
```

## Consequences

### Positive

- **Standardized Autoloading**: Provides a consistent and reliable way to load classes and modules without explicit `require` statements.
- **Rails/Ruby Community Alignment**: Adopting Zeitwerk aligns the project with common practices in the Ruby and Rails ecosystems, making it easier for developers familiar with these environments to contribute.
- **Improved Developer Experience**: Developers no longer need to manually manage `require` paths, leading to faster development cycles and fewer "missing constant" errors.
- **Performance**: Zeitwerk is highly optimized for performance, loading only what's needed, when it's needed.
- **Reduced Boilerplate**: Eliminates the need for numerous `require` statements, making files cleaner and more focused on business logic.

### Negative

- **Strict File Naming Conventions**: Requires strict adherence to Zeitwerk's file naming conventions (e.g., `MyModule::MyClass` must be in `my_module/my_class.rb`). While beneficial for consistency, it can be a learning curve for new contributors or require refactoring existing files.
- **Initial Setup Complexity**: Requires careful initial setup and configuration to ensure all autoload paths are correctly defined and inflections are handled.
- **Debugging Autoloading Issues**: While rare, issues related to incorrect file naming or path configuration can sometimes be tricky to debug.

### Neutral

- **Explicit Inflector Configuration**: The need to explicitly configure inflections for acronyms adds a small amount of initial setup, but this is a one-time cost for significant benefit.

## Alternatives Considered

### Manual Autoloading / Extensive `require_relative` Usage

- **Why rejected**: Becomes unmanageable and error-prone in larger codebases. Leads to fragmented `require` statements spread across many files.
- **Trade-offs**: Simple for very small projects, but scales poorly and hinders maintainability.

### Other Autoloading Gems (e.g., `ActiveSupport::Dependencies`)

- **Why rejected**: `ActiveSupport::Dependencies` is largely superseded by Zeitwerk in modern Rails and Ruby applications, and Zeitwerk is designed to be a standalone component.
- **Trade-offs**: Might offer similar functionality but Zeitwerk is the current standard and offers better performance and explicit design for autoloading.

## Related Decisions

- Project structure and directory layout
- Code style and convention guidelines

## References

- [Zeitwerk GitHub Repository](https://github.com/fxn/zeitwerk)
- [Zeitwerk Documentation](https://github.com/fxn/zeitwerk#zeitwerk)
```
- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-003-Observability-with-dry-monitor.md
```markdown
# ADR-003: Observability with dry-monitor

## Status

Accepted
Date: 2025-06-08

## Context

As the project grew in complexity, the need for better observability into key operations and internal events became critical for debugging, performance monitoring, and understanding system behavior. Without a standardized mechanism for event publishing and subscription, introducing new logging, metrics, or tracing capabilities would require intrusive modifications across various parts of the codebase. We needed a decoupled approach where components could publish events without knowing their subscribers, and subscribers could react to events without knowing their publishers.

## Decision

We decided to implement observability using `dry-monitor` via a central `Notifications` instance. This approach leverages `dry-monitor`'s publish/subscribe pattern to allow different parts of the application to emit events, which can then be consumed by various monitors (e.g., loggers, metrics collectors, debuggers).

A specific integration includes:
- A central `Notifications` instance, acting as the global event bus.
- Integration with `FaradayDryMonitorLogger` (or a similar custom logger adapter) to capture HTTP request/response events from the Faraday HTTP client. This ensures that all outgoing HTTP calls are automatically instrumented and logged through the `dry-monitor` system.

```ruby
# Example (conceptual) dry-monitor setup
# This would typically be initialized globally, e.g., in `config/initializers/monitor.rb`
# or injected into components that need to publish/subscribe.

require 'dry/monitor/notifications'
require 'faraday/dry_monitor_logger' # Assuming this gem/class exists or is custom-defined

module MyProject
  module Core
    class Notifications < Dry::Monitor::Notifications
      # Custom event definitions or additional setup can go here
    end

    # Global notifications instance
    NOTIFICATION_BUS = Notifications.new(:my_project)
  end
end

# Example of how Faraday might be configured to use the dry-monitor logger
# This would typically be part of the Faraday connection setup
# conn = Faraday.new(...) do |f|
#   f.use FaradayDryMonitorLogger, notifications: MyProject::Core::NOTIFICATION_BUS
#   # ... other middleware
# end

# Example of subscribing to an event
# MyProject::Core::NOTIFICATION_BUS.subscribe('http.request.finished') do |event|
#   # Log, metric, or trace the event
#   puts "HTTP Request finished: #{event.payload[:url]} in #{event.payload[:duration]}ms"
# end
```

## Consequences

### Positive

- **Standardized Event Publishing**: Provides a consistent and decoupled way for different parts of the application to emit events without direct dependencies on logging, metrics, or tracing systems.
- **Enhanced Observability**: Enables easy integration of various monitoring tools (logging, metrics, tracing) by simply subscribing to relevant events on the central `Notifications` instance.
- **Improved Debugging**: Critical events can be easily logged or inspected during development and production, aiding in diagnosing issues.
- **Testability**: Components that publish events can be tested in isolation, and monitors can be mocked or swapped out easily during testing.
- **Extensibility**: New monitoring requirements (e.g., adding a new metric provider) can be met by adding new subscribers without modifying existing business logic.

### Negative

- **Adds Dependencies**: Introduces `dry-monitor` and potentially related gems (like `FaradayDryMonitorLogger`) as new project dependencies.
- **Learning Curve**: New contributors may need to understand the `dry-monitor` concepts and the publish/subscribe pattern.
- **Potential for Event Overload**: Without careful design, too many events or overly verbose events could lead to performance overhead or noisy logs/metrics.
- **Event Definition Management**: Requires discipline in defining and documenting event names and their payloads to ensure consistency and usability.

### Neutral

- **Centralized `Notifications` Instance**: While beneficial for global reach, it means the `Notifications` instance needs to be accessible where events are published, potentially via dependency injection or a global singleton.

## Alternatives Considered

### Custom Logger / Direct Logging Calls

- **Why rejected**: Leads to tight coupling between business logic and logging implementation. Extending to metrics or tracing would require pervasive changes.
- **Trade-offs**: Simpler for very basic logging needs, but does not scale for comprehensive observability or multiple monitoring concerns.

### Other Monitoring Libraries (e.g., `ActiveSupport::Notifications`, `Prometheus Client for Ruby`)

- **Why rejected**: `ActiveSupport::Notifications` is tied to Rails and might be overkill or bring unnecessary dependencies for a non-Rails project. Direct Prometheus client integration would be too specific to metrics and not generic enough for general event publishing for debugging or logging.
- **Trade-offs**: `ActiveSupport::Notifications` is a viable alternative for Rails projects. Direct metric libraries are good for metrics-only concerns but less flexible for a broader observability strategy.

## Related Decisions

- HTTP client strategy (ADR-005) due to `FaradayDryMonitorLogger` integration.
- Error reporting strategy (ADR-004) for consistency in handling exceptions, although `dry-monitor` focuses on events.

## References

- [dry-monitor GitHub Repository](https://github.com/dry-rb/dry-monitor)
- [dry-rb ecosystem documentation](https://dry-rb.org/)
- `FaradayDryMonitorLogger` (conceptual/custom component, refers to the idea of an adapter for Faraday)
```
- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-004-Centralized-CLI-Error-Reporting.md
```markdown
# ADR-004: Centralized CLI Error Reporting Strategy

## Status

Accepted
Date: 2025-06-08

## Context

Command-Line Interface (CLI) executables often produce various error messages, ranging from user input validation failures to unexpected system errors. Without a unified approach, each executable might handle and display errors differently, leading to an inconsistent and confusing user experience. Furthermore, debugging CLI applications becomes challenging if error output is not standardized or if critical debug information is not readily available when needed. There was a clear need to centralize error handling to ensure consistency, improve user guidance, and provide robust debugging capabilities via a debug flag.

## Decision

We decided to implement a `ErrorReporter` module or class responsible for centralizing CLI error reporting. This module will provide a consistent interface for handling exceptions and displaying error messages to the user.

Key aspects of this decision include:
- A dedicated `ErrorReporter` module/class to encapsulate error formatting and output logic.
- Support for a debug flag (e.g., `--debug` or `DEBUG=true` environment variable) that, when enabled, provides more verbose error information, such as backtraces, for diagnostic purposes.
- Standardized error message formats for different types of errors (e.g., validation errors, configuration errors, internal errors).
- Integration into CLI executables to ensure all errors are routed through this central mechanism.

```ruby
# Example (conceptual) ErrorReporter module
module MyProject
  module CLI
    module ErrorReporter
      DEBUG_MODE = ENV['DEBUG'] == 'true' || ARGV.include?('--debug')

      def self.report(exception, message: nil, exit_code: 1)
        STDERR.puts "Error: #{message || exception.message}"
        if DEBUG_MODE
          STDERR.puts "Type: #{exception.class}"
          STDERR.puts "Backtrace:\n\t#{exception.backtrace.join("\n\t")}" if exception.backtrace
        end
        exit(exit_code) unless exception.is_a?(SystemExit) # Prevent SystemExit from being wrapped
      end

      # Example usage within a CLI executable
      # begin
      #   # CLI logic here
      # rescue StandardError => e
      #   ErrorReporter.report(e, message: "An unexpected error occurred.")
      # end
    end
  end
end
```

## Consequences

### Positive

- **Consistent User Experience**: All CLI executables will present error messages in a predictable and uniform way, reducing user confusion.
- **Simplified Error Handling**: Developers can use a single, well-defined mechanism to handle and report errors across the entire suite of CLI tools, reducing boilerplate and potential for inconsistencies.
- **Enhanced Debugging**: The debug flag provides immediate access to detailed error information (like backtraces) directly in the terminal, significantly aiding in troubleshooting.
- **Improved Maintainability**: Changes to error reporting logic (e.g., message formatting, logging integration) can be made in one central place, affecting all executables.
- **Clear Separation of Concerns**: Isolates error reporting logic from core application logic.

### Negative

- **Initial Setup Overhead**: Requires implementing and integrating the `ErrorReporter` module into all relevant CLI executables.
- **Potential for Over-reporting**: Without careful design, the debug mode might produce excessively verbose output that is difficult to parse.
- **Dependency**: Introduces a new internal dependency (the `ErrorReporter` module) that all CLI tools must adhere to.

### Neutral

- **Explicit Debug Flag**: Relies on users or developers to explicitly enable debug mode, which is standard practice for verbose output.

## Alternatives Considered

### Individual Executable Error Handling

- **Why rejected**: Leads to inconsistent error messages, duplicated code, and makes it difficult to apply global changes to error reporting. Debugging would be fragmented and manual.
- **Trade-offs**: Simpler for a single, very small executable, but becomes unmanageable and error-prone as the number of executables or complexity grows.

### Using a Generic Logging Library

- **Why rejected**: While logging libraries can capture errors, they typically don't provide the structured, user-friendly CLI output format desired, nor do they inherently handle the debug flag for interactive CLI use as directly as a dedicated error reporter.
- **Trade-offs**: Good for backend logging, but less tailored for immediate, actionable CLI user feedback and interactive debugging. Would still require custom formatting logic.

### Raising and Rescuing `SystemExit` for all errors

- **Why rejected**: While `SystemExit` is good for controlling application exit, using it for all error types can obscure the original exception context and make it harder to differentiate between different error conditions programmatically. It's typically used for intentional exits.
- **Trade-offs**: Very simple way to terminate execution but loses valuable error metadata and can be misleading about the true nature of the error.

## Related Decisions

- Observability strategy (ADR-003) for broader system events and metrics.
- CLI argument parsing strategy, as it relates to the `--debug` flag.

## References

- Ruby's `StandardError` and `SystemExit` classes
- Command-line interface design best practices
```
- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-005-HTTP-Client-Strategy-with-Faraday.md
```markdown
# ADR-005: HTTP Client Strategy with Faraday

## Status

Accepted
Date: 2025-06-08

## Context

The project frequently interacts with external APIs, requiring a robust, flexible, and maintainable HTTP client. Without a standardized approach, different parts of the application might use various HTTP libraries or custom implementations, leading to inconsistent behavior, duplicated effort, and difficulty in applying global configurations (e.g., timeouts, retries, authentication, logging). There was a clear need to adopt a single, well-established HTTP client library that could be configured consistently across all API interactions, ensuring reliability, testability, and ease of development.

## Decision

We decided to standardize on Faraday as the primary HTTP client for all external API interactions. Faraday provides a flexible middleware architecture that allows for easy composition of various HTTP client functionalities (e.g., request/response logging, error handling, retries, caching, authentication).

The implementation strategy involves:
- Using Faraday as the underlying HTTP client library.
- Introducing an `HTTPClient` "atom" (a low-level component or class) that encapsulates the basic Faraday connection setup and configuration. This atom will handle default middleware, connection options, and potentially base URLs.
- Introducing an `HTTPRequestBuilder` "molecule" (a higher-level component or class) that builds upon the `HTTPClient` to construct specific API requests. This molecule will abstract away common request patterns, headers, and payload formatting, providing a consistent interface for different API calls.

```ruby
# Example (conceptual) Faraday HTTPClient atom
require 'faraday'
require 'faraday/retry' # Example for a common middleware

module MyProject
  module HTTP
    class Client
      def initialize(base_url:, notifications: nil)
        @base_url = base_url
        @notifications = notifications # Optional: for dry-monitor integration
        @connection = build_connection
      end

      def connection
        @connection
      end

      private

      def build_connection
        Faraday.new(url: @base_url) do |f|
          f.request :json # Example: Encode request body as JSON
          f.response :json # Example: Decode response body as JSON
          f.response :raise_error # Raise exceptions for 4xx/5xx responses
          f.use Faraday::Retry::Middleware # Example: Automatic retries
          # f.use FaradayDryMonitorLogger, notifications: @notifications if @notifications # Integration with ADR-003
          f.adapter Faraday.default_adapter # The default adapter (e.g., Net::HTTP)
        end
      end
    end

    # Example (conceptual) HTTPRequestBuilder molecule
    class RequestBuilder
      def initialize(http_client:)
        @http_client = http_client.connection
      end

      def get(path, params: {}, headers: {})
        @http_client.get(path, params, headers)
      end

      def post(path, body: {}, headers: {})
        @http_client.post(path, body, headers)
      end

      # ... other HTTP methods
    end
  end
end

# Example usage
# client = MyProject::HTTP::Client.new(base_url: 'https://api.example.com')
# builder = MyProject::HTTP::RequestBuilder.new(http_client: client)
# response = builder.get('/users/123')
# puts response.body
```

## Consequences

### Positive

- **Consistent HTTP Handling**: All external API calls will be made using a unified client, ensuring consistent behavior, error handling, and configuration across the application.
- **Faraday Ecosystem Access**: Leverages the rich ecosystem of Faraday middleware, allowing for easy integration of features like logging, caching, retries, authentication, and more.
- **Improved Testability**: HTTP interactions can be easily mocked or stubbed using libraries compatible with Faraday (e.g., WebMock, VCR), simplifying integration tests.
- **Clear Separation of Concerns**: The `HTTPClient` and `HTTPRequestBuilder` components provide a clean architectural separation, making the code more modular and understandable.
- **Reduced Duplication**: Avoids writing custom HTTP client logic repeatedly for different API calls.

### Negative

- **New Dependency**: Introduces `faraday` and potentially other `faraday` ecosystem gems as new project dependencies, increasing the gem footprint.
- **Configuration Overhead**: Requires initial setup and configuration of Faraday, including choosing and arranging middleware, which can be a learning curve for new developers.
- **Abstraction Layer**: Adds a layer of abstraction (`HTTPClient`, `HTTPRequestBuilder`) which, while beneficial, means developers interact with Faraday indirectly rather than directly.

### Neutral

- **Middleware Complexity**: The power of Faraday's middleware can also introduce complexity if not managed carefully, requiring clear documentation of the middleware stack.

## Alternatives Considered

### `Net::HTTP` Directly

- **Why rejected**: `Net::HTTP` is Ruby's built-in HTTP client but is low-level and lacks many features (e.g., automatic retries, request/response logging, middleware) that are crucial for modern API interactions. Implementing these features directly would involve significant boilerplate and custom code.
- **Trade-offs**: No external dependencies. Very simple for basic, one-off requests. Becomes unwieldy for complex scenarios.

### Other HTTP Client Gems (e.g., `HTTParty`, `RestClient`, `Excon`)

- **Why rejected**: While many good HTTP client gems exist, Faraday was chosen for its strong middleware architecture, making it highly extensible and composable. Some alternatives might be simpler for basic use cases but lack the flexibility and ecosystem of Faraday for complex, enterprise-grade applications.
- **Trade-offs**: Each gem has its own strengths and weaknesses. Some might be simpler for quick prototypes, while others might offer specific features (e.g., performance, specific protocol support). Faraday's extensibility was the decisive factor.

## Related Decisions

- Observability strategy (ADR-003) for integrating `FaradayDryMonitorLogger` and instrumenting HTTP calls.
- CI-Aware VCR configuration (ADR-001) for robust testing of HTTP interactions without relying on external services in CI.

## References

- [Faraday GitHub Repository](https://github.com/lostisland/faraday)
- [Faraday Documentation](https://lostisland.github.io/faraday/)
- `HTTPClient` and `HTTPRequestBuilder` patterns (conceptual, from a component-based design perspective)
```

#### Root Documentation
Location: `*.md` files in project root
Current files:
### CHANGELOG.md
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

#### v.0.2.0+task.4 - 2025-06-14 - Add Model Override Flag Support

### Added
- **Model Override Flags**: Complete implementation of `--model` flag support for both Gemini and LM Studio query commands
  - Model parameter validation and error handling through APIs
  - Help text documentation with usage examples
- **Model Listing Commands**: New CLI commands for discovering available models
  - `llm-gemini-models` command with fuzzy search filtering (text/JSON output)
  - `llm-lmstudio-models` command with fuzzy search filtering (text/JSON output)
  - Updated CLI registration to include models commands
- **Updated Model Lists**: Accurate model names aligned with v1beta API
  - Gemini models: gemini-2.0-flash-lite (default), gemini-2.0-flash, gemini-2.5-flash-preview-05-20, gemini-2.5-pro-preview-06-05, gemini-1.5-flash, gemini-1.5-flash-8b, gemini-1.5-pro
  - LM Studio models: mistralai/devstral-small-2505 (default), deepseek/deepseek-r1-0528-qwen3-8b, and others
- **Enhanced Testing**: 
  - Unit tests for model listing commands with comprehensive filter testing
  - Integration test updates with valid model override scenarios
  - Fixed test model names to use v1beta compatible models

### Changed
- Updated Gemini model list to reflect actual v1beta API availability
- Improved integration tests to use valid model names (gemini-1.5-flash for Gemini tests)
- Enhanced error handling consistency across commands

#### v.0.2.0+task.3 - 2025-06-14 - Implement LM Studio Query Command

### Added
- **LM Studio Integration**: Complete implementation of `llm-lmstudio-query` command for offline LLM inference
  - `LMStudioClient` organism with HTTP REST integration to localhost:1234
  - CLI command with argument parsing for prompts and file input
  - Server health check and connection validation
  - Comprehensive error handling for server unavailable scenarios
  - Default model support (mistralai/devstral-small-2505) with configurability
- **Testing Infrastructure**:
  - Unit tests with mock server scenarios for LMStudioClient
  - Integration tests using Aruba + VCR pattern
  - VCR cassettes for LM Studio API interactions
  - Test coverage for various prompt types and edge cases
- **CLI Infrastructure**:
  - LMS command registration in CLI system
  - Executable script `exe/llm-lmstudio-query`
  - Proper Zeitwerk inflection for LMStudioClient

### Changed
- **Module Loading**: Updated Zeitwerk inflector configuration to include `lm_studio_client`
- **CLI Registration**: Extended CLI system to register LMS commands alongside existing LLM commands
- **VCR Configuration**: Enhanced VCR setup to handle localhost connections for LM Studio testing

## [v.0.2.0+tasks.5 - task.16] - CLI Integration Testing, Documentation Updates, and Code Quality Fixes

### Added
- **CLI Integration Testing**: Implemented Aruba for robust CLI integration testing.
- **Documentation**:
  - Comprehensive Gemini Query Guide.
  - Updated README with Gemini integration features and improved development documentation structure.
  - Updated project overview, architecture, and blueprint documentation.
  - Architectural Decision Records (ADR-002, ADR-003, ADR-004, ADR-005) for key architectural decisions (Zeitwerk autoloading, dry-monitor observability, centralized CLI error reporting, Faraday HTTP client strategy).
  - `binstup` for documentation review prompt tool.
- **Code Quality & Testing Enhancements**:
  - Custom RSpec matchers for HTTP and JSON assertions.
  - Process helpers and shared helpers for integration tests.
  - Centralized `ErrorReporter` for consistent error handling.
  - `dry-monitor` integration for observability, including Faraday middleware events.
  - Gem installation verification to the `bin/build` script.

### Changed
- **Build Process**: Restored `bin/test` and `bin/lint` steps to the `bin/build` script.
- **Test Execution**: Replaced `bin/test` commands with manual verification steps in some documentation.
- **Refactoring**: Refactored code quality improvements including removal of `ActiveSupport` and `ENV.fetch` for API keys.

### Fixed
- **Dependency Management**: Fixed Ruby 3.4 CI Bundler setup issues causing `dry-cli` loading failures.
- **Autoloading**:
  - Fixed module autoloading configuration issues (e.g., missing module definition files).
  - Added `http_request_builder` inflection for Zeitwerk.
  - Removed legacy `autoload` statements.
- **HTTP Client & API Interaction**:
  - Fixed Gemini Client API response handling issues and ensured `raw_body` field is restored.
  - Preserved `v1beta` path in Gemini client `model_info` URL.
  - Fixed HTTP client method signature issues (`build_headers`).
  - Improved Faraday middleware integration (event registration, tests, error handling in middleware).
  - Fixed Content-Type header on GET requests.
  - Handled array values in query parameters.
  - Addressed header duplication, URL concatenation, and Windows path quoting issues.
  - Fixed JSON parsing to correctly handle different response scenarios.
- **Testing**:
  - Fixed integration test configuration issues (dependency loading, URL construction bug, environment setup).
  - Fixed critical syntax error in HTTP Request Builder spec (`malformed describe block`).
  - Fixed HTTP client test signatures to use keyword arguments.
  - Fixed code quality test failures.
  - Fixed VCR subprocess setup in integration tests.
- **Code Quality & Review**:
  - Addressed various code review feedback issues (e.g., `.DS_Store` files, event registration, performance optimizations in `JSONFormatter` and `HTTPRequestBuilder`, simplified error handling, direct class references, guard for empty candidates, HTTP status in error messages, JSON sanitization, blank string handling for API keys).
  - Removed unused `debug_enabled` parameter.
  - Fixed task numbers in documentation files.

## [0.2.0+tasks.1] - 2025-06-08

### Added
- **LLM Integration Framework**: Complete implementation of Google Gemini AI integration
  - `llm-gemini-query` command-line tool for querying Google Gemini API (gemini-2.0-flash-lite model)
  - Support for prompt input from string arguments or file paths
  - Explicit output formatting with `--format` flag (text or json)
  - Debug mode with `--debug` flag for verbose error output
  - Environment variable support for API key configuration (.env file)
- **ATOM Architecture Components**:
  - **Atoms**: HTTPClient, JSONFormatter, EnvReader for core functionality
  - **Molecules**: APICredentials, HTTPRequestBuilder, APIResponseParser for composed behavior
  - **Organisms**: GeminiClient, PromptProcessor for high-level AI operations
- **HTTP Client Integration**: Faraday HTTP client for reliable API communication
- **Comprehensive Testing Suite**:
  - Unit tests for all ATOM components with >95% code coverage
  - Integration tests with live API using VCR for CI-friendly testing
  - CI-aware VCR configuration for automated testing environments
- **Developer Experience**:
  - `.env.example` template for API key configuration
  - Detailed documentation for testing with VCR
  - Examples and refactoring guides for API credentials

### Changed
- Enhanced CLI framework to support LLM command namespace
- Updated gemspec to include Faraday dependency
- Improved error handling with graceful API failure management

## [0.1.0] - 2025-06-06

### Added
- Initial Ruby gem structure with ATOM architecture (atoms, molecules, organisms, ecosystems)
- CLI framework using dry-cli with version command
- Comprehensive build system with bin/build, bin/test, bin/lint scripts
- RSpec testing framework with SimpleCov coverage reporting
- StandardRB linting configuration
- GitHub Actions CI/CD pipeline with multi-Ruby version testing (3.2, 3.3, 3.4)
- Development guides and contribution documentation
- Git workflow with commit message templates and PR templates

### Changed
- Established semantic versioning starting with v0.1.0
- Updated project documentation structure with docs/ directory

#### Project Foundation (v0.0.0 - Development Phase)
- Created the initial project roadmap and defined initial release structure
- Consolidated ideas into Product Requirements Document with context hydration, git aliases, markdown tasks, task capture, and UX features
- Added architectural research and documentation fixes including ATOM architecture research
- Established initial project structure including placeholder scripts in `bin/` and core documentation in `docs-project/`
- Added the `docs-dev` submodule and initial `.gitignore` file

[0.2.0]: https://github.com/your-org/coding-agent-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/your-org/coding-agent-tools/releases/tag/v0.1.0
```

### README.md
```markdown
# Coding Agent Tools (CAT) Ruby Gem

[![CI](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/coding_agent_tools.svg)](https://badge.fury.io/rb/coding_agent_tools)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Ruby gem providing CLI tools designed for AI coding agents and developers to streamline development workflows through predictable, standardized commands.

## 🚀 Quick Start

### Installation

**1. Install as a published gem (once available):**

```bash
gem install coding_agent_tools
```

**2. Or, for local development/use from source:**

Add this line to your application's Gemfile if you are using it as a dependency from a local path (e.g., as a submodule or a local copy):
```ruby
gem 'coding_agent_tools', path: '.'
```
Then execute:
```bash
bundle install
```
Or, if you are working directly within this cloned repository:
```bash
bundle install
```

After installation (either globally or via Bundler in a project), the `coding_agent_tools` command will be available.

## ✨ Key Features

- **LLM Integration**: Query Google Gemini and local LM Studio models
  - **Google Gemini LLM Integration**: Direct integration with Google's Gemini API via `exe/llm-gemini-query`
- **Git Automation**: Create repositories, generate commit messages with AI
- **Task Management**: Navigate documentation-based task backlogs
- **Context Tools**: Generate comprehensive project context documents
- **Offline Support**: Work with local language models via LM Studio

## 🛠 Core Commands (Planned Structure)

The primary executable for the gem is `coding_agent_tools`. Here's a look at the planned command structure (specific commands and options are illustrative and will be implemented in future tasks):

```bash
# General
coding_agent_tools --version
coding_agent_tools --help
coding_agent_tools help <command>

# LLM Communication
coding_agent_tools llm query --provider gemini --prompt "How to optimize Ruby performance?"
coding_agent_tools llm query --provider lm_studio --prompt "Explain SOLID principles"

# Source Control Management (SCM)
coding_agent_tools scm repository create --provider github my-new-repo
coding_agent_tools scm commit_with_message --intention "Refactor user authentication"
coding_agent_tools scm log --oneline

# Task Management
coding_agent_tools task next
coding_agent_tools task list --recent
coding_agent_tools task new_id

# Project Utilities
coding_agent_tools project release_context
# For development tasks related to the gem itself:
# coding_agent_tools project test (or bundle exec rspec)
# coding_agent_tools project lint (or bundle exec standardrb)
# coding_agent_tools project build_gem (or gem build coding_agent_tools.gemspec)
```

*Note: The existing `bin/*` scripts will be gradually replaced or wrapped by these new gem commands.*

## 🔧 Available Standalone Commands

### New Standalone Commands

- **`exe/llm-gemini-query`**: Directly query the Google Gemini API
  - Usage: `exe/llm-gemini-query "Your prompt" [--file] [--format json|text] [--model MODEL_NAME] [--temperature TEMP] [--max-tokens TOKENS] [--system "SYSTEM_PROMPT"] [--debug]`
  - Example: `exe/llm-gemini-query "What is Ruby?"`
  - Requires: `GEMINI_API_KEY` environment variable

## 🏗 Architecture

The gem's library code in `lib/coding_agent_tools/` is structured using an **ATOM-based hierarchy** (Atoms, Molecules, Organisms, Ecosystems), promoting modularity and reusability:

- **`lib/coding_agent_tools/atoms/`**: Smallest, indivisible utility functions or classes.
- **`lib/coding_agent_tools/molecules/`**: Simple compositions of Atoms forming reusable operations.
- **`lib/coding_agent_tools/organisms/`**: More complex units performing specific business logic or features.
- **`lib/coding_agent_tools/ecosystems/`**: The largest units, representing complete subsystems (the CLI app itself is an ecosystem).
- **`lib/coding_agent_tools/models/`**: Data structures (POROs) used across layers.
- **`lib/coding_agent_tools/cli/`**: Contains `dry-cli` command classes.
- **`lib/coding_agent_tools/cli.rb`**: Main `dry-cli` registry.

### Core Dependencies

- **Faraday**: HTTP client for API integrations (Google Gemini)
- **dry-cli**: Command-line interface framework

See the [Architecture Document](docs-project/architecture.md) for more details.

## 🔧 Configuration

### API Keys

Create a `.env` file in your project root (copy from `.env.example`):

```bash
# Google Gemini API Key
# Get this from: https://makersuite.google.com/app/apikey
GEMINI_API_KEY=your_actual_gemini_api_key_here

# GitHub (for repository creation)
GITHUB_TOKEN=your-token
```

Or set environment variables directly:

```bash
# Google Gemini
export GEMINI_API_KEY="your-api-key"

# GitHub (for repository creation)
export GITHUB_TOKEN="your-token"
```

### LM Studio
Ensure LM Studio is running on `localhost:1234` for offline LLM queries.

## 📋 Requirements

- Ruby ≥ 3.4.2
- Git CLI
- Optional: LM Studio for offline LLM support

## 🎯 Use Cases

### For AI Agents
- Deterministic CLI interface for automation
- Reliable Git and task management operations
- Structured JSON output with `--json` flag

### For Developers
- Rapid repository setup and configuration
- AI-generated commit messages based on diffs
- Streamlined task navigation in documentation-driven workflows

## 🚧 Development Status

Currently in active development (v0.1.0 focusing on establishing the gem structure). See [roadmap](docs-project/roadmap.md) for planned releases.

## 💻 Development

For complete development information including environment setup, testing, build tools, and contribution workflow, see **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**.

### Quick Start for Contributors

```bash
# Clone and setup
git clone <repository-url>
cd coding-agent-tools
bin/setup

# Run tests and linting
bin/test && bin/lint

# Start developing
git checkout -b feature/your-feature
```

### Key Development Resources

- **[Development Guide](docs/DEVELOPMENT.md)** - Complete development workflow and tools
- **[Setup Guide](docs/SETUP.md)** - Environment setup instructions  
- **[Contributing](.github/CONTRIBUTING.md)** - Contribution guidelines and standards

## 📚 Documentation

### User Documentation
- **[Setup Guide](docs/SETUP.md)** - Development environment setup
- **[Development Guide](docs/DEVELOPMENT.md)** - Workflow and best practices
- **[Contributing](.github/CONTRIBUTING.md)** - How to contribute

### Project Documentation
- [Architecture](docs-project/architecture.md) - System design and patterns
- [Project Vision](docs-project/what-do-we-build.md) - Goals and use cases
- [Development Guides](docs-dev/guides/) - Internal standards and processes

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details on:

- Setting up your development environment
- Code style and quality standards
- Testing requirements and practices
- Pull request process and guidelines
- Commit message conventions

This project follows documentation-driven development with structured task management in `docs-project/`. See the [project blueprint](docs-project/blueprint.md) for navigation guidance.

### Quick Contribution Workflow

1. Fork the repository and clone your fork
2. Set up development environment: `bin/setup`
3. Create a feature branch: `git checkout -b feature/name`
4. Make your changes following our standards
5. Test your changes: `bin/test && bin/lint`
6. Commit with conventional format and push
7. Open a pull request using our template

## 📄 License

[MIT License](LICENSE)
```

#### Gem Configuration
Location: `Gemfile` and `*.gemspec`
Current content:
### Gemfile
```ruby
# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in coding_agent_tools.gemspec
gemspec

group :development, :test do
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"
  gem "standard", "~> 1.3" # standardrb is provided by this gem
  gem "pry"
  gem "bundler-audit"
  gem "gem-release"
  gem "simplecov", "~> 0.22", require: false
  gem "simplecov-html", "~> 0.12", require: false
  gem "webmock", "~> 3.0"
  gem "vcr", "~> 6.0"
  gem "aruba", "~> 2.0"
end
```

### coding_agent_tools.gemspec
```ruby
# frozen_string_literal: true

require_relative "lib/coding_agent_tools/version"

Gem::Specification.new do |spec|
  spec.name = "coding_agent_tools"
  spec.version = CodingAgentTools::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["opensource@cs3b.com"]

  spec.summary = "A Ruby gem providing CLI tools for AI agents and developers to streamline development workflows."
  spec.description = "The Coding Agent Tools (CAT) gem offers CLI tools for AI agents and developers to automate and standardize development tasks, including LLM interaction, Git operations, and task management."
  spec.homepage = "https://github.com/your-org/coding-agent-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/your-org/coding-agent-tools"
  spec.metadata["changelog_uri"] = "https://github.com/your-org/coding-agent-tools/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "dotenv", "~> 2.0"
  spec.add_dependency "dry-cli"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "zeitwerk", "~> 2.6"
  spec.add_dependency "dry-monitor", "~> 1.0"
  spec.add_dependency "dry-configurable", "~> 1.0" # dry-monitor typically depends on this
  spec.add_dependency "addressable", "~> 2.8"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
```

### Current Project State

#### Test Coverage
Current coverage: 91.37% (974/1066 lines, 27 files)
Target coverage: 90%

#### StandardRB Status
Current offenses: No offenses detected

#### Gem Dependencies
Current dependencies:
- rake ~> 13.0 (development)
- rspec ~> 3.0 (development)
- standard ~> 1.3 (development)
- pry any (development)
- bundler-audit any (development)
- gem-release any (development)
- simplecov ~> 0.22 (development)
- simplecov-html ~> 0.12 (development)
- webmock ~> 3.0 (development)
- vcr ~> 6.0 (development)
- aruba ~> 2.0 (development)

## Your Comprehensive Code Review Task

### Phase 1: Architectural Compliance Analysis

Analyze how the changes align with ATOM architecture:

**1. Atom-Level Components**
- Are new atoms truly atomic and reusable?
- Do atoms have single, clear responsibilities?
- Are atoms properly isolated with no external dependencies?

**2. Molecule-Level Composition**
- Do molecules properly compose atoms?
- Is the composition logic clear and testable?
- Are molecules focused on orchestration rather than implementation?

**3. Organism-Level Integration**
- Do organisms properly coordinate molecules?
- Is business logic appropriately placed?
- Are organisms maintaining proper boundaries?

**4. Ecosystem-Level Patterns**
- Does the change maintain ecosystem cohesion?
- Are cross-cutting concerns properly addressed?
- Is the plugin/extension architecture respected?

### Phase 2: Ruby Gem Best Practices Review

**1. Code Quality & Style**
- [ ] Follows Ruby idioms and conventions
- [ ] StandardRB compliance (or justified exceptions)
- [ ] Consistent naming conventions
- [ ] Proper use of Ruby language features
- [ ] No code smells or anti-patterns

**2. Gem Structure**
- [ ] Proper file organization following gem conventions
- [ ] Correct use of lib/ directory structure
- [ ] Appropriate version management
- [ ] Gemspec file correctness

**3. Dependencies**
- [ ] Minimal dependency footprint
- [ ] Version constraints appropriately specified
- [ ] No unnecessary runtime dependencies
- [ ] Development dependencies properly scoped

**4. Performance Considerations**
- [ ] No obvious performance bottlenecks
- [ ] Efficient algorithms and data structures
- [ ] Proper use of lazy evaluation where appropriate
- [ ] Memory usage considerations

### Phase 3: Test Quality Assessment

**1. Test Coverage**
- Is every new method/class adequately tested?
- Are edge cases covered?
- Are error conditions tested?
- Is the happy path thoroughly tested?

**2. Test Design**
- [ ] Tests follow RSpec best practices
- [ ] Clear test descriptions using RSpec DSL
- [ ] Proper use of contexts and examples
- [ ] DRY principles in test code
- [ ] Fast, isolated unit tests

**3. Test Types**
- [ ] Unit tests for atoms
- [ ] Integration tests for molecules
- [ ] System tests for organisms
- [ ] CLI tests for command-line interface

**4. Test Quality Metrics**
- [ ] Tests are deterministic (no flaky tests)
- [ ] Tests are independent and can run in any order
- [ ] Tests use appropriate doubles/mocks/stubs
- [ ] Tests verify behavior, not implementation

### Phase 4: CLI Design Review

**1. Command Structure**
- [ ] Commands follow Unix philosophy
- [ ] Clear, intuitive command naming
- [ ] Consistent flag/option patterns
- [ ] Proper use of subcommands

**2. User Experience**
- [ ] Helpful error messages
- [ ] Appropriate output formatting
- [ ] Progress indicators for long operations
- [ ] Proper exit codes

**3. AI Agent Compatibility**
- [ ] Machine-parseable output options
- [ ] Structured error reporting
- [ ] Predictable behavior
- [ ] Clear documentation of all options

**4. Help Documentation**
- [ ] Comprehensive --help output
- [ ] Examples in help text
- [ ] Clear option descriptions
- [ ] Version information available

### Phase 5: Security & Safety Analysis

**1. Input Validation**
- All user inputs properly validated?
- SQL injection prevention (if applicable)?
- Command injection prevention?
- Path traversal prevention?

**2. Data Handling**
- Sensitive data properly protected?
- Appropriate use of ENV variables?
- No hardcoded credentials?
- Secure defaults?

**3. Dependencies Security**
- Known vulnerabilities in dependencies?
- Unnecessary permission requirements?
- Appropriate gem signing/verification?

### Phase 6: API Design & Maintainability

**1. Public API Surface**
- [ ] Clear separation of public/private APIs
- [ ] Consistent method signatures
- [ ] Appropriate use of keyword arguments
- [ ] Future-proof design patterns

**2. Error Handling**
- [ ] Custom exceptions where appropriate
- [ ] Informative error messages
- [ ] Proper error propagation
- [ ] Graceful degradation

**3. Code Maintainability**
- [ ] Self-documenting code
- [ ] Appropriate code comments
- [ ] YARD documentation for public APIs
- [ ] Reasonable method/class sizes

**4. Backward Compatibility**
- [ ] Breaking changes properly identified
- [ ] Deprecation warnings added
- [ ] Migration path provided
- [ ] Semantic versioning respected

### Phase 7: Detailed Code Analysis

For each significant code change:

#### [File: path/to/file.rb]

**Code Quality Issues:**
- Issue: [Description]
  - Severity: [Critical/High/Medium/Low]
  - Location: [Line numbers]
  - Suggestion: [How to fix]
  - Example: [Code example if helpful]

**Best Practice Violations:**
- Violation: [Description]
  - Impact: [Why this matters]
  - Recommendation: [Better approach]

**Refactoring Opportunities:**
- Opportunity: [Description]
  - Current approach: [What's there now]
  - Suggested approach: [Better way]
  - Benefits: [Why change it]

### Phase 8: Prioritized Action Items

## 🔴 CRITICAL ISSUES (Must fix before merge)
*Security vulnerabilities, data corruption risks, or breaking changes*
- [ ] [Specific issue with file:line and fix description]

## 🟡 HIGH PRIORITY (Should fix before merge)
*Significant bugs, performance issues, or design flaws*
- [ ] [Specific issue with file:line and fix description]

## 🟢 MEDIUM PRIORITY (Consider fixing)
*Code quality, maintainability, or minor bugs*
- [ ] [Specific issue with file:line and fix description]

## 🔵 SUGGESTIONS (Nice to have)
*Style improvements, refactoring opportunities*
- [ ] [Specific issue with file:line and fix description]

### Phase 9: Positive Feedback

**Well-Done Aspects:**
- [What was done particularly well]
- [Good patterns that should be replicated]
- [Clever solutions worth highlighting]

**Learning Opportunities:**
- [Interesting techniques used]
- [Patterns that could benefit the team]

## Expected Output Format

Structure your comprehensive review as:

```markdown
# Code Review Analysis

## Executive Summary
[2-3 sentences summarizing the overall quality and key concerns]

## Architectural Compliance Assessment
### ATOM Pattern Adherence
[Analysis of how well changes follow ATOM architecture]

### Identified Violations
[List any architectural anti-patterns found]

## Ruby Gem Best Practices
### Strengths
[What was done well according to Ruby standards]

### Areas for Improvement
[What could be more idiomatic or better structured]

## Test Quality Analysis
### Coverage Impact
[How changes affect test coverage]

### Test Design Issues
[Problems with test structure or approach]

### Missing Test Scenarios
[What scenarios need additional testing]

## Security Assessment
### Vulnerabilities Found
[Any security issues discovered]

### Recommendations
[How to address security concerns]

## API Design Review
### Public API Changes
[Impact on gem's public interface]

### Breaking Changes
[Any backward compatibility issues]

## Detailed Code Feedback
[File-by-file analysis using Phase 7 format]

## Prioritized Action Items
[Use 4-tier priority system from Phase 8]

## Performance Considerations
[Any performance impacts or opportunities]

## Refactoring Recommendations
[Larger structural improvements to consider]

## Positive Highlights
[What was done exceptionally well]

## Risk Assessment
[Potential risks if changes are merged as-is]

## Approval Recommendation
[ ] ✅ Approve as-is
[ ] ✅ Approve with minor changes
[ ] ⚠️  Request changes (non-blocking)
[ ] ❌ Request changes (blocking)

### Justification
[Clear reasoning for the recommendation]
```

## Review Checklist

Before completing your review, ensure you've considered:

**Code Quality**
- [ ] All new code follows Ruby idioms
- [ ] No obvious bugs or logic errors
- [ ] Appropriate error handling
- [ ] Clear variable and method names

**Architecture**
- [ ] ATOM pattern properly followed
- [ ] Proper separation of concerns
- [ ] No circular dependencies
- [ ] Clear module boundaries

**Testing**
- [ ] All new code has tests
- [ ] Tests are meaningful and thorough
- [ ] No decrease in coverage
- [ ] Tests follow RSpec conventions

**Documentation**
- [ ] Public APIs documented
- [ ] Complex logic explained
- [ ] CHANGELOG entry needed?
- [ ] README updates needed?

**Performance**
- [ ] No obvious bottlenecks
- [ ] Appropriate algorithm choices
- [ ] Resource usage considered
- [ ] Scalability implications addressed

**Security**
- [ ] Input validation present
- [ ] No security vulnerabilities
- [ ] Secrets handled properly
- [ ] Dependencies are safe

## Critical Success Factors

Your review must be:
1. **Constructive**: Focus on improvement, not criticism
2. **Specific**: Provide exact locations and examples
3. **Actionable**: Every issue should have a suggested fix
4. **Educational**: Help the author learn and grow
5. **Balanced**: Acknowledge both strengths and weaknesses

Begin your comprehensive code review analysis now.
