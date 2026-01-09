---
id: v.0.2.0+task.45
title: Refactor LLM Query Integration Tests
scope: integration-tests
impact: Refactor existing integration tests for LLM queries into a single, unified spec file.
category: refactoring
exposes_to_end_user: false
status: done
---

## Task Objective

Consolidate all existing LLM query integration tests into a single file, `spec/integration/llm_query_integration_spec.rb`. This refactoring is necessary due to recent API changes that simplify the LLM query interface. The new unified test file should cover all previously supported providers (e.g., Google Gemini, LM Studio) and models, ensuring no test coverage is lost.

## Directory Audit

No new directories need to be created. This task involves modifying existing files and creating one new test file, while deleting others.

## Scope of Work

*   Create a new integration test file: `spec/integration/llm_query_integration_spec.rb`.
*   Migrate all relevant tests from existing provider-specific LLM query integration test files (e.g., `spec/integration/llm_gemini_query_integration_spec.rb`, `spec/integration/llm_lmstudio_query_integration_spec.rb`) into the new unified file.
*   Ensure that tests within `llm_query_integration_spec.rb` utilize different providers and models as appropriate, without duplicating behavior-specific tests.
*   Delete the old provider-specific integration test files after their content has been successfully migrated.
*   Delete any VCR cassettes that are no longer in use after the old test files are removed.

## Deliverables

*   `spec/integration/llm_query_integration_spec.rb`: A new, comprehensive integration test file covering all LLM query scenarios.
*   Deletion of obsolete test files (e.g., `spec/integration/llm_gemini_query_integration_spec.rb`, `spec/integration/llm_lmstudio_query_integration_spec.rb`).
*   Deletion of unused VCR cassette files associated with the deleted tests.

## Phases

1.  **Analysis and Planning (0.5 hours)**
    *   Review existing LLM query integration test files to understand their structure and test cases.
    *   Identify common patterns and unique scenarios that need to be preserved in the new unified file.
    *   Determine which VCR cassettes are associated with each test file.
2.  **Implementation (2 hours)**
    *   Create `spec/integration/llm_query_integration_spec.rb`.
    *   Copy and adapt test cases from old files into the new one.
    *   Ensure proper setup and teardown for different providers and models within the unified test file.
    *   Run tests iteratively to confirm functionality.
3.  **Cleanup (0.5 hours)**
    *   Delete the old `spec/integration/llm_<provider>-query_integration_spec.rb` files.
    *   Locate and delete unused VCR cassettes from `spec/cassettes/`.
4.  **Verification (0.5 hours)**
    *   Run the entire `spec/integration` suite to ensure no regressions.
    *   Confirm that all relevant LLM query behaviors are still covered.

## Implementation Plan

1.  **Create new spec file:**
    ```bash
    touch spec/integration/llm_query_integration_spec.rb
    ```
2.  **Migrate test logic:**
    *   Open `spec/integration/llm_gemini_query_integration_spec.rb` and `spec/integration/llm_lmstudio_query_integration_spec.rb`.
    *   Copy relevant `describe` and `context` blocks into `spec/integration/llm_query_integration_spec.rb`.
    *   Modify `it` blocks to use a common interface for `llm-query` and abstract provider/model selection where possible within tests (e.g., using `before` hooks or shared examples).
    *   Ensure each unique behavior is covered once, but with varying providers/models if applicable.
3.  **Delete old files:**
    ```bash
    rm spec/integration/llm_gemini_query_integration_spec.rb
    rm spec/integration/llm_lmstudio_query_integration_spec.rb
    ```
4.  **Delete unused cassettes:**
    *   Manually inspect `spec/cassettes/` for cassettes related to `llm_gemini_query` and `llm_lmstudio_query` and remove them. Use `git status` to verify deleted files. Example:
    ```bash
    rm spec/cassettes/llm_gemini_query_*.yml
    rm spec/cassettes/llm_lmstudio_query_*.yml
    ```

## Acceptance Criteria

*   The file `spec/integration/llm_query_integration_spec.rb` exists and contains all necessary integration tests for LLM queries.
*   The files `spec/integration/llm_gemini_query_integration_spec.rb` and `spec/integration/llm_lmstudio_query_integration_spec.rb` no longer exist.
*   All VCR cassettes specifically associated with the deleted `llm_gemini_query_integration_spec.rb` and `llm_lmstudio_query_integration_spec.rb` files have been removed from `spec/cassettes/`.
*   Running `bin/test spec/integration` passes without any failures or pending tests.
*   The combined test coverage of LLM query features is equivalent to or better than the sum of the individual old test files.
