# Writing Development Guides

This guide outlines best practices for creating and maintaining the development guides located within the `coding-agent-workflow-toolkit/guides/` directory. These guides serve as the primary reference for project standards, processes, and technical approaches, intended for both human developers and AI agents collaborating on the project.

## Goal of Guides

The primary goal of these guides is to:
- Document established standards, best practices, and workflows.
- Ensure consistency across the project.
- Provide clear, actionable instructions and explanations.
- Serve as a reliable knowledge base for both human developers and AI agents.

## Core Principles

1.  **Clarity & Conciseness:** Write clearly and avoid ambiguity. Get straight to the point. Use simple language where possible.
2.  **Accuracy & Up-to-Date:** Ensure information is correct and reflects the current project state and decisions. Update guides promptly when processes or standards change.
3.  **Actionability:** Focus on providing practical, actionable advice and instructions. Explain the "how" and the "why".
4.  **Structure & Scanability:** Use clear headings, subheadings, lists, and code blocks to organize information logically. Make it easy for readers (human or AI) to quickly find relevant sections.
5.  **Consistency:** Use consistent terminology, formatting, and structure across all guides. Refer to terms defined in other guides or the main `project-management.md`.
6.  **Examples:** Provide concrete examples (code snippets, file structures, command outputs) to illustrate concepts and instructions.
7.  **Target Audience:** Write for both human developers (potentially new to the project) and AI agents. This means being explicit, structured, and providing sufficient context.

## Standard Guide Structure

While the specific sections will vary based on the guide's topic, aim for a general structure like this:

1.  **Title (`# Title`):** Clear and descriptive title.
2.  **Introduction/Goal:** Briefly state the purpose of the guide and what the reader will learn or understand after reading it.
3.  **Core Sections (Using `##` and `###`):** Break down the topic into logical sections with clear headings.
    *   Explain key concepts or principles first.
    *   Provide step-by-step instructions for processes.
    *   Detail standards or rules with rationale.
4.  **Examples:** Include well-formatted code blocks, file structure examples, or command outputs where appropriate. Use realistic (but potentially simplified) examples relevant to the toolkit's domain.
5.  **Best Practices/Tips:** Offer actionable advice or highlight common pitfalls.
6.  **Related Documentation:** Link to other relevant guides, workflow instructions, or templates using relative paths (e.g., `[Project Management Guide](project-management.md)`).

## Writing for Humans and AI

- **Structure is Key:** Use Markdown headings (`#`, `##`, `###`), lists (`*`, `-`, `1.`), and code blocks (```) consistently. AI agents parse structure effectively.
- **Explicit Instructions:** Use action verbs and clearly define steps.
- **Define Terminology:** If introducing a specific term, define it clearly or link to where it's defined.
- **Contextual Links:** Link to related guides or specific sections where appropriate to build a connected knowledge graph.
- **Code Examples:** Use clear, minimal, and correct code examples. Specify the language in fenced code blocks (e.g., ```ruby).

## Maintaining Guides

- **Review Regularly:** Periodically review guides for accuracy and relevance, especially when related processes change.
- **Update After Decisions:** If an ADR changes a standard or process, update the corresponding guide(s).
- **Refactor When Needed:** Don't hesitate to restructure or rewrite sections for clarity as the project evolves.

By adhering to these guidelines, we can build and maintain a high-quality set of development guides that effectively support the project's workflow and collaboration.