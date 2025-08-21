---
:input_tokens: 91350
:output_tokens: 917
:total_tokens: 92267
:took: 3.226
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-21T22:49:20Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 91350
:cost:
  :input: 0.009135
  :output: 0.000367
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.009502
  :currency: USD
---

# Enhance `code-review` command to list system prompt components

## Intention

The `code-review` command should provide a way to list all available system prompt components, so users don't have to manually scan the `lib/coding_agent_tools/organisms/code/review_prompts/` directory.

## Problem It Solves

**Observed Issues:**
- Users need to manually navigate the file system to discover available system prompt components for code reviews.
- Discoverability of prompt components is low, leading to potential underutilization of available review strategies.
- Lack of a centralized command to list these components makes it hard for users to understand the full capabilities of the `code-review` tool.

**Impact:**
- Increased time and effort for users to find and select appropriate review prompts.
- Potential for users to miss out on specialized review prompts that could improve code quality.
- Inconsistent user experience due to the manual discovery process.

## Key Patterns from Reflections

- **CLI Tool Pattern**: The project has established patterns for CLI tools, including clear commands, flags, and output formats. Existing tools like `task-manager` and `llm-query` provide examples of how to list available resources.
- **ATOM Architecture**: Prompt components are likely organized within the `lib/coding_agent_tools/organisms/code/review_prompts/` directory, following the ATOM principles.
- **Metadata Extraction**: Components often have associated metadata (e.g., descriptions, usage) that could be surfaced by a listing command.
- **Extensibility**: The system is designed to be extensible, so a listing mechanism should easily accommodate new prompt components.

## Solution Direction

1. **Add a `list` subcommand to `code-review`**: This subcommand will be responsible for discovering and displaying available system prompt components.
2. **Implement Discovery Logic**: The `list` subcommand will scan the `lib/coding_agent_tools/organisms/code/review_prompts/` directory for prompt components.
3. **Display Formatted Output**: The discovered components will be presented to the user in a clear, human-readable format, potentially including descriptions or categories.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact directory structure where system prompt components are stored? (Current understanding points to `lib/coding_agent_tools/organisms/code/review_prompts/`)
2. What metadata should be displayed for each prompt component (e.g., filename, description, category)?
3. Should there be any filtering or sorting options for the listing command (e.g., by category, alphabetical order)?

**Open Questions:**
- How should prompt components be structured to allow for easy metadata extraction (e.g., using YAML front matter, class methods)?
- What should the default output format be for the `list` subcommand?
- How will this feature be tested, particularly regarding the discovery of prompt components?

## Assumptions to Validate

**We assume that:**
- System prompt components are stored in a predictable directory structure within the `dev-tools` gem. - *Needs validation*
- Each prompt component has some form of discoverable metadata (e.g., a class method or file naming convention) that can be used to describe it. - *Needs validation*
- Users will find value in a dedicated command to list these components, rather than manually browsing the file system. - *Needs validation*

## Expected Benefits

- Improved discoverability of system prompt components for code reviews.
- Reduced time and effort for users to select appropriate review prompts.
- Increased utilization of the `code-review` tool's full capabilities.
- Enhanced user experience through a more intuitive and informative CLI.

## Big Unknowns

**Technical Unknowns:**
- The precise mechanism for extracting metadata from prompt components needs to be finalized.
- Potential issues with Zeitwerk or other autoloading mechanisms if prompt components are not loaded correctly during discovery.

**User/Market Unknowns:**
- How users will prefer to filter or sort the list of prompt components.

**Implementation Unknowns:**
- The exact implementation details of the `list` subcommand and its interaction with the existing `code-review` command structure.
- The testing strategy for ensuring the discovery mechanism remains accurate as new prompts are added.
```

> SOURCE

```text
code-review should list all availble system prompt components, so we don't have to scan the whole directory
```
