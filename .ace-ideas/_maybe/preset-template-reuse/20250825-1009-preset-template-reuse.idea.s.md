---

:input_tokens: 115031
:output_tokens: 1028
:total_tokens: 116059
:took: 3.548
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-25T09:09:39Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 115031
:cost:
  :input: 0.011503
  :output: 0.000411
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.011914
  :currency: USD
source: "legacy"
---


# Simplify Context Presets with Dynamic Template Loading

## Intention

To simplify the configuration of context presets in `.coding-agent/context.yml` by automatically loading templates from `docs/context/` based on the provided preset name, thereby reducing redundancy and improving maintainability.

## Problem It Solves

**Observed Issues:**
- Many context presets in `.coding-agent/context.yml` follow a repetitive pattern of embedding content directly from files.
- This leads to duplicated content and a large configuration file that is difficult to manage.
- The current system requires manual duplication of file content into the YAML configuration, which is error-prone and time-consuming.
- There is no automated way to link presets to their source template files.

**Impact:**
- Increased maintenance burden for configuration files.
- Higher risk of inconsistencies between configuration and source template files.
- Reduced developer productivity due to repetitive configuration tasks.
- Difficulty in discovering and utilizing existing contextual templates.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: Workflows should be self-contained, implying that context should be easily accessible and embedded where needed.
- **XML Template Embedding (ADR-002)**: The project already uses an XML-based system for embedding templates, suggesting a precedent for structured content inclusion.
- **Universal Document Embedding System (ADR-005)**: This ADR supports embedding various document types, which can be extended to include context files dynamically.
- **Consistent Path Standards (ADR-004)**: All document paths are relative to the project root, which is essential for reliably locating context templates.
- **ATOM Architecture**: Context loading can be treated as an "Ecosystem" or "Organism" level concern, orchestrating "Molecules" for file reading and "Atoms" for path resolution.

## Solution Direction

1. **Dynamic Preset Loading**: Modify the context loading mechanism to automatically look for a corresponding template file in `docs/context/` when a preset name is provided in `.coding-agent/context.yml`.
2. **Template Discovery Logic**: Implement logic to search for files named `{preset_name}.md` or `{preset_name}.yml` within the `docs/context/` directory.
3. **Content Embedding**: If a matching template file is found, read its content and embed it directly into the context configuration, effectively replacing the need for manual embedding.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact naming convention for context template files in `docs/context/` (e.g., `.md`, `.yml`, or both)?
2. How should conflicts be handled if a preset name matches both a file and a hardcoded configuration value?
3. What is the expected behavior if a specified preset file is not found in `docs/context/`?

**Open Questions:**
- Should this dynamic loading apply only to specific types of presets, or all presets in `.coding-agent/context.yml`?
- How will this change impact existing workflows that might rely on the current structure of `.coding-agent/context.yml`?
- What tooling or validation mechanisms should be put in place to ensure template existence and correct formatting?

## Assumptions to Validate

**We assume that:**
- The majority of context presets are indeed simple embeddings of existing files, making this simplification beneficial. - *Needs validation*
- Developers will follow a consistent naming convention for context template files in `docs/context/`. - *Needs validation*
- The performance impact of dynamically reading files during context loading is acceptable. - *Needs validation*

## Expected Benefits

- **Reduced Configuration Redundancy**: Eliminates the need to duplicate file content within `.coding-agent/context.yml`.
- **Improved Maintainability**: Simplifies the management of context presets by centralizing content in template files.
- **Enhanced Discoverability**: Makes it easier for users to find and utilize existing context templates.
- **Increased Developer Productivity**: Speeds up the process of defining new context presets.
- **Better Adherence to DRY Principle**: Avoids code and content duplication.

## Big Unknowns

**Technical Unknowns:**
- The precise implementation details of the dynamic loading mechanism and how it integrates with the existing `context` command.
- Potential edge cases in file path resolution or content parsing for various template formats.

**User/Market Unknowns:**
- How users will perceive this change in workflow – will it be intuitive?
- Will users adopt the new convention for creating context template files?

**Implementation Unknowns:**
- The effort required to refactor the existing `context` command or related modules.
- The impact on existing tests and the need for new test cases to cover dynamic loading.
- How to best document this new behavior for users and developers.
```

> SOURCE

```text
in context of presets in .coding-agent/context.yml - a lot of them follow the same pattern, we can simplify it - if there is a template in docs/context with the name user pass as preset - we should use it - .coding-agent/context.yml
```
