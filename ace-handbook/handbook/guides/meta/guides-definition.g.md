---
doc-type: guide
title: Writing Development Guides
purpose: Documentation for ace-handbook/handbook/guides/meta/guides-definition.g.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Writing Development Guides

This guide outlines best practices for creating and maintaining the development guides located within the handbook guides directory. These guides serve as the primary reference for project standards, processes, and technical approaches, intended for both human developers and AI agents collaborating on the project.

## Goal of Guides

The primary goal of these guides is to:
- Document established standards, best practices, and workflows.
- Ensure consistency across the project.
- Provide clear, actionable instructions and explanations.
- Serve as a reliable knowledge base for both human developers and AI agents.

## Core Principles

1.  **Conceptual Focus:** Guides explain the "Why" - principles, concepts, standards, and best practices. Workflows explain the "How" - step-by-step procedural instructions. Guides should focus on understanding and decision-making rather than execution.
2.  **Clarity & Conciseness:** Write clearly and avoid ambiguity. Get straight to the point. Use simple language where possible.
3.  **Accuracy & Up-to-Date:** Ensure information is correct and reflects the current project state and decisions. Update guides promptly when processes or standards change.
4.  **Conceptual Actionability:** Provide practical advice, principles, and context that help readers understand what to do and why, while linking to self-contained workflows for specific execution steps.
5.  **Structure & Scanability:** Use clear headings, subheadings, lists, and code blocks to organize information logically. Make it easy for readers (human or AI) to quickly find relevant sections.
6.  **Consistency:** Use consistent terminology, formatting, and structure across all guides. Refer to terms defined in other guides or the main [Project Management Guide](guide://project-management).
7.  **Examples:** Provide concrete examples (code snippets, file structures, command outputs) to illustrate concepts and principles, not step-by-step procedures.
8.  **Target Audience:** Write for both human developers (potentially new to the project) and AI agents. This means being explicit, structured, and providing sufficient context.
9.  **Language Modularity:** When a guide mixes language‑specific details with general advice, extract each language's specifics into a dedicated sub‑guide (e.g., `testing/ruby-rspec.md`, `security/rust.md`). Keep the parent guide language‑agnostic.

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

## Content Guidelines: Guides vs Workflows

Guides and workflows serve distinct purposes and should contain different types of content. Understanding this separation is essential for maintaining consistency across the handbook system.

### What Belongs in Guides

**Conceptual Content:**
- Principles, philosophies, and best practices
- Standards and coding conventions
- Architecture patterns and design approaches
- Explanation of why certain approaches are preferred
- Context and rationale behind decisions
- Deep-dive knowledge and understanding

**Appropriate Guide Content Examples:**
- "Test-driven development principles and benefits"
- "Security considerations for input validation" 
- "Code review standards and what to look for"
- "Performance optimization strategies"
- "Error handling patterns and when to use them"

### What Does NOT Belong in Guides

**Procedural Content:**
- Step-by-step instructions for executing tasks
- Command sequences and specific CLI operations
- Implementation workflows and task execution
- Interactive checklists meant to be completed
- Detailed "how-to" procedures

**Content That Should Be in Workflows Instead:**
- "How to set up test environment" → Move to workflow
- "Steps to perform security audit" → Move to workflow  
- "Checklist for code review process" → Move to workflow
- "Commands to deploy application" → Move to workflow

### Linking Between Guides and Workflows

**From Guides to Workflows:**
- Guides should link to relevant workflows when discussing how principles are applied
- Use clear language: "To implement these security principles, see [Security Audit Workflow](wfi://security-audit)"
- Avoid embedding procedural steps directly in guides

**From Workflows to Guides:**
- Workflows can reference guides for context and rationale
- Link to guides when explaining why certain steps are necessary
- Use format: "For background on these testing principles, see [Testing Guide](guide://testing)"

## Standard Guide Structure

While the specific sections will vary based on the guide's topic, aim for a general structure like this:

1.  **Title (`# Title`):** Clear and descriptive title.
2.  **Introduction/Goal:** Briefly state the purpose of the guide and what the reader will learn or understand after reading it.
3.  **Core Sections (Using `##` and `###`):** Break down the topic into logical sections with clear headings.
    *   Explain key concepts, principles, and philosophies first.
    *   Detail standards, conventions, or rules with rationale.
    *   Provide context and background for decision-making.
    *   Link to relevant workflows for implementation details.
4.  **Examples:** Include well-formatted code blocks, file structure examples, or command outputs to illustrate concepts and patterns. Use realistic examples relevant to the toolkit's domain, focusing on demonstrating principles rather than step-by-step procedures.
5.  **Best Practices/Tips:** Offer conceptual advice, highlight common pitfalls, and explain the reasoning behind recommendations.
6.  **Related Documentation:** Link to other relevant guides, workflow instructions, or templates using paths relative to the project root (e.g., `[Project Management Guide](guide://project-management)`), **not** relative to the current file (e.g., `../project-management.g.md`). Always link to workflows when discussing implementation of the concepts covered.

## Language‑Specific Sub‑Guides

When splitting language‑dependent examples out of a general guide, follow these rules:

1. **Directory & File Names**  
   * Place sub‑guides in a directory that matches the parent guide’s slug.  
   * Use lower‑case filenames that match the language, e.g. `ruby.md`, `rust.md`, `typescript.md`.  
   * For testing, prefer more descriptive names such as `ruby-rspec.md` or `typescript-bun.md` when tool‑specific.

3. **Cross‑Linking**  
   * At the top of each sub‑guide add a short note:  
     ```markdown
     > This page is a language‑specific companion to [Testing Guide](guide://testing)
     ```  
   * Add reciprocal links from the parent guide to its sub‑guides.

3. **Index Updates**  
   * Whenever you add or delete a sub‑guide, update the guides README (or `index.md`) so the navigation tree stays accurate.

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
- **Use Standard Markdown Links:** When linking to other guides, workflow instructions, or project documents, always use the standard Markdown link format with proper file extensions e.g.: `[Writing Guides Guide](./meta/writing-guides-guide.md)`, `[Commit Workflow](wfi://git/commit)`. Avoid using just the path in backticks unless discussing the path itself.
- **Code Examples:** Use clear, minimal, and correct code examples. Specify the language in fenced code blocks (e.g., ```ruby).

## Content Examples: Appropriate vs Inappropriate

Understanding the distinction between conceptual guide content and procedural workflow content is crucial. Here are specific examples to illustrate what belongs in guides vs workflows.

### ✅ Appropriate Guide Content

**Conceptual Explanations:**
```markdown
## Test-Driven Development Philosophy

TDD follows the Red-Green-Refactor cycle, which promotes:
- **Design thinking**: Writing tests first forces you to think about API design
- **Confidence**: Comprehensive tests provide safety for refactoring
- **Documentation**: Tests serve as living documentation of expected behavior

The key insight is that TDD is not just about testing - it's a design methodology that leads to better code architecture.
```

**Standards and Conventions:**
```markdown
## Code Review Standards

When reviewing code, focus on these core areas:
- **Clarity**: Is the code self-documenting and easy to understand?
- **Security**: Are there potential vulnerabilities or data exposure risks?
- **Performance**: Are there obvious inefficiencies or bottlenecks?
- **Maintainability**: Will this code be easy to modify in the future?

For the specific steps to conduct a code review, see [Code Review Workflow](wfi://code-review).
```

### ❌ Inappropriate Guide Content (Move to Workflows)

**Step-by-Step Procedures:**
```markdown
❌ Don't put this in a guide:
## How to Set Up Testing Environment

1. Install Ruby 3.2+
2. Run `bundle install`
3. Copy `.env.example` to `.env`
4. Run `bin/setup`
5. Execute `bin/test` to verify setup

✅ This belongs in a workflow file instead.
```

**Interactive Checklists:**
```markdown
❌ Don't put this in a guide:
## Deployment Checklist
- [ ] Run tests
- [ ] Update version number  
- [ ] Create git tag
- [ ] Push to production

✅ This belongs in a workflow file instead.
```

**Command Sequences:**
```markdown
❌ Don't put this in a guide:
## Git Branch Management
To create a feature branch:
```bash
git checkout main
git pull origin main
git checkout -b feature/new-feature
```

✅ This belongs in a workflow file instead.
```

### 🔄 Converting Procedural to Conceptual Content

**Before (Procedural - belongs in workflow):**
```markdown
## Database Migration Process
1. Create migration file: `rails generate migration AddColumn`
2. Edit the migration to add your changes
3. Run `rails db:migrate`
4. Test the changes
5. Commit the migration file
```

**After (Conceptual - appropriate for guide):**
```markdown
## Database Migration Principles

Database migrations should be:
- **Reversible**: Always include a `down` method or use reversible operations
- **Atomic**: Each migration should represent a single, complete change
- **Tested**: Verify migrations work in both directions before deployment
- **Documented**: Include comments explaining complex migrations

The key principle is that migrations are permanent historical records of database changes. They should never be modified once committed to a shared branch.

For the specific steps to create and run migrations, see [Database Migration Workflow](wfi://database-migration).
```

This transformation maintains the valuable knowledge while removing the procedural steps that belong in self-contained workflows.

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
- **Run a Directory Audit before Large Refactors:** Use `tree -L 2` on your guides directory (or similar) to list the current structure, paste the excerpt into your refactor ticket, and build an explicit file‑manifest from it.
- **Update After Decisions:** If an ADR changes a standard or process, update the corresponding guide(s).
- **Refactor When Needed:** Don't hesitate to restructure or rewrite sections for clarity as the project evolves.

By adhering to these guidelines, we can build and maintain a high-quality set of development guides that effectively support the project's workflow and collaboration.
