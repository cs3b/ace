---
id: v.0.2.0+task.7
status: pending
priority: medium
estimate: 11h # Adjusted estimate due to scope reduction
dependencies: ["v.0.2.0+task.6"]
---

# Implement Code Quality Improvements from Cheat-Sheet

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 lib/ exe/ spec/
```

_Result excerpt (will be filled during task execution):_

```
lib/
├── coding_agent_tools/
│   ├── atoms/
│   ├── cli/
│   ├── middlewares/ # Potentially new
│   ├── molecules/
│   ├── organisms/
│   ├── ecosystems/
│   ├── models/
│   ├── cli.rb
│   ├── cli_registry.rb
│   ├── error.rb
│   ├── notifications.rb # Potentially new
│   └── version.rb
├── coding_agent_tools.rb
exe/
├── coding_agent_tools
└── llm-gemini-query
spec/
├── atoms/
├── cli/
├── integration/
├── middlewares/ # Potentially new
├── molecules/
├── organisms/
├── support/
├── cassettes/
├── coding_agent_tools_spec.rb
├── spec_helper.rb
└── vcr_setup.rb
```

## Objective

Implement various code quality enhancements and best practices outlined in the `o3.code.review.md` (Code-Quality Cheat-Sheet). The goal is to improve the overall maintainability, robustness, developer experience, and adherence to established patterns within the `coding-agent-tools` gem. This includes refining error handling, standardizing library practices, and introducing observability for external HTTP calls using `dry-monitor`.

## Scope of Work

This task focuses on refactoring existing library code and test infrastructure as per the cheat-sheet, with modifications to use `dry-monitor` for observability and skipping Atom/Molecule consolidation. API key loading will be handled by a dedicated `env-reader` atom and is out of scope for this task.

-   **CLI Executable (`exe/llm-gemini-query` and others if applicable):**
    -   Replace duplicated `rescue => e; warn e.backtrace` blocks with a single `ErrorReporter.call(e, debug:)` (needs creation of `ErrorReporter`).
-   **Atoms & Molecules:**
    -   Leverage Faraday utilities more: let Faraday build query strings & merge headers—delete in-house URI/header code if any.
-   **Misc. Library Code:**
    -   Switch to Zeitwerk autoloading; remove ad-hoc `autoload` blocks.
    -   Use `URI.join` or `Addressable::URI` for URL assembly consistently.
    -   Refine exception handling: only re-wrap exceptions when adding real context; otherwise, re-raise the original.
-   **Tests:**
    -   Improve fixture hygiene: Hide helpers in `spec/support` (temp files, cassette helpers) so test bodies read like prose.
    -   Consider custom matchers for more readable expectations if beneficial.
-   **Observability:**
    -   Implement observability for external HTTP calls (e.g., Gemini API calls) using `dry-monitor` as Faraday middleware, allowing consuming applications to subscribe to events.

## Deliverables

#### Create

-   `lib/coding_agent_tools/error_reporter.rb` - A new module/class for centralized error reporting in executables.
-   `lib/coding_agent_tools/notifications.rb` - Module to manage the `Dry::Monitor::Notifications` instance.
-   `lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb` - New Faraday middleware for `dry-monitor` instrumentation.
-   Potentially new RSpec custom matchers in `spec/support/matchers/`.
-   Potentially new helper modules in `spec/support/`.

#### Modify

-   `exe/llm-gemini-query` (and any other executables): Refactor error handling.
-   Various Atom and Molecule classes (specifically HTTP-related ones): Switch to Faraday utils for query/header building.
-   `lib/coding_agent_tools.rb` (or relevant setup files): Implement Zeitwerk, remove old autoloads, potentially initialize `Notifications` module.
-   Files performing URL assembly: Switch to `URI.join` or `Addressable::URI`.
-   Files with custom exception wrapping: Refine logic.
-   `spec/spec_helper.rb` and relevant spec files: Reorganize helpers, potentially add custom matchers.
-   `lib/coding_agent_tools/organisms/gemini_client.rb` (and other Faraday clients): Integrate `FaradayDryMonitorLogger` middleware.
-   `Gemfile`: Add `zeitwerk`, `dry-monitor`, `dry-configurable` (for `dry-monitor` setup), and `addressable` if chosen for URIs.
-   `coding_agent_tools.gemspec`: Add `zeitwerk`, `dry-monitor`, `dry-configurable`, and `addressable` as dependencies if added.

## Phases

1.  **Setup & Tooling:** Implement `ErrorReporter`, switch to Zeitwerk. Add `zeitwerk`, `dry-monitor`, `dry-configurable` and `addressable` dependencies.
2.  **Core Library Refactoring:** Address Faraday usage, URL assembly, and exception wrapping.
3.  **Observability:** Implement `dry-monitor` Logging for External Calls via Faraday middleware.
4.  **Test Refinements:** Improve fixture hygiene and consider custom matchers.
5.  **Review & Testing:** Ensure all changes are covered by tests and maintain functionality.

## Implementation Plan

### Planning Steps

*   [ ] Review `o3.code.review.md` thoroughly to list all actionable code changes (excluding Atom/Molecule merge and ENV.fetch for API keys).
    > TEST: Checklist Creation
    > Type: Pre-condition Check
    > Assert: A detailed checklist of changes from `o3.code.review.md` is created.
    > Command: N/A (Manual review)
*   [ ] Design `ErrorReporter` module/class for CLI executables.
*   [ ] List all current `autoload` statements to be replaced by Zeitwerk.
*   [ ] Research `dry-monitor` basic usage, event registration/instrumentation, and integration as Faraday middleware. Define payload for HTTP request/response events.
*   [ ] Identify Faraday client instances where the `dry-monitor` middleware should be added.
*   [ ] Research `Addressable::URI` vs `URI.join` for common use cases in the project.

### Execution Steps

#### Phase 1: Setup & Tooling

-   [ ] Add `zeitwerk`, `dry-monitor`, `dry-configurable` to `Gemfile` and `coding_agent_tools.gemspec`.
    > TEST: Dependencies Added
    > Type: Action Validation
    > Assert: `zeitwerk`, `dry-monitor`, `dry-configurable` are listed in `Gemfile` and `.gemspec`.
    > Command: `grep "zeitwerk" Gemfile && grep "zeitwerk" coding_agent_tools.gemspec && grep "dry-monitor" Gemfile && grep "dry-monitor" coding_agent_tools.gemspec && grep "dry-configurable" Gemfile && grep "dry-configurable" coding_agent_tools.gemspec`
-   [ ] (Optional) Add `addressable` to `Gemfile` and `coding_agent_tools.gemspec` if chosen over `URI.join`.
-   [ ] Implement `ErrorReporter` module/class in `lib/coding_agent_tools/error_reporter.rb`.
    -   [ ] It should accept an exception and a debug flag.
    -   [ ] It should log the error message and backtrace (if debug enabled).
    > TEST: ErrorReporter Basic Functionality
    > Type: Action Validation
    > Assert: `ErrorReporter.call(StandardError.new("test"), debug: true)` outputs message and backtrace.
    > Command: `ruby -e "require './lib/coding_agent_tools/error_reporter'; CodingAgentTools::ErrorReporter.call(StandardError.new('test err'), debug: true)"`
-   [ ] Configure Zeitwerk for autoloading in `lib/coding_agent_tools.rb`.
    -   [ ] Remove all existing `autoload` statements from the codebase.
    > TEST: Zeitwerk Loading
    > Type: Action Validation
    > Assert: Core classes (e.g., `CodingAgentTools::Atoms::JSONFormatter`) can be loaded without explicit require after `require 'coding_agent_tools'`.
    > Command: `ruby -e "require './lib/coding_agent_tools'; puts CodingAgentTools::Atoms::JSONFormatter.inspect"`

#### Phase 2: Core Library Refactoring

-   [ ] Refactor `exe/llm-gemini-query` to use the new `ErrorReporter`.
    > TEST: CLI Error Handling Refactored
    > Type: Action Validation
    > Assert: `exe/llm-gemini-query` uses `ErrorReporter`.
    > Command: `grep ErrorReporter exe/llm-gemini-query`
-   [ ] Refactor HTTP-related Atoms/Molecules to prefer Faraday's built-in utilities for query string building and header merging over custom implementations.
    > TEST: Faraday Utilities Usage
    > Type: Action Validation
    > Assert: Custom URI/query building for Faraday requests is removed.
    > Command: `grep -E "URI\.encode_www_form|Faraday.*params" lib/coding_agent_tools/molecules/http_request_builder.rb` (check for appropriate usage, expecting removal of manual encoding if Faraday handles it)
-   [ ] Standardize URL construction using `URI.join` or `Addressable::URI`.
    > TEST: URL Assembly Standardization
    > Type: Action Validation
    > Assert: URL joining uses a standard library method.
    > Command: `grep -E "URI\.join|Addressable::URI\.join" lib/coding_agent_tools/**/*.rb`
-   [ ] Review and refactor exception re-wrapping. Only re-wrap to add context; otherwise, re-raise original.
    > TEST: Exception Handling Review
    > Type: Action Validation
    > Assert: `rescue => e` blocks are reviewed for appropriate re-wrapping or re-raising.
    > Command: Manual review of `rescue` blocks.

#### Phase 3: Observability: Implement `dry-monitor` Logging for External Calls

-   [ ] Create `lib/coding_agent_tools/notifications.rb` to initialize and provide access to a `Dry::Monitor::Notifications` instance (e.g., via `CodingAgentTools::Notifications.notifications`).
    > TEST: Notifications Module
    > Type: Action Validation
    > Assert: `CodingAgentTools::Notifications.notifications` returns a `Dry::Monitor::Notifications` instance.
    > Command: `ruby -e "require './lib/coding_agent_tools'; require './lib/coding_agent_tools/notifications'; puts CodingAgentTools::Notifications.notifications.inspect"`
-   [ ] Implement `FaradayDryMonitorLogger` middleware in `lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb`.
    -   [ ] It should accept a `Dry::Monitor::Notifications` instance and an optional event namespace (e.g., `gemini_api`).
    -   [ ] It should instrument an event like `"<namespace>.request.coding_agent_tools"` before the call. Payload should include: `method`, `url`, `headers`.
    -   [ ] It should instrument an event like `"<namespace>.response.coding_agent_tools"` after the call. Payload should include: `method`, `url`, `status`, `duration_ms`, `response_headers`, `error_class` (if an error occurred).
    > TEST: FaradayDryMonitorLogger Created
    > Type: File Existence
    > Assert: `lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb` exists.
    > Command: `test -f lib/coding_agent_tools/middlewares/faraday_dry_monitor_logger.rb`
-   [ ] Integrate the `FaradayDryMonitorLogger` middleware into relevant Faraday client instances (e.g., in `GeminiClient`), passing the notifications instance and appropriate namespace.
    > TEST: Dry::Monitor Middleware Integration in GeminiClient
    > Type: Action Validation
    > Assert: Faraday client in `GeminiClient` uses `FaradayDryMonitorLogger`.
    > Command: `grep FaradayDryMonitorLogger lib/coding_agent_tools/organisms/gemini_client.rb`

#### Phase 4: Test Refinements

-   [ ] Review `spec/support/` and existing specs for helpers that can be centralized or improved for readability.
    -   [ ] E.g., move VCR setup helpers fully into `spec/support/vcr_helpers.rb` if not already.
    > TEST: Test Helper Review
    > Type: Action Validation
    > Assert: `spec/support/` is organized and helpers are well-defined.
    > Command: `tree spec/support/`
-   [ ] Identify 1-2 areas where custom RSpec matchers could significantly improve test readability and implement them.
    > TEST: Custom Matcher Implementation
    > Type: Action Validation
    > Assert: At least one new custom matcher is created and used.
    > Command: `ls spec/support/matchers/` (expect new files if applicable)

#### Phase 5: Review & Testing

-   [ ] Run `standardrb --fix` and ensure all linting passes.
-   [ ] Run `bin/test` and ensure all tests pass, including integration tests.
    > TEST: Full Test Suite
    > Type: Action Validation
    > Assert: All tests pass (`bundle exec rspec`).
    > Command: `bin/test`

## Acceptance Criteria

-   [ ] AC 1: CLI executables use a centralized `ErrorReporter`.
-   [ ] AC 2: Faraday utilities are preferred for query/header building, reducing custom code.
-   [ ] AC 3: Zeitwerk is used for autoloading, and manual `autoload` calls are removed.
-   [ ] AC 4: URL assembly is standardized using `URI.join` or `Addressable::URI`.
-   [ ] AC 5: Exceptions are re-wrapped only to add meaningful context.
-   [ ] AC 6: External HTTP calls made via Faraday are instrumented with `dry-monitor` using a custom middleware, publishing request and response events.
-   [ ] AC 7: Test helper organization in `spec/support/` is improved.
-   [ ] AC 8: (Optional, if beneficial) 1-2 new custom RSpec matchers are introduced and used.
-   [ ] AC 9: Code passes linting with `standardrb`.
-   [ ] AC 10: All tests pass.

## Out of Scope

-   Implementing all items from "Process & Workflow" section of the cheat-sheet (e.g., pre-commit hooks, release tooling setup beyond gem dependencies). These can be separate tasks.
-   Adding RuboCop/Standard & SimpleCov thresholds to CI (this is CI configuration, not library code).
-   Writing new integration specs beyond those needed to verify refactors, unless existing coverage is insufficient for a modified area.
-   Large-scale architectural changes beyond Atom/Molecule consolidation.
-   Auditing and merging Atom classes into Molecules (deferred from original scope).
-   Specifics of API key loading (e.g., via `ENV.fetch`), as this will be handled by a dedicated `env-reader` atom.

## References

-   [Code-Quality Cheat-Sheet](docs-project/current/v.0.2.0-synapse/researches/o3.code.review.md)
-   [Zeitwerk Documentation](https://github.com/fxn/zeitwerk)
-   [dry-monitor Documentation](https://dry-rb.org/gems/dry-monitor/)
-   [dry-configurable Documentation](https://dry-rb.org/gems/dry-configurable/)
-   [Faraday Documentation](https://lostisland.github.io/faraday/)
-   [Addressable::URI Documentation](https://github.com/sporkmonger/addressable)