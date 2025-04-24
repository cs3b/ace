# Writing Effective Workflow Instructions

This guide explains how to create and structure the Markdown-based workflow instructions used by the AI agent within this project. Effective instructions are clear, specific, and provide sufficient context for the AI to perform tasks accurately and efficiently.
**Important:** These instructions are designed to be *read and followed by the AI agent*. They are not scripts to be executed directly in a shell. The user typically invokes a workflow by asking the agent to follow the steps outlined in a specific instruction file, often providing necessary inputs like file paths.

## Core Principles

1.  **Clarity & Specificity**: Instructions should be unambiguous. Use clear action verbs and define expected inputs and outputs precisely. Avoid vague language.
2.  **Context is Key**: Assume the AI might not have the full immediate context. Reference relevant guides (e.g., [Coding Standards](docs-dev/guides/coding-standards.md)), project documents ([Blueprint](docs-project/blueprint.md), [Architecture](docs-project/architecture.md)), or existing code patterns using root-relative paths.
3.  **Structured Format**: Use Markdown sections (like `## Goal`, `## Process Steps`, `## Success Criteria`) to organize the instruction logically. This helps both humans and AI parse the information.
4.  **Focus**: Each workflow instruction should address a single, well-defined process or goal. Break down complex workflows into smaller, composable instructions if possible.
5.  **Examples**: Provide concrete examples of inputs, outputs, or expected results, especially for complex instructions. Few-shot learning helps the AI understand the desired format and behavior.
6.  **Planning Before Prompting**: Just like coding, plan the workflow instruction before writing it. Define the goal, the steps involved, the necessary inputs, and how to measure success.

## Standard Workflow Instruction Structure

While the exact sections may vary slightly depending on the instruction's purpose, aim for a structure similar to this:

```markdown
# [Workflow Instruction Name] Workflow Instruction (e.g., lets-commit)

## Goal
*   Clearly state the primary objective of this workflow instruction. What problem does it solve or what process does it facilitate?

## Prerequisites (Optional)
*   List any conditions that must be met or other workflow instructions that should be run *before* this one.
*   Mention required tools, environment setup, or specific project state.

## Process Steps
*   Outline the sequence of actions the AI agent (guided by the user) should take.
*   Use numbered or bulleted lists for clarity.
*   Be specific about actions, inputs, and expected intermediate results.
*   Reference other guides or commands where necessary (e.g., "Refer to the [Version Control Guide](docs-dev/guides/version-control.md) for commit message format").

## Input (If applicable)
*   Specify the required inputs for the instruction (e.g., file paths, user confirmation, specific data).

## Output / Success Criteria
*   Define what constitutes successful completion of the workflow instruction.
*   Describe the expected output state, artifacts created, or changes made.
*   Use checklists for concrete verification steps.

## Reference Documentation (Optional)
*   List relevant guides or project documents that provide additional context using root-relative paths.

## Usage Example (Optional)
*   Provide a conceptual example of how the command might be invoked or used in a typical scenario.
```

## Examples from This Project

Review existing workflow instructions in `docs-dev/workflow-instructions/` like:
*   `docs-dev/workflow-instructions/load-env.md`: Focuses on context gathering.
*   `docs-dev/workflow-instructions/lets-prepare-tasks/from-pr-comments-api.md`: Complex process with specific inputs (fetched comments) and outputs (structured tasks).
*   `docs-dev/workflow-instructions/lets-commit.md`: Guides a specific, common developer action referencing external standards.
*   `docs-dev/workflow-instructions/self-reflect.md`: Defines a meta-process for analysis and improvement.

## Writing Style Tips

*   **Use Action Verbs:** Start steps with clear verbs (e.g., "Create", "Update", "Verify", "Parse", "Generate").
*   **Be Concise:** Avoid unnecessary jargon or overly long explanations.
*   **Reference Explicitly:** Use root-relative paths to files or other instructions where possible (e.g., [Coding Standards](docs-dev/guides/coding-standards.md), [Load Environment Workflow](docs-dev/workflow-instructions/load-env.md)).
*   **Treat AI as a "Junior Developer":** Provide clear, step-by-step guidance, but also reference established project standards and expect the AI to follow them once pointed to them. Avoid ambiguity.

By following these guidelines, we can create a robust set of workflow instructions that effectively guide the AI agent, leading to more predictable and efficient development outcomes.
