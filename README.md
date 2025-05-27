# Coding Agent Workflow Toolkit (`docs-dev`)

Welcome to the `docs-dev` Coding Agent Workflow Toolkit! This toolkit provides a comprehensive suite of standardized development guides, workflow instructions, and utilities to enhance AI-assisted software development. It's designed to bring consistency, efficiency, and best practices to your projects when working with coding agents or large language models.

You typically integrate this toolkit into your project by adding it as a Git submodule into a `docs-dev/` directory.

## Key Features

*   **Standardized Guides (`guides/`)**: A collection of best practices for various aspects of software development, including coding standards, testing procedures, documentation strategies, version control, and release management.
*   **Actionable Workflow Instructions (`workflow-instructions/`)**: Step-by-step Markdown-based procedures for common development tasks (e.g., initializing a new project's documentation structure, creating user docs, onboarding a new task). These are designed to be interpreted and executed by AI coding assistants or followed by human developers.
*   **Project Management Facilitation**: Defines structures and workflows that help manage the development lifecycle, particularly for initializing and maintaining a `docs-project/` directory in your main project for task tracking, architectural documents, and decision logs.
*   **Tools & Utilities (`tools/`)**: A collection of helper scripts and utilities to support the development workflow (e.g., for task management, documentation validation, or code generation assistance). *(Currently, this section is a placeholder; tools will be added as they are developed and formalized within this toolkit.)*

## Directory Structure

Here's a breakdown of the core directories within this toolkit:

*   **`guides/`**: Contains detailed guides on various development practices.
    *   **`guides/`**: Conceptual guides, best practices, and standards for development within this project. These explain _how_ we do things. This directory includes a `.meta/` subdirectory for guides that are self-referential, describing the process of creating or maintaining the documentation and workflows themselves.
        *   `README.md`: Index for all guides.
        *   `coding-standards.md`: Guidelines for writing clean, maintainable code.
        *   `documentation.md`: Standards for creating and maintaining project documentation.
        *   `project-management.md`: Overview of the project management approach facilitated by this toolkit, explaining the use of `docs-project` for tasks, backlog, etc.
        *   `ship-release.md`: Procedures for releasing new versions of software.
        *   `testing.md`: Strategies and best practices for software testing.
        *   `version-control.md`: Best practices for using Git and managing branches.
        *   `docs-dev/guides/.meta/writing-workflow-instructions-guide.md`: A guide on how to write new workflow instructions compatible with this toolkit.
        *   *(Other guides as developed, e.g., API Design, Security Best Practices)*
*   **`workflow-instructions/`**: Provides step-by-step instructions for specific development tasks, intended for AI or human execution.
    *   `initialize-project-structure.md`: Sets up the `docs-project/` directory and core documents in a new or existing project.
    *   `create-user-docs.md`: Guides the creation of user-facing documentation for features.
    *   `load-env.md`: Instructs on loading the development environment context.
    *   `work-on-task.md`: Defines the process for starting, working on, and completing a development task.
    *   `review-task.md`: Guides the review and refinement of a task definition.
    *   `breakdown-notes-into-tasks/`: Contains sub-workflows to process various inputs (FRDs, PRDs, diffs, etc.) into structured notes for task creation.
    *   *(Other workflow instructions as developed, e.g., `refactor-codebase.md`, `run-tests-and-report.md`)*
*   **`tools/`**: (This directory might be added for utility scripts)
    *   Example: `docs-dev/tools/get-next-task` (a script to help identify or suggest the next task to work on, often by querying the `docs-project` structure).

## How to Integrate and Use

This `docs-dev` toolkit is designed to be integrated into your main software project, residing within a directory named `docs-dev/`.

1.  **Integration**: The recommended method is to add this toolkit as a Git submodule:
    ```sh
    # In your project's root directory
    git submodule add https://github.com/cs3b/coding-agent-workflow-toolkit.git docs-dev
    git submodule update --init --recursive
    ```
    If you need to customize this toolkit extensively, consider forking it on GitHub first and then adding your fork as the submodule. This allows you to pull updates from this upstream repository while maintaining your own versions.

2.  **Usage**:
    *   **Workflow Execution**: Instruct your AI coding assistant to read and execute specific workflow files from your project's `docs-dev/workflow-instructions/` directory. For example, in your coding agent chat, you would write:
        ```
        Read and execute the workflow instruction `docs-dev/workflow-instructions/initialize-project-structure.md`.
        ```
    *   **Consulting Guides**: Developers (and AI assistants, if capable) should refer to the guides in `docs-dev/guides/` for best practices and operational standards.
    *   **Project Initialization**: The `initialize-project-structure.md` workflow is crucial for setting up a `docs-project/` directory in your main project. This `docs-project/` directory will then house all your project-specific documentation, tasks, and architectural details, keeping them separate from this generic `docs-dev` toolkit.

## Relationship with `docs-project`

This `docs-dev` toolkit provides the *engine* – the standardized workflows, guides, and utilities for managing a software project. The *output* and *project-specific context* (such as your project's unique architecture document, your current tasks, or your team's decision log) reside in a separate `docs-project/` directory, which should be at the root of your main project. Many workflows within `docs-dev` are designed to operate on or help create and manage the content within `docs-project`.

## Overall Workflow Ecosystem

For a complete understanding of how this `docs-dev` toolkit fits into the broader AI-assisted development ecosystem, including the detailed specification of the `docs-project` directory and how to set up the entire environment, please refer to the main documentation at the [Coding Agent Workflow Toolkit (Meta) Repository](https://github.com/cs3b/coding-agent-workflow-toolkit-meta).

## Contributing

Contributions to this `docs-dev` toolkit are highly welcome! If you have suggestions for new guides, workflows, utilities, or improvements to existing ones, please open an issue or submit a pull request to the [upstream repository](https://github.com/cs3b/coding-agent-workflow-toolkit). Ensure you follow any contribution guidelines outlined in `CONTRIBUTING.md` (if present).