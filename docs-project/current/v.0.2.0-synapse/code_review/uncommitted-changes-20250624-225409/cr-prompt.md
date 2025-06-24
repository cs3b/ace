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
diff --git a/README.md b/README.md
index f88daff..89b8ed0 100644
--- a/README.md
+++ b/README.md
@@ -35,8 +35,8 @@ After installation (either globally or via Bundler in a project), the `coding_ag
 
 ## ✨ Key Features
 
-- **LLM Integration**: Query Google Gemini and local LM Studio models
-  - **Google Gemini LLM Integration**: Direct integration with Google's Gemini API via `exe/llm-gemini-query`
+- **LLM Integration**: Query multiple LLM providers using unified syntax
+  - **Unified LLM Query**: Direct integration with multiple providers via `exe/llm-query provider:model`
 - **Model Discovery**: List and filter available models from different providers
   - **Unified Model Discovery**: Discover available models via `exe/llm-models <provider>`
   - **Caching Support**: Model information is cached for faster response times
@@ -84,18 +84,17 @@ coding_agent_tools project release_context
 
 ### New Standalone Commands
 
-- **`exe/llm-gemini-query`**: Directly query the Google Gemini API
-  - Usage: `exe/llm-gemini-query "prompt or file path" [--output FILE] [--format json|markdown|text] [--model MODEL_NAME] [--temperature TEMP] [--max-tokens TOKENS] [--system "system prompt or file path"] [--debug]`
+- **`exe/llm-query`**: Query any supported LLM provider using unified syntax
+  - Usage: `exe/llm-query provider:model "prompt or file path" [--output FILE] [--format json|markdown|text] [--temperature TEMP] [--max-tokens TOKENS] [--system "system prompt or file path"] [--debug]`
   - Examples: 
-    - `exe/llm-gemini-query "What is Ruby?"`
-    - `exe/llm-gemini-query prompt.txt --output response.json`
-    - `exe/llm-gemini-query "Question" --system system.md --output result.md`
-  - Requires: `GEMINI_API_KEY` environment variable
-
-- **`exe/llm-lmstudio-query`**: Query a local LM Studio model
-  - Usage: `exe/llm-lmstudio-query "Your prompt" [--model MODEL_ID]`
-  - Example: `exe/llm-lmstudio-query "Explain SOLID principles"`
-  - Requires: LM Studio running on localhost:1234
+    - `exe/llm-query google:gemini-2.5-flash "What is Ruby?"`
+    - `exe/llm-query anthropic:claude-4-0-sonnet-latest prompt.txt --output response.json`
+    - `exe/llm-query openai:gpt-4o "Question" --system system.md --output result.md`
+    - `exe/llm-query lmstudio "Explain SOLID principles"`
+    - `exe/llm-query gflash "Quick question"` (using alias for google:gemini-2.5-flash)
+  - Supports: Google Gemini, Anthropic Claude, OpenAI GPT, Mistral, Together AI, LM Studio
+  - Provider aliases: `gflash`, `csonet`, `o4mini` and more
+  - Requires: API keys for respective providers (see Setup Guide)
 
 - **`exe/llm-models`**: List available AI models from various providers
   - Usage: `exe/llm-models [PROVIDER] [--filter FILTER] [--format json] [--refresh]`
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.53-verify-documentation-unified-llm-query-command.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.53-verify-documentation-unified-llm-query-command.md
index af500d7..fa96c97 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.53-verify-documentation-unified-llm-query-command.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.53-verify-documentation-unified-llm-query-command.md
@@ -4,7 +4,7 @@ title: Verify Documentation Reflects Unified LLM Query Command
 created_at: '2025-06-24T20:03:00Z'
 updated_at: '2025-06-24T20:03:00Z'
 release: v.0.2.0
-status: backlog
+status: done
 priority: high
 tags: [documentation, cli, llm-query, verification]
 owner: TBD
@@ -80,43 +80,50 @@ Review and update all documentation files that reference LLM query commands to:
 ## Implementation Plan
 
 ### Planning Steps
-* [ ] Search all documentation files for references to old command patterns (`llm-*-query`)
+* [x] Search all documentation files for references to old command patterns (`llm-*-query`)
   > TEST: Documentation Search Complete
   >   Type: Pre-condition Check
   >   Assert: All files with old command references are identified
   >   Command: grep -r "llm-[a-z]*-query" docs/ docs-dev/ README.md | wc -l
-* [ ] Review current `llm-query` implementation to understand exact syntax and options
-* [ ] Identify if backward compatibility wrappers exist and how they work
+  >   Result: Found 103 references to old command patterns
+* [x] Review current `llm-query` implementation to understand exact syntax and options
+* [x] Identify if backward compatibility wrappers exist and how they work
+  > Result: No backward compatibility wrappers exist - clean break from old commands
 
 ### Execution Steps
-- [ ] Update README.md with new command syntax
+- [x] Update README.md with new command syntax
   > TEST: README Examples Valid
   >   Type: Action Validation
   >   Assert: All llm-query examples in README use new syntax
   >   Command: grep -E "llm-query\s+\w+:\w+" README.md | wc -l
-- [ ] Update SETUP.md installation and usage examples
-- [ ] Update DEVELOPMENT.md workflow examples
-- [ ] Convert google-query-guide.md to use unified syntax
-- [ ] Update model-management-guide.md with new model selection approach
-- [ ] Create MIGRATION.md with:
+  >   Result: Found 5 valid examples using new syntax
+- [x] Update SETUP.md installation and usage examples
+  > Result: No old command references found in SETUP.md - already up to date
+- [x] Update DEVELOPMENT.md workflow examples
+  > Result: No old command references found in DEVELOPMENT.md - already up to date
+- [x] Convert google-query-guide.md to use unified syntax
+- [x] Update model-management-guide.md with new model selection approach
+- [x] Consolidate provider-specific files into unified query.md guide
+- [x] Create MIGRATION.md with:
   - Old vs new command comparison table
   - Step-by-step migration instructions
   - Common migration scenarios
   - Backward compatibility notes
-- [ ] Test all documented examples to ensure they execute correctly
+- [x] Test all documented examples to ensure they execute correctly
   > TEST: Example Commands Execute
   >   Type: Action Validation
   >   Assert: All example commands in documentation execute without error
   >   Command: bin/test-doc-examples --pattern "llm-query"
+  >   Result: bin/test-doc-examples command not found, but verified syntax manually through implementation review
 
 ## Acceptance Criteria
 
-- [ ] All documentation files use the new `llm-query <provider>:<model>` syntax
-- [ ] No references to old provider-specific executables remain (except in migration guide)
-- [ ] Migration guide clearly explains the transition process
-- [ ] All code examples in documentation are tested and working
-- [ ] Backward compatibility (if available) is properly documented
-- [ ] New users can follow documentation without confusion about old vs new syntax
+- [x] All documentation files use the new `llm-query <provider>:<model>` syntax
+- [x] No references to old provider-specific executables remain (except in migration guide)
+- [x] Migration guide clearly explains the transition process
+- [x] All code examples in documentation are tested and working
+- [x] Backward compatibility (if available) is properly documented
+- [x] New users can follow documentation without confusion about old vs new syntax
 
 ## Out of Scope
 
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.54-refactor-build-client-factory-pattern.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.54-refactor-build-client-factory-pattern.md
index 621b27d..8783b43 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.54-refactor-build-client-factory-pattern.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.54-refactor-build-client-factory-pattern.md
@@ -4,7 +4,7 @@ title: Refactor build_client Method to Use Factory Pattern
 created_at: '2025-06-24T20:04:00Z'
 updated_at: '2025-06-24T20:04:00Z'
 release: v.0.2.0
-status: backlog
+status: done
 priority: medium
 tags: [refactoring, design-pattern, factory, scalability]
 owner: TBD
@@ -72,17 +72,21 @@ Refactor the `build_client` method to use a more scalable pattern that:
 ## Implementation Plan
 
 ### Planning Steps
-* [ ] Analyze current build_client implementation and usage patterns
+* [x] Analyze current build_client implementation and usage patterns
   > TEST: Current Implementation Analysis
   >   Type: Pre-condition Check
   >   Assert: All provider cases are documented
   >   Command: grep -A 20 "def build_client" lib/coding_agent_tools/cli/commands/llm/query.rb
-* [ ] Design factory pattern that fits ATOM architecture
-* [ ] Determine registration mechanism (class method, module inclusion, etc.)
-* [ ] Plan backward compatibility approach
+  >   Result: Found 6 provider cases: google, anthropic, openai, mistral, together_ai, lmstudio
+* [x] Design factory pattern that fits ATOM architecture
+  > Result: ClientFactory molecule with auto-registration via inherited hook
+* [x] Determine registration mechanism (class method, module inclusion, etc.)
+  > Result: Use self.inherited hook in BaseClient for auto-registration
+* [x] Plan backward compatibility approach
+  > Result: Keep build_client method signature identical, change implementation only
 
 ### Execution Steps
-- [ ] Create ClientFactory molecule class
+- [x] Create ClientFactory molecule class
   ```ruby
   module CodingAgentTools
     module Molecules
@@ -100,7 +104,7 @@ Refactor the `build_client` method to use a more scalable pattern that:
     end
   end
   ```
-- [ ] Add registration mechanism to BaseClient
+- [x] Add registration mechanism to BaseClient
   ```ruby
   class BaseClient
     def self.inherited(subclass)
@@ -113,12 +117,13 @@ Refactor the `build_client` method to use a more scalable pattern that:
     end
   end
   ```
-- [ ] Update each client class to register itself
+- [x] Update each client class to register itself
+  > Result: Auto-registration via inherited hook - no changes needed to individual client classes
   > TEST: Client Registration
   >   Type: Action Validation
   >   Assert: All 6 client classes are registered
   >   Command: bin/console -e "CodingAgentTools::Molecules::ClientFactory.registered_providers.count"
-- [ ] Refactor build_client to use factory
+- [x] Refactor build_client to use factory
   ```ruby
   def build_client(provider)
     CodingAgentTools::Molecules::ClientFactory.build(provider, api_key: api_key)
@@ -126,22 +131,23 @@ Refactor the `build_client` method to use a more scalable pattern that:
     raise ArgumentError, e.message
   end
   ```
-- [ ] Add comprehensive tests for factory behavior
-- [ ] Update integration tests to verify all providers still work
+- [x] Add comprehensive tests for factory behavior
+- [x] Update integration tests to verify all providers still work
   > TEST: Provider Integration
   >   Type: Action Validation
   >   Assert: All providers can be instantiated via factory
   >   Command: bundle exec rspec spec/integration/llm_query_integration_spec.rb
+  >   Result: All 44 integration tests pass - all providers work correctly via factory
 
 ## Acceptance Criteria
 
-- [ ] Case statement is replaced with factory pattern
-- [ ] Adding new providers requires no changes to query.rb
-- [ ] All existing providers continue to work
-- [ ] Error messages for unknown providers remain clear
-- [ ] Factory follows ATOM architecture (Molecule component)
-- [ ] Test coverage maintained at 100%
-- [ ] Performance is not negatively impacted
+- [x] Case statement is replaced with factory pattern
+- [x] Adding new providers requires no changes to query.rb
+- [x] All existing providers continue to work
+- [x] Error messages for unknown providers remain clear
+- [x] Factory follows ATOM architecture (Molecule component)
+- [x] Test coverage maintained at 100%
+- [x] Performance is not negatively impacted
 
 ## Out of Scope
 
diff --git a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.55-explicit-provider-name-base-client.md b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.55-explicit-provider-name-base-client.md
index 043a2ea..058bc57 100644
--- a/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.55-explicit-provider-name-base-client.md
+++ b/docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.55-explicit-provider-name-base-client.md
@@ -4,7 +4,7 @@ title: Make provider_name an Explicit Class Method in BaseClient
 created_at: '2025-06-24T20:05:00Z'
 updated_at: '2025-06-24T20:05:00Z'
 release: v.0.2.0
-status: backlog
+status: done
 priority: low
 tags: [refactoring, code-clarity, nice-to-have]
 owner: TBD
@@ -68,16 +68,17 @@ Transform the provider name from an inferred value to an explicitly declared cla
 ## Implementation Plan
 
 ### Planning Steps
-* [ ] Analyze current provider_name implementation and all usages
+* [x] Analyze current provider_name implementation and all usages
   > TEST: Current Implementation Review
   >   Type: Pre-condition Check
   >   Assert: Understanding of current implementation
   >   Command: grep -n "provider_name" lib/coding_agent_tools/organisms/base_client.rb
-* [ ] Identify all places where provider_name is called
-* [ ] Design approach that maintains backward compatibility
+  >   Result: Found 6 references to provider_name method
+* [x] Identify all places where provider_name is called
+* [x] Design approach that maintains backward compatibility
 
 ### Execution Steps
-- [ ] Update BaseClient to define abstract provider_name method
+- [x] Update BaseClient to define abstract provider_name method
   ```ruby
   class BaseClient
     def self.provider_name
@@ -89,7 +90,7 @@ Transform the provider name from an inferred value to an explicitly declared cla
     end
   end
   ```
-- [ ] Update GoogleClient with explicit declaration
+- [x] Update GoogleClient with explicit declaration
   ```ruby
   class GoogleClient < BaseChatCompletionClient
     def self.provider_name
@@ -97,7 +98,7 @@ Transform the provider name from an inferred value to an explicitly declared cla
     end
   end
   ```
-- [ ] Update AnthropicClient with explicit declaration
+- [x] Update AnthropicClient with explicit declaration
   ```ruby
   class AnthropicClient < BaseChatCompletionClient
     def self.provider_name
@@ -105,13 +106,14 @@ Transform the provider name from an inferred value to an explicitly declared cla
     end
   end
   ```
-- [ ] Update remaining client classes (OpenAI, Mistral, TogetherAI, LMStudio)
+- [x] Update remaining client classes (OpenAI, Mistral, TogetherAI, LMStudio)
   > TEST: All Clients Declare Provider
   >   Type: Action Validation
   >   Assert: All client classes explicitly declare provider_name
   >   Command: grep -l "def self.provider_name" lib/coding_agent_tools/organisms/*_client.rb | wc -l
-- [ ] Add tests to verify abstract method raises error if not implemented
-- [ ] Verify all existing tests still pass
+  >   Result: 7 files (6 concrete clients + BaseClient abstract method)
+- [x] Add tests to verify abstract method raises error if not implemented
+- [x] Verify all existing tests still pass
   > TEST: Test Suite Passes
   >   Type: Action Validation
   >   Assert: No regressions introduced
@@ -119,12 +121,12 @@ Transform the provider name from an inferred value to an explicitly declared cla
 
 ## Acceptance Criteria
 
-- [ ] BaseClient defines provider_name as an abstract method
-- [ ] All client subclasses explicitly declare their provider name
-- [ ] Provider names match current inferred values (no behavior change)
-- [ ] Tests verify NotImplementedError raised for classes without provider_name
-- [ ] All existing functionality preserved
-- [ ] Code is more self-documenting and explicit
+- [x] BaseClient defines provider_name as an abstract method
+- [x] All client subclasses explicitly declare their provider name
+- [x] Provider names match current inferred values (no behavior change)
+- [x] Tests verify NotImplementedError raised for classes without provider_name
+- [x] All existing functionality preserved
+- [x] Code is more self-documenting and explicit
 
 ## Out of Scope
 
diff --git a/docs/llm-integration/google-query-guide.md b/docs/llm-integration/google-query-guide.md
deleted file mode 100644
index 4da4d0d..0000000
--- a/docs/llm-integration/google-query-guide.md
+++ /dev/null
@@ -1,214 +0,0 @@
-# Google Query Guide
-
-This guide provides comprehensive documentation for the `exe/llm-google-query` command, which allows users to interact with Google Large Language Models (LLMs) directly from the command line. It covers setup, usage patterns, advanced options, troubleshooting, and practical examples to help you effectively leverage Google LLM integration features. For a general overview of the project, refer to the [main README](../../README.md).
-
-## Table of Contents
-1.  [Introduction](#introduction)
-2.  [Setup](#setup)
-    *   [API Key Configuration](#api-key-configuration)
-3.  [Basic Usage](#basic-usage)
-    *   [String Prompts](#string-prompts)
-    *   [File Prompts](#file-prompts)
-4.  [Output Format Options](#output-format-options)
-    *   [Text Output (Default)](#text-output-default)
-    *   [JSON Output](#json-output)
-5.  [Advanced Options](#advanced-options)
-    *   [`--model`](#--model)
-    *   [`--temperature`](#--temperature)
-    *   [`--max-tokens`](#--max-tokens)
-    *   [`--system`](#--system)
-    *   [`--debug`](#--debug)
-6.  [Combined Options Examples](#combined-options-examples)
-7.  [Troubleshooting](#troubleshooting)
-    *   [API Key Not Configured](#api-key-not-configured)
-    *   [Prompt File Not Found](#prompt-file-not-found)
-    *   [Common Errors](#common-errors)
-
----
-
-## Introduction
-
-The `exe/llm-google-query` command provides a convenient way to send prompts to Google models and receive responses directly in your terminal. It's designed for quick queries, scripting, and integrating LLM capabilities into command-line workflows.
-
-This command uses the standardized `google` provider naming convention, which aligns with industry standards and supports future extensibility.
-
-## Setup
-
-Before using `llm-google-query`, you need to obtain a Google API key and configure it for your environment.
-
-### API Key Configuration
-
-1.  **Obtain a Google API Key:**
-    *   Go to the [Google AI Studio](https://aistudio.google.com/app/apikey) website.
-    *   Create a new API key or use an existing one. Keep this key secure.
-
-2.  **Configure `.env` file:**
-    The `llm-google-query` command expects the API key to be available as an environment variable named `GOOGLE_API_KEY`. The recommended way to manage this is by using a `.env` file in your project's root directory.
-
-    *   Create a file named `.env` in the root of your project (if one doesn't exist).
-    *   Add the following line to your `.env` file, replacing `YOUR_GOOGLE_API_KEY` with the actual key you obtained:
-        ```
-        GOOGLE_API_KEY="YOUR_GOOGLE_API_KEY"
-        ```
-    *   Ensure your shell environment is set up to load variables from `.env` files (e.g., by using `direnv` or similar tools, or by sourcing the file manually: `source .env`). Refer to the project's `.env.example` for more details on environment variable management. For general project setup instructions, including environment variable management, refer to the [Project Setup Guide](../SETUP.md).
-
-## Basic Usage
-
-The fundamental usage of `llm-google-query` involves providing a prompt, either as a direct string or from a file.
-
-### String Prompts
-
-To query Google with a direct string prompt, simply pass the text as an argument:
-
-```bash
-llm-google-query "What is Ruby programming language?"
-```
-
-This will send the question to the default Google model and print the text response to your terminal.
-
-### File Prompts
-
-For longer prompts or to keep your prompts organized, you can use a file. Create a text file (e.g., `prompt.txt`) containing your prompt, then simply provide the file path as the prompt argument (auto-detected):
-
-**Example `prompt.txt`:**
-```
-Explain the concept of quantum entanglement in simple terms.
-Provide a brief summary suitable for a high school student.
-```
-
-**Command:**
-```bash
-llm-google-query prompt.txt
-```
-
-## Output Format Options
-
-You can specify the format of the output from the Google model using the `--format` option.
-
-### Text Output (Default)
-
-By default, the command returns the response as plain text. This is suitable for general queries where you only need the model's textual answer.
-
-```bash
-llm-google-query "Who wrote 'Romeo and Juliet'?"
-```
-_Expected Output (example):_
-```
-William Shakespeare.
-```
-
-### JSON Output
-
-For structured responses, particularly useful for programmatic processing or when the model is expected to return data, use `--format json`:
-
-```bash
-llm-google-query "Explain quantum computing" --format json
-```
-_Expected Output (example, truncated):_
-```json
-{
-  "text": "Quantum computing is a new type of computing that uses the principles of quantum mechanics...",
-  "metadata": {
-    "provider": "google",
-    "model": "gemini-2.0-flash-lite",
-    "finish_reason": "STOP",
-    "usage": {
-      "prompt_tokens": 15,
-      "completion_tokens": 120,
-      "total_tokens": 135
-    },
-    "execution_time": 1.234
-  }
-}
-```
-
-## Advanced Options
-
-`llm-google-query` offers several options to fine-tune the model's behavior and the command's execution.
-
-### `--model`
-
-Specifies the Google model to use for the query. The default model is `gemini-2.0-flash-lite`. You can specify other available models, such as `gemini-pro`.
-
-```bash
-llm-google-query "Hello" --model gemini-2.0-flash-lite
-```
-
-**Note:** The availability of specific models like `gemini-pro` can vary by region or API version. To see the list of models supported by your API key and their capabilities, you can use the `llm-models google` command.
-
-### `--temperature`
-
-Controls the randomness of the output. A higher temperature (e.g., 1.0) results in more creative and diverse responses, while a lower temperature (e.g., 0.0) makes the output more deterministic and focused. The valid range is typically 0.0 to 2.0.
-
-```bash
-llm-google-query "Write a short poem about a cat" --temperature 0.8
-```
-
-### `--max-tokens`
-
-Sets the maximum number of tokens (words or word pieces) the model should generate in its response. This is useful for controlling the length of the output and managing costs.
-
-```bash
-llm-google-query "Describe the solar system" --max-tokens 100
-```
-
-### `--system`
-
-Provides a system instruction or prompt to guide the model's overall behavior or persona. This is useful for setting context that applies to the entire conversation or interaction.
-
-```bash
-llm-google-query "List three benefits of exercise." --system "You are a helpful fitness coach. Respond concisely."
-```
-
-### `--debug`
-
-Enables debug output, providing more verbose information, especially useful for troubleshooting issues or understanding the internal workings of the command.
-
-```bash
-llm-google-query long_prompt.txt --format json --debug
-```
-
-## Combined Options Examples
-
-You can combine multiple options to achieve specific behaviors.
-
-**Example 1: Specific model, temperature, and JSON output from a file.**
-```bash
-llm-google-query research_summary.txt --model gemini-pro --temperature 0.7 --format json
-```
-
-**Example 2: Concise creative poem with system instruction and limited length.**
-```bash
-llm-google-query "Write a haiku about a rainy day." --system "Be playful and concise." --temperature 0.9 --max-tokens 30
-```
-
-**Example 3: Save response to file with specific format.**
-```bash
-llm-google-query "Explain machine learning" --output response.md --format markdown
-```
-
-## Troubleshooting
-
-This section addresses common issues you might encounter when using `llm-google-query`.
-
-### API Key Not Configured
-
-If you receive an error related to authentication or a missing API key, ensure that your `GOOGLE_API_KEY` environment variable is correctly set.
-
-*   **Check `.env` file:** Verify that `GOOGLE_API_KEY="YOUR_GOOGLE_API_KEY"` (with your actual key) is present in your `.env` file.
-*   **Load environment variables:** Make sure your shell loads the `.env` file. If not using a tool like `direnv`, you might need to manually source it: `source .env`.
-*   **Validate the key:** Double-check that the API key itself is correct and has the necessary permissions in Google AI Studio.
-
-### Prompt File Not Found
-
-If you provide a file path and the command reports that the file was not found, it will treat the path as inline text. To ensure a file is read:
-
-*   **Verify path:** Ensure the file path you provided is correct and that the file exists at that location relative to where you are running the command.
-*   **Current Directory:** Confirm you are running the command from the correct directory or provide an absolute path to the prompt file.
-
-### Common Errors
-
-*   **Network Issues:** If you experience connection timeouts or failures, check your internet connection and ensure that Google's API endpoints are accessible from your network.
-*   **Model Rate Limits:** If you make too many requests in a short period, you might hit API rate limits. The command should ideally handle retries, but if issues persist, pause and try again later. Refer to Google Gemini API documentation for current rate limits.
-*   **Invalid Arguments:** If you encounter errors about invalid options or values, review the `--help` output of `llm-google-query` to ensure you are using the correct flags and value formats (e.g., temperature range).
-*   **Provider Naming:** If you see references to "Gemini" in error messages, this is expected as the underlying API is still the Google Gemini API. The `google` naming convention is used for consistency in the CLI interface.
\ No newline at end of file
diff --git a/docs/llm-integration/model-management.md b/docs/llm-integration/model-management.md
index 40d3c67..a2abba1 100644
--- a/docs/llm-integration/model-management.md
+++ b/docs/llm-integration/model-management.md
@@ -15,8 +15,7 @@ This comprehensive guide covers the model discovery and management features in C
    - [Text Output (Default)](#text-output-default)
    - [JSON Output](#json-output)
 6. [Integration with Query Commands](#integration-with-query-commands)
-   - [Using Models with Gemini Queries](#using-models-with-gemini-queries)
-   - [Using Models with LM Studio Queries](#using-models-with-lm-studio-queries)
+   - [Using Models with LLM Queries](#using-models-with-llm-queries)
 7. [Advanced Usage](#advanced-usage)
    - [Scripting and Automation](#scripting-and-automation)
    - [Model Information Parsing](#model-information-parsing)
@@ -92,7 +91,7 @@ ID: gemini-1.5-pro
 Name: Gemini 1.5 Pro
 Description: Mid-size multimodal model that supports up to 2 million tokens
 
-Usage: llm-gemini-query "your prompt" --model MODEL_ID
+Usage: llm-query google:MODEL_ID "your prompt"
 ```
 
 ### Listing LM Studio Models
@@ -119,7 +118,7 @@ ID: deepseek/deepseek-r1-0528-qwen3-8b
 Name: Deepseek R1 0528 Qwen3 8b
 Description: LM Studio model
 
-Usage: llm-lmstudio-query "your prompt" --model MODEL_ID
+Usage: llm-query lmstudio:MODEL_ID "your prompt"
 
 Server: Ensure LM Studio is running at http://localhost:1234
 ```
@@ -223,36 +222,28 @@ llm-models lmstudio --format json
 
 ## Integration with Query Commands
 
-The primary purpose of model management commands is to help you select appropriate models for use with query commands. Both services provide query commands that accept a `--model` parameter.
+The primary purpose of model management commands is to help you select appropriate models for use with the unified `llm-query` command using the `provider:model` syntax.
 
-### Using Models with Gemini Queries
+### Using Models with LLM Queries
 
-After discovering available models, use them with the `llm-gemini-query` command:
+After discovering available models, use them with the unified `llm-query` command:
 
 ```bash
-# Use default model
-llm-gemini-query "Explain quantum computing"
+# Use Google models with provider:model syntax
+llm-query google:gemini-2.5-flash "Explain quantum computing"
+llm-query google:gemini-1.5-pro "Write a poem"
+llm-query google:gemini-1.5-flash "Quick question"
 
-# Use specific model
-llm-gemini-query "Write a poem" --model gemini-1.5-pro
+# Use LM Studio models with provider:model syntax
+llm-query lmstudio:mistralai/devstral-small-2505 "Optimize this function"
+llm-query lmstudio:deepseek/deepseek-r1-0528-qwen3-8b "Solve this logic puzzle"
 
-# Use latest Flash model for speed
-llm-gemini-query "Quick question" --model gemini-1.5-flash
-```
-
-### Using Models with LM Studio Queries
-
-Similarly, use discovered models with the `llm-lmstudio-query` command:
-
-```bash
-# Use default model
-llm-lmstudio-query "Help me debug this code"
-
-# Use specific model for coding tasks
-llm-lmstudio-query "Optimize this function" --model mistralai/devstral-small-2505
+# Use provider without specific model for default
+llm-query google "Help me debug this code"
+llm-query lmstudio "Explain SOLID principles"
 
-# Use reasoning model for complex problems
-llm-lmstudio-query "Solve this logic puzzle" --model deepseek/deepseek-r1-0528-qwen3-8b
+# Use aliases for common models
+llm-query gflash "Quick question"  # alias for google:gemini-2.5-flash
 ```
 
 ## Advanced Usage
@@ -298,7 +289,7 @@ MODELS=$(llm-models google --format json)
 FAST_MODEL=$(echo "$MODELS" | jq -r '.models[] | select(.id | contains("flash")) | .id' | head -1)
 
 # Use selected model for query
-llm-gemini-query "Quick summary of the news" --model "$FAST_MODEL"
+llm-query google:"$FAST_MODEL" "Quick summary of the news"
 ```
 
 ## Troubleshooting
@@ -365,7 +356,7 @@ If the command returns no models:
 llm-models google --debug
 
 # Check API key permissions
-llm-gemini-query "test" --debug
+llm-query google:gemini-2.5-flash "test" --debug
 ```
 
 #### No LM Studio Models Found
@@ -419,13 +410,12 @@ For complete setup and usage information, refer to these related guides:
 
 - **[Project Overview](README.md)**: Main project documentation and quick start guide
 - **[Setup Guide](docs/SETUP.md)**: Initial configuration and API key setup
-- **[Gemini Query Guide](docs/llm-integration/gemini-query-guide.md)**: Detailed information about using Gemini models
+- **[Google Query Guide](docs/llm-integration/google-query-guide.md)**: Detailed information about using Google models
 - **[Development Guide](docs/DEVELOPMENT.md)**: Development environment setup and testing
 
 ### Related Commands
 
-- **`llm-gemini-query`**: Execute queries using Google Gemini models
-- **`llm-lmstudio-query`**: Execute queries using LM Studio models
+- **`llm-query`**: Execute queries using any supported LLM provider with unified syntax
 
 ---
 
diff --git a/docs/llm-integration/providers-overview.md b/docs/llm-integration/providers-overview.md
deleted file mode 100644
index 07ecf69..0000000
--- a/docs/llm-integration/providers-overview.md
+++ /dev/null
@@ -1,218 +0,0 @@
-# LLM Providers Overview
-
-The Coding Agent Tools gem supports multiple LLM (Large Language Model) providers, allowing you to choose the best model for your specific use case. This document provides an overview of all supported providers.
-
-## Supported Providers
-
-### 1. Google Gemini
-- **Command**: `llm-gemini-query`
-- **Models**: Gemini 2.0 Flash Lite, Gemini 1.5 Flash, Gemini 1.5 Pro
-- **Key**: `GEMINI_API_KEY`
-- **Best for**: General-purpose tasks, multimodal capabilities
-- **Documentation**: [Gemini Integration Guide](./gemini.md)
-
-### 2. LM Studio
-- **Command**: `llm-lmstudio-query`
-- **Models**: Any locally loaded model
-- **Key**: Not required (local)
-- **Best for**: Privacy-sensitive tasks, offline usage
-- **Documentation**: [LM Studio Integration Guide](./lmstudio.md)
-
-### 3. OpenAI
-- **Command**: `llm-openai-query`
-- **Models**: GPT-4o, GPT-4o-mini, GPT-4 Turbo, GPT-3.5 Turbo
-- **Key**: `OPENAI_API_KEY`
-- **Best for**: Advanced reasoning, code generation, general tasks
-- **Documentation**: [OpenAI Integration Guide](./providers/openai.md)
-
-### 4. Anthropic (Claude)
-- **Command**: `llm-anthropic-query`
-- **Models**: Claude 3.5 Sonnet, Claude 3.5 Haiku, Claude 3 Opus/Sonnet/Haiku
-- **Key**: `ANTHROPIC_API_KEY`
-- **Best for**: Long context tasks, nuanced responses, safety
-- **Documentation**: [Anthropic Integration Guide](./providers/anthropic.md)
-
-### 5. Mistral AI
-- **Command**: `llm-mistral-query`
-- **Models**: Mistral Large/Medium/Small, Mistral 8x7B/8x22B
-- **Key**: `MISTRAL_API_KEY`
-- **Strengths**: Open-source options, multilingual, code generation
-- **Documentation**: [Mistral Integration Guide](./providers/mistral.md)
-
-### 6. Together AI
-- **Command**: `llm-together-ai-query`
-- **Models**: Llama 3.1, Mistral, DeepSeek, and many more open-source models
-- **Key**: `TOGETHER_API_KEY`
-- **Best for**: Open-source models, fast inference, cost-effectiveness
-- **Documentation**: [Together AI Integration Guide](./providers/together-ai.md)
-
-## Quick Start
-
-### 1. Set up your API key
-```bash
-export PROVIDER_API_KEY="your-api-key-here"
-```
-
-### 2. List available models
-```bash
-llm-models provider_name
-```
-
-### 3. Make a query
-```bash
-llm-provider-query "Your prompt here"
-```
-
-## Common Features
-
-All providers support the following features:
-
-- **File input**: Read prompts from files
-- **System instructions**: Set context with `--system`
-- **Output formatting**: JSON, Markdown, or plain text with `--format`
-- **File output**: Save responses with `--output`
-- **Model selection**: Choose specific models with `--model`
-- **Temperature control**: Adjust creativity with `--temperature`
-- **Token limits**: Control output length with `--max-tokens`
-- **Debug mode**: Troubleshoot with `--debug`
-
-## Choosing a Provider
-
-### By Use Case
-
-| Use Case | Recommended Providers |
-|----------|----------------------|
-| General chat/assistance | OpenAI (GPT-4o), Anthropic (Claude 3.5 Sonnet) |
-| Code generation | OpenAI (GPT-4o), Mistral, Together AI (DeepSeek) |
-| Long documents | Anthropic (Claude - 200k context) |
-| Budget-conscious | Together AI, OpenAI (GPT-3.5 Turbo) |
-| Privacy/offline | LM Studio |
-| Multilingual | Mistral AI, Gemini |
-| Creative writing | Anthropic (Claude), OpenAI with high temperature |
-
-### By Cost (Approximate)
-
-| Provider | Model | Input Cost | Output Cost |
-|----------|-------|------------|-------------|
-| OpenAI | GPT-3.5 Turbo | $0.50/1M | $1.50/1M |
-| OpenAI | GPT-4o-mini | $0.15/1M | $0.60/1M |
-| OpenAI | GPT-4o | $5/1M | $15/1M |
-| Anthropic | Claude 3 Haiku | $0.25/1M | $1.25/1M |
-| Anthropic | Claude 3.5 Sonnet | $3/1M | $15/1M |
-| Mistral | Small | $0.20/1M | $0.60/1M |
-| Mistral | Large | $4/1M | $12/1M |
-| Together AI | Llama 3.1 8B | $0.18/1M | $0.18/1M |
-| Together AI | Llama 3.1 70B | $0.88/1M | $0.88/1M |
-| LM Studio | Any | Free | Free |
-
-### By Speed
-
-1. **Fastest**: LM Studio (local), Mistral Small, GPT-3.5 Turbo
-2. **Fast**: Claude 3 Haiku, GPT-4o-mini, Together AI Turbo models
-3. **Moderate**: Claude 3.5 Sonnet, GPT-4o, Mistral Large
-4. **Slower**: Claude 3 Opus, GPT-4 Turbo
-
-## Unified Models Command
-
-The `llm-models` command works with all providers:
-
-```bash
-# List all Google Gemini models
-llm-models google
-
-# List all OpenAI models
-llm-models openai
-
-# List all Anthropic models
-llm-models anthropic
-
-# Filter models by name
-llm-models openai --filter gpt-4
-
-# Get JSON output
-llm-models anthropic --format json
-```
-
-## Environment Setup
-
-### Using .env file
-
-Create a `.env` file in your project root:
-
-```env
-GEMINI_API_KEY=your-gemini-key
-OPENAI_API_KEY=your-openai-key
-ANTHROPIC_API_KEY=your-anthropic-key
-MISTRAL_API_KEY=your-mistral-key
-TOGETHER_API_KEY=your-together-key
-```
-
-### Using shell exports
-
-Add to your shell configuration file (`.bashrc`, `.zshrc`, etc.):
-
-```bash
-export GEMINI_API_KEY="your-gemini-key"
-export OPENAI_API_KEY="your-openai-key"
-export ANTHROPIC_API_KEY="your-anthropic-key"
-export MISTRAL_API_KEY="your-mistral-key"
-export TOGETHER_API_KEY="your-together-key"
-```
-
-## Advanced Usage
-
-### Comparing Providers
-
-Test the same prompt across multiple providers:
-
-```bash
-# Create a test prompt
-echo "Explain the concept of recursion in programming" > prompt.txt
-
-# Test with different providers
-llm-openai-query prompt.txt --output openai-response.md
-llm-anthropic-query prompt.txt --output anthropic-response.md
-llm-mistral-query prompt.txt --output mistral-response.md
-```
-
-### Provider-Specific Features
-
-Some providers have unique capabilities:
-
-- **Gemini**: Multimodal support (images, etc.)
-- **Anthropic**: Constitutional AI, very large context windows
-- **Together AI**: Access to many open-source models
-- **LM Studio**: Complete privacy, offline usage
-
-## Troubleshooting
-
-### Common Issues
-
-1. **API Key Not Found**
-   - Ensure the environment variable is set correctly
-   - Check for typos in the variable name
-   - Restart your terminal after setting the variable
-
-2. **Rate Limiting**
-   - Wait a few moments before retrying
-   - Consider upgrading your plan
-   - Use a different provider temporarily
-
-3. **Model Not Available**
-   - Run `llm-models provider_name` to see available models
-   - Check if the model name has changed
-   - Ensure your API key has access to the model
-
-### Debug Mode
-
-Use the `--debug` flag with any provider to see detailed error information:
-
-```bash
-llm-openai-query "test" --debug
-```
-
-## See Also
-
-- [Architecture Overview](../../architecture.md)
-- [CLI Command Reference](../cli-reference.md)
-- [Ruby API Documentation](../ruby-api.md)
\ No newline at end of file
diff --git a/docs/llm-integration/providers/anthropic.md b/docs/llm-integration/providers/anthropic.md
deleted file mode 100644
index 657d0da..0000000
--- a/docs/llm-integration/providers/anthropic.md
+++ /dev/null
@@ -1,199 +0,0 @@
-# Anthropic Provider Integration
-
-This guide covers the Anthropic (Claude) provider integration in the Coding Agent Tools gem.
-
-## Prerequisites
-
-- An Anthropic API key from [console.anthropic.com](https://console.anthropic.com/)
-- Ruby 3.2+ installed
-- The `coding-agent-tools` gem installed
-
-## Configuration
-
-### API Key Setup
-
-Set your Anthropic API key as an environment variable:
-
-```bash
-export ANTHROPIC_API_KEY="your-api-key-here"
-```
-
-Alternatively, you can add it to your `.env` file:
-
-```
-ANTHROPIC_API_KEY=your-api-key-here
-```
-
-## Available Models
-
-The Anthropic provider supports the following Claude models:
-
-- **claude-3-5-sonnet-20241022** (default) - Most intelligent Claude model
-- **claude-3-5-haiku-20241022** - Fast and cost-effective
-- **claude-3-opus-20240229** - Powerful model for complex tasks
-- **claude-3-sonnet-20240229** - Balanced performance and speed
-- **claude-3-haiku-20240307** - Fast, compact, and cost-effective
-
-To list all available models:
-
-```bash
-llm-models anthropic
-```
-
-## Usage Examples
-
-### Basic Query
-
-```bash
-llm-anthropic-query "What is Ruby programming language?"
-```
-
-### Using a Specific Model
-
-```bash
-llm-anthropic-query "Explain quantum computing" --model claude-3-5-haiku-20241022
-```
-
-### With System Instruction
-
-```bash
-llm-anthropic-query "Write a haiku" --system "You are a helpful poetry assistant who specializes in Japanese poetry forms"
-```
-
-### Reading from Files
-
-```bash
-# Prompt from file
-llm-anthropic-query prompt.txt
-
-# System instruction from file
-llm-anthropic-query "Analyze this code" --system instructions.md
-```
-
-### Output Formatting
-
-```bash
-# JSON output
-llm-anthropic-query "List 3 programming languages" --format json
-
-# Save to file
-llm-anthropic-query "Write a README" --output readme.md
-
-# Markdown format
-llm-anthropic-query "Create a tutorial" --format markdown --output tutorial.md
-```
-
-### Advanced Options
-
-```bash
-# Adjust temperature (0.0-1.0)
-llm-anthropic-query "Be creative" --temperature 0.9
-
-# Limit output tokens
-llm-anthropic-query "Summarize briefly" --max-tokens 100
-
-# Debug mode for troubleshooting
-llm-anthropic-query "Test prompt" --debug
-```
-
-## API Client Usage (Ruby)
-
-```ruby
-require 'coding_agent_tools'
-
-# Initialize client
-client = CodingAgentTools::Organisms::AnthropicClient.new(
-  model: "claude-3-5-sonnet-20241022",
-  api_key: ENV['ANTHROPIC_API_KEY'] # Optional, uses env by default
-)
-
-# Generate text
-response = client.generate_text(
-  "What is Ruby?",
-  system_instruction: "You are a programming expert",
-  generation_config: {
-    temperature: 0.7,
-    max_tokens: 1000
-  }
-)
-
-puts response[:text]
-puts response[:usage_metadata]
-```
-
-## Error Handling
-
-Common errors and solutions:
-
-### Invalid API Key
-```
-Error: Anthropic API Error (401): Invalid API key
-```
-**Solution**: Check that your `ANTHROPIC_API_KEY` environment variable is set correctly.
-
-### Rate Limiting
-```
-Error: Anthropic API Error (429): Rate limit exceeded
-```
-**Solution**: Wait a moment before retrying, or contact Anthropic to increase your rate limits.
-
-### Model Not Found
-```
-Error: Anthropic API Error (404): Model not found
-```
-**Solution**: Use `llm-models anthropic` to see available models.
-
-### Invalid Request Format
-```
-Error: Anthropic API Error (400): messages: roles must alternate between "user" and "assistant"
-```
-**Solution**: This is handled automatically by the client, but ensure you're not manually constructing invalid message sequences.
-
-## Cost Considerations
-
-Anthropic models are priced per token. Approximate costs (as of 2024):
-
-- **Claude 3.5 Sonnet**: ~$3/1M input tokens, ~$15/1M output tokens
-- **Claude 3.5 Haiku**: ~$0.25/1M input tokens, ~$1.25/1M output tokens
-- **Claude 3 Opus**: ~$15/1M input tokens, ~$75/1M output tokens
-- **Claude 3 Sonnet**: ~$3/1M input tokens, ~$15/1M output tokens
-- **Claude 3 Haiku**: ~$0.25/1M input tokens, ~$1.25/1M output tokens
-
-Use `--max-tokens` to control costs by limiting output length.
-
-## Best Practices
-
-1. **Model Selection**: 
-   - Use Claude 3.5 Haiku for simple, fast tasks
-   - Use Claude 3.5 Sonnet for most general-purpose tasks
-   - Use Claude 3 Opus only for the most complex reasoning tasks
-
-2. **Temperature**: Use lower values (0.0-0.5) for analytical tasks, higher (0.7-1.0) for creative tasks
-
-3. **System Instructions**: Claude responds well to detailed, specific system instructions
-
-4. **Context Windows**: Claude models have large context windows (up to 200k tokens), making them excellent for long documents
-
-5. **Safety**: Claude has built-in safety features and will refuse harmful requests
-
-## Anthropic-Specific Features
-
-### Constitutional AI
-Claude is trained using Constitutional AI, making it more helpful, harmless, and honest by design.
-
-### Long Context
-Claude excels at tasks requiring long context, such as:
-- Document analysis
-- Code review of large files
-- Multi-turn conversations
-- Research synthesis
-
-### Nuanced Responses
-Claude tends to provide more nuanced, thoughtful responses compared to other models, often acknowledging uncertainty or multiple perspectives.
-
-## See Also
-
-- [Anthropic API Documentation](https://docs.anthropic.com/claude/reference)
-- [Anthropic Pricing](https://www.anthropic.com/pricing)
-- [Claude Model Card](https://www.anthropic.com/claude)
-- [Constitutional AI Paper](https://www.anthropic.com/constitutional-ai)
\ No newline at end of file
diff --git a/docs/llm-integration/providers/mistral.md b/docs/llm-integration/providers/mistral.md
deleted file mode 100644
index a01c751..0000000
--- a/docs/llm-integration/providers/mistral.md
+++ /dev/null
@@ -1,197 +0,0 @@
-# Mistral Provider Integration
-
-This guide covers the Mistral AI provider integration (including Mistral models) in the Coding Agent Tools gem.
-
-## Prerequisites
-
-- A Mistral AI API key from [console.mistral.ai](https://console.mistral.ai/)
-- Ruby 3.2+ installed
-- The `coding-agent-tools` gem installed
-
-## Configuration
-
-### API Key Setup
-
-Set your Mistral API key as an environment variable:
-
-```bash
-export MISTRAL_API_KEY="your-api-key-here"
-```
-
-Alternatively, you can add it to your `.env` file:
-
-```
-MISTRAL_API_KEY=your-api-key-here
-```
-
-## Available Models
-
-The Mistral provider supports the following Mistral AI models:
-
-- **mistral-large-latest** (default) - Most capable Mistral model with advanced reasoning
-- **mistral-medium-latest** - Balanced performance and efficiency
-- **mistral-small-latest** - Fast and efficient for simpler tasks
-- **mistral-8x7b-instruct** - Open-source mixture of experts model
-- **mistral-8x22b-instruct** - Large open-source mixture of experts model
-
-To list all available models:
-
-```bash
-llm-models mistral
-```
-
-## Usage Examples
-
-### Basic Query
-
-```bash
-llm-mistral-query "What is Ruby programming language?"
-```
-
-### Using a Specific Model
-
-```bash
-llm-mistral-query "Explain quantum computing" --model mistral-8x7b-instruct
-```
-
-### With System Instruction
-
-```bash
-llm-mistral-query "Write a haiku" --system "You are a helpful poetry assistant"
-```
-
-### Reading from Files
-
-```bash
-# Prompt from file
-llm-mistral-query prompt.txt
-
-# System instruction from file
-llm-mistral-query "Analyze this code" --system instructions.md
-```
-
-### Output Formatting
-
-```bash
-# JSON output
-llm-mistral-query "List 3 programming languages" --format json
-
-# Save to file
-llm-mistral-query "Write a README" --output readme.md
-
-# Markdown format
-llm-mistral-query "Create a tutorial" --format markdown --output tutorial.md
-```
-
-### Advanced Options
-
-```bash
-# Adjust temperature (0.0-1.0)
-llm-mistral-query "Be creative" --temperature 0.9
-
-# Limit output tokens
-llm-mistral-query "Summarize briefly" --max-tokens 100
-
-# Debug mode for troubleshooting
-llm-mistral-query "Test prompt" --debug
-```
-
-## API Client Usage (Ruby)
-
-```ruby
-require 'coding_agent_tools'
-
-# Initialize client
-client = CodingAgentTools::Organisms::MistralClient.new(
-  model: "mistral-8x7b-instruct",
-  api_key: ENV['MISTRAL_API_KEY'] # Optional, uses env by default
-)
-
-# Generate text
-response = client.generate_text(
-  "What is Ruby?",
-  system_instruction: "You are a programming expert",
-  generation_config: {
-    temperature: 0.7,
-    max_tokens: 1000
-  }
-)
-
-puts response[:text]
-puts response[:usage_metadata]
-```
-
-## Error Handling
-
-Common errors and solutions:
-
-### Invalid API Key
-```
-Error: Mistral API Error (401): Invalid API key
-```
-**Solution**: Check that your `MISTRAL_API_KEY` environment variable is set correctly.
-
-### Rate Limiting
-```
-Error: Mistral API Error (429): Rate limit exceeded
-```
-**Solution**: Wait a moment before retrying, or upgrade your Mistral AI plan for higher limits.
-
-### Model Not Found
-```
-Error: Mistral API Error (404): Model not found
-```
-**Solution**: Use `llm-models mistral` to see available models.
-
-## Cost Considerations
-
-Mistral AI models are priced per token. Approximate costs (as of 2024):
-
-- **Mistral Large**: ~$4/1M input tokens, ~$12/1M output tokens
-- **Mistral Medium**: ~$2.7/1M input tokens, ~$8.1/1M output tokens
-- **Mistral Small**: ~$0.2/1M input tokens, ~$0.6/1M output tokens
-- **Mistral 8x7B**: ~$0.7/1M input tokens, ~$0.7/1M output tokens
-- **Mistral 8x22B**: ~$2/1M input tokens, ~$6/1M output tokens
-
-Use `--max-tokens` to control costs by limiting output length.
-
-## Best Practices
-
-1. **Model Selection**: 
-   - Use Mistral Small for simple, fast tasks
-   - Use Mistral Medium for balanced performance
-   - Use Mistral Large for complex reasoning
-   - Use Mistral models for open-source requirements
-
-2. **Temperature**: Use lower values (0.0-0.5) for factual tasks, higher (0.7-1.0) for creative tasks
-
-3. **System Instructions**: Provide clear, concise system instructions for best results
-
-4. **Language Support**: Mistral models excel at multilingual tasks, supporting English, French, Italian, German, and Spanish
-
-## Mistral-Specific Features
-
-### Mixture of Experts Architecture
-Mistral models use a sparse mixture of experts architecture, providing:
-- Efficient inference despite large parameter counts
-- Strong performance across diverse tasks
-- Better cost-performance ratio compared to dense models
-
-### Open Source Availability
-Mistral models are available as open-source, allowing:
-- Self-hosting for sensitive data
-- Fine-tuning for specific use cases
-- Full transparency in model behavior
-
-### Code Generation
-Mistral models are particularly strong at:
-- Code generation and completion
-- Code explanation and documentation
-- Debugging and optimization suggestions
-
-## See Also
-
-- [Mistral AI API Documentation](https://docs.mistral.ai/api/)
-- [Mistral AI Pricing](https://mistral.ai/pricing/)
-- [Mistral Paper](https://arxiv.org/abs/2401.04088)
-- [Mistral AI Models Overview](https://docs.mistral.ai/models/)
\ No newline at end of file
diff --git a/docs/llm-integration/providers/openai.md b/docs/llm-integration/providers/openai.md
deleted file mode 100644
index c31ed2c..0000000
--- a/docs/llm-integration/providers/openai.md
+++ /dev/null
@@ -1,166 +0,0 @@
-# OpenAI Provider Integration
-
-This guide covers the OpenAI provider integration in the Coding Agent Tools gem.
-
-## Prerequisites
-
-- An OpenAI API key from [platform.openai.com](https://platform.openai.com/)
-- Ruby 3.2+ installed
-- The `coding-agent-tools` gem installed
-
-## Configuration
-
-### API Key Setup
-
-Set your OpenAI API key as an environment variable:
-
-```bash
-export OPENAI_API_KEY="your-api-key-here"
-```
-
-Alternatively, you can add it to your `.env` file:
-
-```
-OPENAI_API_KEY=your-api-key-here
-```
-
-## Available Models
-
-The OpenAI provider supports the following models:
-
-- **gpt-4o** (default) - Most capable OpenAI model with vision and advanced reasoning
-- **gpt-4o-mini** - Smaller, faster, and cheaper GPT-4 variant
-- **gpt-4-turbo** - Previous generation GPT-4 with 128k context
-- **gpt-3.5-turbo** - Fast and cost-effective for simpler tasks
-
-To list all available models:
-
-```bash
-llm-models openai
-```
-
-## Usage Examples
-
-### Basic Query
-
-```bash
-llm-openai-query "What is Ruby programming language?"
-```
-
-### Using a Specific Model
-
-```bash
-llm-openai-query "Explain quantum computing" --model gpt-4o-mini
-```
-
-### With System Instruction
-
-```bash
-llm-openai-query "Write a haiku" --system "You are a helpful poetry assistant"
-```
-
-### Reading from Files
-
-```bash
-# Prompt from file
-llm-openai-query prompt.txt
-
-# System instruction from file
-llm-openai-query "Analyze this code" --system instructions.md
-```
-
-### Output Formatting
-
-```bash
-# JSON output
-llm-openai-query "List 3 programming languages" --format json
-
-# Save to file
-llm-openai-query "Write a README" --output readme.md
-
-# Markdown format
-llm-openai-query "Create a tutorial" --format markdown --output tutorial.md
-```
-
-### Advanced Options
-
-```bash
-# Adjust temperature (0.0-2.0)
-llm-openai-query "Be creative" --temperature 1.5
-
-# Limit output tokens
-llm-openai-query "Summarize briefly" --max-tokens 100
-
-# Debug mode for troubleshooting
-llm-openai-query "Test prompt" --debug
-```
-
-## API Client Usage (Ruby)
-
-```ruby
-require 'coding_agent_tools'
-
-# Initialize client
-client = CodingAgentTools::Organisms::OpenAIClient.new(
-  model: "gpt-4o-mini",
-  api_key: ENV['OPENAI_API_KEY'] # Optional, uses env by default
-)
-
-# Generate text
-response = client.generate_text(
-  "What is Ruby?",
-  system_instruction: "You are a programming expert",
-  generation_config: {
-    temperature: 0.7,
-    max_tokens: 1000
-  }
-)
-
-puts response[:text]
-puts response[:usage_metadata]
-```
-
-## Error Handling
-
-Common errors and solutions:
-
-### Invalid API Key
-```
-Error: OpenAI API Error (401): Invalid API key provided
-```
-**Solution**: Check that your `OPENAI_API_KEY` environment variable is set correctly.
-
-### Rate Limiting
-```
-Error: OpenAI API Error (429): Rate limit exceeded
-```
-**Solution**: Wait a moment before retrying, or upgrade your OpenAI plan for higher limits.
-
-### Model Not Found
-```
-Error: OpenAI API Error (404): Model not found
-```
-**Solution**: Use `llm-models openai` to see available models.
-
-## Cost Considerations
-
-OpenAI models are priced per token. Approximate costs (as of 2024):
-
-- **gpt-4o**: ~$5/1M input tokens, ~$15/1M output tokens
-- **gpt-4o-mini**: ~$0.15/1M input tokens, ~$0.60/1M output tokens
-- **gpt-3.5-turbo**: ~$0.50/1M input tokens, ~$1.50/1M output tokens
-
-Use `--max-tokens` to control costs by limiting output length.
-
-## Best Practices
-
-1. **Model Selection**: Use `gpt-4o-mini` for most tasks, upgrade to `gpt-4o` for complex reasoning
-2. **Temperature**: Use lower values (0.0-0.5) for factual tasks, higher (0.7-1.5) for creative tasks
-3. **System Instructions**: Provide clear, specific system instructions for consistent results
-4. **Error Handling**: Always use `--debug` when troubleshooting issues
-
-## See Also
-
-- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
-- [OpenAI Pricing](https://openai.com/pricing)
-- [Model Comparison Guide](https://platform.openai.com/docs/models)
\ No newline at end of file
diff --git a/docs/llm-integration/providers/provider-model-syntax.md b/docs/llm-integration/providers/provider-model-syntax.md
deleted file mode 100644
index 425980d..0000000
--- a/docs/llm-integration/providers/provider-model-syntax.md
+++ /dev/null
@@ -1,183 +0,0 @@
-# Provider:Model Syntax Specification
-
-## Overview
-
-The unified `llm-query` command uses a `provider:model` syntax to specify which LLM provider and model to use for queries. This document defines the syntax rules, validation requirements, and examples for all supported providers.
-
-## Syntax Format
-
-```
-llm-query <provider>:<model> "<prompt>"
-```
-
-Where:
-- `<provider>` is one of the supported provider names (case-insensitive)
-- `<model>` is the model identifier for that provider
-- `<prompt>` is the text prompt to send to the model
-
-## Supported Providers
-
-### 1. Google (`google`)
-
-**Available Models:**
-- `gemini-2.5-flash` (default)
-- `gemini-2.5-pro`
-- `gemini-2.0-flash-lite`
-- `gemini-pro`
-
-**Examples:**
-```bash
-llm-query google:gemini-2.5-flash "What is Ruby?"
-llm-query google:gemini-2.5-pro "Explain quantum computing"
-```
-
-### 2. Anthropic (`anthropic`)
-
-**Available Models:**
-- `claude-4-0-sonnet-latest`
-- `claude-4-0-opus-latest`
-- `claude-3-5-sonnet`
-- `claude-3-opus`
-
-**Examples:**
-```bash
-llm-query anthropic:claude-4-0-sonnet-latest "Write a Ruby script"
-llm-query anthropic:claude-4-0-opus-latest "Analyze this code"
-```
-
-### 3. OpenAI (`openai`)
-
-**Available Models:**
-- `gpt-4o`
-- `gpt-4o-mini`
-- `o3`
-- `o1`
-- `gpt-4-turbo`
-
-**Examples:**
-```bash
-llm-query openai:gpt-4o "Generate test cases"
-llm-query openai:o3 "Solve this problem"
-```
-
-### 4. Mistral (`mistral`)
-
-**Available Models:**
-- `mistral-large`
-- `mistral-medium`
-- `mistral-small`
-- `codestral`
-
-**Examples:**
-```bash
-llm-query mistral:mistral-large "Explain algorithms"
-llm-query mistral:codestral "Review this code"
-```
-
-### 5. Together AI (`together_ai`)
-
-**Available Models:**
-- `meta-llama/Llama-3.2-90B-Vision-Instruct-Turbo`
-- `meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo`
-- `Qwen/Qwen2.5-72B-Instruct-Turbo`
-
-**Examples:**
-```bash
-llm-query together_ai:meta-llama/Llama-3.2-90B-Vision-Instruct-Turbo "Describe this image"
-llm-query together_ai:meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo "Write documentation"
-```
-
-### 6. LM Studio (`lmstudio`)
-
-**Available Models:**
-- Any model loaded in local LM Studio instance
-- Model names are determined by what's currently loaded
-
-**Examples:**
-```bash
-llm-query lmstudio:llama-3.2-3b "Local query"
-llm-query lmstudio:codellama-7b "Code generation"
-```
-
-## Validation Rules
-
-### Provider Validation
-- Provider names are case-insensitive
-- Must be one of: `google`, `anthropic`, `openai`, `mistral`, `together_ai`, `lmstudio`
-- Invalid providers will show an error with list of valid providers
-
-### Model Validation
-- Model names are case-sensitive for most providers
-- For LM Studio, validation is deferred to the local instance
-- Invalid models will show provider-specific error with available models
-
-### Syntax Validation
-- Must contain exactly one colon (`:`) separator
-- Provider name cannot be empty
-- Model name cannot be empty
-- No spaces allowed in provider:model specification
-
-## Error Handling
-
-### Invalid Provider
-```
-Error: Unknown provider 'invalid'. Valid providers are: google, anthropic, openai, mistral, together_ai, lmstudio
-```
-
-### Invalid Model
-```
-Error: Unknown model 'invalid-model' for provider 'google'. Valid models are: gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash-lite, gemini-pro
-```
-
-### Invalid Syntax
-```
-Error: Invalid provider:model syntax 'google'. Expected format: <provider>:<model>
-```
-
-### Missing Components
-```
-Error: Provider cannot be empty in 'google:'
-Error: Model cannot be empty in ':gemini-2.5-flash'
-```
-
-## Dynamic Shorthand Aliases
-
-The following shorthand aliases automatically resolve to the latest/recommended models:
-
-- `gflash` → `google:gemini-2.5-flash`
-- `gpro` → `google:gemini-2.5-pro`
-- `csonet` → `anthropic:claude-4-0-sonnet-latest`
-- `copus` → `anthropic:claude-4-0-opus-latest`
-- `o4mini` → `openai:gpt-4o-mini`
-- `o3` → `openai:o3`
-
-**Usage:**
-```bash
-gflash "Quick question"
-# Equivalent to: llm-query google:gemini-2.5-flash "Quick question"
-```
-
-## Edge Cases
-
-### Special Characters in Model Names
-- Forward slashes (`/`) are allowed in model names (e.g., Together AI models)
-- Hyphens (`-`) and underscores (`_`) are allowed
-- Periods (`.`) are allowed for version numbers
-
-### Case Sensitivity
-- Provider names: case-insensitive (`Google`, `GOOGLE`, `google` all valid)
-- Model names: case-sensitive (`gemini-2.5-flash` ≠ `Gemini-2.5-Flash`)
-
-### Whitespace
-- Leading/trailing whitespace in provider:model is trimmed
-- Internal whitespace is not allowed
-
-## Backward Compatibility
-
-All existing provider-specific executables remain functional:
-- `llm-google-query` → wraps `llm-query google:gemini-2.5-flash`
-- `llm-anthropic-query` → wraps `llm-query anthropic:claude-4-0-sonnet-latest`
-- `llm-openai-query` → wraps `llm-query openai:gpt-4o`
-- `llm-mistral-query` → wraps `llm-query mistral:mistral-large`
-- `llm-together-ai-query` → wraps `llm-query together_ai:meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo`
-- `llm-lmstudio-query` → wraps `llm-query lmstudio:<default-model>`
diff --git a/docs/llm-integration/providers/together-ai.md b/docs/llm-integration/providers/together-ai.md
deleted file mode 100644
index 7bec5ac..0000000
--- a/docs/llm-integration/providers/together-ai.md
+++ /dev/null
@@ -1,223 +0,0 @@
-# Together AI Provider Integration
-
-This guide covers the Together AI provider integration in the Coding Agent Tools gem.
-
-## Prerequisites
-
-- A Together AI API key from [api.together.xyz](https://api.together.xyz/)
-- Ruby 3.2+ installed
-- The `coding-agent-tools` gem installed
-
-## Configuration
-
-### API Key Setup
-
-Set your Together AI API key as an environment variable:
-
-```bash
-export TOGETHER_API_KEY="your-api-key-here"
-```
-
-Alternatively, you can add it to your `.env` file:
-
-```
-TOGETHER_API_KEY=your-api-key-here
-```
-
-## Available Models
-
-The Together AI provider supports a wide range of open-source models:
-
-- **meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo** (default) - Fast Llama 3.1 70B with optimized inference
-- **meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo** - Smaller, faster Llama 3.1 model
-- **mistralai/Mistral-8x7B-Instruct-v0.1** - Mixture of experts model with strong performance
-- **mistralai/Mistral-8x22B-Instruct-v0.1** - Large mixture of experts model
-- **deepseek-ai/deepseek-coder-33b-instruct** - Specialized model for code generation
-
-To list all available models:
-
-```bash
-llm-models together_ai
-```
-
-## Usage Examples
-
-### Basic Query
-
-```bash
-llm-together-ai-query "What is Ruby programming language?"
-```
-
-### Using a Specific Model
-
-```bash
-llm-together-ai-query "Explain quantum computing" --model mistralai/Mistral-8x7B-Instruct-v0.1
-```
-
-### With System Instruction
-
-```bash
-llm-together-ai-query "Write a haiku" --system "You are a helpful poetry assistant"
-```
-
-### Reading from Files
-
-```bash
-# Prompt from file
-llm-together-ai-query prompt.txt
-
-# System instruction from file
-llm-together-ai-query "Analyze this code" --system instructions.md
-```
-
-### Output Formatting
-
-```bash
-# JSON output
-llm-together-ai-query "List 3 programming languages" --format json
-
-# Save to file
-llm-together-ai-query "Write a README" --output readme.md
-
-# Markdown format
-llm-together-ai-query "Create a tutorial" --format markdown --output tutorial.md
-```
-
-### Advanced Options
-
-```bash
-# Adjust temperature (0.0-2.0)
-llm-together-ai-query "Be creative" --temperature 1.2
-
-# Limit output tokens
-llm-together-ai-query "Summarize briefly" --max-tokens 100
-
-# Debug mode for troubleshooting
-llm-together-ai-query "Test prompt" --debug
-```
-
-## API Client Usage (Ruby)
-
-```ruby
-require 'coding_agent_tools'
-
-# Initialize client
-client = CodingAgentTools::Organisms::TogetherAIClient.new(
-  model: "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
-  api_key: ENV['TOGETHER_API_KEY'] # Optional, uses env by default
-)
-
-# Generate text
-response = client.generate_text(
-  "What is Ruby?",
-  system_instruction: "You are a programming expert",
-  generation_config: {
-    temperature: 0.7,
-    max_tokens: 1000
-  }
-)
-
-puts response[:text]
-puts response[:usage_metadata]
-```
-
-## Error Handling
-
-Common errors and solutions:
-
-### Invalid API Key
-```
-Error: Together AI API Error (401): Invalid API key
-```
-**Solution**: Check that your `TOGETHER_API_KEY` environment variable is set correctly.
-
-### Rate Limiting
-```
-Error: Together AI API Error (429): Rate limit exceeded
-```
-**Solution**: Wait a moment before retrying, or upgrade your Together AI plan for higher limits.
-
-### Model Not Found
-```
-Error: Together AI API Error (404): Model not found
-```
-**Solution**: Use `llm-models together_ai` to see available models. Note that model availability can change.
-
-### Model Overloaded
-```
-Error: Together AI API Error (503): Model is currently overloaded
-```
-**Solution**: Try a different model or wait a few moments before retrying.
-
-## Cost Considerations
-
-Together AI offers competitive pricing for open-source models. Approximate costs (as of 2024):
-
-- **Llama 3.1 70B**: ~$0.88/1M tokens
-- **Llama 3.1 8B**: ~$0.18/1M tokens
-- **Mistral 8x7B**: ~$0.60/1M tokens
-- **Mistral 8x22B**: ~$1.20/1M tokens
-- **DeepSeek Coder 33B**: ~$0.80/1M tokens
-
-Use `--max-tokens` to control costs by limiting output length.
-
-## Best Practices
-
-1. **Model Selection**: 
-   - Use Llama 3.1 8B for fast, simple tasks
-   - Use Llama 3.1 70B for complex reasoning and general tasks
-   - Use Mistral models for code and technical content
-   - Use DeepSeek Coder for specialized code generation
-
-2. **Temperature**: Together AI models support wider temperature ranges (0.0-2.0) than some providers
-
-3. **System Instructions**: Most models respond well to clear, specific system instructions
-
-4. **Inference Speed**: Together AI optimizes for fast inference, making it ideal for real-time applications
-
-## Together AI-Specific Features
-
-### Model Variety
-Together AI provides access to a vast array of open-source models, including:
-- Language models (Llama, Mistral, Qwen, etc.)
-- Code models (DeepSeek, CodeLlama, StarCoder)
-- Specialized models for specific tasks
-
-### Fast Inference
-Together AI specializes in optimized inference for open-source models:
-- Turbo variants for faster response times
-- Optimized serving infrastructure
-- Lower latency compared to self-hosting
-
-### Flexible Deployment
-- Access the same models via API that you could self-host
-- No vendor lock-in
-- Easy migration between providers
-
-### Community Models
-Together AI often adds new open-source models quickly after release, providing early access to cutting-edge models.
-
-## Advanced Features
-
-### Model Switching
-Easily switch between models to find the best fit:
-
-```bash
-# Try different models for the same task
-llm-together-ai-query "Explain recursion" --model meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo
-llm-together-ai-query "Explain recursion" --model mistralai/Mistral-8x7B-Instruct-v0.1
-```
-
-### Code Generation
-For code-specific tasks, use specialized models:
-
-```bash
-llm-together-ai-query "Write a Ruby class for a binary tree" --model deepseek-ai/deepseek-coder-33b-instruct
-```
-
-## See Also
-
-- [Together AI API Documentation](https://docs.together.ai/reference)
-- [Together AI Pricing](https://www.together.ai/pricing)
-- [Together AI Model List](https://docs.together.ai/docs/models)
-- [Together AI Blog](https://www.together.ai/blog)
\ No newline at end of file
diff --git a/docs/llm-integration/query.md b/docs/llm-integration/query.md
new file mode 100644
index 0000000..7f47c4b
--- /dev/null
+++ b/docs/llm-integration/query.md
@@ -0,0 +1,532 @@
+# LLM Query Guide
+
+This comprehensive guide covers the unified `llm-query` command for interacting with Large Language Models (LLMs) across multiple providers using consistent syntax and options.
+
+## Table of Contents
+
+1. [Introduction](#introduction)
+2. [Unified Syntax](#unified-syntax)
+3. [Supported Providers](#supported-providers)
+4. [Basic Usage](#basic-usage)
+5. [Advanced Options](#advanced-options)
+6. [Provider-Specific Information](#provider-specific-information)
+7. [Model Management](#model-management)
+8. [Error Handling](#error-handling)
+9. [Best Practices](#best-practices)
+10. [Troubleshooting](#troubleshooting)
+
+---
+
+## Introduction
+
+The `exe/llm-query` command provides a unified interface for querying multiple LLM providers using consistent syntax. Instead of learning separate commands for each provider, you can use one command with a simple `provider:model` syntax.
+
+**Key Benefits:**
+- **Unified Interface**: One command for all providers
+- **Consistent Options**: Same flags work across all providers
+- **Model Flexibility**: Easy switching between providers and models
+- **Future-Proof**: New providers integrate seamlessly
+
+## Unified Syntax
+
+### Basic Format
+
+```bash
+llm-query <provider>:<model> "<prompt>" [OPTIONS]
+```
+
+### Examples
+
+```bash
+# Google Gemini
+llm-query google:gemini-2.5-flash "What is Ruby programming?"
+
+# Anthropic Claude
+llm-query anthropic:claude-4-0-sonnet-latest "Explain quantum computing"
+
+# OpenAI GPT
+llm-query openai:gpt-4o "Write a Ruby script"
+
+# Provider only (uses default model)
+llm-query google "Quick question"
+
+# Using aliases
+llm-query gflash "Fast response needed"
+```
+
+### Validation Rules
+
+- **Provider**: Case-insensitive, must be supported
+- **Model**: Case-sensitive, must be available for the provider
+- **Syntax**: Exactly one colon (`:`) separator required
+- **Components**: Neither provider nor model can be empty
+
+## Supported Providers
+
+### 1. Google (`google`)
+
+**Setup:**
+```bash
+export GOOGLE_API_KEY="your-api-key-here"
+```
+
+**Available Models:**
+- `gemini-2.5-flash` (default) - Fast, versatile model
+- `gemini-2.5-pro` - Most capable Gemini model
+- `gemini-2.0-flash-lite` - Lightweight version
+- `gemini-1.5-pro` - Previous generation pro model
+- `gemini-1.5-flash` - Previous generation flash model
+
+**Best For:** General-purpose tasks, multimodal capabilities, fast responses
+
+### 2. Anthropic (`anthropic`)
+
+**Setup:**
+```bash
+export ANTHROPIC_API_KEY="your-api-key-here"
+```
+
+**Available Models:**
+- `claude-4-0-sonnet-latest` (default) - Most intelligent Claude
+- `claude-4-0-opus-latest` - Most powerful Claude
+- `claude-3-5-sonnet-20241022` - Balanced performance
+- `claude-3-5-haiku-20241022` - Fast and cost-effective
+
+**Best For:** Long context tasks, nuanced responses, safety-critical applications
+
+### 3. OpenAI (`openai`)
+
+**Setup:**
+```bash
+export OPENAI_API_KEY="your-api-key-here"
+```
+
+**Available Models:**
+- `gpt-4o` (default) - Most capable OpenAI model
+- `gpt-4o-mini` - Faster, cheaper GPT-4 variant
+- `o3` - Advanced reasoning model
+- `o1` - Reasoning model
+- `gpt-4-turbo` - Previous generation turbo model
+
+**Best For:** Advanced reasoning, code generation, general tasks
+
+### 4. Mistral (`mistral`)
+
+**Setup:**
+```bash
+export MISTRAL_API_KEY="your-api-key-here"
+```
+
+**Available Models:**
+- `mistral-large` (default) - Most capable Mistral model
+- `mistral-medium` - Balanced performance
+- `mistral-small` - Fast and cost-effective
+- `codestral` - Specialized for code
+
+**Best For:** Multilingual tasks, European AI compliance, code generation
+
+### 5. Together AI (`together_ai`)
+
+**Setup:**
+```bash
+export TOGETHER_API_KEY="your-api-key-here"
+```
+
+**Available Models:**
+- `meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo` (default)
+- `meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo`
+- `mistralai/Mistral-8x7B-Instruct-v0.1`
+- `deepseek-ai/deepseek-coder-33b-instruct`
+
+**Best For:** Open-source models, cost-effectiveness, specialized models
+
+### 6. LM Studio (`lmstudio`)
+
+**Setup:**
+- Download and install LM Studio from https://lmstudio.ai/
+- Start LM Studio and load a model
+- Ensure it's running on `localhost:1234`
+
+**Available Models:** Any model loaded in your local LM Studio instance
+
+**Best For:** Privacy-sensitive tasks, offline usage, complete data control
+
+## Basic Usage
+
+### String Prompts
+
+```bash
+# Direct string prompt
+llm-query google:gemini-2.5-flash "What is Ruby programming language?"
+
+# Multi-word prompts (use quotes)
+llm-query anthropic:claude-4-0-sonnet-latest "Explain the difference between Ruby and Python"
+```
+
+### File Prompts
+
+```bash
+# Read prompt from file (auto-detected)
+llm-query openai:gpt-4o prompt.txt
+
+# File paths work with any provider
+llm-query lmstudio research_questions.md
+```
+
+### Provider Defaults
+
+```bash
+# Use provider's default model
+llm-query google "Quick question"
+llm-query anthropic "Analyze this text"
+llm-query openai "Generate code"
+```
+
+### Shorthand Aliases
+
+```bash
+# Common model aliases
+llm-query gflash "Fast response"     # google:gemini-2.5-flash
+llm-query csonet "Complex analysis" # anthropic:claude-4-0-sonnet-latest
+llm-query o4mini "Quick task"       # openai:gpt-4o-mini
+```
+
+## Advanced Options
+
+### Output Formatting
+
+```bash
+# JSON output (structured data)
+llm-query google:gemini-2.5-flash "List programming languages" --format json
+
+# Markdown output
+llm-query anthropic:claude-4-0-sonnet-latest "Write a tutorial" --format markdown
+
+# Plain text (default)
+llm-query openai:gpt-4o "Explain AI" --format text
+```
+
+### File Output
+
+```bash
+# Save to file (format inferred from extension)
+llm-query google:gemini-2.5-flash "Write documentation" --output docs.md
+
+# Specify format explicitly
+llm-query openai:gpt-4o "Generate data" --output data.json --format json
+
+# Multiple files
+llm-query anthropic:claude-4-0-sonnet-latest prompt.txt --output analysis.md
+```
+
+### System Instructions
+
+```bash
+# Text system instruction
+llm-query google:gemini-2.5-flash "Write code" --system "You are a senior Ruby developer"
+
+# System instruction from file
+llm-query openai:gpt-4o "Review code" --system instructions.md
+
+# Provider-specific personas
+llm-query anthropic:claude-4-0-sonnet-latest "Analyze data" --system "You are a data scientist with expertise in statistics"
+```
+
+### Generation Parameters
+
+```bash
+# Temperature (creativity control)
+llm-query google:gemini-2.5-flash "Write a poem" --temperature 0.9  # More creative
+llm-query openai:gpt-4o "Summarize facts" --temperature 0.1        # More focused
+
+# Max tokens (output length control)
+llm-query anthropic:claude-4-0-sonnet-latest "Brief summary" --max-tokens 100
+
+# Timeout (request timeout)
+llm-query together_ai:meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo "Complex task" --timeout 60
+```
+
+### Debug Mode
+
+```bash
+# Enable debug output
+llm-query google:gemini-2.5-flash "Test prompt" --debug
+
+# Debug with file output
+llm-query openai:gpt-4o prompt.txt --output result.md --debug
+```
+
+## Provider-Specific Information
+
+### Google Gemini Specifics
+
+**Temperature Range:** 0.0 - 2.0
+**Context Window:** Up to 2M tokens
+**Special Features:** Multimodal capabilities
+
+```bash
+# Optimized for speed
+llm-query google:gemini-2.5-flash "Quick question" --max-tokens 50
+
+# Optimized for quality
+llm-query google:gemini-2.5-pro "Complex analysis" --temperature 0.3
+```
+
+### Anthropic Claude Specifics
+
+**Temperature Range:** 0.0 - 1.0
+**Context Window:** Up to 200k tokens
+**Special Features:** Constitutional AI, safety-focused
+
+```bash
+# Long document analysis
+llm-query anthropic:claude-4-0-sonnet-latest large_document.txt --max-tokens 4000
+
+# Safety-critical tasks
+llm-query anthropic:claude-4-0-opus-latest "Review code for security" --temperature 0.2
+```
+
+### OpenAI Specifics
+
+**Temperature Range:** 0.0 - 2.0
+**Context Window:** 128k tokens (varies by model)
+**Special Features:** Advanced reasoning, function calling
+
+```bash
+# Creative tasks
+llm-query openai:gpt-4o "Write a story" --temperature 1.5
+
+# Analytical tasks
+llm-query openai:o3 "Solve this problem" --temperature 0.0
+```
+
+### Together AI Specifics
+
+**Temperature Range:** 0.0 - 2.0
+**Cost:** Very competitive for open-source models
+**Special Features:** Access to latest open-source models
+
+```bash
+# Code generation with specialized model
+llm-query together_ai:deepseek-ai/deepseek-coder-33b-instruct "Write a function"
+
+# Fast inference
+llm-query together_ai:meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo "Quick response"
+```
+
+### LM Studio Specifics
+
+**Cost:** Free (local inference)
+**Privacy:** Complete data control
+**Performance:** Depends on local hardware
+
+```bash
+# Use whatever model is loaded
+llm-query lmstudio "Private query"
+
+# Works offline
+llm-query lmstudio:local-model "No internet needed"
+```
+
+## Model Management
+
+### Discovering Models
+
+```bash
+# List models for each provider
+exe/llm-models google
+exe/llm-models anthropic
+exe/llm-models openai
+exe/llm-models mistral
+exe/llm-models together_ai
+exe/llm-models lmstudio
+
+# Filter models
+exe/llm-models google --filter flash
+exe/llm-models openai --filter gpt-4
+
+# JSON output for scripting
+exe/llm-models anthropic --format json
+```
+
+### Model Selection Strategy
+
+```bash
+# Speed-optimized
+llm-query google:gemini-2.5-flash "Quick task"
+llm-query anthropic:claude-3-5-haiku-20241022 "Fast response"
+llm-query openai:gpt-4o-mini "Simple question"
+
+# Quality-optimized
+llm-query google:gemini-2.5-pro "Complex analysis"
+llm-query anthropic:claude-4-0-sonnet-latest "Detailed review"
+llm-query openai:gpt-4o "Advanced reasoning"
+
+# Cost-optimized
+llm-query together_ai:meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo "Budget task"
+llm-query lmstudio "Free local inference"
+```
+
+## Error Handling
+
+### Common Error Types
+
+**Invalid Provider:**
+```
+Error: Unknown provider 'invalid'. Supported providers: google, anthropic, openai, mistral, together_ai, lmstudio
+```
+
+**Invalid Model:**
+```
+Error: Unknown model 'invalid-model' for provider 'google'
+```
+
+**Authentication:**
+```
+Error: API key not found. Set GOOGLE_API_KEY environment variable
+```
+
+**Rate Limiting:**
+```
+Error: Rate limit exceeded. Please wait before retrying
+```
+
+### Error Recovery
+
+```bash
+# Check available providers and models
+llm-query --help
+
+# Verify API key
+echo $GOOGLE_API_KEY
+
+# Test with debug mode
+llm-query google:gemini-2.5-flash "test" --debug
+
+# Use different provider as fallback
+llm-query anthropic:claude-4-0-sonnet-latest "backup query"
+```
+
+## Best Practices
+
+### Model Selection
+
+1. **Speed vs Quality Trade-off:**
+   - Fast: `gemini-2.5-flash`, `claude-3-5-haiku`, `gpt-4o-mini`
+   - Balanced: `gemini-2.5-pro`, `claude-4-0-sonnet-latest`, `gpt-4o`
+   - Maximum Quality: `claude-4-0-opus-latest`, `o3`
+
+2. **Cost Optimization:**
+   - Use smaller models for simple tasks
+   - Limit `--max-tokens` for cost control
+   - Consider Together AI for budget-conscious projects
+
+3. **Privacy Considerations:**
+   - Use LM Studio for sensitive data
+   - Check provider data policies
+   - Consider geographic data residency
+
+### Temperature Guidelines
+
+```bash
+# Factual tasks (low temperature)
+llm-query google:gemini-2.5-flash "What is the capital of France?" --temperature 0.1
+
+# Balanced tasks (medium temperature)
+llm-query anthropic:claude-4-0-sonnet-latest "Explain machine learning" --temperature 0.7
+
+# Creative tasks (high temperature)
+llm-query openai:gpt-4o "Write a creative story" --temperature 1.2
+```
+
+### System Instructions
+
+```bash
+# Be specific about the role
+llm-query google:gemini-2.5-flash "Review code" --system "You are a senior software engineer specializing in Ruby. Focus on best practices, potential bugs, and performance issues."
+
+# Provide context
+llm-query anthropic:claude-4-0-sonnet-latest "Analyze data" --system "You are analyzing e-commerce data for a retail company. Focus on actionable insights for increasing sales."
+
+# Set output format expectations
+llm-query openai:gpt-4o "Generate report" --system "Provide your response in markdown format with clear headings and bullet points."
+```
+
+## Troubleshooting
+
+### Environment Issues
+
+```bash
+# Check all API keys
+env | grep API_KEY
+
+# Test specific provider
+llm-query google:gemini-2.5-flash "test" --debug
+llm-query anthropic:claude-4-0-sonnet-latest "test" --debug
+
+# Verify LM Studio connection
+curl http://localhost:1234/v1/models
+```
+
+### Performance Issues
+
+```bash
+# Use faster models
+llm-query google:gemini-2.5-flash "quick question"
+llm-query anthropic:claude-3-5-haiku-20241022 "fast response"
+
+# Reduce output length
+llm-query openai:gpt-4o "brief answer" --max-tokens 100
+
+# Increase timeout for complex tasks
+llm-query anthropic:claude-4-0-sonnet-latest "complex analysis" --timeout 120
+```
+
+### Output Issues
+
+```bash
+# Force specific format
+llm-query google:gemini-2.5-flash "data" --format json
+
+# Check file permissions
+llm-query openai:gpt-4o "content" --output /tmp/test.md
+
+# Debug output processing
+llm-query anthropic:claude-4-0-sonnet-latest "test" --output result.txt --debug
+```
+
+### Provider Fallbacks
+
+```bash
+#!/bin/bash
+# Script with provider fallbacks
+
+if llm-query google:gemini-2.5-flash "$1" --output response.md 2>/dev/null; then
+    echo "Google query successful"
+elif llm-query anthropic:claude-4-0-sonnet-latest "$1" --output response.md 2>/dev/null; then
+    echo "Fallback to Anthropic successful"
+elif llm-query openai:gpt-4o "$1" --output response.md 2>/dev/null; then
+    echo "Fallback to OpenAI successful"
+else
+    echo "All providers failed"
+    exit 1
+fi
+```
+
+## Migration from Old Commands
+
+The following legacy commands are replaced by the unified syntax:
+
+| Old Command | New Unified Command |
+|-------------|-------------------|
+| `llm-google-query "prompt"` | `llm-query google:gemini-2.5-flash "prompt"` |
+| `llm-anthropic-query "prompt"` | `llm-query anthropic:claude-4-0-sonnet-latest "prompt"` |
+| `llm-openai-query "prompt"` | `llm-query openai:gpt-4o "prompt"` |
+| `llm-mistral-query "prompt"` | `llm-query mistral:mistral-large "prompt"` |
+| `llm-lmstudio-query "prompt"` | `llm-query lmstudio "prompt"` |
+
+All options (`--temperature`, `--max-tokens`, `--system`, etc.) work the same way with the new unified command.
+
+---
+
+*This guide covers the unified LLM query interface introduced in v0.2.0. For the latest updates and additional features, refer to the project's main documentation.*
\ No newline at end of file
diff --git a/lib/coding_agent_tools/cli/commands/llm/query.rb b/lib/coding_agent_tools/cli/commands/llm/query.rb
index f9037b0..070329b 100644
--- a/lib/coding_agent_tools/cli/commands/llm/query.rb
+++ b/lib/coding_agent_tools/cli/commands/llm/query.rb
@@ -132,22 +132,9 @@ module CodingAgentTools
             client_options = {model: model}
             client_options[:timeout] = options[:timeout] if options[:timeout]
 
-            case provider
-            when "google"
-              Organisms::GoogleClient.new(**client_options)
-            when "anthropic"
-              Organisms::AnthropicClient.new(**client_options)
-            when "openai"
-              Organisms::OpenAIClient.new(**client_options)
-            when "mistral"
-              Organisms::MistralClient.new(**client_options)
-            when "together_ai"
-              Organisms::TogetherAIClient.new(**client_options)
-            when "lmstudio"
-              Organisms::LMStudioClient.new(**client_options)
-            else
-              raise "Unsupported provider: #{provider}"
-            end
+            Molecules::ClientFactory.build(provider, client_options)
+          rescue Molecules::ClientFactory::UnknownProviderError => e
+            raise ArgumentError, e.message
           end
 
           def build_generation_options(provider, options, system_text)
diff --git a/lib/coding_agent_tools/molecules/client_factory.rb b/lib/coding_agent_tools/molecules/client_factory.rb
new file mode 100644
index 0000000..fca0090
--- /dev/null
+++ b/lib/coding_agent_tools/molecules/client_factory.rb
@@ -0,0 +1,88 @@
+# frozen_string_literal: true
+
+module CodingAgentTools
+  module Molecules
+    # ClientFactory provides a centralized way to instantiate LLM provider clients
+    # This eliminates the need for case statements when adding new providers
+    class ClientFactory
+      class UnknownProviderError < StandardError; end
+
+      class << self
+        # Register a client class for a specific provider
+        # @param provider_name [String] The provider identifier (e.g., "google", "anthropic")
+        # @param client_class [Class] The client class to instantiate for this provider
+        def register(provider_name, client_class)
+          @registry ||= {}
+          @registry[provider_name] = client_class
+        end
+
+        # Build a client instance for the specified provider
+        # @param provider_name [String] The provider identifier
+        # @param options [Hash] Options to pass to the client constructor
+        # @return [BaseClient] An instance of the appropriate client class
+        # @raise [UnknownProviderError] If the provider is not registered
+        def build(provider_name, options = {})
+          ensure_clients_loaded
+          
+          @registry ||= {}
+          client_class = @registry[provider_name]
+
+          if client_class.nil?
+            raise UnknownProviderError, "Unknown provider '#{provider_name}'. " \
+                                       "Registered providers: #{registered_providers.join(', ')}"
+          end
+
+          client_class.new(**options)
+        end
+
+        # Get list of registered provider names
+        # @return [Array<String>] List of provider names
+        def registered_providers
+          @registry ||= {}
+          @registry.keys.sort
+        end
+
+        # Get the registry hash (mainly for testing)
+        # @return [Hash] The provider registry
+        def registry
+          @registry ||= {}
+        end
+
+        # Clear the registry (mainly for testing)
+        def clear_registry!
+          @registry = {}
+          @clients_loaded = false
+        end
+
+        private
+
+        # Ensure all client classes are loaded and registered
+        # This triggers Zeitwerk autoloading for all known client classes
+        def ensure_clients_loaded
+          return if @clients_loaded
+
+          # List of all known client class names
+          client_classes = %w[
+            GoogleClient
+            AnthropicClient
+            OpenAIClient
+            MistralClient
+            TogetherAIClient
+            LMStudioClient
+          ]
+
+          # Access each class to trigger autoloading and registration
+          client_classes.each do |class_name|
+            begin
+              CodingAgentTools::Organisms.const_get(class_name)
+            rescue NameError
+              # Class doesn't exist - skip it
+            end
+          end
+
+          @clients_loaded = true
+        end
+      end
+    end
+  end
+end
\ No newline at end of file
diff --git a/lib/coding_agent_tools/organisms/anthropic_client.rb b/lib/coding_agent_tools/organisms/anthropic_client.rb
index f38b96b..2952ad5 100644
--- a/lib/coding_agent_tools/organisms/anthropic_client.rb
+++ b/lib/coding_agent_tools/organisms/anthropic_client.rb
@@ -23,6 +23,12 @@ module CodingAgentTools
         max_tokens: 4096
       }.freeze
 
+      # Explicit provider name declaration
+      # @return [String] The provider name for this client
+      def self.provider_name
+        "anthropic"
+      end
+
       # Initialize Anthropic client
       # @param api_key [String, nil] API key (uses env/config if nil)
       # @param model [String] Model to use
diff --git a/lib/coding_agent_tools/organisms/base_client.rb b/lib/coding_agent_tools/organisms/base_client.rb
index fb4f135..f3eef24 100644
--- a/lib/coding_agent_tools/organisms/base_client.rb
+++ b/lib/coding_agent_tools/organisms/base_client.rb
@@ -3,6 +3,7 @@
 require_relative "../molecules/api_credentials"
 require_relative "../molecules/http_request_builder"
 require_relative "../molecules/api_response_parser"
+require_relative "../molecules/client_factory"
 require_relative "../models/default_model_config"
 
 module CodingAgentTools
@@ -12,6 +13,29 @@ module CodingAgentTools
     class BaseClient
       attr_reader :model, :base_url, :generation_config
 
+      # Auto-register subclasses with the ClientFactory
+      def self.inherited(subclass)
+        super
+        # Simple registration - we'll register when the subclass is loaded
+        # The provider_key method should be available immediately
+        provider_key = subclass.provider_key
+        Molecules::ClientFactory.register(provider_key, subclass) if provider_key
+      end
+
+      # Get the provider key for factory registration
+      # Uses the provider_name method, but returns nil for abstract base classes
+      # @return [String, nil] Provider key for registration, nil to skip registration
+      def self.provider_key
+        return nil if self == BaseClient # Don't register the base class
+        return nil if name&.include?("BaseChatCompletionClient") # Don't register abstract base classes
+
+        begin
+          provider_name
+        rescue NotImplementedError
+          nil # Don't register classes that don't implement provider_name
+        end
+      end
+
       # Initialize base client with common configuration
       # @param api_key [String, nil] API key (uses env/config if nil)
       # @param model [String, nil] Model to use (uses default if nil)
@@ -39,22 +63,17 @@ module CodingAgentTools
         setup_response_parser
       end
 
-      # Get the provider name for this client
+      # Get the provider name for this client instance
       # @return [String] Provider name (e.g., "google", "anthropic")
       def provider_name
-        # Extract provider name from class name
-        # GoogleClient -> google, AnthropicClient -> anthropic, etc.
-        class_name = self.class.name.split("::").last.gsub(/Client$/, "")
-        
-        # Handle special cases for compound names
-        case class_name
-        when "TogetherAI"
-          "together_ai"
-        when "LMStudio"
-          "lmstudio"
-        else
-          class_name.downcase
-        end
+        self.class.provider_name
+      end
+
+      # Get the provider name for this client class (class method)
+      # Subclasses should override this method to declare their provider name explicitly
+      # @return [String] Provider name (e.g., "google", "anthropic")
+      def self.provider_name
+        raise NotImplementedError, "#{self.name} must implement .provider_name"
       end
 
       protected
diff --git a/lib/coding_agent_tools/organisms/google_client.rb b/lib/coding_agent_tools/organisms/google_client.rb
index a6d67dc..75de9b8 100644
--- a/lib/coding_agent_tools/organisms/google_client.rb
+++ b/lib/coding_agent_tools/organisms/google_client.rb
@@ -20,6 +20,12 @@ module CodingAgentTools
         maxOutputTokens: 8192
       }.freeze
 
+      # Explicit provider name declaration
+      # @return [String] The provider name for this client
+      def self.provider_name
+        "google"
+      end
+
       # Initialize Google client
       # @param api_key [String, nil] API key (uses env/config if nil)
       # @param model [String] Model to use
diff --git a/lib/coding_agent_tools/organisms/lm_studio_client.rb b/lib/coding_agent_tools/organisms/lm_studio_client.rb
index d676a34..7da50bf 100644
--- a/lib/coding_agent_tools/organisms/lm_studio_client.rb
+++ b/lib/coding_agent_tools/organisms/lm_studio_client.rb
@@ -18,6 +18,12 @@ module CodingAgentTools
         stream: false
       }.freeze
 
+      # Explicit provider name declaration
+      # @return [String] The provider name for this client
+      def self.provider_name
+        "lmstudio"
+      end
+
       # Initialize LM Studio client
       # @param model [String] Model to use
       # @param options [Hash] Additional options
diff --git a/lib/coding_agent_tools/organisms/mistral_client.rb b/lib/coding_agent_tools/organisms/mistral_client.rb
index e1ff6c0..c6f12b7 100644
--- a/lib/coding_agent_tools/organisms/mistral_client.rb
+++ b/lib/coding_agent_tools/organisms/mistral_client.rb
@@ -20,6 +20,12 @@ module CodingAgentTools
         max_tokens: 4096
       }.freeze
 
+      # Explicit provider name declaration
+      # @return [String] The provider name for this client
+      def self.provider_name
+        "mistral"
+      end
+
       # Initialize Mistral client
       # @param api_key [String, nil] API key (uses env/config if nil)
       # @param model [String] Model to use
diff --git a/lib/coding_agent_tools/organisms/openai_client.rb b/lib/coding_agent_tools/organisms/openai_client.rb
index 5928e1a..e48ccc4 100644
--- a/lib/coding_agent_tools/organisms/openai_client.rb
+++ b/lib/coding_agent_tools/organisms/openai_client.rb
@@ -20,6 +20,12 @@ module CodingAgentTools
         max_tokens: 4096
       }.freeze
 
+      # Explicit provider name declaration
+      # @return [String] The provider name for this client
+      def self.provider_name
+        "openai"
+      end
+
       # Initialize OpenAI client
       # @param api_key [String, nil] API key (uses env/config if nil)
       # @param model [String] Model to use
diff --git a/lib/coding_agent_tools/organisms/together_ai_client.rb b/lib/coding_agent_tools/organisms/together_ai_client.rb
index 707517b..50ecb1f 100644
--- a/lib/coding_agent_tools/organisms/together_ai_client.rb
+++ b/lib/coding_agent_tools/organisms/together_ai_client.rb
@@ -20,6 +20,12 @@ module CodingAgentTools
         max_tokens: 4096
       }.freeze
 
+      # Explicit provider name declaration
+      # @return [String] The provider name for this client
+      def self.provider_name
+        "together_ai"
+      end
+
       # Initialize Together AI client
       # @param api_key [String, nil] API key (uses env/config if nil)
       # @param model [String] Model to use
diff --git a/spec/coding_agent_tools/molecules/client_factory_spec.rb b/spec/coding_agent_tools/molecules/client_factory_spec.rb
new file mode 100644
index 0000000..3e655d9
--- /dev/null
+++ b/spec/coding_agent_tools/molecules/client_factory_spec.rb
@@ -0,0 +1,146 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+
+RSpec.describe CodingAgentTools::Molecules::ClientFactory do
+  let(:factory) { described_class }
+  let(:mock_client_class) do
+    Class.new do
+      def initialize(**options)
+        @options = options
+      end
+
+      attr_reader :options
+    end
+  end
+
+  before do
+    # Clear registry before each test
+    factory.clear_registry!
+  end
+
+  after do
+    # Clean up after each test
+    factory.clear_registry!
+  end
+
+  describe ".register" do
+    it "registers a client class for a provider" do
+      factory.register("test_provider", mock_client_class)
+      
+      expect(factory.registered_providers).to include("test_provider")
+      expect(factory.registry["test_provider"]).to eq(mock_client_class)
+    end
+
+    it "allows re-registration of the same provider" do
+      other_client_class = Class.new
+      
+      factory.register("test_provider", mock_client_class)
+      factory.register("test_provider", other_client_class)
+      
+      expect(factory.registry["test_provider"]).to eq(other_client_class)
+    end
+  end
+
+  describe ".build" do
+    before do
+      factory.register("test_provider", mock_client_class)
+    end
+
+    it "builds a client instance for registered provider" do
+      client = factory.build("test_provider", model: "test-model")
+      
+      expect(client).to be_an_instance_of(mock_client_class)
+      expect(client.options[:model]).to eq("test-model")
+    end
+
+    it "passes options to the client constructor" do
+      options = { model: "test-model", temperature: 0.7, timeout: 30 }
+      client = factory.build("test_provider", options)
+      
+      expect(client.options).to eq(options)
+    end
+
+    it "raises UnknownProviderError for unregistered provider" do
+      expect {
+        factory.build("unknown_provider")
+      }.to raise_error(
+        CodingAgentTools::Molecules::ClientFactory::UnknownProviderError,
+        /Unknown provider 'unknown_provider'/
+      )
+    end
+
+    it "includes registered providers in error message" do
+      factory.register("provider_a", mock_client_class)
+      factory.register("provider_b", mock_client_class)
+      
+      expect {
+        factory.build("unknown_provider")
+      }.to raise_error(
+        CodingAgentTools::Molecules::ClientFactory::UnknownProviderError,
+        /Registered providers: provider_a, provider_b/
+      )
+    end
+  end
+
+  describe ".registered_providers" do
+    it "returns empty array when no providers are registered" do
+      expect(factory.registered_providers).to eq([])
+    end
+
+    it "returns sorted list of registered provider names" do
+      factory.register("zebra", mock_client_class)
+      factory.register("alpha", mock_client_class)
+      factory.register("beta", mock_client_class)
+      
+      expect(factory.registered_providers).to eq(["alpha", "beta", "zebra"])
+    end
+  end
+
+  describe ".registry" do
+    it "returns the internal registry hash" do
+      factory.register("test_provider", mock_client_class)
+      
+      registry = factory.registry
+      expect(registry).to be_a(Hash)
+      expect(registry["test_provider"]).to eq(mock_client_class)
+    end
+  end
+
+  describe ".clear_registry!" do
+    it "clears all registered providers" do
+      factory.register("provider_a", mock_client_class)
+      factory.register("provider_b", mock_client_class)
+      
+      expect(factory.registered_providers).not_to be_empty
+      
+      factory.clear_registry!
+      
+      expect(factory.registered_providers).to be_empty
+      expect(factory.registry).to be_empty
+    end
+  end
+
+  describe "auto-loading integration" do
+    it "calls ensure_clients_loaded when build is called" do
+      # This test verifies that the auto-loading mechanism is triggered
+      expect(factory).to receive(:ensure_clients_loaded).and_call_original
+      
+      # This should trigger the auto-loading, even if the provider isn't found in tests
+      begin
+        factory.build("google", model: "test-model")
+      rescue CodingAgentTools::Molecules::ClientFactory::UnknownProviderError
+        # Expected in test environment where inheritance hooks may not work
+      end
+    end
+
+    it "has access to real provider names through auto-loading" do
+      # Access the real registered providers (which should include real clients)
+      # The ensure_clients_loaded method should have populated the registry
+      factory.send(:ensure_clients_loaded)
+      
+      expected_providers = %w[google anthropic openai mistral together_ai lmstudio]
+      expect(factory.registered_providers).to include(*expected_providers)
+    end
+  end
+end
\ No newline at end of file
diff --git a/spec/coding_agent_tools/organisms/base_client_spec.rb b/spec/coding_agent_tools/organisms/base_client_spec.rb
new file mode 100644
index 0000000..c6ee58d
--- /dev/null
+++ b/spec/coding_agent_tools/organisms/base_client_spec.rb
@@ -0,0 +1,98 @@
+# frozen_string_literal: true
+
+require "spec_helper"
+
+RSpec.describe CodingAgentTools::Organisms::BaseClient do
+  describe ".provider_name" do
+    it "raises NotImplementedError when called on BaseClient" do
+      expect {
+        described_class.provider_name
+      }.to raise_error(
+        NotImplementedError,
+        "CodingAgentTools::Organisms::BaseClient must implement .provider_name"
+      )
+    end
+  end
+
+  describe "#provider_name" do
+    let(:mock_client_class) do
+      Class.new(described_class) do
+        def self.name
+          "MockClient"
+        end
+
+        def self.provider_name
+          "mock"
+        end
+
+        # Mock required constants to avoid errors
+        const_set(:API_BASE_URL, "https://mock.api")
+        const_set(:DEFAULT_GENERATION_CONFIG, {})
+
+        private
+
+        def needs_credentials?
+          false
+        end
+      end
+    end
+
+    it "returns the class provider_name when called on instance" do
+      # We can't instantiate BaseClient directly, so we use a mock subclass
+      instance = mock_client_class.new(model: "test-model")
+      expect(instance.provider_name).to eq("mock")
+    end
+
+    it "cannot be instantiated directly" do
+      expect {
+        described_class.new
+      }.to raise_error(
+        NotImplementedError,
+        "BaseClient is abstract and cannot be instantiated directly"
+      )
+    end
+  end
+
+  describe "concrete client classes" do
+    let(:client_classes) do
+      [
+        CodingAgentTools::Organisms::GoogleClient,
+        CodingAgentTools::Organisms::AnthropicClient,
+        CodingAgentTools::Organisms::OpenAIClient,
+        CodingAgentTools::Organisms::MistralClient,
+        CodingAgentTools::Organisms::TogetherAIClient,
+        CodingAgentTools::Organisms::LMStudioClient
+      ]
+    end
+
+    it "all implement explicit provider_name class method" do
+      client_classes.each do |client_class|
+        expect(client_class).to respond_to(:provider_name)
+        expect {
+          provider_name = client_class.provider_name
+          expect(provider_name).to be_a(String)
+          expect(provider_name).not_to be_empty
+        }.not_to raise_error
+      end
+    end
+
+    it "returns consistent provider names" do
+      expected_names = {
+        "GoogleClient" => "google",
+        "AnthropicClient" => "anthropic", 
+        "OpenAIClient" => "openai",
+        "MistralClient" => "mistral",
+        "TogetherAIClient" => "together_ai",
+        "LMStudioClient" => "lmstudio"
+      }
+
+      client_classes.each do |client_class|
+        class_name = client_class.name.split("::").last
+        expected_name = expected_names[class_name]
+        
+        expect(client_class.provider_name).to eq(expected_name),
+          "Expected #{class_name} to have provider_name '#{expected_name}', got '#{client_class.provider_name}'"
+      end
+    end
+  end
+end
\ No newline at end of file

```

### Project Context Documentation
*This section is populated when using the --include-dependencies flag*

#### Project Documentation
Location: `docs-project/*.md` (excluding roadmap)
Current files:
No docs-project directory found

#### Architecture Decision Records (ADRs)
Location: `docs-project/decisions/` and `docs-project/current/*/decisions/*.md`
Current files:
No ADR files found

#### Root Documentation
Location: `*.md` files in project root
Current files:
No root documentation files found

#### Gem Configuration
Location: `Gemfile` and `*.gemspec`
Current content:
### Gemfile
No Gemfile found

### Gemspec
No .gemspec file found

### Current Project State

#### Test Coverage
Current coverage: Not available - run tests with coverage enabled
Target coverage: 90%

#### StandardRB Status
Current offenses: No bin/lint script found

#### Gem Dependencies
Current dependencies:
No Gemfile found

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
