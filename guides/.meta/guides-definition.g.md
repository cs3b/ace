# Writing Development Guides

This guide outlines best practices for creating and maintaining the development guides located within the `dev-handbook/guides/` directory. These guides serve as the primary reference for project standards, processes, and technical approaches, intended for both human developers and AI agents collaborating on the project.

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
5.  **Consistency:** Use consistent terminology, formatting, and structure across all guides. Refer to terms defined in other guides or the main [Project Management Guide](dev-handbook/guides/project-management.g.md).
6.  **Examples:** Provide concrete examples (code snippets, file structures, command outputs) to illustrate concepts and instructions.
7.  **Target Audience:** Write for both human developers (potentially new to the project) and AI agents. This means being explicit, structured, and providing sufficient context.
8.  **Language Modularity:** When a guide mixes language‑specific details with general advice, extract each language's specifics into a dedicated sub‑guide (e.g., `testing/ruby-rspec.md`, `security/rust.md`). Keep the parent guide language‑agnostic.

## File Naming Convention

All guide files must use the `.g.md` suffix to distinguish them from workflow instructions (which use `.wf.md`). This convention enables proper editor configuration and clear separation of content types.

### Naming Pattern
- **Format:** `<noun-phrase>.g.md`
- **Style:** Use noun-based naming that describes what the guide covers, avoiding action verbs
- **Examples:**
  - `coding-standards.g.md` (not `write-coding-standards.g.md`)
  - `testing-tdd-cycle.g.md` (not `implement-tdd-cycle.g.md`)
  - `release-publish.g.md` (not `publish-release.g.md`)
  - `debug-troubleshooting.g.md` (not `troubleshoot-issues.g.md`)

### Contrast with Workflow Instructions
Unlike workflow instructions (`.wf.md` files) which use verb-first naming to indicate actions:
- **Guides** document standards and knowledge: `security.g.md`, `performance.g.md`
- **Workflows** describe processes to execute: `commit.wf.md`, `fix-tests.wf.md`

This naming distinction helps both humans and AI agents quickly identify whether a file provides reference information (guide) or executable instructions (workflow).

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
5.  **Related Documentation:** Link to other relevant guides, workflow instructions, or templates using paths relative to the project root (e.g., `[Project Management Guide](dev-handbook/guides/project-management.g.md)`), **not** relative to the current file (e.g., `../project-management.g.md`).

## Language‑Specific Sub‑Guides

When splitting language‑dependent examples out of a general guide, follow these rules:

1. **Directory & File Names**  
   * Place sub‑guides in a directory that matches the parent guide’s slug.  
   * Use lower‑case filenames that match the language, e.g. `ruby.md`, `rust.md`, `typescript.md`.  
   * For testing, prefer more descriptive names such as `ruby-rspec.md` or `typescript-bun.md` when tool‑specific.

3. **Cross‑Linking**  
   * At the top of each sub‑guide add a short note:  
     ```markdown
     > This page is a language‑specific companion to [Testing Guide](dev-handbook/guides/testing.g.md)
     ```  
   * Add reciprocal links from the parent guide to its sub‑guides.

3. **Index Updates**  
   * Whenever you add or delete a sub‑guide, update `dev-handbook/guides/README.md` (or `index.md`) so the navigation tree stays accurate.

4. **Example Tree**

   ```
   guides
   ├── security.g.md
   └── security
       ├── ruby.md
       ├── rust.md
       └── typescript.md
   ```

## Writing for Humans and AI

- **Structure is Key:** Use Markdown headings (`#`, `##`, `###`), lists (`*`, `-`, `1.`), and code blocks (```) consistently. AI agents parse structure effectively.
- **Explicit Instructions:** Use action verbs and clearly define steps.
- **Define Terminology:** If introducing a specific term, define it clearly or link to where it's defined (using root-relative paths).
- **Contextual Links:** Link to related guides or specific sections where appropriate using root-relative paths to build a connected knowledge graph.
- **Use Standard Markdown Links:** When linking to other guides, workflow instructions, or project documents, always use the standard Markdown link format with proper file extensions e.g.: `[Writing Guides Guide](dev-handbook/guides/.meta/writing-guides-guide.md)`, `[Commit Workflow](dev-handbook/workflow-instructions/commit.wf.md)`. Avoid using just the path in backticks unless discussing the path itself.
- **Code Examples:** Use clear, minimal, and correct code examples. Specify the language in fenced code blocks (e.g., ```ruby).

## Checkbox Usage Guidelines

Guides are **informational and reference documents**, not actionable tasks. Proper checkbox usage is critical to prevent AI agents from treating guides as interactive checklists.

### ❌ Inappropriate Use (Don't Do This)

**Interactive Checklists in Guides:**
```markdown
## Security Review Process
- [ ] Check input validation
- [ ] Verify authentication
- [ ] Test authorization
```

This treats the guide as a task to be completed, which is incorrect.

### ✅ Appropriate Use (Do This Instead)

**Informational Bullet Points:**
```markdown
## Security Review Areas
- **Input Validation**: Check all user inputs are sanitized
- **Authentication**: Verify login mechanisms work correctly
- **Authorization**: Test that permissions are properly enforced
```

### ✅ Legitimate Checkbox Uses in Guides

**1. Template Examples:**
When showing what a task or checklist should look like:

```markdown
## Example Task Format
Here's how to structure implementation steps:

- [ ] Step 1: Implement feature A
- [ ] Step 2: Add tests for feature A
- [ ] Step 3: Update documentation
```

**2. Reference Templates:**
When providing copyable templates:

```markdown
## Pull Request Template
Copy this template for your PRs:

## Changes
- Implemented new feature

## Testing
- [ ] Unit tests added
- [ ] Integration tests updated
```

**Key Principle:** If the checkboxes are meant to be copied/used elsewhere or serve as examples, they're appropriate. If they suggest the guide itself should be "completed," they're inappropriate.

## Maintaining Guides

- **Review Regularly:** Periodically review guides for accuracy and relevance, especially when related processes change.
- **Run a Directory Audit before Large Refactors:** Use `tree -L 2 dev-handbook/guides` (or similar) to list the current structure, paste the excerpt into your refactor ticket, and build an explicit file‑manifest from it.
- **Update After Decisions:** If an ADR changes a standard or process, update the corresponding guide(s).
- **Refactor When Needed:** Don't hesitate to restructure or rewrite sections for clarity as the project evolves.

By adhering to these guidelines, we can build and maintain a high-quality set of development guides that effectively support the project's workflow and collaboration.
