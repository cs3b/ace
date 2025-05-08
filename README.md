# Coding Agent Workflow Toolkit (Meta)

This repository (`coding-agent-workflow-toolkit-meta`) provides the overarching documentation and guidance for setting up and using a comprehensive, AI-assisted development workflow. It explains how to integrate the `docs-dev` toolkit (which contains standardized development guides and workflow instructions) with a `docs-project` structure (for your project-specific documentation and task management).

The goal is to create a consistent, efficient, and AI-friendly development environment.

## Core Components

1.  **`docs-dev` Toolkit**:
    *   A specialized toolkit, ideally consumed from its own repository: `https://github.com/cs3b/coding-agent-workflow-toolkit`. It provides standardized development guides, workflow instructions, templates, and utilities.
    *   You integrate `docs-dev` into your project, typically as a Git submodule, into a local `docs-dev/` directory.
    *   The `docs-dev/` folder within *this* meta-repository contains an *example* of such a toolkit's README and structure, primarily for illustrative purposes here. For actual use and the latest version, always refer to the dedicated `docs-dev` toolkit repository.

2.  **`docs-project` Structure**:
    *   A standardized directory structure for all your project-specific documentation (e.g., `what-do-we-build.md`, `architecture.md`, `blueprint.md`), task management (`backlog/`, `current/`, `done/`), and decision logs.
    *   This structure is typically initialized and managed by workflows found in the `docs-dev` toolkit.
    *   The `docs-project/` folder within *this* meta-repository contains an *example* README detailing the `docs-project` specification and an example of its structure.

## Getting Started / Setup

To establish this workflow in your project:

**Prerequisites:**
-   Git installed on your system.

**Step 1: Integrate the `docs-dev` Toolkit**

The `docs-dev` toolkit contains all the standard guides, workflow instructions, and templates. It is highly recommended to add it to your project as a Git submodule from its dedicated repository.

*   **Canonical `docs-dev` repository**: `https://github.com/cs3b/coding-agent-workflow-toolkit`

In your project's root directory, run:
```sh
git submodule add https://github.com/cs3b/coding-agent-workflow-toolkit.git docs-dev
git submodule update --init --recursive
```
This will clone the `docs-dev` toolkit into a `docs-dev/` directory in your project, ready for use.

**Advanced: Forking `docs-dev` for Customization**

If you need to customize the `docs-dev` toolkit (e.g., tailor guides/workflows, create technology-specific branches for your projects):

1.  **Fork**: Fork the canonical `docs-dev` repository (i.e., `https://github.com/cs3b/coding-agent-workflow-toolkit`) on GitHub.
2.  **Add Your Fork as Submodule**: In your project's root, add your personal fork as the submodule:
    ```sh
    git submodule add <URL_OF_YOUR_FORKED_DOCS_DEV_REPO> docs-dev
    git submodule update --init --recursive
    ```
    (Replace `<URL_OF_YOUR_FORKED_DOCS_DEV_REPO>` with the URL of your fork).
3.  **Customize**: Navigate into your local `docs-dev` submodule (`cd docs-dev`), create a new branch (e.g., `git checkout -b my-project-specific-branch`), and make your modifications.
4.  **Stay Updated**: To incorporate updates from the original `docs-dev` toolkit, periodically fetch and merge changes from the upstream repository into your fork's main branch, and then merge those updates into your custom branches.

**Step 2: Initialize Your `docs-project` Structure**

Once the `docs-dev` toolkit is integrated (i.e., you have a `docs-dev/` directory in your project containing the toolkit), use its `initialize-project-structure.md` workflow to set up your project-specific `docs-project/` directory.

This is typically done by instructing an AI coding assistant. See the "Using Workflow Instructions with a Chat Interface" section below for how to do this.

## Understanding `docs-project/`

The `docs-project/` directory, once initialized in your project, becomes the central hub for its living documentation and operational context. It includes:
-   Core documents defining the project: `what-do-we-build.md`, `architecture.md`, `blueprint.md`.
-   Task management system: `backlog/`, `current/`, `done/` directories.
-   Decision log: `decisions/` directory.

For a detailed explanation of the `docs-project` specification and structure, refer to the example `README.md` located at `coding-agent-workflow-toolkit-meta/docs-project/README.md`.

## Using Workflow Instructions with a Chat Interface

Most interactions with the `docs-dev` workflows are designed to be performed via an AI-powered chat interface or coding assistant that can read files and execute commands. To run a workflow:

1.  Ensure the `docs-dev` toolkit is present in your project at the `docs-dev/` path.
2.  Instruct your AI assistant to read and execute the desired workflow instruction file.

**Example: Initializing the project structure**
Provide the following instruction to your chat assistant:
```
Read and execute the workflow instruction located at `docs-dev/workflow-instructions/initialize-project-structure.md`.
```

The assistant should then parse the Markdown file and follow the steps described, potentially asking for clarifications or performing file operations as required by the workflow.

## Integration Examples

To see how the Coding Agent Workflow Toolkit can be integrated with various coding tools and for examples of specific workflows, please refer to the `coding-agent-workflow-toolkit-meta/examples/` directory within this repository.

## Purpose of This Meta-Repository

This `coding-agent-workflow-toolkit-meta` repository serves to:
1.  Explain the overall philosophy, architecture, and integration strategy of the `docs-dev` toolkit and the `docs-project` specification.
2.  Provide illustrative examples of README files and directory structures for both `docs-dev` and `docs-project`. These are for guidance; the canonical `docs-dev` toolkit should be sourced from its own repository.
3.  Offer a centralized place for high-level discussions, issues, and examples related to the entire AI-assisted development workflow ecosystem.

For the actual `docs-dev` toolkit, its most current version, and its own issue tracking, please refer to its dedicated repository: `https://github.com/cs3b/coding-agent-workflow-toolkit`.