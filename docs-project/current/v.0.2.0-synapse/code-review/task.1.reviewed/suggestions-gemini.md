# Comprehensive Documentation Review Analysis

## Executive Summary

This extensive diff introduces a significant new feature: LLM integration with Google Gemini, accessible via a new CLI command `exe/llm-gemini-query`. It follows the project's ATOM architecture, adding new Atom, Molecule, and Organism components. Key supporting changes include the adoption of Zeitwerk for autoloading, `dry-monitor` for observability, Faraday for HTTP requests, and VCR for robust API testing. The changes also enhance CI, developer experience (e.g., `.env.example`, improved build scripts), and add substantial new documentation (ADRs, guides, examples).

The primary documentation impact is the need to introduce these new features, explain their usage, document architectural decisions (Zeitwerk, `dry-monitor`, VCR strategy), and update existing architectural and setup guides to reflect new dependencies and configurations.

## Detailed Diff Analysis

### 1. New Features Added

*   **LLM Integration Framework (Google Gemini)**:
    *   New CLI command `exe/llm-gemini-query` for querying Google Gemini (default model `gemini-2.0-flash-lite`).
    *   Supports prompt input from string arguments or file paths (`--file` flag).
    *   Explicit output formatting (`--format text|json`).
    *   Debug mode (`--debug`) for verbose error output.
    *   Model parameter overrides (`--model`, `--temperature`, `--max-tokens`, `--system`).
    *   New ATOM components:
        *   **Atoms**: `EnvReader`, `HTTPClient`, `JSONFormatter`.
        *   **Molecules**: `APICredentials`, `HTTPRequestBuilder`, `APIResponseParser`.
        *   **Organisms**: `GeminiClient`, `PromptProcessor`.
    *   Centralized error reporting (`lib/coding_agent_tools/error_reporter.rb`).
    *   Observability framework (`lib/coding_agent_tools/notifications.rb`, `lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb`) using `dry-monitor`.
*   **Environment Configuration**:
    *   `.env.example` added for project root and `spec/` directory for API key and VCR configuration.
    *   `APICredentials` and `EnvReader` support loading from `.env` files.
*   **Testing Infrastructure**:
    *   VCR integration for API testing (`spec/support/vcr.rb`, `spec/support/env_helper.rb`, `spec/vcr_setup.rb`).
    *   CI-aware VCR configuration.
    *   VCR cassettes added (`spec/cassettes/`).
    *   New test helpers (`spec/support/process_helpers.rb`, `spec/support/matchers/*`).
    *   Extensive unit and integration tests for new components.
*   **Ruby Version Management**:
    *   `.tool-versions` file specifying Ruby `3.4.2`.

### 2. Existing Features Modified

*   **CLI Framework**:
    *   Enhanced to support the `llm query` command structure via `lib/coding_agent_tools/cli.rb` and `lib/coding_agent_tools/cli_registry.rb`.
*   **Build Process (`bin/build`)**:
    *   Added `bin/test` and `bin/lint` steps (restored/ensured).
    *   Added gem installation verification (`gem install --local` and `ruby -e "require 'coding_agent_tools'"`) after build.
*   **Test Execution (`bin/test`)**:
    *   Default RSpec format changed to `progress`.
*   **Release Command (`bin/rc`)**:
    *   Path to `get-current-release-path` script corrected to `.sh`.
*   **CI Workflow (`.github/workflows/ci.yml`)**:
    *   Added `RACK_ENV: test` environment variable.
    *   Added step to copy `.env.example` to `.env` for tests requiring its presence.
    *   Added `bin/setup` step before running tests and building the gem.
*   **Autoloading (`lib/coding_agent_tools.rb`)**:
    *   Switched from manual `autoload` to Zeitwerk for gem loading, with inflections for acronyms.

### 3. Architecture & Design Changes

*   **ATOM Architecture**: Strictly followed for new LLM components.
*   **Zeitwerk Autoloading**: Adopted for managing gem dependencies.
*   **`dry-monitor` for Observability**: Introduced for instrumenting HTTP calls.
*   **Faraday for HTTP Client**: Standardized HTTP client library.
*   **VCR for API Testing**: Implemented for robust, CI-friendly integration tests.
*   **Centralized Error Handling**: `ErrorReporter` module for CLI executables.
*   **CLI Command Registration**: Using `cli_registry.rb` to manage command registration, attempting to solve potential circular dependencies.
*   **Refactored `APICredentials`**: Made more generic, service-specific configuration moved to client (Organism) level.

### 4. Breaking Changes

*   **Ruby Version**: Implicitly, if projects consuming the gem were relying on an older Ruby version not compatible with 3.4.2 or new dependencies. `.tool-versions` suggests a strong preference for 3.4.2.
*   **`APICredentials` Refactoring**: If `APICredentials` was used directly by consumers in a way that relied on its previous Gemini-specific behavior (e.g., default `GEMINI_API_KEY` constant without explicit `env_key_name`), this could be a breaking change. The new `docs/refactoring_api_credentials.md` addresses this.

### 5. Dependencies & Infrastructure

*   **New Gems Added**:
    *   `faraday (~> 2.0)`
    *   `zeitwerk (~> 2.6)`
    *   `dry-monitor (~> 1.0)`
    *   `dry-configurable (~> 1.0)`
    *   `addressable (~> 2.8)`
    *   `webmock (~> 3.0)` (dev/test)
    *   `vcr (~> 6.0)` (dev/test)
*   **CI Workflow (`.github/workflows/ci.yml`)**: Updates to environment, setup steps.
*   **`.tool-versions`**: Enforces Ruby 3.4.2.
*   **`docs-dev` Submodule**: Updated to a new commit (50d49e4).

### 6. Internal Refactoring

*   **`APICredentials`**: As described, made more generic.
*   **HTTP Request Building**: Standardized on Faraday and `HTTPRequestBuilder`.
*   **Error Handling**: Introduction of `CodingAgentTools::Error` and `ErrorReporter`.
*   **Autoloading**: Switch to Zeitwerk.

## Architecture Decision Records Required

### New ADRs Needed

1.  **ADR-002: Zeitwerk for Autoloading**
    *   **Reason**: The project switched from manual `autoload` to Zeitwerk. This is a significant architectural change affecting how constants are loaded and how the project is structured.
    *   **Content**: Rationale (standardization, efficiency), benefits, implications (e.g., file/class naming conventions), and how inflections are handled for existing acronyms.
2.  **ADR-003: Observability with `dry-monitor`**
    *   **Reason**: Introduction of `dry-monitor` and a custom Faraday middleware (`FaradayDryMonitorLogger`) for instrumenting HTTP calls.
    *   **Content**: Decision to use `dry-monitor`, structure of the custom middleware, events published (e.g., `gemini_api.request.coding_agent_tools`), payload structure, and guidance for consumers on subscribing to these events.
3.  **ADR-004: Centralized CLI Error Reporting**
    *   **Reason**: Implementation of `ErrorReporter` module for consistent error handling in CLI executables.
    *   **Content**: Design of `ErrorReporter`, how it's used in executables like `exe/llm-gemini-query`, benefits of centralization (consistent output, debug mode handling).
4.  **ADR-005: HTTP Client Strategy with Faraday**
    *   **Reason**: Standardization on Faraday for HTTP communication and the creation of `HTTPClient` Atom and `HTTPRequestBuilder` Molecule.
    *   **Content**: Rationale for choosing Faraday, design of the Atom and Molecule for HTTP, middleware usage (e.g., Faraday's built-in JSON middleware, custom `FaradayDryMonitorLogger`).

### Existing ADRs to Update

*   **`ADR-001-CI-Aware-VCR-Configuration.md`** (New in this diff)
    *   **Change**: While new, ensure it fully reflects the implementation details in `spec/support/vcr.rb`, `spec/support/env_helper.rb`, and the new `spec/vcr_setup.rb` for subprocesses. The current ADR seems good but confirm against all VCR helper files.

## Comprehensive Documentation Update Plan

## 🔴 CRITICAL UPDATES (Must be done immediately)

*   [X] **`CHANGELOG.md`**: Update for version `0.2.0` (or the appropriate version for these features). The diff includes a very detailed entry for `[0.2.0+tasks.1]`, which seems to cover the scope of the provided diff. *Verify this entry fully captures all aspects of the diff.*
*   [X] **`README.md`**:
    *   Announce new `exe/llm-gemini-query` command in "Key Features" and "Core Commands".
    *   Add usage examples for `exe/llm-gemini-query`.
    *   Document `GEMINI_API_KEY` environment variable in "Configuration" section, mentioning `.env.example`.
    *   Update Ruby version requirement if changed by `.tool-versions`.
*   [X] **NEW FILE**: `docs/llm-integration/gemini-query-guide.md` (or similar path like `docs/features/gemini-query.md`).
    *   Detailed guide on using `exe/llm-gemini-query`.
    *   Explain all CLI options (`--prompt`, `--file`, `--format`, `--debug`, `--model`, `--temperature`, `--max-tokens`, `--system`).
    *   API key setup using `.env` and `GEMINI_API_KEY`.
    *   Example use cases.
*   [X] **`docs/testing-with-vcr.md`** (New in diff): Review thoroughly for accuracy against the implemented VCR setup (`spec/support/vcr.rb`, `spec/support/env_helper.rb`, `spec/vcr_setup.rb`). Ensure it covers:
    *   CI-aware recording mode.
    *   API key setup (`spec/.env.example`) for recording.
    *   Filtering of sensitive data.
    *   Subprocess testing with VCR (if applicable to general users/contributors, otherwise internal dev note).
*   [X] **`docs/refactoring_api_credentials.md`** (New in diff): Review for clarity and accuracy on how `APICredentials` works with `EnvReader` and its generic nature. Include usage examples (already present in diff).
*   [X] **`.env.example` (Root and `spec/`)**: Ensure comments clearly explain each variable.

## 🟡 HIGH PRIORITY UPDATES (Should be done soon)

*   [X] **`docs-project/architecture.md`**:
    *   Update "ATOM-Based Code Structure" to reflect new Atoms (`EnvReader`, `HTTPClient`, `JSONFormatter`), Molecules (`APICredentials`, `HTTPRequestBuilder`, `APIResponseParser`), and Organisms (`GeminiClient`, `PromptProcessor`).
    *   Add new sections/mentions for cross-cutting concerns or new architectural elements:
        *   Zeitwerk for autoloading.
        *   `dry-monitor` and `FaradayDryMonitorLogger` for observability.
        *   `ErrorReporter` for CLI error handling.
        *   `cli_registry.rb` for command registration.
        *   New `exe/` executables like `llm-gemini-query`.
    *   Update "File Organization" for new `lib/` subdirectories (e.g., `middlewares/`, `notifications.rb`), `exe/llm-gemini-query`.
    *   Update "Dependencies" (Runtime) with Faraday, Zeitwerk, dry-monitor, dry-configurable, addressable.
    *   Update "Dependencies" (Development) with VCR, WebMock.
    *   Update "Key Commands (as per PRD)" section to reflect `exe/llm-gemini-query` and its relation to the main `coding_agent_tools llm query` command.
*   [X] **`docs-project/blueprint.md`**:
    *   Update "Project Organization" for new `lib/` subdirectories, `exe/`.
    *   Update "Technology Stack" with new gems.
    *   Update "Entry Points" and "Common Workflows" to include `exe/llm-gemini-query`.
    *   Update "Dependencies" (Runtime & Development).
*   [X] **`docs/SETUP.md`**:
    *   Update Ruby version to 3.4.2 based on `.tool-versions`.
    *   Mention `.env.example` and `GEMINI_API_KEY` setup for development (especially for VCR recording).
    *   Mention new dependencies like Faraday if they have specific setup notes (unlikely for these).
*   [X] **`docs/DEVELOPMENT.md`**:
    *   Update "Testing Strategy" to detail VCR usage for API integration tests, or link prominently to `docs/testing-with-vcr.md`.
    *   Mention `.env` setup in `spec/` for API tests.
    *   Update "Build System Commands" if `bin/build` changes (gem installation verification) are significant for developer workflow.
    *   Mention new architectural patterns (Zeitwerk, `dry-monitor`).
*   [X] **NEW ADRs**: Create ADRs for Zeitwerk, `dry-monitor` observability, CLI Error Reporting, and Faraday HTTP Client Strategy as detailed in Phase 2.

## 🟢 MEDIUM PRIORITY UPDATES (Should be done eventually)

*   [ ] **`docs-project/what-do-we-build.md`**:
    *   Update "Key Features" to reflect that LLM communication with Gemini is now implemented.
    *   Update "What We Build" to list the new ATOM components and CLI tool.
*   [X] **NEW FILE**: `examples/llm_gemini_query_usage.rb` (or update existing examples).
    *   Provide programmatic examples if `GeminiClient` or other organisms are intended for library use. The diff adds `examples/generic_api_credentials.rb` which is good. Consider one for `GeminiClient`.
*   [ ] **CLI Command Help Text**: Ensure `dry-cli` generates accurate and helpful text for `llm query` and its options, and that `exe/llm-gemini-query --help` (with its output rewriting) is clear.

## 🔵 LOW PRIORITY UPDATES (Nice to have)

*   [ ] Review all existing documentation for minor wording tweaks or updates related to new dependencies or slight workflow changes (e.g., `bin/test --format progress`).
*   [x] Update CI badge URL in `README.md` (already done in diff).

## Detailed Implementation Specifications

#### `README.md`

*   **Section to Update**: "Key Features"
    *   **Required Changes**: Add a bullet point for "Google Gemini LLM Integration via `exe/llm-gemini-query`."
*   **Section to Update**: "Core Commands (Planned Structure)" (or a new "Available Commands" section)
    *   **Required Changes**: Add an entry for `exe/llm-gemini-query`.
    *   **New Content Suggestions**:
        ```markdown
        ### New Standalone Commands
        *   `exe/llm-gemini-query`: Directly query the Google Gemini API.
            *   Usage: `exe/llm-gemini-query "Your prompt" [--file] [--format json|text] [--model MODEL_NAME] [--temperature TEMP] [--max-tokens TOKENS] [--system "SYSTEM_PROMPT"] [--debug]`
            *   Example: `exe/llm-gemini-query "What is Ruby?"`
            *   See `docs/llm-integration/gemini-query-guide.md` for full details.
        ```
*   **Section to Update**: "Configuration" / "API Keys"
    *   **Required Changes**: Add information about `GEMINI_API_KEY`.
    *   **New Content Suggestions**:
        ```markdown
        ### API Keys
        *   **Google Gemini**: Set the `GEMINI_API_KEY` environment variable. You can place this in an `.env` file in the project root. See `.env.example`.
          ```bash
          # In .env file
          GEMINI_API_KEY="your_actual_gemini_api_key_here"
          ```
        ```
*   **Section to Update**: "Requirements"
    *   **Required Changes**: Update Ruby version to "Ruby >= 3.4.2 (or as per `.tool-versions`)"
*   **Section to Update**: "Development" / "Quick Start"
    *   **Required Changes**: Mention copying `spec/.env.example` to `spec/.env` and adding API key for running tests that record VCR cassettes.
*   **Section to Update**: "Architecture"
    *   **Required Changes**: Briefly mention new core components like Faraday, Zeitwerk, and VCR for testing. Link to the updated `docs-project/architecture.md`.

#### NEW FILE: `docs/llm-integration/gemini-query-guide.md`

*   **Content Suggestions**:
    *   **Introduction**: Purpose of `exe/llm-gemini-query`.
    *   **Setup**:
        *   API Key: How to get a `GEMINI_API_KEY`, where to put it (`.env` file, environment variable). Reference `.env.example`.
    *   **Basic Usage**:
        *   Querying with a string prompt: `exe/llm-gemini-query "What is the meaning of life?"`
        *   Querying with a file prompt: `exe/llm-gemini-query path/to/prompt.txt --file`
    *   **Output Formats**:
        *   Default (text): `exe/llm-gemini-query "Prompt"`
        *   JSON format: `exe/llm-gemini-query "Prompt" --format json` (show example JSON output structure).
    *   **Advanced Options**:
        *   `--model <MODEL_NAME>`: e.g., `gemini-pro`, `gemini-2.0-flash-lite` (default).
        *   `--temperature <FLOAT>`: Explain effect (0.0-2.0).
        *   `--max-tokens <INTEGER>`: Explain effect.
        *   `--system <STRING>`: Explain system prompt usage.
        *   `--debug`: Explain verbose error output.
    *   **Examples**: Combine multiple options.
    *   **Troubleshooting**: Common errors (API key issues, file not found).

#### `docs-project/architecture.md`

*   **Section to Update**: "ATOM-Based Code Structure in `lib/coding_agent_tools/`"
    *   **Required Changes**:
        *   Ensure `EnvReader`, `HTTPClient`, `JSONFormatter` are listed under Atoms.
        *   Ensure `APICredentials`, `HTTPRequestBuilder`, `APIResponseParser` are listed under Molecules.
        *   Ensure `GeminiClient`, `PromptProcessor` are listed under Organisms.
        *   Add new top-level directories/concepts if applicable:
            *   `middlewares/` (e.g., `FaradayDryMonitorLogger`) - explain its role.
            *   `notifications.rb` (`Dry::Monitor::Notifications` wrapper) - explain its role.
            *   `error_reporter.rb` - explain its role for CLI executables.
            *   `cli_registry.rb` - explain its role in `dry-cli` command registration.
*   **Section to Update**: "File Organization"
    *   **Required Changes**: Add entries for:
        *   `exe/llm-gemini-query`
        *   `lib/coding_agent_tools/atoms/env_reader.rb`, `http_client.rb`, `json_formatter.rb`
        *   `lib/coding_agent_tools/molecules/api_credentials.rb`, `http_request_builder.rb`, `api_response_parser.rb`
        *   `lib/coding_agent_tools/organisms/gemini_client.rb`, `prompt_processor.rb`
        *   `lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb`
        *   `lib/coding_agent_tools/notifications.rb`
        *   `lib/coding_agent_tools/error_reporter.rb`
        *   `lib/coding_agent_tools/cli_registry.rb`
        *   `spec/cassettes/`
        *   `spec/support/env_helper.rb`, `vcr.rb`, `process_helpers.rb`, `matchers/*`
        *   `spec/vcr_setup.rb`
        *   `.env.example` (root and `spec/`)
        *   `.tool-versions`
*   **Section to Update**: "Development Patterns"
    *   **Required Changes**: Add a sub-section for "Testing with VCR" and "Observability with dry-monitor".
*   **Section to Update**: "Dependencies" / "Runtime Dependencies"
    *   **Required Changes**: Add `faraday`, `zeitwerk`, `dry-monitor`, `dry-configurable`, `addressable`.
*   **Section to Update**: "Dependencies" / "Development Dependencies"
    *   **Required Changes**: Add `vcr`, `webmock`.

#### `docs/SETUP.md`

*   **Section to Update**: "Prerequisites" / "Required"
    *   **Required Changes**: Update Ruby version to `3.4.2` (as specified in `.tool-versions`).
*   **Section to Update**: "Configuration" / "API Keys (Optional)"
    *   **Required Changes**: Specifically mention `GEMINI_API_KEY` and `.env.example` for setting it up for development, especially if developers want to record new VCR cassettes.
    *   **New Content Suggestions**: "For features interacting with external APIs like Google Gemini, you'll need an API key to record new test interactions (VCR cassettes). Copy `.env.example` to `.env` and fill in your `GEMINI_API_KEY`."

#### `docs/DEVELOPMENT.md`

*   **Section to Update**: "Testing Strategy" / "Integration Tests" (or new subsection)
    *   **Required Changes**: Explain the use of VCR for API integration tests. Link to `docs/testing-with-vcr.md`.
    *   **New Content Suggestions**: "API-dependent integration tests (e.g., in `spec/integration/`) use VCR to record and replay HTTP interactions. This ensures tests are fast, deterministic, and don't require live API keys in CI. See `docs/testing-with-vcr.md` for details on running and recording VCR tests."
*   **Section to Update**: "Build System Commands" / `bin/build`
    *   **Required Changes**: Mention the new gem installation verification step.
    *   **New Content Suggestions**: "The `bin/build` script now also includes a step to locally install the built gem and verify it can be required, providing an extra layer of confidence before publishing."

#### NEW ADR: Zeitwerk for Autoloading (ADR-002)

*   **Context**: Project previously used manual `autoload`. Switched to Zeitwerk for more standard and robust autoloading.
*   **Decision**: Adopt Zeitwerk. Configure inflector for existing acronym-based class names (e.g., `HTTPClient` from `http_client.rb`).
*   **Consequences**: Standardized loading, adherence to Rails/Ruby community best practices. Requires correct file naming. Simplifies `require` statements.
*   **Alternatives**: Stick with manual `autoload`, use `require_relative` extensively.

#### NEW ADR: Observability with `dry-monitor` (ADR-003)

*   **Context**: Need to instrument key operations, starting with external HTTP calls, for better debugging and potential monitoring.
*   **Decision**: Use `dry-monitor` via a central `CodingAgentTools::Notifications` instance. Implement `FaradayDryMonitorLogger` as Faraday middleware to publish request/response events.
*   **Consequences**: Provides a standardized way to subscribe to internal gem events (e.g., `gemini_api.request.coding_agent_tools`). Consumers can log these, monitor performance, etc. Adds `dry-monitor` and `dry-configurable` dependencies.
*   **Alternatives**: Custom logger, other monitoring libraries.

#### NEW ADR: Centralized CLI Error Reporting (ADR-004)

*   **Context**: Need for consistent error output format for CLI executables, especially with a `--debug` flag for more verbose output.
*   **Decision**: Implement `CodingAgentTools::ErrorReporter` module. CLI executables (e.g., `exe/llm-gemini-query`) should rescue general exceptions and pass them to `ErrorReporter.call(e, debug: debug_flag)`.
*   **Consequences**: Consistent user experience for errors. Simplifies error handling logic in individual executables.
*   **Alternatives**: Each executable handles its own error formatting.

#### NEW ADR: HTTP Client Strategy with Faraday (ADR-005)

*   **Context**: Need a robust and flexible HTTP client for API interactions.
*   **Decision**: Standardize on Faraday. Create `Atoms::HTTPClient` for basic GET/POST using Faraday. Create `Molecules::HTTPRequestBuilder` to compose `HTTPClient` and provide higher-level request building (e.g., `json_request`). Use Faraday middleware for common tasks (JSON encoding/decoding, custom logging).
*   **Consequences**: Consistent HTTP request handling. Leverage Faraday's ecosystem of adapters and middleware. Adds Faraday dependency.
*   **Alternatives**: Net::HTTP directly, other HTTP client gems.

## Cross-Reference Update Map

*   `README.md`:
    *   Link "ATOM-based hierarchy" to `docs-project/architecture.md#atom-based-code-structure-in-libcoding_agent_tools`.
    *   Link `exe/llm-gemini-query` usage to `docs/llm-integration/gemini-query-guide.md`.
    *   Link `GEMINI_API_KEY` setup to `docs/llm-integration/gemini-query-guide.md#setup`.
*   `docs-project/architecture.md`:
    *   Link "Testing Framework" to `docs/testing-with-vcr.md` when discussing integration tests.
    *   Link "Decision Records" to the new ADRs.
*   `docs/DEVELOPMENT.md`:
    *   Link "Testing Strategy" (for integration tests) to `docs/testing-with-vcr.md`.
*   `docs/SETUP.md`:
    *   Link API key setup to `docs/testing-with-vcr.md#api-key-setup-development-only` or `docs/llm-integration/gemini-query-guide.md#setup`.

## Quality Assurance Validation

**Completeness**
- [X] All diff changes have corresponding documentation updates (planned).
- [X] All new features have usage examples (planned for `llm-gemini-query`, `APICredentials` has one).
- [X] All breaking changes are clearly documented (API Credentials refactoring documented).
- [X] All deprecated functionality is marked with migration paths (N/A for this diff).

**Accuracy**
- [X] All code examples are syntactically correct (to be verified upon writing).
- [X] All CLI examples use correct syntax (to be verified upon writing).
- [X] All links and references are functional (to be verified upon writing).
- [X] All version numbers and dates are correct (CHANGELOG looks good).

**Consistency**
- [X] Documentation style matches project guidelines (to be maintained).
- [X] Terminology is consistent across all documents (to be maintained).
- [X] Cross-references between documents are updated (planned).
- [X] Formatting follows established patterns (to be maintained).

**User Experience**
- [X] Changes are explained from user perspective (planned for guides).
- [X] Migration paths are clear and actionable (`refactoring_api_credentials.md`).
- [X] Examples are practical and realistic (planned).
- [X] Documentation remains accessible to target audience (to be maintained).

## Risk Assessment

*   **Outdated Information**: If documentation is not updated comprehensively, users and developers will encounter discrepancies between docs and actual behavior, leading to confusion and errors.
*   **Onboarding Difficulty**: New developers will struggle if architectural changes (Zeitwerk, new components) are not reflected in `architecture.md` and `blueprint.md`.
*   **Incorrect Usage**: Users might misuse the new `llm-gemini-query` command or fail to configure API keys correctly if `README.md` and the new guide are missing or inaccurate.
*   **Testing Issues**: Developers might struggle with VCR if `testing-with-vcr.md` is not accurate or if `spec/.env.example` is unclear.

## Implementation Timeline Recommendation

1.  **Immediately (Post-Merge)**:
    *   Verify/Update `CHANGELOG.md`.
    *   Update `README.md` with critical info on `llm-gemini-query` and API key setup.
    *   Create and publish `docs/llm-integration/gemini-query-guide.md`.
    *   Publish/Verify `docs/testing-with-vcr.md` and `docs/refactoring_api_credentials.md`.
2.  **Within 1-2 Sprints**:
    *   Update `docs-project/architecture.md` and `docs-project/blueprint.md`.
    *   Update `docs/SETUP.md` and `docs/DEVELOPMENT.md`.
    *   Write and publish all new ADRs.
3.  **Ongoing/As Needed**:
    *   Add more code examples.
    *   Refine CLI help text details.
    *   Review and update `docs-project/what-do-we-build.md`.

## Additional Recommendations

*   **Automated Link Checking**: Implement a CI step to check for broken internal markdown links.
*   **Documentation Versioning**: As the project grows, consider versioning documentation alongside gem versions, especially for user-facing guides.
*   **Live Examples**: For CLI tools, consider using a tool that can embed and verify CLI command outputs directly in the documentation (e.g., `sphinx-exec-directive` if using Sphinx, or custom scripts).
*   **Glossary**: As new architectural terms (Zeitwerk, dry-monitor, VCR cassettes) are introduced, a project glossary in `docs/` might become beneficial.
