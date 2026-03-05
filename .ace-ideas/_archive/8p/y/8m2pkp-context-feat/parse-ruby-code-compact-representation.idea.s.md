---
title: ACE Context Ruby Code Parsing and Compact Representation
filename_suggestion: feat-context-ruby-code-parsing
enhanced_at: 2025-11-03 17:03:01.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-12-09 00:55:25.000000000 +00:00
id: 8m2pkp
tags: []
created_at: '2025-11-03 17:02:59'
---

# ACE Context Ruby Code Parsing and Compact Representation

## Problem
AI agents working within the ACE ecosystem frequently need to understand the structure and intent of existing Ruby code to effectively plan new features, refactor, or debug. Currently, `ace-context` can load raw file content, but this often provides verbose, unstructured data that consumes valuable LLM tokens and requires the LLM to perform its own parsing and summarization. This leads to inefficient token usage, potential misinterpretations, and a lack of deterministic, structured code context for AI agents.

## Solution
Introduce a new context extension within the `ace-context` gem that specifically processes Ruby (`.rb`) files. This extension will parse Ruby code to extract key structural elements (classes, modules, methods, parameters, associated documentation/comments) and represent them in a highly compact, structured, and deterministic format. This 'code skeleton' will provide AI agents with a precise and token-efficient overview of the codebase relevant to their task, enabling better planning and execution.

## Implementation Approach
This feature will be implemented within the `ace-context` gem, adhering to the ATOM architecture pattern:

*   **Atoms**: `ruby_parser` (utilizing a robust Ruby parsing library like `parser` or `Ripper` to generate AST), `docstring_extractor` (to pull YARD docs or comments), `method_signature_formatter` (to create compact method signatures).
*   **Molecules**: `ruby_file_analyzer` (combines atoms to parse a single Ruby file and extract its core components), `code_structure_builder` (aggregates data from multiple files into a unified, compact representation).
*   **Organisms**: `ruby_context_loader` (orchestrates the molecules to process specified Ruby files or globs, integrating with `ace-context`'s existing context loading mechanisms and applying configuration).
*   **Models**: `ruby_code_structure` (immutable data models to represent parsed classes, modules, methods, and their attributes).

The CLI interface will be extended to allow specifying Ruby files or globs for context loading, e.g., `ace-context load --ruby-code 'lib/**/*.rb'`. Configuration will leverage `Ace::Core.config.get('ace', 'context', 'ruby_code_parser')` to define parsing depth, inclusion/exclusion rules (e.g., private methods, specific documentation types), and the desired output format (e.g., YAML, structured markdown).

## Considerations
-   **Determinism**: The output must be consistent across runs for the same input, crucial for AI agent reliability.
-   **Configurability**: Provide granular control over what code elements are extracted and how they are represented to allow agents to tailor context to specific tasks.
-   **Performance**: Efficiently parse large Ruby codebases without significant overhead.
-   **Output Format**: Determine the most effective compact representation for LLMs (e.g., a custom YAML structure, a highly structured markdown format, or a simple DSL).
-   **Integration with `ace-context`**: Ensure seamless integration with existing context types and the caching mechanism of `ace-context`.
-   **Error Handling**: Robust handling of malformed or unparseable Ruby files.

## Benefits
-   **Improved AI Context Quality**: Provides highly relevant, structured, and actionable code context directly to LLMs.
-   **Reduced Token Consumption**: Significantly lowers token usage by providing a compact code skeleton instead of raw file content.
-   **Enhanced AI Planning**: Enables AI agents to better understand the existing codebase's architecture and identify relevant areas for modification or extension.
-   **Deterministic Input**: Ensures consistent and predictable input for AI agents, leading to more reliable and accurate outputs.
-   **Extensibility**: Establishes a pattern for future language-specific context extensions within `ace-context`, aligning with the vision of making every development capability an installable gem.

---

## Original Idea

```
ace-context-ruby -> add a context extension that will alllow to use ace-context *.rb file or glob of files and return the document that represent the code in the most compact way possible -> we can work on this should we return methods and params group by classes, should we only documentation, should we use some fast llm to parse it and make it in single format, so when we are planning new feature we have the skeleton of the existing code in context
```