# AI Agent Task: Comprehensive Diff-Based Documentation Review

You are an expert technical documentation analyst and software architect. Your task is to review the provided code diff and create a comprehensive plan to update ALL related documentation, ensuring perfect consistency between implementation and documentation.

## Context: Project Information

This project follows:
- **ATOM architecture** pattern (Atoms, Molecules, Organisms, Ecosystems)
- **Test-driven development** with RSpec
- **CLI-first design** for both humans and AI agents
- **Documentation-driven development** approach
- **Semantic versioning** with clear changelog practices

## Input Data

### 1. Code Diff to Review
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
diff --git a/README.md b/README.md
index a655dd1..d7f0c59 100644
--- a/README.md
+++ b/README.md
@@ -130,7 +130,7 @@ export GITHUB_TOKEN="your-token"
 ```
 
 ### LM Studio
-Ensure LM Studio is running on `localhost:1234` for offline LLM queries.
+Ensure LM Studio is running on `localhost:1234` for offline LLM queries. No API credentials required for localhost usage.
 
 ## 📋 Requirements
 
diff --git a/bin/cr b/bin/cr
new file mode 100755
index 0000000..0f07c15
--- /dev/null
+++ b/bin/cr
@@ -0,0 +1,30 @@
+#!/usr/bin/env bash
+# frozen_string_literal: true
+
+# Code Review Prompt Generator
+# Wrapper script for generating comprehensive code review prompts from diffs
+
+set -euo pipefail
+
+# Get the directory of this script
+SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
+
+# Path to the actual tool
+TOOL_PATH="$PROJECT_ROOT/docs-dev/tools/generate-code-review-prompt"
+
+# Check if the tool exists
+if [[ ! -f "$TOOL_PATH" ]]; then
+    echo "Error: Code review prompt generator not found at $TOOL_PATH"
+    echo "Make sure the docs-dev submodule is properly initialized."
+    exit 1
+fi
+
+# Check if the tool is executable
+if [[ ! -x "$TOOL_PATH" ]]; then
+    echo "Making code review prompt generator executable..."
+    chmod +x "$TOOL_PATH"
+fi
+
+# Pass all arguments to the actual tool
+exec "$TOOL_PATH" "$@"
diff --git a/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-combined.md b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-combined.md
new file mode 100644
index 0000000..d1e1106
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-combined.md
@@ -0,0 +1,380 @@
+# Combined Code Review Analysis
+
+## Executive Summary
+
+This comprehensive code review combines insights from three independent analyses (Gemini 2.5 Pro, OpenAI O3, and Sonnet 3.7) of the model override flags and LM Studio query commands implementation. The consensus across all reviews is that this is a high-quality implementation that demonstrates excellent adherence to ATOM architecture principles, Ruby best practices, and comprehensive testing standards.
+
+**Key Strengths:**
+- Excellent ATOM architecture compliance with proper separation of concerns
+- Comprehensive test coverage including unit tests, integration tests, and edge cases
+- Robust error handling and defensive programming practices
+- Consistent CLI design and user experience
+- Well-designed new data model (should be `Models::LlmModelInfo`) and `LMStudioClient` organism
+
+**Primary Concerns:**
+- Code duplication in executable wrapper scripts (`exe/*`)
+- CI fragility due to localhost probes in integration tests
+- Unnecessary `APICredentials` usage in `LMStudioClient` for localhost scenarios
+- Minor opportunities for refactoring and consolidation
+
+All reviews recommend **approval with minor changes**, indicating the implementation is production-ready with some maintenance improvements recommended.
+
+## Architectural Compliance Assessment
+
+### ATOM Pattern Adherence
+**Consensus:** All three reviews confirm excellent ATOM architecture compliance.
+
+- **Atoms**: Existing atoms properly reused, no new atoms needed
+- **Molecules**: ~~New `Model` molecule is well-designed as a pure data object with clear responsibilities~~ **CORRECTION**: Should be reclassified as `Models::LlmModelInfo` per house rules
+- **Organisms**: `LMStudioClient` properly orchestrates molecules and encapsulates business logic
+- **Ecosystem**: CLI commands seamlessly integrated using established `dry-cli` patterns
+
+### Identified Violations
+**Minor violations identified:**
+1. **LMStudioClient APICredentials usage** (All reviews) - Forces credential lookup for localhost scenarios where authentication isn't needed
+2. **Executable wrapper duplication** (All reviews) - Copy-pasted logic instead of shared components
+3. **Model classification** (User feedback) - Current `Model` molecule should be reclassified as `Models::LlmModelInfo` per house rules
+
+## Ruby Gem Best Practices
+
+### Strengths
+**Consistently highlighted across all reviews:**
+- Idiomatic Ruby with keyword arguments and proper naming conventions
+- Strong error handling with informative messages
+- Excellent use of Ruby OOP features and encapsulation
+- Proper gem structure and Zeitwerk integration
+- StandardRB compliance maintained
+
+### Areas for Improvement
+**Common recommendations:**
+- Extract duplicate wrapper logic to reduce maintenance overhead
+- Remove unnecessary `APICredentials` dependency in `LMStudioClient`
+- Consider extracting hardcoded values (roles, model formatting) as constants
+- Simplify nested conditionals in error handling where possible
+
+## Test Quality Analysis
+
+### Coverage Impact
+**All reviews confirm comprehensive test coverage:**
+- Unit tests for all new classes and CLI commands
+- Integration tests using Aruba and VCR
+- Edge case handling (server unavailability, invalid models, special characters)
+- Coverage maintains >90% target threshold
+
+### Test Design Issues
+**Critical issue identified (OpenAI O3):**
+- **CI Fragility**: Integration specs probe `http://localhost:1234/v1/models` before VCR wrapping, causing failures in CI environments with WebMock
+- **Recommendation**: Use VCR-wrapped probes or WebMock-allowed hosts configuration
+
+### Missing Test Scenarios
+**Identified gaps:**
+- Executable wrapper output rewriting logic testing
+- ANSI color preservation verification in `StringIO` capture
+- Error path testing in `LMStudioClient.handle_error`
+- Empty result set handling in model filtering
+
+## Security Assessment
+
+### Vulnerabilities Found
+**Consensus:** No security vulnerabilities identified across all reviews.
+
+### Recommendations
+- Continue proper API key handling through environment variables
+- Consider adding timeout parameters to prevent hanging requests
+- Validate model names from user input to prevent unexpected behavior
+- Localhost HTTP assumptions are acceptable for LM Studio use case
+
+## API Design Review
+
+### Public API Changes
+**Well-designed additions:**
+- `llm-gemini-models` and `llm-lmstudio-models` commands for model listing
+- `llm-lmstudio-query` command for local model querying
+- `--model` flag support on query commands
+- New `LMStudioClient` organism and data model (should be `Models::LlmModelInfo`)
+
+### Breaking Changes
+**All reviews confirm:** No breaking changes - implementation is purely additive.
+
+## User Feedback Integration
+
+### Model Classification Correction
+
+**Issue Identified**: The current `Model` molecule violates the established house rules for component classification.
+
+**House Rules Violation**:
+- **Current**: `lib/coding_agent_tools/molecules/model.rb` (Molecules::Model)
+- **Should be**: `lib/coding_agent_tools/models/llm_model_info.rb` (Models::LlmModelInfo)
+
+**Reasoning**:
+- Pure data carrier with attributes + trivial helpers, no outside IO → belongs in Models/
+- Molecules should be "behavior-oriented helpers that compose atoms to perform work"
+- The current Model class is an immutable data structure, not a behavioral component
+
+**Suggested Implementation**:
+```ruby
+# lib/coding_agent_tools/models/llm_model_info.rb
+module CodingAgentTools
+  module Models
+    # Value object describing an LLM that CAT can talk to
+    # This is intentionally immutable; create a new instance for changes.
+    LlmModelInfo = Struct.new(
+      :provider,        # :gemini, :openai, :local etc.
+      :name,            # "gemini-1.5-pro", "gpt-4o-mini"…
+      :context_window,  # tokens
+      :max_tokens,      # tokens
+      :temperature,     # default temp
+      :cost_per_1k,     # optional billing info
+      keyword_init: true
+    ) do
+      # Optional convenience helpers are fine
+      def chat_capable?
+        provider != :openai || name.start_with?("gpt")
+      end
+    end
+  end
+end
+```
+
+**Migration Steps**:
+1. Move the file to `lib/coding_agent_tools/models/`
+2. Update any require paths (`require 'coding_agent_tools/models/llm_model_info'`)
+3. Adjust namespaces in callers (`Models::LlmModelInfo.new(...)`)
+4. Zeitwerk will handle autoloading automatically
+
+**Benefits**:
+- Maintains clean mental model: "anything under models/ is a dumb data object"
+- Keeps Molecules action-oriented, preventing catch-all accumulation
+- Future-proofs for potential persistence layer (YAML/DB) without breaking API users
+- Follows established architectural patterns correctly
+
+## Detailed Code Feedback
+
+### File: `exe/llm-gemini-models`, `exe/llm-lmstudio-models`, `exe/llm-lmstudio-query`
+
+**Code Quality Issues (All Reviews):**
+- **Issue**: Significant code duplication across all three executables
+  - **Severity**: Medium (Gemini), Medium (O3), Medium (Sonnet)
+  - **Location**: Lines ~23-99 in each file
+  - **Consensus Solution**: Extract common wrapper logic into shared helper module
+
+**Proposed Refactoring (From Gemini Review):**
+```ruby
+# lib/coding_agent_tools/cli/executable_wrapper.rb
+module CodingAgentTools
+  module Cli
+    module ExecutableWrapper
+      def self.call(command_path:, subcommand_args:, program_name:)
+        # Centralized argument handling, output capture, and modification logic
+      end
+    end
+  end
+end
+```
+
+### File: `lib/coding_agent_tools/organisms/lm_studio_client.rb`
+
+**Code Quality Issues:**
+- **APICredentials Dependency** (All Reviews):
+  - **Issue**: Forces credential lookup for localhost scenarios
+  - **Severity**: Medium
+  - **Solution**: Make credential injection optional or remove entirely
+
+- **Complex Validation Logic** (Sonnet):
+  - **Issue**: Nested conditionals in `extract_generated_text`
+  - **Suggestion**: Use Ruby's `dig` method for cleaner validation
+  ```ruby
+  choice = data.dig(:choices, 0)
+  return error_message unless choice.is_a?(Hash)
+  ```
+
+- **Hardcoded Role Values** (Sonnet):
+  - **Issue**: String literals for "system" and "user" roles
+  - **Solution**: Define constants like `ROLE_SYSTEM = "system"`
+
+### File: `lib/coding_agent_tools/cli/commands/llm/models.rb` and `lms/models.rb`
+
+**Refactoring Opportunities:**
+- **Code Duplication** (All Reviews):
+  - **Issue**: Similar structure between LLM and LMS model commands
+  - **Solution**: Extract base class or shared module for common functionality
+
+- **Model Name Formatting** (Sonnet):
+  - **Current**: Case statements for word formatting
+  - **Suggested**: Hash-based mapping for flexibility
+  ```ruby
+  WORD_FORMATTING = {
+    "gemini" => "Gemini",
+    "flash" => "Flash"
+  }.freeze
+  ```
+
+### File: `lib/coding_agent_tools/organisms/gemini_client.rb`
+
+**Refactoring Opportunities (Gemini Review):**
+- **URL Construction**: Use `Addressable::URI#join` instead of manual path concatenation
+- **Benefits**: More idiomatic and robust URL handling
+
+## Prioritized Action Items
+
+### 🔴 CRITICAL ISSUES (Must fix before merge)
+**None identified** - All reviews agree no critical blocking issues exist.
+
+### 🟡 HIGH PRIORITY (Should fix before merge)
+
+1. **CI Fragility Fix** (OpenAI O3):
+   - **Issue**: Replace raw Net::HTTP probe in LMS integration specs
+   - **Solution**: Use VCR-wrapped probe or WebMock configuration
+   - **Impact**: Prevents CI test failures and coverage gaps
+
+2. **Executable Wrapper Refactoring** (All Reviews):
+   - **Issue**: Code duplication in `exe/*` scripts
+   - **Solution**: Extract shared wrapper logic to common module
+   - **Impact**: Improves maintainability and follows DRY principles
+
+### 🟢 MEDIUM PRIORITY (Consider fixing)
+
+1. **Model Classification Correction** (User Feedback):
+   - **File**: `lib/coding_agent_tools/molecules/model.rb`
+   - **Issue**: Current `Model` molecule is actually a pure data carrier, not a behavior-oriented helper
+   - **Solution**: Move to `lib/coding_agent_tools/models/llm_model_info.rb` as `Models::LlmModelInfo`
+   - **Migration Steps**:
+     - Move file to `lib/coding_agent_tools/models/`
+     - Update require paths and namespaces in callers
+     - Consider using `Struct` with keyword arguments for cleaner implementation
+
+2. **Remove APICredentials Dependency** (All Reviews):
+   - **File**: `lib/coding_agent_tools/organisms/lm_studio_client.rb`
+   - **Issue**: Unnecessary credential lookup for localhost scenarios
+   - **Solution**: Make credential injection optional or remove entirely
+
+3. **ANSI Color Verification** (Gemini):
+   - **Issue**: Confirm if `StringIO` strips ANSI colors from CLI output
+   - **Solution**: Test and document limitation or find alternative
+
+4. **Simplify Validation Logic** (Sonnet):
+   - **Issue**: Complex nested validation in `extract_generated_text`
+   - **Solution**: Use Ruby's `dig` method for cleaner code
+
+### 🔵 SUGGESTIONS (Nice to have)
+
+1. **Extract Common CLI Functionality** (Sonnet):
+   - **Issue**: Duplication between model listing commands
+   - **Solution**: Create shared base class or module
+
+2. **URL Construction Improvement** (Gemini):
+   - **Issue**: Manual URL path joining in `GeminiClient`
+   - **Solution**: Use `Addressable::URI#join` for cleaner code
+
+3. **Constant Extraction** (Sonnet):
+   - **Issue**: Hardcoded string values for roles and formatting
+   - **Solution**: Define constants for better maintainability
+
+4. **Fallback Model List Centralization** (Gemini):
+   - **Issue**: Hardcoded fallback lists in command classes
+   - **Solution**: Move to client organism constants
+
+## Performance Considerations
+
+**Consensus findings:**
+- Dynamic model listing API calls have minimal CLI impact with proper fallbacks
+- Efficient model filtering using simple string matching (appropriate for small lists)
+- Good default timeouts and error handling for network operations
+- 180-second timeout for `LMStudioClient` is generous but appropriate for local inference
+
+**Recommendations:**
+- Consider adding model list caching (TTL) to avoid repeated API hits
+- Provide streaming output option for long LMS completions
+- Monitor memory usage with large StringIO captures
+
+## Refactoring Recommendations
+
+**Primary Focus Areas:**
+1. **Executable Wrapper Consolidation**: Create shared template system for script generation
+2. **Base Command Classes**: Extract common functionality for model listing commands
+3. **Error Handling Patterns**: Create shared module for common error handling
+4. **URL Construction**: Standardize approach across all clients
+
+## Positive Highlights
+
+**Consistently praised across all reviews:**
+- **Excellent ATOM Architecture**: Proper separation of concerns and component composition
+- **Comprehensive Testing**: Thorough coverage including edge cases and integration scenarios
+- **Robust Error Handling**: Defensive programming with clear error messages
+- **Clean CLI Design**: Intuitive commands with useful features like filtering and multiple formats
+- **Well-Designed Components**: Data model (should be `Models::LlmModelInfo`) exemplifies clean, focused design
+- **Strong Documentation**: Detailed changelog and task documentation maintenance
+- **Dynamic Model Discovery**: Significant usability improvement with API fallbacks
+
+## Risk Assessment
+
+**All reviews indicate low implementation risk:**
+- Changes are primarily additive with no breaking changes
+- Comprehensive test coverage provides safety net
+- Clear separation of concerns minimizes impact radius
+- Main risk is maintenance overhead from code duplication (addressed by recommendations)
+
+## Contradiction Analysis
+
+**No significant contradictions found between reviews.** All three reviews:
+- Agree on architectural compliance and code quality
+- Identify similar issues with consistent severity assessments
+- Recommend similar solutions and improvements
+- Concur on approval with minor changes
+
+**Minor emphasis differences:**
+- OpenAI O3 places stronger emphasis on CI fragility fix
+- Sonnet provides more detailed refactoring suggestions
+- Gemini focuses more on URL construction improvements
+
+## Final Approval Recommendation
+
+**✅ APPROVE WITH MINOR CHANGES**
+
+### Justification
+
+All three independent reviews reach the same conclusion: this is a high-quality implementation that adds valuable functionality while maintaining architectural integrity and code standards. The identified issues are primarily maintenance-oriented improvements rather than functional defects.
+
+**Minimum changes recommended before merge:**
+1. Fix CI fragility in integration tests
+2. Extract executable wrapper duplication
+3. Correct Model classification to Models::LlmModelInfo per house rules
+
+**The implementation demonstrates:**
+- Strong architectural compliance with ATOM patterns
+- Comprehensive testing and error handling
+- Consistent CLI design and user experience
+- No security vulnerabilities or breaking changes
+- Clear benefit to users with dynamic model discovery
+
+The suggested improvements can be addressed either before merging or in subsequent iterations without impacting the core functionality or user experience.
+
+---
+
+## Summary - Individual Review Contributions
+
+### Gemini 2.5 Pro Review Contribution
+- **Structure**: Provided comprehensive framework with detailed prioritization system
+- **Focus Areas**: Executable wrapper duplication, URL construction patterns, task documentation alignment
+- **Unique Insights**: Specific refactoring code examples, ANSI color consideration, fallback model list centralization
+- **Strengths**: Detailed architectural analysis, specific code improvement suggestions
+
+### OpenAI O3 Review Contribution  
+- **Structure**: Concise technical analysis with clear risk assessment
+- **Focus Areas**: CI fragility, performance considerations, maintainability concerns
+- **Unique Insights**: WebMock configuration issues, memory usage considerations, streaming output suggestions
+- **Strengths**: Practical deployment concerns, specific CI/CD recommendations
+
+### Sonnet 3.7 Review Contribution
+- **Structure**: Thorough code-level analysis with specific refactoring examples
+- **Focus Areas**: Code quality improvements, method-level optimizations, constant extraction
+- **Unique Insights**: Ruby idiom improvements, detailed validation logic alternatives, hash-based mapping suggestions
+- **Strengths**: Deep code review with actionable improvement examples, Ruby best practices focus
+
+### User Feedback Contribution
+- **Structure**: Architectural governance and house rules enforcement
+- **Focus Areas**: Component classification correctness, ATOM pattern adherence
+- **Unique Insights**: Model vs Molecule distinction, proper data structure placement per established conventions
+- **Strengths**: Ensures consistency with project's architectural standards and maintainable patterns
+
+**Combined Value**: The three reviews complement each other excellently - Gemini provides architectural oversight, OpenAI focuses on operational concerns, and Sonnet delivers detailed code quality analysis. The user feedback adds crucial architectural governance, ensuring the implementation follows established house rules. Together they provide comprehensive coverage of all aspects from architecture to implementation details while maintaining project consistency.
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-gemini-2.5-pro.md b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-gemini-2.5-pro.md
new file mode 100644
index 0000000..6243a6e
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-gemini-2.5-pro.md
@@ -0,0 +1,242 @@
+# Code Review Analysis
+
+## Executive Summary
+This diff introduces significant new functionality related to model management for both Gemini and LM Studio LLMs, including model override flags for query commands and new commands for listing available models. The implementation largely adheres to the project's ATOM architecture and Ruby best practices. Testing is comprehensive, with new unit and integration tests. Key strengths include robust error handling in the `LMStudioClient`, dynamic model listing capabilities, and a consistent CLI experience. The main area for improvement is the duplicated and potentially fragile output manipulation logic in the new `exe/*` wrapper scripts.
+
+## Architectural Compliance Assessment
+### ATOM Pattern Adherence
+The changes align well with the ATOM architecture:
+-   **Atoms**: Existing atoms are leveraged effectively. No new core operational atoms are introduced, which is fine as existing ones are sufficient.
+-   **Molecules**:
+    -   `Molecules::Model` is a new data molecule that clearly defines the structure for AI model representation. It provides useful methods for display (`to_s`) and serialization (`to_json_hash`), fitting its role.
+    -   Existing molecules like `APICredentials`, `HTTPRequestBuilder`, and `APIResponseParser` are correctly composed by the new `LMStudioClient` organism.
+-   **Organisms**:
+    -   `Organisms::LMStudioClient` is a well-designed new organism. It encapsulates all logic for interacting with the LM Studio server, including health checks, text generation, and model listing. Its composition of molecules for credentials, request building, and response parsing is a good demonstration of the ATOM pattern. The error handling within this organism is notably robust.
+    -   `Organisms::GeminiClient` is appropriately extended with a `list_models` method, keeping API interaction logic within the organism.
+-   **Ecosystem**:
+    -   New CLI commands (`llm models`, `lms query`, `lms models`) are integrated into the existing `dry-cli` ecosystem under logical namespaces (`llm`, `lms`).
+    -   The `exe/*` scripts act as thin wrappers, delegating to the main CLI application, which is a good pattern for CLI-first design.
+
+### Identified Violations
+-   No major architectural violations were identified. The ATOM pattern is generally well respected.
+
+## Ruby Gem Best Practices
+### Strengths
+-   **Modularity**: New components are well-encapsulated and organized within the established directory structure.
+-   **Consistency**: New CLI commands and client classes follow patterns similar to existing ones, promoting consistency.
+-   **Zeitwerk Integration**: Proper inflection for `lm_studio_client` ensures correct autoloading.
+-   **Robustness**: Fallback mechanisms for model listing (using hardcoded lists if API calls fail) improve resilience.
+
+### Areas for Improvement
+-   **`exe/*` Script Logic**: The three new `exe` scripts (`llm-gemini-models`, `llm-lmstudio-models`, `llm-lmstudio-query`) share nearly identical logic for:
+    1.  Bundler/setup and load path management (this part is good).
+    2.  Prepending command arguments (e.g., `["llm", "models"]`).
+    3.  Capturing `stdout`/`stderr` using `StringIO`.
+    4.  Modifying help/error messages using `gsub` to display the direct executable name (e.g., `llm-gemini-models`) instead of the subcommand path (e.g., `... llm models`).
+    This duplication is not DRY and makes these wrappers harder to maintain. A shared helper module or a refinement in how `dry-cli` is invoked could centralize this logic.
+-   **ANSI Color Stripping**: The `exe/*` scripts note that `StringIO` might strip ANSI color codes. If colorized output from `dry-cli` (e.g., for help text or errors) is important, this could be a UX degradation. This needs verification and a potential alternative if colors are lost and desired.
+
+## Test Quality Analysis
+### Coverage Impact
+-   The changelog and new spec files indicate a strong focus on testing the new functionality. New unit tests are added for CLI command classes (`LLM::Models`, `LMS::Models`, `LMS::Query`) and the `LMStudioClient` organism.
+-   New integration tests (`llm_lmstudio_query_integration_spec.rb`) using Aruba and VCR for the `llm-lmstudio-query` command are excellent and follow best practices.
+-   Existing Gemini integration tests are updated.
+
+### Test Design Issues
+-   No major design issues apparent from the diff. The use of VCR for API interactions and Aruba for CLI testing is a robust approach.
+-   The `LMStudioClient` tests should thoroughly cover the detailed error checking logic in `extract_generated_text`.
+
+### Missing Test Scenarios
+-   It would be beneficial to have a test case specifically for the `exe/*` scripts' output rewriting logic to ensure it behaves as expected with various `dry-cli` outputs (e.g., different error messages, help screens for sub-subcommands if they arise).
+-   A test to confirm whether ANSI colors are preserved or stripped by the `StringIO` capture in `exe/*` scripts would be useful.
+
+## Security Assessment
+### Vulnerabilities Found
+-   No new security vulnerabilities are apparent in this diff.
+
+### Recommendations
+-   **API Key Handling**: Continue the current practice of using `APICredentials` and environment variables for API keys. Ensure LM Studio API keys (if they become a feature beyond localhost) are handled with similar care.
+-   **Input Validation**: The `PromptProcessor` handles prompt input. For model names coming from user input (`--model` flag), ensure validation occurs within the client or command layer to prevent unexpected behavior if invalid characters or overly long strings are passed, especially if these are used in constructing API request paths or bodies. The changelog mentions "Model parameter validation and error handling through APIs," which is good.
+
+## API Design Review
+### Public API Changes
+-   **CLI**: New commands `llm-gemini-models`, `llm-lmstudio-models`, `llm-lmstudio-query` and their associated flags (`--model`, `--filter`, `--format`, etc.) form the new public CLI API. This API is well-structured and consistent.
+-   **Ruby API**:
+    -   `Organisms::GeminiClient#list_models` is a new public method.
+    -   `Organisms::LMStudioClient` and its public methods (`server_available?`, `generate_text`, `list_models`, `model_info`) are new additions to the gem's internal API.
+    -   `Molecules::Model` provides a clear and useful data structure.
+
+### Breaking Changes
+-   The changes are additive, introducing new functionality. No breaking changes to existing public APIs were identified.
+
+## Detailed Code Feedback
+
+### File: `exe/llm-gemini-models`, `exe/llm-lmstudio-models`, `exe/llm-lmstudio-query`
+
+**Code Quality Issues:**
+-   **Issue**: Duplication of stdout/stderr capturing and output modification logic.
+    -   Severity: Medium
+    -   Location: Lines ~23-99 in each of these files.
+    -   Suggestion: Refactor this shared logic into a helper module (e.g., `CodingAgentTools::Cli::ExecutableHelper`) that can be included or called by these scripts. This helper could encapsulate the `Dry::CLI.new.call` invocation, output capturing, and string replacement.
+    -   Example (Conceptual Helper):
+        ```ruby
+        # lib/coding_agent_tools/cli/executable_wrapper.rb
+        module CodingAgentTools
+          module Cli
+            module ExecutableWrapper
+              def self.call(command_path:, subcommand_args:, program_name:)
+                original_stdout = $stdout
+                original_stderr = $stderr
+                # ... capture logic ...
+                modified_args = subcommand_args + ARGV.dup # ARGV will be modified by Dry::CLI
+                ARGV.clear
+                ARGV.concat(modified_args)
+
+                # Ensure commands are registered
+                case command_path # or a more generic registration mechanism
+                when "llm" then Commands.register_llm_commands
+                when "lms" then Commands.register_lms_commands
+                end
+
+                Dry::CLI.new(Commands).call
+                # ... output modification and printing logic ...
+              rescue SystemExit => e
+                # ... output modification for SystemExit ...
+                raise e
+              rescue => e
+                # ... ErrorReporter.call ...
+              ensure
+                # ... restore stdout/stderr ...
+              end
+            end
+          end
+        end
+
+        # In exe/llm-gemini-models:
+        # CodingAgentTools::Cli::ExecutableWrapper.call(
+        #   command_path: "llm",
+        #   subcommand_args: ["llm", "models"],
+        #   program_name: "llm-gemini-models"
+        # )
+        ```
+-   **Issue**: Potential stripping of ANSI color codes by `StringIO`.
+    -   Severity: Low (UX impact)
+    -   Location: Usage of `StringIO` for capturing output.
+    -   Suggestion: Verify if ANSI colors are stripped. If they are, and if colors are important for CLI output, investigate alternative methods for modifying the program name in help text, or accept the limitation. `dry-cli` might have configuration options for program name in help output that could avoid this workaround.
+
+### File: `lib/coding_agent_tools/cli/commands/llm/models.rb` and `lib/coding_agent_tools/cli/commands/lms/models.rb`
+
+**Refactoring Opportunities:**
+-   **Opportunity**: Shared logic between `LLM::Models` and `LMS::Models`.
+    -   Current approach: Two separate classes with very similar structure (options, call method flow, filtering, output formatting, error handling).
+    -   Suggested approach: If more model providers with listing capabilities are anticipated, consider creating a base command class or a shared module for common model listing functionality (e.g., option definitions for `:filter`, `:format`, `:debug`, and the `output_models` / `handle_error` methods). For only two providers, the current duplication is acceptable but keep an eye on it if more are added.
+    -   Benefits: Reduced duplication, easier maintenance of shared logic.
+
+**Best Practice Violations (Minor):**
+-   Violation: Fallback model lists are hardcoded within the command classes.
+    -   Impact: Small; makes it slightly harder to update these lists without code changes.
+    -   Recommendation: Consider moving these fallback lists to constants within the respective client organisms (`GeminiClient`, `LMStudioClient`) or a dedicated configuration module. This centralizes model-related data.
+    ```ruby
+    # In Organisms::GeminiClient
+    # FALLBACK_MODELS_DATA = [...]
+    # In LLM::Models, if API fails:
+    # Organisms::GeminiClient::FALLBACK_MODELS_DATA.map { |data| Molecules::Model.new(**data) }
+    ```
+
+### File: `lib/coding_agent_tools/organisms/gemini_client.rb`
+
+**Refactoring Opportunities:**
+-   **Opportunity**: URL construction for `list_models`.
+    -   Current approach: Manual path concatenation logic.
+    ```ruby
+    # url_obj = Addressable::URI.parse(@base_url)
+    # base_path = url_obj.path.end_with?("/") ? url_obj.path.chomp("/") : url_obj.path
+    # url_obj.path = "#{base_path}/#{path_segment}"
+    ```
+    -   Suggested approach: Use `Addressable::URI#join` or `Addressable::URI.join`.
+    ```ruby
+    # url = Addressable::URI.join(@base_url, path_segment).to_s
+    # or
+    # url_obj = Addressable::URI.parse(@base_url)
+    # url_obj = url_obj.join(path_segment)
+    # url_obj.query_values = {key: @api_key}
+    # url = url_obj.to_s
+    ```
+    -   Benefits: More idiomatic, less verbose, and potentially more robust.
+
+### File: `lib/coding_agent_tools/organisms/lm_studio_client.rb`
+
+**Code Quality Issues (Minor):**
+-   **Issue**: Default API key environment variable `LM_STUDIO_API_KEY`.
+    -   Severity: Low
+    -   Location: `initialize` method.
+    -   Suggestion: While having the `APICredentials` logic is consistent, LM Studio typically runs on localhost without an API key. Documenting that this key is usually not required for default LM Studio setups would be helpful for users. If it's *never* used by LM Studio, the `APICredentials` machinery for it might be unnecessary overhead for this specific client. However, keeping it for consistency or future-proofing is also a valid argument.
+
+**Well-Done Aspects:**
+-   The `extract_generated_text` method's detailed validation of the API response structure is excellent. This significantly improves robustness against unexpected or malformed responses from the LM Studio API.
+-   The `server_available?` check before making API calls is a good practice.
+
+### File: `docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md`
+**Documentation Issues:**
+-   **Issue**: Discrepancy in "Out of Scope" regarding dynamic model discovery.
+    -   Severity: Low (Documentation inconsistency)
+    -   Location: "Out of Scope" section.
+    -   Suggestion: The task file states `❌ Dynamic model discovery from remote APIs (will use manual/hardcoded lists)` is out of scope. However, the implementation *does* include dynamic model listing from APIs (with a fallback to hardcoded lists). The Changelog correctly reflects this as an "Added" feature. Update the task file to align with the implemented (and superior) functionality or clarify what specific aspect of "dynamic discovery" remains out of scope.
+
+#=> it was refactored based on user feedback, after the task was completed
+
+## Prioritized Action Items
+## 🔴 CRITICAL ISSUES (Must fix before merge)
+*No critical issues identified.*
+
+## 🟡 HIGH PRIORITY (Should fix before merge)
+-   **`exe/*` Scripts Refactoring**:
+    -   File: `exe/llm-gemini-models`, `exe/llm-lmstudio-models`, `exe/llm-lmstudio-query`
+    -   Issue: Significant code duplication for argument prepending, output capturing, and help text modification.
+    -   Fix: Refactor the shared wrapper logic into a common module or helper method to improve maintainability and adhere to DRY principles.
+
+## 🟢 MEDIUM PRIORITY (Consider fixing)
+-   **ANSI Color Check in `exe/*`**:
+    -   File: `exe/*` scripts.
+    -   Issue: Confirm if `StringIO` output capturing strips ANSI color codes from `dry-cli`'s help/error messages.
+    -   Fix: If colors are stripped and deemed important, investigate alternative methods for program name customization in help text or alternative capture methods. Otherwise, document this limitation.
+-   **Fallback Model List Centralization**:
+    -   File: `lib/coding_agent_tools/cli/commands/llm/models.rb`, `lib/coding_agent_tools/cli/commands/lms/models.rb`
+    -   Issue: Hardcoded fallback model lists within command classes.
+    -   Fix: Consider moving these lists to constants within the respective client organisms or a dedicated configuration module for better centralization.
+
+## 🔵 SUGGESTIONS (Nice to have)
+-   **URL Construction in `GeminiClient`**:
+    -   File: `lib/coding_agent_tools/organisms/gemini_client.rb`
+    -   Issue: Manual URL path joining logic in `list_models`.
+    -   Fix: Refactor to use `Addressable::URI#join` for cleaner and more idiomatic URL construction.
+-   **Task File Update**:
+    -   File: `docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md`
+    -   Issue: "Out of Scope" for dynamic model discovery doesn't match the implemented feature.
+    -   Fix: Update the task file's scope to accurately reflect that dynamic model listing from APIs was implemented.
+
+## Performance Considerations
+-   The dynamic model listing features introduce API calls when `llm-*-models` commands are run. The impact should be minimal for CLI usage, and fallbacks exist.
+-   The timeout for `LMStudioClient` is 180 seconds. This is generous but might be appropriate for local model inference times, which can vary.
+
+## Refactoring Recommendations
+-   The primary refactoring recommendation is for the `exe/*` script wrapper logic as detailed in High Priority.
+-   If more model providers are added, consider a base class for model listing CLI commands (`lib/.../commands/.../models.rb`).
+
+## Positive Highlights
+-   **Robust `LMStudioClient`**: The error checking and response parsing in `LMStudioClient` are thorough and defensive, which is excellent for dealing with external APIs.
+-   **Dynamic Model Listing**: The addition of dynamic model listing (with fallbacks) for both Gemini and LM Studio greatly enhances usability and discoverability. This is a significant improvement, especially noted in the reflection for task 4.
+-   **Comprehensive Testing**: The commitment to testing, including new unit tests for commands/organisms and Aruba/VCR integration tests for LM Studio, is commendable and aligns with project standards.
+-   **Clear CLI Design**: The new commands and their options are intuitive and provide useful features like filtering and multiple output formats, catering well to both human users and AI agents.
+-   **`Molecules::Model`**: This new data molecule provides a clean and consistent way to represent model information throughout the application.
+-   **Changelog and Task Documentation**: The `CHANGELOG.md` is detailed and well-maintained. Task files are generally kept up-to-date, reflecting a mature documentation-driven process. The reflection notes are also valuable.
+
+## Risk Assessment
+-   **Low Risk**: The changes are primarily additive.
+-   The main risk is minor regressions or UX issues related to the `exe/*` script output modification if not thoroughly tested across different `dry-cli` outputs. The duplicated logic in these scripts poses a maintenance risk.
+
+## Approval Recommendation
+[ ] ✅ Approve with minor changes
+
+### Justification
+The diff introduces valuable new features with generally high-quality code and strong testing. The architectural alignment is good. The primary concern is the duplicated logic in the `exe/*` wrapper scripts, which should be refactored for better maintainability. Addressing this (High Priority item) would make the changes excellent. The Medium Priority and Suggestion items are good for further polish.
diff --git a/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-openai-o3.md b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-openai-o3.md
new file mode 100644
index 0000000..5d607fa
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-openai-o3.md
@@ -0,0 +1,139 @@
+# Code Review Analysis
+
+## Executive Summary
+The diff introduces LM Studio support, model-listing commands, a reusable `Model` molecule, and extensive test suites.  Overall quality is high: the ATOM layering is respected, code is idiomatic Ruby, tests are thorough, StandardRB passes, and no critical security issues were found.
+Main concerns are duplication in the new executables, un-needed APICredentials usage in the local client, minor error-handling gaps, and CI-fragility caused by real localhost probes in integration specs.
+
+---
+
+## Architectural Compliance Assessment
+### ATOM Pattern Adherence
+| Layer | New artefacts | Assessment |
+|-------|---------------|------------|
+| Atoms | — | none added – OK |
+| Molecules | `Molecules::Model` | Pure data object, no external deps → ✔ |
+| Organisms | `Organisms::LMStudioClient` | Orchestrates HTTPRequestBuilder, APIResponseParser, APICredentials → good separation ✔ |
+| CLI / Ecosystem | New commands under `cli/commands/lms/*` & `llm/*`; CLI registry extended | Follows existing CLI ecosystem conventions ✔ |
+
+### Identified Violations
+1. `LMStudioClient` instantiates `APICredentials` although localhost does not require auth (breaks “no unnecessary deps” rule) – **Medium**.
+2. Executable wrappers (`exe/llm-*`) contain copy-pasted logic instead of an Atom/Molecule – **Low** (maintainability).
+
+---
+
+## Ruby Gem Best Practices
+### Strengths
+* Idiomatic Ruby (keyword args, Safe Navigation, frozen string, StandardRB clean)
+* Zeitwerk inflector updated correctly
+* Gem structure & gemspec unaffected, runtime deps unchanged
+
+### Areas for Improvement
+* Move duplicate wrapper logic to one helper (DRY, easier bug-fixing)
+* Remove unused `@api_key` / `APICredentials` from `LMStudioClient` or make auth optional
+* Consider adding version bump in `version.rb` together with CHANGELOG entry
+
+---
+
+## Test Quality Analysis
+### Coverage Impact
++ substantial: new specs raise line coverage > 91 % (above 90 % target).
+
+### Test Design Issues
+* Integration specs probe `http://localhost:1234/v1/models` **before** VCR; on CI with WebMock this raises exception unless rescued → use WebMock-allowed hosts or wrap in VCR. (**High**)
+* Executable specs missing (wrappers not tested).
+
+### Missing Test Scenarios
+* Error path in `LMStudioClient.handle_error`
+* Models command JSON filtering with empty result set
+* Duplicate SystemExit printing in wrappers
+
+---
+
+## Security Assessment
+No secrets leaked; ENV-based keys filtered in VCR.
+Regex substitutions in executables may unintentionally mangle user output but do not expose data (Low).
+Localhost HTTP is assumed safe – acceptable.
+
+---
+
+## API Design Review
+No public API breaking changes; new public surface:
+* `LMStudioClient`
+* `Molecules::Model`
+
+Both use keyword args, documented via YARD-style comments – ✔
+
+---
+
+## Detailed Code Feedback (selected)
+
+### lib/coding_agent_tools/organisms/lm_studio_client.rb
+*Issue:* Forces `APICredentials` lookup – not needed for localhost.
+*Suggestion:* Make credential injection optional or drop entirely.
+
+*Issue:* `@generation_config.merge` keeps nils; consider `compact`.
+
+### exe/llm-gemini-models / exe/llm-lmstudio-models / exe/llm-lmstudio-query
+*Duplication:* Same 100+ lines repeated three times.
+*Refactor:* Extract a `Executable::Wrapper` atom that receives sub-command array and self-name.
+
+*Performance:* Capturing all output via `StringIO` fine for small outputs but could be heavy for long streaming responses.
+
+### spec/integration/llm_lmstudio_query_integration_spec.rb
+*Fragility:* Real HTTP probe in `before` may fail under WebMock; wrap in `begin … rescue` already, but still counts as skipped tests → reduce coverage. Use VCR for the check or stub.
+
+### lib/coding_agent_tools/cli/commands/llm/models.rb
+*Edge case:* `model.description.downcase` safe because description always set, yet keep defensive coding: `to_s.downcase`.
+
+---
+
+## Prioritized Action Items
+
+### 🔴 Critical
+None – code safe to merge.
+
+### 🟡 High
+1. **CI Fragility** – replace raw Net::HTTP probe in LMS integration specs with `WebMock.allow_net_connect?` check or VCR-wrapped probe.
+
+### 🟢 Medium
+1. Drop or gate `APICredentials` usage inside `LMStudioClient`.
+2. Extract common executable wrapper into shared helper to remove duplication.
+3. Add unit tests for wrappers (at least ensure modified help output works).
+
+### 🔵 Suggestions
+1. Consider caching Gemini/LM-Studio model lists (TTL) to avoid repeated API hits.
+2. Provide streamed output option for long LMS completions.
+
+---
+
+## Performance Considerations
+Model-listing commands hit remote API every run; acceptable for CLI but might add `--cache` later.
+StringIO capture duplicates large outputs in memory; could stream directly when not modifying.
+
+---
+
+## Refactoring Recommendations
+* Create `CodingAgentTools::Executable::Wrapper.call(binary_name, subcommand_path)` to generalise wrapper logic.
+* Provide `CredentialsBase` molecule; let `GeminiClient` use it, while `LMStudioClient` skips.
+
+---
+
+## Positive Highlights
+* Excellent validation in `LMStudioClient.extract_generated_text` – defensive coding!
+* Thorough unit & integration test coverage; happy-path and edge cases.
+* Consistent CLI UX across Gemini & LM Studio commands.
+* Proper use of Dry-CLI option DSL; examples included.
+* Detailed CHANGELOG and documentation updates keep project transparent.
+
+---
+
+## Risk Assessment
+Low risk of regression; new code largely isolated.  Biggest risk is CI skips causing blind spots; once addressed, merge is safe.
+
+---
+
+## Approval Recommendation
+☑️ **Approve with minor changes**
+
+### Justification
+Changes add valuable offline LLM functionality and model discovery.  Architecture, style, and tests are solid.  Only minor maintainability and CI reliability fixes are recommended before final merge.
diff --git a/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-prompt.md b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-prompt.md
new file mode 100644
index 0000000..848a8ae
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-prompt.md
@@ -0,0 +1,8926 @@
+# AI Agent Task: Comprehensive Ruby Gem Code Review
+
+You are an expert Ruby developer, software architect, and code quality specialist. Your task is to perform a thorough code review of the provided diff, focusing on Ruby gem best practices, ATOM architecture compliance, and maintaining high standards for CLI-first design.
+
+## Context: Project Standards
+
+This Ruby gem follows:
+- **ATOM architecture** pattern (Atoms, Molecules, Organisms, Ecosystems)
+- **Test-driven development** with RSpec (100% coverage target)
+- **CLI-first design** optimized for both humans and AI agents
+- **Documentation-driven development** approach
+- **Semantic versioning** with conventional commits
+- **Ruby style guide** with StandardRB enforcement
+
+## Input Data
+
+### Code Diff to Review
+```diff
+diff --git a/CHANGELOG.md b/CHANGELOG.md
+index 78ffe00..963dfff 100644
+--- a/CHANGELOG.md
++++ b/CHANGELOG.md
+@@ -5,6 +5,55 @@ All notable changes to this project will be documented in this file.
+ The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
+ and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
+ 
++## Unreleased
++
++#### v.0.2.0+task.4 - 2025-06-14 - Add Model Override Flag Support
++
++### Added
++- **Model Override Flags**: Complete implementation of `--model` flag support for both Gemini and LM Studio query commands
++  - Model parameter validation and error handling through APIs
++  - Help text documentation with usage examples
++- **Model Listing Commands**: New CLI commands for discovering available models
++  - `llm-gemini-models` command with fuzzy search filtering (text/JSON output)
++  - `llm-lmstudio-models` command with fuzzy search filtering (text/JSON output)
++  - Updated CLI registration to include models commands
++- **Updated Model Lists**: Accurate model names aligned with v1beta API
++  - Gemini models: gemini-2.0-flash-lite (default), gemini-2.0-flash, gemini-2.5-flash-preview-05-20, gemini-2.5-pro-preview-06-05, gemini-1.5-flash, gemini-1.5-flash-8b, gemini-1.5-pro
++  - LM Studio models: mistralai/devstral-small-2505 (default), deepseek/deepseek-r1-0528-qwen3-8b, and others
++- **Enhanced Testing**: 
++  - Unit tests for model listing commands with comprehensive filter testing
++  - Integration test updates with valid model override scenarios
++  - Fixed test model names to use v1beta compatible models
++
++### Changed
++- Updated Gemini model list to reflect actual v1beta API availability
++- Improved integration tests to use valid model names (gemini-1.5-flash for Gemini tests)
++- Enhanced error handling consistency across commands
++
++#### v.0.2.0+task.3 - 2025-06-14 - Implement LM Studio Query Command
++
++### Added
++- **LM Studio Integration**: Complete implementation of `llm-lmstudio-query` command for offline LLM inference
++  - `LMStudioClient` organism with HTTP REST integration to localhost:1234
++  - CLI command with argument parsing for prompts and file input
++  - Server health check and connection validation
++  - Comprehensive error handling for server unavailable scenarios
++  - Default model support (mistralai/devstral-small-2505) with configurability
++- **Testing Infrastructure**:
++  - Unit tests with mock server scenarios for LMStudioClient
++  - Integration tests using Aruba + VCR pattern
++  - VCR cassettes for LM Studio API interactions
++  - Test coverage for various prompt types and edge cases
++- **CLI Infrastructure**:
++  - LMS command registration in CLI system
++  - Executable script `exe/llm-lmstudio-query`
++  - Proper Zeitwerk inflection for LMStudioClient
++
++### Changed
++- **Module Loading**: Updated Zeitwerk inflector configuration to include `lm_studio_client`
++- **CLI Registration**: Extended CLI system to register LMS commands alongside existing LLM commands
++- **VCR Configuration**: Enhanced VCR setup to handle localhost connections for LM Studio testing
++
+ ## [v.0.2.0+tasks.5 - task.16] - CLI Integration Testing, Documentation Updates, and Code Quality Fixes
+ 
+ ### Added
+diff --git a/docs-project/current/v.0.2.0-synapse/reflections/20250614-reflections-on-model-override-task.md b/docs-project/current/v.0.2.0-synapse/reflections/20250614-reflections-on-model-override-task.md
+new file mode 100644
+index 0000000..afd4e36
+--- /dev/null
++++ b/docs-project/current/v.0.2.0-synapse/reflections/20250614-reflections-on-model-override-task.md
+@@ -0,0 +1,19 @@
++# Reflections Template
++
++## Stop Doing
++
++- **Guessing File Paths:** I incorrectly guessed the path for the VCR cassette when trying to delete it. I should have used `find_path` first to confirm its location before attempting a file operation.
++- **Making Assumptions on Test Failures:** I jumped to the conclusion that the VCR cassette was the problem for the failing integration test, when the root cause was the use of an invalid model name in the test setup. Re-recording the cassette fixed it, but only after I had already corrected the model name. I need to analyze the complete context of a failure before attempting a fix.
++- **Using Hardcoded Lists for Dynamic Data:** The initial implementation for listing models used a static, hardcoded list. It was a correct user suggestion to change this to a dynamic API call. I should default to fetching dynamic data from its source when possible.
++
++## Continue Doing
++
++- **Systematically Following Workflow Instructions:** I successfully followed the steps outlined in `create-reflection-note.wf.md`, which led to the correct creation of the reflection file.
++- **Correcting Tool Usage Errors:** When the `bin/rc -p` command failed, I correctly interpreted the help output and used the right command (`bin/rc`) immediately after.
++- **Refactoring to Better Data Structures:** Adopting the `Molecules::Model` class to represent model data was a significant improvement over using raw hashes. I should continue to embrace creating clear data structures.
++
++## Start Doing
++
++- **Verifying Paths Before Acting:** I will make it a priority to use `find_path` or `list_directory` to confirm a file's existence and exact path before attempting to modify or delete it, to avoid failed tool calls.
++- **Deeper Root Cause Analysis:** When a test fails, I will focus more on identifying the fundamental reason (e.g., "Why did the API call fail?") rather than just fixing the immediate symptom (e.g., "The test failed").
++- **Designing for Dynamism First:** When dealing with data that can change, like a list of API-provided models, my default approach should be to build a dynamic solution from the start, rather than beginning with a hardcoded one.
+\ No newline at end of file
+diff --git a/docs-project/current/v.0.2.0-synapse/reflections/20250614-task3-lms-studio-query-implementation.md b/docs-project/current/v.0.2.0-synapse/reflections/20250614-task3-lms-studio-query-implementation.md
+new file mode 100644
+index 0000000..8c1abf9
+--- /dev/null
++++ b/docs-project/current/v.0.2.0-synapse/reflections/20250614-task3-lms-studio-query-implementation.md
+@@ -0,0 +1,23 @@
++# Reflections Template
++
++## Stop Doing
++
++- Allowing stdout leakage in unit tests - this makes test output noisy and harder to debug
++- Writing integration tests that don't properly use VCR for recording HTTP interactions
++- Using inconsistent parameter handling between CLI arguments and method calls (mixing hash vs keyword arguments)
++- Relying on `exit` calls in CLI commands without proper testing patterns that handle SystemExit exceptions
++
++## Continue Doing
++
++- Using comprehensive VCR cassettes that include both health check and actual API calls for realistic integration testing
++- Following the ATOM architecture pattern (organisms composing molecules) for consistent code organization
++- Writing detailed unit tests with proper mocking to isolate components and test error scenarios
++- Using Aruba for CLI integration testing to properly test the executable behavior
++
++## Start Doing
++
++- Capturing stdout/stderr output in all tests that involve print statements to prevent leakage
++- Using SystemExit exceptions in tests when mocking exit calls to ensure proper test flow control
++- Adding explicit parameter validation and type checking in CLI command methods
++- Creating more comprehensive error handling scenarios in integration tests using WebMock for server unavailability
++- Ensuring VCR cassettes include all necessary HTTP interactions (both GET /models and POST /chat/completions)
+\ No newline at end of file
+diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md
+index 0eac1f3..5f85a71 100644
+--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md
++++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.12-Update-Setup-and-Development-Documentation.md
+@@ -1,6 +1,6 @@
+ ---
+ id: v.0.2.0+task.12
+-status: pending
++status: done
+ priority: high
+ estimate: 3h
+ dependencies: [v.0.2.0+task.1]
+@@ -54,18 +54,18 @@ Update the setup and development documentation to reflect the new requirements a
+ 
+ ### Planning Steps
+ 
+-* [ ] Review current SETUP.md and DEVELOPMENT.md to understand existing structure
++* [x] Review current SETUP.md and DEVELOPMENT.md to understand existing structure
+   > TEST: Development Docs Structure Analysis
+   > Type: Pre-condition Check
+   > Assert: Current documentation structure and sections are identified
+   > Manual Verification: Manually review `docs/SETUP.md` and `docs/DEVELOPMENT.md` to understand their existing structure and sections.
+-* [ ] Review .tool-versions and new dependencies to understand updated requirements
+-* [ ] Analyze VCR setup and testing patterns from task.1 implementation
+-* [ ] Plan content updates to maintain document flow and usability
++* [x] Review .tool-versions and new dependencies to understand updated requirements
++* [x] Analyze VCR setup and testing patterns from task.1 implementation
++* [x] Plan content updates to maintain document flow and usability
+ 
+ ### Execution Steps
+ 
+-- [ ] Update `docs/SETUP.md` "Prerequisites" section:
++- [x] Update `docs/SETUP.md` "Prerequisites" section:
+   - Update Ruby version requirement to 3.4.2 (from .tool-versions)
+   - Add "Configuration" section for API keys setup
+   - Document GEMINI_API_KEY and .env.example usage for development
+@@ -74,15 +74,15 @@ Update the setup and development documentation to reflect the new requirements a
+   > Type: Action Validation
+   > Assert: SETUP.md reflects all new requirements and configuration
+   > Manual Verification: Review `docs/SETUP.md` to confirm it reflects all new requirements, including Ruby version, API key setup instructions, and `.env.example`/`spec/.env` usage.
+-- [ ] Update `docs/DEVELOPMENT.md` "Testing Strategy" section:
++- [x] Update `docs/DEVELOPMENT.md` "Testing Strategy" section:
+   - Add new subsection for "Integration Tests with VCR"
+   - Document VCR usage for API-dependent tests
+   - Link to docs/testing-with-vcr.md for detailed VCR information
+   - Explain API key setup in spec/ for recording new cassettes
+-- [ ] Update DEVELOPMENT.md "Build System Commands" section:
++- [x] Update DEVELOPMENT.md "Build System Commands" section:
+   - Document new gem installation verification step in bin/build
+   - Explain enhanced build confidence through local gem installation testing
+-- [ ] Add new section in DEVELOPMENT.md for "Architectural Patterns":
++- [x] Add new section in DEVELOPMENT.md for "Architectural Patterns":
+   - Mention Zeitwerk autoloading adoption
+   - Document dry-monitor observability pattern
+   - Explain ATOM-based component organization
+@@ -90,21 +90,21 @@ Update the setup and development documentation to reflect the new requirements a
+   > Type: Action Validation
+   > Assert: DEVELOPMENT.md includes all new patterns and testing strategies
+   > Manual Verification: Review `docs/DEVELOPMENT.md` to confirm it includes the new "Integration Tests with VCR" section, updated "Build System Commands," and the new "Architectural Patterns" section (Zeitwerk, dry-monitor, ATOM organization).
+-- [ ] Add cross-references between SETUP.md and DEVELOPMENT.md for consistency
+-- [ ] Ensure all new development dependencies are mentioned with their development purpose
++- [x] Add cross-references between SETUP.md and DEVELOPMENT.md for consistency
++- [x] Ensure all new development dependencies are mentioned with their development purpose
+ 
+ ## Acceptance Criteria
+ 
+-- [ ] SETUP.md "Prerequisites" section specifies Ruby >= 3.4.2
+-- [ ] SETUP.md includes "Configuration" section with GEMINI_API_KEY setup instructions
+-- [ ] SETUP.md documents .env.example usage and spec/.env setup for VCR
+-- [ ] DEVELOPMENT.md "Testing Strategy" includes VCR integration testing section
+-- [ ] DEVELOPMENT.md links to docs/testing-with-vcr.md for detailed VCR information
+-- [ ] DEVELOPMENT.md "Build System Commands" documents new gem verification step
+-- [ ] DEVELOPMENT.md includes new "Architectural Patterns" section covering Zeitwerk, dry-monitor, and ATOM organization
+-- [ ] Both documents maintain consistency in terminology and cross-reference appropriately
+-- [ ] All new development dependencies are explained with their purpose
+-- [ ] Documents follow existing project documentation style and formatting
++- [x] SETUP.md "Prerequisites" section specifies Ruby >= 3.4.2
++- [x] SETUP.md includes "Configuration" section with GEMINI_API_KEY setup instructions
++- [x] SETUP.md documents .env.example usage and spec/.env setup for VCR
++- [x] DEVELOPMENT.md "Testing Strategy" includes VCR integration testing section
++- [x] DEVELOPMENT.md links to docs/testing-with-vcr.md for detailed VCR information
++- [x] DEVELOPMENT.md "Build System Commands" documents new gem verification step
++- [x] DEVELOPMENT.md includes new "Architectural Patterns" section covering Zeitwerk, dry-monitor, and ATOM organization
++- [x] Both documents maintain consistency in terminology and cross-reference appropriately
++- [x] All new development dependencies are explained with their purpose
++- [x] Documents follow existing project documentation style and formatting
+ 
+ ## Out of Scope
+ 
+diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md
+index aa970f0..54d1193 100644
+--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md
++++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.2-Implement-API-Key-Discovery-System.md
+@@ -1,6 +1,6 @@
+ ---
+ id: v.0.2.0+task.2 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
+-status: pending # See [Project Management Guide](project-management.md) for all possible values
++status: done # See [Project Management Guide](project-management.md) for all possible values
+ priority: high
+ estimate: 4h
+ dependencies: [v.0.2.0+task.1]
+@@ -38,16 +38,14 @@ Implement API key discovery system (R-LLM-2) that supports finding Gemini API ke
+ 
+ #### Create
+ 
+-- lib/coding_agent_tools/config/api_key_resolver.rb
+-- lib/coding_agent_tools/config/gemini_config.rb
+-- spec/config/api_key_resolver_spec.rb
+-- spec/config/gemini_config_spec.rb
+-- spec/fixtures/gemini_config_sample
++- ✅ lib/coding_agent_tools/molecules/api_credentials.rb (COMPLETED - implements multi-source API key discovery)
++- ✅ lib/coding_agent_tools/atoms/env_reader.rb (COMPLETED - handles environment variable and .env file reading)
++- ✅ spec/coding_agent_tools/molecules/api_credentials_spec.rb (COMPLETED - comprehensive test coverage)
+ 
+ #### Modify
+ 
+-- lib/coding_agent_tools/llm/gemini_client.rb (integrate key discovery)
+-- lib/coding_agent_tools.rb (require new modules)
++- ✅ lib/coding_agent_tools/organisms/gemini_client.rb (COMPLETED - integrates with APICredentials via constructor)
++- ✅ lib/coding_agent_tools.rb (COMPLETED - modules auto-loaded via Zeitwerk)
+ 
+ ## Phases
+ 
+@@ -77,39 +75,39 @@ Implement API key discovery system (R-LLM-2) that supports finding Gemini API ke
+ 
+ *Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._
+ 
+-- [ ] Create ApiKeyResolver class with multi-source discovery
+-  > TEST: Verify ApiKeyResolver Class
++- [x] Create APICredentials molecule with multi-source discovery
++  > TEST: Verify APICredentials Class
+   > Type: Action Validation
+-  > Assert: ApiKeyResolver class exists with resolve method
+-  > Command: ruby -e "require './lib/coding_agent_tools/config/api_key_resolver'; puts CodingAgentTools::Config::ApiKeyResolver.new.respond_to?(:resolve)"
+-- [ ] Implement environment variable lookup for GEMINI_API_KEY
++  > Assert: APICredentials class exists with api_key method
++  > Command: ruby -e "require './lib/coding_agent_tools/molecules/api_credentials'; puts CodingAgentTools::Molecules::APICredentials.new(env_key_name: 'GEMINI_API_KEY').respond_to?(:api_key)"
++- [x] Implement environment variable lookup for GEMINI_API_KEY
+   > TEST: Verify Environment Variable Lookup
+   > Type: Action Validation
+-  > Assert: Resolver finds key from environment variable when no config file exists
+-  > Command: rm -f ~/.gemini/config && GEMINI_API_KEY=test_key ruby -e "require './lib/coding_agent_tools/config/api_key_resolver'; puts CodingAgentTools::Config::ApiKeyResolver.new.resolve"
+-- [ ] Create GeminiConfig class for ~/.gemini/config file parsing
+-- [ ] Implement YAML/JSON config file reader with error handling
++  > Assert: APICredentials finds key from environment variable
++  > Command: GEMINI_API_KEY=test_key ruby -e "require './lib/coding_agent_tools/molecules/api_credentials'; puts CodingAgentTools::Molecules::APICredentials.new(env_key_name: 'GEMINI_API_KEY').api_key"
++- [x] Create EnvReader atom for .env file parsing and environment access
++- [x] Implement .env file reader with automatic discovery and error handling
+   > TEST: Verify Config File Reading
+   > Type: Action Validation
+-  > Assert: Config reader parses sample config file
+-  > Command: ruby -e "require './lib/coding_agent_tools/config/gemini_config'; puts CodingAgentTools::Config::GeminiConfig.from_file('spec/fixtures/gemini_config_sample').api_key"
+-- [ ] Integrate key discovery into GeminiClient initialization
+-- [ ] Add comprehensive unit tests for all discovery scenarios
++  > Assert: EnvReader loads .env files correctly
++  > Command: ruby -e "require './lib/coding_agent_tools/atoms/env_reader'; puts CodingAgentTools::Atoms::EnvReader.load_env_file('.env')"
++- [x] Integrate key discovery into GeminiClient initialization
++- [x] Add comprehensive unit tests for all discovery scenarios
+   > TEST: Verify Test Coverage
+   > Type: Action Validation
+-  > Assert: All config classes have corresponding test files
+-  > Command: find spec -name "*config*" -o -name "*api_key*"
++  > Assert: All molecules have corresponding test files
++  > Command: find spec -name "*api_credentials*" -o -name "*env_reader*"
+ 
+ ## Acceptance Criteria
+ 
+ *Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._
+ 
+-- [ ] AC 1: System successfully discovers API key from GEMINI_API_KEY environment variable
+-- [ ] AC 2: System successfully reads API key from ~/.gemini/config file
+-- [ ] AC 3: Priority order is enforced (config file takes precedence over ENV variable)
+-- [ ] AC 4: Clear error messages when API key is not found or invalid
+-- [ ] AC 5: GeminiClient integrates seamlessly with key discovery system
+-- [ ] AC 6: All unit tests pass with >95% code coverage
++- [x] AC 1: System successfully discovers API key from GEMINI_API_KEY environment variable
++- [x] AC 2: System successfully reads API key from .env files (implemented via EnvReader atom)
++- [x] AC 3: Priority order is enforced (singleton config > ENV variable > error)
++- [x] AC 4: Clear error messages when API key is not found or invalid
++- [x] AC 5: GeminiClient integrates seamlessly with APICredentials molecule
++- [x] AC 6: All unit tests pass with comprehensive coverage
+ 
+ ## Out of Scope
+ 
+@@ -122,6 +120,8 @@ Implement API key discovery system (R-LLM-2) that supports finding Gemini API ke
+ ## References
+ 
+ - Fish implementation: docs-project/backlog/v.0.2.0-synapse/docs/gemini-query.fish (shows .env file loading pattern)
+-- Priority: ~/.gemini/config > GEMINI_API_KEY environment variable
++- Implemented Priority: Singleton config > GEMINI_API_KEY environment variable > .env file > error
++- Architecture: APICredentials molecule composes EnvReader atom for multi-source key discovery
++- Integration: GeminiClient organism uses APICredentials for authentication
+ 
+ ```
+diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md
+index d2cc25d..7e81164 100644
+--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md
++++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.3-Implement-lms-studio-query-Command.md
+@@ -1,9 +1,9 @@
+ ---
+ id: v.0.2.0+task.3 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
+-status: pending # See [Project Management Guide](project-management.md) for all possible values
++status: done # See [Project Management Guide](project-management.md) for all possible values
+ priority: medium
+ estimate: 6h
+-dependencies: []
++dependencies: [v.0.2.0+task.2]
+ ---
+ 
+ # Implement lms-studio-query Command
+@@ -24,11 +24,11 @@ _Result excerpt:_
+ 
+ ## Objective
+ 
+-Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studio on `localhost:1234` using the server's REST protocol for offline inference. Default model should be "mistral-small-24b-instruct-2501@8bit" but configurable. This provides offline LLM capabilities as an alternative to cloud-based services.
++Implement the `llm-lmstudio-query` command (R-LLM-3) that interfaces with LM Studio on `localhost:1234` using the server's REST protocol for offline inference. Default model should be "mistralai/devstral-small-2505" but configurable. This provides offline LLM capabilities as an alternative to cloud-based services.
+ 
+ ## Scope of Work
+ 
+-- Create CLI command `lms-studio-query` with Ruby implementation
++- Create CLI command `llm-lmstudio-query` with Ruby implementation
+ - Integrate with LM Studio REST API on localhost:1234
+ - Support prompt input from string argument or file path
+ - Handle response formatting and error scenarios
+@@ -38,17 +38,21 @@ Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studi
+ 
+ #### Create
+ 
+-- lib/coding_agent_tools/commands/lms_studio_query.rb
+-- lib/coding_agent_tools/llm/lm_studio_client.rb
+-- bin/lms-studio-query (executable CLI script)
+-- spec/commands/lms_studio_query_spec.rb
+-- spec/llm/lm_studio_client_spec.rb
++- lib/coding_agent_tools/cli/commands/lms/query.rb
++- lib/coding_agent_tools/organisms/lm_studio_client.rb
++- exe/llm-lmstudio-query (executable CLI script)
++- spec/coding_agent_tools/cli/commands/lms/query_spec.rb
++- spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
++- spec/integration/llm_lmstudio_query_integration_spec.rb (Aruba + VCR integration tests)
+ 
+ #### Modify
+ 
+-- lib/coding_agent_tools.rb (require new modules)
+ - coding_agent_tools.gemspec (add http client dependencies if needed)
+ 
++#### Note on Zeitwerk
++
++- lib/coding_agent_tools.rb modifications may not be needed due to Zeitwerk autoloading (ADR-002), as long as proper file naming conventions are followed
++
+ ## Phases
+ 
+ 1. Research & API Analysis
+@@ -64,52 +68,58 @@ Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studi
+ 
+ *Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._
+ 
+-- [ ] Research LM Studio REST API documentation and endpoints (reference lms-query.fish)
++- [x] Research LM Studio REST API documentation and endpoints (reference lms-query.fish)
+   > TEST: API Documentation Review
+   > Type: Pre-condition Check
+   > Assert: Understand LM Studio REST protocol and response formats
+   > Command: Manual testing with curl against localhost:1234
+-- [ ] Analyze LM Studio server startup and configuration requirements
+-- [ ] Design error handling for server unavailable scenarios
+-- [ ] Plan consistent interface with Gemini client for future abstraction
++- [x] Analyze LM Studio server startup and configuration requirements
++- [x] Design error handling for server unavailable scenarios
++- [x] Plan consistent interface with Gemini client for future abstraction
+ 
+ ### Execution Steps
+ 
+ *Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._
+ 
+-- [ ] Create LMStudioClient class with HTTP REST integration (based on lms-query.fish)
++- [x] Create LMStudioClient organism with HTTP REST integration (reusing HTTPRequestBuilder and APIResponseParser molecules)
+   > TEST: Verify LMStudioClient Class
+   > Type: Action Validation
+   > Assert: LMStudioClient class exists with generate_text method
+-  > Command: ruby -e "require './lib/coding_agent_tools/llm/lm_studio_client'; puts CodingAgentTools::LLM::LMStudioClient.new.respond_to?(:generate_text)"
+-- [ ] Implement server health check and connection validation
++  > Command: ruby -e "require './lib/coding_agent_tools/organisms/lm_studio_client'; puts CodingAgentTools::Organisms::LMStudioClient.new.respond_to?(:generate_text)"
++- [x] Implement server health check and connection validation
+   > TEST: Verify Server Health Check
+   > Type: Action Validation
+   > Assert: Client can detect if LM Studio server is running
+-  > Command: ruby -e "require './lib/coding_agent_tools/llm/lm_studio_client'; puts CodingAgentTools::LLM::LMStudioClient.new.server_available?"
+-- [ ] Implement CLI command class with argument parsing
+-- [ ] Create executable bin script that calls the command class
++  > Command: ruby -e "require './lib/coding_agent_tools/organisms/lm_studio_client'; puts CodingAgentTools::Organisms::LMStudioClient.new.server_available?"
++- [x] Implement CLI command class with argument parsing
++- [x] Create executable script in exe/ that calls the CLI command class
+   > TEST: Verify CLI Executable
+   > Type: Action Validation
+-  > Assert: lms-studio-query command is executable and shows help
+-  > Command: bin/lms-studio-query --help
+-- [ ] Add comprehensive unit tests including mock server scenarios
++  > Assert: llm-lmstudio-query command is executable and shows help
++  > Command: exe/llm-lmstudio-query --help
++- [x] Add comprehensive unit tests including mock server scenarios
+   > TEST: Verify Test Coverage
+   > Type: Action Validation
+   > Assert: All new classes have corresponding test files with mocks
+   > Command: find spec -name "*lm_studio*" -o -name "*lms*"
+-- [ ] Implement integration test with actual LM Studio instance
++- [x] Integrate APICredentials molecule for authentication (reuse from Task 2)
++- [x] Create integration tests using Aruba + VCR pattern (following llm_gemini_query_integration_spec.rb)
++  > TEST: Verify Integration Test Setup
++  > Type: Action Validation
++  > Assert: Integration test file exists and follows Aruba/VCR pattern
++  > Command: find spec/integration -name "*llm_lmstudio*"
++- [x] Configure VCR cassettes for LM Studio API interactions
+ 
+ ## Acceptance Criteria
+ 
+ *Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._
+ 
+-- [ ] AC 1: `lms-studio-query` command accepts prompts as string arguments and file paths
+-- [ ] AC 2: Command successfully interfaces with LM Studio REST API on localhost:1234
+-- [ ] AC 3: Response output matches expected format from LM Studio
+-- [ ] AC 4: Clear error messages when LM Studio server is not available
+-- [ ] AC 5: All unit tests pass with >95% code coverage
+-- [ ] AC 6: Integration test successfully calls live LM Studio instance
++- [x] AC 1: `llm-lmstudio-query` command accepts prompts as string arguments and file paths
++- [x] AC 2: Command successfully interfaces with LM Studio REST API on localhost:1234
++- [x] AC 3: Response output matches expected format from LM Studio
++- [x] AC 4: Clear error messages when LM Studio server is not available
++- [x] AC 5: All unit tests pass with >95% code coverage
++- [x] AC 6: Integration test successfully calls live LM Studio instance
+ 
+ ## Out of Scope
+ 
+@@ -124,6 +134,11 @@ Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studi
+ 
+ - Fish implementation: docs-project/backlog/v.0.2.0-synapse/docs/lms-query.fish
+ - LM Studio API endpoint: http://localhost:1234/v1/chat/completions
+-- Default model: mistral-small-24b-instruct-2501@8bit
++- Default model: mistralai/devstral-small-2505
++- Architecture: Follow ATOM pattern - LMStudioClient organism composes APICredentials, HTTPRequestBuilder, and APIResponseParser molecules
++- Reuse existing molecules: APICredentials (from Task 2), HTTPRequestBuilder, APIResponseParser
++- CLI pattern: Follow same structure as lib/coding_agent_tools/cli/commands/llm/query.rb
++- Integration testing: Use Aruba + VCR pattern similar to llm_gemini_query_integration_spec.rb
++- Zeitwerk: Follow ADR-002 file naming conventions to avoid manual require statements
+ 
+ ```
+diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md
+index be25ce1..03de153 100644
+--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md
++++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.4-Add-Model-Override-Flag-Support.md
+@@ -1,9 +1,9 @@
+ ---
+ id: v.0.2.0+task.4 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
+-status: pending # See [Project Management Guide](project-management.md) for all possible values
++status: done # See [Project Management Guide](project-management.md) for all possible values
+ priority: medium
+ estimate: 3h
+-dependencies: [v.0.2.0+task.1, v.0.2.0+task.3]
++dependencies: [v.0.2.0+task.3]
+ ---
+ 
+ # Add Model Override Flag Support
+@@ -24,11 +24,12 @@ _Result excerpt:_
+ 
+ ## Objective
+ 
+-Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-studio-query` commands to allow users to override default models. Default models: Gemini uses "gemini-2.0-flash-lite" and LM Studio uses "mistral-small-24b-instruct-2501@8bit". This provides flexibility for users to select specific models based on their needs or availability.
++Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `llm-lmstudio-query` commands to allow users to override default models. Default models: Gemini uses "gemini-2.0-flash-lite" and LM Studio uses "mistralai/devstral-small-2505". Additionally, implement separate model listing commands `exe/llm-gemini-models` and `exe/llm-lmstudio-models` with fuzzy search filtering capability. This provides flexibility for users to select specific models based on their needs or availability.
+ 
+ ## Scope of Work
+ 
+-- Add `--model` flag to both llm-gemini-query and lms-studio-query commands
++- Add `--model` flag to both llm-gemini-query and llm-lmstudio-query commands
++- Implement separate model listing commands with fuzzy search filtering
+ - Implement model validation and error handling for invalid models
+ - Update client classes to support dynamic model selection
+ - Add configuration for default model settings
+@@ -38,23 +39,29 @@ Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-
+ 
+ #### Create
+ 
+-- spec/integration/model_override_spec.rb
++- lib/coding_agent_tools/cli/commands/llm/models.rb
++- lib/coding_agent_tools/cli/commands/lms/models.rb
++- exe/llm-gemini-models (executable CLI script)
++- exe/llm-lmstudio-models (executable CLI script)
++- spec/coding_agent_tools/cli/commands/llm/models_spec.rb
++- spec/coding_agent_tools/cli/commands/lms/models_spec.rb
+ 
+ #### Modify
+ 
+-- lib/coding_agent_tools/commands/llm_gemini_query.rb (add --model flag)
+-- lib/coding_agent_tools/commands/lms_studio_query.rb (add --model flag)
+-- lib/coding_agent_tools/llm/gemini_client.rb (support model parameter)
+-- lib/coding_agent_tools/llm/lm_studio_client.rb (support model parameter)
+-- bin/llm-gemini-query (update help text)
+-- bin/lms-studio-query (update help text)
++- lib/coding_agent_tools/cli/commands/llm/query.rb (✅ already has --model flag)
++- lib/coding_agent_tools/cli/commands/lms/query.rb (add --model flag, from Task 3)
++- lib/coding_agent_tools/organisms/gemini_client.rb (✅ already supports model parameter)
++- lib/coding_agent_tools/organisms/lm_studio_client.rb (support model parameter)
++- exe/llm-gemini-query (update help text)
++- exe/llm-lmstudio-query (update help text)
+ 
+ ## Phases
+ 
+ 1. Design & Analysis
+-2. CLI Flag Implementation
+-3. Client Integration
+-4. Testing & Documentation
++2. Model Listing Commands Implementation
++3. CLI Flag Implementation (partially done for Gemini)
++4. Client Integration
++5. Testing & Documentation
+ 
+ ## Implementation Plan
+ 
+@@ -64,60 +71,81 @@ Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-
+ 
+ *Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._
+ 
+-- [ ] Research available Gemini models and their identifiers (reference gemini-query.fish)
++- [x] Research available Gemini models and their identifiers (reference gemini-query.fish)
+   > TEST: Model Research
+   > Type: Pre-condition Check
+   > Assert: Understand valid model names for Gemini and LM Studio
+   > Command: Manual review of API documentation and Fish implementations
+-- [ ] Analyze current CLI argument parsing patterns in existing commands
+-- [ ] Design model validation strategy and error messages
+-- [ ] Plan default model configuration approach
++- [x] Analyze current CLI argument parsing patterns in existing commands
++- [x] Design model validation strategy and error messages
++- [x] Plan default model configuration approach
++- [x] Design fuzzy search filtering mechanism for model listing
++- [x] Plan model listing data structure and API integration approach
+ 
+ ### Execution Steps
+ 
+ *Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._
+ 
+-- [ ] Add --model flag to llm-gemini-query command parser
++- [x] Add --model flag to llm-gemini-query command parser (✅ already implemented)
+   > TEST: Verify Gemini Model Flag
+   > Type: Action Validation
+   > Assert: llm-gemini-query accepts --model flag
+-  > Command: bin/llm-gemini-query --help | grep -i model
+-- [ ] Add --model flag to lms-studio-query command parser
++  > Command: exe/llm-gemini-query --help | grep -i model
++- [x] Add --model flag to llm-lmstudio-query command parser
+   > TEST: Verify LM Studio Model Flag
+   > Type: Action Validation
+-  > Assert: lms-studio-query accepts --model flag  
+-  > Command: bin/lms-studio-query --help | grep -i model
+-- [ ] Update GeminiClient to accept model parameter in constructor
++  > Assert: llm-lmstudio-query accepts --model flag  
++  > Command: exe/llm-lmstudio-query --help | grep -i model
++- [x] Update GeminiClient to accept model parameter in constructor (✅ already implemented)
+   > TEST: Verify Gemini Client Model Support
+   > Type: Action Validation
+   > Assert: GeminiClient accepts model parameter
+-  > Command: ruby -e "require './lib/coding_agent_tools/llm/gemini_client'; puts CodingAgentTools::LLM::GeminiClient.new(model: 'test').respond_to?(:generate_text)"
+-- [ ] Update LMStudioClient to accept model parameter in constructor
+-- [ ] Implement model validation with helpful error messages
++  > Command: ruby -e "require './lib/coding_agent_tools/organisms/gemini_client'; puts CodingAgentTools::Organisms::GeminiClient.new(model: 'test').respond_to?(:generate_text)"
++- [x] Update LMStudioClient to accept model parameter in constructor
++- [x] Create llm-gemini-models command with fuzzy search filtering
++  > TEST: Verify Gemini Models Command
++  > Type: Action Validation
++  > Assert: llm-gemini-models command exists and supports filtering
++  > Command: exe/llm-gemini-models --help
++- [x] Create llm-lmstudio-models command with fuzzy search filtering
++  > TEST: Verify LM Studio Models Command
++  > Type: Action Validation
++  > Assert: llm-lmstudio-models command exists and supports filtering
++  > Command: exe/llm-lmstudio-models --help
++- [x] Implement model validation with helpful error messages
+   > TEST: Verify Model Validation
+   > Type: Action Validation
+   > Assert: Commands show helpful error for invalid models
+-  > Command: bin/llm-gemini-query --model invalid_model "test" 2>&1 | grep -i "invalid model"
+-- [ ] Add integration tests for model override functionality
+-  > TEST: Verify Integration Tests
++  > Command: exe/llm-gemini-query --model invalid_model "test" 2>&1 | grep -i "invalid model"
++- [x] Add model override tests to existing integration test files
++  > TEST: Verify Model Override in Gemini Integration Tests
++  > Type: Action Validation
++  > Assert: Gemini integration tests include model override scenarios (test with gemini-1.5-flash)
++  > Command: grep -n "model.*gemini-1.5-flash" spec/integration/llm_gemini_query_integration_spec.rb
++  > TEST: Verify Model Override in LM Studio Integration Tests
+   > Type: Action Validation
+-  > Assert: Integration test file exists and tests model overrides
+-  > Command: find spec -name "*model_override*"
++  > Assert: LM Studio integration tests include model override scenarios (test with mistralai/devstral-small-2505)
++  > Command: grep -n "model.*mistralai/devstral-small-2505" spec/integration/llm_lmstudio_query_integration_spec.rb
+ 
+ ## Acceptance Criteria
+ 
+ *Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._
+ 
+-- [ ] AC 1: Both commands accept --model flag with proper argument parsing
+-- [ ] AC 2: Model parameter is passed through to respective client classes
+-- [ ] AC 3: Invalid model names produce clear error messages
+-- [ ] AC 4: Default models work when --model flag is not specified (gemini-2.0-flash-lite for Gemini, mistral-small-24b-instruct-2501@8bit for LM Studio)
+-- [ ] AC 5: Help text documents available models and usage examples
+-- [ ] AC 6: All unit and integration tests pass
++- [x] AC 1: Gemini command accepts --model flag with proper argument parsing (✅ completed)
++- [x] AC 1b: LM Studio command accepts --model flag with proper argument parsing
++- [x] AC 2: Model parameter is passed through to GeminiClient (✅ completed)
++- [x] AC 2b: Model parameter is passed through to LMStudioClient
++- [x] AC 3: Invalid model names produce clear error messages
++- [x] AC 4: Default models work when --model flag is not specified (gemini-2.0-flash-lite for Gemini, ✅ completed)
++- [x] AC 4b: Default model works for LM Studio (mistralai/devstral-small-2505)
++- [x] AC 5: Help text documents available models and usage examples
++- [x] AC 6: Model listing commands work with fuzzy search filtering
++- [x] AC 7: Model override functionality is tested in existing integration tests (llm_gemini_query_integration_spec.rb and llm_lmstudio_query_integration_spec.rb)
++- [x] AC 8: All unit and integration tests pass
+ 
+ ## Out of Scope
+ 
+-- ❌ Dynamic model discovery or listing from services
++- ❌ Dynamic model discovery from remote APIs (will use manual/hardcoded lists)
+ - ❌ Model capability validation or compatibility checking
+ - ❌ Performance benchmarking between different models
+ - ❌ Model-specific parameter tuning (temperature, top-k, etc.)
+@@ -130,8 +158,13 @@ Implement `--model` flag support (R-LLM-4) for both `llm-gemini-query` and `lms-
+   - docs-project/backlog/v.0.2.0-synapse/docs/gemini-query.fish
+   - docs-project/backlog/v.0.2.0-synapse/docs/lms-query.fish
+ - Default models:
+-  - Gemini: gemini-2.0-flash-lite
+-  - LM Studio: mistral-small-24b-instruct-2501@8bit
++  - Gemini: gemini-2.0-flash-lite (✅ implemented)
++  - LM Studio: mistralai/devstral-small-2505
++- Current implementation: lib/coding_agent_tools/cli/commands/llm/query.rb already has --model flag
++- Architecture: Model listing commands follow same CLI pattern as query commands
++- Fuzzy search: Use simple string matching for model name filtering
++- Integration testing: Add model override tests to existing integration specs rather than separate file
++- Test models: Use gemini-1.5-flash for Gemini tests and mistralai/devstral-small-2505 for LM Studio tests in VCR cassettes
+ 
+ 
+ ```
+diff --git a/exe/llm-gemini-models b/exe/llm-gemini-models
+new file mode 100755
+index 0000000..3447a04
+--- /dev/null
++++ b/exe/llm-gemini-models
+@@ -0,0 +1,104 @@
++#!/usr/bin/env ruby
++
++# Only require bundler/setup if it hasn't been loaded already
++# (e.g., via RUBYOPT) and we're in a bundled environment
++unless defined?(Bundler)
++  if ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../Gemfile", __FILE__))
++    begin
++      require "bundler/setup"
++    rescue LoadError
++      # If bundler isn't available, continue without it
++      # This can happen in subprocess calls where Ruby version differs
++    end
++  end
++end
++
++# Set up load paths for development if necessary (e.g., when not installed as a gem)
++# This ensures that `lib` is on the load path.
++# If the gem is installed, this line is not strictly necessary but doesn't hurt.
++# If running from the project's exe directory, it's crucial.
++$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
++
++require "coding_agent_tools"
++require "coding_agent_tools/cli"
++require "coding_agent_tools/error_reporter"
++
++# This executable is a convenience wrapper that calls the main CLI
++# with the 'llm models' command prepended to the arguments
++begin
++  # Prepend 'llm models' to the arguments and call the main CLI
++  modified_args = ["llm", "models"] + ARGV
++
++  # Replace ARGV with our modified arguments
++  ARGV.clear
++  ARGV.concat(modified_args)
++
++  # Ensure LLM commands are registered before calling CLI
++  CodingAgentTools::Cli::Commands.register_llm_commands
++
++  # Capture both stdout and stderr to modify error/help messages
++  original_stdout = $stdout
++  original_stderr = $stderr
++  require "stringio"
++  # Note: Capturing output with StringIO might strip/affect ANSI color codes from the underlying CLI command.
++  captured_stdout = StringIO.new
++  captured_stderr = StringIO.new
++
++  $stdout = captured_stdout
++  $stderr = captured_stderr
++
++  # Call the main CLI
++  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
++
++  # If we get here, the command succeeded without raising SystemExit
++  # Get the captured output and display it
++  stdout_content = captured_stdout.string
++  stderr_content = captured_stderr.string
++
++  # Restore stdout and stderr
++  $stdout = original_stdout
++  $stderr = original_stderr
++
++  # Modify messages to show only 'llm-gemini-models' instead of full path
++  if stdout_content.include?("llm models") || stderr_content.include?("llm models")
++    stdout_content = stdout_content.gsub("llm-gemini-models llm models", "llm-gemini-models")
++    stderr_content = stderr_content.gsub(/"[^"]*llm[^"]*models"/, '"llm-gemini-models"')
++    stderr_content = stderr_content.gsub(/Usage: "[^"]*llm[^"]*models[^"]*"/, 'Usage: "llm-gemini-models"')
++  end
++
++  # Print the output
++  $stdout.print stdout_content unless stdout_content.empty?
++  $stderr.print stderr_content unless stderr_content.empty?
++rescue SystemExit => e
++  # Get the captured output
++  stdout_content = captured_stdout.string
++  stderr_content = captured_stderr.string
++
++  # Restore stdout and stderr
++  $stdout = original_stdout
++  $stderr = original_stderr
++
++  # Modify messages to show only 'llm-gemini-models' instead of full path
++  if stdout_content.include?("llm models") || stderr_content.include?("llm models")
++    stdout_content = stdout_content.gsub("llm-gemini-models llm models", "llm-gemini-models")
++    stderr_content = stderr_content.gsub(/"[^"]*llm[^"]*models"/, '"llm-gemini-models"')
++    stderr_content = stderr_content.gsub(/Usage: "[^"]*llm[^"]*models[^"]*"/, 'Usage: "llm-gemini-models"')
++  end
++
++  # Print the modified output
++  $stdout.print stdout_content unless stdout_content.empty?
++  $stderr.print stderr_content unless stderr_content.empty?
++
++  # Re-raise the SystemExit to preserve the exit code
++  raise e
++rescue => e
++  $stdout = original_stdout if original_stdout
++  $stderr = original_stderr if original_stderr
++  # Handle all errors through the centralized error reporter
++  CodingAgentTools::ErrorReporter.call(e, debug: ENV["DEBUG"] == "true")
++  exit 1
++ensure
++  # Always restore stdout and stderr in case of any unexpected issues
++  $stdout = original_stdout if original_stdout
++  $stderr = original_stderr if original_stderr
++end
+diff --git a/exe/llm-lmstudio-models b/exe/llm-lmstudio-models
+new file mode 100755
+index 0000000..6d507c9
+--- /dev/null
++++ b/exe/llm-lmstudio-models
+@@ -0,0 +1,104 @@
++#!/usr/bin/env ruby
++
++# Only require bundler/setup if it hasn't been loaded already
++# (e.g., via RUBYOPT) and we're in a bundled environment
++unless defined?(Bundler)
++  if ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../Gemfile", __FILE__))
++    begin
++      require "bundler/setup"
++    rescue LoadError
++      # If bundler isn't available, continue without it
++      # This can happen in subprocess calls where Ruby version differs
++    end
++  end
++end
++
++# Set up load paths for development if necessary (e.g., when not installed as a gem)
++# This ensures that `lib` is on the load path.
++# If the gem is installed, this line is not strictly necessary but doesn't hurt.
++# If running from the project's exe directory, it's crucial.
++$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
++
++require "coding_agent_tools"
++require "coding_agent_tools/cli"
++require "coding_agent_tools/error_reporter"
++
++# This executable is a convenience wrapper that calls the main CLI
++# with the 'lms models' command prepended to the arguments
++begin
++  # Prepend 'lms models' to the arguments and call the main CLI
++  modified_args = ["lms", "models"] + ARGV
++
++  # Replace ARGV with our modified arguments
++  ARGV.clear
++  ARGV.concat(modified_args)
++
++  # Ensure LMS commands are registered before calling CLI
++  CodingAgentTools::Cli::Commands.register_lms_commands
++
++  # Capture both stdout and stderr to modify error/help messages
++  original_stdout = $stdout
++  original_stderr = $stderr
++  require "stringio"
++  # Note: Capturing output with StringIO might strip/affect ANSI color codes from the underlying CLI command.
++  captured_stdout = StringIO.new
++  captured_stderr = StringIO.new
++
++  $stdout = captured_stdout
++  $stderr = captured_stderr
++
++  # Call the main CLI
++  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
++
++  # If we get here, the command succeeded without raising SystemExit
++  # Get the captured output and display it
++  stdout_content = captured_stdout.string
++  stderr_content = captured_stderr.string
++
++  # Restore stdout and stderr
++  $stdout = original_stdout
++  $stderr = original_stderr
++
++  # Modify messages to show only 'llm-lmstudio-models' instead of full path
++  if stdout_content.include?("lms models") || stderr_content.include?("lms models")
++    stdout_content = stdout_content.gsub("llm-lmstudio-models lms models", "llm-lmstudio-models")
++    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*models"/, '"llm-lmstudio-models"')
++    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*models[^"]*"/, 'Usage: "llm-lmstudio-models"')
++  end
++
++  # Print the output
++  $stdout.print stdout_content unless stdout_content.empty?
++  $stderr.print stderr_content unless stderr_content.empty?
++rescue SystemExit => e
++  # Get the captured output
++  stdout_content = captured_stdout.string
++  stderr_content = captured_stderr.string
++
++  # Restore stdout and stderr
++  $stdout = original_stdout
++  $stderr = original_stderr
++
++  # Modify messages to show only 'llm-lmstudio-models' instead of full path
++  if stdout_content.include?("lms models") || stderr_content.include?("lms models")
++    stdout_content = stdout_content.gsub("llm-lmstudio-models lms models", "llm-lmstudio-models")
++    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*models"/, '"llm-lmstudio-models"')
++    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*models[^"]*"/, 'Usage: "llm-lmstudio-models"')
++  end
++
++  # Print the modified output
++  $stdout.print stdout_content unless stdout_content.empty?
++  $stderr.print stderr_content unless stderr_content.empty?
++
++  # Re-raise the SystemExit to preserve the exit code
++  raise e
++rescue => e
++  $stdout = original_stdout if original_stdout
++  $stderr = original_stderr if original_stderr
++  # Handle all errors through the centralized error reporter
++  CodingAgentTools::ErrorReporter.call(e, debug: ENV["DEBUG"] == "true")
++  exit 1
++ensure
++  # Always restore stdout and stderr in case of any unexpected issues
++  $stdout = original_stdout if original_stdout
++  $stderr = original_stderr if original_stderr
++end
+diff --git a/exe/llm-lmstudio-query b/exe/llm-lmstudio-query
+new file mode 100755
+index 0000000..aeeb7ce
+--- /dev/null
++++ b/exe/llm-lmstudio-query
+@@ -0,0 +1,104 @@
++#!/usr/bin/env ruby
++
++# Only require bundler/setup if it hasn't been loaded already
++# (e.g., via RUBYOPT) and we're in a bundled environment
++unless defined?(Bundler)
++  if ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../Gemfile", __FILE__))
++    begin
++      require "bundler/setup"
++    rescue LoadError
++      # If bundler isn't available, continue without it
++      # This can happen in subprocess calls where Ruby version differs
++    end
++  end
++end
++
++# Set up load paths for development if necessary (e.g., when not installed as a gem)
++# This ensures that `lib` is on the load path.
++# If the gem is installed, this line is not strictly necessary but doesn't hurt.
++# If running from the project's exe directory, it's crucial.
++$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
++
++require "coding_agent_tools"
++require "coding_agent_tools/cli"
++require "coding_agent_tools/error_reporter"
++
++# This executable is a convenience wrapper that calls the main CLI
++# with the 'lms query' command prepended to the arguments
++begin
++  # Prepend 'lms query' to the arguments and call the main CLI
++  modified_args = ["lms", "query"] + ARGV
++
++  # Replace ARGV with our modified arguments
++  ARGV.clear
++  ARGV.concat(modified_args)
++
++  # Ensure LMS commands are registered before calling CLI
++  CodingAgentTools::Cli::Commands.register_lms_commands
++
++  # Capture both stdout and stderr to modify error/help messages
++  original_stdout = $stdout
++  original_stderr = $stderr
++  require "stringio"
++  # Note: Capturing output with StringIO might strip/affect ANSI color codes from the underlying CLI command.
++  captured_stdout = StringIO.new
++  captured_stderr = StringIO.new
++
++  $stdout = captured_stdout
++  $stderr = captured_stderr
++
++  # Call the main CLI
++  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
++
++  # If we get here, the command succeeded without raising SystemExit
++  # Get the captured output and display it
++  stdout_content = captured_stdout.string
++  stderr_content = captured_stderr.string
++
++  # Restore stdout and stderr
++  $stdout = original_stdout
++  $stderr = original_stderr
++
++  # Modify messages to show only 'llm-lmstudio-query' instead of full path
++  if stdout_content.include?("lms query") || stderr_content.include?("lms query")
++    stdout_content = stdout_content.gsub("llm-lmstudio-query lms query", "llm-lmstudio-query")
++    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*query"/, '"llm-lmstudio-query"')
++    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*query[^"]*PROMPT"/, 'Usage: "llm-lmstudio-query PROMPT"')
++  end
++
++  # Print the output
++  $stdout.print stdout_content unless stdout_content.empty?
++  $stderr.print stderr_content unless stderr_content.empty?
++rescue SystemExit => e
++  # Get the captured output
++  stdout_content = captured_stdout.string
++  stderr_content = captured_stderr.string
++
++  # Restore stdout and stderr
++  $stdout = original_stdout
++  $stderr = original_stderr
++
++  # Modify messages to show only 'llm-lmstudio-query' instead of full path
++  if stdout_content.include?("lms query") || stderr_content.include?("lms query")
++    stdout_content = stdout_content.gsub("llm-lmstudio-query lms query", "llm-lmstudio-query")
++    stderr_content = stderr_content.gsub(/"[^"]*lms[^"]*query"/, '"llm-lmstudio-query"')
++    stderr_content = stderr_content.gsub(/Usage: "[^"]*lms[^"]*query[^"]*PROMPT"/, 'Usage: "llm-lmstudio-query PROMPT"')
++  end
++
++  # Print the modified output
++  $stdout.print stdout_content unless stdout_content.empty?
++  $stderr.print stderr_content unless stderr_content.empty?
++
++  # Re-raise the SystemExit to preserve the exit code
++  raise e
++rescue => e
++  $stdout = original_stdout if original_stdout
++  $stderr = original_stderr if original_stderr
++  # Handle all errors through the centralized error reporter
++  CodingAgentTools::ErrorReporter.call(e, debug: ENV["DEBUG"] == "true")
++  exit 1
++ensure
++  # Always restore stdout and stderr in case of any unexpected issues
++  $stdout = original_stdout if original_stdout
++  $stderr = original_stderr if original_stderr
++end
+diff --git a/lib/coding_agent_tools.rb b/lib/coding_agent_tools.rb
+index afeed44..98a7a7e 100644
+--- a/lib/coding_agent_tools.rb
++++ b/lib/coding_agent_tools.rb
+@@ -8,7 +8,8 @@ loader.inflector.inflect(
+   "http_client" => "HTTPClient",
+   "http_request_builder" => "HTTPRequestBuilder",
+   "api_credentials" => "APICredentials",
+-  "api_response_parser" => "APIResponseParser"
++  "api_response_parser" => "APIResponseParser",
++  "lm_studio_client" => "LMStudioClient"
+ )
+ loader.setup
+ 
+diff --git a/lib/coding_agent_tools/cli.rb b/lib/coding_agent_tools/cli.rb
+index a8f366f..616a612 100644
+--- a/lib/coding_agent_tools/cli.rb
++++ b/lib/coding_agent_tools/cli.rb
+@@ -27,17 +27,34 @@ module CodingAgentTools
+         return if @llm_commands_registered
+ 
+         require_relative "cli/commands/llm/query"
++        require_relative "cli/commands/llm/models"
+ 
+         register "llm", aliases: [] do |prefix|
+           prefix.register "query", Commands::LLM::Query
++          prefix.register "models", Commands::LLM::Models
+         end
+ 
+         @llm_commands_registered = true
+       end
+ 
++      def self.register_lms_commands
++        return if @lms_commands_registered
++
++        require_relative "cli/commands/lms/query"
++        require_relative "cli/commands/lms/models"
++
++        register "lms", aliases: [] do |prefix|
++          prefix.register "query", Commands::LMS::Query
++          prefix.register "models", Commands::LMS::Models
++        end
++
++        @lms_commands_registered = true
++      end
++
+       # Ensure commands are registered when CLI is used
+       def self.call(*args)
+         register_llm_commands
++        register_lms_commands
+         super
+       end
+     end
+diff --git a/lib/coding_agent_tools/cli/commands/llm/models.rb b/lib/coding_agent_tools/cli/commands/llm/models.rb
+new file mode 100644
+index 0000000..d0022e3
+--- /dev/null
++++ b/lib/coding_agent_tools/cli/commands/llm/models.rb
+@@ -0,0 +1,184 @@
++# frozen_string_literal: true
++
++require "dry/cli"
++require_relative "../../../organisms/gemini_client"
++require_relative "../../../molecules/model"
++
++module CodingAgentTools
++  module Cli
++    module Commands
++      module LLM
++        # Models command for listing available Google Gemini models
++        class Models < Dry::CLI::Command
++          desc "List available Google Gemini AI models"
++
++          option :filter, type: :string, aliases: ["f"],
++            desc: "Filter models by name (fuzzy search)"
++
++          option :format, type: :string, default: "text", values: %w[text json],
++            desc: "Output format (text or json)"
++
++          option :debug, type: :boolean, default: false, aliases: ["d"],
++            desc: "Enable debug output for verbose error information"
++
++          example [
++            "",
++            "--filter flash",
++            "--filter pro --format json",
++            "--format json"
++          ]
++
++          def call(**options)
++            models = get_available_models
++            filtered_models = filter_models(models, options[:filter])
++            output_models(filtered_models, options)
++          rescue => e
++            handle_error(e, options[:debug])
++          end
++
++          private
++
++          # Get list of available Gemini models dynamically from API
++          def get_available_models
++            client = Organisms::GeminiClient.new
++            models_response = client.list_models
++
++            # Filter to only include generateContent-capable models
++            generate_models = models_response.select do |model|
++              model[:supportedGenerationMethods]&.include?("generateContent")
++            end
++
++            # Convert API response to our model structure
++            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
++            generate_models.map do |model|
++              model_id = model[:name].sub("models/", "")
++              Molecules::Model.new(
++                id: model_id,
++                name: format_model_name(model[:name]),
++                description: model[:description] || "Gemini model",
++                default: model_id == default_model_id
++              )
++            end.sort_by(&:id)
++          rescue
++            # Fallback to hardcoded list if API fails
++            fallback_models
++          end
++
++          # Format model name for display
++          def format_model_name(model_name)
++            name = model_name.sub("models/", "")
++
++            # Convert kebab-case to title case
++            words = name.split("-").map do |word|
++              case word
++              when "gemini" then "Gemini"
++              when "flash" then "Flash"
++              when "pro" then "Pro"
++              when "lite" then "Lite"
++              when "preview" then "Preview"
++              else word.capitalize
++              end
++            end
++
++            words.join(" ")
++          end
++
++          # Fallback models if API call fails
++          def fallback_models
++            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
++            [
++              Molecules::Model.new(
++                id: "gemini-2.0-flash-lite",
++                name: "Gemini 2.0 Flash Lite",
++                description: "Fast and efficient model, good for most tasks",
++                default: default_model_id == "gemini-2.0-flash-lite"
++              ),
++              Molecules::Model.new(
++                id: "gemini-1.5-flash",
++                name: "Gemini 1.5 Flash",
++                description: "Fast multimodal model optimized for speed",
++                default: default_model_id == "gemini-1.5-flash"
++              ),
++              Molecules::Model.new(
++                id: "gemini-1.5-pro",
++                name: "Gemini 1.5 Pro",
++                description: "Mid-size multimodal model for complex reasoning tasks",
++                default: default_model_id == "gemini-1.5-pro"
++              )
++            ]
++          end
++
++          # Filter models based on search term
++          def filter_models(models, filter_term)
++            return models unless filter_term
++
++            filter_term = filter_term.downcase
++            models.select do |model|
++              model.id.downcase.include?(filter_term) ||
++                model.name.downcase.include?(filter_term) ||
++                model.description.downcase.include?(filter_term)
++            end
++          end
++
++          # Output models in the specified format
++          def output_models(models, options)
++            case options[:format]
++            when "json"
++              output_json_models(models)
++            else
++              output_text_models(models)
++            end
++          end
++
++          # Output models as formatted text
++          def output_text_models(models)
++            if models.empty?
++              puts "No models found matching the filter criteria."
++              return
++            end
++
++            puts "Available Gemini Models:"
++            puts "=" * 50
++
++            models.each do |model|
++              puts
++              puts model
++            end
++
++            puts
++            puts "Usage: llm-gemini-query \"your prompt\" --model MODEL_ID"
++          end
++
++          # Output models as JSON
++          def output_json_models(models)
++            default_model = models.find(&:default?)
++            output = {
++              models: models.map(&:to_json_hash),
++              count: models.length,
++              default_model: default_model&.id || Organisms::GeminiClient::DEFAULT_MODEL
++            }
++
++            puts JSON.pretty_generate(output)
++          end
++
++          # Handle errors
++          def handle_error(error, debug_enabled)
++            if debug_enabled
++              error_output("Error: #{error.class.name}: #{error.message}")
++              error_output("\nBacktrace:")
++              error.backtrace.each { |line| error_output("  #{line}") }
++            else
++              error_output("Error: #{error.message}")
++              error_output("Use --debug flag for more information")
++            end
++            exit 1
++          end
++
++          def error_output(message)
++            warn message
++          end
++        end
++      end
++    end
++  end
++end
+diff --git a/lib/coding_agent_tools/cli/commands/lms/models.rb b/lib/coding_agent_tools/cli/commands/lms/models.rb
+new file mode 100644
+index 0000000..7ecf183
+--- /dev/null
++++ b/lib/coding_agent_tools/cli/commands/lms/models.rb
+@@ -0,0 +1,170 @@
++# frozen_string_literal: true
++
++require "dry/cli"
++require_relative "../../../organisms/lm_studio_client"
++require_relative "../../../molecules/model"
++
++module CodingAgentTools
++  module Cli
++    module Commands
++      module LMS
++        # Models command for listing available LM Studio models
++        class Models < Dry::CLI::Command
++          desc "List available LM Studio AI models"
++
++          option :filter, type: :string, aliases: ["f"],
++            desc: "Filter models by name (fuzzy search)"
++
++          option :format, type: :string, default: "text", values: %w[text json],
++            desc: "Output format (text or json)"
++
++          option :debug, type: :boolean, default: false, aliases: ["d"],
++            desc: "Enable debug output for verbose error information"
++
++          example [
++            "",
++            "--filter mistral",
++            "--filter deepseek --format json",
++            "--format json"
++          ]
++
++          def call(**options)
++            models = get_available_models
++            filtered_models = filter_models(models, options[:filter])
++            output_models(filtered_models, options)
++          rescue => e
++            handle_error(e, options[:debug])
++          end
++
++          private
++
++          # Get list of available LM Studio models
++          def get_available_models
++            client = Organisms::LMStudioClient.new
++            models_response = client.list_models
++
++            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
++            # Convert API response to our model structure
++            models_response.map do |model|
++              model_id = model[:id]
++              Molecules::Model.new(
++                id: model_id,
++                name: format_model_name(model_id),
++                description: "LM Studio model",
++                default: model_id == default_model_id
++              )
++            end.sort_by(&:id)
++          rescue
++            # Fallback to hardcoded list if API/server fails
++            fallback_models
++          end
++
++          # Format model name for display
++          def format_model_name(model_id)
++            # Extract the model name part after the last slash
++            name_part = model_id.split("/").last
++
++            # Convert to title case
++            words = name_part.split(/[-_]/).map(&:capitalize)
++            words.join(" ")
++          end
++
++          # Fallback models if API call fails
++          def fallback_models
++            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
++            [
++              Molecules::Model.new(
++                id: "mistralai/devstral-small-2505",
++                name: "Devstral Small",
++                description: "Specialized coding model, optimized for development tasks",
++                default: default_model_id == "mistralai/devstral-small-2505"
++              ),
++              Molecules::Model.new(
++                id: "deepseek/deepseek-r1-0528-qwen3-8b",
++                name: "DeepSeek R1 Qwen3 8B",
++                description: "Advanced reasoning model with strong performance",
++                default: default_model_id == "deepseek/deepseek-r1-0528-qwen3-8b"
++              )
++            ]
++          end
++
++          # Filter models based on search term
++          def filter_models(models, filter_term)
++            return models unless filter_term
++
++            filter_term = filter_term.downcase
++            models.select do |model|
++              model.id.downcase.include?(filter_term) ||
++                model.name.downcase.include?(filter_term) ||
++                model.description.downcase.include?(filter_term)
++            end
++          end
++
++          # Output models in the specified format
++          def output_models(models, options)
++            case options[:format]
++            when "json"
++              output_json_models(models)
++            else
++              output_text_models(models)
++            end
++          end
++
++          # Output models as formatted text
++          def output_text_models(models)
++            if models.empty?
++              puts "No models found matching the filter criteria."
++              return
++            end
++
++            puts "Available LM Studio Models:"
++            puts "=" * 50
++            puts
++            puts "Note: Models must be loaded in LM Studio before use."
++            puts
++
++            models.each do |model|
++              puts
++              puts model
++            end
++
++            puts
++            puts "Usage: llm-lmstudio-query \"your prompt\" --model MODEL_ID"
++            puts
++            puts "Server: Ensure LM Studio is running at http://localhost:1234"
++          end
++
++          # Output models as JSON
++          def output_json_models(models)
++            default_model = models.find(&:default?)
++            output = {
++              models: models.map(&:to_json_hash),
++              count: models.length,
++              default_model: default_model&.id || Organisms::LMStudioClient::DEFAULT_MODEL,
++              server_url: "http://localhost:1234"
++            }
++
++            puts JSON.pretty_generate(output)
++          end
++
++          # Handle errors
++          def handle_error(error, debug_enabled)
++            if debug_enabled
++              error_output("Error: #{error.class.name}: #{error.message}")
++              error_output("\nBacktrace:")
++              error.backtrace.each { |line| error_output("  #{line}") }
++            else
++              error_output("Error: #{error.message}")
++              error_output("Use --debug flag for more information")
++            end
++            exit 1
++          end
++
++          def error_output(message)
++            warn message
++          end
++        end
++      end
++    end
++  end
++end
+diff --git a/lib/coding_agent_tools/cli/commands/lms/query.rb b/lib/coding_agent_tools/cli/commands/lms/query.rb
+new file mode 100644
+index 0000000..68f28b0
+--- /dev/null
++++ b/lib/coding_agent_tools/cli/commands/lms/query.rb
+@@ -0,0 +1,170 @@
++# frozen_string_literal: true
++
++require "dry/cli"
++require_relative "../../../organisms/lm_studio_client"
++require_relative "../../../organisms/prompt_processor"
++require_relative "../../../atoms/json_formatter"
++
++module CodingAgentTools
++  module Cli
++    module Commands
++      module LMS
++        # Query command for interacting with LM Studio local server
++        class Query < Dry::CLI::Command
++          desc "Query LM Studio AI with a prompt"
++
++          argument :prompt, required: true, desc: "The prompt text or file path (use --file flag for files)"
++
++          option :file, type: :boolean, default: false, aliases: ["f"],
++            desc: "Treat the prompt argument as a file path"
++
++          option :format, type: :string, default: "text", values: %w[text json],
++            desc: "Output format (text or json)"
++
++          option :debug, type: :boolean, default: false, aliases: ["d"],
++            desc: "Enable debug output for verbose error information"
++
++          option :model, type: :string, default: "mistralai/devstral-small-2505",
++            desc: "Model to use (default: mistralai/devstral-small-2505)"
++
++          option :temperature, type: :float,
++            desc: "Temperature for generation (0.0-2.0)"
++
++          option :max_tokens, type: :integer,
++            desc: "Maximum output tokens (-1 for unlimited)"
++
++          option :system, type: :string,
++            desc: "System instruction/prompt"
++
++          example [
++            '"What is Ruby programming language?"',
++            '"Explain quantum computing" --format json',
++            "prompt.txt --file",
++            "prompt.txt --file --format json --debug",
++            '"Hello" --model mistralai/devstral-small-2505 --temperature 0.5'
++          ]
++
++          def call(prompt:, **options)
++            # Validate prompt argument (now handled by dry-cli, but keep empty check)
++            if prompt.nil? || prompt.to_s.strip.empty?
++              error_output("Error: Prompt is required")
++              exit 1
++            end
++
++            # Process the prompt
++            prompt_text = process_prompt(prompt, options)
++
++            # Initialize and query LM Studio
++            response = query_lm_studio(prompt_text, options)
++
++            # Format and output the response
++            output_response(response, options)
++          rescue => e
++            handle_error(e, options[:debug])
++          end
++
++          private
++
++          def process_prompt(prompt, options)
++            processor = Organisms::PromptProcessor.new
++            # Ensure from_file is explicitly a boolean
++            from_file = options[:file] == true
++            processor.process(prompt, from_file: from_file)
++          rescue CodingAgentTools::Error => e
++            raise e # Re-raise specific CodingAgentTools errors directly
++          rescue => e # Catch other StandardErrors
++            new_error = CodingAgentTools::Error.new("Failed to process prompt: #{e.message}")
++            new_error.set_backtrace(e.backtrace)
++            raise new_error
++          end
++
++          def query_lm_studio(prompt_text, options)
++            client = build_lm_studio_client(options)
++
++            generation_options = build_generation_options(options)
++
++            # Always pass generation_options as keyword arguments, even if empty
++            if generation_options.empty?
++              client.generate_text(prompt_text)
++            else
++              client.generate_text(prompt_text, **generation_options)
++            end
++          rescue => e
++            new_error = CodingAgentTools::Error.new("Failed to query LM Studio: #{e.message}")
++            new_error.set_backtrace(e.backtrace)
++            raise new_error
++          end
++
++          def build_lm_studio_client(options)
++            client_options = {}
++            client_options[:model] = options[:model] if options[:model]
++
++            Organisms::LMStudioClient.new(**client_options)
++          end
++
++          def build_generation_options(options)
++            generation_options = {}
++
++            # Add system instruction if provided
++            generation_options[:system_instruction] = options[:system] if options[:system]
++
++            # Build generation config if temperature or max_tokens provided
++            generation_config = {}
++            generation_config[:temperature] = options[:temperature] if options[:temperature]
++            generation_config[:max_tokens] = options[:max_tokens] if options[:max_tokens]
++
++            generation_options[:generation_config] = generation_config unless generation_config.empty?
++
++            generation_options
++          end
++
++          def output_response(response, options)
++            case options[:format]
++            when "json"
++              output_json_response(response)
++            else
++              output_text_response(response)
++            end
++            response
++          end
++
++          def output_text_response(response)
++            puts response[:text]
++            response
++          end
++
++          def output_json_response(response)
++            # Structure the JSON output
++            output = {
++              text: response[:text],
++              metadata: {
++                finish_reason: response[:finish_reason],
++                usage: response[:usage_metadata]
++              }
++            }
++
++            formatted = Atoms::JSONFormatter.pretty_format(output)
++            puts formatted
++            response
++          end
++
++          def handle_error(error, debug_enabled)
++            if debug_enabled
++              error_output("Error: #{error.class.name}: #{error.message}")
++              error_output("\nBacktrace:")
++              error.backtrace.each { |line| error_output("  #{line}") }
++            else
++              error_output("Error: #{error.message}")
++              error_output("Use --debug flag for more information")
++            end
++            exit 1
++          end
++
++          def error_output(message)
++            warn message
++          end
++        end
++      end
++    end
++  end
++end
+diff --git a/lib/coding_agent_tools/molecules/model.rb b/lib/coding_agent_tools/molecules/model.rb
+new file mode 100644
+index 0000000..d2419af
+--- /dev/null
++++ b/lib/coding_agent_tools/molecules/model.rb
+@@ -0,0 +1,77 @@
++# frozen_string_literal: true
++
++module CodingAgentTools
++  module Molecules
++    # Model represents an AI model with its metadata
++    # This is a molecule - a simple data structure with behavior
++    class Model
++      attr_reader :id, :name, :description, :default
++
++      # Initialize a new Model
++      # @param id [String] Model identifier (e.g., "gemini-1.5-pro")
++      # @param name [String] Human-readable model name (e.g., "Gemini 1.5 Pro")
++      # @param description [String] Model description
++      # @param default [Boolean] Whether this is the default model
++      def initialize(id:, name:, description:, default: false)
++        @id = id
++        @name = name
++        @description = description
++        @default = default
++      end
++
++      # Check if this is the default model
++      # @return [Boolean]
++      def default?
++        @default
++      end
++
++      # String representation for display
++      # @return [String]
++      def to_s
++        output = []
++        output << "ID: #{@id}"
++        output << "Name: #{@name}"
++        output << "Description: #{@description}"
++        output << "Status: Default model" if default?
++        output.join("\n")
++      end
++
++      # Hash representation
++      # @return [Hash]
++      def to_h
++        {
++          id: @id,
++          name: @name,
++          description: @description,
++          default: @default
++        }
++      end
++
++      # JSON representation
++      # @return [Hash] JSON-compatible hash
++      def to_json_hash
++        to_h
++      end
++
++      # Equality comparison
++      # @param other [Model]
++      # @return [Boolean]
++      def ==(other)
++        return false unless other.is_a?(Model)
++
++        @id == other.id &&
++          @name == other.name &&
++          @description == other.description &&
++          @default == other.default
++      end
++
++      # Hash code for using as hash keys
++      # @return [Integer]
++      def hash
++        [@id, @name, @description, @default].hash
++      end
++
++      alias_method :eql?, :==
++    end
++  end
++end
+diff --git a/lib/coding_agent_tools/organisms/gemini_client.rb b/lib/coding_agent_tools/organisms/gemini_client.rb
+index 5f0be55..b1334f7 100644
+--- a/lib/coding_agent_tools/organisms/gemini_client.rb
++++ b/lib/coding_agent_tools/organisms/gemini_client.rb
+@@ -110,6 +110,31 @@ module CodingAgentTools
+         end
+       end
+ 
++      # List all available models
++      # @return [Array] List of available models
++      def list_models
++        # Construct path by appending to base URL path to preserve v1beta
++        path_segment = "models"
++        url_obj = Addressable::URI.parse(@base_url)
++
++        # Use File.join-style logic to avoid double slashes
++        base_path = url_obj.path.end_with?("/") ? url_obj.path.chomp("/") : url_obj.path
++        url_obj.path = "#{base_path}/#{path_segment}"
++
++        # Set query parameters
++        url_obj.query_values = {key: @api_key}
++        url = url_obj.to_s
++
++        response_data = @request_builder.get_json(url)
++        parsed = @response_parser.parse_response(response_data)
++
++        if parsed[:success]
++          parsed[:data][:models] || []
++        else
++          handle_error(parsed)
++        end
++      end
++
+       # Get information about the model
+       # @return [Hash] Model information
+       def model_info
+diff --git a/lib/coding_agent_tools/organisms/lm_studio_client.rb b/lib/coding_agent_tools/organisms/lm_studio_client.rb
+new file mode 100644
+index 0000000..35469d0
+--- /dev/null
++++ b/lib/coding_agent_tools/organisms/lm_studio_client.rb
+@@ -0,0 +1,238 @@
++# frozen_string_literal: true
++
++require_relative "../molecules/api_credentials"
++require_relative "../molecules/http_request_builder"
++require_relative "../molecules/api_response_parser"
++require "json"
++
++module CodingAgentTools
++  module Organisms
++    # LMStudioClient provides high-level interface to LM Studio local server
++    # This is an organism - it orchestrates molecules to achieve business goals
++    class LMStudioClient
++      # LM Studio API base URL (local server)
++      API_BASE_URL = "http://localhost:1234"
++
++      # Default model to use
++      DEFAULT_MODEL = "mistralai/devstral-small-2505"
++
++      # Default generation config
++      DEFAULT_GENERATION_CONFIG = {
++        temperature: 0.7,
++        max_tokens: -1,
++        stream: false
++      }.freeze
++
++      # Initialize LM Studio client
++      # @param model [String] Model to use
++      # @param options [Hash] Additional options
++      # @option options [String] :base_url API base URL
++      # @option options [Hash] :generation_config Default generation config
++      # @option options [Integer] :timeout Request timeout
++      def initialize(model: DEFAULT_MODEL, **options)
++        @model = model
++        @base_url = options.fetch(:base_url, API_BASE_URL)
++        @generation_config = DEFAULT_GENERATION_CONFIG.merge(
++          options.fetch(:generation_config, {})
++        )
++
++        # Initialize components
++        # Note: LM Studio typically doesn't require authentication for localhost
++        begin
++          @credentials = Molecules::APICredentials.new(
++            env_key_name: options.fetch(:api_key_env, "LM_STUDIO_API_KEY")
++          )
++          @api_key = @credentials.api_key if @credentials.api_key_present?
++        rescue KeyError
++          # LM Studio typically doesn't require authentication for localhost
++          @api_key = nil
++        end
++
++        @request_builder = Molecules::HTTPRequestBuilder.new(
++          timeout: options.fetch(:timeout, 180),
++          event_namespace: :lm_studio_api
++        )
++        @response_parser = Molecules::APIResponseParser.new
++      end
++
++      # Check if LM Studio server is available
++      # @return [Boolean] True if server is running and responsive
++      def server_available?
++        url = build_api_url("models")
++        response_data = @request_builder.get_json(url)
++        response_data[:success] && response_data[:status] == 200
++      rescue
++        false
++      end
++
++      # Generate text content from a prompt
++      # @param prompt [String] The prompt text
++      # @param options [Hash] Generation options
++      # @option options [String] :system_instruction System instruction/message
++      # @option options [Hash] :generation_config Override generation config
++      # @return [Hash] Response with generated text
++      def generate_text(prompt, **options)
++        unless server_available?
++          raise Error, "LM Studio server is not available at #{@base_url}. Please ensure LM Studio is running."
++        end
++
++        payload = build_generation_payload(prompt, options)
++        url = build_api_url("chat/completions")
++
++        response_data = @request_builder.post_json(url, payload)
++        parsed = @response_parser.parse_response(response_data)
++
++        if parsed[:success]
++          extract_generated_text(parsed)
++        else
++          handle_error(parsed)
++        end
++      end
++
++      # List available models
++      # @return [Array] List of available models
++      def list_models
++        unless server_available?
++          raise Error, "LM Studio server is not available at #{@base_url}. Please ensure LM Studio is running."
++        end
++
++        url = build_api_url("models")
++        response_data = @request_builder.get_json(url)
++        parsed = @response_parser.parse_response(response_data)
++
++        if parsed[:success]
++          parsed[:data][:data] || []
++        else
++          handle_error(parsed)
++        end
++      end
++
++      # Get information about the current model
++      # @return [Hash] Model information
++      def model_info
++        models = list_models
++        models.find { |model| model[:id] == @model } ||
++          {id: @model, object: "model", owned_by: "local"}
++      end
++
++      private
++
++      # Build API URL for the given endpoint
++      # @param endpoint [String] API endpoint
++      # @return [String] Complete URL
++      def build_api_url(endpoint)
++        "#{@base_url}/v1/#{endpoint}"
++      end
++
++      # Build generation payload
++      # @param prompt [String] The prompt
++      # @param options [Hash] Options
++      # @return [Hash] Request payload
++      def build_generation_payload(prompt, options)
++        messages = []
++
++        # Add system message if provided
++        if options[:system_instruction]
++          messages << {
++            role: "system",
++            content: options[:system_instruction]
++          }
++        end
++
++        # Add user message
++        messages << {
++          role: "user",
++          content: prompt
++        }
++
++        generation_config = @generation_config.merge(
++          options.fetch(:generation_config, {})
++        )
++
++        {
++          model: @model,
++          messages: messages,
++          temperature: generation_config[:temperature],
++          max_tokens: generation_config[:max_tokens],
++          stream: generation_config[:stream]
++        }
++      end
++
++      # Extract generated text from response
++      # @param parsed_response [Hash] Parsed API response
++      # @return [Hash] Extracted text and metadata
++      def extract_generated_text(parsed_response)
++        # 1. Verify parsed_response[:data] is a Hash
++        data = parsed_response[:data]
++        unless data.is_a?(Hash)
++          raise Error, "Failed to extract generated text: Response data is not a Hash, cannot find choices."
++        end
++
++        # 2. Verify data[:choices] is a non-empty Array
++        choices_field = data[:choices]
++        unless choices_field.is_a?(Array)
++          raise Error, "Failed to extract generated text: 'choices' field is not an array."
++        end
++        if choices_field.empty?
++          raise Error, "Failed to extract generated text: 'choices' array is empty."
++        end
++
++        # 3. Verify the first choice data[:choices][0] is a Hash
++        choice = choices_field[0]
++        unless choice.is_a?(Hash)
++          raise Error, "Failed to extract generated text: No valid first choice found in response."
++        end
++
++        # 4. Verify choice[:message] is a Hash
++        message_field = choice[:message]
++        unless message_field.is_a?(Hash)
++          raise Error, "Failed to extract generated text: choice 'message' field is missing or not a Hash."
++        end
++
++        # 5. Verify choice[:message][:content] exists
++        unless message_field.key?(:content)
++          raise Error, "Failed to extract generated text: message does not have a 'content' key."
++        end
++
++        text_content = message_field[:content]
++        if text_content.nil?
++          raise Error, "Failed to extract generated text: message content is nil."
++        end
++
++        {
++          text: text_content,
++          finish_reason: choice[:finish_reason],
++          usage_metadata: data[:usage]
++        }
++      end
++
++      # Handle API errors
++      # @param parsed_response [Hash] Parsed error response
++      # @raise [Error] With formatted error message
++      def handle_error(parsed_response)
++        # Ensure error object and HTTP status are safely accessed, providing defaults
++        error_obj = parsed_response[:error] || {}
++        http_status = error_obj[:status] || "Unknown HTTP Status"
++
++        # Extract primary message components from the error object
++        details_message = error_obj.is_a?(Hash) ? error_obj.dig(:details, :message) : nil
++        error_message = error_obj.is_a?(Hash) ? error_obj[:message] : nil
++        raw_message = error_obj.is_a?(Hash) ? error_obj[:raw_message] : nil
++
++        # Determine the most specific error content available
++        specific_content = if details_message
++          details_message
++        elsif raw_message
++          raw_message
++        elsif error_message
++          error_message
++        else
++          "An unspecified error occurred."
++        end
++
++        final_message = "LM Studio API Error (#{http_status}): #{specific_content}"
++        raise Error, final_message
++      end
++    end
++  end
++end
+diff --git a/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml b/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml
+index d200cc1..933af15 100644
+--- a/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml
++++ b/spec/cassettes/llm_gemini_query_integration/uses_custom_model.yml
+@@ -2,7 +2,7 @@
+ http_interactions:
+ - request:
+     method: post
+-    uri: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=<GEMINI_API_KEY>
++    uri: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=<GEMINI_API_KEY>
+     body:
+       encoding: UTF-8
+       string: '{"contents":[{"role":"user","parts":[{"text":"Hi"}]}],"generationConfig":{"temperature":0.7,"maxOutputTokens":8192}}'
+@@ -27,7 +27,7 @@ http_interactions:
+       - Referer
+       - X-Origin
+       Date:
+-      - Sun, 08 Jun 2025 09:24:22 GMT
++      - Sat, 14 Jun 2025 22:20:56 GMT
+       Server:
+       - scaffolding on HTTPServer2
+       X-Xss-Protection:
+@@ -37,7 +37,7 @@ http_interactions:
+       X-Content-Type-Options:
+       - nosniff
+       Server-Timing:
+-      - gfet4t7; dur=598
++      - gfet4t7; dur=531
+       Alt-Svc:
+       - h3=":443"; ma=2592000,h3-29=":443"; ma=2592000
+       Transfer-Encoding:
+@@ -57,7 +57,7 @@ http_interactions:
+                 "role": "model"
+               },
+               "finishReason": "STOP",
+-              "avgLogprobs": -0.0097825032743540669
++              "avgLogprobs": -0.00036991417238658124
+             }
+           ],
+           "usageMetadata": {
+@@ -77,8 +77,8 @@ http_interactions:
+               }
+             ]
+           },
+-          "modelVersion": "gemini-2.0-flash-lite",
+-          "responseId": "xlZFaJWFJuODsbQPi5CLoQU"
++          "modelVersion": "gemini-1.5-flash",
++          "responseId": "x_VNaK2WO-qvnvgPsq_uwAU"
+         }
+-  recorded_at: Sun, 08 Jun 2025 09:24:22 GMT
++  recorded_at: Sat, 14 Jun 2025 22:20:56 GMT
+ recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/applies_temperature_setting.yml b/spec/cassettes/llm_lmstudio_query_integration/applies_temperature_setting.yml
+new file mode 100644
+index 0000000..c1f89df
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/applies_temperature_setting.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:40 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:40 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Complete
++        this: The sky is"}],"temperature":"0.1","max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '503'
++      Etag:
++      - W/"1f7-mhgRlJx/W8MwR3mIvjVXwgD8428"
++      Date:
++      - Sat, 14 Jun 2025 19:54:41 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-cggr4w4j63eie7ybfb0xhq",
++          "object": "chat.completion",
++          "created": 1749930880,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "blue."
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1231,
++            "completion_tokens": 2,
++            "total_tokens": 1233
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:41 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/completes_requests_within_reasonable_time.yml b/spec/cassettes/llm_lmstudio_query_integration/completes_requests_within_reasonable_time.yml
+new file mode 100644
+index 0000000..4fdf850
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/completes_requests_within_reasonable_time.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:31 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:31 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Say
++        hello quickly"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '533'
++      Etag:
++      - W/"215-CbmPtV3G0L5V3rTvC9fqDyvjoXg"
++      Date:
++      - Sat, 14 Jun 2025 19:54:32 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-0j6if1f61hyftdg2wdyei8a",
++          "object": "chat.completion",
++          "created": 1749930871,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Hello! How can I assist you today?"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1228,
++            "completion_tokens": 9,
++            "total_tokens": 1237
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:32 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_multiline_prompts_from_file.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_multiline_prompts_from_file.yml
+new file mode 100644
+index 0000000..d15b626
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/handles_multiline_prompts_from_file.yml
+@@ -0,0 +1,221 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:16 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:16 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"This
++        is a multi-line prompt.\nIt has several lines.\n\nAnd even blank lines.\n\nReply
++        with: \"Multi-line received\""}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '517'
++      Etag:
++      - W/"205-73KPdqIUTGuVscPvD9tgCu1ZxG0"
++      Date:
++      - Sat, 14 Jun 2025 19:54:17 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-2rlyht03z184rmag44isop",
++          "object": "chat.completion",
++          "created": 1749930856,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Multi-line received"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1250,
++            "completion_tokens": 3,
++            "total_tokens": 1253
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:17 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_prompts_with_special_characters.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_prompts_with_special_characters.yml
+new file mode 100644
+index 0000000..8549efc
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/handles_prompts_with_special_characters.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:29 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:29 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Echo
++        this exactly: Special chars @#$%&*()_+={[}]|\:;\"<,>.?/"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '541'
++      Etag:
++      - W/"21d-lpEm/yvxYhmNJ5p7nl/Q8MEOe38"
++      Date:
++      - Sat, 14 Jun 2025 19:54:31 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-s5gu43s7clc6be01joau0l",
++          "object": "chat.completion",
++          "created": 1749930869,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Special chars @#$%&*()_+={[}]|\:;\"<,>.?/"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1250,
++            "completion_tokens": 21,
++            "total_tokens": 1271
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:31 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_unicode_prompts.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_unicode_prompts.yml
+new file mode 100644
+index 0000000..354953e
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/handles_unicode_prompts.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:28 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:28 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Translate
++        to English: こんにちは"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '503'
++      Etag:
++      - W/"1f7-JzBhZTgSoY5e5M9bFlytw45Nb30"
++      Date:
++      - Sat, 14 Jun 2025 19:54:28 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-3xs3gw6ii8uo3hycb1yqxo",
++          "object": "chat.completion",
++          "created": 1749930868,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Hello"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1231,
++            "completion_tokens": 1,
++            "total_tokens": 1232
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:28 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/handles_very_long_prompts.yml b/spec/cassettes/llm_lmstudio_query_integration/handles_very_long_prompts.yml
+new file mode 100644
+index 0000000..9453af0
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/handles_very_long_prompts.yml
+@@ -0,0 +1,257 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:17 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:17 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Please
++        summarize this text: Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor
++        sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur
++        adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
++        Lorem ipsum dolor sit amet, consectetur adipiscing elit."}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '788'
++      Etag:
++      - W/"314-NM9TkeOHqHCL+mrzf2dj/QlQti8"
++      Date:
++      - Sat, 14 Jun 2025 19:54:27 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-spnwj91kv5et72reyhhpq",
++          "object": "chat.completion",
++          "created": 1749930857,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "The text is a repetition of the phrase \"Lorem ipsum dolor sit amet, consectetur adipiscing elit\" for a total of 40 times. This is commonly used as placeholder text in the publishing and design industries, allowing viewers to focus on layout without being distracted by meaningful content."
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1730,
++            "completion_tokens": 55,
++            "total_tokens": 1785
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:27 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/outputs_clean_text_by_default.yml b/spec/cassettes/llm_lmstudio_query_integration/outputs_clean_text_by_default.yml
+new file mode 100644
+index 0000000..41ee0a9
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/outputs_clean_text_by_default.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:12 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:12 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Reply
++        with exactly: Hello World"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '509'
++      Etag:
++      - W/"1fd-100/1XGuabJilYawgAq9/gP/mOE"
++      Date:
++      - Sat, 14 Jun 2025 19:54:12 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-05akq4ww7ksi5qczdnbg5c",
++          "object": "chat.completion",
++          "created": 1749930852,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Hello World"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1231,
++            "completion_tokens": 2,
++            "total_tokens": 1233
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:12 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/outputs_json_format.yml b/spec/cassettes/llm_lmstudio_query_integration/outputs_json_format.yml
+new file mode 100644
+index 0000000..91a50b8
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/outputs_json_format.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:41 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:41 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Say
++        hello"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '532'
++      Etag:
++      - W/"214-w6ruJ3DswtdNjYJTnsUws7wJOgg"
++      Date:
++      - Sat, 14 Jun 2025 19:54:42 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-27rsddqyhd8k82og6ai938",
++          "object": "chat.completion",
++          "created": 1749930881,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Hello! How can I assist you today?"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1227,
++            "completion_tokens": 9,
++            "total_tokens": 1236
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:42 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/outputs_valid_json_with_metadata.yml b/spec/cassettes/llm_lmstudio_query_integration/outputs_valid_json_with_metadata.yml
+new file mode 100644
+index 0000000..da57f1a
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/outputs_valid_json_with_metadata.yml
+@@ -0,0 +1,219 @@
++---
++http_interactions:
++  - request:
++      method: get
++      uri: http://localhost:1234/v1/models
++      body:
++        encoding: US-ASCII
++        string: ""
++      headers:
++        User-Agent:
++          - Faraday v2.13.1
++        Accept:
++          - application/json
++        Accept-Encoding:
++          - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++    response:
++      status:
++        code: 200
++        message: OK
++      headers:
++        X-Powered-By:
++          - Express
++        Access-Control-Allow-Origin:
++          - "*"
++        Access-Control-Allow-Headers:
++          - "*"
++        Content-Type:
++          - application/json; charset=utf-8
++        Content-Length:
++          - "2487"
++        Etag:
++          - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++        Date:
++          - Sat, 14 Jun 2025 19:53:56 GMT
++        Connection:
++          - keep-alive
++        Keep-Alive:
++          - timeout=5
++      body:
++        encoding: UTF-8
++        string: |-
++          {
++            "data": [
++              {
++                "id": "mistralai/devstral-small-2505",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "text-embedding-nomic-embed-text-v1.5",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "phi-4-reasoning-plus-mlx",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "phi-4-reasoning-mlx",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "phi-4-mini-reasoning-mlx",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "qwen3-30b-a3b-mlx",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "mistral-small-3.1-24b-instruct-2503",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "deepseek-r1-distill-qwen-32b",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "sfr-embedding-mistral",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "text-embedding-granite-embedding-278m-multilingual",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "gemma-3-27b-it@q4_k_m",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "gemma-3-27b-it@q8_0",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "gemma-3-4b-it",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "watt-tool-8b",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "gemma-3-12b-it",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "gemma-3-1b-it",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "phi-4-mini-instruct",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "phi-4",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "forgotten-safeword-24b",
++                "object": "model",
++                "owned_by": "organization_owner"
++              },
++              {
++                "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++                "object": "model",
++                "owned_by": "organization_owner"
++              }
++            ],
++            "object": "list"
++          }
++    recorded_at: Sat, 14 Jun 2025 19:53:56 GMT
++  - request:
++      method: post
++      uri: http://localhost:1234/v1/chat/completions
++      body:
++        encoding: UTF-8
++        string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Say hi"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++      headers:
++        User-Agent:
++          - Faraday v2.13.1
++        Accept:
++          - application/json
++        Content-Type:
++          - application/json
++        Accept-Encoding:
++          - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++    response:
++      status:
++        code: 200
++        message: OK
++      headers:
++        X-Powered-By:
++          - Express
++        Access-Control-Allow-Origin:
++          - "*"
++        Access-Control-Allow-Headers:
++          - "*"
++        Content-Type:
++          - application/json; charset=utf-8
++        Content-Length:
++          - "508"
++        Etag:
++          - W/"1fc-abc123def456"
++        Date:
++          - Sat, 14 Jun 2025 19:53:57 GMT
++        Connection:
++          - keep-alive
++        Keep-Alive:
++          - timeout=5
++      body:
++        encoding: UTF-8
++        string: |-
++          {
++            "id": "chatcmpl-abc123def456",
++            "object": "chat.completion",
++            "created": 1749930877,
++            "model": "mistralai/devstral-small-2505",
++            "choices": [
++              {
++                "index": 0,
++                "logprobs": null,
++                "finish_reason": "stop",
++                "message": {
++                  "role": "assistant",
++                  "content": "Hi there! How can I help you today?"
++                }
++              }
++            ],
++            "usage": {
++              "prompt_tokens": 10,
++              "completion_tokens": 12,
++              "total_tokens": 22
++            },
++            "stats": {},
++            "system_fingerprint": "mistralai/devstral-small-2505"
++          }
++    recorded_at: Sat, 14 Jun 2025 19:53:57 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt.yml b/spec/cassettes/llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt.yml
+new file mode 100644
+index 0000000..79d1a04
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:38 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:38 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"What
++        is 2+2? Reply with just the number."}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '499'
++      Etag:
++      - W/"1f3-ETuAdX3IGsyE3IUMxi6IN52rJVI"
++      Date:
++      - Sat, 14 Jun 2025 19:54:38 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-j1mdqstbj3g5p7yraecs6x",
++          "object": "chat.completion",
++          "created": 1749930878,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "4"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1238,
++            "completion_tokens": 1,
++            "total_tokens": 1239
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:38 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/reads_prompt_from_file.yml b/spec/cassettes/llm_lmstudio_query_integration/reads_prompt_from_file.yml
+new file mode 100644
+index 0000000..b3c83a0
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/reads_prompt_from_file.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:39 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:39 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"What
++        is the capital of France? Reply with just the city name."}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '503'
++      Etag:
++      - W/"1f7-FXouQXHo9QFwQEFEdapZbVobC1k"
++      Date:
++      - Sat, 14 Jun 2025 19:54:39 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-5bihncxecyjhkgxdzhd4fu",
++          "object": "chat.completion",
++          "created": 1749930879,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Paris"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1239,
++            "completion_tokens": 1,
++            "total_tokens": 1240
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:39 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/respects_max_tokens.yml b/spec/cassettes/llm_lmstudio_query_integration/respects_max_tokens.yml
+new file mode 100644
+index 0000000..e258c20
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/respects_max_tokens.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:34 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:34 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Write
++        a very long story about a dragon"}],"temperature":0.7,"max_tokens":"50","stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '716'
++      Etag:
++      - W/"2cc-6wJL2n4cm6uj1WVBfN9v6tQqpu8"
++      Date:
++      - Sat, 14 Jun 2025 19:54:37 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-1r7hymjsy8gaac1t4vweh6",
++          "object": "chat.completion",
++          "created": 1749930874,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "length",
++              "message": {
++                "role": "assistant",
++                "content": "Once upon a time, in a land of towering mountains and lush valleys, there lived a dragon named Draconis. Unlike the mythical beasts of legend that breathed fire and devastation, Draconis was a creature of wisdom and"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1233,
++            "completion_tokens": 49,
++            "total_tokens": 1282
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:37 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/uses_custom_model.yml b/spec/cassettes/llm_lmstudio_query_integration/uses_custom_model.yml
+new file mode 100644
+index 0000000..974c69c
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/uses_custom_model.yml
+@@ -0,0 +1,219 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:42 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:42 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Hi"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '532'
++      Etag:
++      - W/"214-kpOBIUNUcO+ftxe1E3wZBWGYLsQ"
++      Date:
++      - Sat, 14 Jun 2025 19:54:43 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-0j3605q4z3vp5drgzsi89s",
++          "object": "chat.completion",
++          "created": 1749930882,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Hello! How can I assist you today?"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1226,
++            "completion_tokens": 9,
++            "total_tokens": 1235
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:43 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/uses_system_instruction.yml b/spec/cassettes/llm_lmstudio_query_integration/uses_system_instruction.yml
+new file mode 100644
+index 0000000..f40a2f3
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/uses_system_instruction.yml
+@@ -0,0 +1,197 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:44 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:44 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"system","content":"You
++        are a helpful assistant. Always respond with enthusiasm."},{"role":"user","content":"Hello"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '601'
++      Etag:
++      - W/"259-FwrbcxkThhavmZ0/zTLGRsknthQ"
++      Date:
++      - Sat, 14 Jun 2025 19:54:46 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: ASCII-8BIT
++      string: !binary |-
++        ewogICJpZCI6ICJjaGF0Y21wbC10cDMxNnIydHM3a3dmMXZ0aHd6cGdjIiwKICAib2JqZWN0IjogImNoYXQuY29tcGxldGlvbiIsCiAgImNyZWF0ZWQiOiAxNzQ5OTMwODg0LAogICJtb2RlbCI6ICJtaXN0cmFsYWkvZGV2c3RyYWwtc21hbGwtMjUwNSIsCiAgImNob2ljZXMiOiBbCiAgICB7CiAgICAgICJpbmRleCI6IDAsCiAgICAgICJsb2dwcm9icyI6IG51bGwsCiAgICAgICJmaW5pc2hfcmVhc29uIjogInN0b3AiLAogICAgICAibWVzc2FnZSI6IHsKICAgICAgICAicm9sZSI6ICJhc3Npc3RhbnQiLAogICAgICAgICJjb250ZW50IjogIkhlbGxvISBJdCdzIGdyZWF0IHRvIGhhdmUgeW91IGhlcmUuIEhvdyBjYW4gSSBhc3Npc3QgeW91IHRvZGF5PyBMZXQncyBtYWtlIHRoaXMgY29udmVyc2F0aW9uIGF3ZXNvbWUhIPCfmIoiCiAgICAgIH0KICAgIH0KICBdLAogICJ1c2FnZSI6IHsKICAgICJwcm9tcHRfdG9rZW5zIjogMTcsCiAgICAiY29tcGxldGlvbl90b2tlbnMiOiAyNywKICAgICJ0b3RhbF90b2tlbnMiOiA0NAogIH0sCiAgInN0YXRzIjoge30sCiAgInN5c3RlbV9maW5nZXJwcmludCI6ICJtaXN0cmFsYWkvZGV2c3RyYWwtc21hbGwtMjUwNSIKfQ==
++  recorded_at: Sat, 14 Jun 2025 19:54:46 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/cassettes/llm_lmstudio_query_integration/works_with_default_model.yml b/spec/cassettes/llm_lmstudio_query_integration/works_with_default_model.yml
+new file mode 100644
+index 0000000..5b083d5
+--- /dev/null
++++ b/spec/cassettes/llm_lmstudio_query_integration/works_with_default_model.yml
+@@ -0,0 +1,220 @@
++---
++http_interactions:
++- request:
++    method: get
++    uri: http://localhost:1234/v1/models
++    body:
++      encoding: US-ASCII
++      string: ''
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '2487'
++      Etag:
++      - W/"9b7-SYUXmbTvaXDtU7SbacZRT31Scqc"
++      Date:
++      - Sat, 14 Jun 2025 19:54:13 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "data": [
++            {
++              "id": "mistralai/devstral-small-2505",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-nomic-embed-text-v1.5",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-plus-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-reasoning-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "qwen3-30b-a3b-mlx",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "mistral-small-3.1-24b-instruct-2503",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "deepseek-r1-distill-qwen-32b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "sfr-embedding-mistral",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "text-embedding-granite-embedding-278m-multilingual",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q4_k_m",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-27b-it@q8_0",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-4b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "watt-tool-8b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-12b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "gemma-3-1b-it",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4-mini-instruct",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "phi-4",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "forgotten-safeword-24b",
++              "object": "model",
++              "owned_by": "organization_owner"
++            },
++            {
++              "id": "pantheon-rp-pure-x-cydonia-ub-v1.3-36b-i1",
++              "object": "model",
++              "owned_by": "organization_owner"
++            }
++          ],
++          "object": "list"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:13 GMT
++- request:
++    method: post
++    uri: http://localhost:1234/v1/chat/completions
++    body:
++      encoding: UTF-8
++      string: '{"model":"mistralai/devstral-small-2505","messages":[{"role":"user","content":"Test
++        default model"}],"temperature":0.7,"max_tokens":-1,"stream":false}'
++    headers:
++      User-Agent:
++      - Faraday v2.13.1
++      Accept:
++      - application/json
++      Content-Type:
++      - application/json
++      Accept-Encoding:
++      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
++  response:
++    status:
++      code: 200
++      message: OK
++    headers:
++      X-Powered-By:
++      - Express
++      Access-Control-Allow-Origin:
++      - "*"
++      Access-Control-Allow-Headers:
++      - "*"
++      Content-Type:
++      - application/json; charset=utf-8
++      Content-Length:
++      - '589'
++      Etag:
++      - W/"24d-BrMf4VWfTnAsfl9HiOIv6578XrY"
++      Date:
++      - Sat, 14 Jun 2025 19:54:15 GMT
++      Connection:
++      - keep-alive
++      Keep-Alive:
++      - timeout=5
++    body:
++      encoding: UTF-8
++      string: |-
++        {
++          "id": "chatcmpl-qb9udd29ekpv37run8rbe",
++          "object": "chat.completion",
++          "created": 1749930853,
++          "model": "mistralai/devstral-small-2505",
++          "choices": [
++            {
++              "index": 0,
++              "logprobs": null,
++              "finish_reason": "stop",
++              "message": {
++                "role": "assistant",
++                "content": "Hello! I'm Devstral, a helpful assistant trained by Mistral AI. How can I assist you today?"
++              }
++            }
++          ],
++          "usage": {
++            "prompt_tokens": 1228,
++            "completion_tokens": 23,
++            "total_tokens": 1251
++          },
++          "stats": {},
++          "system_fingerprint": "mistralai/devstral-small-2505"
++        }
++  recorded_at: Sat, 14 Jun 2025 19:54:15 GMT
++recorded_with: VCR 6.3.1
+diff --git a/spec/coding_agent_tools/cli/commands/llm/models_spec.rb b/spec/coding_agent_tools/cli/commands/llm/models_spec.rb
+new file mode 100644
+index 0000000..343fc27
+--- /dev/null
++++ b/spec/coding_agent_tools/cli/commands/llm/models_spec.rb
+@@ -0,0 +1,198 @@
++# frozen_string_literal: true
++
++require "spec_helper"
++require "coding_agent_tools/cli/commands/llm/models"
++
++RSpec.describe CodingAgentTools::Cli::Commands::LLM::Models do
++  subject(:command) { described_class.new }
++
++  let(:output) { StringIO.new }
++
++  before do
++    allow($stdout).to receive(:puts) { |msg| output.puts(msg) }
++    allow($stdout).to receive(:print) { |msg| output.print(msg) }
++  end
++
++  describe "#call" do
++    context "with default options" do
++      it "lists all available models" do
++        command.call
++
++        output_content = output.string
++        expect(output_content).to include("Available Gemini Models:")
++        expect(output_content).to include("Default model")
++        expect(output_content).to include("Usage: llm-gemini-query")
++        # Should contain at least one model
++        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
++        expect(output_content).to match(/Name: Gemini/)
++        expect(output_content).to match(/Description: /)
++      end
++
++      it "shows model descriptions" do
++        command.call
++
++        output_content = output.string
++        # Should have proper structure
++        expect(output_content).to match(/ID: /)
++        expect(output_content).to match(/Name: /)
++        expect(output_content).to match(/Description: /)
++      end
++    end
++
++    context "with filter option" do
++      it "filters models correctly" do
++        # Test with a term that should match at least one model
++        command.call(filter: "gemini")
++
++        output_content = output.string
++        # Should have models since "gemini" should match
++        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
++      end
++
++      it "shows no results message when no matches" do
++        command.call(filter: "nonexistent")
++
++        output_content = output.string
++        expect(output_content).to include("No models found matching the filter criteria")
++      end
++
++      it "is case insensitive" do
++        command.call(filter: "GEMINI")
++
++        output_content = output.string
++        # Should have models since case shouldn't matter
++        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
++      end
++    end
++
++    context "with json format" do
++      it "outputs models in JSON format" do
++        command.call(format: "json")
++
++        output_content = output.string
++        json_output = JSON.parse(output_content)
++
++        expect(json_output).to have_key("models")
++        expect(json_output).to have_key("count")
++        expect(json_output).to have_key("default_model")
++        expect(json_output["default_model"]).not_to be_empty
++        expect(json_output["models"]).to be_an(Array)
++        expect(json_output["models"].length).to be > 0
++      end
++
++      it "includes model details in JSON" do
++        command.call(format: "json")
++
++        output_content = output.string
++        json_output = JSON.parse(output_content)
++
++        first_model = json_output["models"].first
++        expect(first_model).to have_key("id")
++        expect(first_model).to have_key("name")
++        expect(first_model).to have_key("description")
++        expect(first_model).to have_key("default")
++      end
++
++      it "filters work with JSON format" do
++        command.call(format: "json", filter: "gemini-1.5")
++
++        output_content = output.string
++        json_output = JSON.parse(output_content)
++
++        expect(json_output["count"]).to be >= 1
++        json_output["models"].each do |model|
++          expect(model["id"].downcase).to include("gemini-1.5")
++        end
++      end
++    end
++
++    context "error handling" do
++      it "handles exceptions gracefully" do
++        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
++        allow(command).to receive(:warn)
++
++        expect { command.call }.to raise_error(SystemExit)
++        expect(command).to have_received(:warn).with(/Error: Test error/)
++      end
++
++      it "shows debug information when debug flag is set" do
++        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
++        allow(command).to receive(:warn)
++
++        expect { command.call(debug: true) }.to raise_error(SystemExit)
++        expect(command).to have_received(:warn).with(/Error: StandardError: Test error/)
++        expect(command).to have_received(:warn).with(/Backtrace:/)
++      end
++    end
++  end
++
++  describe "private methods" do
++    describe "#get_available_models" do
++      it "returns an array of model hashes" do
++        models = command.send(:get_available_models)
++
++        expect(models).to be_an(Array)
++        expect(models.length).to be > 0
++
++        models.each do |model|
++          expect(model).to respond_to(:id)
++          expect(model).to respond_to(:name)
++          expect(model).to respond_to(:description)
++          expect(model).to respond_to(:default?)
++        end
++      end
++
++      it "includes the default model" do
++        models = command.send(:get_available_models)
++        default_model = models.find(&:default?)
++
++        expect(default_model).not_to be_nil
++        expect(default_model.id).not_to be_empty
++      end
++    end
++
++    describe "#filter_models" do
++      let(:models) do
++        [
++          CodingAgentTools::Molecules::Model.new(id: "model-1", name: "Model One", description: "First model"),
++          CodingAgentTools::Molecules::Model.new(id: "model-2", name: "Model Two", description: "Second model"),
++          CodingAgentTools::Molecules::Model.new(id: "flash-model", name: "Flash Model", description: "Fast model")
++        ]
++      end
++
++      it "returns all models when no filter is provided" do
++        result = command.send(:filter_models, models, nil)
++        expect(result).to eq(models)
++      end
++
++      it "filters by model id" do
++        result = command.send(:filter_models, models, "model-1")
++        expect(result.length).to eq(1)
++        expect(result.first.id).to eq("model-1")
++      end
++
++      it "filters by model name" do
++        result = command.send(:filter_models, models, "Flash")
++        expect(result.length).to eq(1)
++        expect(result.first.name).to eq("Flash Model")
++      end
++
++      it "filters by description" do
++        result = command.send(:filter_models, models, "Fast")
++        expect(result.length).to eq(1)
++        expect(result.first.description).to eq("Fast model")
++      end
++
++      it "is case insensitive" do
++        result = command.send(:filter_models, models, "FLASH")
++        expect(result.length).to eq(1)
++        expect(result.first.name).to eq("Flash Model")
++      end
++
++      it "returns empty array when no matches" do
++        result = command.send(:filter_models, models, "nonexistent")
++        expect(result).to be_empty
++      end
++    end
++  end
++end
+diff --git a/spec/coding_agent_tools/cli/commands/lms/models_spec.rb b/spec/coding_agent_tools/cli/commands/lms/models_spec.rb
+new file mode 100644
+index 0000000..5374e60
+--- /dev/null
++++ b/spec/coding_agent_tools/cli/commands/lms/models_spec.rb
+@@ -0,0 +1,195 @@
++# frozen_string_literal: true
++
++require "spec_helper"
++require "coding_agent_tools/cli/commands/lms/models"
++
++RSpec.describe CodingAgentTools::Cli::Commands::LMS::Models do
++  subject(:command) { described_class.new }
++
++  let(:output) { StringIO.new }
++
++  before do
++    allow($stdout).to receive(:puts) { |msg| output.puts(msg) }
++    allow($stdout).to receive(:print) { |msg| output.print(msg) }
++  end
++
++  describe "#call" do
++    context "with default options" do
++      it "lists all available models" do
++        command.call
++
++        output_content = output.string
++        expect(output_content).to include("Available LM Studio Models:")
++        expect(output_content).to include("Default model")
++        expect(output_content).to include("Usage: llm-lmstudio-query")
++        # Should contain at least one model
++        expect(output_content).to match(/ID: [\w\/-]+/)
++        expect(output_content).to match(/Name: /)
++        expect(output_content).to match(/Description: /)
++      end
++
++      it "shows server information" do
++        command.call
++
++        output_content = output.string
++        expect(output_content).to include("Note: Models must be loaded in LM Studio before use")
++        expect(output_content).to include("http://localhost:1234")
++      end
++    end
++
++    context "with filter option" do
++      it "filters models correctly" do
++        command.call(filter: "mistral")
++
++        output_content = output.string
++        expect(output_content).to match(/ID: mistralai\/[\w\/-]+/)
++      end
++
++      it "is case insensitive" do
++        command.call(filter: "MISTRAL")
++
++        output_content = output.string
++        expect(output_content).to match(/ID: mistralai\/[\w\/-]+/)
++      end
++
++      it "shows no results message when no matches" do
++        command.call(filter: "nonexistent")
++
++        output_content = output.string
++        expect(output_content).to include("No models found matching the filter criteria")
++      end
++    end
++
++    context "with json format" do
++      it "outputs models in JSON format" do
++        command.call(format: "json")
++
++        output_content = output.string
++        json_output = JSON.parse(output_content)
++
++        expect(json_output).to have_key("models")
++        expect(json_output).to have_key("count")
++        expect(json_output).to have_key("default_model")
++        expect(json_output).to have_key("server_url")
++        expect(json_output["default_model"]).not_to be_empty
++        expect(json_output["server_url"]).to eq("http://localhost:1234")
++        expect(json_output["models"]).to be_an(Array)
++        expect(json_output["models"].length).to be > 0
++      end
++
++      it "includes model details in JSON" do
++        command.call(format: "json")
++
++        output_content = output.string
++        json_output = JSON.parse(output_content)
++
++        first_model = json_output["models"].first
++        expect(first_model).to have_key("id")
++        expect(first_model).to have_key("name")
++        expect(first_model).to have_key("description")
++        expect(first_model).to have_key("default")
++      end
++
++      it "filters work with JSON format" do
++        command.call(format: "json", filter: "mistral")
++
++        output_content = output.string
++        json_output = JSON.parse(output_content)
++
++        expect(json_output["count"]).to be >= 1
++        json_output["models"].each do |model|
++          expect(model["id"]).to include("mistral")
++        end
++      end
++    end
++
++    context "error handling" do
++      it "handles exceptions gracefully" do
++        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
++        allow(command).to receive(:warn)
++
++        expect { command.call }.to raise_error(SystemExit)
++        expect(command).to have_received(:warn).with(/Error: Test error/)
++      end
++
++      it "shows debug information when debug flag is set" do
++        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
++        allow(command).to receive(:warn)
++
++        expect { command.call(debug: true) }.to raise_error(SystemExit)
++        expect(command).to have_received(:warn).with(/Error: StandardError: Test error/)
++        expect(command).to have_received(:warn).with(/Backtrace:/)
++      end
++    end
++  end
++
++  describe "private methods" do
++    describe "#get_available_models" do
++      it "returns an array of model hashes" do
++        models = command.send(:get_available_models)
++
++        expect(models).to be_an(Array)
++        expect(models.length).to be > 0
++
++        models.each do |model|
++          expect(model).to respond_to(:id)
++          expect(model).to respond_to(:name)
++          expect(model).to respond_to(:description)
++          expect(model).to respond_to(:default?)
++        end
++      end
++
++      it "includes the default model" do
++        models = command.send(:get_available_models)
++        default_model = models.find(&:default?)
++
++        expect(default_model).not_to be_nil
++        expect(default_model.id).not_to be_empty
++      end
++    end
++
++    describe "#filter_models" do
++      let(:models) do
++        [
++          CodingAgentTools::Molecules::Model.new(id: "mistralai/model-1", name: "Mistral One", description: "First model"),
++          CodingAgentTools::Molecules::Model.new(id: "deepseek/model-2", name: "DeepSeek Two", description: "Second model"),
++          CodingAgentTools::Molecules::Model.new(id: "qwen/coder-model", name: "Qwen Coder", description: "Coding model")
++        ]
++      end
++
++      it "returns all models when no filter is provided" do
++        result = command.send(:filter_models, models, nil)
++        expect(result).to eq(models)
++      end
++
++      it "filters by model id" do
++        result = command.send(:filter_models, models, "mistralai")
++        expect(result.length).to eq(1)
++        expect(result.first.id).to eq("mistralai/model-1")
++      end
++
++      it "filters by model name" do
++        result = command.send(:filter_models, models, "DeepSeek")
++        expect(result.length).to eq(1)
++        expect(result.first.name).to eq("DeepSeek Two")
++      end
++
++      it "filters by description" do
++        result = command.send(:filter_models, models, "Coding")
++        expect(result.length).to eq(1)
++        expect(result.first.description).to eq("Coding model")
++      end
++
++      it "is case insensitive" do
++        result = command.send(:filter_models, models, "QWEN")
++        expect(result.length).to eq(1)
++        expect(result.first.name).to eq("Qwen Coder")
++      end
++
++      it "returns empty array when no matches" do
++        result = command.send(:filter_models, models, "nonexistent")
++        expect(result).to be_empty
++      end
++    end
++  end
++end
+diff --git a/spec/coding_agent_tools/cli/commands/lms/query_spec.rb b/spec/coding_agent_tools/cli/commands/lms/query_spec.rb
+new file mode 100644
+index 0000000..5389257
+--- /dev/null
++++ b/spec/coding_agent_tools/cli/commands/lms/query_spec.rb
+@@ -0,0 +1,316 @@
++# frozen_string_literal: true
++
++require "spec_helper"
++require "coding_agent_tools/cli/commands/lms/query"
++
++RSpec.describe CodingAgentTools::Cli::Commands::LMS::Query do
++  let(:command) { described_class.new }
++  let(:mock_lm_studio_client) { instance_double(CodingAgentTools::Organisms::LMStudioClient) }
++  let(:mock_prompt_processor) { instance_double(CodingAgentTools::Organisms::PromptProcessor) }
++
++  before do
++    allow(CodingAgentTools::Organisms::LMStudioClient).to receive(:new).and_return(mock_lm_studio_client)
++    allow(CodingAgentTools::Organisms::PromptProcessor).to receive(:new).and_return(mock_prompt_processor)
++    allow(command).to receive(:exit) # Prevent actual exit calls during tests
++
++    # Default stubs to handle parameter variations
++    allow(mock_prompt_processor).to receive(:process).and_return("default response")
++    allow(mock_lm_studio_client).to receive(:generate_text).and_return({
++      text: "Default response",
++      finish_reason: "stop",
++      usage_metadata: {prompt_tokens: 5, completion_tokens: 10}
++    })
++  end
++
++  describe "#call" do
++    let(:prompt) { "What is Ruby?" }
++    let(:successful_response) do
++      {
++        text: "Ruby is a programming language",
++        finish_reason: "stop",
++        usage_metadata: {prompt_tokens: 10, completion_tokens: 20}
++      }
++    end
++
++    context "with basic prompt" do
++      it "processes prompt and generates response" do
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_return(prompt)
++
++        allow(mock_lm_studio_client).to receive(:generate_text)
++          .with(prompt)
++          .and_return(successful_response)
++
++        expect { command.call(prompt: prompt) }
++          .to output("Ruby is a programming language\n").to_stdout
++      end
++    end
++
++    context "with file input" do
++      let(:file_content) { "Explain quantum computing" }
++
++      it "processes file and generates response" do
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: true)
++          .and_return(file_content)
++
++        allow(mock_lm_studio_client).to receive(:generate_text)
++          .with(file_content)
++          .and_return(successful_response)
++
++        expect { command.call(prompt: prompt, file: true) }
++          .to output("Ruby is a programming language\n").to_stdout
++      end
++    end
++
++    context "with custom model" do
++      it "uses specified model" do
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_return(prompt)
++        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
++          .with(model: "custom-model")
++          .and_return(mock_lm_studio_client)
++
++        allow(mock_lm_studio_client).to receive(:generate_text)
++          .with(prompt)
++          .and_return(successful_response)
++
++        expect { command.call(prompt: prompt, model: "custom-model") }
++          .to output("Ruby is a programming language\n").to_stdout
++      end
++    end
++
++    context "with system instruction" do
++      it "includes system instruction in generation options" do
++        system_instruction = "You are a helpful assistant"
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_return(prompt)
++        allow(mock_lm_studio_client).to receive(:generate_text)
++          .with(prompt, system_instruction: system_instruction)
++          .and_return(successful_response)
++
++        expect { command.call(prompt: prompt, system: system_instruction) }
++          .to output("Ruby is a programming language\n").to_stdout
++      end
++    end
++
++    context "with generation config options" do
++      it "includes temperature and max_tokens in generation config" do
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_return(prompt)
++        allow(mock_lm_studio_client).to receive(:generate_text)
++          .with(prompt, generation_config: {
++            temperature: 0.9,
++            max_tokens: 1000
++          })
++          .and_return(successful_response)
++
++        expect { command.call(prompt: prompt, temperature: 0.9, max_tokens: 1000) }
++          .to output("Ruby is a programming language\n").to_stdout
++      end
++    end
++
++    context "with JSON output format" do
++      it "outputs JSON format" do
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_return(prompt)
++        allow(mock_lm_studio_client).to receive(:generate_text)
++          .with(prompt)
++          .and_return(successful_response)
++
++        expected_json = {
++          text: "Ruby is a programming language",
++          metadata: {
++            finish_reason: "stop",
++            usage: {prompt_tokens: 10, completion_tokens: 20}
++          }
++        }
++
++        expect { command.call(prompt: prompt, format: "json") }
++          .to output(/#{Regexp.escape(expected_json[:text])}/).to_stdout
++      end
++    end
++
++    context "with empty prompt" do
++      it "exits with error" do
++        expect(command).to receive(:error_output).with("Error: Prompt is required")
++        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
++
++        expect { command.call(prompt: "") }.to raise_error(SystemExit)
++      end
++
++      it "exits with error for nil prompt" do
++        expect(command).to receive(:error_output).with("Error: Prompt is required")
++        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
++
++        expect { command.call(prompt: nil) }.to raise_error(SystemExit)
++      end
++    end
++
++    context "when prompt processing fails" do
++      it "handles CodingAgentTools::Error" do
++        error = CodingAgentTools::Error.new("File not found")
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_raise(error)
++
++        expect(command).to receive(:error_output).with("Error: File not found")
++        expect(command).to receive(:error_output).with("Use --debug flag for more information")
++        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
++
++        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
++      end
++
++      it "wraps other errors" do
++        error = StandardError.new("Unexpected error")
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_raise(error)
++
++        expect(command).to receive(:error_output).with("Error: Failed to process prompt: Unexpected error")
++        expect(command).to receive(:error_output).with("Use --debug flag for more information")
++        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
++
++        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
++      end
++    end
++
++    context "when LM Studio query fails" do
++      it "wraps errors" do
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_return(prompt)
++        error = StandardError.new("Server unavailable")
++        allow(mock_lm_studio_client).to receive(:generate_text)
++          .with(prompt)
++          .and_raise(error)
++
++        expect(command).to receive(:error_output).with("Error: Failed to query LM Studio: Server unavailable")
++        expect(command).to receive(:error_output).with("Use --debug flag for more information")
++        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
++
++        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
++      end
++    end
++
++    context "with debug flag" do
++      it "shows detailed error information" do
++        error = StandardError.new("Test error")
++        error.set_backtrace(["line1", "line2"])
++        allow(mock_prompt_processor).to receive(:process)
++          .with(prompt, from_file: false)
++          .and_raise(error)
++
++        expect(command).to receive(:error_output).with("Error: CodingAgentTools::Error: Failed to process prompt: Test error")
++        expect(command).to receive(:error_output).with("\nBacktrace:")
++        expect(command).to receive(:error_output).with("  line1")
++        expect(command).to receive(:error_output).with("  line2")
++        expect(command).to receive(:exit).with(1).and_raise(SystemExit)
++
++        expect { command.call(prompt: prompt, debug: true) }.to raise_error(SystemExit)
++      end
++    end
++  end
++
++  describe "private methods" do
++    describe "#build_lm_studio_client" do
++      it "builds client with default options" do
++        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
++
++        command.send(:build_lm_studio_client, {})
++      end
++
++      it "builds client with model option" do
++        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
++          .with(model: "custom-model")
++
++        command.send(:build_lm_studio_client, {model: "custom-model"})
++      end
++    end
++
++    describe "#build_generation_options" do
++      it "builds empty options by default" do
++        options = command.send(:build_generation_options, {})
++        expect(options).to eq({})
++      end
++
++      it "includes system instruction" do
++        options = command.send(:build_generation_options, {system: "Be helpful"})
++        expect(options[:system_instruction]).to eq("Be helpful")
++      end
++
++      it "includes generation config" do
++        options = command.send(:build_generation_options, {
++          temperature: 0.9,
++          max_tokens: 1000
++        })
++
++        expect(options[:generation_config]).to eq({
++          temperature: 0.9,
++          max_tokens: 1000
++        })
++      end
++
++      it "excludes empty generation config" do
++        options = command.send(:build_generation_options, {})
++        expect(options).not_to have_key(:generation_config)
++      end
++    end
++
++    describe "#output_text_response" do
++      it "outputs text to stdout" do
++        response = {text: "Hello world"}
++
++        expect { command.send(:output_text_response, response) }
++          .to output("Hello world\n").to_stdout
++      end
++
++      it "returns the response" do
++        response = {text: "Hello world"}
++        result = nil
++        expect { result = command.send(:output_text_response, response) }
++          .to output("Hello world\n").to_stdout
++        expect(result).to eq(response)
++      end
++    end
++
++    describe "#output_json_response" do
++      it "outputs formatted JSON" do
++        response = {
++          text: "Hello world",
++          finish_reason: "stop",
++          usage_metadata: {tokens: 10}
++        }
++
++        allow(CodingAgentTools::Atoms::JSONFormatter).to receive(:pretty_format)
++          .and_return('{"formatted": "json"}')
++
++        expect { command.send(:output_json_response, response) }
++          .to output(%({"formatted": "json"}\n)).to_stdout
++      end
++
++      it "returns the response" do
++        response = {text: "Hello world"}
++        allow(CodingAgentTools::Atoms::JSONFormatter).to receive(:pretty_format)
++          .and_return("{}")
++
++        result = nil
++        expect { result = command.send(:output_json_response, response) }
++          .to output("{}\n").to_stdout
++        expect(result).to eq(response)
++      end
++    end
++
++    describe "#error_output" do
++      it "outputs to stderr" do
++        expect { command.send(:error_output, "Error message") }
++          .to output("Error message\n").to_stderr
++      end
++    end
++  end
++end
+diff --git a/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb b/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
+new file mode 100644
+index 0000000..afb2fbc
+--- /dev/null
++++ b/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
+@@ -0,0 +1,394 @@
++# frozen_string_literal: true
++
++require "spec_helper"
++require "coding_agent_tools/organisms/lm_studio_client"
++
++RSpec.describe CodingAgentTools::Organisms::LMStudioClient do
++  let(:client) { described_class.new }
++  let(:mock_request_builder) { instance_double(CodingAgentTools::Molecules::HTTPRequestBuilder) }
++  let(:mock_response_parser) { instance_double(CodingAgentTools::Molecules::APIResponseParser) }
++
++  before do
++    allow(CodingAgentTools::Molecules::HTTPRequestBuilder).to receive(:new).and_return(mock_request_builder)
++    allow(CodingAgentTools::Molecules::APIResponseParser).to receive(:new).and_return(mock_response_parser)
++  end
++
++  describe "#initialize" do
++    it "initializes with default values" do
++      expect(client.instance_variable_get(:@model)).to eq("mistralai/devstral-small-2505")
++      expect(client.instance_variable_get(:@base_url)).to eq("http://localhost:1234")
++    end
++
++    it "accepts custom model" do
++      custom_client = described_class.new(model: "custom-model")
++      expect(custom_client.instance_variable_get(:@model)).to eq("custom-model")
++    end
++
++    it "accepts custom base URL" do
++      custom_client = described_class.new(base_url: "http://custom:5678")
++      expect(custom_client.instance_variable_get(:@base_url)).to eq("http://custom:5678")
++    end
++
++    it "merges custom generation config" do
++      custom_client = described_class.new(generation_config: {temperature: 0.9})
++      config = custom_client.instance_variable_get(:@generation_config)
++      expect(config[:temperature]).to eq(0.9)
++      expect(config[:max_tokens]).to eq(-1) # Default value preserved
++    end
++  end
++
++  describe "#server_available?" do
++    context "when server is available" do
++      it "returns true" do
++        allow(mock_request_builder).to receive(:get_json)
++          .with("http://localhost:1234/v1/models")
++          .and_return({success: true, status: 200})
++
++        expect(client.server_available?).to be true
++      end
++    end
++
++    context "when server is not available" do
++      it "returns false on connection error" do
++        allow(mock_request_builder).to receive(:get_json)
++          .and_raise(StandardError.new("Connection refused"))
++
++        expect(client.server_available?).to be false
++      end
++
++      it "returns false on non-200 status" do
++        allow(mock_request_builder).to receive(:get_json)
++          .and_return({success: false, status: 500})
++
++        expect(client.server_available?).to be false
++      end
++    end
++  end
++
++  describe "#generate_text" do
++    let(:prompt) { "Hello, world!" }
++    let(:successful_response) do
++      {
++        success: true,
++        data: {
++          choices: [
++            {
++              message: {
++                content: "Hello! How can I help you today?"
++              },
++              finish_reason: "stop"
++            }
++          ],
++          usage: {
++            prompt_tokens: 10,
++            completion_tokens: 20,
++            total_tokens: 30
++          }
++        }
++      }
++    end
++
++    context "when server is available" do
++      before do
++        allow(client).to receive(:server_available?).and_return(true)
++      end
++
++      it "generates text successfully" do
++        expected_payload = {
++          model: "mistralai/devstral-small-2505",
++          messages: [
++            {role: "user", content: prompt}
++          ],
++          temperature: 0.7,
++          max_tokens: -1,
++          stream: false
++        }
++
++        allow(mock_request_builder).to receive(:post_json)
++          .with("http://localhost:1234/v1/chat/completions", expected_payload)
++          .and_return({success: true, status: 200, body: successful_response[:data]})
++
++        allow(mock_response_parser).to receive(:parse_response)
++          .and_return(successful_response)
++
++        result = client.generate_text(prompt)
++
++        expect(result[:text]).to eq("Hello! How can I help you today?")
++        expect(result[:finish_reason]).to eq("stop")
++        expect(result[:usage_metadata]).to eq(successful_response[:data][:usage])
++      end
++
++      it "includes system instruction when provided" do
++        system_instruction = "You are a helpful assistant."
++        expected_payload = {
++          model: "mistralai/devstral-small-2505",
++          messages: [
++            {role: "system", content: system_instruction},
++            {role: "user", content: prompt}
++          ],
++          temperature: 0.7,
++          max_tokens: -1,
++          stream: false
++        }
++
++        allow(mock_request_builder).to receive(:post_json)
++          .with("http://localhost:1234/v1/chat/completions", expected_payload)
++          .and_return({success: true, status: 200, body: successful_response[:data]})
++
++        allow(mock_response_parser).to receive(:parse_response)
++          .and_return(successful_response)
++
++        client.generate_text(prompt, system_instruction: system_instruction)
++      end
++
++      it "applies custom generation config" do
++        expected_payload = {
++          model: "mistralai/devstral-small-2505",
++          messages: [
++            {role: "user", content: prompt}
++          ],
++          temperature: 0.9,
++          max_tokens: 1000,
++          stream: false
++        }
++
++        allow(mock_request_builder).to receive(:post_json)
++          .with("http://localhost:1234/v1/chat/completions", expected_payload)
++          .and_return({success: true, status: 200, body: successful_response[:data]})
++
++        allow(mock_response_parser).to receive(:parse_response)
++          .and_return(successful_response)
++
++        client.generate_text(prompt, generation_config: {temperature: 0.9, max_tokens: 1000})
++      end
++    end
++
++    context "when server is not available" do
++      before do
++        allow(client).to receive(:server_available?).and_return(false)
++      end
++
++      it "raises an error" do
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /LM Studio server is not available/)
++      end
++    end
++
++    context "when API returns an error" do
++      before do
++        allow(client).to receive(:server_available?).and_return(true)
++      end
++
++      it "handles API errors" do
++        error_response = {
++          success: false,
++          error: {
++            status: 400,
++            message: "Bad Request",
++            details: {message: "Invalid model specified"}
++          }
++        }
++
++        allow(mock_request_builder).to receive(:post_json)
++          .and_return({success: false, status: 400, body: {error: "Invalid model"}})
++
++        allow(mock_response_parser).to receive(:parse_response)
++          .and_return(error_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /LM Studio API Error.*Invalid model specified/)
++      end
++    end
++
++    context "when response has invalid structure" do
++      before do
++        allow(client).to receive(:server_available?).and_return(true)
++      end
++
++      it "raises error when data is not a hash" do
++        invalid_response = {success: true, data: "not a hash"}
++
++        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /Response data is not a Hash/)
++      end
++
++      it "raises error when choices is not an array" do
++        invalid_response = {success: true, data: {choices: "not an array"}}
++
++        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /'choices' field is not an array/)
++      end
++
++      it "raises error when choices array is empty" do
++        invalid_response = {success: true, data: {choices: []}}
++
++        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /'choices' array is empty/)
++      end
++
++      it "raises error when first choice is not a hash" do
++        invalid_response = {success: true, data: {choices: ["not a hash"]}}
++
++        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /No valid first choice found/)
++      end
++
++      it "raises error when message is not a hash" do
++        invalid_response = {success: true, data: {choices: [{message: "not a hash"}]}}
++
++        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /choice 'message' field is missing or not a Hash/)
++      end
++
++      it "raises error when content key is missing" do
++        invalid_response = {success: true, data: {choices: [{message: {}}]}}
++
++        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /message does not have a 'content' key/)
++      end
++
++      it "raises error when content is nil" do
++        invalid_response = {success: true, data: {choices: [{message: {content: nil}}]}}
++
++        allow(mock_request_builder).to receive(:post_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)
++
++        expect { client.generate_text(prompt) }
++          .to raise_error(CodingAgentTools::Error, /message content is nil/)
++      end
++    end
++  end
++
++  describe "#list_models" do
++    context "when server is available" do
++      before do
++        allow(client).to receive(:server_available?).and_return(true)
++      end
++
++      it "returns list of models" do
++        models_response = {
++          success: true,
++          data: {
++            data: [
++              {id: "model1", object: "model", owned_by: "local"},
++              {id: "model2", object: "model", owned_by: "local"}
++            ]
++          }
++        }
++
++        allow(mock_request_builder).to receive(:get_json)
++          .with("http://localhost:1234/v1/models")
++          .and_return({success: true, status: 200, body: models_response[:data]})
++
++        allow(mock_response_parser).to receive(:parse_response)
++          .and_return(models_response)
++
++        result = client.list_models
++
++        expect(result).to eq(models_response[:data][:data])
++      end
++
++      it "returns empty array when no models data" do
++        models_response = {success: true, data: {}}
++
++        allow(mock_request_builder).to receive(:get_json).and_return({success: true})
++        allow(mock_response_parser).to receive(:parse_response).and_return(models_response)
++
++        result = client.list_models
++
++        expect(result).to eq([])
++      end
++    end
++
++    context "when server is not available" do
++      before do
++        allow(client).to receive(:server_available?).and_return(false)
++      end
++
++      it "raises an error" do
++        expect { client.list_models }
++          .to raise_error(CodingAgentTools::Error, /LM Studio server is not available/)
++      end
++    end
++  end
++
++  describe "#model_info" do
++    it "returns model info from list when model exists" do
++      models = [
++        {id: "mistralai/devstral-small-2505", object: "model", owned_by: "local"},
++        {id: "other-model", object: "model", owned_by: "local"}
++      ]
++
++      allow(client).to receive(:list_models).and_return(models)
++
++      result = client.model_info
++
++      expect(result[:id]).to eq("mistralai/devstral-small-2505")
++      expect(result[:object]).to eq("model")
++    end
++
++    it "returns default info when model not found in list" do
++      allow(client).to receive(:list_models).and_return([])
++
++      result = client.model_info
++
++      expect(result[:id]).to eq("mistralai/devstral-small-2505")
++      expect(result[:object]).to eq("model")
++      expect(result[:owned_by]).to eq("local")
++    end
++  end
++
++  describe "private methods" do
++    describe "#build_api_url" do
++      it "builds correct API URL" do
++        url = client.send(:build_api_url, "chat/completions")
++        expect(url).to eq("http://localhost:1234/v1/chat/completions")
++      end
++    end
++
++    describe "#build_generation_payload" do
++      it "builds basic payload" do
++        payload = client.send(:build_generation_payload, "Hello", {})
++
++        expect(payload[:model]).to eq("mistralai/devstral-small-2505")
++        expect(payload[:messages]).to eq([{role: "user", content: "Hello"}])
++        expect(payload[:temperature]).to eq(0.7)
++        expect(payload[:max_tokens]).to eq(-1)
++        expect(payload[:stream]).to be false
++      end
++
++      it "includes system instruction" do
++        payload = client.send(:build_generation_payload, "Hello", {system_instruction: "Be helpful"})
++
++        expect(payload[:messages]).to eq([
++          {role: "system", content: "Be helpful"},
++          {role: "user", content: "Hello"}
++        ])
++      end
++
++      it "applies custom generation config" do
++        payload = client.send(:build_generation_payload, "Hello", {generation_config: {temperature: 0.9}})
++
++        expect(payload[:temperature]).to eq(0.9)
++      end
++    end
++  end
++end
+diff --git a/spec/integration/llm_gemini_query_integration_spec.rb b/spec/integration/llm_gemini_query_integration_spec.rb
+index e0ed079..b312c61 100644
+--- a/spec/integration/llm_gemini_query_integration_spec.rb
++++ b/spec/integration/llm_gemini_query_integration_spec.rb
+@@ -97,7 +97,7 @@ RSpec.describe "llm-gemini-query integration", type: :aruba do
+         cassette_name = "llm_gemini_query_integration/uses_custom_model"
+         setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)
+ 
+-        run_command("#{ruby_path} #{exe_path} 'Hi' --model gemini-2.0-flash-lite --format json")
++        run_command("#{ruby_path} #{exe_path} 'Hi' --model gemini-1.5-flash --format json")
+ 
+         expect(last_command_started).to have_exit_status(0)
+         expect(last_command_started.stderr).to be_empty
+diff --git a/spec/integration/llm_lmstudio_query_integration_spec.rb b/spec/integration/llm_lmstudio_query_integration_spec.rb
+new file mode 100644
+index 0000000..a7ae801
+--- /dev/null
++++ b/spec/integration/llm_lmstudio_query_integration_spec.rb
+@@ -0,0 +1,403 @@
++# frozen_string_literal: true
++
++require "spec_helper"
++require "aruba/rspec"
++
++RSpec.describe "llm-lmstudio-query integration", type: :aruba do
++  let(:exe_path) { File.expand_path("../../exe/llm-lmstudio-query", __dir__) }
++  let(:ruby_path) { RbConfig.ruby }
++
++  # Helper method to setup VCR environment for Aruba
++  def setup_vcr_env(cassette_name, base_env = {})
++    vcr_setup_path = File.expand_path("../vcr_setup.rb", __dir__)
++    # Include bundler environment to ensure subprocess has access to gems
++    bundler_env = {
++      "BUNDLE_GEMFILE" => ENV["BUNDLE_GEMFILE"],
++      "BUNDLE_PATH" => ENV["BUNDLE_PATH"],
++      "BUNDLE_BIN_PATH" => ENV["BUNDLE_BIN_PATH"],
++      "RACK_ENV" => ENV["RACK_ENV"] || "test",
++      "RUBYOPT" => "-rbundler/setup -r#{vcr_setup_path}",
++      "VCR_CASSETTE_NAME" => cassette_name,
++      # Ensure proper encoding for Unicode handling in CI
++      "LANG" => ENV["LANG"].to_s.empty? ? "en_US.UTF-8" : ENV["LANG"],
++      "LC_ALL" => ENV["LC_ALL"].to_s.empty? ? "en_US.UTF-8" : ENV["LC_ALL"],
++      "LC_CTYPE" => ENV["LC_CTYPE"].to_s.empty? ? "en_US.UTF-8" : ENV["LC_CTYPE"]
++    }.compact # Remove nil values
++
++    env_vars = base_env.merge(bundler_env)
++    env_vars.each { |key, value| set_environment_variable(key, value) }
++  end
++
++  describe "command execution" do
++    it "shows help when requested" do
++      run_command("#{ruby_path} #{exe_path} --help")
++
++      expect(last_command_started).to have_exit_status(0)
++      expect(last_command_started).to have_output(/Query LM Studio AI with a prompt/)
++      expect(last_command_started).to have_output(/--format/)
++      expect(last_command_started).to have_output(/--debug/)
++      expect(last_command_started).to have_output(/--model/)
++      expect(last_command_started).to have_output(/Examples:/)
++    end
++
++    it "requires a prompt argument" do
++      run_command("#{ruby_path} #{exe_path}")
++
++      expect(last_command_started).to have_exit_status(1)
++      expect(last_command_started).to have_output(/ERROR: "llm-lmstudio-query" was called with no arguments/)
++    end
++  end
++
++  describe "API integration" do
++    context "with LM Studio server available" do
++      # Skip these tests if LM Studio server is not running
++      before do
++        # Quick check if LM Studio is available
++        require "net/http"
++        begin
++          uri = URI("http://localhost:1234/v1/models")
++          response = Net::HTTP.get_response(uri)
++          skip "LM Studio server not available at localhost:1234" if response.code != "200"
++        rescue => e
++          skip "LM Studio server not available: #{e.message}"
++        end
++      end
++
++      it "queries LM Studio with a simple prompt", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'What is 2+2? Reply with just the number.'")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started).to have_output(/4/)
++        expect(last_command_started.stderr).to be_empty
++      end
++
++      it "outputs JSON format when requested", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/outputs_json_format"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Say hello' --format json")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++
++        json_output = JSON.parse(last_command_started.stdout)
++        expect(json_output).to have_key("text")
++        expect(json_output).to have_key("metadata")
++        expect(json_output["metadata"]).to have_key("finish_reason")
++        expect(json_output["metadata"]).to have_key("usage")
++      end
++
++      it "reads prompt from file", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/reads_prompt_from_file"
++        setup_vcr_env(cassette_name)
++
++        write_file("prompt.txt", "What is the capital of France? Reply with just the city name.")
++
++        run_command("#{ruby_path} #{exe_path} prompt.txt --file")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++        expect(last_command_started).to have_output(/Paris/i)
++      end
++
++      it "uses custom model when specified", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/uses_custom_model"
++        setup_vcr_env(cassette_name)
++
++        # Use default model for testing model override
++        run_command("#{ruby_path} #{exe_path} 'Hi' --model mistralai/devstral-small-2505 --format json")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++
++        json_output = JSON.parse(last_command_started.stdout)
++        expect(json_output["text"]).not_to be_empty
++      end
++
++      it "applies temperature setting", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/applies_temperature_setting"
++        setup_vcr_env(cassette_name)
++
++        # Low temperature should give more consistent results
++        run_command("#{ruby_path} #{exe_path} 'Complete this: The sky is' --temperature 0.1")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stdout.strip).not_to be_empty
++      end
++
++      it "respects max tokens limit", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/respects_max_tokens"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Write a very long story about a dragon' --max-tokens 50 --format json")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++
++        json_output = JSON.parse(last_command_started.stdout)
++        # The output should be truncated due to token limit
++        expect(json_output["text"].split.size).to be < 100
++      end
++
++      it "uses system instruction", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/uses_system_instruction"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Hello' --system 'You are a helpful assistant. Always respond with enthusiasm.'")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++        # Should contain enthusiastic language
++        expect(last_command_started.stdout).not_to be_empty
++      end
++    end
++
++    context "with LM Studio server unavailable" do
++      it "shows error message when server is not running" do
++        # Mock the server check to return false
++        run_command("#{ruby_path} -e \"
++          require 'webmock'
++          WebMock.enable!
++          WebMock.stub_request(:get, 'http://localhost:1234/v1/models').to_raise(Errno::ECONNREFUSED)
++          load '#{exe_path}'
++        \" 'Test prompt'")
++
++        expect(last_command_started).not_to have_exit_status(0)
++        expect(last_command_started.stderr).to include("Error:")
++        expect(last_command_started.stderr).to match(/LM Studio server.*not available/i)
++      end
++
++      it "shows detailed error with debug flag when server unavailable" do
++        # Mock the server check to return connection refused
++        run_command("#{ruby_path} -e \"
++          require 'webmock'
++          WebMock.enable!
++          WebMock.stub_request(:get, 'http://localhost:1234/v1/models').to_raise(Errno::ECONNREFUSED)
++          load '#{exe_path}'
++        \" 'Test prompt' --debug")
++
++        expect(last_command_started).not_to have_exit_status(0)
++        expect(last_command_started.stderr).to include("Error:")
++        expect(last_command_started.stderr).to include("Backtrace:")
++      end
++    end
++  end
++
++  describe "error handling" do
++    it "handles malformed JSON prompt file gracefully", :vcr do
++      write_file("malformed.json", '{"invalid": json}')
++
++      run_command("#{ruby_path} #{exe_path} malformed.json --file")
++
++      expect(last_command_started).not_to have_exit_status(0)
++      expect(last_command_started.stderr).to include("Error:")
++    end
++
++    it "handles non-existent file" do
++      run_command("#{ruby_path} #{exe_path} /non/existent/file.txt --file")
++
++      expect(last_command_started).not_to have_exit_status(0)
++      expect(last_command_started.stderr).to match(/not found|does not exist/i)
++    end
++
++    it "handles empty file" do
++      write_file("empty.txt", "")
++
++      run_command("#{ruby_path} #{exe_path} empty.txt --file")
++
++      expect(last_command_started).not_to have_exit_status(0)
++      expect(last_command_started.stderr).to match(/empty|blank/i)
++    end
++  end
++
++  describe "output formats" do
++    context "with LM Studio available" do
++      before do
++        # Skip if LM Studio is not available
++        require "net/http"
++        begin
++          uri = URI("http://localhost:1234/v1/models")
++          response = Net::HTTP.get_response(uri)
++          skip "LM Studio server not available" if response.code != "200"
++        rescue => e
++          skip "LM Studio server not available: #{e.message}"
++        end
++      end
++
++      it "outputs clean text by default", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/outputs_clean_text_by_default"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Reply with exactly: Hello World'")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++        expect(last_command_started.stdout.strip).to include("Hello World")
++        # Should not contain JSON formatting
++        expect(last_command_started.stdout).not_to include("{")
++        expect(last_command_started.stdout).not_to include("}")
++      end
++
++      it "outputs valid JSON with metadata when requested", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/outputs_valid_json_with_metadata"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Say hi' --format json")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++
++        # Verify it's valid JSON
++        json_output = JSON.parse(last_command_started.stdout)
++
++        # Check structure
++        expect(json_output).to be_a(Hash)
++        expect(json_output).to have_key("text")
++        expect(json_output).to have_key("metadata")
++
++        # Check metadata structure
++        metadata = json_output["metadata"]
++        expect(metadata).to have_key("finish_reason")
++        expect(metadata).to have_key("usage")
++
++        # Usage should have token counts (if available)
++        usage = metadata["usage"]
++        expect(usage).to be_a(Hash) if usage
++      end
++    end
++  end
++
++  describe "complex prompts" do
++    context "with LM Studio available" do
++      before do
++        # Skip if LM Studio is not available
++        require "net/http"
++        begin
++          uri = URI("http://localhost:1234/v1/models")
++          response = Net::HTTP.get_response(uri)
++          skip "LM Studio server not available" if response.code != "200"
++        rescue => e
++          skip "LM Studio server not available: #{e.message}"
++        end
++      end
++
++      it "handles multi-line prompts from file", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/handles_multiline_prompts_from_file"
++        setup_vcr_env(cassette_name)
++
++        write_file("multiline.txt", <<~PROMPT)
++          This is a multi-line prompt.
++          It has several lines.
++
++          And even blank lines.
++
++          Reply with: "Multi-line received"
++        PROMPT
++
++        run_command("#{ruby_path} #{exe_path} multiline.txt --file")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++        expect(last_command_started.stdout).to include("Multi-line received")
++      end
++
++      it "handles prompts with special characters", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/handles_prompts_with_special_characters"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Echo this exactly: Special chars @#$%&*()_+={[}]|\:;\"<,>.?/'")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++        # LM Studio should handle special characters
++        expect(last_command_started.stdout.strip).not_to be_empty
++      end
++
++      it "handles Unicode prompts", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/handles_unicode_prompts"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Translate to English: こんにちは'")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++        expect(last_command_started.stdout.downcase).to match(/hello|hi|good|translation/)
++      end
++
++      it "handles very long prompts", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/handles_very_long_prompts"
++        setup_vcr_env(cassette_name)
++
++        long_prompt = "Please summarize this text: " + ("Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 50)
++
++        run_command("#{ruby_path} #{exe_path} '#{long_prompt}' --format json")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stderr).to be_empty
++
++        json_output = JSON.parse(last_command_started.stdout)
++        expect(json_output["text"]).not_to be_empty
++      end
++    end
++  end
++
++  describe "performance and reliability" do
++    context "with LM Studio available" do
++      before do
++        # Skip if LM Studio is not available
++        require "net/http"
++        begin
++          uri = URI("http://localhost:1234/v1/models")
++          response = Net::HTTP.get_response(uri)
++          skip "LM Studio server not available" if response.code != "200"
++        rescue => e
++          skip "LM Studio server not available: #{e.message}"
++        end
++      end
++
++      it "completes requests within reasonable time", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/completes_requests_within_reasonable_time"
++        setup_vcr_env(cassette_name)
++
++        start_time = Time.now
++
++        run_command("#{ruby_path} #{exe_path} 'Say hello quickly'")
++
++        duration = Time.now - start_time
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(duration).to be < 180 # 3 minute timeout for local model inference
++        expect(last_command_started.stdout.strip).not_to be_empty
++      end
++    end
++  end
++
++  describe "model management" do
++    context "with LM Studio available" do
++      before do
++        # Skip if LM Studio is not available
++        require "net/http"
++        begin
++          uri = URI("http://localhost:1234/v1/models")
++          response = Net::HTTP.get_response(uri)
++          skip "LM Studio server not available" if response.code != "200"
++        rescue => e
++          skip "LM Studio server not available: #{e.message}"
++        end
++      end
++
++      it "works with default model", :vcr do
++        cassette_name = "llm_lmstudio_query_integration/works_with_default_model"
++        setup_vcr_env(cassette_name)
++
++        run_command("#{ruby_path} #{exe_path} 'Test default model'")
++
++        expect(last_command_started).to have_exit_status(0)
++        expect(last_command_started.stdout.strip).not_to be_empty
++      end
++    end
++  end
++end
+diff --git a/spec/vcr_setup.rb b/spec/vcr_setup.rb
+index 9652a7a..1db690d 100644
+--- a/spec/vcr_setup.rb
++++ b/spec/vcr_setup.rb
+@@ -23,7 +23,10 @@ VCR.configure do |config|
+   # Configure to handle Gemini API
+   config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }
+ 
+-  # Allow localhost connections for tests
++  # Configure to handle LM Studio API (localhost)
++  config.filter_sensitive_data("<LM_STUDIO_API_KEY>") { ENV["LM_STUDIO_API_KEY"] }
++
++  # Allow localhost connections for tests (needed for LM Studio)
+   config.ignore_localhost = false
+ 
+   # Configure for test environment
+diff --git a/test_prompt.txt b/test_prompt.txt
+new file mode 100644
+index 0000000..e965047
+--- /dev/null
++++ b/test_prompt.txt
+@@ -0,0 +1 @@
++Hello
+
+```
+
+### Project Context Documentation
+*This section is populated when using the --include-dependencies flag*
+
+#### Project Documentation
+Location: `docs-project/*.md` (excluding roadmap)
+Current files:
+- ### docs-project/architecture.md
+```markdown
+# Coding Agent Tools Ruby Gem - Architecture
+
+## Overview
+
+This document outlines the architectural design and technical implementation details for the Coding Agent Tools (CAT) Ruby Gem. It provides a structured view of the system for developers and AI agents, explaining how the different components interact to provide automated development workflows. For a more high-level overview of the project structure and organization, refer to the [Project Blueprint](./blueprint.md).
+
+## Technology Stack
+
+### Core Technologies
+
+- **Primary Language**: Ruby
+- **Runtime/Framework**: MRI (C Ruby) version 3.2 or later
+- **Database**: N/A (Gem does not have a primary database; interacts with Git, files, and external APIs)
+- **Package Manager**: Bundler
+
+### Development Tools
+
+- **Build System**: Standard Ruby Gem build (`gemspec`)
+- **Testing Framework**: RSpec (for unit and integration tests), Aruba (for CLI integration tests)
+- **Linting/Formatting**: RuboCop (likely used for style enforcement)
+- **Type System**: Native Ruby (Sorbet not explicitly mentioned in PRD v1)
+
+### Infrastructure & Deployment
+
+- **Containerization**: Optional (e.g., Docker for running LM Studio)
+- **Cloud Platform**: N/A (Gem runs locally or in CI environments)
+- **CI/CD**: GitHub Actions (used for automated testing and building)
+- **Monitoring**: Basic opt-in analytics via Snowplow collector (v1)
+
+## System Architecture
+
+### High-Level Components
+
+The gem's architecture is designed for modularity and testability. The code within `lib/coding_agent_tools/` specifically follows an ATOM-based hierarchy (Atoms, Molecules, Organisms, Ecosystems) inspired by Atomic Design principles for composing functionality. This high-level component breakdown is also reflected in the project's directory structure, as detailed in the [Project Blueprint's Project Organization section](./blueprint.md#project-organization).
+
+```mermaid
+flowchart TD
+    subgraph Ruby Gem (CAT)
+        direction TB
+        CLI[Executables / bin/*]
+        ServiceObjects[🔧 Service Objects]
+        Adapters[🌐 Adapters]
+        Models[(Data Models)]
+    end
+    CLI --> ServiceObjects --> Adapters
+    Adapters -->|Gemini REST| GeminiAPI((Google Gemini))
+    Adapters -->|LM Studio| LMStudio((Local Model))\n(localhost:1234)
+    Adapters -->|Git CLI / GitHub API| GitHub((Git/GitHub))
+    ServiceObjects --> Models
+    Models -->|Reads from/Writes to| LocalFS[(Local File System)\n(e.g., docs-project tasks)]
+```
+
+### Component Descriptions
+
+#### CLI (Action Layer)
+- **Purpose**: Provides the command-line interface for user and agent interaction.
+- **Technology**: Ruby, potentially using libraries like Thor or Dry-CLI.
+- **Key Responsibilities**: Parsing command-line arguments, initial input validation, invoking the appropriate Service Objects.
+- **Interfaces**: Communicates with Service Objects.
+
+#### Service Objects (Transformation Layer)
+- **Purpose**: Contains the core business logic and orchestrates operations.
+- **Technology**: Pure Ruby classes.
+- **Key Responsibilities**: Implementing specific workflows (e.g., generating a commit message, finding the next task), transforming data between models and adapters.
+- **Interfaces**: Interacts with Adapters and Models. Designed to be testable in isolation.
+
+#### Adapters (Operation Layer)
+- **Purpose**: Provides interfaces to external systems or tools (LLMs, Git, file system).
+- **Technology**: Ruby classes wrapping external libraries or system calls.
+- **Key Responsibilities**: Handling communication protocols (HTTP, system commands), error handling for external interactions, translating external responses into internal data models.
+- **Interfaces**: Communicates with external APIs/tools and is used by Service Objects.
+
+#### Models (Model Layer)
+- **Purpose**: Represents the data structures used within the gem.
+- **Technology**: Plain Old Ruby Objects (POROs) or simple data structures.
+- **Key Responsibilities**: Defining the structure of data related to Git objects, task items, API responses, etc.
+- **Interfaces**: Used by Service Objects and Adapters.
+
+### ATOM-Based Code Structure in `lib/coding_agent_tools/`
+
+The internal structure of the gem's library code (`lib/coding_agent_tools/`) adheres to an ATOM-based hierarchy, promoting reusability and clear separation of concerns:
+
+-   **Atoms (`lib/coding_agent_tools/atoms/`)**: The smallest, indivisible units of behavior or functionality. They have no dependencies on other parts of this gem and are highly reusable (e.g., `EnvReader` for environment variables, `HTTPClient` for external API calls, `JSONFormatter` for data serialization/deserialization, utility functions for string normalization, basic file readers).
+-   **Molecules (`lib/coding_agent_tools/molecules/`)**: Simple compositions of Atoms that form a meaningful, reusable operation (e.g., `APICredentials` for managing authentication details, `HTTPRequestBuilder` for constructing API requests, `APIResponseParser` for handling API responses, configuration loaders using file access and parsing atoms, basic Git clients using command execution atoms).
+-   **Organisms (`lib/coding_agent_tools/organisms/`)**: More complex units that perform specific business-related functions or features of the gem. They orchestrate Molecules and Atoms to achieve a distinct goal (e.g., `GeminiClient` for interacting with the Gemini API, `PromptProcessor` for preparing and parsing LLM prompts, LLM queriers, commit message suggesters). These often correspond to Service Objects.
+-   **Ecosystems (`lib/coding_agent_tools/ecosystems/`)**: Cohesive groupings of Organisms and other components that deliver a larger, bounded context or subsystem. The overall CLI application, orchestrated by `dry-cli`, can be considered the primary ecosystem.
+-   **Models (`lib/coding_agent_tools/models/`)**: Plain Old Ruby Objects (POROs) or simple data structures used across various layers to represent entities and data (e.g., `Task`, `LLMResponse`).
+-   **CLI Commands (`lib/coding_agent_tools/cli/` and `lib/coding_agent_tools/cli.rb`)**: These are the entry points for the command-line interface, built using `dry-cli`. Commands typically delegate their core logic to Organisms.
+-   **Cross-Cutting Concerns (`lib/coding_agent_tools/`)**: Modules that provide shared functionalities used across different layers, ensuring consistency and centralized handling of aspects like logging, error reporting, and middleware processing (e.g., `middlewares/` for request/response processing, `notifications.rb` for system-wide alerts, `error.rb` for custom error definitions, `cli.rb` for command registration).
+
+## Data Flow
+
+Data typically flows from the CLI (user input) to a Service Object, which uses Adapters to interact with external systems (LLM, Git, file system). The Adapters return data, potentially mapped to internal Models, back to the Service Object for processing. The final result is returned through the Adapter layer back to the Service Object, and finally outputted via the CLI. For task utilities, data might be read from local files (`docs-project/`) via an Adapter/Service Object and formatted for CLI output.
+
+### Request Processing Flow (Example: git-commit-with-message)
+
+1.  **Input**: User/agent invokes `bin/git-commit-with-message` with arguments (`--intention`, `--files`, etc.).
+2.  **Processing (CLI)**: The CLI executable parses arguments, calls the relevant Service Object.
+3.  **Processing (Service Object)**: Service Object gathers necessary context (diff from Git via Adapter), prepares prompt for LLM.
+4.  **External Interaction (Adapter)**: Service Object calls the LLM Adapter (e.g., `GeminiAdapter`) with the prompt.
+5.  **External Service**: LLM API processes the prompt and returns a message.
+6.  **Processing (Adapter)**: Adapter receives the LLM response, potentially validates/formats it, returns to Service Object.
+7.  **Processing (Service Object)**: Service Object takes the generated message, stages files (via Git Adapter), and performs the Git commit (via Git Adapter).
+8.  **Output**: CLI confirms the commit or reports errors.
+
+## Command-line Tools (bin/)
+
+The `bin/` directory contains executable scripts that serve as the primary interface for the gem. These are often thin wrappers (binstubs) that invoke the main gem logic.
+
+### Key Commands (as per PRD):
+
+-   `bin/llm-gemini-query`: Query Google Gemini.
+-   `bin/lms-studio-query`: Query local LM Studio.
+-   `bin/github-repository-create`: Create a GitHub repository.
+-   `bin/git-commit-with-message`: Generate and perform a Git commit.
+-   `bin/tr`: List recent tasks.
+-   `bin/tn`: Find the next actionable task.
+-   `bin/rc`: Get current release path and version.
+-   `bin/test`: Run the test suite.
+-   `bin/lint`: Run code quality checks.
+-   `bin/build`: Build the gem.
+-   `bin/run`: (Context dependent, potentially runs gem commands or a sample usage).
+-   `bin/tree`: Display project directory structure (likely wraps `docs-dev/tools/tree.sh`).
+
+These scripts are intended to be idempotent where possible and provide a consistent, predictable interface for automation.
+
+## File Organization
+
+```
+.
+├── bin/                   # Executable command-line scripts (binstubs/wrappers)
+├── docs-dev/              # Submodule: Development resources, guides, templates, tools
+│   ├── guides/            # Best practices, patterns, templates
+│   ├── tools/             # Utility scripts (e.g., for task management, tree display)
+│   └── workflow-instructions/ # AI workflow definitions
+├── docs-project/          # Project-specific documentation and management files
+│   ├── backlog/           # Task files for future releases
+│   ├── current/           # Task files for the current release
+│   ├── done/              # Completed task files
+│   ├── decisions/         # Architecture Decision Records (.keep file ensures directory exists)
+│   ├── architecture.md    # This document
+│   ├── blueprint.md       # Project structure overview and AI guidelines
+│   └── what-do-we-build.md # Project vision and goals
+├── exe/                   # Gem executables (e.g., coding_agent_tools)
+├── lib/                   # Ruby gem source code
+│   ├── coding_agent_tools.rb # Main gem file, loads components
+│   └── coding_agent_tools/
+│       ├── atoms/         # Smallest, indivisible units (utilities, transformations)
+│       ├── cli/           # Dry-CLI command definitions and subcommands
+│       ├── ecosystems/    # Complete subsystems or major features
+│       ├── middlewares/   # Common middleware for request/response processing
+│       ├── molecules/     # Simple compositions of atoms
+│       ├── models/        # Data structures (POROs)
+│       ├── notifications.rb # Global notification and event handling
+│       ├── organisms/     # Business logic handlers, orchestrating molecules/atoms
+│       ├── cli.rb         # Main Dry-CLI registry
+│       ├── error.rb       # Custom gem-specific error classes
+│       └── version.rb     # Gem version definition
+├── spec/                  # RSpec test files (unit, integration, CLI)
+├── .github/               # GitHub specific files (e.g. workflows)
+│   └── workflows/
+│       └── main.yml       # CI workflow
+├── .gitignore             # Specifies intentionally untracked files
+├── .rspec                 # RSpec configuration
+├── .standard.yml          # StandardRB configuration
+├── CHANGELOG.md           # Record of changes
+├── Gemfile                # Bundler dependency file
+├── LICENSE.txt            # Project license
+├── PRD.md                 # Product Requirements Document (primary source of truth)
+├── Rakefile               # Rake tasks
+├── README.md              # Project overview and quick start guide
+└── coding_agent_tools.gemspec # Gem specification file
+```
+
+The primary Ruby source code resides in the `lib/coding_agent_tools/` directory, organized according to the ATOM pattern. Tests are located in the `spec/` directory. For a comprehensive overview of the overall project directory structure, refer to the [Project Blueprint's Project Organization section](./blueprint.md#project-organization).
+
+## Development Patterns
+
+-   **ATOM-Based Hierarchy**: The core library implementation (`lib/coding_agent_tools/`) follows an Atoms, Molecules, Organisms, Ecosystems hierarchy to ensure modularity, reusability, testability, and maintainability. This pattern promotes a clear separation of concerns, making components easier to understand, test, and adapt.
+-   **Test-Driven Development (TDD)**: A strong emphasis is placed on writing tests (`spec/`) before or alongside implementation code, aiming for high test coverage. This approach ensures code correctness and facilitates refactoring.
+-   **Dependency Injection**: Components are designed to accept dependencies (like adapters) via initialization rather than creating them internally. This facilitates easier testing by allowing mock objects to be injected, and promotes flexibility by decoupling components from their concrete implementations.
+-   **CLI-First Design**: The architecture prioritizes a robust and predictable command-line interface as the primary interaction method. This allows the gem to be easily integrated into automated workflows and used directly by developers or other agents.
+-   **Testing with VCR**: HTTP interactions with external APIs are recorded and replayed using VCR. This ensures tests are fast, reliable, and deterministic, as they do not rely on live external services, making the test suite robust against network issues or API changes.
+-   **Observability with dry-monitor**: Key events and operations within the gem are instrumented using `dry-monitor`. This allows for centralized logging, error reporting, and performance monitoring by decoupling the event emitters from their consumers, thus avoiding tightly coupled concerns and promoting a flexible monitoring setup.
+
+## Security Considerations
+
+-   **API Key/Token Handling**: The gem avoids hardcoding secrets. API keys and tokens (e.g., `GEMINI_API_KEY`, `GITHUB_TOKEN`) are read from environment variables or standard configuration locations (`~/.gemini/config`, macOS keychain).
+-   **No Plaintext Secrets in Logs**: Logging is designed to avoid exposing sensitive information.
+-   **Input Validation**: Basic input validation is performed, particularly at the CLI/Action layer, to prevent command injection or other security vulnerabilities.
+
+## Performance Considerations
+
+-   **Startup Latency**: Target low startup latency (≤ 200 ms for CLI commands) for responsiveness, especially when invoked by agents.
+-   **Caching**: Potential for implementing caching strategies (e.g., for LLM responses or frequently accessed data) to improve performance.
+-   **Profiling**: Standard Ruby profiling tools can be used to identify performance bottlenecks.
+
+## Deployment Architecture
+
+The gem is deployed as a standard RubyGem.
+
+-   **Installation**: Users install via `gem install coding_agent_tools` or by adding `gem 'coding_agent_tools'` to their `Gemfile` and running `bundle install`.
+-   **Binstubs**: Bundler generates binstubs in the project's `bin/` directory (or globally if installed system-wide), providing convenient wrappers for executables.
+-   **CI/CD**: GitHub Actions are used to build the gem, run tests, and potentially publish new versions.
+
+## Extension Points
+
+The ATOM architecture provides several extension points:
+
+-   **New Commands**: Add new executables in `bin/` and corresponding Action/Service Object logic in `lib/`.
+-   **New Adapters**: Implement new Adapters in `lib/coding_agent_tools/operations/` to integrate with different external APIs, LLM providers, or tools. These can then be used by existing or new Service Objects.
+-   **New Models**: Define new data structures in `lib/coding_agent_tools/models/` as needed for new features or data representations.
+-   **Custom Scripts**: Users can create their own scripts in the project's `bin/` directory that utilize the gem's internal API or CLI commands.
+
+## Dependencies
+
+### Runtime Dependencies
+
+-   Ruby (>= 3.2)
+-   Bundler
+-   `faraday`: Flexible HTTP client library.
+-   `zeitwerk`: Efficient and thread-safe code loader.
+-   `dry-monitor`: Event-based monitoring and instrumentation toolkit.
+-   `dry-configurable`: Provides configuration capabilities for Ruby objects.
+-   `addressable`: URI manipulation library, replacing Ruby's URI.
+-   Standard system **Git CLI**
+-   Optional: **LM Studio** for offline LLM support
+
+### Development Dependencies
+
+-   RSpec: Testing framework.
+-   RuboCop / StandardRB: Code style linter and formatter.
+-   `vcr`: Records and replays HTTP interactions for tests.
+-   `webmock`: Stubs and sets expectations on HTTP requests.
+-   `docs-dev/tools/*` scripts: Dependencies for certain `bin/` utilities that wrap scripts from the `docs-dev` submodule.
+-   **SimpleCov** - Code coverage analysis
+-   **Pry** - Interactive debugging
+
+For a comprehensive and up-to-date list of dependencies, refer to the `coding_agent_tools.gemspec` and `Gemfile`, and consult the [Project Blueprint's Dependencies section](./blueprint.md#dependencies) for a complementary overview.
+
+## Decision Records
+
+Significant architectural decisions are documented as Architecture Decision Records (ADRs).
+
+For detailed decision records, see [docs-project/decisions/](../../../coding-agent-tools/docs-project/decisions/).
+
+## Troubleshooting
+
+(This section is a placeholder and should be populated with common issues and their solutions as they are identified.)
+
+-   **Issue**: Command not found after installation.
+    -   **Symptoms**: Running `bin/tn` or other commands results in "command not found".
+    -   **Solution**: Ensure Bundler binstubs are set up and your PATH includes the project's `bin/` directory. Run `bundle install` if using Bundler.
+
+-   **Issue**: LLM query fails.
+    -   **Symptoms**: Commands like `bin/llm-gemini-query` report API errors or connection issues.
+    -   **Solution**: Check environment variables (`GEMINI_API_KEY`), network connectivity, and the status of the LM Studio server if using the local model.
+
+## Future Considerations
+
+-   **Multi-language bindings**: Explore providing SDKs or libraries in languages other than Ruby (post v1).
+-   **Streaming LLM responses**: Investigate if agents require streaming output from LLMs rather than waiting for a full reply.
+-   **Encrypted local storage**: Consider if caching or storing sensitive data locally requires encryption.
+-   **Rubocop plugin**: Assess the value of a Rubocop plugin to enforce ATOM directory boundaries and other architectural conventions.
+-   **Advanced Task Management Integration**: Explore deeper integrations with external task management systems.
+```
+- ### docs-project/blueprint.md
+```markdown
+# Project Blueprint: Coding Agent Tools Ruby Gem
+
+## What is a Blueprint?
+
+This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.
+
+## Core Project Documents
+
+- [What We Build](./what-do-we-build.md) - Project vision and goals
+- [Architecture](./architecture.md) - System design and implementation principles
+
+## Project Organization
+
+This project follows a documentation-first approach with these primary directories:
+
+- **docs-dev/** - Development resources and workflows (Git submodule)
+  - **guides/** - Best practices and standards for development
+  - **tools/** - Utility scripts to support development workflows (e.g., for task management, tree display)
+  - **workflow-instructions/** - Structured commands for AI agents
+  - **zed/** - Editor integration (if applicable)
+
+- **docs-project/** - Project-specific documentation, task management, and decisions
+  - **backlog/** - Pending tasks for future releases
+  - **current/** - Active release cycle work
+  - **done/** - Completed releases and tasks
+  - **decisions/** - Architecture Decision Records (ADRs)
+
+- **bin/** - Executable scripts (binstubs/wrappers) for project automation (e.g., `bin/test`, `bin/tn`)
+
+- **exe/** - Primary gem executables (e.g., `exe/llm-gemini-query`)
+
+- **lib/** - Ruby gem source code, organized by the ATOM architecture pattern with subdirectories for `atoms/`, `molecules/`, `organisms/`, `cli/`, `models/`, and cross-cutting concerns like `middlewares/`.
+
+- **spec/** - RSpec test files (unit, integration, CLI)
+
+<!-- Add your project-specific directories here -->
+
+## View Complete Directory Structure
+
+To see the complete filtered directory structure, run:
+
+```bash
+bin/tree
+```
+
+This will show all project files while filtering out temporary files, session logs, and other non-essential directories.
+
+## Key Project-Specific Files
+
+- [Product Requirements Document (PRD)](../../PRD.md) - Primary source of truth for project goals and requirements
+- [Main README](../../README.md) - Project overview, installation, runtime configuration, and user-facing documentation
+- [Development Guide](../../docs/DEVELOPMENT.md) - Development environment setup, testing, build tools, and contributor workflow
+- [Workflow Instructions](../../docs-dev/workflow-instructions/README.md) - Entry point for understanding available AI workflows
+- [Project Guides](../../docs-dev/guides/README.md) - Development standards and best practices
+- `coding_agent_tools.gemspec` - Ruby gem definition and dependencies
+- `Gemfile` - Bundler dependency management
+
+## Technology Stack
+
+- **Primary Language**: Ruby (>= 3.4.2)
+- **Architecture Pattern**: ATOM (Action, Transformation, Operation, Model), Zeitwerk for efficient code loading, and dry-monitor for observability
+- **Runtime Dependencies**: Faraday (HTTP client), dry-cli (CLI framework), dry-configurable (configuration management), addressable (URI parsing and manipulation)
+- **Development Tools**: RSpec, StandardRB, VCR, WebMock, Aruba, Zeitwerk
+- **Integrations**: Google Gemini API, LM Studio (local), Git CLI, GitHub REST API
+
+### Documentation Separation
+
+- **README.md**: Contains runtime information, installation instructions, basic usage, and configuration for end users
+- **docs/DEVELOPMENT.md**: Contains development environment setup, testing frameworks, build tools, and contributor guidelines
+
+## Read-Only Paths
+
+AI agents should treat the following paths as read-only unless explicitly instructed to modify them for specific maintenance or update tasks. Modifying these files without careful consideration can break core project workflows or documentation standards.
+
+- `docs-dev/guides/**/*`
+- `docs-dev/workflow-instructions/**/*`
+- `docs-dev/tools/_binstubs/**/*`
+- `docs-dev/guides/initialize-project-templates/**/*`
+- `docs-project/decisions/**/*` (Modify only when adding or updating ADRs)
+- `docs-project/done/**/*` (Completed tasks should not be modified)
+- `lib/**/*` (Treat the core gem implementation as stable unless working on a specific feature or bug fix requiring changes here)
+- `spec/**/*` (Treat tests as read-only unless writing new tests or fixing broken ones related to code changes)
+- `.gitignore` (Modify carefully when adding/removing ignored patterns)
+- `Gemfile.lock` (Manage dependencies via `bundle add`/`remove` or explicit instruction)
+- `bin/*` (Modify only when updating binstub templates or adding new project-specific scripts)
+- `*.lock` # Dependency lock files (e.g., Gemfile.lock)
+- `dist/**/*` # Built artifacts
+- `build/**/*` # Build output
+- `pkg/**/*` # Gem packages
+
+## Ignored Paths
+
+AI agents should generally ignore the contents of the following paths during tasks such as searching for tasks, summarizing project state, or performing code analysis, unless the task explicitly requires interacting with these directories (e.g., cleaning build artifacts). These paths often contain transient data, dependencies, or build artifacts.
+
+- `docs-project/done/**/*` # Completed tasks (already read-only, but explicitly ignored for general tasks)
+- `vendor/**/*` (Bundler dependencies)
+- `tmp/**/*`
+- `log/**/*`
+- `.git/**/*`
+- `.bundle/**/*`
+- `coverage/**/*` (Test coverage reports)
+- `node_modules/**/*` (If applicable for frontend/tooling)
+- `.idea/**/*`, `.vscode/**/*` (Editor specific configurations)
+- `**/.*.swp`, `**/.*.swo` (Swap files)
+- `/.DS_Store` (macOS system files)
+- `**/Thumbs.db` (Windows system files)
+- `**/.env` # Environment files
+- `**/.env.*` # Environment variants
+- `*.session.log`
+- `*.lock`
+- `*.tmp`
+- `*~` # Backup files
+
+## Entry Points
+
+### Development
+
+```bash
+# Run the test suite
+bin/test
+
+# Run code quality checks
+bin/lint
+
+# Build the gem
+bin/build
+```
+*(Note: `bin/run` might be used for specific entry points if defined)*
+
+### Common Workflows
+
+- **Find Next Task**: Use `bin/tn` to identify the next unblocked task to work on.
+- **Summarize Recent Work**: Use `bin/tr` to see recently completed or updated tasks.
+- **Commit Changes**: Use `bin/git-commit-with-message` to stage changes and generate a commit message.
+- **Query LLM**: Use `exe/llm-gemini-query` or `bin/lms-studio-query` to interact with language models.
+- **Generate Documentation Review**: Use `bin/cr-docs` to create comprehensive documentation update prompts from code diffs.
+
+Refer to the [Architecture document](./architecture.md#command-line-tools-bin) for a more detailed list and description of `bin/` commands.
+
+## Dependencies
+
+### Runtime Dependencies
+
+- **Ruby** (>= 3.2)
+- **Bundler** - Dependency management
+- **faraday** - Flexible HTTP client library.
+- **zeitwerk** - Efficient and thread-safe code loader.
+- **dry-monitor** - Event-based monitoring and instrumentation toolkit.
+- **dry-configurable** - Provides configuration capabilities for Ruby objects.
+- **addressable** - URI manipulation library.
+
+### Development Dependencies
+
+- **RSpec** - Testing framework.
+- **RuboCop / StandardRB** - Code style linter and formatter.
+- **VCR** - Records and replays HTTP interactions for tests.
+- **WebMock** - Stubs and sets expectations on HTTP requests.
+- `docs-dev/tools/*` scripts (used by some `bin/` wrappers).
+
+See `coding_agent_tools.gemspec` and `Gemfile` for complete dependency specifications.
+
+## Submodules
+
+### docs-dev
+
+- Path: `docs-dev`
+- Repository: [Repository URL - assumed external]
+- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
+- **Important**: Commits for this submodule must be made from within the submodule directory (`../../docs-dev`).
+
+---
+
+*This blueprint serves as a quick reference and guide for automated agents. It should be updated if the project structure, key technologies, or operational guidelines change significantly.*
+```
+- ### docs-project/what-do-we-build.md
+```markdown
+# Coding Agent Tools Ruby Gem
+
+## What We Build 🔍
+
+The **Coding Agent Tools (CAT)** project provides a Ruby gem and associated command-line interface (CLI) tools designed to streamline development workflows for both human developers and autonomous AI coding agents. Its core purpose is to enable seamless interaction with local projects, Git repositories, and task backlogs by offering a predictable and standardized set of commands and a programmable API. By automating routine Dev Ops tasks like querying LLMs, generating commit messages, creating repositories, and navigating task queues, CAT frees up developers and agents to concentrate on higher-value design and coding activities.
+
+## ✨ Key Features
+
+- **LLM Communication**: Implemented CLI commands (`llm-gemini-query`, `lms-studio-query`) for interacting with Google Gemini and local LM Studio models.
+- **Git Workflow Automation**: Tools for creating GitHub repositories (`github-repository-create`) and generating intelligent Git commit messages based on diffs and intentions (`git-commit-with-message`).
+- **Task Management Utilities**: Commands (`tn`, `tr`, `rc`) to help developers and agents identify the next actionable task, review recent tasks, and manage release directories, often integrating with documentation-based task backlogs.
+- **Standardized Interface**: Provides a consistent CLI and API surface for automation, reducing reliance on ad-hoc scripts.
+- **Offline Support**: Enables querying local language models via LM Studio.
+
+## Core Design Principles
+
+- **ATOM Architecture**: Structured around the Action, Transformation, Operation, and Model pattern for maintainability, testability, and clear separation of concerns.
+- **Test-Driven Development**: High emphasis on testing with a goal of 100% unit and integration test coverage using RSpec.
+- **Predictable CLI**: Designing commands with ergonomic flags suitable for both human and agent interaction.
+- **Modularity**: Components are designed with explicit boundaries and dependency injection.
+- **Ruby Best Practices**: Adhering to standard Ruby conventions and practices.
+
+## Target Use Cases
+
+### Primary Use Cases
+
+- **Automated Development Workflows**: AI coding agents using CAT commands to perform tasks like committing code, querying models, or finding the next work item within CI/CD pipelines or local development environments.
+- **Accelerated Project Setup**: Developers quickly initializing Git repositories and setting up remotes with standardized commands.
+- **Streamlined Commit Process**: Developers generating informative and consistent commit messages automatically based on their code changes and intent.
+- **Efficient Task Navigation**: Developers and agents easily identifying and tracking development tasks within a structured documentation system.
+
+### Secondary Use Cases
+
+- **Offline AI Interaction**: Developers and agents interacting with local language models via LM Studio for rapid iteration or sensitive tasks.
+- **Integrating with Documentation**: Utilizing CAT commands to manage task backlogs defined within documentation files.
+
+## User Personas
+
+### Primary Users
+
+**Alex – AI Coding Agent**: An automated system designed to perform coding tasks.
+- Needs: A deterministic and stable CLI surface to reliably execute development and operations steps.
+- Goals: Successfully complete assigned coding and Dev Ops tasks without manual intervention.
+- Pain Points: Brittle and inconsistent ad-hoc shell scripts that cause workflow failures.
+
+**Sam – Senior Dev**: An experienced software engineer focused on efficient development.
+- Needs: Rapidly set up new project remotes, easily craft descriptive and atomic commits.
+- Goals: Reduce time spent on routine Git and project setup chores; maintain a clean and traceable commit history.
+- Pain Points: Forgetting push URLs for new repositories, struggling to write clear and concise commit messages for complex changes.
+
+### Secondary Users
+
+**Priya – DX Engineer**: An engineer focused on improving the developer experience.
+- Context: Priya uses CAT as a foundation for building standardized, testable, and extendable developer tools and workflows within their organization. They need a framework that follows Ruby best practices and is easy to integrate and extend.
+
+## Success Metrics
+
+### Primary Metrics
+- **Time-to-Commit**: Reduce median time from code change to committed diff by **30%** within the pilot team (Target: ≤ 70% of original time).
+- **Agent Adoption**: ≥ **80%** of automated CI runs invoke at least one CAT command.
+
+### Secondary Metrics
+- **Support Load**: ≤ **2** support tickets per week related to Git setup or task selection after 1 month post-launch.
+- **Reliability**: CLI commands succeed ≥ **99%** over 1,000 automated invocations in testing/monitoring.
+
+## Technology Philosophy
+
+### Core Technology Choices
+- **Primary Language**: Ruby - Chosen for its expressiveness, developer productivity, and suitability for scripting and tooling development.
+- **Runtime**: MRI (C Ruby) ≥ 3.2 - Standard and widely adopted Ruby implementation.
+
+### Technical Principles
+- **ATOM Architecture**: Guiding principle for structuring the codebase into distinct, testable layers.
+- **Focus on CLI/API**: Prioritizing a stable and well-documented interface for programmatic and human use.
+- **External Dependency Management**: Explicitly managing dependencies and aiming for minimal, well-vetted external libraries.
+
+## Project Boundaries
+
+### What We Build
+- A Ruby gem (`coding_agent_tools`) installable via standard Ruby package managers (RubyGems, Bundler).
+- A suite of CLI executables (`bin/`) for common Dev Ops and task management workflows, including `exe/llm-gemini-query`.
+- Core ATOM components, including:
+  - **Atoms**: `EnvReader`, `HTTPClient`, `JSONFormatter`
+  - **Molecules**: `APICredentials`, `HTTPRequestBuilder`, `APIResponseParser`
+  - **Organisms**: `GeminiClient`, `PromptProcessor`
+- An internal API used by the CLI, which can potentially be exposed for programmatic use.
+- Integrations with Google Gemini API and local LM Studio API.
+- Integrations with Git CLI and GitHub REST API (v3).
+- Tools to interact with documentation-based task backlogs (e.g., in `docs-project`).
+- Comprehensive unit and integration tests.
+- Documentation (`docs-project/`) detailing usage and architecture.
+
+### What We Don't Build (v1)
+- SDKs or libraries in languages other than Ruby.
+- A full-featured graphical user interface (GUI) for Git or task management.
+- Direct integrations with proprietary LLM endpoints other than those specified (e.g., direct OpenAI calls within the gem, although wrappers could be built by users).
+- Real-time collaborative editing features.
+- A complete replacement for robust ticketing systems (Jira, Asana, etc.), but rather a tool to interact with backlog information potentially stored elsewhere or locally in docs.
+
+## Value Proposition
+
+### Problems We Solve
+1. **Inconsistent Automation**: Replaces ad-hoc, project-specific scripts with a standardized, testable, and maintainable toolkit.
+2. **Agent Orchestration Gap**: Provides coding agents with reliable, deterministic tools to perform common development and Dev Ops tasks they currently struggle with.
+3. **Dev Ops Overhead**: Automates routine tasks like repository creation and commit message generation, reducing manual effort for developers.
+
+### Unique Advantages
+- **AI-Native Design**: Built specifically with the needs of AI coding agents in mind, offering a robust and predictable interface.
+- **Documentation-Driven**: Designed to integrate with documentation-based workflows and task management.
+- **Opinionated but Extendable**: Provides strong conventions while allowing for customization and extension of specific tools and workflows.
+- **Offline Capability**: Supports interaction with local LLMs for enhanced privacy and speed.
+
+## Future Vision
+
+### Short-term Goals (Complete by ~Aug 2025 - v1.0.0)
+- Finalize and release GitHub repository creation and commit generator tools.
+- Implement and stabilize task utility commands (`tn`, `tr`, `rc`).
+- Reach ≥ 95% test coverage.
+- Publish stable v1.0.0 to RubyGems.
+
+### Medium-term Goals (6-12 months post-v1)
+- Gather user feedback and prioritize feature requests.
+- Explore integrations with other LLM providers (if needed and not proprietary).
+- Enhance task management features, potentially integrating with external systems.
+- Improve performance and scalability.
+
+### Long-term Vision (1+ years)
+- Become a standard tool in AI-assisted Ruby development workflows.
+- Potentially explore mechanisms for cross-language support (e.g., via a shared core or well-defined API boundaries).
+- Expand the suite of automated Dev Ops and development tasks supported.
+
+## Dependencies and Ecosystem
+
+### Key Dependencies
+- **Ruby ≥ 3.2**: The required runtime environment.
+- **Google Gemini API**: Required for online LLM interactions.
+- **LM Studio**: Required for local, offline LLM interactions.
+- **Git CLI**: Fundamental command-line tool interacted with by the gem.
+- **GitHub REST API (v3)**: Used for repository creation.
+- **`docs-dev/tools/*` scripts**: Utility scripts assumed to be present in the `docs-dev` submodule for certain operations (like task utilities).
+
+### Ecosystem Integration
+- **Git/GitHub**: Deep integration for repository management and commit workflows.
+- **Task Backlogs (Docs-based)**: Designed to work with tasks defined in documentation files (`docs-project/`).
+- **CI/CD Pipelines**: Intended to be invoked as part of automated workflows.
+- **AI Coding Agents**: Primary users and integrators of the tools.
+
+## Submodules
+
+### docs-dev
+- Path: `docs-dev`
+- Repository: [Repository URL - assumed external]
+- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
+- **Important**: Commits for this submodule must be made from within the submodule directory.
+
+---
+
+*This document should be updated as the project evolves and new insights are gained about user needs and project direction.*
+```
+
+#### Architecture Decision Records (ADRs)
+Location: `docs-project/decisions/` and `docs-project/current/*/decisions/*.md`
+Current files:
+- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-001-CI-Aware-VCR-Configuration.md
+```markdown
+# ADR-001: CI-Aware VCR Configuration for Integration Tests
+
+## Status
+
+Accepted
+Date: 2025-06-07
+
+## Context
+
+The project needed a robust solution for testing the `llm-gemini-query` command's integration with the Google Gemini API. The challenge was to create tests that:
+
+1. **Run consistently** across development and CI environments
+2. **Don't require API keys in CI** to avoid security risks and external dependencies
+3. **Automatically record new interactions** during development without manual intervention
+4. **Maintain simplicity** and use standard Ruby testing patterns
+5. **Prevent accidental API costs** from test runs in CI
+
+Initial approaches considered custom test runners and complex environment management, but these added unnecessary complexity and deviated from standard Ruby/RSpec patterns.
+
+The key insight was that VCR already provides powerful configuration options that could be leveraged with minimal custom code.
+
+## Decision
+
+We implemented a CI-aware VCR configuration using VCR's built-in recording mode options with environment-based switching:
+
+```ruby
+# CI-aware recording mode
+recording_mode = if ENV['CI']
+                   :none  # Never record in CI
+                 else
+                   case ENV['VCR_RECORD']
+                   when 'true', '1', 'all'
+                     :all
+                   when 'new_episodes', 'new'
+                     :new_episodes  
+                   when 'none', 'false', '0'
+                     :none
+                   else
+                     :once  # Auto-record missing cassettes in development
+                   end
+                 end
+
+config.default_cassette_options[:record] = recording_mode
+```
+
+This configuration automatically:
+- **In CI environments** (`ENV['CI']` is set): Uses `:none` mode - only replays existing cassettes, never makes API calls
+- **In development**: Uses `:once` mode by default - automatically records missing cassettes, replays existing ones
+- **Provides overrides**: Allows explicit control via `VCR_RECORD` environment variable when needed
+
+The solution uses standard `bin/test` command (wrapper around `bundle exec rspec`) with environment variables for control, eliminating the need for custom tooling.
+
+## Consequences
+
+### Positive
+
+- **Zero Configuration**: Works out of the box for developers and CI
+- **Standard Ruby Patterns**: Uses familiar `bin/test` commands and RSpec conventions
+- **Automatic CI Detection**: No manual configuration needed across different CI platforms
+- **Developer Friendly**: Missing cassettes are recorded automatically during development
+- **Security**: No API keys required in CI, automatic sensitive data filtering
+- **Fast CI Builds**: No external API calls means faster, more reliable test runs
+- **Cost Control**: Prevents accidental API usage in CI environments
+- **Maintainable**: Any Ruby developer can understand and modify the configuration
+
+### Negative
+
+- **Initial Recording Requires API Key**: Developers need a real API key to record new cassettes (though this is unavoidable)
+- **Cassette Maintenance**: Cassettes need to be updated when API responses change (though this provides value by catching API changes)
+
+### Neutral
+
+- **Cassettes in Repository**: VCR cassettes are committed to version control, increasing repository size slightly but providing test reliability
+- **Environment Variable Dependency**: Relies on CI platforms setting `ENV['CI']` (which is standard practice)
+
+## Alternatives Considered
+
+### Custom Test Runner Script
+- **Why rejected**: Added unnecessary complexity and deviated from standard Ruby patterns
+- **Trade-offs**: Would have provided more fine-grained control but at the cost of maintainability and developer experience
+
+### Manual VCR Mode Switching
+- **Why rejected**: Required developers to remember to set different modes for different scenarios
+- **Trade-offs**: Would have been simpler to implement but error-prone and poor developer experience
+
+### Always Recording in Development
+- **Why rejected**: Would make unnecessary API calls and potentially hit rate limits
+- **Trade-offs**: Would have been simpler but wasteful of API quota and slower test runs
+
+### Separate Test Suites for CI vs Development
+- **Why rejected**: Would create maintenance overhead and potential for CI/development drift
+- **Trade-offs**: Might have been cleaner separation but would duplicate test maintenance
+
+## Related Decisions
+
+- Integration test strategy for `llm-gemini-query` command
+- API key management and security practices
+- Test automation and CI/CD pipeline design
+
+## References
+
+- [VCR Documentation - Recording Modes](https://relishapp.com/vcr/vcr/docs/record-modes)
+- [VCR GitHub Repository](https://github.com/vcr/vcr)
+- [Ruby CI Environment Detection Patterns](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables)
+- [Google Gemini API Documentation](https://ai.google.dev/api/rest)
+```
+- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-002-Zeitwerk-for-Autoloading.md
+```markdown
+# ADR-002: Zeitwerk for Autoloading
+
+## Status
+
+Accepted
+Date: 2025-06-08
+
+## Context
+
+The project's codebase, initially small, relied on manual `require` statements or simple `require_relative` patterns for loading classes and modules. As the project grew in complexity and size, this manual approach became increasingly cumbersome, prone to errors (e.g., forgotten `require` statements, circular dependencies), and difficult to maintain. There was a clear need for a more robust, standardized, and automated autoloading mechanism to improve developer experience, reduce boilerplate, and align with modern Ruby and Rails development practices.
+
+## Decision
+
+We decided to adopt Zeitwerk as the primary autoloading mechanism for the project. Zeitwerk, known for its performance and strict adherence to file naming conventions, provides an efficient and convention-over-configuration solution for autoloading.
+
+The specific implementation includes:
+- Configuring Zeitwerk to manage the project's autoload paths.
+- Utilizing Zeitwerk's inflector configuration to handle acronym-based class names (e.g., `CLI`, `HTTP`, `API`) correctly, ensuring that `CLI` is autoloaded from `cli.rb` and not `c_l_i.rb`.
+
+```ruby
+# Example (conceptual) Zeitwerk configuration
+# This would typically be set up in a central initialization file.
+loader = Zeitwerk::Loader.new
+loader.push_dir("lib") # Assuming 'lib' is the root of our autoloadable code
+loader.inflector.inflect(
+  "CLI" => "CLI",
+  "HTTP" => "HTTP",
+  "API" => "API"
+)
+loader.setup
+```
+
+## Consequences
+
+### Positive
+
+- **Standardized Autoloading**: Provides a consistent and reliable way to load classes and modules without explicit `require` statements.
+- **Rails/Ruby Community Alignment**: Adopting Zeitwerk aligns the project with common practices in the Ruby and Rails ecosystems, making it easier for developers familiar with these environments to contribute.
+- **Improved Developer Experience**: Developers no longer need to manually manage `require` paths, leading to faster development cycles and fewer "missing constant" errors.
+- **Performance**: Zeitwerk is highly optimized for performance, loading only what's needed, when it's needed.
+- **Reduced Boilerplate**: Eliminates the need for numerous `require` statements, making files cleaner and more focused on business logic.
+
+### Negative
+
+- **Strict File Naming Conventions**: Requires strict adherence to Zeitwerk's file naming conventions (e.g., `MyModule::MyClass` must be in `my_module/my_class.rb`). While beneficial for consistency, it can be a learning curve for new contributors or require refactoring existing files.
+- **Initial Setup Complexity**: Requires careful initial setup and configuration to ensure all autoload paths are correctly defined and inflections are handled.
+- **Debugging Autoloading Issues**: While rare, issues related to incorrect file naming or path configuration can sometimes be tricky to debug.
+
+### Neutral
+
+- **Explicit Inflector Configuration**: The need to explicitly configure inflections for acronyms adds a small amount of initial setup, but this is a one-time cost for significant benefit.
+
+## Alternatives Considered
+
+### Manual Autoloading / Extensive `require_relative` Usage
+
+- **Why rejected**: Becomes unmanageable and error-prone in larger codebases. Leads to fragmented `require` statements spread across many files.
+- **Trade-offs**: Simple for very small projects, but scales poorly and hinders maintainability.
+
+### Other Autoloading Gems (e.g., `ActiveSupport::Dependencies`)
+
+- **Why rejected**: `ActiveSupport::Dependencies` is largely superseded by Zeitwerk in modern Rails and Ruby applications, and Zeitwerk is designed to be a standalone component.
+- **Trade-offs**: Might offer similar functionality but Zeitwerk is the current standard and offers better performance and explicit design for autoloading.
+
+## Related Decisions
+
+- Project structure and directory layout
+- Code style and convention guidelines
+
+## References
+
+- [Zeitwerk GitHub Repository](https://github.com/fxn/zeitwerk)
+- [Zeitwerk Documentation](https://github.com/fxn/zeitwerk#zeitwerk)
+```
+- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-003-Observability-with-dry-monitor.md
+```markdown
+# ADR-003: Observability with dry-monitor
+
+## Status
+
+Accepted
+Date: 2025-06-08
+
+## Context
+
+As the project grew in complexity, the need for better observability into key operations and internal events became critical for debugging, performance monitoring, and understanding system behavior. Without a standardized mechanism for event publishing and subscription, introducing new logging, metrics, or tracing capabilities would require intrusive modifications across various parts of the codebase. We needed a decoupled approach where components could publish events without knowing their subscribers, and subscribers could react to events without knowing their publishers.
+
+## Decision
+
+We decided to implement observability using `dry-monitor` via a central `Notifications` instance. This approach leverages `dry-monitor`'s publish/subscribe pattern to allow different parts of the application to emit events, which can then be consumed by various monitors (e.g., loggers, metrics collectors, debuggers).
+
+A specific integration includes:
+- A central `Notifications` instance, acting as the global event bus.
+- Integration with `FaradayDryMonitorLogger` (or a similar custom logger adapter) to capture HTTP request/response events from the Faraday HTTP client. This ensures that all outgoing HTTP calls are automatically instrumented and logged through the `dry-monitor` system.
+
+```ruby
+# Example (conceptual) dry-monitor setup
+# This would typically be initialized globally, e.g., in `config/initializers/monitor.rb`
+# or injected into components that need to publish/subscribe.
+
+require 'dry/monitor/notifications'
+require 'faraday/dry_monitor_logger' # Assuming this gem/class exists or is custom-defined
+
+module MyProject
+  module Core
+    class Notifications < Dry::Monitor::Notifications
+      # Custom event definitions or additional setup can go here
+    end
+
+    # Global notifications instance
+    NOTIFICATION_BUS = Notifications.new(:my_project)
+  end
+end
+
+# Example of how Faraday might be configured to use the dry-monitor logger
+# This would typically be part of the Faraday connection setup
+# conn = Faraday.new(...) do |f|
+#   f.use FaradayDryMonitorLogger, notifications: MyProject::Core::NOTIFICATION_BUS
+#   # ... other middleware
+# end
+
+# Example of subscribing to an event
+# MyProject::Core::NOTIFICATION_BUS.subscribe('http.request.finished') do |event|
+#   # Log, metric, or trace the event
+#   puts "HTTP Request finished: #{event.payload[:url]} in #{event.payload[:duration]}ms"
+# end
+```
+
+## Consequences
+
+### Positive
+
+- **Standardized Event Publishing**: Provides a consistent and decoupled way for different parts of the application to emit events without direct dependencies on logging, metrics, or tracing systems.
+- **Enhanced Observability**: Enables easy integration of various monitoring tools (logging, metrics, tracing) by simply subscribing to relevant events on the central `Notifications` instance.
+- **Improved Debugging**: Critical events can be easily logged or inspected during development and production, aiding in diagnosing issues.
+- **Testability**: Components that publish events can be tested in isolation, and monitors can be mocked or swapped out easily during testing.
+- **Extensibility**: New monitoring requirements (e.g., adding a new metric provider) can be met by adding new subscribers without modifying existing business logic.
+
+### Negative
+
+- **Adds Dependencies**: Introduces `dry-monitor` and potentially related gems (like `FaradayDryMonitorLogger`) as new project dependencies.
+- **Learning Curve**: New contributors may need to understand the `dry-monitor` concepts and the publish/subscribe pattern.
+- **Potential for Event Overload**: Without careful design, too many events or overly verbose events could lead to performance overhead or noisy logs/metrics.
+- **Event Definition Management**: Requires discipline in defining and documenting event names and their payloads to ensure consistency and usability.
+
+### Neutral
+
+- **Centralized `Notifications` Instance**: While beneficial for global reach, it means the `Notifications` instance needs to be accessible where events are published, potentially via dependency injection or a global singleton.
+
+## Alternatives Considered
+
+### Custom Logger / Direct Logging Calls
+
+- **Why rejected**: Leads to tight coupling between business logic and logging implementation. Extending to metrics or tracing would require pervasive changes.
+- **Trade-offs**: Simpler for very basic logging needs, but does not scale for comprehensive observability or multiple monitoring concerns.
+
+### Other Monitoring Libraries (e.g., `ActiveSupport::Notifications`, `Prometheus Client for Ruby`)
+
+- **Why rejected**: `ActiveSupport::Notifications` is tied to Rails and might be overkill or bring unnecessary dependencies for a non-Rails project. Direct Prometheus client integration would be too specific to metrics and not generic enough for general event publishing for debugging or logging.
+- **Trade-offs**: `ActiveSupport::Notifications` is a viable alternative for Rails projects. Direct metric libraries are good for metrics-only concerns but less flexible for a broader observability strategy.
+
+## Related Decisions
+
+- HTTP client strategy (ADR-005) due to `FaradayDryMonitorLogger` integration.
+- Error reporting strategy (ADR-004) for consistency in handling exceptions, although `dry-monitor` focuses on events.
+
+## References
+
+- [dry-monitor GitHub Repository](https://github.com/dry-rb/dry-monitor)
+- [dry-rb ecosystem documentation](https://dry-rb.org/)
+- `FaradayDryMonitorLogger` (conceptual/custom component, refers to the idea of an adapter for Faraday)
+```
+- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-004-Centralized-CLI-Error-Reporting.md
+```markdown
+# ADR-004: Centralized CLI Error Reporting Strategy
+
+## Status
+
+Accepted
+Date: 2025-06-08
+
+## Context
+
+Command-Line Interface (CLI) executables often produce various error messages, ranging from user input validation failures to unexpected system errors. Without a unified approach, each executable might handle and display errors differently, leading to an inconsistent and confusing user experience. Furthermore, debugging CLI applications becomes challenging if error output is not standardized or if critical debug information is not readily available when needed. There was a clear need to centralize error handling to ensure consistency, improve user guidance, and provide robust debugging capabilities via a debug flag.
+
+## Decision
+
+We decided to implement a `ErrorReporter` module or class responsible for centralizing CLI error reporting. This module will provide a consistent interface for handling exceptions and displaying error messages to the user.
+
+Key aspects of this decision include:
+- A dedicated `ErrorReporter` module/class to encapsulate error formatting and output logic.
+- Support for a debug flag (e.g., `--debug` or `DEBUG=true` environment variable) that, when enabled, provides more verbose error information, such as backtraces, for diagnostic purposes.
+- Standardized error message formats for different types of errors (e.g., validation errors, configuration errors, internal errors).
+- Integration into CLI executables to ensure all errors are routed through this central mechanism.
+
+```ruby
+# Example (conceptual) ErrorReporter module
+module MyProject
+  module CLI
+    module ErrorReporter
+      DEBUG_MODE = ENV['DEBUG'] == 'true' || ARGV.include?('--debug')
+
+      def self.report(exception, message: nil, exit_code: 1)
+        STDERR.puts "Error: #{message || exception.message}"
+        if DEBUG_MODE
+          STDERR.puts "Type: #{exception.class}"
+          STDERR.puts "Backtrace:\n\t#{exception.backtrace.join("\n\t")}" if exception.backtrace
+        end
+        exit(exit_code) unless exception.is_a?(SystemExit) # Prevent SystemExit from being wrapped
+      end
+
+      # Example usage within a CLI executable
+      # begin
+      #   # CLI logic here
+      # rescue StandardError => e
+      #   ErrorReporter.report(e, message: "An unexpected error occurred.")
+      # end
+    end
+  end
+end
+```
+
+## Consequences
+
+### Positive
+
+- **Consistent User Experience**: All CLI executables will present error messages in a predictable and uniform way, reducing user confusion.
+- **Simplified Error Handling**: Developers can use a single, well-defined mechanism to handle and report errors across the entire suite of CLI tools, reducing boilerplate and potential for inconsistencies.
+- **Enhanced Debugging**: The debug flag provides immediate access to detailed error information (like backtraces) directly in the terminal, significantly aiding in troubleshooting.
+- **Improved Maintainability**: Changes to error reporting logic (e.g., message formatting, logging integration) can be made in one central place, affecting all executables.
+- **Clear Separation of Concerns**: Isolates error reporting logic from core application logic.
+
+### Negative
+
+- **Initial Setup Overhead**: Requires implementing and integrating the `ErrorReporter` module into all relevant CLI executables.
+- **Potential for Over-reporting**: Without careful design, the debug mode might produce excessively verbose output that is difficult to parse.
+- **Dependency**: Introduces a new internal dependency (the `ErrorReporter` module) that all CLI tools must adhere to.
+
+### Neutral
+
+- **Explicit Debug Flag**: Relies on users or developers to explicitly enable debug mode, which is standard practice for verbose output.
+
+## Alternatives Considered
+
+### Individual Executable Error Handling
+
+- **Why rejected**: Leads to inconsistent error messages, duplicated code, and makes it difficult to apply global changes to error reporting. Debugging would be fragmented and manual.
+- **Trade-offs**: Simpler for a single, very small executable, but becomes unmanageable and error-prone as the number of executables or complexity grows.
+
+### Using a Generic Logging Library
+
+- **Why rejected**: While logging libraries can capture errors, they typically don't provide the structured, user-friendly CLI output format desired, nor do they inherently handle the debug flag for interactive CLI use as directly as a dedicated error reporter.
+- **Trade-offs**: Good for backend logging, but less tailored for immediate, actionable CLI user feedback and interactive debugging. Would still require custom formatting logic.
+
+### Raising and Rescuing `SystemExit` for all errors
+
+- **Why rejected**: While `SystemExit` is good for controlling application exit, using it for all error types can obscure the original exception context and make it harder to differentiate between different error conditions programmatically. It's typically used for intentional exits.
+- **Trade-offs**: Very simple way to terminate execution but loses valuable error metadata and can be misleading about the true nature of the error.
+
+## Related Decisions
+
+- Observability strategy (ADR-003) for broader system events and metrics.
+- CLI argument parsing strategy, as it relates to the `--debug` flag.
+
+## References
+
+- Ruby's `StandardError` and `SystemExit` classes
+- Command-line interface design best practices
+```
+- ### docs-project/current/v.0.2.0-synapse/decisions/ADR-005-HTTP-Client-Strategy-with-Faraday.md
+```markdown
+# ADR-005: HTTP Client Strategy with Faraday
+
+## Status
+
+Accepted
+Date: 2025-06-08
+
+## Context
+
+The project frequently interacts with external APIs, requiring a robust, flexible, and maintainable HTTP client. Without a standardized approach, different parts of the application might use various HTTP libraries or custom implementations, leading to inconsistent behavior, duplicated effort, and difficulty in applying global configurations (e.g., timeouts, retries, authentication, logging). There was a clear need to adopt a single, well-established HTTP client library that could be configured consistently across all API interactions, ensuring reliability, testability, and ease of development.
+
+## Decision
+
+We decided to standardize on Faraday as the primary HTTP client for all external API interactions. Faraday provides a flexible middleware architecture that allows for easy composition of various HTTP client functionalities (e.g., request/response logging, error handling, retries, caching, authentication).
+
+The implementation strategy involves:
+- Using Faraday as the underlying HTTP client library.
+- Introducing an `HTTPClient` "atom" (a low-level component or class) that encapsulates the basic Faraday connection setup and configuration. This atom will handle default middleware, connection options, and potentially base URLs.
+- Introducing an `HTTPRequestBuilder` "molecule" (a higher-level component or class) that builds upon the `HTTPClient` to construct specific API requests. This molecule will abstract away common request patterns, headers, and payload formatting, providing a consistent interface for different API calls.
+
+```ruby
+# Example (conceptual) Faraday HTTPClient atom
+require 'faraday'
+require 'faraday/retry' # Example for a common middleware
+
+module MyProject
+  module HTTP
+    class Client
+      def initialize(base_url:, notifications: nil)
+        @base_url = base_url
+        @notifications = notifications # Optional: for dry-monitor integration
+        @connection = build_connection
+      end
+
+      def connection
+        @connection
+      end
+
+      private
+
+      def build_connection
+        Faraday.new(url: @base_url) do |f|
+          f.request :json # Example: Encode request body as JSON
+          f.response :json # Example: Decode response body as JSON
+          f.response :raise_error # Raise exceptions for 4xx/5xx responses
+          f.use Faraday::Retry::Middleware # Example: Automatic retries
+          # f.use FaradayDryMonitorLogger, notifications: @notifications if @notifications # Integration with ADR-003
+          f.adapter Faraday.default_adapter # The default adapter (e.g., Net::HTTP)
+        end
+      end
+    end
+
+    # Example (conceptual) HTTPRequestBuilder molecule
+    class RequestBuilder
+      def initialize(http_client:)
+        @http_client = http_client.connection
+      end
+
+      def get(path, params: {}, headers: {})
+        @http_client.get(path, params, headers)
+      end
+
+      def post(path, body: {}, headers: {})
+        @http_client.post(path, body, headers)
+      end
+
+      # ... other HTTP methods
+    end
+  end
+end
+
+# Example usage
+# client = MyProject::HTTP::Client.new(base_url: 'https://api.example.com')
+# builder = MyProject::HTTP::RequestBuilder.new(http_client: client)
+# response = builder.get('/users/123')
+# puts response.body
+```
+
+## Consequences
+
+### Positive
+
+- **Consistent HTTP Handling**: All external API calls will be made using a unified client, ensuring consistent behavior, error handling, and configuration across the application.
+- **Faraday Ecosystem Access**: Leverages the rich ecosystem of Faraday middleware, allowing for easy integration of features like logging, caching, retries, authentication, and more.
+- **Improved Testability**: HTTP interactions can be easily mocked or stubbed using libraries compatible with Faraday (e.g., WebMock, VCR), simplifying integration tests.
+- **Clear Separation of Concerns**: The `HTTPClient` and `HTTPRequestBuilder` components provide a clean architectural separation, making the code more modular and understandable.
+- **Reduced Duplication**: Avoids writing custom HTTP client logic repeatedly for different API calls.
+
+### Negative
+
+- **New Dependency**: Introduces `faraday` and potentially other `faraday` ecosystem gems as new project dependencies, increasing the gem footprint.
+- **Configuration Overhead**: Requires initial setup and configuration of Faraday, including choosing and arranging middleware, which can be a learning curve for new developers.
+- **Abstraction Layer**: Adds a layer of abstraction (`HTTPClient`, `HTTPRequestBuilder`) which, while beneficial, means developers interact with Faraday indirectly rather than directly.
+
+### Neutral
+
+- **Middleware Complexity**: The power of Faraday's middleware can also introduce complexity if not managed carefully, requiring clear documentation of the middleware stack.
+
+## Alternatives Considered
+
+### `Net::HTTP` Directly
+
+- **Why rejected**: `Net::HTTP` is Ruby's built-in HTTP client but is low-level and lacks many features (e.g., automatic retries, request/response logging, middleware) that are crucial for modern API interactions. Implementing these features directly would involve significant boilerplate and custom code.
+- **Trade-offs**: No external dependencies. Very simple for basic, one-off requests. Becomes unwieldy for complex scenarios.
+
+### Other HTTP Client Gems (e.g., `HTTParty`, `RestClient`, `Excon`)
+
+- **Why rejected**: While many good HTTP client gems exist, Faraday was chosen for its strong middleware architecture, making it highly extensible and composable. Some alternatives might be simpler for basic use cases but lack the flexibility and ecosystem of Faraday for complex, enterprise-grade applications.
+- **Trade-offs**: Each gem has its own strengths and weaknesses. Some might be simpler for quick prototypes, while others might offer specific features (e.g., performance, specific protocol support). Faraday's extensibility was the decisive factor.
+
+## Related Decisions
+
+- Observability strategy (ADR-003) for integrating `FaradayDryMonitorLogger` and instrumenting HTTP calls.
+- CI-Aware VCR configuration (ADR-001) for robust testing of HTTP interactions without relying on external services in CI.
+
+## References
+
+- [Faraday GitHub Repository](https://github.com/lostisland/faraday)
+- [Faraday Documentation](https://lostisland.github.io/faraday/)
+- `HTTPClient` and `HTTPRequestBuilder` patterns (conceptual, from a component-based design perspective)
+```
+
+#### Root Documentation
+Location: `*.md` files in project root
+Current files:
+### CHANGELOG.md
+```markdown
+# Changelog
+
+All notable changes to this project will be documented in this file.
+
+The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
+and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
+
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
+## [v.0.2.0+tasks.5 - task.16] - CLI Integration Testing, Documentation Updates, and Code Quality Fixes
+
+### Added
+- **CLI Integration Testing**: Implemented Aruba for robust CLI integration testing.
+- **Documentation**:
+  - Comprehensive Gemini Query Guide.
+  - Updated README with Gemini integration features and improved development documentation structure.
+  - Updated project overview, architecture, and blueprint documentation.
+  - Architectural Decision Records (ADR-002, ADR-003, ADR-004, ADR-005) for key architectural decisions (Zeitwerk autoloading, dry-monitor observability, centralized CLI error reporting, Faraday HTTP client strategy).
+  - `binstup` for documentation review prompt tool.
+- **Code Quality & Testing Enhancements**:
+  - Custom RSpec matchers for HTTP and JSON assertions.
+  - Process helpers and shared helpers for integration tests.
+  - Centralized `ErrorReporter` for consistent error handling.
+  - `dry-monitor` integration for observability, including Faraday middleware events.
+  - Gem installation verification to the `bin/build` script.
+
+### Changed
+- **Build Process**: Restored `bin/test` and `bin/lint` steps to the `bin/build` script.
+- **Test Execution**: Replaced `bin/test` commands with manual verification steps in some documentation.
+- **Refactoring**: Refactored code quality improvements including removal of `ActiveSupport` and `ENV.fetch` for API keys.
+
+### Fixed
+- **Dependency Management**: Fixed Ruby 3.4 CI Bundler setup issues causing `dry-cli` loading failures.
+- **Autoloading**:
+  - Fixed module autoloading configuration issues (e.g., missing module definition files).
+  - Added `http_request_builder` inflection for Zeitwerk.
+  - Removed legacy `autoload` statements.
+- **HTTP Client & API Interaction**:
+  - Fixed Gemini Client API response handling issues and ensured `raw_body` field is restored.
+  - Preserved `v1beta` path in Gemini client `model_info` URL.
+  - Fixed HTTP client method signature issues (`build_headers`).
+  - Improved Faraday middleware integration (event registration, tests, error handling in middleware).
+  - Fixed Content-Type header on GET requests.
+  - Handled array values in query parameters.
+  - Addressed header duplication, URL concatenation, and Windows path quoting issues.
+  - Fixed JSON parsing to correctly handle different response scenarios.
+- **Testing**:
+  - Fixed integration test configuration issues (dependency loading, URL construction bug, environment setup).
+  - Fixed critical syntax error in HTTP Request Builder spec (`malformed describe block`).
+  - Fixed HTTP client test signatures to use keyword arguments.
+  - Fixed code quality test failures.
+  - Fixed VCR subprocess setup in integration tests.
+- **Code Quality & Review**:
+  - Addressed various code review feedback issues (e.g., `.DS_Store` files, event registration, performance optimizations in `JSONFormatter` and `HTTPRequestBuilder`, simplified error handling, direct class references, guard for empty candidates, HTTP status in error messages, JSON sanitization, blank string handling for API keys).
+  - Removed unused `debug_enabled` parameter.
+  - Fixed task numbers in documentation files.
+
+## [0.2.0+tasks.1] - 2025-06-08
+
+### Added
+- **LLM Integration Framework**: Complete implementation of Google Gemini AI integration
+  - `llm-gemini-query` command-line tool for querying Google Gemini API (gemini-2.0-flash-lite model)
+  - Support for prompt input from string arguments or file paths
+  - Explicit output formatting with `--format` flag (text or json)
+  - Debug mode with `--debug` flag for verbose error output
+  - Environment variable support for API key configuration (.env file)
+- **ATOM Architecture Components**:
+  - **Atoms**: HTTPClient, JSONFormatter, EnvReader for core functionality
+  - **Molecules**: APICredentials, HTTPRequestBuilder, APIResponseParser for composed behavior
+  - **Organisms**: GeminiClient, PromptProcessor for high-level AI operations
+- **HTTP Client Integration**: Faraday HTTP client for reliable API communication
+- **Comprehensive Testing Suite**:
+  - Unit tests for all ATOM components with >95% code coverage
+  - Integration tests with live API using VCR for CI-friendly testing
+  - CI-aware VCR configuration for automated testing environments
+- **Developer Experience**:
+  - `.env.example` template for API key configuration
+  - Detailed documentation for testing with VCR
+  - Examples and refactoring guides for API credentials
+
+### Changed
+- Enhanced CLI framework to support LLM command namespace
+- Updated gemspec to include Faraday dependency
+- Improved error handling with graceful API failure management
+
+## [0.1.0] - 2025-06-06
+
+### Added
+- Initial Ruby gem structure with ATOM architecture (atoms, molecules, organisms, ecosystems)
+- CLI framework using dry-cli with version command
+- Comprehensive build system with bin/build, bin/test, bin/lint scripts
+- RSpec testing framework with SimpleCov coverage reporting
+- StandardRB linting configuration
+- GitHub Actions CI/CD pipeline with multi-Ruby version testing (3.2, 3.3, 3.4)
+- Development guides and contribution documentation
+- Git workflow with commit message templates and PR templates
+
+### Changed
+- Established semantic versioning starting with v0.1.0
+- Updated project documentation structure with docs/ directory
+
+#### Project Foundation (v0.0.0 - Development Phase)
+- Created the initial project roadmap and defined initial release structure
+- Consolidated ideas into Product Requirements Document with context hydration, git aliases, markdown tasks, task capture, and UX features
+- Added architectural research and documentation fixes including ATOM architecture research
+- Established initial project structure including placeholder scripts in `bin/` and core documentation in `docs-project/`
+- Added the `docs-dev` submodule and initial `.gitignore` file
+
+[0.2.0]: https://github.com/your-org/coding-agent-tools/compare/v0.1.0...v0.2.0
+[0.1.0]: https://github.com/your-org/coding-agent-tools/releases/tag/v0.1.0
+```
+
+### README.md
+```markdown
+# Coding Agent Tools (CAT) Ruby Gem
+
+[![CI](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/cs3b/coding-agent-tools/actions/workflows/ci.yml)
+[![Gem Version](https://badge.fury.io/rb/coding_agent_tools.svg)](https://badge.fury.io/rb/coding_agent_tools)
+[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
+
+A Ruby gem providing CLI tools designed for AI coding agents and developers to streamline development workflows through predictable, standardized commands.
+
+## 🚀 Quick Start
+
+### Installation
+
+**1. Install as a published gem (once available):**
+
+```bash
+gem install coding_agent_tools
+```
+
+**2. Or, for local development/use from source:**
+
+Add this line to your application's Gemfile if you are using it as a dependency from a local path (e.g., as a submodule or a local copy):
+```ruby
+gem 'coding_agent_tools', path: '.'
+```
+Then execute:
+```bash
+bundle install
+```
+Or, if you are working directly within this cloned repository:
+```bash
+bundle install
+```
+
+After installation (either globally or via Bundler in a project), the `coding_agent_tools` command will be available.
+
+## ✨ Key Features
+
+- **LLM Integration**: Query Google Gemini and local LM Studio models
+  - **Google Gemini LLM Integration**: Direct integration with Google's Gemini API via `exe/llm-gemini-query`
+- **Git Automation**: Create repositories, generate commit messages with AI
+- **Task Management**: Navigate documentation-based task backlogs
+- **Context Tools**: Generate comprehensive project context documents
+- **Offline Support**: Work with local language models via LM Studio
+
+## 🛠 Core Commands (Planned Structure)
+
+The primary executable for the gem is `coding_agent_tools`. Here's a look at the planned command structure (specific commands and options are illustrative and will be implemented in future tasks):
+
+```bash
+# General
+coding_agent_tools --version
+coding_agent_tools --help
+coding_agent_tools help <command>
+
+# LLM Communication
+coding_agent_tools llm query --provider gemini --prompt "How to optimize Ruby performance?"
+coding_agent_tools llm query --provider lm_studio --prompt "Explain SOLID principles"
+
+# Source Control Management (SCM)
+coding_agent_tools scm repository create --provider github my-new-repo
+coding_agent_tools scm commit_with_message --intention "Refactor user authentication"
+coding_agent_tools scm log --oneline
+
+# Task Management
+coding_agent_tools task next
+coding_agent_tools task list --recent
+coding_agent_tools task new_id
+
+# Project Utilities
+coding_agent_tools project release_context
+# For development tasks related to the gem itself:
+# coding_agent_tools project test (or bundle exec rspec)
+# coding_agent_tools project lint (or bundle exec standardrb)
+# coding_agent_tools project build_gem (or gem build coding_agent_tools.gemspec)
+```
+
+*Note: The existing `bin/*` scripts will be gradually replaced or wrapped by these new gem commands.*
+
+## 🔧 Available Standalone Commands
+
+### New Standalone Commands
+
+- **`exe/llm-gemini-query`**: Directly query the Google Gemini API
+  - Usage: `exe/llm-gemini-query "Your prompt" [--file] [--format json|text] [--model MODEL_NAME] [--temperature TEMP] [--max-tokens TOKENS] [--system "SYSTEM_PROMPT"] [--debug]`
+  - Example: `exe/llm-gemini-query "What is Ruby?"`
+  - Requires: `GEMINI_API_KEY` environment variable
+
+## 🏗 Architecture
+
+The gem's library code in `lib/coding_agent_tools/` is structured using an **ATOM-based hierarchy** (Atoms, Molecules, Organisms, Ecosystems), promoting modularity and reusability:
+
+- **`lib/coding_agent_tools/atoms/`**: Smallest, indivisible utility functions or classes.
+- **`lib/coding_agent_tools/molecules/`**: Simple compositions of Atoms forming reusable operations.
+- **`lib/coding_agent_tools/organisms/`**: More complex units performing specific business logic or features.
+- **`lib/coding_agent_tools/ecosystems/`**: The largest units, representing complete subsystems (the CLI app itself is an ecosystem).
+- **`lib/coding_agent_tools/models/`**: Data structures (POROs) used across layers.
+- **`lib/coding_agent_tools/cli/`**: Contains `dry-cli` command classes.
+- **`lib/coding_agent_tools/cli.rb`**: Main `dry-cli` registry.
+
+### Core Dependencies
+
+- **Faraday**: HTTP client for API integrations (Google Gemini)
+- **dry-cli**: Command-line interface framework
+
+See the [Architecture Document](docs-project/architecture.md) for more details.
+
+## 🔧 Configuration
+
+### API Keys
+
+Create a `.env` file in your project root (copy from `.env.example`):
+
+```bash
+# Google Gemini API Key
+# Get this from: https://makersuite.google.com/app/apikey
+GEMINI_API_KEY=your_actual_gemini_api_key_here
+
+# GitHub (for repository creation)
+GITHUB_TOKEN=your-token
+```
+
+Or set environment variables directly:
+
+```bash
+# Google Gemini
+export GEMINI_API_KEY="your-api-key"
+
+# GitHub (for repository creation)
+export GITHUB_TOKEN="your-token"
+```
+
+### LM Studio
+Ensure LM Studio is running on `localhost:1234` for offline LLM queries.
+
+## 📋 Requirements
+
+- Ruby ≥ 3.4.2
+- Git CLI
+- Optional: LM Studio for offline LLM support
+
+## 🎯 Use Cases
+
+### For AI Agents
+- Deterministic CLI interface for automation
+- Reliable Git and task management operations
+- Structured JSON output with `--json` flag
+
+### For Developers
+- Rapid repository setup and configuration
+- AI-generated commit messages based on diffs
+- Streamlined task navigation in documentation-driven workflows
+
+## 🚧 Development Status
+
+Currently in active development (v0.1.0 focusing on establishing the gem structure). See [roadmap](docs-project/roadmap.md) for planned releases.
+
+## 💻 Development
+
+For complete development information including environment setup, testing, build tools, and contribution workflow, see **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**.
+
+### Quick Start for Contributors
+
+```bash
+# Clone and setup
+git clone <repository-url>
+cd coding-agent-tools
+bin/setup
+
+# Run tests and linting
+bin/test && bin/lint
+
+# Start developing
+git checkout -b feature/your-feature
+```
+
+### Key Development Resources
+
+- **[Development Guide](docs/DEVELOPMENT.md)** - Complete development workflow and tools
+- **[Setup Guide](docs/SETUP.md)** - Environment setup instructions  
+- **[Contributing](.github/CONTRIBUTING.md)** - Contribution guidelines and standards
+
+## 📚 Documentation
+
+### User Documentation
+- **[Setup Guide](docs/SETUP.md)** - Development environment setup
+- **[Development Guide](docs/DEVELOPMENT.md)** - Workflow and best practices
+- **[Contributing](.github/CONTRIBUTING.md)** - How to contribute
+
+### Project Documentation
+- [Architecture](docs-project/architecture.md) - System design and patterns
+- [Project Vision](docs-project/what-do-we-build.md) - Goals and use cases
+- [Development Guides](docs-dev/guides/) - Internal standards and processes
+
+## 🤝 Contributing
+
+We welcome contributions! Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details on:
+
+- Setting up your development environment
+- Code style and quality standards
+- Testing requirements and practices
+- Pull request process and guidelines
+- Commit message conventions
+
+This project follows documentation-driven development with structured task management in `docs-project/`. See the [project blueprint](docs-project/blueprint.md) for navigation guidance.
+
+### Quick Contribution Workflow
+
+1. Fork the repository and clone your fork
+2. Set up development environment: `bin/setup`
+3. Create a feature branch: `git checkout -b feature/name`
+4. Make your changes following our standards
+5. Test your changes: `bin/test && bin/lint`
+6. Commit with conventional format and push
+7. Open a pull request using our template
+
+## 📄 License
+
+[MIT License](LICENSE)
+```
+
+#### Gem Configuration
+Location: `Gemfile` and `*.gemspec`
+Current content:
+### Gemfile
+```ruby
+# frozen_string_literal: true
+
+source "https://rubygems.org"
+
+# Specify your gem's dependencies in coding_agent_tools.gemspec
+gemspec
+
+group :development, :test do
+  gem "rake", "~> 13.0"
+  gem "rspec", "~> 3.0"
+  gem "standard", "~> 1.3" # standardrb is provided by this gem
+  gem "pry"
+  gem "bundler-audit"
+  gem "gem-release"
+  gem "simplecov", "~> 0.22", require: false
+  gem "simplecov-html", "~> 0.12", require: false
+  gem "webmock", "~> 3.0"
+  gem "vcr", "~> 6.0"
+  gem "aruba", "~> 2.0"
+end
+```
+
+### coding_agent_tools.gemspec
+```ruby
+# frozen_string_literal: true
+
+require_relative "lib/coding_agent_tools/version"
+
+Gem::Specification.new do |spec|
+  spec.name = "coding_agent_tools"
+  spec.version = CodingAgentTools::VERSION
+  spec.authors = ["Michal Czyz"]
+  spec.email = ["opensource@cs3b.com"]
+
+  spec.summary = "A Ruby gem providing CLI tools for AI agents and developers to streamline development workflows."
+  spec.description = "The Coding Agent Tools (CAT) gem offers CLI tools for AI agents and developers to automate and standardize development tasks, including LLM interaction, Git operations, and task management."
+  spec.homepage = "https://github.com/your-org/coding-agent-tools"
+  spec.license = "MIT"
+  spec.required_ruby_version = ">= 3.2.0"
+
+  spec.metadata["allowed_push_host"] = "https://rubygems.org"
+
+  spec.metadata["homepage_uri"] = spec.homepage
+  spec.metadata["source_code_uri"] = "https://github.com/your-org/coding-agent-tools"
+  spec.metadata["changelog_uri"] = "https://github.com/your-org/coding-agent-tools/blob/main/CHANGELOG.md"
+
+  # Specify which files should be added to the gem when it is released.
+  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
+  gemspec = File.basename(__FILE__)
+  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
+    ls.readlines("\x0", chomp: true).reject do |f|
+      (f == gemspec) ||
+        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
+    end
+  end
+  spec.bindir = "exe"
+  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
+  spec.require_paths = ["lib"]
+
+  # Uncomment to register a new dependency of your gem
+  # spec.add_dependency "example-gem", "~> 1.0"
+  spec.add_dependency "dotenv", "~> 2.0"
+  spec.add_dependency "dry-cli"
+  spec.add_dependency "faraday", "~> 2.0"
+  spec.add_dependency "zeitwerk", "~> 2.6"
+  spec.add_dependency "dry-monitor", "~> 1.0"
+  spec.add_dependency "dry-configurable", "~> 1.0" # dry-monitor typically depends on this
+  spec.add_dependency "addressable", "~> 2.8"
+
+  # For more information and examples about making a new gem, check out our
+  # guide at: https://bundler.io/guides/creating_gem.html
+end
+```
+
+### Current Project State
+
+#### Test Coverage
+Current coverage: 91.37% (974/1066 lines, 27 files)
+Target coverage: 90%
+
+#### StandardRB Status
+Current offenses: No offenses detected
+
+#### Gem Dependencies
+Current dependencies:
+- rake ~> 13.0 (development)
+- rspec ~> 3.0 (development)
+- standard ~> 1.3 (development)
+- pry any (development)
+- bundler-audit any (development)
+- gem-release any (development)
+- simplecov ~> 0.22 (development)
+- simplecov-html ~> 0.12 (development)
+- webmock ~> 3.0 (development)
+- vcr ~> 6.0 (development)
+- aruba ~> 2.0 (development)
+
+## Your Comprehensive Code Review Task
+
+### Phase 1: Architectural Compliance Analysis
+
+Analyze how the changes align with ATOM architecture:
+
+**1. Atom-Level Components**
+- Are new atoms truly atomic and reusable?
+- Do atoms have single, clear responsibilities?
+- Are atoms properly isolated with no external dependencies?
+
+**2. Molecule-Level Composition**
+- Do molecules properly compose atoms?
+- Is the composition logic clear and testable?
+- Are molecules focused on orchestration rather than implementation?
+
+**3. Organism-Level Integration**
+- Do organisms properly coordinate molecules?
+- Is business logic appropriately placed?
+- Are organisms maintaining proper boundaries?
+
+**4. Ecosystem-Level Patterns**
+- Does the change maintain ecosystem cohesion?
+- Are cross-cutting concerns properly addressed?
+- Is the plugin/extension architecture respected?
+
+### Phase 2: Ruby Gem Best Practices Review
+
+**1. Code Quality & Style**
+- [ ] Follows Ruby idioms and conventions
+- [ ] StandardRB compliance (or justified exceptions)
+- [ ] Consistent naming conventions
+- [ ] Proper use of Ruby language features
+- [ ] No code smells or anti-patterns
+
+**2. Gem Structure**
+- [ ] Proper file organization following gem conventions
+- [ ] Correct use of lib/ directory structure
+- [ ] Appropriate version management
+- [ ] Gemspec file correctness
+
+**3. Dependencies**
+- [ ] Minimal dependency footprint
+- [ ] Version constraints appropriately specified
+- [ ] No unnecessary runtime dependencies
+- [ ] Development dependencies properly scoped
+
+**4. Performance Considerations**
+- [ ] No obvious performance bottlenecks
+- [ ] Efficient algorithms and data structures
+- [ ] Proper use of lazy evaluation where appropriate
+- [ ] Memory usage considerations
+
+### Phase 3: Test Quality Assessment
+
+**1. Test Coverage**
+- Is every new method/class adequately tested?
+- Are edge cases covered?
+- Are error conditions tested?
+- Is the happy path thoroughly tested?
+
+**2. Test Design**
+- [ ] Tests follow RSpec best practices
+- [ ] Clear test descriptions using RSpec DSL
+- [ ] Proper use of contexts and examples
+- [ ] DRY principles in test code
+- [ ] Fast, isolated unit tests
+
+**3. Test Types**
+- [ ] Unit tests for atoms
+- [ ] Integration tests for molecules
+- [ ] System tests for organisms
+- [ ] CLI tests for command-line interface
+
+**4. Test Quality Metrics**
+- [ ] Tests are deterministic (no flaky tests)
+- [ ] Tests are independent and can run in any order
+- [ ] Tests use appropriate doubles/mocks/stubs
+- [ ] Tests verify behavior, not implementation
+
+### Phase 4: CLI Design Review
+
+**1. Command Structure**
+- [ ] Commands follow Unix philosophy
+- [ ] Clear, intuitive command naming
+- [ ] Consistent flag/option patterns
+- [ ] Proper use of subcommands
+
+**2. User Experience**
+- [ ] Helpful error messages
+- [ ] Appropriate output formatting
+- [ ] Progress indicators for long operations
+- [ ] Proper exit codes
+
+**3. AI Agent Compatibility**
+- [ ] Machine-parseable output options
+- [ ] Structured error reporting
+- [ ] Predictable behavior
+- [ ] Clear documentation of all options
+
+**4. Help Documentation**
+- [ ] Comprehensive --help output
+- [ ] Examples in help text
+- [ ] Clear option descriptions
+- [ ] Version information available
+
+### Phase 5: Security & Safety Analysis
+
+**1. Input Validation**
+- All user inputs properly validated?
+- SQL injection prevention (if applicable)?
+- Command injection prevention?
+- Path traversal prevention?
+
+**2. Data Handling**
+- Sensitive data properly protected?
+- Appropriate use of ENV variables?
+- No hardcoded credentials?
+- Secure defaults?
+
+**3. Dependencies Security**
+- Known vulnerabilities in dependencies?
+- Unnecessary permission requirements?
+- Appropriate gem signing/verification?
+
+### Phase 6: API Design & Maintainability
+
+**1. Public API Surface**
+- [ ] Clear separation of public/private APIs
+- [ ] Consistent method signatures
+- [ ] Appropriate use of keyword arguments
+- [ ] Future-proof design patterns
+
+**2. Error Handling**
+- [ ] Custom exceptions where appropriate
+- [ ] Informative error messages
+- [ ] Proper error propagation
+- [ ] Graceful degradation
+
+**3. Code Maintainability**
+- [ ] Self-documenting code
+- [ ] Appropriate code comments
+- [ ] YARD documentation for public APIs
+- [ ] Reasonable method/class sizes
+
+**4. Backward Compatibility**
+- [ ] Breaking changes properly identified
+- [ ] Deprecation warnings added
+- [ ] Migration path provided
+- [ ] Semantic versioning respected
+
+### Phase 7: Detailed Code Analysis
+
+For each significant code change:
+
+#### [File: path/to/file.rb]
+
+**Code Quality Issues:**
+- Issue: [Description]
+  - Severity: [Critical/High/Medium/Low]
+  - Location: [Line numbers]
+  - Suggestion: [How to fix]
+  - Example: [Code example if helpful]
+
+**Best Practice Violations:**
+- Violation: [Description]
+  - Impact: [Why this matters]
+  - Recommendation: [Better approach]
+
+**Refactoring Opportunities:**
+- Opportunity: [Description]
+  - Current approach: [What's there now]
+  - Suggested approach: [Better way]
+  - Benefits: [Why change it]
+
+### Phase 8: Prioritized Action Items
+
+## 🔴 CRITICAL ISSUES (Must fix before merge)
+*Security vulnerabilities, data corruption risks, or breaking changes*
+- [ ] [Specific issue with file:line and fix description]
+
+## 🟡 HIGH PRIORITY (Should fix before merge)
+*Significant bugs, performance issues, or design flaws*
+- [ ] [Specific issue with file:line and fix description]
+
+## 🟢 MEDIUM PRIORITY (Consider fixing)
+*Code quality, maintainability, or minor bugs*
+- [ ] [Specific issue with file:line and fix description]
+
+## 🔵 SUGGESTIONS (Nice to have)
+*Style improvements, refactoring opportunities*
+- [ ] [Specific issue with file:line and fix description]
+
+### Phase 9: Positive Feedback
+
+**Well-Done Aspects:**
+- [What was done particularly well]
+- [Good patterns that should be replicated]
+- [Clever solutions worth highlighting]
+
+**Learning Opportunities:**
+- [Interesting techniques used]
+- [Patterns that could benefit the team]
+
+## Expected Output Format
+
+Structure your comprehensive review as:
+
+```markdown
+# Code Review Analysis
+
+## Executive Summary
+[2-3 sentences summarizing the overall quality and key concerns]
+
+## Architectural Compliance Assessment
+### ATOM Pattern Adherence
+[Analysis of how well changes follow ATOM architecture]
+
+### Identified Violations
+[List any architectural anti-patterns found]
+
+## Ruby Gem Best Practices
+### Strengths
+[What was done well according to Ruby standards]
+
+### Areas for Improvement
+[What could be more idiomatic or better structured]
+
+## Test Quality Analysis
+### Coverage Impact
+[How changes affect test coverage]
+
+### Test Design Issues
+[Problems with test structure or approach]
+
+### Missing Test Scenarios
+[What scenarios need additional testing]
+
+## Security Assessment
+### Vulnerabilities Found
+[Any security issues discovered]
+
+### Recommendations
+[How to address security concerns]
+
+## API Design Review
+### Public API Changes
+[Impact on gem's public interface]
+
+### Breaking Changes
+[Any backward compatibility issues]
+
+## Detailed Code Feedback
+[File-by-file analysis using Phase 7 format]
+
+## Prioritized Action Items
+[Use 4-tier priority system from Phase 8]
+
+## Performance Considerations
+[Any performance impacts or opportunities]
+
+## Refactoring Recommendations
+[Larger structural improvements to consider]
+
+## Positive Highlights
+[What was done exceptionally well]
+
+## Risk Assessment
+[Potential risks if changes are merged as-is]
+
+## Approval Recommendation
+[ ] ✅ Approve as-is
+[ ] ✅ Approve with minor changes
+[ ] ⚠️  Request changes (non-blocking)
+[ ] ❌ Request changes (blocking)
+
+### Justification
+[Clear reasoning for the recommendation]
+```
+
+## Review Checklist
+
+Before completing your review, ensure you've considered:
+
+**Code Quality**
+- [ ] All new code follows Ruby idioms
+- [ ] No obvious bugs or logic errors
+- [ ] Appropriate error handling
+- [ ] Clear variable and method names
+
+**Architecture**
+- [ ] ATOM pattern properly followed
+- [ ] Proper separation of concerns
+- [ ] No circular dependencies
+- [ ] Clear module boundaries
+
+**Testing**
+- [ ] All new code has tests
+- [ ] Tests are meaningful and thorough
+- [ ] No decrease in coverage
+- [ ] Tests follow RSpec conventions
+
+**Documentation**
+- [ ] Public APIs documented
+- [ ] Complex logic explained
+- [ ] CHANGELOG entry needed?
+- [ ] README updates needed?
+
+**Performance**
+- [ ] No obvious bottlenecks
+- [ ] Appropriate algorithm choices
+- [ ] Resource usage considered
+- [ ] Scalability implications addressed
+
+**Security**
+- [ ] Input validation present
+- [ ] No security vulnerabilities
+- [ ] Secrets handled properly
+- [ ] Dependencies are safe
+
+## Critical Success Factors
+
+Your review must be:
+1. **Constructive**: Focus on improvement, not criticism
+2. **Specific**: Provide exact locations and examples
+3. **Actionable**: Every issue should have a suggested fix
+4. **Educational**: Help the author learn and grow
+5. **Balanced**: Acknowledge both strengths and weaknesses
+
+Begin your comprehensive code review analysis now.
diff --git a/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-sonnet-3.7-thinking.md b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-sonnet-3.7-thinking.md
new file mode 100644
index 0000000..fd6ccdc
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-sonnet-3.7-thinking.md
@@ -0,0 +1,207 @@
+# Code Review Analysis
+
+## Executive Summary
+The implementation of model override flags and LM Studio query commands is very well executed, showcasing excellent adherence to ATOM architecture and Ruby best practices. The code demonstrates high-quality test coverage, good error handling, and maintainable design. While there are minor opportunities for reducing duplication and enhancing error handling, there are no critical issues that would block approval.
+
+## Architectural Compliance Assessment
+### ATOM Pattern Adherence
+The changes exemplify strong ATOM architecture compliance:
+
+- **Atoms**: No new atoms introduced, but existing atoms are appropriately reused.
+- **Molecules**: The new `Model` molecule is well-designed with clear responsibilities, proper encapsulation, and necessary behavior for representing model metadata.
+- **Organisms**: The `LMStudioClient` organism correctly orchestrates molecules (HTTPRequestBuilder, APIResponseParser), properly encapsulates business logic, and maintains clear boundaries and responsibilities.
+- **Ecosystems**: New CLI commands are seamlessly integrated into the existing ecosystem using the established dry-cli patterns. Command registration is properly handled in the CLI registry.
+
+### Identified Violations
+No significant architectural violations were found. The code maintains excellent separation of concerns and follows established patterns.
+
+## Ruby Gem Best Practices
+### Strengths
+- Consistent use of keyword arguments for flexible and clear method signatures
+- Strong error handling with informative messages and appropriate exit codes
+- Excellent use of Ruby's OOP features with clear method naming and encapsulation
+- Proper gem structure with executables in `exe/`, library code in `lib/`, and tests in `spec/`
+- Thoughtful use of Ruby idioms like predicate methods ending with `?` (e.g., `default?`)
+
+### Areas for Improvement
+- Some code duplication exists in the executable scripts which could be extracted to reduce maintenance overhead
+- A few instances of nested conditionals in error handling could be simplified
+- Some hardcoded values (like role names and model formatting rules) could be extracted as constants for better maintainability
+
+## Test Quality Analysis
+### Coverage Impact
+The changes include comprehensive test coverage across multiple levels:
+- Unit tests for new classes (`LMStudioClient`, `Model`, CLI commands)
+- Integration tests using Aruba and VCR for CLI commands
+- Edge case handling (server unavailability, invalid models, special character handling)
+
+All this maintains the high test coverage standard of the project.
+
+### Test Design Issues
+No significant test design issues identified. The tests follow RSpec best practices with:
+- Clear contexts and descriptions
+- Appropriate use of mocks and stubs
+- Good isolation of test cases
+- Comprehensive assertions
+
+### Missing Test Scenarios
+The test coverage appears comprehensive, addressing:
+- Happy paths (successful queries)
+- Error paths (server unavailable, invalid models)
+- Edge cases (special characters, Unicode, long prompts)
+
+No notable missing scenarios identified.
+
+## Security Assessment
+### Vulnerabilities Found
+No security vulnerabilities identified. The code properly:
+- Validates inputs
+- Checks server availability
+- Handles errors gracefully
+- Uses environment variables for configuration
+
+### Recommendations
+- Consider adding a timeout parameter to LM Studio HTTP requests to prevent potential hanging in case of slow local server responses
+
+## API Design Review
+### Public API Changes
+The changes add well-designed new commands to the CLI surface:
+- `llm-gemini-models` and `llm-lmstudio-models` for listing available models
+- `llm-lmstudio-query` for querying local LM Studio models
+- Support for `--model` flag on query commands
+
+These additions are consistent with existing commands and follow established patterns.
+
+### Breaking Changes
+No breaking changes identified. The new functionality enhances existing features without disrupting current behavior.
+
+## Detailed Code Feedback
+
+### File: lib/coding_agent_tools/organisms/lm_studio_client.rb
+
+**Code Quality Issues:**
+- Issue: Complex nested validation in `extract_generated_text` method
+  - Severity: Low
+  - Location: Lines 160-202
+  - Suggestion: Consider using Ruby's `dig` method or a more concise validation approach
+  - Example:
+    ```ruby
+    # Instead of multiple nested conditionals
+    choice = data.dig(:choices, 0)
+    return error_message unless choice.is_a?(Hash)
+
+    message = choice.dig(:message)
+    return error_message unless message.is_a?(Hash)
+
+    content = message.dig(:content)
+    return error_message if content.nil?
+    ```
+
+**Refactoring Opportunities:**
+- Opportunity: Hardcoded role values in `build_generation_payload`
+  - Current approach: Direct string literals for "system" and "user" roles
+  - Suggested approach: Define constants like `ROLE_SYSTEM = "system"` and `ROLE_USER = "user"`
+  - Benefits: Improves maintainability if API role names change
+
+### File: lib/coding_agent_tools/molecules/model.rb
+
+This is an excellent example of a well-designed molecule. It has:
+- Clear responsibility (representing a model with metadata)
+- Proper encapsulation with accessor methods
+- Implementation of necessary behavior (equality, hashing, serialization)
+- Good separation of concerns
+
+No significant issues identified.
+
+### File: lib/coding_agent_tools/cli/commands/llm/models.rb and lms/models.rb
+
+**Code Quality Issues:**
+- Issue: Model name formatting logic in `format_model_name` using case statements
+  - Severity: Low
+  - Location: Around lines 70-85
+  - Suggestion: Consider a more flexible mapping approach for model name formatting
+  - Example:
+    ```ruby
+    WORD_FORMATTING = {
+      "gemini" => "Gemini",
+      "flash" => "Flash",
+      # etc.
+    }.freeze
+
+    def format_model_name(model_name)
+      words = name.split("-").map do |word|
+        WORD_FORMATTING[word.downcase] || word.capitalize
+      end
+      words.join(" ")
+    end
+    ```
+
+**Refactoring Opportunities:**
+- Opportunity: Duplicated code between `llm/models.rb` and `lms/models.rb`
+  - Current approach: Similar code structure with minor differences
+  - Suggested approach: Extract common functionality to a shared base class or module
+  - Benefits: Reduces duplication and makes future changes easier to maintain
+
+### File: exe/llm-gemini-models, exe/llm-lmstudio-models, exe/llm-lmstudio-query
+
+**Code Quality Issues:**
+- Issue: Significant code duplication across executable scripts
+  - Severity: Medium
+  - Location: Throughout these files
+  - Suggestion: Create a shared helper method or template generation approach
+
+**Best Practice Violations:**
+- Violation: Each executable duplicates output capture and error handling logic
+  - Impact: Increases maintenance burden; changes need to be applied to multiple files
+  - Recommendation: Extract common functionality to a shared module or generate scripts from templates
+
+## Prioritized Action Items
+
+### 🟡 HIGH PRIORITY (Should fix before merge)
+*No high priority issues identified*
+
+### 🟢 MEDIUM PRIORITY (Consider fixing)
+- [ ] Reduce code duplication in executable scripts (exe/llm-gemini-models, exe/llm-lmstudio-models, exe/llm-lmstudio-query)
+- [ ] Consider refactoring the nested validation logic in LMStudioClient's extract_generated_text method to make it more concise and maintainable
+
+### 🔵 SUGGESTIONS (Nice to have)
+- [ ] Use constants for hardcoded string values like role names ("system", "user") in LMStudioClient
+- [ ] Consider a more scalable approach to model name formatting in the models commands
+- [ ] Extract common functionality between the similar CLI command classes (llm/models.rb and lms/models.rb)
+- [ ] Add more comments to complex methods like extract_generated_text for better maintainability
+
+## Performance Considerations
+The implementation appears to have good performance characteristics:
+- Efficient model filtering with simple string matching (appropriate for small lists)
+- Proper HTTP request construction and handling
+- Good default timeouts and error handling for network operations
+- Appropriate use of object caching and lazy loading where needed
+
+## Refactoring Recommendations
+Beyond the specific opportunities mentioned above:
+1. Consider creating a shared base class for model listing commands to reduce duplication
+2. Explore using a template system for generating the executable scripts
+3. Look into extracting common error handling patterns into a shared module
+
+## Positive Highlights
+- Excellent adherence to ATOM architecture principles
+- Comprehensive test coverage with meaningful assertions
+- Strong error handling throughout with clear messages
+- Well-designed CLI interface with consistent patterns
+- Good separation of concerns in all components
+- The `Model` molecule is a great example of a clean, focused component
+
+## Risk Assessment
+The changes present minimal risk:
+- No breaking changes to existing functionality
+- Comprehensive test coverage
+- Good error handling
+- Clear separation of concerns
+
+The only minor risk is the maintenance overhead from some code duplication, but this doesn't impact functionality.
+
+## Approval Recommendation
+[✅] Approve with minor changes
+
+### Justification
+The implementation demonstrates excellent adherence to the project's architectural patterns, Ruby best practices, and testing standards. The code is well-structured, readable, and maintainable. While there are opportunities for reducing duplication and enhancing some aspects of the implementation, none of these issues are critical or would significantly impact the functionality or maintainability of the codebase. The suggested improvements can be addressed either before merging or in future iterations.
diff --git a/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-user.md b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-user.md
new file mode 100644
index 0000000..b8be101
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-user.md
@@ -0,0 +1,49 @@
+We should move molecules/model to models/llm_modl_info
+
+Following those house rules:
+
+Class kind 	Directory / namespace	Why
+Pure data carrierattributes + maybe trivial helpers, no outside IO	lib/coding_agent_tools/models/llm_model_info.rb CodingAgentTools::Models::LlmModelInfo	Matches Models = data structures definition; easy for all layers to require/use.
+Small behaviour-oriented helper that does something(e.g., token-cost calculator that calls atoms)	lib/coding_agent_tools/molecules/	Molecules are “simple compositions of atoms that form a meaningful, reusable operation”.
+
+Rule of thumb
+	•	No IO, no orchestration ⇒ Models/
+	•	Composes atoms to perform work ⇒ Molecules/
+	•	Coordinates multiple molecules, maybe talks to adapters ⇒ Organisms/
+
+Suggested file
+
+# lib/coding_agent_tools/models/llm_model_info.rb
+module CodingAgentTools
+  module Models
+    # Value object describing an LLM that CAT can talk to
+    # This is intentionally immutable; create a new instance for changes.
+    LlmModelInfo = Struct.new(
+      :provider,        # :gemini, :openai, :local etc.
+      :name,            # "gemini-1.5-pro", "gpt-4o-mini"…
+      :context_window,  # tokens
+      :max_tokens,      # tokens
+      :temperature,     # default temp
+      :cost_per_1k,     # optional billing info
+      keyword_init: true
+    ) do
+      # Optional convenience helpers are fine
+      def chat_capable?
+        provider != :openai || name.start_with?("gpt")
+      end
+    end
+  end
+end
+
+Migration steps
+	1.	Move the file to lib/coding_agent_tools/models/.
+	2.	Update any require paths (require 'coding_agent_tools/models/llm_model_info').
+	3.	Adjust namespaces in callers (Models::LlmModelInfo.new(...)).
+	4.	If Zeitwerk is autoloading, no extra config needed—folder name matches namespace.
+
+Why this keeps the mental model clean
+	•	Readers instantly know “anything under models/ is a dumb data object” without wondering if it hides logic.
+	•	Molecules remain action-oriented, preventing them from becoming a catch-all.
+	•	If one day you decide to persist LLM metadata to a YAML file or DB, you can either extend this object or introduce a repository/adapter layer without breaking API users.
+
+So despite the “model” name collision with Rails, sticking to Models for lightweight POROs is perfectly idiomatic in your ATOM variant.
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
diff --git a/docs-project/current/v.0.2.0-synapse/reflections/20250615-atom-architecture-refactoring-task-creation.md b/docs-project/current/v.0.2.0-synapse/reflections/20250615-atom-architecture-refactoring-task-creation.md
new file mode 100644
index 0000000..a7e0fef
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/reflections/20250615-atom-architecture-refactoring-task-creation.md
@@ -0,0 +1,22 @@
+# Reflections Template
+
+## Stop Doing
+
+- Placing data structures in molecules/ when they don't compose atoms or perform meaningful operations
+- Mixing architectural concerns by having pure data carriers in behavior-oriented namespaces
+- Creating tasks without first understanding the full dependency chain and usage patterns
+
+## Continue Doing
+
+- Following ATOM architecture house rules consistently across the codebase
+- Using code review feedback as input for structured task creation
+- Performing thorough directory audits before making architectural changes
+- Creating detailed implementation plans with embedded tests for verification
+- Maintaining backward compatibility during refactoring by preserving public APIs
+
+## Start Doing
+
+- Proactively identifying other classes that might be misplaced according to ATOM principles
+- Creating architectural decision records (ADRs) when making significant structural changes
+- Adding more granular tests around class behavior to catch regressions during refactoring
+- Documenting the rationale for architectural decisions in code comments for future maintainers
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
 
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.13-Create-New-ADRs-for-Architectural-Decisions.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.13-Create-New-ADRs-for-Architectural-Decisions.md
index 3bb4963..03e16cc 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.13-Create-New-ADRs-for-Architectural-Decisions.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.13-Create-New-ADRs-for-Architectural-Decisions.md
@@ -1,6 +1,6 @@
 ---
 id: v.0.2.0+task.13
-status: completed
+status: done
 priority: high
 estimate: 6h
 dependencies: [v.0.2.0+task.1]
@@ -125,4 +125,4 @@ Create four new Architecture Decision Records (ADRs) to document the significant
 - `docs-project/decisions/ADR-001-CI-Aware-VCR-Configuration.md` for format reference
 - `docs-dev/workflow-instructions/create-adr.wf.md` for ADR creation workflow
 - Task.1 implementation code for technical accuracy
-- `docs-dev/guides/documentation.g.md` for style guidelines
\ No newline at end of file
+- `docs-dev/guides/documentation.g.md` for style guidelines
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.15-Final-Documentation-Review-and-Consistency-Check.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.15-Final-Documentation-Review-and-Consistency-Check.md
index 237297c..74396eb 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.15-Final-Documentation-Review-and-Consistency-Check.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.15-Final-Documentation-Review-and-Consistency-Check.md
@@ -1,6 +1,6 @@
 ---
 id: v.0.2.0+task.15
-status: pending
+status: blocked
 priority: low
 estimate: 4h
 dependencies: [v.0.2.0+task.9, v.0.2.0+task.10, v.0.2.0+task.11, v.0.2.0+task.12, v.0.2.0+task.13, v.0.2.0+task.14]
@@ -152,4 +152,4 @@ Perform a comprehensive final review of all project documentation to ensure cons
 - `coding-agent-tools/docs-project/current/v.0.2.0-synapse/code-review/task.1.reviewed/suggestions-gemini.md` (lines 178-179)
 - All documentation files updated in previous tasks (v.0.2.0+task.9 through v.0.2.0+task.14)
 - `docs-dev/guides/documentation.g.md` for style guidelines
-- `docs-dev/tools/lint-md-links.rb` for automated link checking if available
\ No newline at end of file
+- `docs-dev/tools/lint-md-links.rb` for automated link checking if available
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.17-Refactor-Model-Class-to-Follow-ATOM-Architecture-Pattern.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.17-Refactor-Model-Class-to-Follow-ATOM-Architecture-Pattern.md
new file mode 100644
index 0000000..573e14b
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.17-Refactor-Model-Class-to-Follow-ATOM-Architecture-Pattern.md
@@ -0,0 +1,141 @@
+---
+id: v.0.2.0+task.17
+status: done
+priority: medium
+estimate: 3h
+dependencies: []
+---
+
+# Refactor Model Class to Follow ATOM Architecture Pattern
+
+## 0. Directory Audit ✅
+
+_Command run:_
+
+```bash
+tree -L 3 lib/coding_agent_tools | head -20
+```
+
+_Result excerpt:_
+
+```
+lib/coding_agent_tools
+├── atoms
+│   ├── env_reader.rb
+│   ├── http_client.rb
+│   └── json_formatter.rb
+├── atoms.rb
+├── cli
+│   └── commands
+│       ├── llm
+│       └── lms
+├── cli_registry.rb
+├── cli.rb
+├── ecosystems
+├── ecosystems.rb
+├── error_reporter.rb
+├── error.rb
+├── middlewares
+│   └── faraday_dry_monitor_logger.rb
+├── models
+├── models.rb
+```
+
+## Objective
+
+Move the `Molecules::Model` class to `Models::LlmModelInfo` following the ATOM architecture house rules to transform it from a behavior-oriented helper to a pure data carrier structure. This aligns with the architectural principle that models should contain no outside IO and serve as immutable data structures, while molecules should focus on simple compositions of atoms that perform meaningful operations.
+
+## Scope of Work
+
+- Move `lib/coding_agent_tools/molecules/model.rb` to `lib/coding_agent_tools/models/llm_model_info.rb`
+- Transform class from behavior-oriented `Molecules::Model` to data-focused `Models::LlmModelInfo` using Struct
+- Update all require statements and class references in dependent files
+- Update namespace usage throughout the codebase
+- Remove the old molecules/model.rb file
+- Ensure all tests continue to pass
+
+### Deliverables
+
+#### Create
+
+- `lib/coding_agent_tools/models/llm_model_info.rb` - New Struct-based immutable value object
+
+#### Modify
+
+- `lib/coding_agent_tools/cli/commands/llm/models.rb` - Update requires and class references
+- `lib/coding_agent_tools/cli/commands/lms/models.rb` - Update requires and class references  
+- `spec/coding_agent_tools/cli/commands/llm/models_spec.rb` - Update class references in tests
+- `spec/coding_agent_tools/cli/commands/lms/models_spec.rb` - Update class references in tests
+
+#### Delete
+
+- `lib/coding_agent_tools/molecules/model.rb` - Remove old file after migration
+
+## Phases
+
+1. **Audit** - Verify current usage and dependencies
+2. **Create** - Implement new LlmModelInfo struct in models directory
+3. **Migrate** - Update all require statements and class references
+4. **Test** - Verify all tests pass with new structure
+5. **Cleanup** - Remove old molecules/model.rb file
+
+## Implementation Plan
+
+### Planning Steps
+
+* [x] Analyze current Model class API to ensure new Struct maintains compatibility
+  > TEST: API Compatibility Check
+  > Type: Pre-condition Check
+  > Assert: All public methods and attributes are identified and documented
+  > Command: grep -n "def\|attr_" lib/coding_agent_tools/molecules/model.rb
+* [ ] Review all usages to understand required interface methods
+* [ ] Plan Struct design with keyword_init and helper methods as needed
+
+### Execution Steps
+
+- [x] Create new `lib/coding_agent_tools/models/llm_model_info.rb` with Struct-based implementation
+  > TEST: New File Structure
+  > Type: Action Validation
+  > Assert: New file exists and contains properly structured LlmModelInfo Struct
+  > Command: test -f lib/coding_agent_tools/models/llm_model_info.rb && ruby -c lib/coding_agent_tools/models/llm_model_info.rb
+- [x] Update require statement in `lib/coding_agent_tools/cli/commands/llm/models.rb`
+- [x] Update class references from `Molecules::Model` to `Models::LlmModelInfo` in llm/models.rb
+- [x] Update require statement in `lib/coding_agent_tools/cli/commands/lms/models.rb`
+- [x] Update class references from `Molecules::Model` to `Models::LlmModelInfo` in lms/models.rb
+- [x] Update class references in `spec/coding_agent_tools/cli/commands/llm/models_spec.rb`
+- [x] Update class references in `spec/coding_agent_tools/cli/commands/lms/models_spec.rb`
+- [x] Run all tests to verify functionality is preserved
+  > TEST: All Tests Pass
+  > Type: Action Validation
+  > Assert: All tests pass after the refactoring
+  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/llm/models_spec.rb spec/coding_agent_tools/cli/commands/lms/models_spec.rb
+- [x] Delete old `lib/coding_agent_tools/molecules/model.rb` file
+- [x] Run full test suite to ensure no regressions
+  > TEST: Full Test Suite
+  > Type: Action Validation
+  > Assert: Complete test suite passes with no regressions
+  > Command: bundle exec rspec
+
+## Acceptance Criteria
+
+- [x] New `Models::LlmModelInfo` Struct is created with all required attributes (id, name, description, default)
+- [x] All require statements updated to point to new models/llm_model_info location
+- [x] All class references changed from `Molecules::Model` to `Models::LlmModelInfo`
+- [x] All existing functionality preserved (to_s, to_h, to_json_hash, ==, hash methods)
+- [x] All tests pass without modification to test logic
+- [x] Old molecules/model.rb file is removed
+- [x] New class follows Struct pattern with keyword_init: true as suggested in code review
+
+## Out of Scope
+
+- ❌ Changing the public API or method signatures of the class
+- ❌ Modifying test expectations or logic beyond namespace updates
+- ❌ Adding new functionality or features to the class
+- ❌ Refactoring other molecules that don't violate ATOM architecture principles
+
+## References
+
+- Code Review Document: `docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-user.md`
+- ATOM Architecture House Rules mentioned in code review
+- Current implementation: `lib/coding_agent_tools/molecules/model.rb`
+- Target pattern: Struct-based immutable value object with keyword_init
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.18-Fix-CI-Fragility-in-LMS-Integration-Specs.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.18-Fix-CI-Fragility-in-LMS-Integration-Specs.md
new file mode 100644
index 0000000..6eb1249
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.18-Fix-CI-Fragility-in-LMS-Integration-Specs.md
@@ -0,0 +1,122 @@
+---
+id: v.0.2.0+task.18
+status: done
+priority: high
+estimate: 4h
+dependencies: []
+---
+
+# Fix CI Fragility in LMS Integration Specs
+
+## 0. Directory Audit ✅
+
+_Command run:_
+
+```bash
+tree -L 3 spec/ | grep -E "(lm_studio|lms|integration)" | head -10
+```
+
+_Result excerpt:_
+
+```
+spec/
+├── integration/
+│   ├── lm_studio_client_spec.rb
+│   └── cli/
+│       └── commands/
+│           └── lms/
+└── support/
+    └── shared_examples/
+```
+
+## Objective
+
+Replace raw Net::HTTP probes in LMS integration specs to prevent CI test failures and coverage gaps. The current implementation uses direct HTTP calls that make tests fragile and unreliable in CI environments.
+
+## Scope of Work
+
+- Identify all instances of raw Net::HTTP usage in LMS integration specs
+- Replace with VCR-wrapped probes or WebMock configuration
+- Ensure test isolation and repeatability across different environments
+- Maintain existing test coverage while improving reliability
+
+### Deliverables
+
+#### Modify
+
+- spec/integration/lm_studio_client_spec.rb
+- spec/support/vcr_setup.rb (if exists, or create)
+- Related LMS integration test files
+
+#### Create
+
+- VCR cassettes for LMS API interactions
+- WebMock configuration for test isolation
+
+## Phases
+
+1. Audit - Identify all raw Net::HTTP usage in LMS specs
+2. Design - Choose between VCR or WebMock approach
+3. Implement - Replace raw HTTP calls with chosen solution
+4. Verify - Ensure all tests pass consistently in CI
+
+## Implementation Plan
+
+### Planning Steps
+
+* [x] Analyze current LMS integration specs to identify raw Net::HTTP usage patterns
+  > TEST: HTTP Usage Analysis Complete
+  > Type: Pre-condition Check
+  > Assert: All instances of raw Net::HTTP calls are documented
+  > Command: grep -r "Net::HTTP" spec/ --include="*lm*" --include="*lms*"
+  > RESULT: Found 5 instances in spec/integration/llm_lmstudio_query_integration_spec.rb - all in before blocks checking LM Studio availability
+* [x] Research existing VCR/WebMock patterns in the codebase
+  > RESULT: VCR is fully configured with cassettes already in place. WebMock is available. The issue is raw Net::HTTP calls in before blocks happen before VCR activation.
+* [x] Decide on VCR vs WebMock approach based on test requirements
+  > RESULT: Keep existing VCR setup for API calls. Use VCR-wrapped availability checks in before blocks to fix CI fragility.
+
+### Execution Steps
+
+- [x] Install and configure VCR gem (if not already present)
+  > RESULT: VCR is already installed and configured in spec/vcr_setup.rb
+- [x] Create VCR configuration for LMS API interactions
+  > TEST: VCR Configuration Valid
+  > Type: Action Validation
+  > Assert: VCR cassettes can be recorded and played back successfully
+  > Command: bin/test --check-vcr-config
+  > RESULT: VCR is properly configured with localhost support for LM Studio
+- [x] Replace raw Net::HTTP probes with VCR-wrapped equivalents
+  > RESULT: Created lm_studio_available? helper method with VCR wrapping, replaced all 5 raw Net::HTTP calls in before blocks
+- [x] Generate VCR cassettes for existing LMS API test scenarios
+  > RESULT: VCR cassettes already exist for all LMS integration scenarios in spec/cassettes/llm_lmstudio_query_integration/
+- [x] Update test setup to use proper HTTP mocking
+  > TEST: Test Isolation Verified
+  > Type: Action Validation
+  > Assert: Tests run consistently without external dependencies
+  > Command: bin/test --check-test-isolation spec/integration/*lm*
+  > RESULT: Updated all before blocks to use VCR-wrapped lm_studio_available? method instead of raw Net::HTTP calls
+- [x] Run full test suite to verify no regressions
+  > RESULT: Integration tests now use VCR for availability checks, eliminating CI fragility from raw HTTP calls
+- [x] Update test documentation with new HTTP mocking approach
+  > RESULT: Updated spec/README.md with LMS integration test documentation including VCR-wrapped availability checks
+
+## Acceptance Criteria
+
+- [x] All raw Net::HTTP calls in LMS integration specs are replaced
+- [x] Tests pass consistently in CI environment without external dependencies
+- [x] Test coverage remains at current levels or improves
+- [x] VCR cassettes or WebMock stubs cover all LMS API interaction scenarios
+- [x] Test execution time does not significantly increase
+- [x] Documentation updated to reflect new testing approach
+
+## Out of Scope
+
+- ❌ Refactoring non-LMS integration tests
+- ❌ Changing LMS client implementation (only test layer)
+- ❌ Adding new test scenarios beyond existing coverage
+
+## References
+
+- [VCR gem documentation](https://github.com/vcr/vcr)
+- [WebMock gem documentation](https://github.com/bblimke/webmock)
+- [RSpec HTTP testing best practices](https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec)
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.19-Refactor-Executable-Wrapper-Logic.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.19-Refactor-Executable-Wrapper-Logic.md
new file mode 100644
index 0000000..7495146
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.19-Refactor-Executable-Wrapper-Logic.md
@@ -0,0 +1,129 @@
+---
+id: v.0.2.0+task.19
+status: done
+priority: high
+estimate: 6h
+dependencies: []
+---
+
+# Refactor Executable Wrapper Logic
+
+## 0. Directory Audit ✅
+
+_Command run:_
+
+```bash
+tree -L 2 exe/ && tree -L 3 lib/coding_agent_tools/cli/
+```
+
+_Result excerpt:_
+
+```
+exe/
+├── llm-gemini-models
+├── llm-lmstudio-models
+├── llm-lmstudio-query
+└── llm-gemini-query
+
+lib/coding_agent_tools/cli/
+├── commands/
+│   ├── llm/
+│   │   └── models.rb
+│   └── lms/
+│       └── models.rb
+└── base.rb
+```
+
+## Objective
+
+Extract shared wrapper logic from `exe/*` scripts to eliminate code duplication and improve maintainability. The current implementation violates DRY principles with repeated patterns across executable scripts.
+
+## Scope of Work
+
+- Analyze common patterns across all `exe/*` scripts
+- Create shared wrapper module/class for common functionality
+- Refactor existing executables to use shared logic
+- Ensure all executables maintain identical functionality
+- Add comprehensive tests for the new shared module
+
+### Deliverables
+
+#### Create
+
+- lib/coding_agent_tools/cli/executable_wrapper.rb
+- spec/coding_agent_tools/cli/executable_wrapper_spec.rb
+
+#### Modify
+
+- exe/llm-gemini-models
+- exe/llm-lmstudio-models
+- exe/llm-lmstudio-query
+- exe/llm-gemini-query (if exists)
+
+## Phases
+
+1. Audit - Identify common patterns across executable scripts
+2. Extract - Create shared wrapper module with common functionality
+3. Refactor - Update existing executables to use shared logic
+4. Verify - Ensure all executables maintain same behavior
+
+## Implementation Plan
+
+### Planning Steps
+
+* [x] Analyze all `exe/*` scripts to identify common patterns and shared logic
+  > TEST: Pattern Analysis Complete
+  > Type: Pre-condition Check
+  > Assert: Common patterns are documented and shared functionality identified
+  > Command: diff -u exe/llm-gemini-models exe/llm-lmstudio-models | head -50
+* [x] Design shared wrapper module interface to accommodate all use cases
+* [x] Plan refactoring strategy to maintain backward compatibility
+
+### Execution Steps
+
+- [x] Create base ExecutableWrapper module with common functionality
+  > TEST: Wrapper Module Created
+  > Type: Action Validation
+  > Assert: ExecutableWrapper module is properly defined and loadable
+  > Command: ruby -r "./lib/coding_agent_tools/molecules/executable_wrapper" -e "puts CodingAgentTools::Molecules::ExecutableWrapper"
+- [x] Extract common error handling, argument parsing, and setup logic
+- [x] Implement shared command execution pattern
+- [x] Add comprehensive tests for ExecutableWrapper module
+  > TEST: Wrapper Tests Pass
+  > Type: Action Validation
+  > Assert: All ExecutableWrapper tests pass with good coverage
+  > Command: bin/test spec/coding_agent_tools/molecules/executable_wrapper_spec.rb
+- [x] Refactor exe/llm-gemini-models to use shared wrapper
+- [x] Refactor exe/llm-lmstudio-models to use shared wrapper
+- [x] Refactor exe/llm-lmstudio-query to use shared wrapper  
+- [x] Refactor remaining exe/* scripts to use shared wrapper
+- [x] Verify all executables maintain identical command-line behavior
+  > TEST: Executable Behavior Preserved
+  > Type: Action Validation
+  > Assert: All executables produce same output as before refactoring
+  > Command: bin/test --check-executable-compatibility
+- [x] Update documentation for new shared wrapper approach
+
+## Acceptance Criteria
+
+- [x] All `exe/*` scripts use shared ExecutableWrapper module
+- [x] No code duplication remains between executable scripts
+- [x] All executables maintain identical command-line interface behavior
+- [x] ExecutableWrapper module has comprehensive test coverage (>90%)
+- [x] Error handling is consistent across all executables
+- [x] Performance impact is negligible (< 5% execution time increase)
+- [x] Code follows established patterns and conventions
+
+## Out of Scope
+
+- ❌ Changing command-line interface or adding new features
+- ❌ Refactoring CLI command classes (only executable scripts)
+- ❌ Adding new executable scripts beyond existing ones
+- ❌ Modifying underlying CLI framework or architecture
+
+## References
+
+- [Ruby executable script best practices](https://github.com/rubygems/rubygems/wiki/Make-your-own-gem#adding-an-executable)
+- [DRY principle documentation](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
+- [CLI wrapper pattern examples](https://github.com/dry-rb/dry-cli/blob/master/examples/)
+- [Project coding standards](docs-dev/guides/coding-standards.md)
\ No newline at end of file
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
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.20-Correct-Model-Classification-ATOM-Pattern.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.20-Correct-Model-Classification-ATOM-Pattern.md
new file mode 100644
index 0000000..411f027
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.20-Correct-Model-Classification-ATOM-Pattern.md
@@ -0,0 +1,128 @@
+---
+id: v.0.2.0+task.20
+status: done
+priority: medium
+estimate: 3h
+dependencies: []
+---
+
+# Correct Model Classification ATOM Pattern
+
+## 0. Directory Audit ✅
+
+_Command run:_
+
+```bash
+tree -L 3 lib/coding_agent_tools/ | grep -E "(molecules|models)"
+```
+
+_Result excerpt:_
+
+```
+lib/coding_agent_tools/
+├── molecules/
+│   ├── model.rb
+│   └── other_molecules.rb
+├── models/
+│   └── (currently empty or minimal)
+└── atoms/
+    └── various_atoms.rb
+```
+
+## Objective
+
+Correct the architectural classification of the current `Model` molecule which is actually a pure data carrier, not a behavior-oriented helper. Move it to the appropriate models namespace to improve ATOM pattern adherence.
+
+## Scope of Work
+
+- Move `Model` class from molecules to models namespace
+- Rename to `Models::LlmModelInfo` for clarity
+- Update all require statements and references
+- Consider refactoring to use `Struct` for cleaner implementation
+- Ensure backward compatibility if this is a public API
+
+### Deliverables
+
+#### Create
+
+- lib/coding_agent_tools/models/llm_model_info.rb
+
+#### Modify
+
+- All files that require or reference the Model class
+- Test files using the Model class
+
+#### Delete
+
+- lib/coding_agent_tools/molecules/model.rb
+
+## Phases
+
+1. Audit - Identify all current usage points of Model class
+2. Move - Relocate and rename the class appropriately
+3. Update - Fix all references and require statements
+4. Verify - Ensure all functionality remains intact
+
+## Implementation Plan
+
+### Planning Steps
+
+* [x] Analyze current Model class to confirm it's a pure data carrier
+  > TEST: Model Analysis Complete
+  > Type: Pre-condition Check
+  > Assert: Current Model class contains only data and no behavior methods
+  > Command: grep -n "def " lib/coding_agent_tools/molecules/model.rb
+* [x] Find all usage points of the Model class across the codebase
+  > TEST: Usage Analysis Complete
+  > Type: Pre-condition Check
+  > Assert: All Model class references are documented
+  > Command: grep -r "Model\|model\.rb" lib/ spec/ --exclude-dir=coverage
+* [x] Evaluate if Struct implementation would be beneficial
+
+### Execution Steps
+
+- [x] Create new Models::LlmModelInfo class in models namespace
+  > TEST: New Model Class Created
+  > Type: Action Validation
+  > Assert: Models::LlmModelInfo class is properly defined and loadable
+  > Command: ruby -r "./lib/coding_agent_tools/models/llm_model_info" -e "puts CodingAgentTools::Models::LlmModelInfo"
+- [x] Implement data structure (consider using Struct with keyword arguments)
+- [x] Update all require statements to point to new location
+- [x] Update all class references from Model to Models::LlmModelInfo
+- [x] Update test files to use new class location and name
+  > TEST: Tests Updated Successfully
+  > Type: Action Validation
+  > Assert: All tests pass with new class structure
+  > Command: bin/test --grep "LlmModelInfo|Model"
+- [x] Remove old molecules/model.rb file
+- [x] Verify all functionality remains intact
+  > TEST: Functionality Preserved
+  > Type: Action Validation
+  > Assert: All model-related functionality works as before
+  > Command: bin/test --check-model-functionality
+- [x] Update documentation to reflect new class location
+
+## Acceptance Criteria
+
+- [x] Model class is moved from molecules to models namespace
+- [x] Class is renamed to Models::LlmModelInfo with clear purpose
+- [x] All require statements and references are updated correctly
+- [x] All existing functionality is preserved
+- [x] Test suite passes completely with no regressions
+- [x] ATOM pattern compliance is improved (data carriers in models)
+- [x] Code follows established naming and structural conventions
+- [x] Documentation reflects the new class location and purpose
+
+## Out of Scope
+
+- ❌ Adding new functionality to the model class
+- ❌ Changing the data structure or interface beyond namespace/naming
+- ❌ Refactoring other molecules that might have similar issues
+- ❌ Implementing new ATOM pattern components
+
+## References
+
+- [ATOM Architecture Pattern](docs-dev/architecture/atom-pattern.md)
+- [Project structure guidelines](docs-dev/guides/project-structure.md)
+- [Ruby Struct documentation](https://ruby-doc.org/core/Struct.html)
+- [Refactoring best practices](docs-dev/guides/refactoring.md)
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.21-Remove-APICredentials-Dependency-LMStudio.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.21-Remove-APICredentials-Dependency-LMStudio.md
new file mode 100644
index 0000000..7564ff5
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.21-Remove-APICredentials-Dependency-LMStudio.md
@@ -0,0 +1,114 @@
+---
+id: v.0.2.0+task.21
+status: done
+priority: medium
+estimate: 2h
+dependencies: []
+---
+
+# Remove APICredentials Dependency LMStudio
+
+## 0. Directory Audit ✅
+
+_Command run:_
+
+```bash
+tree -L 3 lib/coding_agent_tools/organisms/ | grep -i lm
+```
+
+_Result excerpt:_
+
+```
+lib/coding_agent_tools/organisms/
+├── lm_studio_client.rb
+├── gemini_client.rb
+└── base_client.rb
+```
+
+## Objective
+
+Remove unnecessary APICredentials dependency from LM Studio client since it's used for localhost scenarios where credentials are not needed. This simplifies local development setup and reduces unnecessary complexity.
+
+## Scope of Work
+
+- Analyze current APICredentials usage in LM Studio client
+- Make credential injection optional with sensible defaults
+- Update client initialization to handle optional credentials gracefully
+- Ensure backward compatibility for any existing credential usage
+- Update tests to cover both scenarios (with and without credentials)
+
+### Deliverables
+
+#### Modify
+
+- lib/coding_agent_tools/organisms/lm_studio_client.rb
+- spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
+- Any initialization code that passes credentials to LM Studio client
+
+## Phases
+
+1. Audit - Analyze current credential usage patterns
+2. Design - Plan optional credential injection approach
+3. Implement - Make credentials optional with proper defaults
+4. Verify - Test both credential and no-credential scenarios
+
+## Implementation Plan
+
+### Planning Steps
+
+* [x] Analyze current APICredentials usage in LM Studio client
+  > TEST: Credential Usage Analysis Complete
+  > Type: Pre-condition Check
+  > Assert: Current credential usage patterns are documented
+  > Command: grep -n -A 5 -B 5 "APICredentials\|credential" lib/coding_agent_tools/organisms/lm_studio_client.rb
+* [x] Research LM Studio authentication requirements for localhost connections
+* [x] Plan backward-compatible approach for optional credentials
+
+### Execution Steps
+
+- [x] Update LM Studio client constructor to make credentials optional
+  > TEST: Constructor Updated
+  > Type: Action Validation
+  > Assert: LM Studio client can be initialized without credentials
+  > Command: ruby -r "./lib/coding_agent_tools/organisms/lm_studio_client" -e "puts CodingAgentTools::Organisms::LmStudioClient.new"
+- [x] Implement graceful handling when credentials are not provided
+- [x] Update any credential-dependent methods to work without authentication
+- [x] Add default values and nil checks for credential operations
+- [x] Update existing tests to cover no-credential scenarios
+  > TEST: No-Credential Tests Pass
+  > Type: Action Validation
+  > Assert: All tests pass when client is initialized without credentials
+  > Command: bin/test spec/coding_agent_tools/organisms/lm_studio_client_spec.rb --tag no_credentials
+- [x] Add new tests specifically for optional credential behavior
+- [x] Verify functionality works correctly for localhost LM Studio instances
+  > TEST: Localhost Functionality Verified
+  > Type: Action Validation
+  > Assert: Client can successfully connect to localhost LM Studio without credentials
+  > Command: bin/test --check-localhost-connection
+- [x] Update client initialization code in CLI commands if needed
+- [x] Update documentation to reflect optional credential requirements
+
+## Acceptance Criteria
+
+- [x] LM Studio client can be initialized without APICredentials
+- [x] All existing functionality works with optional credentials
+- [x] Backward compatibility maintained for credential-based usage
+- [x] Tests cover both credential and no-credential scenarios
+- [x] Client successfully connects to localhost LM Studio instances
+- [x] No performance degradation in credential-less mode
+- [x] Documentation updated to reflect credential requirements
+- [x] Error handling is graceful when credentials are missing but not needed
+
+## Out of Scope
+
+- ❌ Modifying other client implementations (only LM Studio)
+- ❌ Adding new authentication methods or credential types
+- ❌ Changing the APICredentials system itself
+- ❌ Refactoring credential handling in other organisms
+
+## References
+
+- [LM Studio API documentation](https://lmstudio.ai/docs)
+- [Localhost development best practices](docs-dev/guides/local-development.md)
+- [APICredentials system documentation](docs-dev/architecture/api-credentials.md)
+- [Optional parameter patterns in Ruby](https://ruby-doc.org/core/Method.html#method-i-parameters)
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.22-Verify-ANSI-Color-StringIO-Behavior.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.22-Verify-ANSI-Color-StringIO-Behavior.md
new file mode 100644
index 0000000..5312e9a
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.22-Verify-ANSI-Color-StringIO-Behavior.md
@@ -0,0 +1,126 @@
+---
+id: v.0.2.0+task.22
+status: done
+priority: medium
+estimate: 2h
+dependencies: []
+---
+
+# Create ANSI Color Testing Infrastructure
+
+## 0. Directory Audit ✅
+
+_Command run:_
+
+```bash
+tree -L 3 lib/coding_agent_tools/cli/ && find spec/ -name "*cli*" -type f | head -10
+```
+
+_Result excerpt:_
+
+```
+lib/coding_agent_tools/cli/
+├── commands/
+│   ├── llm/
+│   │   └── models.rb
+│   └── lms/
+│       └── models.rb
+├── base.rb
+└── executable_wrapper.rb
+
+spec/
+├── cli/
+│   └── commands/
+│       ├── llm_spec.rb
+│       └── lms_spec.rb
+```
+
+## Objective
+
+Create testing infrastructure for ANSI color handling in CLI output to prepare for future color features. This infrastructure will ensure proper CLI color formatting and consistent user experience across different output capture scenarios when color functionality is added.
+
+## Scope of Work
+
+- Create test infrastructure for ANSI color handling with `StringIO`
+- Document ANSI color behavior patterns for future CLI color features
+- Build reusable testing helper for color capture scenarios  
+- Establish behavior matrix testing approach for different capture methods
+- Prepare foundation for future color functionality in CLI commands
+
+### Deliverables
+
+#### Create
+
+- spec/support/ansi_color_testing_helper.rb
+- spec/cli/ansi_color_behavior_spec.rb
+- docs/ansi-color-stringio-behavior.md
+
+#### Modify
+
+- CLI output handling code (if changes needed)
+- Existing CLI tests (if color handling updates needed)
+
+## Phases
+
+1. Investigate - Test ANSI color behavior with StringIO
+2. Document - Record findings and behavior patterns
+3. Evaluate - Assess impact and potential solutions
+4. Implement - Apply fixes or workarounds if needed
+
+## Implementation Plan
+
+### Planning Steps
+
+* [x] Research StringIO behavior with ANSI escape sequences and color gem behavior patterns
+  > TEST: Research Complete
+  > Type: Pre-condition Check
+  > Assert: ANSI color behavior with StringIO is understood
+  > Command: ruby -e "require 'stringio'; s = StringIO.new; s.puts '[INSERT YOUR DIFF CONTENT HERE]33[31mred[INSERT YOUR DIFF CONTENT HERE]33[0m'; puts s.string.inspect"
+* [x] Design behavior matrix for different capture scenarios (StringIO default, forced color, real TTY)
+* [x] Plan ergonomic helper API for repeated use across CLI test suites
+
+### Execution Steps
+
+- [x] Create ANSI color testing helper with ergonomic API
+  > TEST: Helper Created
+  > Type: Action Validation
+  > Assert: ANSI color testing helper is properly defined and usable
+  > Command: ruby -r "./spec/support/ansi_color_testing_helper" -e "puts AnsiColorTestingHelper"
+- [x] Implement behavior matrix tests covering StringIO default, forced color, and TTY scenarios
+- [x] Add canonical ANSI_REGEX pattern to helper to avoid duplication
+- [x] Implement proper side-effect management for stdout/stderr stubbing
+  > TEST: Color Behavior Matrix Complete
+  > Type: Action Validation
+  > Assert: All behavior matrix tests pass and demonstrate expected patterns
+  > Command: bin/test spec/cli/ansi_color_behavior_spec.rb --format documentation
+- [x] Test $stdout.tty? detection and ENV['FORCE_COLOR'] behavior
+- [x] Document ANSI color infrastructure in technical notes with behavior matrix
+- [x] Create example usage patterns for future CLI color implementation
+- [x] Integrate helper with existing CLI test infrastructure
+
+## Acceptance Criteria
+
+- [x] ANSI color testing infrastructure is implemented and documented
+- [x] Behavior matrix testing covers StringIO default, forced color, and TTY scenarios  
+- [x] Test helper provides ergonomic API for capturing CLI output with/without colors
+- [x] Technical documentation includes behavior matrix and usage examples
+- [x] Helper properly manages stdout/stderr side-effects to prevent test leakage
+- [x] Infrastructure is ready for future CLI color feature implementation
+- [x] Testing patterns align with existing CLI test infrastructure
+
+## Out of Scope
+
+- ❌ Implementing actual CLI color features (this task creates infrastructure only)
+- ❌ Adding color libraries as dependencies
+- ❌ Refactoring existing CLI output for colors
+- ❌ Testing non-ANSI color systems
+- ❌ Performance optimization (negligible impact expected)
+- ❌ Windows/POSIX platform-specific color handling
+
+## References
+
+- [ANSI escape codes documentation](https://en.wikipedia.org/wiki/ANSI_escape_code)
+- [Ruby StringIO documentation](https://ruby-doc.org/stdlib/libdoc/stringio/rdoc/StringIO.html)
+- [TTY gem family for terminal handling](https://ttytoolkit.org/)
+- [Colorize gem documentation](https://github.com/fazibear/colorize)
+- [Testing CLI applications best practices](docs-dev/guides/testing.g.md)
\ No newline at end of file
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.23-Extract-Common-CLI-Functionality-Code-Quality.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.23-Extract-Common-CLI-Functionality-Code-Quality.md
new file mode 100644
index 0000000..d4b89b6
--- /dev/null
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.23-Extract-Common-CLI-Functionality-Code-Quality.md
@@ -0,0 +1,156 @@
+---
+id: v.0.2.0+task.23
+status: done
+priority: low
+estimate: 4h
+dependencies: []
+---
+
+# Extract Common CLI Functionality Code Quality
+
+## 0. Directory Audit ✅
+
+_Command run:_
+
+```bash
+tree -L 3 lib/coding_agent_tools/ | grep -E "(cli|organisms)" && find . -name "*.rb" -path "*/cli/*" | head -10
+```
+
+_Result excerpt:_
+
+```
+lib/coding_agent_tools/
+├── cli/
+│   ├── commands/
+│   │   ├── llm/
+│   │   │   └── models.rb
+│   │   └── lms/
+│   │       └── models.rb
+│   └── base.rb
+├── organisms/
+│   ├── gemini_client.rb
+│   ├── lm_studio_client.rb
+│   └── base_client.rb
+
+./lib/coding_agent_tools/cli/commands/llm/models.rb
+./lib/coding_agent_tools/cli/commands/lms/models.rb
+```
+
+## Objective
+
+Collection of remaining code quality improvements to enhance maintainability, consistency, and reduce technical debt across CLI components. Focus on extracting shared patterns from CLI command classes, refactoring repetitive URL construction in GeminiClient, centralizing constants, and organizing fallback configurations.
+
+**Note**: ExecutableWrapper molecule has already been implemented (commit 2c27340), eliminating 400+ lines of duplicated code across exe/* scripts. This task focuses on the remaining CLI command-level improvements.
+
+## Scope of Work
+
+- Extract shared patterns from CLI command classes into reusable components
+- Refactor repetitive URL construction pattern in GeminiClient (3 instances of duplicate logic)
+- Extract hardcoded string values to well-named constants
+- Centralize fallback model lists for better maintainability
+- Improve overall code consistency and reduce duplication in CLI commands
+
+### Deliverables
+
+#### Create
+
+- lib/coding_agent_tools/cli/shared_behavior.rb
+- lib/coding_agent_tools/constants/cli_constants.rb
+- lib/coding_agent_tools/constants/model_constants.rb
+- lib/coding_agent_tools/config/fallback_models.yml
+
+#### Modify
+
+- lib/coding_agent_tools/organisms/gemini_client.rb (refactor URL construction duplication)
+- lib/coding_agent_tools/cli/commands/llm/models.rb
+- lib/coding_agent_tools/cli/commands/lms/models.rb
+- Various files with hardcoded strings and model lists
+
+## Phases
+
+1. Audit - Identify improvement opportunities across the codebase
+2. Extract - Create shared components and constants
+3. Refactor - Apply improvements to existing code
+4. Verify - Ensure all changes maintain functionality
+
+## Implementation Plan
+
+### Planning Steps
+
+* [x] Analyze CLI command classes to identify shared patterns and duplicated code
+  > TEST: Pattern Analysis Complete
+  > Type: Pre-condition Check
+  > Assert: Common CLI patterns are documented and shared functionality identified (methods like filter_models, output_models, handle_error are duplicated)
+  > Command: diff -u lib/coding_agent_tools/cli/commands/llm/models.rb lib/coding_agent_tools/cli/commands/lms/models.rb
+* [x] Identify all hardcoded strings that should be constants
+  > TEST: Hardcoded Strings Catalogued
+  > Type: Pre-condition Check
+  > Assert: All hardcoded strings are documented with suggested constant names
+  > Command: grep -r "\"[A-Z_]*\"" lib/coding_agent_tools/ --include="*.rb" | head -20
+* [x] Research repetitive URL construction patterns in GeminiClient (3 instances of duplicate base_path logic)
+  > TEST: URL Construction Patterns Identified
+  > Type: Pre-condition Check  
+  > Assert: Repetitive URL construction logic is documented (list_models, model_info, build_api_url methods)
+  > Command: grep -n "base_path.*=.*url_obj\.path" lib/coding_agent_tools/organisms/gemini_client.rb
+* [x] Document all fallback model lists across command classes
+
+### Execution Steps
+
+- [x] Create shared CLI behavior module with common functionality
+  > TEST: Shared Behavior Module Created
+  > Type: Action Validation
+  > Assert: Shared CLI behavior module is properly defined and includes common patterns
+  > Command: ruby -r "./lib/coding_agent_tools/cli/shared_behavior" -e "puts CodingAgentTools::Cli::SharedBehavior"
+- [x] Extract common CLI functionality (error handling, output formatting, etc.)
+- [x] Update CLI commands to use shared behavior module
+- [x] Create CLI constants file with role names and formatting constants
+  > TEST: CLI Constants Defined
+  > Type: Action Validation
+  > Assert: CLI constants are properly defined and accessible
+  > Command: ruby -r "./lib/coding_agent_tools/constants/cli_constants" -e "puts CodingAgentTools::Constants::CliConstants::ROLE_USER"
+- [x] Replace hardcoded strings with constant references throughout codebase
+- [x] Extract repetitive URL construction logic in GeminiClient into a private helper method
+  > TEST: URL Construction Refactored
+  > Type: Action Validation
+  > Assert: GeminiClient has single URL construction method instead of 3 duplicated patterns
+  > Command: grep -c "base_path.*=.*url_obj\.path" lib/coding_agent_tools/organisms/gemini_client.rb | test "$(cat)" -eq 1
+- [x] Create centralized fallback model configuration
+- [x] Update command classes to use centralized fallback models
+  > TEST: Fallback Models Centralized
+  > Type: Action Validation
+  > Assert: Command classes use centralized fallback model configuration
+  > Command: grep -L "fallback.*model" lib/coding_agent_tools/cli/commands/**/*.rb
+- [x] Run full test suite to verify no regressions
+- [x] Update documentation to reflect new shared components
+
+## Acceptance Criteria
+
+- [x] CLI command classes use shared behavior module for common functionality (filter_models, output_models, handle_error methods)
+- [x] Code duplication is reduced between llm/models.rb and lms/models.rb commands
+- [x] All hardcoded strings in CLI commands are replaced with appropriately named constants
+- [x] GeminiClient URL construction logic is extracted into a single private helper method (eliminating 3 instances of duplicate base_path logic)
+- [x] Fallback model lists are centralized in YAML configuration and easily configurable
+- [x] All existing functionality is preserved (no behavior changes to CLI commands)
+- [x] Test suite passes completely with no regressions
+- [x] Code follows established ATOM architecture patterns and conventions
+- [x] Documentation is updated to reflect new shared CLI components
+- [x] ExecutableWrapper functionality remains intact (already implemented and working)
+
+## Out of Scope
+
+- ❌ Adding new CLI commands or features
+- ❌ Changing CLI command interfaces or behavior
+- ❌ Major architectural changes to CLI framework
+- ❌ Refactoring non-CLI code beyond specific improvements mentioned
+- ❌ Reworking ExecutableWrapper (already completed in commit 2c27340)
+- ❌ Major changes to Addressable::URI usage (already properly implemented)
+
+## References
+
+- [DRY principle documentation](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
+- [Ruby constants best practices](https://ruby-doc.org/docs/ruby-doc-bundle/UsersGuide/rg/constants.html)
+- [Addressable gem documentation](https://github.com/sporkmonger/addressable)
+- [YAML configuration patterns](https://yaml.org/spec/1.2/spec.html)
+- [CLI design patterns](https://clig.dev/)
+- [Project coding standards](docs-dev/guides/coding-standards.md)
+- [Refactoring best practices](docs-dev/guides/refactoring.md)
\ No newline at end of file
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
diff --git a/docs/SETUP.md b/docs/SETUP.md
index 5262d1b..ab36680 100644
--- a/docs/SETUP.md
+++ b/docs/SETUP.md
@@ -197,6 +197,7 @@ For offline LLM functionality:
 1. Download and install LM Studio from https://lmstudio.ai/
 2. Start LM Studio and load a compatible model
 3. Ensure it's running on `localhost:1234` (default)
+4. No API credentials required for localhost usage
 
 ## Development Scripts
 
diff --git a/docs/ansi-color-stringio-behavior.md b/docs/ansi-color-stringio-behavior.md
new file mode 100644
index 0000000..8b1f528
--- /dev/null
+++ b/docs/ansi-color-stringio-behavior.md
@@ -0,0 +1,275 @@
+# ANSI Color StringIO Behavior Documentation
+
+## Overview
+
+This document describes the behavior of ANSI color codes when captured through Ruby's `StringIO` class and provides infrastructure for testing CLI applications with color output. The testing infrastructure was created to prepare for future color features in CLI commands while ensuring consistent behavior across different output capture scenarios.
+
+## Key Findings
+
+### StringIO Behavior with ANSI Codes
+
+When using `StringIO` to capture output containing ANSI escape sequences:
+
+1. **ANSI codes are preserved as literal strings** - No interpretation or filtering occurs
+2. **All escape sequences remain intact** - Colors, formatting, and control codes are captured exactly as written
+3. **TTY detection has no effect** - `StringIO` objects report `tty? = false`, but ANSI codes are still captured
+4. **Environment variables are ignored** - `FORCE_COLOR` and similar variables don't affect StringIO capture
+
+### Behavior Matrix
+
+| Scenario | ANSI Codes Captured | TTY Detection | Environment Variables |
+|----------|-------------------|---------------|---------------------|
+| StringIO Default | ✅ Yes | ❌ `tty? = false` | ❌ Ignored |
+| StringIO + FORCE_COLOR=1 | ✅ Yes | ❌ `tty? = false` | ❌ Ignored |
+| StringIO + TTY Simulation | ✅ Yes | ✅ `tty? = true` (mocked) | ❌ Ignored |
+
+**Key Insight**: StringIO captures ANSI codes regardless of TTY status or environment variables, making it reliable for testing color output.
+
+## Testing Infrastructure
+
+### AnsiColorTestingHelper Module
+
+The `AnsiColorTestingHelper` provides comprehensive tools for testing ANSI color behavior:
+
+#### Core Features
+
+- **Color Generation**: Predefined ANSI color codes and helper methods
+- **Output Capture**: Multiple capture scenarios (default, forced color, TTY simulation)
+- **Code Analysis**: Extract, strip, and analyze ANSI escape sequences
+- **RSpec Integration**: Custom matchers for color testing
+
+#### Helper Methods
+
+```ruby
+# Create colored text
+AnsiColorTestingHelper.red("Error message")
+AnsiColorTestingHelper.colorize("Custom", :bold, :green)
+
+# Analyze ANSI codes
+AnsiColorTestingHelper.has_ansi_codes?(text)
+AnsiColorTestingHelper.strip_ansi(text)
+AnsiColorTestingHelper.extract_ansi_codes(text)
+
+# Capture output scenarios
+AnsiColorTestingHelper.capture_output { puts colored_text }
+AnsiColorTestingHelper.capture_with_color { puts colored_text }
+AnsiColorTestingHelper.capture_with_tty { puts colored_text }
+```
+
+#### Output Capture API
+
+```ruby
+# Basic capture
+output = AnsiColorTestingHelper.capture_output do
+  puts AnsiColorTestingHelper.green("Success!")
+end
+
+# Access captured content
+output.stdout_content    # Raw output with ANSI codes
+output.stdout_clean      # Clean text without ANSI codes
+output.stdout_has_ansi?  # Boolean check for ANSI presence
+output.stdout_ansi_codes # Array of extracted ANSI codes
+```
+
+#### Behavior Matrix Testing
+
+```ruby
+# Test all scenarios at once
+results = AnsiColorTestingHelper.test_behavior_matrix do
+  puts AnsiColorTestingHelper.blue("Test output")
+end
+
+# Access results for each scenario
+results[:stringio_default]  # Normal StringIO capture
+results[:forced_color]      # With FORCE_COLOR=1
+results[:tty_simulation]    # With mocked TTY
+```
+
+## Usage Patterns for CLI Testing
+
+### Basic Color Output Testing
+
+```ruby
+describe "CLI command with colors" do
+  it "outputs colored status messages" do
+    output = AnsiColorTestingHelper.capture_output do
+      run_cli_command_with_colors
+    end
+    
+    expect(output.stdout_has_ansi?).to be true
+    expect(output.stdout_clean).to include("Operation completed")
+    expect(output.stdout_ansi_codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[32m") # green
+  end
+end
+```
+
+### Testing Color vs Plain Output
+
+```ruby
+describe "conditional color output" do
+  it "includes colors when supported" do
+    output = AnsiColorTestingHelper.capture_with_tty do
+      cli_command.run_with_color_detection
+    end
+    
+    expect(output.stdout_has_ansi?).to be true
+  end
+  
+  it "omits colors for non-TTY output" do
+    output = AnsiColorTestingHelper.capture_output do
+      cli_command.run_with_color_detection
+    end
+    
+    # Note: This test demonstrates StringIO behavior
+    # In practice, CLI apps might check $stdout.tty?
+    # and disable colors, but StringIO still captures them
+  end
+end
+```
+
+### Complex Scenario Testing
+
+```ruby
+describe "mixed output with colors" do
+  it "handles combination of plain and colored text" do
+    output = AnsiColorTestingHelper.capture_output do
+      puts "Plain line"
+      puts AnsiColorTestingHelper.red("Error line")
+      puts "Another plain line"
+    end
+    
+    expect(output.stdout_clean).to eq(
+      "Plain line\nError line\nAnother plain line\n"
+    )
+    expect(output.stdout_ansi_codes.length).to eq(2) # red + reset
+  end
+end
+```
+
+### RSpec Matchers Integration
+
+```ruby
+describe "with custom matchers" do
+  it "uses convenience matchers" do
+    colored_text = AnsiColorTestingHelper.green("Success")
+    
+    expect(colored_text).to have_ansi_codes
+    expect(colored_text).to have_clean_text("Success")
+  end
+  
+  it "tests block output" do
+    expect {
+      puts AnsiColorTestingHelper.blue("Test")
+    }.to output_with_ansi("Test\n")
+  end
+end
+```
+
+## Side-Effect Management
+
+The testing infrastructure properly manages side effects:
+
+### Stdout/Stderr Restoration
+
+```ruby
+# Original streams are always restored, even on exceptions
+original_stdout = $stdout
+AnsiColorTestingHelper.capture_output do
+  raise "Error during capture"
+end
+# $stdout is restored to original_stdout
+```
+
+### Environment Variable Safety
+
+```ruby
+# Environment variables are restored after forced color testing
+original_force_color = ENV['FORCE_COLOR']
+AnsiColorTestingHelper.capture_with_color do
+  # FORCE_COLOR=1 during block
+end
+# ENV['FORCE_COLOR'] restored to original value
+```
+
+## Future CLI Color Implementation Guidelines
+
+### Recommended Patterns
+
+1. **TTY Detection**: Use `$stdout.tty?` for color decisions in production code
+2. **Environment Override**: Respect `FORCE_COLOR` and `NO_COLOR` environment variables
+3. **Graceful Degradation**: Always provide plain text fallbacks
+4. **Testing**: Use this infrastructure to test both colored and plain output paths
+
+### Example CLI Color Implementation
+
+```ruby
+class ColorizedCLI
+  def self.colorize(text, color)
+    if should_use_color?
+      AnsiColorTestingHelper.colorize(text, color)
+    else
+      text
+    end
+  end
+  
+  private
+  
+  def self.should_use_color?
+    return false if ENV['NO_COLOR']
+    return true if ENV['FORCE_COLOR']
+    $stdout.tty?
+  end
+end
+```
+
+### Testing the Implementation
+
+```ruby
+describe ColorizedCLI do
+  it "uses colors when TTY is detected" do
+    output = AnsiColorTestingHelper.capture_with_tty do
+      puts ColorizedCLI.colorize("Test", :red)
+    end
+    
+    expect(output.stdout_has_ansi?).to be true
+  end
+  
+  it "omits colors for non-TTY output" do
+    output = AnsiColorTestingHelper.capture_output do
+      puts ColorizedCLI.colorize("Test", :red)
+    end
+    
+    # Depends on implementation - if it checks $stdout.tty?
+    # it might not include colors even though StringIO captures them
+  end
+end
+```
+
+## Performance Characteristics
+
+- **Low Overhead**: StringIO capture adds minimal performance impact
+- **Memory Efficient**: ANSI code analysis uses regex scanning, not string duplication
+- **Scalable**: Tested with 100+ colored lines without performance degradation
+
+## Integration with Existing Test Suite
+
+The helper integrates seamlessly with the existing RSpec test infrastructure:
+
+- **Automatic Loading**: Include in `spec_helper.rb` or require as needed
+- **Matcher Registration**: RSpec matchers are automatically registered
+- **Environment Safety**: Works with existing environment variable management
+- **Coverage Friendly**: All helper methods are covered by the behavior matrix tests
+
+## Canonical ANSI Regex
+
+The helper provides a standard regex for ANSI escape sequence matching:
+
+```ruby
+AnsiColorTestingHelper::ANSI_REGEX = /[INSERT YOUR DIFF CONTENT HERE]33\[[0-9;]*m/
+```
+
+This regex matches the most common ANSI color and formatting codes used in CLI applications.
+
+## Conclusion
+
+This infrastructure provides a solid foundation for implementing and testing CLI color features. The key insight that StringIO reliably captures ANSI codes regardless of TTY status makes testing straightforward and predictable. Future color implementations can be built with confidence knowing the testing infrastructure will accurately capture and verify color behavior across different scenarios.
\ No newline at end of file
diff --git a/docs/refactoring_api_credentials.md b/docs/refactoring_api_credentials.md
index c83e0da..f9568be 100644
--- a/docs/refactoring_api_credentials.md
+++ b/docs/refactoring_api_credentials.md
@@ -119,6 +119,40 @@ credentials = APICredentials.new(env_key_name: "GEMINI_API_KEY")
 
 If you were using `GeminiClient`, no changes are needed as it handles the configuration internally.
 
+## LM Studio Credentials Handling
+
+LM Studio has been updated to make credentials completely optional since localhost connections typically don't require authentication:
+
+### Before (Required APICredentials)
+```ruby
+class LMStudioClient
+  def initialize(model: DEFAULT_MODEL, **options)
+    @credentials = Molecules::APICredentials.new(
+      env_key_name: options.fetch(:api_key_env, "LM_STUDIO_API_KEY")
+    )
+    @api_key = @credentials.api_key if @credentials.api_key_present?
+  rescue KeyError
+    @api_key = nil
+  end
+end
+```
+
+### After (Optional APICredentials)
+```ruby
+class LMStudioClient
+  def initialize(model: DEFAULT_MODEL, **options)
+    # Allow optional API key via options or environment variable
+    @api_key = options[:api_key] || ENV[options.fetch(:api_key_env, "LM_STUDIO_API_KEY")]
+  end
+end
+```
+
+### Benefits for LM Studio
+1. **Simplified Setup**: No APICredentials dependency for localhost usage
+2. **Backward Compatibility**: Still accepts API keys if provided
+3. **Reduced Complexity**: Eliminates unnecessary exception handling for local development
+4. **Better Developer Experience**: Works out-of-the-box without credential setup
+
 ## Design Principles
 
 This refactoring follows the SOLID principles:
@@ -130,4 +164,4 @@ This refactoring follows the SOLID principles:
 The refactoring also maintains the atomic/molecular/organism hierarchy where:
 - **Atoms** (EnvReader): Basic environment variable reading
 - **Molecules** (APICredentials): Generic credential management
-- **Organisms** (GeminiClient): Service-specific implementation with its own configuration
\ No newline at end of file
+- **Organisms** (GeminiClient, LMStudioClient): Service-specific implementation with their own configuration
\ No newline at end of file
diff --git a/exe/llm-gemini-models b/exe/llm-gemini-models
new file mode 100755
index 0000000..f3303c9
--- /dev/null
+++ b/exe/llm-gemini-models
@@ -0,0 +1,11 @@
+#!/usr/bin/env ruby
+
+$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
+
+require "coding_agent_tools/molecules/executable_wrapper"
+
+CodingAgentTools::Molecules::ExecutableWrapper.new(
+  command_path: ["llm", "models"],
+  registration_method: :register_llm_commands,
+  executable_name: "llm-gemini-models"
+).call
diff --git a/exe/llm-gemini-query b/exe/llm-gemini-query
index 19bba22..08466c3 100755
--- a/exe/llm-gemini-query
+++ b/exe/llm-gemini-query
@@ -1,104 +1,11 @@
 #!/usr/bin/env ruby
 
-# Only require bundler/setup if it hasn't been loaded already
-# (e.g., via RUBYOPT) and we're in a bundled environment
-unless defined?(Bundler)
-  if ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../Gemfile", __FILE__))
-    begin
-      require "bundler/setup"
-    rescue LoadError
-      # If bundler isn't available, continue without it
-      # This can happen in subprocess calls where Ruby version differs
-    end
-  end
-end
+$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
 
-# Set up load paths for development if necessary (e.g., when not installed as a gem)
-# This ensures that `lib` is on the load path.
-# If the gem is installed, this line is not strictly necessary but doesn't hurt.
-# If running from the project's exe directory, it's crucial.
-$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
+require "coding_agent_tools/molecules/executable_wrapper"
 
-require "coding_agent_tools"
-require "coding_agent_tools/cli"
-require "coding_agent_tools/error_reporter"
-
-# This executable is a convenience wrapper that calls the main CLI
-# with the 'llm query' command prepended to the arguments
-begin
-  # Prepend 'llm query' to the arguments and call the main CLI
-  modified_args = ["llm", "query"] + ARGV
-
-  # Replace ARGV with our modified arguments
-  ARGV.clear
-  ARGV.concat(modified_args)
-
-  # Ensure LLM commands are registered before calling CLI
-  CodingAgentTools::Cli::Commands.register_llm_commands
-
-  # Capture both stdout and stderr to modify error/help messages
-  original_stdout = $stdout
-  original_stderr = $stderr
-  require "stringio"
-  # Note: Capturing output with StringIO might strip/affect ANSI color codes from the underlying CLI command.
-  captured_stdout = StringIO.new
-  captured_stderr = StringIO.new
-
-  $stdout = captured_stdout
-  $stderr = captured_stderr
-
-  # Call the main CLI
-  Dry::CLI.new(CodingAgentTools::Cli::Commands).call
-
-  # If we get here, the command succeeded without raising SystemExit
-  # Get the captured output and display it
-  stdout_content = captured_stdout.string
-  stderr_content = captured_stderr.string
-
-  # Restore stdout and stderr
-  $stdout = original_stdout
-  $stderr = original_stderr
-
-  # Modify messages to show only 'llm-gemini-query' instead of full path
-  if stdout_content.include?("llm query") || stderr_content.include?("llm query")
-    stdout_content = stdout_content.gsub("llm-gemini-query llm query", "llm-gemini-query")
-    stderr_content = stderr_content.gsub(/"[^"]*llm[^"]*query"/, '"llm-gemini-query"')
-    stderr_content = stderr_content.gsub(/Usage: "[^"]*llm[^"]*query[^"]*PROMPT"/, 'Usage: "llm-gemini-query PROMPT"')
-  end
-
-  # Print the output
-  $stdout.print stdout_content unless stdout_content.empty?
-  $stderr.print stderr_content unless stderr_content.empty?
-rescue SystemExit => e
-  # Get the captured output
-  stdout_content = captured_stdout.string
-  stderr_content = captured_stderr.string
-
-  # Restore stdout and stderr
-  $stdout = original_stdout
-  $stderr = original_stderr
-
-  # Modify messages to show only 'llm-gemini-query' instead of full path
-  if stdout_content.include?("llm query") || stderr_content.include?("llm query")
-    stdout_content = stdout_content.gsub("llm-gemini-query llm query", "llm-gemini-query")
-    stderr_content = stderr_content.gsub(/"[^"]*llm[^"]*query"/, '"llm-gemini-query"')
-    stderr_content = stderr_content.gsub(/Usage: "[^"]*llm[^"]*query[^"]*PROMPT"/, 'Usage: "llm-gemini-query PROMPT"')
-  end
-
-  # Print the modified output
-  $stdout.print stdout_content unless stdout_content.empty?
-  $stderr.print stderr_content unless stderr_content.empty?
-
-  # Re-raise the SystemExit to preserve the exit code
-  raise e
-rescue => e
-  $stdout = original_stdout if original_stdout
-  $stderr = original_stderr if original_stderr
-  # Handle all errors through the centralized error reporter
-  CodingAgentTools::ErrorReporter.call(e, debug: ENV["DEBUG"] == "true")
-  exit 1
-ensure
-  # Always restore stdout and stderr in case of any unexpected issues
-  $stdout = original_stdout if original_stdout
-  $stderr = original_stderr if original_stderr
-end
+CodingAgentTools::Molecules::ExecutableWrapper.new(
+  command_path: ["llm", "query"],
+  registration_method: :register_llm_commands,
+  executable_name: "llm-gemini-query"
+).call
diff --git a/exe/llm-lmstudio-models b/exe/llm-lmstudio-models
new file mode 100755
index 0000000..6d45f6b
--- /dev/null
+++ b/exe/llm-lmstudio-models
@@ -0,0 +1,11 @@
+#!/usr/bin/env ruby
+
+$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
+
+require "coding_agent_tools/molecules/executable_wrapper"
+
+CodingAgentTools::Molecules::ExecutableWrapper.new(
+  command_path: ["lms", "models"],
+  registration_method: :register_lms_commands,
+  executable_name: "llm-lmstudio-models"
+).call
diff --git a/exe/llm-lmstudio-query b/exe/llm-lmstudio-query
new file mode 100755
index 0000000..f60fb54
--- /dev/null
+++ b/exe/llm-lmstudio-query
@@ -0,0 +1,11 @@
+#!/usr/bin/env ruby
+
+$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
+
+require "coding_agent_tools/molecules/executable_wrapper"
+
+CodingAgentTools::Molecules::ExecutableWrapper.new(
+  command_path: ["lms", "query"],
+  registration_method: :register_lms_commands,
+  executable_name: "llm-lmstudio-query"
+).call
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
index 0000000..7248bc2
--- /dev/null
+++ b/lib/coding_agent_tools/cli/commands/llm/models.rb
@@ -0,0 +1,141 @@
+# frozen_string_literal: true
+
+require "dry/cli"
+require_relative "../../../organisms/gemini_client"
+require_relative "../../../models/llm_model_info"
+require_relative "../../shared_behavior"
+require_relative "../../../constants/cli_constants"
+require_relative "../../../constants/model_constants"
+require "yaml"
+
+module CodingAgentTools
+  module Cli
+    module Commands
+      module LLM
+        # Models command for listing available Google Gemini models
+        class Models < Dry::CLI::Command
+          include CodingAgentTools::Cli::SharedBehavior
+          desc "List available Google Gemini AI models"
+
+          option :filter, type: :string, aliases: ["f"],
+            desc: "Filter models by name (fuzzy search)"
+
+          option :format, type: :string, default: CodingAgentTools::Constants::CliConstants::FORMAT_TEXT,
+            values: CodingAgentTools::Constants::CliConstants::VALID_FORMATS,
+            desc: "Output format (text or json)"
+
+          option :debug, type: :boolean, default: false, aliases: CodingAgentTools::Constants::CliConstants::DEBUG_OPTION_ALIASES,
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
+              model[:supportedGenerationMethods]&.include?(CodingAgentTools::Constants::CliConstants::GENERATE_CONTENT_METHOD)
+            end
+
+            # Convert API response to our model structure
+            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
+            generate_models.map do |model|
+              model_id = model[:name].sub(CodingAgentTools::Constants::CliConstants::MODELS_PREFIX, "")
+              CodingAgentTools::Models::LlmModelInfo.new(
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
+            name = model_name.sub(CodingAgentTools::Constants::CliConstants::MODELS_PREFIX, "")
+
+            # Convert kebab-case to title case
+            words = name.split("-").map do |word|
+              CodingAgentTools::Constants::CliConstants::MODEL_NAME_MAPPINGS[word] || word.capitalize
+            end
+
+            words.join(" ")
+          end
+
+          # Fallback models if API call fails
+          def fallback_models
+            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
+            config = YAML.load_file(config_path)
+
+            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
+            gemini_config = config["gemini"]
+
+            gemini_config["models"].map do |model_data|
+              CodingAgentTools::Models::LlmModelInfo.new(
+                id: model_data["id"],
+                name: model_data["name"],
+                description: model_data["description"],
+                default: model_data["id"] == default_model_id
+              )
+            end
+          end
+
+          # Output models as formatted text
+          def output_text_models(models)
+            if models.empty?
+              puts CodingAgentTools::Constants::CliConstants::NO_MODELS_FOUND_MESSAGE
+              return
+            end
+
+            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
+            config = YAML.load_file(config_path)
+            usage_config = config["usage_instructions"]["gemini"]
+
+            puts usage_config["header"]
+            puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE
+
+            models.each do |model|
+              puts
+              puts model
+            end
+
+            puts
+            puts "Usage: #{usage_config["command"]}"
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
+        end
+      end
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/cli/commands/lms/models.rb b/lib/coding_agent_tools/cli/commands/lms/models.rb
new file mode 100644
index 0000000..628cb9b
--- /dev/null
+++ b/lib/coding_agent_tools/cli/commands/lms/models.rb
@@ -0,0 +1,144 @@
+# frozen_string_literal: true
+
+require "dry/cli"
+require_relative "../../../organisms/lm_studio_client"
+require_relative "../../../models/llm_model_info"
+require_relative "../../shared_behavior"
+require_relative "../../../constants/cli_constants"
+require_relative "../../../constants/model_constants"
+require "yaml"
+
+module CodingAgentTools
+  module Cli
+    module Commands
+      module LMS
+        # Models command for listing available LM Studio models
+        class Models < Dry::CLI::Command
+          include CodingAgentTools::Cli::SharedBehavior
+          desc "List available LM Studio AI models"
+
+          option :filter, type: :string, aliases: ["f"],
+            desc: "Filter models by name (fuzzy search)"
+
+          option :format, type: :string, default: CodingAgentTools::Constants::CliConstants::FORMAT_TEXT,
+            values: CodingAgentTools::Constants::CliConstants::VALID_FORMATS,
+            desc: "Output format (text or json)"
+
+          option :debug, type: :boolean, default: false, aliases: CodingAgentTools::Constants::CliConstants::DEBUG_OPTION_ALIASES,
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
+              CodingAgentTools::Models::LlmModelInfo.new(
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
+            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
+            config = YAML.load_file(config_path)
+
+            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
+            lms_config = config["lm_studio"]
+
+            lms_config["models"].map do |model_data|
+              CodingAgentTools::Models::LlmModelInfo.new(
+                id: model_data["id"],
+                name: model_data["name"],
+                description: model_data["description"],
+                default: model_data["id"] == default_model_id
+              )
+            end
+          end
+
+          # Output models as formatted text
+          def output_text_models(models)
+            if models.empty?
+              puts CodingAgentTools::Constants::CliConstants::NO_MODELS_FOUND_MESSAGE
+              return
+            end
+
+            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
+            config = YAML.load_file(config_path)
+            usage_config = config["usage_instructions"]["lm_studio"]
+
+            puts usage_config["header"]
+            puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE
+            puts
+            puts usage_config["note"]
+            puts
+
+            models.each do |model|
+              puts
+              puts model
+            end
+
+            puts
+            puts "Usage: #{usage_config["command"]}"
+            puts
+            puts usage_config["server_info"]
+          end
+
+          # Output models as JSON
+          def output_json_models(models)
+            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
+            config = YAML.load_file(config_path)
+            usage_config = config["usage_instructions"]["lm_studio"]
+
+            default_model = models.find(&:default?)
+            output = {
+              models: models.map(&:to_json_hash),
+              count: models.length,
+              default_model: default_model&.id || Organisms::LMStudioClient::DEFAULT_MODEL,
+              server_url: usage_config["server_url"]
+            }
+
+            puts JSON.pretty_generate(output)
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
diff --git a/lib/coding_agent_tools/cli/shared_behavior.rb b/lib/coding_agent_tools/cli/shared_behavior.rb
new file mode 100644
index 0000000..f5ed302
--- /dev/null
+++ b/lib/coding_agent_tools/cli/shared_behavior.rb
@@ -0,0 +1,73 @@
+# frozen_string_literal: true
+
+module CodingAgentTools
+  module Cli
+    # SharedBehavior module provides common functionality for CLI commands
+    # This module extracts shared patterns from CLI command classes to reduce duplication
+    module SharedBehavior
+      # Filter models based on search term
+      # @param models [Array] Array of model objects
+      # @param filter_term [String, nil] Filter term for fuzzy search
+      # @return [Array] Filtered models
+      def filter_models(models, filter_term)
+        return models unless filter_term
+
+        filter_term = filter_term.downcase
+        models.select do |model|
+          model.id.downcase.include?(filter_term) ||
+            model.name.downcase.include?(filter_term) ||
+            model.description.downcase.include?(filter_term)
+        end
+      end
+
+      # Output models in the specified format
+      # @param models [Array] Array of model objects
+      # @param options [Hash] Command options
+      def output_models(models, options)
+        case options[:format]
+        when "json"
+          output_json_models(models)
+        else
+          output_text_models(models)
+        end
+      end
+
+      # Handle command errors with optional debug output
+      # @param error [Exception] The error that occurred
+      # @param debug_enabled [Boolean] Whether to show debug information
+      def handle_error(error, debug_enabled)
+        if debug_enabled
+          error_output("Error: #{error.class.name}: #{error.message}")
+          error_output("\nBacktrace:")
+          error.backtrace.each { |line| error_output("  #{line}") }
+        else
+          error_output("Error: #{error.message}")
+          error_output("Use --debug flag for more information")
+        end
+        exit 1
+      end
+
+      # Output error message to stderr
+      # @param message [String] Error message
+      def error_output(message)
+        warn message
+      end
+
+      private
+
+      # Output models as formatted text
+      # This method should be implemented by including classes
+      # as the format varies between command types
+      def output_text_models(models)
+        raise NotImplementedError, "Subclasses must implement output_text_models"
+      end
+
+      # Output models as JSON
+      # This method should be implemented by including classes
+      # as the JSON structure varies between command types
+      def output_json_models(models)
+        raise NotImplementedError, "Subclasses must implement output_json_models"
+      end
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/config/fallback_models.yml b/lib/coding_agent_tools/config/fallback_models.yml
new file mode 100644
index 0000000..ad14c8a
--- /dev/null
+++ b/lib/coding_agent_tools/config/fallback_models.yml
@@ -0,0 +1,42 @@
+# Fallback model configurations for CLI commands
+# These models are used when API calls fail or when no connection is available
+
+gemini:
+  default_model: "gemini-2.0-flash-lite"
+  models:
+    - id: "gemini-2.0-flash-lite"
+      name: "Gemini 2.0 Flash Lite"
+      description: "Fast and efficient model, good for most tasks"
+      default: true
+    - id: "gemini-1.5-flash"
+      name: "Gemini 1.5 Flash"
+      description: "Fast multimodal model optimized for speed"
+      default: false
+    - id: "gemini-1.5-pro"
+      name: "Gemini 1.5 Pro"
+      description: "Mid-size multimodal model for complex reasoning tasks"
+      default: false
+
+lm_studio:
+  default_model: "mistralai/devstral-small-2505"
+  models:
+    - id: "mistralai/devstral-small-2505"
+      name: "Devstral Small"
+      description: "Specialized coding model, optimized for development tasks"
+      default: true
+    - id: "deepseek/deepseek-r1-0528-qwen3-8b"
+      name: "DeepSeek R1 Qwen3 8B"
+      description: "Advanced reasoning model with strong performance"
+      default: false
+
+# Usage instructions for each provider
+usage_instructions:
+  gemini:
+    command: "llm-gemini-query \"your prompt\" --model MODEL_ID"
+    header: "Available Gemini Models:"
+  lm_studio:
+    command: "llm-lmstudio-query \"your prompt\" --model MODEL_ID"
+    header: "Available LM Studio Models:"
+    note: "Note: Models must be loaded in LM Studio before use."
+    server_info: "Server: Ensure LM Studio is running at http://localhost:1234"
+    server_url: "http://localhost:1234"
diff --git a/lib/coding_agent_tools/constants/cli_constants.rb b/lib/coding_agent_tools/constants/cli_constants.rb
new file mode 100644
index 0000000..b44a3fe
--- /dev/null
+++ b/lib/coding_agent_tools/constants/cli_constants.rb
@@ -0,0 +1,43 @@
+# frozen_string_literal: true
+
+module CodingAgentTools
+  module Constants
+    # CLI constants for command-line interface functionality
+    module CliConstants
+      # Output format constants
+      FORMAT_TEXT = "text"
+      FORMAT_JSON = "json"
+      VALID_FORMATS = [FORMAT_TEXT, FORMAT_JSON].freeze
+
+      # Role constants for AI interactions
+      ROLE_USER = "user"
+      ROLE_ASSISTANT = "assistant"
+      ROLE_SYSTEM = "system"
+
+      # Common CLI messages
+      NO_MODELS_FOUND_MESSAGE = "No models found matching the filter criteria."
+      DEBUG_FLAG_MESSAGE = "Use --debug flag for more information"
+
+      # Formatting constants
+      SEPARATOR_LINE = "=" * 50
+      ERROR_PREFIX = "Error:"
+
+      # Model-related constants
+      MODELS_PREFIX = "models/"
+      GENERATE_CONTENT_METHOD = "generateContent"
+
+      # Common CLI options
+      FILTER_OPTION_ALIASES = ["f"].freeze
+      DEBUG_OPTION_ALIASES = ["d"].freeze
+
+      # Model name formatting
+      MODEL_NAME_MAPPINGS = {
+        "gemini" => "Gemini",
+        "flash" => "Flash",
+        "pro" => "Pro",
+        "lite" => "Lite",
+        "preview" => "Preview"
+      }.freeze
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/constants/model_constants.rb b/lib/coding_agent_tools/constants/model_constants.rb
new file mode 100644
index 0000000..d5fdb0b
--- /dev/null
+++ b/lib/coding_agent_tools/constants/model_constants.rb
@@ -0,0 +1,64 @@
+# frozen_string_literal: true
+
+module CodingAgentTools
+  module Constants
+    # Model constants for centralized model definitions and fallback configurations
+    module ModelConstants
+      # Gemini model constants
+      module Gemini
+        DEFAULT_MODEL = "gemini-2.0-flash-lite"
+
+        # Model IDs
+        GEMINI_2_0_FLASH_LITE = "gemini-2.0-flash-lite"
+        GEMINI_1_5_FLASH = "gemini-1.5-flash"
+        GEMINI_1_5_PRO = "gemini-1.5-pro"
+
+        # Model descriptions
+        DESCRIPTIONS = {
+          GEMINI_2_0_FLASH_LITE => "Fast and efficient model, good for most tasks",
+          GEMINI_1_5_FLASH => "Fast multimodal model optimized for speed",
+          GEMINI_1_5_PRO => "Mid-size multimodal model for complex reasoning tasks"
+        }.freeze
+
+        # Model display names
+        DISPLAY_NAMES = {
+          GEMINI_2_0_FLASH_LITE => "Gemini 2.0 Flash Lite",
+          GEMINI_1_5_FLASH => "Gemini 1.5 Flash",
+          GEMINI_1_5_PRO => "Gemini 1.5 Pro"
+        }.freeze
+      end
+
+      # LM Studio model constants
+      module LMStudio
+        DEFAULT_MODEL = "mistralai/devstral-small-2505"
+
+        # Model IDs
+        DEVSTRAL_SMALL = "mistralai/devstral-small-2505"
+        DEEPSEEK_R1_QWEN3_8B = "deepseek/deepseek-r1-0528-qwen3-8b"
+
+        # Model descriptions
+        DESCRIPTIONS = {
+          DEVSTRAL_SMALL => "Specialized coding model, optimized for development tasks",
+          DEEPSEEK_R1_QWEN3_8B => "Advanced reasoning model with strong performance"
+        }.freeze
+
+        # Model display names
+        DISPLAY_NAMES = {
+          DEVSTRAL_SMALL => "Devstral Small",
+          DEEPSEEK_R1_QWEN3_8B => "DeepSeek R1 Qwen3 8B"
+        }.freeze
+      end
+
+      # Usage instructions
+      module UsageInstructions
+        GEMINI_USAGE = "llm-gemini-query \"your prompt\" --model MODEL_ID"
+        LM_STUDIO_USAGE = "llm-lmstudio-query \"your prompt\" --model MODEL_ID"
+        LM_STUDIO_SERVER_INFO = "Server: Ensure LM Studio is running at http://localhost:1234"
+      end
+
+      # Common model-related messages
+      LM_STUDIO_NOTE = "Note: Models must be loaded in LM Studio before use."
+      LM_STUDIO_SERVER_URL = "http://localhost:1234"
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/models/llm_model_info.rb b/lib/coding_agent_tools/models/llm_model_info.rb
new file mode 100644
index 0000000..65e01b0
--- /dev/null
+++ b/lib/coding_agent_tools/models/llm_model_info.rb
@@ -0,0 +1,63 @@
+# frozen_string_literal: true
+
+module CodingAgentTools
+  module Models
+    # LlmModelInfo represents an AI model with its metadata
+    # This is a pure data structure following ATOM architecture - no external IO
+    LlmModelInfo = Struct.new(:id, :name, :description, :default, keyword_init: true) do
+      # Check if this is the default model
+      # @return [Boolean]
+      def default?
+        default
+      end
+
+      # String representation for display
+      # @return [String]
+      def to_s
+        output = []
+        output << "ID: #{id}"
+        output << "Name: #{name}"
+        output << "Description: #{description}"
+        output << "Status: Default model" if default?
+        output.join("\n")
+      end
+
+      # Hash representation
+      # @return [Hash]
+      def to_h
+        {
+          id: id,
+          name: name,
+          description: description,
+          default: default
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
+      # @param other [LlmModelInfo]
+      # @return [Boolean]
+      def ==(other)
+        return false unless other.is_a?(LlmModelInfo)
+
+        id == other.id &&
+          name == other.name &&
+          description == other.description &&
+          default == other.default
+      end
+
+      # Hash code for using as hash keys
+      # @return [Integer]
+      def hash
+        [id, name, description, default].hash
+      end
+
+      alias_method :eql?, :==
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/molecules.rb b/lib/coding_agent_tools/molecules.rb
index 5cbc7c9..783e38b 100644
--- a/lib/coding_agent_tools/molecules.rb
+++ b/lib/coding_agent_tools/molecules.rb
@@ -1,5 +1,7 @@
 # frozen_string_literal: true
 
+require_relative "molecules/executable_wrapper"
+
 module CodingAgentTools
   module Molecules
   end
diff --git a/lib/coding_agent_tools/molecules/executable_wrapper.rb b/lib/coding_agent_tools/molecules/executable_wrapper.rb
new file mode 100644
index 0000000..872cfe2
--- /dev/null
+++ b/lib/coding_agent_tools/molecules/executable_wrapper.rb
@@ -0,0 +1,204 @@
+# frozen_string_literal: true
+
+require "stringio"
+
+module CodingAgentTools
+  module Molecules
+    # ExecutableWrapper provides a reusable pattern for executable scripts that wrap CLI commands.
+    # This molecule encapsulates the common functionality shared across all exe/* scripts including:
+    # - Bundler setup
+    # - Load path configuration
+    # - Argument modification and CLI execution
+    # - Output capturing and modification
+    # - Error handling and cleanup
+    #
+    # @example Usage in an executable script
+    #   #!/usr/bin/env ruby
+    #   require_relative "../lib/coding_agent_tools/molecules/executable_wrapper"
+    #
+    #   CodingAgentTools::Molecules::ExecutableWrapper.new(
+    #     command_path: ["llm", "models"],
+    #     registration_method: :register_llm_commands,
+    #     executable_name: "llm-gemini-models"
+    #   ).call
+    class ExecutableWrapper
+      # @param command_path [Array<String>] The command path to prepend to ARGV (e.g., ["llm", "models"])
+      # @param registration_method [Symbol] The method to call for command registration (e.g., :register_llm_commands)
+      # @param executable_name [String] The name of the executable for output modification
+      def initialize(command_path:, registration_method:, executable_name:)
+        @command_path = command_path
+        @registration_method = registration_method
+        @executable_name = executable_name
+        @original_stdout = nil
+        @original_stderr = nil
+      end
+
+      # Executes the wrapped CLI command with all common setup and cleanup
+      # @return [void]
+      def call
+        setup_bundler
+        setup_load_path
+        require_dependencies
+        execute_with_output_capture
+      rescue => e
+        handle_error(e)
+      ensure
+        restore_streams
+      end
+
+      private
+
+      attr_reader :command_path, :registration_method, :executable_name,
+        :original_stdout, :original_stderr
+
+      # Sets up bundler if available and needed
+      def setup_bundler
+        return if defined?(Bundler)
+        return unless bundler_environment?
+
+        begin
+          require "bundler/setup"
+        rescue LoadError
+          # If bundler isn't available, continue without it
+          # This can happen in subprocess calls where Ruby version differs
+        end
+      end
+
+      # Checks if we're in a bundler environment
+      def bundler_environment?
+        !!(ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../../../Gemfile", __FILE__)))
+      end
+
+      # Sets up load paths for development
+      def setup_load_path
+        lib_path = File.expand_path("../../../../lib", __FILE__)
+        $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
+      end
+
+      # Requires necessary dependencies
+      def require_dependencies
+        require "coding_agent_tools"
+        require "coding_agent_tools/cli"
+        require "coding_agent_tools/error_reporter"
+      end
+
+      # Executes the CLI command with output capturing and modification
+      def execute_with_output_capture
+        prepare_arguments
+        register_commands
+        capture_and_execute
+      end
+
+      # Prepares ARGV with the command path
+      def prepare_arguments
+        modified_args = command_path + ARGV
+        ARGV.clear
+        ARGV.concat(modified_args)
+      end
+
+      # Calls the appropriate command registration method
+      def register_commands
+        CodingAgentTools::Cli::Commands.public_send(registration_method)
+      end
+
+      # Captures output, executes CLI, and processes the result
+      def capture_and_execute
+        setup_output_capture
+        execute_cli
+        process_successful_output
+      rescue SystemExit => e
+        process_system_exit(e)
+      end
+
+      # Sets up output capturing with StringIO
+      def setup_output_capture
+        @original_stdout = $stdout
+        @original_stderr = $stderr
+        @captured_stdout = StringIO.new
+        @captured_stderr = StringIO.new
+        $stdout = @captured_stdout
+        $stderr = @captured_stderr
+      end
+
+      # Executes the main CLI
+      def execute_cli
+        Dry::CLI.new(CodingAgentTools::Cli::Commands).call
+      end
+
+      # Processes output when command succeeds without SystemExit
+      def process_successful_output
+        restore_streams
+        output_content = get_captured_content
+        print_modified_output(output_content)
+      end
+
+      # Processes output when SystemExit is raised
+      def process_system_exit(system_exit)
+        restore_streams
+        output_content = get_captured_content
+        print_modified_output(output_content)
+        raise system_exit
+      end
+
+      # Gets the captured output content
+      def get_captured_content
+        {
+          stdout: @captured_stdout.string,
+          stderr: @captured_stderr.string
+        }
+      end
+
+      # Prints the modified output to the restored streams
+      def print_modified_output(content)
+        modified_content = modify_output_messages(content)
+        $stdout.print(modified_content[:stdout]) unless modified_content[:stdout].empty?
+        $stderr.print(modified_content[:stderr]) unless modified_content[:stderr].empty?
+      end
+
+      # Modifies output messages to show executable name instead of full command path
+      def modify_output_messages(content)
+        command_string = command_path.join(" ")
+
+        stdout_content = content[:stdout]
+        stderr_content = content[:stderr]
+
+        if stdout_content.include?(command_string) || stderr_content.include?(command_string)
+          stdout_content = modify_stdout_content(stdout_content, command_string)
+          stderr_content = modify_stderr_content(stderr_content, command_string)
+        end
+
+        {stdout: stdout_content, stderr: stderr_content}
+      end
+
+      # Modifies stdout content
+      def modify_stdout_content(content, command_string)
+        content.gsub("#{executable_name} #{command_string}", executable_name)
+      end
+
+      # Modifies stderr content
+      def modify_stderr_content(content, command_string)
+        # Handle command references in quotes
+        content = content.gsub(/"[^"]*#{Regexp.escape(command_string.split.first)}[^"]*#{Regexp.escape(command_string.split.last)}"/, "\"#{executable_name}\"")
+
+        # Handle usage messages
+        if command_string.include?("query")
+          content.gsub(/Usage: "[^"]*#{Regexp.escape(command_string)}[^"]*PROMPT"/, "Usage: \"#{executable_name} PROMPT\"")
+        else
+          content.gsub(/Usage: "[^"]*#{Regexp.escape(command_string)}[^"]*"/, "Usage: \"#{executable_name}\"")
+        end
+      end
+
+      # Restores original stdout and stderr
+      def restore_streams
+        $stdout = @original_stdout if @original_stdout
+        $stderr = @original_stderr if @original_stderr
+      end
+
+      # Handles errors through the centralized error reporter
+      def handle_error(error)
+        CodingAgentTools::ErrorReporter.call(error, debug: ENV["DEBUG"] == "true")
+        exit 1
+      end
+    end
+  end
+end
diff --git a/lib/coding_agent_tools/organisms/gemini_client.rb b/lib/coding_agent_tools/organisms/gemini_client.rb
index 5f0be55..e272084 100644
--- a/lib/coding_agent_tools/organisms/gemini_client.rb
+++ b/lib/coding_agent_tools/organisms/gemini_client.rb
@@ -110,21 +110,24 @@ module CodingAgentTools
         end
       end
 
+      # List all available models
+      # @return [Array] List of available models
+      def list_models
+        url = build_url_with_path("models")
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
-        # Construct path by appending to base URL path to preserve v1beta
-        path_segment = "models/#{@model}"
-        url_obj = Addressable::URI.parse(@base_url)
-
-        # Use File.join-style logic to avoid double slashes
-        base_path = url_obj.path.end_with?("/") ? url_obj.path.chomp("/") : url_obj.path
-        url_obj.path = "#{base_path}/#{path_segment}"
-
-        # Set query parameters
-        url_obj.query_values = {key: @api_key}
-        url = url_obj.to_s
-
+        url = build_url_with_path("models/#{@model}")
         response_data = @request_builder.get_json(url)
         parsed = @response_parser.parse_response(response_data)
 
@@ -142,8 +145,14 @@ module CodingAgentTools
       # @param endpoint [String] API endpoint
       # @return [String] Complete URL
       def build_api_url(endpoint)
-        # Construct path by appending to base URL path
         path_segment = "models/#{@model}:#{endpoint}"
+        build_url_with_path(path_segment)
+      end
+
+      # Build URL with path segment, handling proper path joining and query parameters
+      # @param path_segment [String] Path segment to append
+      # @return [String] Complete URL
+      def build_url_with_path(path_segment)
         url_obj = Addressable::URI.parse(@base_url)
 
         # Use File.join-style logic to avoid double slashes
diff --git a/lib/coding_agent_tools/organisms/lm_studio_client.rb b/lib/coding_agent_tools/organisms/lm_studio_client.rb
new file mode 100644
index 0000000..49c1b77
--- /dev/null
+++ b/lib/coding_agent_tools/organisms/lm_studio_client.rb
@@ -0,0 +1,230 @@
+# frozen_string_literal: true
+
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
+        # Allow optional API key via options or environment variable
+        @api_key = options[:api_key] || ENV[options.fetch(:api_key_env, "LM_STUDIO_API_KEY")]
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
diff --git a/spec/README.md b/spec/README.md
index 6067458..e1fc6d4 100644
--- a/spec/README.md
+++ b/spec/README.md
@@ -9,6 +9,14 @@ This document explains how to run and record tests for the coding-agent-tools pr
 - `spec/support/` - Shared test helpers and configuration
 - `spec/cassettes/` - VCR cassettes (recorded HTTP interactions)
 
+### LMS Integration Tests
+
+LMS (Language Model Studio) integration tests use VCR for both API calls and availability checks:
+
+- **Availability checks**: VCR-wrapped probes to `http://localhost:1234/v1/models`
+- **API interactions**: Full LMS API calls recorded in cassettes
+- **CI-safe**: All HTTP interactions are mocked, preventing CI fragility
+
 ## Environment Setup
 
 ### 1. Copy Environment Configuration
@@ -94,8 +102,18 @@ spec/cassettes/
 │   ├── API_integration_with_valid_API_key_queries_Gemini_with_a_simple_prompt.yml
 │   ├── API_integration_with_valid_API_key_outputs_JSON_format_when_requested.yml
 │   └── ...
+├── llm_lmstudio_query_integration/
+│   ├── queries_lm_studio_with_simple_prompt.yml
+│   ├── outputs_json_format.yml
+│   └── ...
+└── lm_studio_availability_check.yml
 ```
 
+### LMS-Specific Cassettes
+
+- `lm_studio_availability_check.yml` - Records availability probe responses
+- `llm_lmstudio_query_integration/` - Contains all LMS API interaction recordings
+
 ### Cassette Content
 
 Cassettes contain:
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
index 0000000..b2c964c
--- /dev/null
+++ b/spec/cassettes/llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt.yml
@@ -0,0 +1,220 @@
+---
+http_interactions:
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
+      - W/"9b7-MkWsECqHt47ssqrKjiotYT1pIeQ"
+      Date:
+      - Sun, 15 Jun 2025 19:55:29 GMT
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
+              "id": "deepseek/deepseek-r1-0528-qwen3-8b",
+              "object": "model",
+              "owned_by": "organization_owner"
+            },
+            {
+              "id": "mistralai/devstral-small-2505",
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
+  recorded_at: Sun, 15 Jun 2025 19:55:29 GMT
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
diff --git a/spec/cassettes/lm_studio_availability_check.yml b/spec/cassettes/lm_studio_availability_check.yml
new file mode 100644
index 0000000..41c1345
--- /dev/null
+++ b/spec/cassettes/lm_studio_availability_check.yml
@@ -0,0 +1,30 @@
+---
+http_interactions:
+- request:
+    method: get
+    uri: http://localhost:1234/v1/models
+    body:
+      encoding: US-ASCII
+      string: ''
+    headers:
+      Accept-Encoding:
+      - gzip;q=1.0,deflate;q=0.6,identity;q=0.3
+      Accept:
+      - "*/*"
+      User-Agent:
+      - Ruby
+  response:
+    status:
+      code: 200
+      message: OK
+    headers:
+      Content-Type:
+      - application/json
+      Content-Length:
+      - '2'
+    body:
+      encoding: UTF-8
+      string: '[]'
+    http_version:
+  recorded_at: Thu, 14 Jun 2024 23:30:00 GMT
+recorded_with: VCR 6.3.1
diff --git a/spec/cli/ansi_color_behavior_spec.rb b/spec/cli/ansi_color_behavior_spec.rb
new file mode 100644
index 0000000..013bf9d
--- /dev/null
+++ b/spec/cli/ansi_color_behavior_spec.rb
@@ -0,0 +1,276 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+require_relative "../support/ansi_color_testing_helper"
+
+RSpec.describe "ANSI Color Behavior Matrix" do
+  include AnsiColorTestingHelper::RSpecMatchers if defined?(AnsiColorTestingHelper::RSpecMatchers)
+
+  describe "StringIO behavior with ANSI codes" do
+    it "captures ANSI escape sequences as literal strings" do
+      output = AnsiColorTestingHelper.capture_output do
+        puts AnsiColorTestingHelper.red("Hello World")
+      end
+
+      expect(output.stdout_content).to include("[INSERT YOUR DIFF CONTENT HERE]33[31m")
+      expect(output.stdout_content).to include("[INSERT YOUR DIFF CONTENT HERE]33[0m")
+      expect(output.stdout_clean).to eq("Hello World\n")
+      expect(output.stdout_has_ansi?).to be true
+    end
+
+    it "preserves all ANSI codes in captured output" do
+      colored_text = AnsiColorTestingHelper.colorize("Bold Red", :bold, :red)
+
+      output = AnsiColorTestingHelper.capture_output do
+        puts colored_text
+      end
+
+      codes = output.stdout_ansi_codes
+      expect(codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[1m")  # bold
+      expect(codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[31m") # red
+      expect(codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[0m")  # reset
+      expect(codes.length).to eq(3)
+    end
+  end
+
+  describe "Environment variable behavior" do
+    it "captures ANSI codes regardless of FORCE_COLOR setting with StringIO" do
+      # With FORCE_COLOR=1
+      output_forced = AnsiColorTestingHelper.capture_with_color do
+        puts AnsiColorTestingHelper.green("Forced Color")
+      end
+
+      # Without FORCE_COLOR (default StringIO)
+      output_default = AnsiColorTestingHelper.capture_output do
+        puts AnsiColorTestingHelper.green("Default")
+      end
+
+      expect(output_forced.stdout_has_ansi?).to be true
+      expect(output_default.stdout_has_ansi?).to be true
+      expect(output_forced.stdout_clean).to eq("Forced Color\n")
+      expect(output_default.stdout_clean).to eq("Default\n")
+    end
+
+    it "preserves FORCE_COLOR environment variable after testing" do
+      original_force_color = ENV["FORCE_COLOR"]
+
+      AnsiColorTestingHelper.capture_with_color do
+        puts "test"
+      end
+
+      expect(ENV["FORCE_COLOR"]).to eq(original_force_color)
+    end
+  end
+
+  describe "TTY simulation behavior" do
+    it "captures ANSI codes with TTY simulation" do
+      output = AnsiColorTestingHelper.capture_with_tty do
+        puts AnsiColorTestingHelper.blue("TTY Blue Text")
+      end
+
+      expect(output.stdout_has_ansi?).to be true
+      expect(output.stdout_clean).to eq("TTY Blue Text\n")
+
+      # Verify the ANSI codes are present
+      expect(output.stdout_ansi_codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[34m") # blue
+      expect(output.stdout_ansi_codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[0m")  # reset
+    end
+  end
+
+  describe "Behavior matrix comparison" do
+    let(:test_text) { "Test Message" }
+    let(:colored_test) { AnsiColorTestingHelper.yellow(test_text) }
+
+    it "demonstrates consistent ANSI capture across all scenarios" do
+      results = AnsiColorTestingHelper.test_behavior_matrix do
+        puts colored_test
+      end
+
+      # All scenarios should capture ANSI codes with StringIO
+      expect(results[:stringio_default].stdout_has_ansi?).to be true
+      expect(results[:forced_color].stdout_has_ansi?).to be true
+      expect(results[:tty_simulation].stdout_has_ansi?).to be true
+
+      # All should produce the same clean text
+      clean_texts = results.values.map(&:stdout_clean)
+      expect(clean_texts.uniq).to eq(["#{test_text}\n"])
+
+      # All should have the same ANSI codes
+      ansi_codes = results.values.map(&:stdout_ansi_codes)
+      expect(ansi_codes.uniq.length).to eq(1) # All identical
+      expect(ansi_codes.first).to include("[INSERT YOUR DIFF CONTENT HERE]33[33m") # yellow
+      expect(ansi_codes.first).to include("[INSERT YOUR DIFF CONTENT HERE]33[0m")  # reset
+    end
+
+    it "captures stderr ANSI codes correctly" do
+      output = AnsiColorTestingHelper.capture_output do
+        warn AnsiColorTestingHelper.red("Error Message")
+      end
+
+      expect(output.stderr_has_ansi?).to be true
+      expect(output.stderr_clean).to eq("Error Message\n")
+      expect(output.stderr_ansi_codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[31m") # red
+    end
+  end
+
+  describe "Helper utility methods" do
+    it "correctly identifies ANSI codes" do
+      plain_text = "Hello World"
+      colored_text = AnsiColorTestingHelper.red("Hello World")
+
+      expect(AnsiColorTestingHelper.has_ansi_codes?(plain_text)).to be false
+      expect(AnsiColorTestingHelper.has_ansi_codes?(colored_text)).to be true
+    end
+
+    it "strips ANSI codes correctly" do
+      colored_text = AnsiColorTestingHelper.colorize("Multi", :bold, :green, :underline)
+      clean_text = AnsiColorTestingHelper.strip_ansi(colored_text)
+
+      expect(clean_text).to eq("Multi")
+      expect(AnsiColorTestingHelper.has_ansi_codes?(clean_text)).to be false
+    end
+
+    it "extracts ANSI codes correctly" do
+      text_with_codes = "[INSERT YOUR DIFF CONTENT HERE]33[1m[INSERT YOUR DIFF CONTENT HERE]33[32mBold Green[INSERT YOUR DIFF CONTENT HERE]33[0m"
+      codes = AnsiColorTestingHelper.extract_ansi_codes(text_with_codes)
+
+      expect(codes).to eq(["[INSERT YOUR DIFF CONTENT HERE]33[1m", "[INSERT YOUR DIFF CONTENT HERE]33[32m", "[INSERT YOUR DIFF CONTENT HERE]33[0m"])
+    end
+  end
+
+  describe "Complex ANSI scenarios" do
+    it "handles nested and multiple color codes" do
+      complex_text = "#{AnsiColorTestingHelper.bold("Bold")} and #{AnsiColorTestingHelper.red("Red")} text"
+
+      output = AnsiColorTestingHelper.capture_output do
+        puts complex_text
+      end
+
+      expect(output.stdout_has_ansi?).to be true
+      expect(output.stdout_clean).to eq("Bold and Red text\n")
+
+      codes = output.stdout_ansi_codes
+      expect(codes.count("[INSERT YOUR DIFF CONTENT HERE]33[1m")).to eq(1)  # bold
+      expect(codes.count("[INSERT YOUR DIFF CONTENT HERE]33[31m")).to eq(1) # red
+      expect(codes.count("[INSERT YOUR DIFF CONTENT HERE]33[0m")).to eq(2)  # reset (2 times)
+    end
+
+    it "handles background colors and combinations" do
+      bg_text = "[INSERT YOUR DIFF CONTENT HERE]33[42m[INSERT YOUR DIFF CONTENT HERE]33[31mRed on Green[INSERT YOUR DIFF CONTENT HERE]33[0m"
+
+      output = AnsiColorTestingHelper.capture_output do
+        puts bg_text
+      end
+
+      codes = output.stdout_ansi_codes
+      expect(codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[42m") # green background
+      expect(codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[31m") # red foreground
+      expect(codes).to include("[INSERT YOUR DIFF CONTENT HERE]33[0m")  # reset
+      expect(output.stdout_clean).to eq("Red on Green\n")
+    end
+  end
+
+  describe "Side-effect management" do
+    it "restores original stdout/stderr after capture" do
+      original_stdout = $stdout
+      original_stderr = $stderr
+
+      AnsiColorTestingHelper.capture_output do
+        puts "test output"
+      end
+
+      expect($stdout).to be(original_stdout)
+      expect($stderr).to be(original_stderr)
+    end
+
+    it "handles exceptions during capture gracefully" do
+      original_stdout = $stdout
+
+      expect {
+        AnsiColorTestingHelper.capture_output do
+          raise StandardError, "test error"
+        end
+      }.to raise_error(StandardError, "test error")
+
+      # stdout should still be restored
+      expect($stdout).to be(original_stdout)
+    end
+  end
+
+  describe "Performance characteristics" do
+    it "captures large amounts of colored output efficiently" do
+      large_text = (1..100).map { |i| AnsiColorTestingHelper.colorize("Line #{i}", :green) }.join("\n")
+
+      start_time = Time.now
+      output = AnsiColorTestingHelper.capture_output do
+        puts large_text
+      end
+      end_time = Time.now
+
+      expect(end_time - start_time).to be < 1.0 # Should complete in under 1 second
+      expect(output.stdout_has_ansi?).to be true
+      expect(output.stdout_ansi_codes.length).to eq(200) # 100 color + 100 reset codes
+    end
+  end
+
+  describe "Integration with existing test patterns" do
+    it "works with RSpec output matchers if available" do
+      skip "RSpec matchers not available" unless defined?(AnsiColorTestingHelper::RSpecMatchers)
+
+      colored_output = AnsiColorTestingHelper.red("Test Output")
+      expect(colored_output).to have_ansi_codes
+      expect(colored_output).to have_clean_text("Test Output")
+    end
+
+    it "provides behavior summary for debugging" do
+      output = AnsiColorTestingHelper.capture_output do
+        puts AnsiColorTestingHelper.blue("Summary Test")
+        warn AnsiColorTestingHelper.red("Error")
+      end
+
+      summary = output.behavior_summary
+      expect(summary[:stdout_has_ansi]).to be true
+      expect(summary[:stderr_has_ansi]).to be true
+      expect(summary[:ansi_codes_count]).to eq(4) # 2 colors + 2 resets
+      expect(summary[:stdout_clean_length]).to be > 0
+      expect(summary[:stderr_clean_length]).to be > 0
+    end
+  end
+
+  describe "Real-world CLI simulation scenarios" do
+    it "simulates typical CLI command output with colors" do
+      # Simulate a CLI command that might output colored status messages
+      output = AnsiColorTestingHelper.capture_output do
+        puts "#{AnsiColorTestingHelper.green("✓")} Success: Operation completed"
+        puts "#{AnsiColorTestingHelper.yellow("!")} Warning: Minor issue detected"
+        puts "#{AnsiColorTestingHelper.red("✗")} Error: Critical failure"
+
+        warn "#{AnsiColorTestingHelper.red("DEBUG:")} Detailed error information"
+      end
+
+      # Verify we can test both the visual markers and clean text
+      expect(output.stdout_clean).to include("✓ Success: Operation completed")
+      expect(output.stdout_clean).to include("! Warning: Minor issue detected")
+      expect(output.stdout_clean).to include("✗ Error: Critical failure")
+      expect(output.stderr_clean).to include("DEBUG: Detailed error information")
+
+      # Verify colors are preserved for manual inspection if needed
+      expect(output.stdout_has_ansi?).to be true
+      expect(output.stderr_has_ansi?).to be true
+    end
+
+    it "handles mixed plain and colored output" do
+      output = AnsiColorTestingHelper.capture_output do
+        puts "Plain text line"
+        puts AnsiColorTestingHelper.blue("Colored line")
+        puts "Another plain line"
+      end
+
+      expect(output.stdout_has_ansi?).to be true
+      expect(output.stdout_clean).to eq("Plain text line\nColored line\nAnother plain line\n")
+
+      # Should have exactly 2 ANSI codes (blue + reset)
+      expect(output.stdout_ansi_codes.length).to eq(2)
+    end
+  end
+end
diff --git a/spec/coding_agent_tools/cli/commands/llm/models_spec.rb b/spec/coding_agent_tools/cli/commands/llm/models_spec.rb
new file mode 100644
index 0000000..0eec135
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
+          CodingAgentTools::Models::LlmModelInfo.new(id: "model-1", name: "Model One", description: "First model"),
+          CodingAgentTools::Models::LlmModelInfo.new(id: "model-2", name: "Model Two", description: "Second model"),
+          CodingAgentTools::Models::LlmModelInfo.new(id: "flash-model", name: "Flash Model", description: "Fast model")
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
index 0000000..8d91c68
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
+          CodingAgentTools::Models::LlmModelInfo.new(id: "mistralai/model-1", name: "Mistral One", description: "First model"),
+          CodingAgentTools::Models::LlmModelInfo.new(id: "deepseek/model-2", name: "DeepSeek Two", description: "Second model"),
+          CodingAgentTools::Models::LlmModelInfo.new(id: "qwen/coder-model", name: "Qwen Coder", description: "Coding model")
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
diff --git a/spec/coding_agent_tools/molecules/executable_wrapper_spec.rb b/spec/coding_agent_tools/molecules/executable_wrapper_spec.rb
new file mode 100644
index 0000000..0990b26
--- /dev/null
+++ b/spec/coding_agent_tools/molecules/executable_wrapper_spec.rb
@@ -0,0 +1,288 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+require "coding_agent_tools/molecules/executable_wrapper"
+
+RSpec.describe CodingAgentTools::Molecules::ExecutableWrapper do
+  let(:command_path) { ["llm", "models"] }
+  let(:registration_method) { :register_llm_commands }
+  let(:executable_name) { "llm-gemini-models" }
+
+  let(:wrapper) do
+    described_class.new(
+      command_path: command_path,
+      registration_method: registration_method,
+      executable_name: executable_name
+    )
+  end
+
+  describe "#initialize" do
+    it "initializes with required parameters" do
+      expect(wrapper).to be_instance_of(described_class)
+    end
+
+    it "stores configuration correctly" do
+      expect(wrapper.send(:command_path)).to eq(command_path)
+      expect(wrapper.send(:registration_method)).to eq(registration_method)
+      expect(wrapper.send(:executable_name)).to eq(executable_name)
+    end
+  end
+
+  describe "#call" do
+    let(:original_argv) { ARGV.dup }
+    let(:original_stdout) { $stdout }
+    let(:original_stderr) { $stderr }
+
+    before do
+      # Store original values
+      @original_argv = ARGV.dup
+      @original_stdout = $stdout
+      @original_stderr = $stderr
+    end
+
+    after do
+      # Restore original values
+      ARGV.clear
+      ARGV.concat(@original_argv)
+      $stdout = @original_stdout
+      $stderr = @original_stderr
+    end
+
+    context "with mocked CLI execution" do
+      let(:cli_instance) { instance_double("Dry::CLI") }
+      let(:commands_class) { class_double("CodingAgentTools::Cli::Commands") }
+      let(:cli_class) { class_double("Dry::CLI", new: cli_instance) }
+
+      before do
+        # Mock the CLI components to avoid actual execution
+        allow_any_instance_of(described_class).to receive(:setup_bundler)
+        allow_any_instance_of(described_class).to receive(:setup_load_path)
+        allow_any_instance_of(described_class).to receive(:require_dependencies)
+
+        # Mock command registration
+        allow(commands_class).to receive(registration_method)
+        stub_const("CodingAgentTools::Cli::Commands", commands_class)
+
+        # Mock CLI execution
+        allow(cli_instance).to receive(:call)
+        stub_const("Dry::CLI", cli_class)
+      end
+
+      it "modifies ARGV with command path" do
+        original_args = ["--help"]
+        ARGV.clear
+        ARGV.concat(original_args)
+
+        wrapper.call
+
+        expect(ARGV).to eq(["llm", "models", "--help"])
+      end
+
+      it "calls command registration method" do
+        expect(CodingAgentTools::Cli::Commands).to receive(registration_method)
+        wrapper.call
+      end
+
+      it "executes CLI" do
+        expect(cli_class).to receive(:new).and_return(cli_instance)
+        expect(cli_instance).to receive(:call)
+        wrapper.call
+      end
+
+      it "restores streams after execution" do
+        wrapper.call
+        expect($stdout).to eq(original_stdout)
+        expect($stderr).to eq(original_stderr)
+      end
+    end
+
+    context "when CLI execution raises SystemExit" do
+      let(:exit_code) { 1 }
+      let(:system_exit) { SystemExit.new(exit_code) }
+
+      before do
+        allow_any_instance_of(described_class).to receive(:setup_bundler)
+        allow_any_instance_of(described_class).to receive(:setup_load_path)
+        allow_any_instance_of(described_class).to receive(:require_dependencies)
+
+        commands_class = class_double("CodingAgentTools::Cli::Commands")
+        allow(commands_class).to receive(registration_method)
+        stub_const("CodingAgentTools::Cli::Commands", commands_class)
+
+        cli_instance = instance_double("Dry::CLI")
+        allow(cli_instance).to receive(:call).and_raise(system_exit)
+        cli_class = class_double("Dry::CLI", new: cli_instance)
+        stub_const("Dry::CLI", cli_class)
+      end
+
+      it "re-raises SystemExit" do
+        expect { wrapper.call }.to raise_error(SystemExit)
+      end
+
+      it "restores streams before re-raising" do
+        expect { wrapper.call }.to raise_error(SystemExit)
+        expect($stdout).to eq(original_stdout)
+        expect($stderr).to eq(original_stderr)
+      end
+    end
+
+    context "when an unexpected error occurs" do
+      let(:error) { StandardError.new("Test error") }
+
+      before do
+        allow_any_instance_of(described_class).to receive(:setup_bundler).and_raise(error)
+
+        # Mock ErrorReporter
+        error_reporter = class_double("CodingAgentTools::ErrorReporter")
+        allow(error_reporter).to receive(:call)
+        stub_const("CodingAgentTools::ErrorReporter", error_reporter)
+
+        # Mock exit to prevent actual exit
+        allow_any_instance_of(described_class).to receive(:exit)
+      end
+
+      it "handles error through ErrorReporter" do
+        expect(CodingAgentTools::ErrorReporter).to receive(:call).with(error, debug: false)
+        wrapper.call
+      end
+
+      it "exits with code 1" do
+        expect_any_instance_of(described_class).to receive(:exit).with(1)
+        wrapper.call
+      end
+
+      it "restores streams after error" do
+        wrapper.call
+        expect($stdout).to eq(original_stdout)
+        expect($stderr).to eq(original_stderr)
+      end
+    end
+  end
+
+  describe "output modification" do
+    let(:content) do
+      {
+        stdout: "llm-gemini-models llm models --help",
+        stderr: 'Usage: "some-path llm models"'
+      }
+    end
+
+    it "modifies stdout content correctly" do
+      modified = wrapper.send(:modify_output_messages, content)
+      expect(modified[:stdout]).to eq("llm-gemini-models --help")
+    end
+
+    it "modifies stderr content with command references" do
+      modified = wrapper.send(:modify_output_messages, content)
+      expect(modified[:stderr]).to eq('Usage: "llm-gemini-models"')
+    end
+
+    context "for query commands" do
+      let(:command_path) { ["llm", "query"] }
+      let(:executable_name) { "llm-gemini-query" }
+      let(:content) do
+        {
+          stdout: "",
+          stderr: 'Usage: "some-path llm query PROMPT"'
+        }
+      end
+
+      it "handles query command usage patterns" do
+        modified = wrapper.send(:modify_output_messages, content)
+        expect(modified[:stderr]).to eq('Usage: "llm-gemini-query PROMPT"')
+      end
+    end
+
+    context "when content doesn't contain command string" do
+      let(:content) do
+        {
+          stdout: "Regular output",
+          stderr: "Regular error"
+        }
+      end
+
+      it "returns content unchanged" do
+        modified = wrapper.send(:modify_output_messages, content)
+        expect(modified).to eq(content)
+      end
+    end
+  end
+
+  describe "private methods" do
+    describe "#bundler_environment?" do
+      it "returns true when BUNDLE_GEMFILE is set" do
+        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return("/path/to/Gemfile")
+        expect(wrapper.send(:bundler_environment?)).to be true
+      end
+
+      it "returns true when Gemfile exists" do
+        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return(nil)
+        allow(File).to receive(:exist?).and_return(true)
+        expect(wrapper.send(:bundler_environment?)).to be true
+      end
+
+      it "returns false when neither condition is met" do
+        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return(nil)
+        allow(File).to receive(:exist?).and_return(false)
+        expect(wrapper.send(:bundler_environment?)).to be false
+      end
+    end
+
+    describe "#prepare_arguments" do
+      let(:original_argv) { ["--help", "--verbose"] }
+
+      before do
+        ARGV.clear
+        ARGV.concat(original_argv)
+      end
+
+      after do
+        ARGV.clear
+        ARGV.concat(original_argv)
+      end
+
+      it "prepends command path to ARGV" do
+        wrapper.send(:prepare_arguments)
+        expect(ARGV).to eq(["llm", "models", "--help", "--verbose"])
+      end
+    end
+
+    describe "#get_captured_content" do
+      it "returns captured stdout and stderr" do
+        wrapper.instance_variable_set(:@captured_stdout, StringIO.new("stdout content"))
+        wrapper.instance_variable_set(:@captured_stderr, StringIO.new("stderr content"))
+
+        content = wrapper.send(:get_captured_content)
+
+        expect(content[:stdout]).to eq("stdout content")
+        expect(content[:stderr]).to eq("stderr content")
+      end
+    end
+  end
+
+  describe "integration with different command configurations" do
+    context "with LMS commands" do
+      let(:command_path) { ["lms", "models"] }
+      let(:registration_method) { :register_lms_commands }
+      let(:executable_name) { "llm-lmstudio-models" }
+
+      it "works with different command configurations" do
+        expect(wrapper.send(:command_path)).to eq(["lms", "models"])
+        expect(wrapper.send(:registration_method)).to eq(:register_lms_commands)
+        expect(wrapper.send(:executable_name)).to eq("llm-lmstudio-models")
+      end
+    end
+
+    context "with query commands" do
+      let(:command_path) { ["lms", "query"] }
+      let(:registration_method) { :register_lms_commands }
+      let(:executable_name) { "llm-lmstudio-query" }
+
+      it "works with query command configurations" do
+        expect(wrapper.send(:command_path)).to eq(["lms", "query"])
+        expect(wrapper.send(:registration_method)).to eq(:register_lms_commands)
+        expect(wrapper.send(:executable_name)).to eq("llm-lmstudio-query")
+      end
+    end
+  end
+end
diff --git a/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb b/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
new file mode 100644
index 0000000..9ebf893
--- /dev/null
+++ b/spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
@@ -0,0 +1,543 @@
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
+
+    it "initializes without credentials" do
+      # Clear any environment variables that might interfere
+      allow(ENV).to receive(:[]).with("LM_STUDIO_API_KEY").and_return(nil)
+
+      client = described_class.new
+      expect(client.instance_variable_get(:@api_key)).to be_nil
+    end
+
+    it "accepts API key via options" do
+      client = described_class.new(api_key: "test-key")
+      expect(client.instance_variable_get(:@api_key)).to eq("test-key")
+    end
+
+    it "accepts API key via environment variable" do
+      allow(ENV).to receive(:[]).with("LM_STUDIO_API_KEY").and_return("env-key")
+
+      client = described_class.new
+      expect(client.instance_variable_get(:@api_key)).to eq("env-key")
+    end
+
+    it "prefers options API key over environment variable" do
+      allow(ENV).to receive(:[]).with("LM_STUDIO_API_KEY").and_return("env-key")
+
+      client = described_class.new(api_key: "option-key")
+      expect(client.instance_variable_get(:@api_key)).to eq("option-key")
+    end
+
+    context "no credentials", :no_credentials do
+      before do
+        allow(ENV).to receive(:[]).with("LM_STUDIO_API_KEY").and_return(nil)
+      end
+
+      it "initializes successfully without any credentials" do
+        expect { described_class.new }.not_to raise_error
+      end
+
+      it "works with server availability check" do
+        client = described_class.new
+        allow(client.instance_variable_get(:@request_builder)).to receive(:get_json)
+          .and_return({success: true, status: 200})
+
+        expect(client.server_available?).to be true
+      end
+
+      it "works with text generation" do
+        client = described_class.new
+        allow(client).to receive(:server_available?).and_return(true)
+
+        successful_response = {
+          success: true,
+          data: {
+            choices: [
+              {
+                message: {
+                  content: "Hello! How can I help you today?"
+                },
+                finish_reason: "stop"
+              }
+            ],
+            usage: {
+              prompt_tokens: 10,
+              completion_tokens: 20,
+              total_tokens: 30
+            }
+          }
+        }
+
+        allow(client.instance_variable_get(:@request_builder)).to receive(:post_json)
+          .and_return({success: true, status: 200, body: successful_response[:data]})
+
+        allow(client.instance_variable_get(:@response_parser)).to receive(:parse_response)
+          .and_return(successful_response)
+
+        result = client.generate_text("Hello, world!")
+        expect(result[:text]).to eq("Hello! How can I help you today?")
+      end
+
+      it "works with model listing" do
+        client = described_class.new
+        allow(client).to receive(:server_available?).and_return(true)
+
+        models_response = {
+          success: true,
+          data: {
+            data: [
+              {id: "model1", object: "model", owned_by: "local"}
+            ]
+          }
+        }
+
+        allow(client.instance_variable_get(:@request_builder)).to receive(:get_json)
+          .and_return({success: true, status: 200, body: models_response[:data]})
+
+        allow(client.instance_variable_get(:@response_parser)).to receive(:parse_response)
+          .and_return(models_response)
+
+        result = client.list_models
+        expect(result).to eq(models_response[:data][:data])
+      end
+
+      it "verifies localhost functionality without credentials", :localhost_functionality do
+        client = described_class.new
+
+        # Test that client can be created and configured for localhost
+        expect(client.instance_variable_get(:@base_url)).to eq("http://localhost:1234")
+        expect(client.instance_variable_get(:@api_key)).to be_nil
+
+        # Test that all core methods can be called (with mocked responses)
+        allow(client).to receive(:server_available?).and_return(true)
+
+        # Mock successful text generation
+        successful_response = {
+          success: true,
+          data: {
+            choices: [{message: {content: "Test response"}, finish_reason: "stop"}],
+            usage: {prompt_tokens: 5, completion_tokens: 10, total_tokens: 15}
+          }
+        }
+
+        allow(client.instance_variable_get(:@request_builder)).to receive(:post_json)
+          .and_return({success: true, status: 200, body: successful_response[:data]})
+        allow(client.instance_variable_get(:@response_parser)).to receive(:parse_response)
+          .and_return(successful_response)
+
+        # Verify text generation works
+        result = client.generate_text("test prompt")
+        expect(result[:text]).to eq("Test response")
+
+        # Mock successful model listing
+        models_response = {
+          success: true,
+          data: {data: [{id: "test-model", object: "model"}]}
+        }
+
+        allow(client.instance_variable_get(:@request_builder)).to receive(:get_json)
+          .and_return({success: true, status: 200, body: models_response[:data]})
+        allow(client.instance_variable_get(:@response_parser)).to receive(:parse_response)
+          .and_return(models_response)
+
+        # Verify model listing works
+        models = client.list_models
+        expect(models).to eq([{id: "test-model", object: "model"}])
+
+        # Verify model info works
+        model_info = client.model_info
+        expect(model_info).to be_a(Hash)
+      end
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
index 0000000..54c8ea9
--- /dev/null
+++ b/spec/integration/llm_lmstudio_query_integration_spec.rb
@@ -0,0 +1,375 @@
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
+  # VCR-wrapped helper to check LM Studio availability
+  def lm_studio_available?
+    VCR.use_cassette("lm_studio_availability_check", record: :once) do
+      require "net/http"
+      uri = URI("http://localhost:1234/v1/models")
+      response = Net::HTTP.get_response(uri)
+      response.code == "200"
+    end
+  rescue
+    false
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
+        skip "LM Studio server not available at localhost:1234" unless lm_studio_available?
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
+        skip "LM Studio server not available" unless lm_studio_available?
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
+        skip "LM Studio server not available" unless lm_studio_available?
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
+        skip "LM Studio server not available" unless lm_studio_available?
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
+        skip "LM Studio server not available" unless lm_studio_available?
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
diff --git a/spec/spec_helper.rb b/spec/spec_helper.rb
index 54a3197..7320f98 100644
--- a/spec/spec_helper.rb
+++ b/spec/spec_helper.rb
@@ -39,6 +39,8 @@ require_relative "support/matchers/http_matchers"
 require_relative "support/process_helpers"
 # Helper for safe ENV manipulation in specs
 require_relative "support/env_helpers"
+# ANSI color testing infrastructure
+require_relative "support/ansi_color_testing_helper"
 
 RSpec.configure do |config|
   # Enable flags like --only-failures and --next-failure
diff --git a/spec/support/ansi_color_testing_helper.rb b/spec/support/ansi_color_testing_helper.rb
new file mode 100644
index 0000000..62b5a1d
--- /dev/null
+++ b/spec/support/ansi_color_testing_helper.rb
@@ -0,0 +1,337 @@
+# frozen_string_literal: true
+
+module AnsiColorTestingHelper
+  # Standard ANSI color codes for testing
+  ANSI_CODES = {
+    reset: "[INSERT YOUR DIFF CONTENT HERE]33[0m",
+    bold: "[INSERT YOUR DIFF CONTENT HERE]33[1m",
+    dim: "[INSERT YOUR DIFF CONTENT HERE]33[2m",
+    italic: "[INSERT YOUR DIFF CONTENT HERE]33[3m",
+    underline: "[INSERT YOUR DIFF CONTENT HERE]33[4m",
+    blink: "[INSERT YOUR DIFF CONTENT HERE]33[5m",
+    reverse: "[INSERT YOUR DIFF CONTENT HERE]33[7m",
+    strikethrough: "[INSERT YOUR DIFF CONTENT HERE]33[9m",
+    black: "[INSERT YOUR DIFF CONTENT HERE]33[30m",
+    red: "[INSERT YOUR DIFF CONTENT HERE]33[31m",
+    green: "[INSERT YOUR DIFF CONTENT HERE]33[32m",
+    yellow: "[INSERT YOUR DIFF CONTENT HERE]33[33m",
+    blue: "[INSERT YOUR DIFF CONTENT HERE]33[34m",
+    magenta: "[INSERT YOUR DIFF CONTENT HERE]33[35m",
+    cyan: "[INSERT YOUR DIFF CONTENT HERE]33[36m",
+    white: "[INSERT YOUR DIFF CONTENT HERE]33[37m",
+    bright_black: "[INSERT YOUR DIFF CONTENT HERE]33[90m",
+    bright_red: "[INSERT YOUR DIFF CONTENT HERE]33[91m",
+    bright_green: "[INSERT YOUR DIFF CONTENT HERE]33[92m",
+    bright_yellow: "[INSERT YOUR DIFF CONTENT HERE]33[93m",
+    bright_blue: "[INSERT YOUR DIFF CONTENT HERE]33[94m",
+    bright_magenta: "[INSERT YOUR DIFF CONTENT HERE]33[95m",
+    bright_cyan: "[INSERT YOUR DIFF CONTENT HERE]33[96m",
+    bright_white: "[INSERT YOUR DIFF CONTENT HERE]33[97m",
+    bg_black: "[INSERT YOUR DIFF CONTENT HERE]33[40m",
+    bg_red: "[INSERT YOUR DIFF CONTENT HERE]33[41m",
+    bg_green: "[INSERT YOUR DIFF CONTENT HERE]33[42m",
+    bg_yellow: "[INSERT YOUR DIFF CONTENT HERE]33[43m",
+    bg_blue: "[INSERT YOUR DIFF CONTENT HERE]33[44m",
+    bg_magenta: "[INSERT YOUR DIFF CONTENT HERE]33[45m",
+    bg_cyan: "[INSERT YOUR DIFF CONTENT HERE]33[46m",
+    bg_white: "[INSERT YOUR DIFF CONTENT HERE]33[47m"
+  }.freeze
+
+  # Canonical regex for matching ANSI escape sequences
+  ANSI_REGEX = /[INSERT YOUR DIFF CONTENT HERE]33\[[0-9;]*m/
+
+  # Helper methods for creating colored text
+  def self.colorize(text, *codes)
+    codes_str = codes.map { |code| ANSI_CODES[code] || code }.join
+    "#{codes_str}#{text}#{ANSI_CODES[:reset]}"
+  end
+
+  def self.red(text)
+    colorize(text, :red)
+  end
+
+  def self.green(text)
+    colorize(text, :green)
+  end
+
+  def self.yellow(text)
+    colorize(text, :yellow)
+  end
+
+  def self.blue(text)
+    colorize(text, :blue)
+  end
+
+  def self.bold(text)
+    colorize(text, :bold)
+  end
+
+  # Strip ANSI codes from text
+  def self.strip_ansi(text)
+    text.gsub(ANSI_REGEX, "")
+  end
+
+  # Extract only ANSI codes from text
+  def self.extract_ansi_codes(text)
+    text.scan(ANSI_REGEX)
+  end
+
+  # Check if text contains ANSI codes
+  def self.has_ansi_codes?(text)
+    !!(text =~ ANSI_REGEX)
+  end
+
+  # Capture output scenarios for behavior matrix testing
+  class OutputCapture
+    attr_reader :stdout_content, :stderr_content, :stdout_raw, :stderr_raw
+
+    def initialize
+      @original_stdout = $stdout
+      @original_stderr = $stderr
+      @stdout_stringio = StringIO.new
+      @stderr_stringio = StringIO.new
+    end
+
+    # Capture with StringIO (default behavior - no TTY)
+    def capture_with_stringio(&block)
+      $stdout = @stdout_stringio
+      $stderr = @stderr_stringio
+
+      yield
+
+      @stdout_content = @stdout_stringio.string
+      @stderr_content = @stderr_stringio.string
+      @stdout_raw = @stdout_content
+      @stderr_raw = @stderr_content
+
+      self
+    ensure
+      $stdout = @original_stdout
+      $stderr = @original_stderr
+    end
+
+    # Capture with forced color (FORCE_COLOR=1)
+    def capture_with_forced_color(&block)
+      original_force_color = ENV["FORCE_COLOR"]
+      ENV["FORCE_COLOR"] = "1"
+
+      capture_with_stringio(&block)
+    ensure
+      if original_force_color
+        ENV["FORCE_COLOR"] = original_force_color
+      else
+        ENV.delete("FORCE_COLOR")
+      end
+    end
+
+    # Capture with TTY simulation (mock $stdout.tty? to return true)
+    def capture_with_tty_simulation(&block)
+      # Create a custom StringIO that responds to tty? as true
+      tty_stdout = StringIO.new
+      tty_stderr = StringIO.new
+
+      # Define singleton methods to make them behave like TTY
+      def tty_stdout.tty?
+        true
+      end
+
+      def tty_stderr.tty?
+        true
+      end
+
+      $stdout = tty_stdout
+      $stderr = tty_stderr
+
+      yield
+
+      @stdout_content = tty_stdout.string
+      @stderr_content = tty_stderr.string
+      @stdout_raw = @stdout_content
+      @stderr_raw = @stderr_content
+
+      self
+    ensure
+      $stdout = @original_stdout
+      $stderr = @original_stderr
+    end
+
+    # Check if captured output contains ANSI codes
+    def stdout_has_ansi?
+      AnsiColorTestingHelper.has_ansi_codes?(@stdout_content)
+    end
+
+    def stderr_has_ansi?
+      AnsiColorTestingHelper.has_ansi_codes?(@stderr_content)
+    end
+
+    # Get clean text without ANSI codes
+    def stdout_clean
+      AnsiColorTestingHelper.strip_ansi(@stdout_content)
+    end
+
+    def stderr_clean
+      AnsiColorTestingHelper.strip_ansi(@stderr_content)
+    end
+
+    # Get only the ANSI codes from output
+    def stdout_ansi_codes
+      AnsiColorTestingHelper.extract_ansi_codes(@stdout_content)
+    end
+
+    def stderr_ansi_codes
+      AnsiColorTestingHelper.extract_ansi_codes(@stderr_content)
+    end
+
+    # Behavior matrix results
+    def behavior_summary
+      {
+        stdout_has_ansi: stdout_has_ansi?,
+        stderr_has_ansi: stderr_has_ansi?,
+        stdout_length: @stdout_content.length,
+        stderr_length: @stderr_content.length,
+        stdout_clean_length: stdout_clean.length,
+        stderr_clean_length: stderr_clean.length,
+        ansi_codes_count: (stdout_ansi_codes + stderr_ansi_codes).length
+      }
+    end
+  end
+
+  # Convenience methods for quick testing
+  def self.capture_output(&block)
+    OutputCapture.new.capture_with_stringio(&block)
+  end
+
+  def self.capture_with_color(&block)
+    OutputCapture.new.capture_with_forced_color(&block)
+  end
+
+  def self.capture_with_tty(&block)
+    OutputCapture.new.capture_with_tty_simulation(&block)
+  end
+
+  # Behavior matrix testing - runs the same block with different capture methods
+  def self.test_behavior_matrix(&block)
+    {
+      stringio_default: capture_output(&block),
+      forced_color: capture_with_color(&block),
+      tty_simulation: capture_with_tty(&block)
+    }
+  end
+
+  # RSpec matchers integration
+  module RSpecMatchers
+    def self.define_matchers
+      return unless defined?(RSpec)
+
+      RSpec::Matchers.define :have_ansi_codes do
+        match do |text|
+          AnsiColorTestingHelper.has_ansi_codes?(text)
+        end
+
+        failure_message do |text|
+          "expected #{text.inspect} to contain ANSI color codes"
+        end
+
+        failure_message_when_negated do |text|
+          "expected #{text.inspect} not to contain ANSI color codes, but found: #{AnsiColorTestingHelper.extract_ansi_codes(text)}"
+        end
+      end
+
+      RSpec::Matchers.define :have_clean_text do |expected|
+        match do |text|
+          AnsiColorTestingHelper.strip_ansi(text) == expected
+        end
+
+        failure_message do |text|
+          clean = AnsiColorTestingHelper.strip_ansi(text)
+          "expected clean text to be #{expected.inspect}, but got #{clean.inspect}"
+        end
+      end
+
+      RSpec::Matchers.define :output_with_ansi do |expected_clean_text|
+        supports_block_expectations
+
+        match do |block|
+          capture = AnsiColorTestingHelper.capture_output(&block)
+          @actual_clean = capture.stdout_clean
+          @has_ansi = capture.stdout_has_ansi?
+
+          @actual_clean == expected_clean_text && @has_ansi
+        end
+
+        failure_message do
+          messages = []
+          messages << "expected output to contain ANSI codes" unless @has_ansi
+          messages << "expected clean text to be #{expected_clean_text.inspect}, but got #{@actual_clean.inspect}" if @actual_clean != expected_clean_text
+          messages.join(" and ")
+        end
+      end
+    end
+  end
+end
+
+# Auto-define matchers in RSpec if available
+AnsiColorTestingHelper::RSpecMatchers.define_matchers if defined?(RSpec)
+
+# Integration with existing CLI test patterns
+module AnsiColorTestingHelper
+  module CliIntegration
+    # Helper for testing CLI commands with color output
+    def with_color_capture(scenario: :default, &block)
+      case scenario
+      when :default
+        AnsiColorTestingHelper.capture_output(&block)
+      when :force_color
+        AnsiColorTestingHelper.capture_with_color(&block)
+      when :tty
+        AnsiColorTestingHelper.capture_with_tty(&block)
+      else
+        raise ArgumentError, "Unknown scenario: #{scenario}"
+      end
+    end
+
+    # Test a command across all color scenarios
+    def test_command_color_matrix(command_proc)
+      {
+        no_color: with_color_capture(scenario: :default, &command_proc),
+        force_color: with_color_capture(scenario: :force_color, &command_proc),
+        tty_color: with_color_capture(scenario: :tty, &command_proc)
+      }
+    end
+
+    # Verify color consistency across scenarios
+    def expect_consistent_clean_output(results, expected_clean_text)
+      results.each do |scenario, output|
+        expect(output.stdout_clean).to eq(expected_clean_text),
+          "Clean output mismatch in #{scenario} scenario"
+      end
+    end
+
+    # Example CLI color implementation pattern
+    def self.example_colorized_output(text, color, options = {})
+      use_color = should_use_color?(options)
+      if use_color
+        AnsiColorTestingHelper.colorize(text, color)
+      else
+        text
+      end
+    end
+
+    private_class_method
+
+    def self.should_use_color?(options = {})
+      # Example color detection logic for CLI apps
+      return false if ENV["NO_COLOR"]
+      return true if ENV["FORCE_COLOR"] || options[:force_color]
+      return options[:tty] if options.key?(:tty)
+      $stdout.tty?
+    end
+  end
+end
+
+# Include integration helpers in RSpec if available
+if defined?(RSpec)
+  RSpec.configure do |config|
+    config.include AnsiColorTestingHelper::CliIntegration
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

### 2. Current Documentation State

#### Architecture Decision Records (ADRs)
Location: `docs-project/decisions/`
Current files:
No ADR files found (only .keep file exists)

#### Project Documentation  
Location: `docs-project/*.md` (excluding roadmap)
Current files:
docs-project/architecture.md:
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
---

docs-project/blueprint.md:
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
---

docs-project/what-do-we-build.md:
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
---

#### Root Documentation
Location: `*.md` files in project root
Current files:
CHANGELOG.md:
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
---

README.md:
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
Ensure LM Studio is running on `localhost:1234` for offline LLM queries. No API credentials required for localhost usage.

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
---

#### Technical Documentation
Location: `docs/**/*.md`
Current files:
docs/DEVELOPMENT.md:
# Development Workflow Guide

This guide covers the day-to-day development workflow for Coding Agent Tools, including how to use the existing build system tools and follow best practices.

## Overview

The Coding Agent Tools project follows a structured development workflow that emphasizes:
- **Test-Driven Development (TDD)**: Write tests first, then implement features
- **Continuous Integration**: Automated testing and linting on every commit
- **Conventional Commits**: Standardized commit message format
- **Code Quality**: StandardRB linting and comprehensive test coverage

## Development Dependencies

### Core Development Tools

- **RSpec**: Testing framework for unit, integration, and feature tests
- **StandardRB**: Ruby code style and formatting enforcer
- **SimpleCov**: Code coverage analysis and reporting

### Testing & Quality Assurance

- **VCR**: HTTP interaction recording for testing external API integrations
- **WebMock**: HTTP request stubbing and mocking for isolated tests
- **Aruba**: CLI testing framework for command-line integration tests
- **FactoryBot**: Test data generation and fixture management
- **Pry**: Interactive debugging and REPL for development

### Development Support

- **Zeitwerk**: Code loading and autoloading for development environment
- **Bundler**: Dependency management and gem packaging
- **Rake**: Task automation and build system integration
- **YARD**: Documentation generation from code comments

For complete dependency information, see `coding_agent_tools.gemspec` and `Gemfile`.

## API Key Setup for Development

### Environment Configuration

For running tests that interact with real APIs or recording new VCR cassettes:

1. **Copy the example environment files**:
   ```bash
   cp .env.example .env
   cp spec/.env.example spec/.env
   ```

2. **Edit the `.env` files and add your actual API keys** (particularly `GEMINI_API_KEY`):
   ```bash
   # In .env file
   GEMINI_API_KEY="your_actual_gemini_api_key_here"
   
   # In spec/.env file (for testing)
   GEMINI_API_KEY="your_actual_gemini_api_key_here"
   VCR_RECORD=false  # Set to true when recording new cassettes
   ```

3. **When recording new VCR cassettes**, set `VCR_RECORD=true` in `spec/.env`

### Getting API Keys

- **Google Gemini API Key**: Get this from [Google AI Studio](https://makersuite.google.com/app/apikey)
- **GitHub Token** (if needed): Generate from [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)

## Daily Development Workflow

### 1. Start Working on a Feature

```bash
# Get the latest changes
git checkout main
git pull origin main

# Create a new feature branch
git checkout -b feature/your-feature-name
# or for bug fixes
git checkout -b fix/issue-description
```

### 2. Development Cycle

Follow this cycle for each feature or change:

#### A. Write Tests First (TDD)

```bash
# Create or update test files
# Location: spec/coding_agent_tools/...

# Run tests to see them fail (Red)
bin/test
```

#### B. Implement the Feature

```bash
# Write minimal code to make tests pass
# Location: lib/coding_agent_tools/...

# Run tests to see them pass (Green)
bin/test
```

#### C. Refactor and Clean Up

```bash
# Improve code quality without changing functionality
# Run linter to ensure code style
bin/lint

# Run tests to ensure nothing broke
bin/test
```

#### D. Verify Build

```bash
# Build the gem to ensure no packaging issues
bin/build
```

### 3. Commit Your Changes

```bash
# Review your changes
git status
git diff

# Stage related changes
git add path/to/changed/files

# Commit with conventional format
git commit
# This opens your editor with the .gitmessage template
```

### 4. Push and Create Pull Request

```bash
# Push your branch
git push origin feature/your-feature-name

# Create a pull request on GitHub
# Use the provided PR template
```

## Build System Commands

The project includes several `bin/` scripts for common development tasks:

### Core Development Commands

#### `bin/setup`
**Purpose**: Initial project setup and dependency installation
```bash
bin/setup
```
- Installs Ruby gem dependencies
- Sets up development environment
- Configures local settings
- Verifies installation

#### `bin/test`
**Purpose**: Run the complete test suite
```bash
# Run all tests
bin/test

# Run with coverage report
COVERAGE=true bin/test

# Run specific test file
bundle exec rspec spec/path/to/specific_test.rb
```
- Executes RSpec test suite
- Shows test results and failures
- Generates coverage reports when requested
- Validates all functionality

#### `bin/lint`
**Purpose**: Check and fix code style using StandardRB
```bash
# Check for style violations
bin/lint

# Auto-fix violations (when possible)
bundle exec standardrb --fix
```
- Enforces Ruby style guide (StandardRB)
- Reports style violations
- Can automatically fix many issues
- Ensures consistent code formatting

#### `bin/build`
**Purpose**: Build the gem package and verify its local installation
```bash
bin/build
```
- Compiles the gem package
- Validates gemspec configuration
- Creates `.gem` file for distribution
- Verifies packaging integrity by attempting to install the gem locally in a temporary environment
- Provides enhanced build confidence by ensuring the gem can be correctly installed and used

#### `bin/console`
**Purpose**: Interactive development console
```bash
bin/console
```
- Starts IRB with gem loaded
- Allows interactive testing of classes
- Useful for debugging and exploration
- Access to all gem functionality

### Project Management Commands

#### `bin/tn` (Task Next)
**Purpose**: Get the next task to work on
```bash
bin/tn
```
- Shows the next pending task
- Displays task dependencies
- Helps prioritize development work

#### `bin/tal` (Task All List)
**Purpose**: List all available tasks
```bash
bin/tal
```
- Shows complete task backlog
- Displays task status and priorities
- Helps with project planning

### Git Workflow Commands

#### `bin/gc` (Git Commit)
**Purpose**: Enhanced git commit with AI-generated messages
```bash
bin/gc -i "intention of the changes"
```
- Generates descriptive commit messages
- Follows conventional commit format
- Integrates with project workflow

#### `bin/gl` (Git Log)
**Purpose**: Enhanced git log display
```bash
bin/gl
```
- Shows formatted commit history
- Provides better visualization
- Helps track project progress

## Testing Strategy

### Test Organization

```
spec/
├── coding_agent_tools/
│   ├── atoms/          # Unit tests for atomic components
│   ├── molecules/      # Integration tests for molecules
│   ├── organisms/      # Feature tests for organisms
│   └── ecosystems/     # End-to-end tests for ecosystems
├── fixtures/           # Test data and mock files
└── support/           # Test helpers and configurations
```

### Test Types

#### Unit Tests (Atoms)
- Test individual methods and classes
- Fast execution
- Isolated from dependencies
- High coverage target (95%+)

```ruby
RSpec.describe CodingAgentTools::Atoms::FileUtils do
  describe "#read_safely" do
    it "returns file content when file exists" do
      # Test implementation
    end
  end
end
```

#### Integration Tests (Molecules)
- Test component interactions
- Moderate execution time
- Limited external dependencies
- Focus on interface contracts

```ruby
RSpec.describe CodingAgentTools::Molecules::GitOperations do
  describe "#commit_with_message" do
    it "creates commit with proper format" do
      # Test implementation
    end
  end
end
```

#### Feature Tests (Organisms)
- Test complete features
- Slower execution
- May include external calls
- Validate user-facing functionality

```ruby
RSpec.describe CodingAgentTools::Organisms::TaskManager do
  describe "#next_task" do
    it "returns highest priority pending task" do
      # Test implementation
    end
  end
end
```

#### End-to-End Tests (Ecosystems)
- Test complete workflows
- Slowest execution
- Full system integration
- Validate entire user journeys

```ruby
RSpec.describe "CLI Integration" do
  it "completes full task workflow" do
    # Test implementation
  end
end
```

#### Integration Tests with VCR
- Specifically for tests that interact with external APIs (e.g., Google Gemini, GitHub).
- Uses VCR to record and replay HTTP interactions, ensuring tests are fast, deterministic, and don't rely on live external services.
- When recording new cassettes, ensure `VCR_RECORD=true` is set in `spec/.env` and your API keys are configured.
- For detailed setup and usage, refer to the [VCR Testing Guide](docs/testing-with-vcr.md).

```ruby
# Example of a VCR-enabled test
RSpec.describe CodingAgentTools::Molecules::LLMApiClient do
  it "makes an API call and records/replays the response" do
    VCR.use_cassette("llm_response_example") do
      # Test implementation that triggers an external API call
      response = described_class.new.generate_text("test prompt")
      expect(response).to include("expected text")
    end
  end
end
```

### Running Tests

```bash
# Run all tests
bin/test

# Run tests with coverage
COVERAGE=true bin/test

# Run specific test categories
bundle exec rspec spec/coding_agent_tools/atoms/
bundle exec rspec spec/coding_agent_tools/molecules/

# Run tests matching pattern
bundle exec rspec --grep "TaskManager"

# Run failed tests only
bundle exec rspec --only-failures
```

## Code Quality Standards

### StandardRB Configuration

The project uses StandardRB for code formatting and style enforcement:

```yaml
# .standard.yml (if needed for customization)
ruby_version: 3.2
```

### Code Review Checklist

Before submitting code:

- [ ] All tests pass (`bin/test`)
- [ ] Code follows StandardRB style (`bin/lint`)
- [ ] New functionality has tests
- [ ] Documentation is updated
- [ ] Commit messages follow conventional format
- [ ] No hardcoded values or secrets
- [ ] Error handling is appropriate
- [ ] Performance impact considered

### Coverage Requirements

- **Minimum coverage**: 80%
- **Target coverage**: 90%+
- **Critical paths**: 100% coverage required

View coverage reports:
```bash
COVERAGE=true bin/test
open coverage/index.html
```

## Architecture Patterns

### ATOM Hierarchy

```ruby
# Atoms: Simple, pure functions
module CodingAgentTools::Atoms::StringUtils
  def self.snake_case(string)
    # Implementation
  end
end

# Molecules: Compositions of atoms
class CodingAgentTools::Molecules::FileProcessor
  include CodingAgentTools::Atoms::StringUtils

  def process_file(path)
    # Uses atoms to build functionality
  end
end

# Organisms: Business logic components
class CodingAgentTools::Organisms::ProjectManager
  def initialize(file_processor: Molecules::FileProcessor.new)
    @file_processor = file_processor
  end
end

# Ecosystems: Complete subsystems
class CodingAgentTools::Ecosystems::CLI
  def initialize
    @project_manager = Organisms::ProjectManager.new
  end
end
```

### Dependency Injection

Use dependency injection for testability:

```ruby
class SomeClass
  def initialize(dependency: DefaultDependency.new)
    @dependency = dependency
  end
end

# In tests
let(:mock_dependency) { double("dependency") }
let(:instance) { described_class.new(dependency: mock_dependency) }
```

### Zeitwerk Autoloading

The project utilizes Zeitwerk for efficient and performant code autoloading. This means classes and modules are automatically loaded when first referenced, without requiring explicit `require` statements for most of the application's own code.

- **Benefits**: Faster startup times, less boilerplate `require` statements, and a clearer representation of the codebase structure.
- **Convention**: Code is organized into directories matching the module/class hierarchy. For example, `lib/coding_agent_tools/atoms/string_utils.rb` defines `CodingAgentTools::Atoms::StringUtils`.
- **Development**: When adding new files or directories, ensure they follow Zeitwerk's naming conventions to be automatically picked up. Run `bin/console` to confirm autoloading works as expected for new components.

### Dry-Monitor Observability

`dry-monitor` is used to implement an event-based observability pattern. This allows for clear separation of concerns by dispatching events when significant actions occur within the application, which other components can subscribe to.

- **Benefits**: Decoupled components, easier debugging and logging, and the ability to extend functionality without modifying core logic.
- **Usage**: Components publish events (e.g., `monitor.publish(:task_completed, task_id: 123)`), and listeners subscribe to these events to perform actions like logging, metrics collection, or triggering subsequent processes.
- **Example**: Critical operations might publish events that `dry-monitor` listeners can pick up to log detailed information, or update internal state for monitoring dashboards.

## Debugging Workflow

### Using the Console

```bash
bin/console

# In the console:
> require 'pry'; binding.pry  # Set breakpoint
> CodingAgentTools::SomeClass.new.debug_method
```

### Adding Debug Output

```ruby
# Use structured logging
require 'logger'

logger = Logger.new(STDOUT)
logger.debug "Processing file: #{filename}"
logger.info "Operation completed successfully"
logger.error "Failed to process: #{error.message}"
```

### Running Single Tests

```bash
# Run specific test
bundle exec rspec spec/path/to/test_spec.rb:line_number

# Run with debugging
bundle exec rspec spec/path/to/test_spec.rb --pry
```

## Performance Considerations

### Benchmarking

```ruby
require 'benchmark'

Benchmark.bm do |x|
  x.report("method_a") { 1000.times { method_a } }
  x.report("method_b") { 1000.times { method_b } }
end
```

### Profiling

```ruby
require 'ruby-prof'

RubyProf.start
# Your code here
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
```

## Common Development Tasks

### Adding a New Feature

1. **Plan the feature**:
   - Define requirements and scope
   - Identify affected components
   - Plan test strategy

2. **Write tests first**:
   ```bash
   # Create test file
   touch spec/coding_agent_tools/path/to/new_feature_spec.rb
   
   # Write failing tests
   bin/test  # Should show failures
   ```

3. **Implement the feature**:
   ```bash
   # Create implementation file
   touch lib/coding_agent_tools/path/to/new_feature.rb
   
   # Implement minimal code
   bin/test  # Should pass
   ```

4. **Refactor and optimize**:
   ```bash
   bin/lint  # Check style
   bin/test  # Verify functionality
   ```

### Fixing a Bug

1. **Reproduce the bug**:
   ```bash
   # Write a failing test that demonstrates the bug
   bin/test  # Should fail
   ```

2. **Fix the issue**:
   ```bash
   # Make minimal changes to fix the bug
   bin/test  # Should pass
   ```

3. **Verify the fix**:
   ```bash
   bin/test  # All tests should pass
   bin/lint  # Code should be clean
   ```

### Updating Dependencies

```bash
# Update Gemfile.lock
bundle update

# Run tests to ensure compatibility
bin/test

# Check for security vulnerabilities
bundle audit
```

## Release Workflow

### Preparing for Release

1. **Update version**:
   ```ruby
   # lib/coding_agent_tools/version.rb
   VERSION = "0.2.0"
   ```

2. **Update changelog**:
   ```markdown
   # CHANGELOG.md
   ## [0.2.0] - 2024-01-15
   ### Added
   - New feature description
   ### Fixed
   - Bug fix description
   ```

3. **Final verification**:
   ```bash
   bin/test
   bin/lint
   bin/build
   ```

### Version Tagging

```bash
# Tag the release
git tag -a v0.2.0 -m "Release version 0.2.0"
git push origin v0.2.0
```

## Troubleshooting

### Common Issues

#### Tests Failing Unexpectedly
```bash
# Clear test cache
rm -rf spec/examples.txt

# Reinstall dependencies
bundle clean --force
bundle install

# Run tests again
bin/test
```

#### Linter Errors
```bash
# Auto-fix common issues
bundle exec standardrb --fix

# Check remaining issues
bin/lint
```

#### Build Failures
```bash
# Check gemspec validity
gem build coding_agent_tools.gemspec

# Verify dependencies
bundle check
```

## Best Practices Summary

1. **Always run tests before committing**: `bin/test`
2. **Keep commits small and focused**: One logical change per commit
3. **Write descriptive commit messages**: Follow conventional commits
4. **Update tests with code changes**: Maintain test coverage
5. **Use the build scripts**: Leverage `bin/` commands for consistency
6. **Review your own code first**: Check diff before pushing
7. **Ask for help when stuck**: Use GitHub issues or discussions

## Quick Reference

```bash
# Daily workflow commands
bin/setup     # Initial setup
bin/test      # Run tests
bin/lint      # Check style
bin/build     # Build gem
bin/console   # Interactive shell

# Git workflow
git checkout -b feature/name
# ... make changes ...
bin/test && bin/lint
git commit
git push origin feature/name

# Project management
bin/tn        # Next task
bin/tal       # All tasks
bin/gc -i "intention"  # AI commit
```

Happy coding! 🚀
---

docs/SETUP.md:
# Development Setup Guide

This guide will help you set up a complete development environment for Coding Agent Tools from scratch.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

### Required
- **Ruby 3.4.2**
- **Git** (version 2.0+)
- **Bundler** gem

### Optional
- **LM Studio** (for offline LLM functionality)
- **GitHub CLI** (`gh`) for enhanced GitHub integration

## System-Specific Setup

### macOS

```bash
# Install Ruby via Homebrew (recommended)
brew install ruby

# Or use rbenv for version management
brew install rbenv
rbenv install 3.4.2
rbenv global 3.4.2

# Install Bundler
gem install bundler
```

### Ubuntu/Debian

```bash
# Install Ruby and development dependencies
sudo apt update
sudo apt install ruby-full ruby-bundler build-essential git

# Verify installation
ruby --version
bundler --version
```

### Windows

```bash
# Use RubyInstaller
# Download from: https://rubyinstaller.org/
# Install Ruby+Devkit version

# Verify installation in Command Prompt or PowerShell
ruby --version
bundler --version
```

## Project Setup

### 1. Clone the Repository

```bash
# Clone your fork (replace with your username)
git clone https://github.com/cs3b/coding-agent-tools.git
cd coding-agent-tools

# Or clone the main repository
git clone https://github.com/cs3b/coding-agent-tools.git
cd coding-agent-tools
```

### 2. Automated Setup

The project includes an automated setup script that handles all dependencies:

```bash
# Run the setup script
bin/setup
```

This script will:
- Install all Ruby gem dependencies via Bundler
- Set up development tools and configurations
- Verify the installation
- Create necessary local configuration files

### 3. Manual Setup (Alternative)

If you prefer manual setup or the automated script fails:

```bash
# Install dependencies
bundle install

# Verify installation
bundle exec ruby --version
```

## Verification

After setup, verify everything is working correctly:

### 1. Run Tests

```bash
# Run the full test suite
bin/test

# Expected output: All tests should pass
# Example output:
# Finished in 2.34 seconds (files took 0.5 seconds to load)
# 42 examples, 0 failures
```

### 2. Run Linter

```bash
# Check code style
bin/lint

# Expected output: No offenses detected
# If there are style issues, they will be listed
```

### 3. Build Gem

```bash
# Build the gem locally
bin/build

# Expected output: Successfully built RubyGem
# Creates: coding_agent_tools-X.X.X.gem
```

### 4. Interactive Console

```bash
# Start the development console
bin/console

# This opens an IRB session with the gem loaded
# You can test classes and methods interactively
```

## Configuration

### 1. Git Configuration

Set up Git commit message template:

```bash
# Configure commit template
git config commit.template .gitmessage

# Verify configuration
git config --list | grep commit.template
```

### 2. API Keys (Optional)

For full functionality, especially for features interacting with external APIs, configure your API keys using the provided example environment files.

1.  **Copy the example environment files**:
    ```bash
    cp .env.example .env
    cp spec/.env.example spec/.env
    ```

2.  **Edit the `.env` and `spec/.env` files**:
    - Open `.env` and `spec/.env` in your editor.
    - Add your actual `GEMINI_API_KEY` to both files.
    - The `spec/.env` file is specifically for testing and VCR recording. When you need to record new VCR cassettes for API integration tests, you will set `VCR_RECORD=true` in this file.

    Example `.env` (development settings):
    ```
    # .env
    GEMINI_API_KEY="your_actual_gemini_api_key_here"
    GITHUB_TOKEN="your_actual_github_token_here"
    ```

    Example `spec/.env` (testing settings for VCR):
    ```
    # spec/.env
    GEMINI_API_KEY="your_actual_gemini_api_key_here"
    VCR_RECORD=false # Set to true when recording new cassettes
    ```

3.  **Obtaining API Keys**:
    - **Google Gemini API Key**: Get this from [Google AI Studio](https://makersuite.google.com/app/apikey).
    - **GitHub Token** (if needed): Generate from [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens).

### 3. LM Studio (Optional)

For offline LLM functionality:

1. Download and install LM Studio from https://lmstudio.ai/
2. Start LM Studio and load a compatible model
3. Ensure it's running on `localhost:1234` (default)
4. No API credentials required for localhost usage

## Development Scripts

The project includes several convenience scripts in the `bin/` directory:

### Core Development Scripts

```bash
# Setup and dependency management
bin/setup          # Initial project setup

# Testing and quality assurance
bin/test           # Run all tests
bin/lint           # Run StandardRB linter
bin/build          # Build the gem

# Development tools
bin/console        # Interactive Ruby console
bin/run            # Run gem commands during development
```

### Project-Specific Scripts

```bash
# Task management
bin/tn             # Get next task to work on
bin/tal            # List all tasks
bin/tnid           # Get task by ID

# Git workflow
bin/gc             # Git commit with message
bin/gl             # Git log
bin/gp             # Git push

# Other utilities
bin/tree           # Show project structure
bin/rc             # Release context generation
bin/tr             # Task runner
```

## IDE/Editor Setup

### VS Code

Recommended extensions:
- Ruby LSP
- StandardRB (Ruby formatter)
- GitLens
- Markdown All in One

Example `.vscode/settings.json`:
```json
{
  "ruby.useLanguageServer": true,
  "ruby.lint": {
    "standardrb": true
  },
  "ruby.format": "standardrb",
  "[ruby]": {
    "editor.defaultFormatter": "shopify.ruby-lsp",
    "editor.formatOnSave": true
  }
}
```

### RubyMine/IntelliJ

1. Install Ruby plugin
2. Configure StandardRB as the formatter
3. Enable "Format on save"
4. Set up Git integration

## Common Issues and Solutions

### Bundle Install Fails

```bash
# Clear Bundler cache
bundle clean --force

# Reinstall dependencies
rm Gemfile.lock
bundle install
```

### Permission Issues (macOS/Linux)

```bash
# If gem installation fails due to permissions
sudo gem install bundler

# Or use user-local installation
gem install --user-install bundler
```

### Ruby Version Issues

```bash
# Check current Ruby version
ruby --version

# If using rbenv, ensure correct version
rbenv versions
rbenv local 3.4.2
```

### Git Configuration Issues

```bash
# If commit template isn't working
git config --local commit.template .gitmessage

# Verify Git is properly configured
git config --list --local
```

## Testing Your Setup

Create a simple test to verify everything works:

```bash
# Create a test file
cat > test_setup.rb << 'EOF'
#!/usr/bin/env ruby

require_relative 'lib/coding_agent_tools'

puts "Ruby version: #{RUBY_VERSION}"
puts "Gem loaded successfully: #{defined?(CodingAgentTools) ? 'Yes' : 'No'}"
puts "Setup complete! 🎉"
EOF

# Run the test
ruby test_setup.rb

# Clean up
rm test_setup.rb
```

## Next Steps

Once your development environment is set up:

1. **Read the [Development Guide](DEVELOPMENT.md)** to understand the workflow
2. **Check [CONTRIBUTING.md](../.github/CONTRIBUTING.md)** for contribution guidelines
3. **Explore the codebase** structure in `lib/coding_agent_tools/`
4. **Run existing tests** to understand the current functionality
5. **Look for issues** labeled "good first issue" to start contributing

## Getting Help

If you encounter issues during setup:

1. **Check existing issues** on GitHub
2. **Review the troubleshooting section** above
3. **Create a new issue** with:
   - Your operating system and version
   - Ruby version (`ruby --version`)
   - Complete error messages
   - Steps you've already tried

## Quick Reference

```bash
# Complete setup workflow
git clone https://github.com/YOUR_USERNAME/coding-agent-tools.git
cd coding-agent-tools
bin/setup
bin/test
bin/lint

# Daily development workflow
git checkout -b feature/my-feature
# ... make changes ...
bin/test && bin/lint
git commit
git push origin feature/my-feature
```

Happy coding! 🚀
---

docs/ansi-color-stringio-behavior.md:
# ANSI Color StringIO Behavior Documentation

## Overview

This document describes the behavior of ANSI color codes when captured through Ruby's `StringIO` class and provides infrastructure for testing CLI applications with color output. The testing infrastructure was created to prepare for future color features in CLI commands while ensuring consistent behavior across different output capture scenarios.

## Key Findings

### StringIO Behavior with ANSI Codes

When using `StringIO` to capture output containing ANSI escape sequences:

1. **ANSI codes are preserved as literal strings** - No interpretation or filtering occurs
2. **All escape sequences remain intact** - Colors, formatting, and control codes are captured exactly as written
3. **TTY detection has no effect** - `StringIO` objects report `tty? = false`, but ANSI codes are still captured
4. **Environment variables are ignored** - `FORCE_COLOR` and similar variables don't affect StringIO capture

### Behavior Matrix

| Scenario | ANSI Codes Captured | TTY Detection | Environment Variables |
|----------|-------------------|---------------|---------------------|
| StringIO Default | ✅ Yes | ❌ `tty? = false` | ❌ Ignored |
| StringIO + FORCE_COLOR=1 | ✅ Yes | ❌ `tty? = false` | ❌ Ignored |
| StringIO + TTY Simulation | ✅ Yes | ✅ `tty? = true` (mocked) | ❌ Ignored |

**Key Insight**: StringIO captures ANSI codes regardless of TTY status or environment variables, making it reliable for testing color output.

## Testing Infrastructure

### AnsiColorTestingHelper Module

The `AnsiColorTestingHelper` provides comprehensive tools for testing ANSI color behavior:

#### Core Features

- **Color Generation**: Predefined ANSI color codes and helper methods
- **Output Capture**: Multiple capture scenarios (default, forced color, TTY simulation)
- **Code Analysis**: Extract, strip, and analyze ANSI escape sequences
- **RSpec Integration**: Custom matchers for color testing

#### Helper Methods

```ruby
# Create colored text
AnsiColorTestingHelper.red("Error message")
AnsiColorTestingHelper.colorize("Custom", :bold, :green)

# Analyze ANSI codes
AnsiColorTestingHelper.has_ansi_codes?(text)
AnsiColorTestingHelper.strip_ansi(text)
AnsiColorTestingHelper.extract_ansi_codes(text)

# Capture output scenarios
AnsiColorTestingHelper.capture_output { puts colored_text }
AnsiColorTestingHelper.capture_with_color { puts colored_text }
AnsiColorTestingHelper.capture_with_tty { puts colored_text }
```

#### Output Capture API

```ruby
# Basic capture
output = AnsiColorTestingHelper.capture_output do
  puts AnsiColorTestingHelper.green("Success!")
end

# Access captured content
output.stdout_content    # Raw output with ANSI codes
output.stdout_clean      # Clean text without ANSI codes
output.stdout_has_ansi?  # Boolean check for ANSI presence
output.stdout_ansi_codes # Array of extracted ANSI codes
```

#### Behavior Matrix Testing

```ruby
# Test all scenarios at once
results = AnsiColorTestingHelper.test_behavior_matrix do
  puts AnsiColorTestingHelper.blue("Test output")
end

# Access results for each scenario
results[:stringio_default]  # Normal StringIO capture
results[:forced_color]      # With FORCE_COLOR=1
results[:tty_simulation]    # With mocked TTY
```

## Usage Patterns for CLI Testing

### Basic Color Output Testing

```ruby
describe "CLI command with colors" do
  it "outputs colored status messages" do
    output = AnsiColorTestingHelper.capture_output do
      run_cli_command_with_colors
    end
    
    expect(output.stdout_has_ansi?).to be true
    expect(output.stdout_clean).to include("Operation completed")
    expect(output.stdout_ansi_codes).to include("[LIST YOUR TECHNICAL DOCUMENTATION FILES HERE]33[32m") # green
  end
end
```

### Testing Color vs Plain Output

```ruby
describe "conditional color output" do
  it "includes colors when supported" do
    output = AnsiColorTestingHelper.capture_with_tty do
      cli_command.run_with_color_detection
    end
    
    expect(output.stdout_has_ansi?).to be true
  end
  
  it "omits colors for non-TTY output" do
    output = AnsiColorTestingHelper.capture_output do
      cli_command.run_with_color_detection
    end
    
    # Note: This test demonstrates StringIO behavior
    # In practice, CLI apps might check $stdout.tty?
    # and disable colors, but StringIO still captures them
  end
end
```

### Complex Scenario Testing

```ruby
describe "mixed output with colors" do
  it "handles combination of plain and colored text" do
    output = AnsiColorTestingHelper.capture_output do
      puts "Plain line"
      puts AnsiColorTestingHelper.red("Error line")
      puts "Another plain line"
    end
    
    expect(output.stdout_clean).to eq(
      "Plain line\nError line\nAnother plain line\n"
    )
    expect(output.stdout_ansi_codes.length).to eq(2) # red + reset
  end
end
```

### RSpec Matchers Integration

```ruby
describe "with custom matchers" do
  it "uses convenience matchers" do
    colored_text = AnsiColorTestingHelper.green("Success")
    
    expect(colored_text).to have_ansi_codes
    expect(colored_text).to have_clean_text("Success")
  end
  
  it "tests block output" do
    expect {
      puts AnsiColorTestingHelper.blue("Test")
    }.to output_with_ansi("Test\n")
  end
end
```

## Side-Effect Management

The testing infrastructure properly manages side effects:

### Stdout/Stderr Restoration

```ruby
# Original streams are always restored, even on exceptions
original_stdout = $stdout
AnsiColorTestingHelper.capture_output do
  raise "Error during capture"
end
# $stdout is restored to original_stdout
```

### Environment Variable Safety

```ruby
# Environment variables are restored after forced color testing
original_force_color = ENV['FORCE_COLOR']
AnsiColorTestingHelper.capture_with_color do
  # FORCE_COLOR=1 during block
end
# ENV['FORCE_COLOR'] restored to original value
```

## Future CLI Color Implementation Guidelines

### Recommended Patterns

1. **TTY Detection**: Use `$stdout.tty?` for color decisions in production code
2. **Environment Override**: Respect `FORCE_COLOR` and `NO_COLOR` environment variables
3. **Graceful Degradation**: Always provide plain text fallbacks
4. **Testing**: Use this infrastructure to test both colored and plain output paths

### Example CLI Color Implementation

```ruby
class ColorizedCLI
  def self.colorize(text, color)
    if should_use_color?
      AnsiColorTestingHelper.colorize(text, color)
    else
      text
    end
  end
  
  private
  
  def self.should_use_color?
    return false if ENV['NO_COLOR']
    return true if ENV['FORCE_COLOR']
    $stdout.tty?
  end
end
```

### Testing the Implementation

```ruby
describe ColorizedCLI do
  it "uses colors when TTY is detected" do
    output = AnsiColorTestingHelper.capture_with_tty do
      puts ColorizedCLI.colorize("Test", :red)
    end
    
    expect(output.stdout_has_ansi?).to be true
  end
  
  it "omits colors for non-TTY output" do
    output = AnsiColorTestingHelper.capture_output do
      puts ColorizedCLI.colorize("Test", :red)
    end
    
    # Depends on implementation - if it checks $stdout.tty?
    # it might not include colors even though StringIO captures them
  end
end
```

## Performance Characteristics

- **Low Overhead**: StringIO capture adds minimal performance impact
- **Memory Efficient**: ANSI code analysis uses regex scanning, not string duplication
- **Scalable**: Tested with 100+ colored lines without performance degradation

## Integration with Existing Test Suite

The helper integrates seamlessly with the existing RSpec test infrastructure:

- **Automatic Loading**: Include in `spec_helper.rb` or require as needed
- **Matcher Registration**: RSpec matchers are automatically registered
- **Environment Safety**: Works with existing environment variable management
- **Coverage Friendly**: All helper methods are covered by the behavior matrix tests

## Canonical ANSI Regex

The helper provides a standard regex for ANSI escape sequence matching:

```ruby
AnsiColorTestingHelper::ANSI_REGEX = /[LIST YOUR TECHNICAL DOCUMENTATION FILES HERE]33\[[0-9;]*m/
```

This regex matches the most common ANSI color and formatting codes used in CLI applications.

## Conclusion

This infrastructure provides a solid foundation for implementing and testing CLI color features. The key insight that StringIO reliably captures ANSI codes regardless of TTY status makes testing straightforward and predictable. Future color implementations can be built with confidence knowing the testing infrastructure will accurately capture and verify color behavior across different scenarios.
---

docs/llm-integration/gemini-query-guide.md:
# Gemini Query Guide

This guide provides comprehensive documentation for the `exe/llm-gemini-query` command, which allows users to interact with Google Gemini Large Language Models (LLMs) directly from the command line. It covers setup, usage patterns, advanced options, troubleshooting, and practical examples to help you effectively leverage Gemini LLM integration features. For a general overview of the project, refer to the [main README](../../README.md).

## Table of Contents
1.  [Introduction](#introduction)
2.  [Setup](#setup)
    *   [API Key Configuration](#api-key-configuration)
3.  [Basic Usage](#basic-usage)
    *   [String Prompts](#string-prompts)
    *   [File Prompts](#file-prompts)
4.  [Output Format Options](#output-format-options)
    *   [Text Output (Default)](#text-output-default)
    *   [JSON Output](#json-output)
5.  [Advanced Options](#advanced-options)
    *   [`--model`](#--model)
    *   [`--temperature`](#--temperature)
    *   [`--max-tokens`](#--max-tokens)
    *   [`--system`](#--system)
    *   [`--debug`](#--debug)
6.  [Combined Options Examples](#combined-options-examples)
7.  [Troubleshooting](#troubleshooting)
    *   [API Key Not Configured](#api-key-not-configured)
    *   [Prompt File Not Found](#prompt-file-not-found)
    *   [Common Errors](#common-errors)

---

## Introduction

The `exe/llm-gemini-query` command provides a convenient way to send prompts to Google Gemini models and receive responses directly in your terminal. It's designed for quick queries, scripting, and integrating LLM capabilities into command-line workflows.

## Setup

Before using `llm-gemini-query`, you need to obtain a Google Gemini API key and configure it for your environment.

### API Key Configuration

1.  **Obtain a Gemini API Key:**
    *   Go to the [Google AI Studio](https://aistudio.google.com/app/apikey) website.
    *   Create a new API key or use an existing one. Keep this key secure.

2.  **Configure `.env` file:**
    The `llm-gemini-query` command expects the API key to be available as an environment variable named `GEMINI_API_KEY`. The recommended way to manage this is by using a `.env` file in your project's root directory.

    *   Create a file named `.env` in the root of your project (if one doesn't exist).
    *   Add the following line to your `.env` file, replacing `YOUR_GEMINI_API_KEY` with the actual key you obtained:
        ```/dev/null/example.env#L1
        GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
        ```
    *   Ensure your shell environment is set up to load variables from `.env` files (e.g., by using `direnv` or similar tools, or by sourcing the file manually: `source .env`). Refer to the project's `.env.example` for more details on environment variable management. For general project setup instructions, including environment variable management, refer to the [Project Setup Guide](../SETUP.md).

## Basic Usage

The fundamental usage of `llm-gemini-query` involves providing a prompt, either as a direct string or from a file.

### String Prompts

To query Gemini with a direct string prompt, simply pass the text as an argument:

```/dev/null/example.sh#L1
llm-gemini-query "What is Ruby programming language?"
```

This will send the question to the default Gemini model and print the text response to your terminal.

### File Prompts

For longer prompts or to keep your prompts organized, you can use a file. Create a text file (e.g., `prompt.txt`) containing your prompt, then use the `--file` (or `-f`) flag:

**Example `prompt.txt`:**
```/dev/null/prompt.txt#L1-3
Explain the concept of quantum entanglement in simple terms.
Provide a brief summary suitable for a high school student.
```

**Command:**
```/dev/null/example.sh#L1
llm-gemini-query prompt.txt --file
```

## Output Format Options

You can specify the format of the output from the Gemini model using the `--format` option.

### Text Output (Default)

By default, the command returns the response as plain text. This is suitable for general queries where you only need the model's textual answer.

```/dev/null/example.sh#L1
llm-gemini-query "Who wrote 'Romeo and Juliet'?"
```
_Expected Output (example):_
```/dev/null/output.txt#L1
William Shakespeare.
```

### JSON Output

For structured responses, particularly useful for programmatic processing or when the model is expected to return data, use `--format json`:

```/dev/null/example.sh#L1
llm-gemini-query "Explain quantum computing" --format json
```
_Expected Output (example, truncated):_
```/dev/null/output.json#L1-10
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Quantum computing is a new type of computing that uses the principles of quantum mechanics..."
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP",
      "index": 0
    }
  ],
  "promptFeedback": {
    "safetyRatings": []
  }
}
```

## Advanced Options

`llm-gemini-query` offers several options to fine-tune the model's behavior and the command's execution.

### `--model`

Specifies the Gemini model to use for the query. The default model is `gemini-2.0-flash-lite`. You can specify other available models, such as `gemini-pro`.

```/dev/null/example.sh#L1
llm-gemini-query \"Hello\" --model gemini-2.0-flash-lite
```

**Note:** The availability of specific models like `gemini-pro` can vary by region or API version. To see the list of models supported by your API key and their capabilities, you may need to consult the Google Gemini API documentation or use a programmatic approach to list available models.

### `--temperature`

Controls the randomness of the output. A higher temperature (e.g., 1.0) results in more creative and diverse responses, while a lower temperature (e.g., 0.0) makes the output more deterministic and focused. The valid range is typically 0.0 to 2.0.

```/dev/null/example.sh#L1
llm-gemini-query "Write a short poem about a cat" --temperature 0.8
```

### `--max-tokens`

Sets the maximum number of tokens (words or word pieces) the model should generate in its response. This is useful for controlling the length of the output and managing costs.

```/dev/null/example.sh#L1
llm-gemini-query "Describe the solar system" --max-tokens 100
```

### `--system`

Provides a system instruction or prompt to guide the model's overall behavior or persona. This is useful for setting context that applies to the entire conversation or interaction.

```/dev/null/example.sh#L1
llm-gemini-query "List three benefits of exercise." --system "You are a helpful fitness coach. Respond concisely."
```

### `--debug`

Enables debug output, providing more verbose information, especially useful for troubleshooting issues or understanding the internal workings of the command.

```/dev/null/example.sh#L1
llm-gemini-query long_prompt.txt --file --format json --debug
```

## Combined Options Examples

You can combine multiple options to achieve specific behaviors.

**Example 1: Specific model, temperature, and JSON output from a file.**
```/dev/null/example.sh#L1
llm-gemini-query research_summary.txt --file --model gemini-pro --temperature 0.7 --format json
```

**Example 2: Concise creative poem with system instruction and limited length.**
```/dev/null/example.sh#L1
llm-gemini-query "Write a haiku about a rainy day." --system "Be playful and concise." --temperature 0.9 --max-tokens 30
```

## Troubleshooting

This section addresses common issues you might encounter when using `llm-gemini-query`.

### API Key Not Configured

If you receive an error related to authentication or a missing API key, ensure that your `GEMINI_API_KEY` environment variable is correctly set.

*   **Check `.env` file:** Verify that `GEMINI_API_KEY="YOUR_GEMINI_API_KEY"` (with your actual key) is present in your `.env` file.
*   **Load environment variables:** Make sure your shell loads the `.env` file. If not using a tool like `direnv`, you might need to manually source it: `source .env`.
*   **Validate the key:** Double-check that the API key itself is correct and has the necessary permissions in Google AI Studio.

### Prompt File Not Found

If you use the `--file` flag and the command reports that the file was not found:

*   **Verify path:** Ensure the file path you provided is correct and that the file exists at that location relative to where you are running the command.
*   **Current Directory:** Confirm you are running the command from the correct directory or provide an absolute path to the prompt file.

### Common Errors

*   **Network Issues:** If you experience connection timeouts or failures, check your internet connection and ensure that Google's Gemini API endpoints are accessible from your network.
*   **Model Rate Limits:** If you make too many requests in a short period, you might hit API rate limits. The command should ideally handle retries, but if issues persist, pause and try again later. Refer to Google Gemini API documentation for current rate limits.
*   **Invalid Arguments:** If you encounter errors about invalid options or values, review the `--help` output of `llm-gemini-query` to ensure you are using the correct flags and value formats (e.g., temperature range).
---

docs/refactoring_api_credentials.md:
# API Credentials Refactoring

## Overview

The `APICredentials` class has been refactored to be more generic and reusable. Previously, it had hardcoded knowledge about Gemini API, but now it's a generic credential manager that can be used for any API service.

## Changes Made

### 1. Removed Service-Specific Constants

**Before:**
```ruby
class APICredentials
  # Default environment variable name for Gemini API key
  DEFAULT_GEMINI_KEY_NAME = "GEMINI_API_KEY"
  
  def initialize(env_key_name: DEFAULT_GEMINI_KEY_NAME, env_file_path: nil)
    # ...
  end
end
```

**After:**
```ruby
class APICredentials
  def initialize(env_key_name: nil, env_file_path: nil)
    # ...
  end
end
```

### 2. Made `env_key_name` Optional with Runtime Validation

The `env_key_name` parameter is now optional during initialization, but required when accessing the API key:

```ruby
def api_key
  raise KeyError, "env_key_name not set. Please provide it during initialization." if @env_key_name.nil?
  # ... rest of the logic
end
```

### 3. Moved Service-Specific Configuration to Service Classes

The Gemini-specific configuration is now owned by `GeminiClient`:

```ruby
class GeminiClient
  # Default environment variable name for Gemini API key
  DEFAULT_API_KEY_ENV = "GEMINI_API_KEY"
  
  def initialize(api_key: nil, model: DEFAULT_MODEL, **options)
    @credentials = Molecules::APICredentials.new(
      env_key_name: options.fetch(:api_key_env, DEFAULT_API_KEY_ENV)
    )
    # ...
  end
end
```

## Benefits

1. **Reusability**: `APICredentials` can now be used for any API service, not just Gemini
2. **Separation of Concerns**: Service-specific details are kept in service-specific classes
3. **Flexibility**: Each service can specify its own environment variable naming convention
4. **Backward Compatibility**: The optional `env_key_name` parameter maintains compatibility with existing code

## Usage Examples

### Generic API Credentials

```ruby
# For different services
github_creds = APICredentials.new(env_key_name: "GITHUB_TOKEN")
stripe_creds = APICredentials.new(env_key_name: "STRIPE_API_KEY")
custom_creds = APICredentials.new(env_key_name: "MY_SERVICE_KEY")

# Check if keys are available
if github_creds.api_key_present?
  token = github_creds.api_key_with_prefix("token ")
end
```

### With GeminiClient

```ruby
# Uses default GEMINI_API_KEY environment variable
client = GeminiClient.new

# Or with custom environment variable
client = GeminiClient.new(api_key_env: "MY_GEMINI_KEY")
```

### Error Handling

```ruby
# Without env_key_name
creds = APICredentials.new
creds.api_key # => KeyError: env_key_name not set. Please provide it during initialization.

# With env_key_name but missing environment variable
creds = APICredentials.new(env_key_name: "MISSING_KEY")
creds.api_key # => KeyError: API key not found. Please set MISSING_KEY environment variable...
```

## Migration Guide

If you were using `APICredentials` directly without specifying `env_key_name`:

**Before:**
```ruby
credentials = APICredentials.new  # Used GEMINI_API_KEY by default
```

**After:**
```ruby
credentials = APICredentials.new(env_key_name: "GEMINI_API_KEY")
```

If you were using `GeminiClient`, no changes are needed as it handles the configuration internally.

## LM Studio Credentials Handling

LM Studio has been updated to make credentials completely optional since localhost connections typically don't require authentication:

### Before (Required APICredentials)
```ruby
class LMStudioClient
  def initialize(model: DEFAULT_MODEL, **options)
    @credentials = Molecules::APICredentials.new(
      env_key_name: options.fetch(:api_key_env, "LM_STUDIO_API_KEY")
    )
    @api_key = @credentials.api_key if @credentials.api_key_present?
  rescue KeyError
    @api_key = nil
  end
end
```

### After (Optional APICredentials)
```ruby
class LMStudioClient
  def initialize(model: DEFAULT_MODEL, **options)
    # Allow optional API key via options or environment variable
    @api_key = options[:api_key] || ENV[options.fetch(:api_key_env, "LM_STUDIO_API_KEY")]
  end
end
```

### Benefits for LM Studio
1. **Simplified Setup**: No APICredentials dependency for localhost usage
2. **Backward Compatibility**: Still accepts API keys if provided
3. **Reduced Complexity**: Eliminates unnecessary exception handling for local development
4. **Better Developer Experience**: Works out-of-the-box without credential setup

## Design Principles

This refactoring follows the SOLID principles:

1. **Single Responsibility**: `APICredentials` now has one job - manage API credentials generically
2. **Open/Closed**: The class is open for extension (can be used with any API) but closed for modification
3. **Dependency Inversion**: High-level modules (organisms) don't depend on low-level details (specific env var names)

The refactoring also maintains the atomic/molecular/organism hierarchy where:
- **Atoms** (EnvReader): Basic environment variable reading
- **Molecules** (APICredentials): Generic credential management
- **Organisms** (GeminiClient, LMStudioClient): Service-specific implementation with their own configuration
---

docs/testing-with-vcr.md:
# Testing with VCR (Video Cassette Recorder)

This project uses VCR to record and replay HTTP interactions with external APIs, particularly the Google Gemini API. This allows tests to run consistently without making actual API calls during regular test runs.

## Overview

VCR works by:
1. **Recording**: Capturing real HTTP requests and responses during the first test run
2. **Replaying**: Using the recorded interactions for subsequent test runs
3. **Filtering**: Removing sensitive data like API keys from recordings

Our VCR configuration is **CI-aware**, meaning it automatically behaves differently in development vs CI environments:

- **Development**: Automatically records missing cassettes, replays existing ones
- **CI**: Only uses existing cassettes, never makes external API calls

## Quick Start

### Running Tests

```bash
# Run all tests (uses existing cassettes, records missing ones in development)
bin/test

# Run integration tests specifically
bin/test spec/integration/

# Run with debug output
TEST_DEBUG=true bin/test spec/integration/
```

### Recording New Cassettes

1. **Set up your API key** (one-time setup):
   ```bash
   cp spec/.env.example spec/.env
   # Edit spec/.env and add: GEMINI_API_KEY=your_actual_api_key_here
   ```

2. **Write your test** with the `:vcr` tag:
   ```ruby
   it "queries Gemini API", :vcr do
     # Your test code that makes API calls
   end
   ```

3. **Run the test** - VCR automatically records missing cassettes:
   ```bash
   bin/test spec/integration/your_test_file.rb
   ```

4. **Commit the cassette**:
   ```bash
   git add spec/cassettes/
   git commit -m "Add VCR cassette for new test"
   ```

## Configuration

### Automatic CI Detection

VCR is configured to detect CI environments automatically:

```ruby
# In spec/support/vcr.rb
recording_mode = if ENV['CI']
                   :none  # Never record in CI
                 else
                   :once  # Auto-record missing cassettes in development
                 end
```

### Manual Control

You can override the automatic behavior with environment variables:

```bash
# Force re-record all cassettes (overwrites existing)
VCR_RECORD=true bin/test spec/integration/

# Record only missing cassettes
VCR_RECORD=new_episodes bin/test spec/integration/

# Use only existing cassettes (fail if missing)
VCR_RECORD=none bin/test spec/integration/

# Simulate CI environment
CI=true bin/test spec/integration/
```

## Setup Details

### Environment Configuration

VCR is already configured in the project:
- `spec/support/vcr.rb` - Main VCR configuration with CI-aware recording
- `spec/support/env_helper.rb` - Smart API key management
- `spec/spec_helper.rb` - Loads VCR support
- `spec/cassettes/` - Directory where recordings are stored

### API Key Setup (Development Only)

1. **Get a Google AI API key**:
   - Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Create a new API key for testing
   - **Important**: Use a separate key for testing, not your production key

2. **Configure locally**:
   ```bash
   # Copy environment template
   cp spec/.env.example spec/.env
   
   # Edit spec/.env and add your key:
   echo "GEMINI_API_KEY=your_actual_api_key_here" >> spec/.env
   ```

**Note**: The helper picks up both `spec/.env` and repo-root `.env` files. API keys are only needed for recording new cassettes. Normal test runs and CI use pre-recorded cassettes without requiring any API keys.

## Writing Tests

### Basic VCR Test

```ruby
RSpec.describe "API Integration" do
  # Use the environment helper for consistent API key handling
  let(:api_key) { EnvHelper.gemini_api_key }

  it "queries Gemini with a simple prompt", :vcr do
    output, error, status = Open3.capture3(
      { "GEMINI_API_KEY" => api_key },
      exe_path,
      "What is 2+2? Reply with just the number."
    )

    expect(status).to be_success
    expect(output.strip).to match(/4/)
  end
end
```

### Custom Cassette Names

By default, cassettes are named after test descriptions. You can specify custom names:

```ruby
it "custom test", vcr: "my_custom_cassette_name" do
  # test code
end
```

### Custom VCR Options

```ruby
it "test with custom options", vcr_options: { match_requests_on: [:method, :uri] } do
  # test code
end
```

## Recording Scenarios

### Adding New Tests

1. Write test with `:vcr` tag
2. Run test - VCR automatically records missing cassettes
3. Commit cassette file

### Updating API Responses

1. Delete specific cassette file:
   ```bash
   rm spec/cassettes/path/to/specific_cassette.yml
   ```

2. Run test - VCR automatically re-records:
   ```bash
   bin/test spec/integration/your_test.rb
   ```

### Major API Changes

1. Remove all cassettes and re-record:
   ```bash
   rm -rf spec/cassettes/
   VCR_RECORD=true bin/test spec/integration/
   ```

2. Review all changes and commit:
   ```bash
   git diff spec/cassettes/
   git add spec/cassettes/
   git commit -m "Update VCR cassettes for API changes"
   ```

## Security Features

### Automatic Data Filtering

VCR automatically removes sensitive data from cassettes:

```ruby
# API keys in headers (X-Goog-Api-Key)
config.filter_sensitive_data('<GEMINI_API_KEY>') do |interaction|
  interaction.request.headers['X-Goog-Api-Key']&.first
end

# API keys in query parameters (?key=abc123)
config.filter_sensitive_data('<GEMINI_API_KEY>') do |interaction|
  # Extracts and filters API keys from URLs
end

# Authorization headers
config.filter_sensitive_data('<AUTHORIZATION>') do |interaction|
  interaction.request.headers['Authorization']&.first
end
```

### Safe Defaults

- **CI Environment**: Always uses test keys, never makes API calls
- **Development**: Uses test keys unless real key is explicitly provided
- **Git Integration**: Real API keys are gitignored, cassettes are committed with filtered data

## File Structure

```
spec/
├── .env.example          # Template for environment variables
├── .env                  # Your actual config (gitignored)
├── cassettes/            # VCR recordings (committed to repository)
│   └── llm-gemini-query_integration/
│       ├── API_integration/
│       │   ├── with_valid_API_key/
│       │   │   ├── queries_Gemini_with_a_simple_prompt.yml
│       │   │   └── outputs_JSON_format_when_requested.yml
│       │   └── with_invalid_API_key/
│       └── command_execution/
├── integration/
│   └── llm_gemini_query_integration_spec.rb
└── support/
    ├── vcr.rb           # CI-aware VCR configuration
    └── env_helper.rb    # Smart environment management
```

## CI/CD Integration

### GitHub Actions

```yaml
# In .github/workflows/test.yml
- name: Run tests with VCR
  run: bin/test spec/integration/
  env:
    CI: true  # VCR automatically uses cassettes-only mode
    # No GEMINI_API_KEY needed - uses recorded cassettes
```

### What Happens in CI

1. **No API Keys Required**: CI runs entirely from pre-recorded cassettes
2. **Fast Execution**: No external API calls mean faster test runs
3. **Deterministic Results**: No network issues or rate limits
4. **Automatic Detection**: CI platforms set `CI=true` by default

## Troubleshooting

### Common Issues

1. **"No cassette found" errors**:
   ```bash
   # Record the missing cassette
   bin/test spec/path/to/failing_test.rb
   ```

2. **API key required for recording**:
   ```bash
   # Set up your API key in spec/.env
   echo "GEMINI_API_KEY=your_key_here" >> spec/.env
   ```

3. **Request mismatches**:
   - VCR matches on method, URI, headers, and body
   - Small changes in requests may require re-recording
   - Check cassette names match test descriptions

### Debugging VCR

Enable debug logging:

```bash
# Enable VCR debug output
TEST_DEBUG=true bin/test spec/integration/

# View debug log
cat vcr_debug.log
```

Check cassette contents:

```bash
# List all cassettes
find spec/cassettes -name "*.yml" -type f

# View specific cassette
cat spec/cassettes/your_test_cassette.yml

# Check for API key leaks (should show <GEMINI_API_KEY>)
grep -r "GEMINI_API_KEY" spec/cassettes/
```

### Verifying Security

Always check that sensitive data is filtered:

```bash
# These should NOT appear in cassettes:
grep -r "your_actual_api_key" spec/cassettes/  # Should be empty
grep -r "AIza" spec/cassettes/                 # Should be empty (Google API key prefix)

# These SHOULD appear (filtered placeholders):
grep -r "<GEMINI_API_KEY>" spec/cassettes/     # Should show filtered keys
```

## Best Practices

### Development Workflow

1. **Let VCR auto-record** - it handles missing cassettes automatically
2. **Use `VCR_RECORD=true` sparingly** - only when you need to overwrite existing cassettes
3. **Review cassettes before committing** to ensure no sensitive data leaked
4. **Use descriptive test names** - they become cassette filenames
5. **Keep tests focused** - one API interaction per test when possible

### Security Guidelines

1. **Never commit real API keys** to the repository
2. **Use dedicated test API keys** separate from production
3. **Rotate test keys regularly** and use minimal permissions
4. **Always verify filtering worked** before committing cassettes
5. **Set up git hooks** to prevent accidental key commits

### CI/CD Guidelines

1. **No API keys in CI** - rely on pre-recorded cassettes
2. **Include cassettes in repository** - don't generate them in CI
3. **Monitor for missing cassettes** in CI failures
4. **Keep cassettes up to date** with API changes

## Environment Variables Reference

| Variable | Values | Description |
|----------|--------|-------------|
| `CI` | `true`/unset | Automatically set by CI platforms, switches VCR to cassettes-only mode |
| `VCR_RECORD` | `true`, `new_episodes`, `none` | Override default recording behavior |
| `TEST_DEBUG` | `true`/unset | Enable detailed VCR logging and debug output |
| `GEMINI_API_KEY` | Your API key | Required for recording new cassettes (development only) |

## Quick Reference Commands

```bash
# Normal development
bin/test spec/integration/                    # Run tests (auto-records missing)

# Explicit recording control  
VCR_RECORD=true bin/test spec/integration/    # Re-record all cassettes
VCR_RECORD=new_episodes bin/test spec/        # Record only missing
VCR_RECORD=none bin/test spec/integration/    # Cassettes only (fail if missing)

# Debug and troubleshooting
TEST_DEBUG=true bin/test spec/integration/    # Enable debug output
CI=true bin/test spec/integration/            # Simulate CI environment

# Cassette management
find spec/cassettes -name "*.yml" -type f     # List all cassettes
rm -rf spec/cassettes/                        # Remove all cassettes
rm spec/cassettes/path/to/specific.yml        # Remove specific cassette
```

This CI-aware VCR configuration provides a seamless testing experience that automatically adapts to your environment while maintaining security and reliability.
---

## Your Comprehensive Analysis Task

### Phase 1: Deep Diff Analysis

Analyze the diff and categorize every change:

**1. New Features Added**
- What new functionality was introduced?
- What new APIs or interfaces were created?
- What new configuration options were added?

**2. Existing Features Modified**
- What existing functionality changed behavior?
- What APIs had signature changes?
- What configuration options were modified?

**3. Architecture & Design Changes**
- What structural patterns were introduced or modified?
- What design decisions were made?
- What trade-offs were considered?

**4. Breaking Changes**
- What changes might break existing user workflows?
- What deprecated functionality was removed?
- What API changes are not backward compatible?

**5. Dependencies & Infrastructure**
- What external dependencies were added/removed/updated?
- What build or deployment configuration changed?
- What environment variables or settings changed?

**6. Internal Refactoring**
- What code organization changes occurred?
- What performance optimizations were made?
- What technical debt was addressed?

### Phase 2: Architectural Decision Documentation

For each significant change identified, determine:

**New ADRs Needed:**
- What architectural decisions were made during implementation?
- What alternatives were considered and rejected?
- What constraints or requirements drove these decisions?
- What are the long-term implications?

**Existing ADRs to Update:**
- What previously documented decisions need revision?
- What assumptions are no longer valid?
- What decisions need additional context or clarification?

### Phase 3: Documentation Impact Assessment

Systematically assess each documentation category:

#### Architecture Decision Records (`docs-project/decisions/`)
- [ ] **New ADR Required**: [Topic] - [Reason for documentation]
- [ ] **Update Existing ADR**: [File] - [Specific changes needed]

#### Project Documentation (`docs-project/*.md`)
- [ ] **architecture.md**: [Specific sections needing updates]
- [ ] **blueprint.md**: [Specific sections needing updates]
- [ ] **what-do-we-build.md**: [Specific sections needing updates]

#### Root Documentation (`*.md`)
- [ ] **README.md**: [Specific sections needing updates]
- [ ] **CHANGELOG.md**: [Version entry and changes to document]
- [ ] **Other files**: [Specify files and required changes]

#### Technical Documentation (`docs/**/*.md`)
- [ ] **SETUP.md**: [Installation/setup changes needed]
- [ ] **DEVELOPMENT.md**: [Development workflow changes needed]
- [ ] **Other guides**: [Specify files and required changes]

### Phase 4: Comprehensive Update Requirements

Consider and document all additional updates needed:

**Code Examples & Snippets**
- Do existing code examples in documentation still work?
- Do new features need usage examples?
- Are there outdated API usage patterns?

**CLI Documentation**
- Do command-line help texts need updates?
- Are there new CLI flags or options to document?
- Do existing CLI examples still work?

**Configuration Documentation**
- Do environment variable examples need updates?
- Are there new configuration options to document?
- Do configuration file templates need updates?

**Integration Guides**
- Do third-party integration instructions need updates?
- Are there new integration possibilities to document?
- Do existing integration examples still work?

**Migration Guides**
- Do breaking changes need migration documentation?
- Are there upgrade paths to document?
- Do users need specific migration steps?

### Phase 5: Create Prioritized Action Plan

Organize all identified updates by priority:

## 🔴 CRITICAL UPDATES (Must be done immediately)
*These affect user safety, security, or basic functionality*
- [ ] [Specific update with file path and detailed rationale]

## 🟡 HIGH PRIORITY UPDATES (Should be done soon)
*These affect user experience or developer onboarding*
- [ ] [Specific update with file path and detailed rationale]

## 🟢 MEDIUM PRIORITY UPDATES (Should be done eventually)
*These improve clarity, completeness, or maintainability*
- [ ] [Specific update with file path and detailed rationale]

## 🔵 LOW PRIORITY UPDATES (Nice to have)
*These address minor inconsistencies or optimizations*
- [ ] [Specific update with file path and detailed rationale]

### Phase 6: Detailed Implementation Specifications

For each update identified, provide:

#### [File Path/Name]
- **Section to Update**: [Specific section heading or line numbers]
- **Current Content**: [Quote relevant current content if significant changes]
- **Required Changes**: [Exactly what needs to be changed]
- **New Content Suggestions**: [Proposed new text or examples]
- **Rationale**: [Why this change is needed based on the diff]
- **Dependencies**: [What other updates this depends on]
- **Cross-references**: [What other documents reference this content]

### Phase 7: Quality Assurance Checklist

Ensure your recommendations address:

**Completeness**
- [ ] All diff changes have corresponding documentation updates
- [ ] All new features have usage examples
- [ ] All breaking changes are clearly documented
- [ ] All deprecated functionality is marked with migration paths

**Accuracy**
- [ ] All code examples are syntactically correct
- [ ] All CLI examples use correct syntax
- [ ] All links and references are functional
- [ ] All version numbers and dates are correct

**Consistency**
- [ ] Documentation style matches project guidelines
- [ ] Terminology is consistent across all documents
- [ ] Cross-references between documents are updated
- [ ] Formatting follows established patterns

**User Experience**
- [ ] Changes are explained from user perspective
- [ ] Migration paths are clear and actionable
- [ ] Examples are practical and realistic
- [ ] Documentation remains accessible to target audience

## Expected Output Format

Structure your comprehensive response as:

```markdown
# Comprehensive Documentation Review Analysis

## Executive Summary
[2-3 sentence overview of changes and their documentation impact]

## Detailed Diff Analysis
### New Features
[Detailed list with implications]

### Modified Features  
[Detailed list with implications]

### Architecture Changes
[Detailed list with implications]

### Breaking Changes
[Detailed list with user impact]

### Dependencies & Infrastructure
[Detailed list with setup implications]

## Architecture Decision Records Required
### New ADRs Needed
[List with detailed rationale for each]

### Existing ADRs to Update
[List with specific changes needed]

## Comprehensive Documentation Update Plan
[Use the 4-tier priority system from Phase 5]

## Detailed Implementation Specifications
[Use the format from Phase 6 for each identified update]

## Cross-Reference Update Map
[List all internal links and references that need updating]

## Quality Assurance Validation
[Completed checklist from Phase 7]

## Risk Assessment
[Potential issues if documentation updates are not completed]

## Implementation Timeline Recommendation
[Suggested order and timing for implementing updates]

## Additional Recommendations
[Any other considerations, tools, or processes that would help]
```

## Critical Success Factors

Your analysis must be:
1. **Exhaustive**: Miss nothing that could affect users or developers
2. **Specific**: Provide exact file paths, section names, and change descriptions
3. **Prioritized**: Clear ranking of importance and urgency
4. **Actionable**: Every recommendation should be implementable
5. **User-focused**: Consider impact on actual users and their workflows

Begin your comprehensive analysis now.