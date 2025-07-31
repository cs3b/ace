---
:input_tokens: 45658
:output_tokens: 1104
:total_tokens: 46762
:took: 4.462
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-07-31T07:00:48Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45658
:cost:
  :input: 0.004566
  :output: 0.000442
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005007
  :currency: USD
---

# Create-Path Task New Flag Handling

## Intention

To allow `create-path task-new` to accept undefined flags as attributes for a task's YAML metadata, or alternatively, to pass them as a single metadata string.

## Problem It Solves

**Observed Issues:**
- Flags for `create-path task-new` that are not explicitly defined (e.g., `--status`, `--priority`) are currently not handled, causing errors or being ignored.
- The current system lacks a flexible way to add arbitrary metadata to new tasks created via `create-path`.
- The need to extend task creation with custom attributes without modifying the core `create-path` command's flag definitions frequently.

**Impact:**
- Inability to easily assign custom, dynamic attributes like status, priority, or estimation to newly created tasks via the CLI.
- Workflows relying on dynamic task attributes are broken or require manual intervention.
- Inconsistent task metadata management, hindering automation and project tracking.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: Workflows should be executable without external context. Allowing dynamic metadata for task creation aligns with this by enabling workflows to define task attributes on the fly.
- **XML Template Embedding Architecture (ADR-002)**: While not directly related to flags, the need for flexible content embedding suggests a desire for flexible data handling.
- **Consistent Path Standards (ADR-004)**: The project values consistent and predictable handling of inputs, including command-line arguments.
- **Universal Document Embedding System (ADR-005)**: The desire for a unified system to handle different document types hints at a broader need for flexible data handling across the toolkit.
- **ATOM Architecture House Rules (ADR-011)**: New features should fit within the ATOM structure, suggesting that task metadata handling might involve Molecules or Organisms.
- **Tools Reference (`docs/tools.md`)**: The `create-path` tool is documented, and its functionality needs to align with the project's overall approach to CLI arguments and metadata.

## Solution Direction

1. **Treat Undefined Flags as YAML Attributes**: Dynamically capture any unrecognized flags and their values, then serialize them into the task's YAML metadata.
2. **Use `--metadata` Flag**: As a fallback or alternative, allow passing metadata as a single string (e.g., `--metadata "status:draft,priority:high,estimate:2h"`) that will be parsed into YAML attributes.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the most robust and least ambiguous way to parse arbitrary key-value pairs from undefined flags into a structured YAML format, especially considering potential naming conflicts with future defined flags?
2. How will this dynamic flag handling interact with the existing `create-path` command's defined flags (e.g., `--title`)? Should dynamic attributes be merged, overwritten, or cause an error if a name collision occurs?
3. What is the preferred order of precedence if the same metadata key is provided via an undefined flag and the `--metadata` string?

**Open Questions:**
- What specific YAML structure should be used within the task file to store these dynamically added attributes? Should it be a top-level `metadata:` key, or nested within existing YAML frontmatter?
- How should the tool handle potential errors during the parsing of dynamic flags into YAML (e.g., invalid values, type mismatches)?
- Should there be a limit on the number or complexity of dynamic attributes that can be passed?

## Assumptions to Validate

**We assume that:**
- The task creation process (likely managed by `dev-taskflow/current/`) can accommodate arbitrary metadata fields in its YAML structure. - *Needs validation*
- Users will benefit from the flexibility of adding custom task attributes without needing to update the `create-path` command itself. - *Needs validation*
- The parsing of undefined flags into metadata will not introduce significant ambiguity or parsing complexity that outweighs its benefits. - *Needs validation*

## Expected Benefits

- **Increased Flexibility**: Allows users to add custom task metadata dynamically without modifying the `create-path` tool's code.
- **Improved Workflow Integration**: Enables workflows to pass specific, context-dependent task attributes during creation.
- **Reduced Maintenance**: Avoids the need to constantly update `create-path`'s flag definitions for every potential new metadata field.
- **Enhanced Task Management**: Richer task metadata leads to better tracking, filtering, and automation.

## Big Unknowns

**Technical Unknowns:**
- The exact implementation details for capturing and parsing undefined flags into a reliable YAML structure.
- Potential conflicts or ambiguities if undefined flag names clash with future defined flags or internal YAML keys.

**User/Market Unknowns:**
- How frequently will users need to add arbitrary metadata fields to tasks?
- What are the most common types of custom metadata users would want to add?

**Implementation Unknowns:**
- The effort required to refactor `create-path` to support this dynamic flag parsing.
- The impact on existing tests and the need for new test cases to cover dynamic metadata handling.