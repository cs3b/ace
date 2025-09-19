# Coding Agent Workflow Toolkit (Meta)

This repository (`coding-agent-workflow-toolkit-meta`) provides the overarching documentation and guidance for setting up and using a comprehensive, AI-assisted
development workflow. It explains how to integrate the `dev-handbook` toolkit (which contains standardized development guides and workflow instructions) with a
`dev-taskflow` structure (for your project-specific documentation and task management).

The goal is to create a consistent, efficient, and AI-friendly development environment.

## Core Components

1.  **`dev-handbook` Toolkit**: A specialized toolkit providing standardized development guides, workflow instructions, templates, and utilities.
   * The `dev-handbook/` directory is part of this integrated meta-repository and contains the complete toolkit ready for use.
2.  **`dev-taskflow` Structure**: A standardized directory structure for all your project-specific documentation (e.g., `what-do-we-build.md`,
`architecture.md`, `blueprint.md`), task management (`backlog/`, `current/`, `done/`), and decision logs.
* This structure is typically initialized and managed by workflows found in the `dev-handbook` toolkit. The `dev-taskflow/` folder within *this*
  meta-repository contains an *example* README detailing the `dev-taskflow` specification and an example of its structure.

## Getting Started / Setup

To establish this workflow in your project:

**Prerequisites:**

* Git installed on your system.

**Step 1: Using the `dev-handbook` Toolkit**

The `dev-handbook` toolkit contains all the standard guides, workflow instructions, and templates, and is already integrated into this repository in the `dev-handbook/` directory.

**Customization**

To customize the `dev-handbook` toolkit for your specific needs:

1. **Make Direct Modifications**: Navigate to the `dev-handbook/` directory and make your modifications directly.
2. **Create Custom Branches**: Create technology-specific or project-specific branches for different use cases.
3. **Track Changes**: Use Git to track your customizations and merge updates as needed.

**Step 2: Initialize Your `dev-taskflow` Structure**

With the `dev-handbook` toolkit available in the `dev-handbook/` directory, use its
`initialize-project-structure.md` workflow to set up your project-specific `dev-taskflow/` directory.

This is typically done by instructing an AI coding assistant. See the "Using Workflow Instructions with a Chat Interface" section below for how to do this.

## Understanding `dev-taskflow/`

The `dev-taskflow/` directory, once initialized in your project, becomes the central hub for its living documentation and operational context. It includes:

Core documents defining the project: `what-do-we-build.md`, `architecture.md`, `blueprint.md`.

* Task management system: `backlog/`, `current/`, `done/` directories.
* Decision log: `decisions/` directory.

For a detailed explanation of the `dev-taskflow` specification and structure, refer to the example `README.md` located at
`coding-agent-workflow-toolkit-meta/dev-taskflow/README.md`.

## Using Workflow Instructions with a Chat Interface

Most interactions with the `dev-handbook` workflows are designed to be performed via an AI-powered chat interface or coding assistant that can read files and
execute commands. To run a workflow:

1.  Ensure the `dev-handbook` toolkit is present in your project at the `dev-handbook/` path.
2.  Instruct your AI assistant to read and execute the desired workflow instruction file, providing any necessary inputs like file paths.

### Claude Code Integration

For [Claude Code][1] users, this repository includes native command integration through the `.claude/commands/` system. Each workflow instruction has a
corresponding command:

**Available Commands:**

* `/commit` - Follow commit workflow
* `/create-adr` - Create Architecture Decision Record
* `/create-api-docs` - Generate API documentation
* `/create-reflection-note` - Create project reflection
* `/create-test-cases` - Generate test cases
* `/create-user-docs` - Create user documentation
* `/draft-release` - Draft new release
* `/fix-tests` - Fix failing tests
* `/initialize-project-structure` - Set up project structure
* `/load-project-context` - Load project context
* `/publish-release` - Publish release
* `/plan-task` - Plan task implementation
* `/update-blueprint` - Update project blueprint
* `/update-roadmap` - Update project roadmap
* `/work-on-task` - Work on a task

**Usage:** Simply type `/command-name` in Claude Code to execute the corresponding workflow. Each command automatically reads the full workflow instructions and
commits changes when complete.

Here are some common examples:

**1. Initialize Project Structure** To set up your project\'s documentation and task management structure, often using a Product Requirements Document (PRD) as
initial input:

Read and execute the workflow instruction
`dev-handbook/workflow-instructions/initialize-project-structure.md`.
(The AI will likely ask for the location of a PRD or prompt for project details if one isn't found.)
```

**2. Breakdown Ideas/Notes into Actionable Tasks** To convert various inputs (like Feature Requirements Documents, raw notes, or PR feedback) into well-defined,
actionable tasks: This often involves a preparatory step to structure the input, followed by task creation. For instance, to process an FRD:

```text
1. Prepare an analysis from your Feature Requirements Document (FRD):
   Read and execute the workflow instruction `dev-handbook/workflow-instructions/draft-task.md`.
   (The AI will likely ask for the FRD content or path).

2. Create tasks from the structured analysis:
   Instruct the AI to use the output from the previous step to define and create
   individual task files in `dev-taskflow/backlog/{release_version}/tasks/`,
   following the guidelines in `dev-handbook/guides/write-actionable-task.md`.
```

(Note: The `dev-handbook/workflow-instructions/draft-task.md` workflow handles different input sources for task creation in a single, comprehensive workflow.)

**3. Review a Task** To thoroughly review an existing task definition (e.g., the next one suggested by a script like `task-manager next`) against project goals,
architecture, and recent changes, and to propose refinements:

```text
You might use a helper script (e.g., `task-manager next` if available in your
`` directory) via the terminal tool, or manually select
a task from `dev-taskflow/current/{release_version}/tasks/`.

2. Instruct the agent with the task's file path:
   Read and execute the workflow instruction
   `dev-handbook/workflow-instructions/plan-task.md` using the task file
   <path_to_identified_task.md>.
```

(The agent will then guide you through the review process as per the workflow, checking against project context and recent changes.)

**4. Work on a Task** To implement a defined and reviewed task (e.g., the next one suggested by `task-manager next`), following its embedded step-by-step plan:

```text
(Similar to reviewing a task, use `task-manager next` or manual selection).

2. Instruct the agent with the task's file path:
   Read and execute the workflow instruction
   `dev-handbook/workflow-instructions/work-on-task.md` using the task file
   <path_to_identified_task.md>.
```

(The agent will then follow the implementation plan within the task file, guiding you through the test-code-refactor cycle for each step.)

## Integration Examples

To see how the Coding Agent Workflow Toolkit can be integrated with various coding tools and for examples of specific workflows, please refer to the
`coding-agent-workflow-toolkit-meta/examples/` directory within this repository.

## FAQ

| Question | Answer |
|----------
| **What’s the difference between `dev-handbook` and `dev-taskflow`?** | `dev-handbook` is reusable, language-agnostic guidance; `dev-taskflow` holds your project-specific artefacts. (in this case the meta project, where we use it to improve itself) |

* * *

## Purpose of This Meta-Repository

This `coding-agent-workflow-toolkit-meta` repository serves to:

Explain the overall philosophy, architecture, and integration strategy of the `dev-handbook` toolkit and the `dev-taskflow` specification. Provide illustrative
examples of README files and directory structures for both `dev-handbook` and `dev-taskflow`. These are for guidance; the canonical `dev-handbook` toolkit
should be sourced from its own repository. Offer a centralized place for high-level discussions, issues, and examples related to the entire AI-assisted
development workflow ecosystem.

The `dev-handbook` toolkit is fully integrated into this repository and ready for immediate use.



[1]: https://claude.ai/code