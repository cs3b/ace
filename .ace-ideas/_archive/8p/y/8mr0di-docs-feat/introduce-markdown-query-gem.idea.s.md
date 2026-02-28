---
title: Introduce ace-mq for querying Markdown documents
filename_suggestion: feat-docs-markdown-query
enhanced_at: 2025-11-28 00:15:44.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2025-12-09 00:53:15.000000000 +00:00
id: 8mr0di
tags: []
created_at: '2025-11-28 00:15:00'
---

# Introduce ace-mq for querying Markdown documents

## Problem
Currently, while `ace-docs` effectively manages documentation, there's a lack of a precise, programmatic mechanism to query specific sections or header levels within Markdown files. AI agents frequently need to extract exact pieces of information (e.g., a specific section of a guide, all H2 headers, content under a particular heading) without parsing the entire document or relying on fuzzy string matching. This inefficiency leads to agents processing more context than necessary, increasing token usage, and potentially reducing the accuracy and speed of their operations.

## Solution
Introduce a new `ace-*` gem, `ace-mq` (Markdown Query), which will provide `jq`-like and `yq`-like querying capabilities specifically tailored for Markdown documents. `ace-mq` would enable users and AI agents to specify queries to extract content based on structural elements such as header levels, section titles, block types (e.g., code blocks, lists), or even specific frontmatter fields (leveraging `ace-docs`'s frontmatter parsing capabilities). The tool would output structured data (e.g., JSON, YAML) representing the queried sections, making it easily consumable by other `ace-*` gems or AI agents.

## Implementation Approach
- **New Gem:** Create `ace-mq` as a new functional gem following the `ace-*` pattern, ensuring it has a dedicated CLI interface.
- **ATOM Architecture:**
    - **Atoms:** Develop pure functions for low-level Markdown parsing, such as `header_parser`, `block_type_identifier`, and `frontmatter_reader`.
    - **Molecules:** Combine atoms to identify and extract specific document structures, like `section_finder`, `header_level_filter`, and `code_block_extractor`.
    - **Organisms:** Orchestrate molecules to execute complex queries, forming a `markdown_query_engine` that can process a query string against a Markdown document and a `document_transformer` to format the output.
    - **Models:** Define immutable data structures to represent parsed Markdown components, such as `MarkdownDocument`, `Section`, `Header`, and `CodeBlock`.
- **CLI Interface:** Implement a `Thor`-based CLI (e.g., `ace-mq query <file> --path '$.sections[?(@.level == 2)]' --output json`) to ensure deterministic execution and consistent interaction for both human and AI users.
- **Integration:** Design `ace-mq` to integrate seamlessly with `ace-docs` for document loading and potentially `ace-context` for intelligent context chunking. Workflows in `ace-handbook` could leverage `ace-nav wfi://ace-mq/query-section?file=path/to/doc.md&section=Problem` for direct access to specific content.

## Considerations
- **Query Language Design:** Develop a clear, expressive, and robust query language for Markdown structures, potentially drawing inspiration from JSONPath or XPath, but adapted for Markdown's hierarchical nature.
- **Output Formats:** Support various output formats (JSON, YAML, raw Markdown, plain text) to accommodate diverse downstream tools and agent requirements.
- **Performance:** Optimize parsing and querying for efficiency, especially with large Markdown files.
- **Error Handling:** Provide clear and actionable error messages for invalid queries or non-existent paths.
- **Configuration:** Utilize `ace-support-core` for configuration, allowing project-specific query presets or default behaviors.

## Benefits
- **Improved AI Agent Efficiency:** Enables agents to precisely target and extract only the necessary information, significantly reducing token usage and improving the quality and relevance of their responses.
- **Enhanced Documentation Management:** Provides powerful programmatic access to documentation content, facilitating advanced automation and content analysis.
- **Deterministic Context Provisioning:** Ensures that agents receive consistent and accurate context based on explicit, verifiable queries, reducing ambiguity.
- **New `ace-*` Capability:** Adds a valuable, reusable tool to the ACE ecosystem, aligning with the project's vision of making every development capability an installable Ruby gem.
- **Facilitates `ace-handbook` Development:** Workflows and agents within `ace-handbook` can leverage `ace-mq` for dynamic content extraction from guides and instructions, making them more adaptable and powerful.

---

## Original Idea

```
ace markdown support -> mq similar to jq and yq - to query certain level of headers or only some sections
```