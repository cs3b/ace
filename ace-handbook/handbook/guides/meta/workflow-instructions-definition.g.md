---
doc-type: guide
title: Writing Effective Workflow Instructions
purpose: Documentation for ace-handbook/handbook/guides/meta/workflow-instructions-definition.g.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Writing Effective Workflow Instructions


This guide explains how to create and structure the Markdown-based workflow instructions used by the AI agent within this project. Effective instructions are clear, specific, and provide sufficient context for the AI to perform tasks accurately and efficiently.
**Important:** These instructions are designed to be *read and followed by the AI agent*. They are not scripts to be executed directly in a shell. The user typically invokes a workflow by asking the agent to follow the steps outlined in a specific instruction file, often providing necessary inputs like file paths.

## Core Principles

1.  **Clarity & Specificity**: Instructions should be unambiguous. Use clear action verbs and define expected inputs and outputs precisely. Avoid vague language.
2.  **Self-Containment**: Each workflow should be independently executable without requiring external references. Embed all necessary templates, examples, and context directly within the workflow.
3.  **Context Loading**: Include a `## Project Context Loading` section that lists specific files an AI agent should load before executing the workflow. This replaces the need for cross-workflow dependencies.
4.  **Structured Format**: Use consistent Markdown sections:
    - `## Goal` - Clear objective statement
    - `## Prerequisites` - Required conditions
    - `## Project Context Loading` - Files to load
    - `## High-Level Execution Plan` - Planning and execution phases with checkboxes
    - `## Process Steps` - Detailed implementation steps
    - `## Success Criteria` - Validation points
5.  **Embedded Content**: Instead of referencing external templates or guides, embed the essential content directly. This includes:
    - Template structures
    - Example commands
    - Common patterns
    - Format specifications
6.  **Focus**: Each workflow instruction should address a single, well-defined process or goal. Complex workflows should still be self-contained rather than split into sub-workflows.
7.  **Examples**: Provide concrete examples of inputs, outputs, or expected results inline. Embed template content rather than referencing external files.
8.  **Planning Before Execution**: Include a high-level execution plan with planning and execution phases, using checkboxes for task tracking during workflow execution.

## Handling Technology-Specific Content

Workflow instructions should be self-contained while remaining practical across different technology stacks. This is achieved through embedded examples and patterns rather than external references.

### Embedding Technology Examples

When dealing with technology-specific content:

1. **Embed Common Examples**: Include examples for multiple common technologies directly in the workflow:

   ```markdown
   ### Common Test Commands
   - Ruby: `bundle exec rspec`
   - Node.js: `npm test`
   - Python: `pytest`
   - Rust: `cargo test`
   ```

2. **Use Inline Pattern Sections**: Create sections that show patterns for different stacks:

   ```markdown
   ### Version File Locations
   - Node.js: `package.json`
   - Ruby: `*.gemspec` or `lib/*/version.rb`
   - Python: `setup.py` or `pyproject.toml`
   - Rust: `Cargo.toml`
   ```

3. **Provide Template Adaptations**: When embedding templates, show variations:

   ```markdown
   ### Build Commands
   ```bash

   # TODO: Replace with project-specific build command
   # Examples:
   # - Ruby: bundle install
   # - Node.js: npm install && npm run build
   # - Python: pip install -r requirements.txt
   # - Rust: cargo build --release

   ```
   ```

This approach ensures workflows remain self-contained and immediately usable without external lookups, while providing practical guidance for different technology stacks.

## Standard Workflow Instruction Structure

All workflow instructions should follow this standardized structure for consistency and self-containment:

```markdown
# [Workflow Name] Workflow Instruction

## Goal

Clearly state the primary objective of this workflow. What problem does it solve or what process does it facilitate?

## Prerequisites

- List any conditions that must be met before starting
- Required tools, permissions, or project state
- Do NOT reference other workflows that must be run first

## Project Context Loading

* Load project objectives: `docs/vision.md`
* Load architecture: `docs/architecture.md`  
* Load current release: `dev-taskflow/current/*/`
* [Other specific files relevant to this workflow]

## High-Level Execution Plan

### Planning Phase
* [ ] [Planning step 1]
* [ ] [Planning step 2]
* [ ] [Planning step 3]

### Execution Phase
- [ ] [Execution step 1]
- [ ] [Execution step 2]
- [ ] [Execution step 3]

## Process Steps

1. **Step Name**: Detailed description
   * Sub-steps with specific actions
   * Embed any necessary templates or examples here
   * Include commands inline rather than referencing external docs
   
2. **Step Name**: Next major step
   ```bash

   # Example commands embedded directly
   bin/test
   bin/lint

   ```

## Embedded Templates

### Template Name
```markdown

[Complete template content embedded here]
[No external references]

```

### Another Template
```yaml

[Full template structure]
[All fields documented]

```

## Success Criteria

- Clear, verifiable outcomes listed as simple bullets
- No checkboxes in success criteria
- Focus on what should exist or be true after completion
- Each criterion should be objectively verifiable

## Common Patterns

### Pattern 1
[Description and example embedded]

### Pattern 2
[Description and example embedded]

## Best Practices

**DO:**
- [Specific practices for this workflow]
- [Common successful approaches]

**DON'T:**
- [Common pitfalls to avoid]
- [Anti-patterns specific to this workflow]
```

## File Naming Convention

All workflow instruction files must use the `.wf.md` suffix to distinguish them from guides (which use `.g.md`). This convention enables proper editor configuration and clear separation of content types.

### Naming Pattern

-   **Format:** Use the pattern `<verb>-<context>.wf.md`.

    -   `<verb>`: Represents the primary action or purpose of the workflow (e.g., `commit`, `fix`, `prepare`, `release`, `run`, `work-on`).
    -   `<context>`: Provides specific context for the action (e.g., `tests`, `tasks`, `task`).

-   **Style:** Use verb-first naming that describes what action the workflow performs
-   **Prefix:** Avoid prefixes like `lets-`. Files previously using this prefix should be renamed.
-   **Examples:**

    -   `commit.wf.md`
    -   `fix-tests.wf.md`
    -   `prepare-tasks.wf.md`
    -   `release.wf.md`
    -   `work-on-task.wf.md`

### Contrast with Guides

Unlike guides (`.g.md` files) which use noun-based naming to describe knowledge areas:

- **Workflows** describe processes to execute: `commit.wf.md`, `fix-tests.wf.md`
- **Guides** document standards and knowledge: `security.g.md`, `performance.g.md`

This naming distinction helps both humans and AI agents quickly identify whether a file provides executable instructions (workflow) or reference information (guide).

## Examples from This Project

Review these refactored workflow instructions that demonstrate self-containment principles:

### Context Loading Example

`wfi://bundle` (project context loading):

- Includes explicit file loading instructions
- No external workflow dependencies
- Clear context gathering steps

### Embedded Templates Example

`wfi://handbook/init-project`:

- Contains complete PRD, README, and architecture templates
- Embeds all binstub scripts
- Includes full v.0.0.0 release structure

### Simplified Process Example

`wfi://task/draft`:

- Unified approach for all input types
- Embedded task template
- No sub-workflow dependencies

### Command Reference Example

`wfi://release/publish`:

- Embeds package registry commands for all major platforms
- Includes changelog format specification
- Contains complete release process without external references

## Key Refactoring Principles

When refactoring workflows for independence:

1. **Embed, Don't Reference**: Copy essential content from guides into workflows
2. **Explicit Context Loading**: List specific files to load at the start
3. **Include All Templates**: Embed complete templates rather than referencing them
4. **Provide Multiple Examples**: Show patterns for different technology stacks
5. **Self-Contained Commands**: Include full command examples inline
6. **Remove Cross-Dependencies**: No workflow should require another workflow to run first

## See Also

- [Embedding Tests in AI Agent Workflows](./workflow-instructions-embedding-tests.g.md)

## Writing Style Tips

*   **Use Action Verbs:** Start steps with clear verbs (e.g., "Create", "Update", "Verify", "Parse", "Generate").
*   **Be Concise:** Avoid unnecessary jargon or overly long explanations.
*   **Embed Content:** Instead of referencing external guides or templates, embed the essential content directly in the workflow. This ensures self-containment.
*   **List Context Files:** In the Project Context Loading section, use root-relative paths to list files the AI should load before starting (e.g., `docs/architecture.md`, `dev-taskflow/current/*/`).
*   **Treat AI as a "Junior Developer":** Provide clear, step-by-step guidance, but also reference established project standards and expect the AI to follow them once pointed to them. Avoid ambiguity.

## List Formatting in Workflows

Workflow instructions use simple bullet points and numbered lists, avoiding interactive checkboxes except in templates and examples. Understanding proper formatting is crucial for effective AI agent interaction.

### ✅ Success Criteria: Use Simple Bullet Points

**Post-Execution Validation:**

```markdown
## Success Criteria
- All specified files have been created in the correct locations
- Configuration changes are applied and verified
- Tests pass and coverage requirements are met
- Documentation has been updated to reflect changes
```

These criteria serve as a **validation list** to confirm the workflow was completed successfully. They should:

- Be specific and verifiable
- Focus on outcomes rather than process steps
- Allow manual verification by humans or agents
- Be written as simple bullet points, never as interactive checkboxes

### ❌ Never Use Checkboxes in Workflow Content

**Don't use checkboxes for any workflow content:**

```markdown
<!-- DON'T DO THIS -->
## Process Steps
- [ ] Run the command `bin/setup`
- [ ] Edit the configuration file
- [ ] Test the changes

## Success Criteria
- [ ] Configuration is updated
- [ ] Tests pass
```

Instead, use numbered steps for processes and simple bullets for criteria:

```markdown
<!-- DO THIS -->
## Process Steps

1. **Initialize Setup**: Run the setup command
   ```bash

   bin/setup

   ```

2. **Configure System**: Edit the configuration file
   - Update the API endpoint URL
   - Set the appropriate timeout values

3. **Validate Changes**: Test the configuration
   ```bash

   bin/test --config

   ```

## Success Criteria
- Configuration is properly updated
- All tests pass successfully
```

### ✅ Appropriate Checkbox Use: Templates and Examples Only

Checkboxes are appropriate **only** when:

- Documenting task template formats (showing what task files should contain)
- Providing copyable templates for users
- Giving examples of syntax in documentation

```markdown
## Example: When documenting task structure
Tasks should include execution steps formatted like this:
- [ ] Step 1: Implement feature
- [ ] Step 2: Add tests
```

### Agent Interaction Guidelines

**Success Criteria Lists:**

- Are meant for **post-execution validation** only
- Should always be written as simple bullet points
- Serve as verification criteria to confirm completion
- Help users and agents validate the workflow outcome
- Never use interactive checkboxes

## Workflow Independence Principles

### Self-Containment Requirements

Every workflow must be independently executable:

1. **No Cross-Workflow Dependencies**: Never require another workflow to be run first. Instead, list prerequisites as conditions that should exist.

2. **Embedded Essential Content**: Include all necessary information within the workflow:
   - Template structures
   - Command examples
   - Format specifications
   - Common patterns

3. **Explicit Context Loading**: Replace implicit dependencies with explicit file loading:

   ```markdown
   ## Project Context Loading
   * Load project structure: `docs/blueprint.md`
   * Load current tasks: `dev-taskflow/current/*/tasks/*.md`
   * Check existing PRD: `PRD.md` or `README.md`
   ```

4. **Complete Process Coverage**: Ensure the workflow contains everything needed from start to finish without external lookups.

### Migration from Dependent to Independent

When refactoring existing workflows:

1. **Identify External References**: Find all links to guides, templates, or other workflows
2. **Extract Essential Content**: Copy the necessary information into the workflow
3. **Convert Prerequisites**: Change "Run X workflow first" to "Ensure Y exists"
4. **Embed Templates**: Include complete template content rather than linking
5. **Add Context Loading**: List specific files to load at the beginning

**Process Steps:**

- Should be numbered for sequential execution
- May contain embedded tests or verification commands
- Focus on actions and commands to execute
- Use clear, imperative language
- Never use checkboxes

By following these guidelines, we can create a robust set of workflow instructions that effectively guide the AI agent, leading to more predictable and efficient development outcomes.
