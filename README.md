# Coding Agent Workflow Toolkit

The Coding Agent Workflow Toolkit provides a structured approach to AI-assisted software development. It helps standardize development processes, manage project-specific documentation, and integrate AI capabilities effectively.

The toolkit is primarily composed of two key directories:
-   `docs-dev/`: Contains standardized development guides, workflow instructions, and templates to ensure consistency and best practices.
-   `docs-project/`: Houses all project-specific documentation, including architectural blueprints, task management, and decision logs, tailored to your current project.

## Getting Started / Setup

To integrate the Coding Agent Workflow Toolkit into your existing project:

**Prerequisites:**
-   Git installed on your system.

**Step 1: Add `docs-dev` to Your Project**

You can integrate the `docs-dev` component into your project using Git submodules. This allows you to keep `docs-dev` updated with the latest from its source repository.

In your project's root directory, run:

```
git submodule add git@github.com:cs3b/coding-agent-workflow-toolkit docs-dev
```

This will clone the `coding-agent-workflow-toolkit-meta` repository into a directory named `workflow-toolkit` in your project. The `docs-dev` content will then be available at `workflow-toolkit/docs-dev/`.

Alternatively, you can manually copy the `docs-dev/` directory from this repository into your project.

**Step 2: Initialize Project Structure**

Once `docs-dev` is part of your project (e.g., at `workflow-toolkit/docs-dev/` if you used the submodule method, or simply `docs-dev/` if you copied it), you need to initialize your project-specific documentation structure.

The `initialize-project-structure.md` workflow, located at `workflow-toolkit/docs-dev/workflow-instructions/initialize-project-structure.md` (adjust path if you copied `docs-dev` differently), guides you through this setup. Follow the steps outlined in that document. This process will create and populate the `docs-project/` directory with essential files like `what-do-we-build.md`, `architecture.md`, and `blueprint.md`.

## Understanding `docs-project/`

The `docs-project/` directory is the heart of your project's specific documentation and operational context. It contains:
-   **Core Documents**: `what-do-we-build.md` (project vision), `architecture.md` (technical design), `blueprint.md` (file and directory structure).
-   **Task Management**: Directories like `backlog/`, `current/`, and `done/` for tracking development tasks.
-   **Decision Log**: The `decisions/` directory for recording important architectural and technical decisions.

This directory and its contents are primarily managed and utilized by the workflows and guides found in `docs-dev/`.

## Integration Examples

To see how the Coding Agent Workflow Toolkit can be integrated with various coding tools and for examples of specific workflows, please refer to the `coding-agent-workflow-toolkit-meta/examples/` directory.
*(This directory will be populated with concrete examples as the toolkit evolves.)*

## Further Information

-   For more details on the standardized guides and workflow instructions, see the `README.md` inside the `docs-dev/` directory (`workflow-toolkit/docs-dev/README.md`).
-   For more information on the structure and purpose of the project-specific documentation, see the `README.md` inside the `docs-project/` directory (once initialized).
