# Coding Agent Workflow Toolkit (`dev-handbook`)

This toolkit provides standardized development guides, workflow instructions, and templates for AI-assisted software development. It's designed to be integrated as a Git submodule.

## Directory Structure

* **`guides/`**: Development best practices and standards
  * Includes `.meta/` subdirectory for self-referential guides about maintaining the documentation itself
* **`workflow-instructions/`**: Step-by-step procedures for AI agents to execute common development tasks
* **`templates/`**: Reusable templates for projects, tasks, documentation, and releases
* **`tmp/`**: Temporary files and working directories

## Integration

Add as a Git submodule to your project:

```sh
git submodule add <repository-url> dev-handbook
git submodule update --init --recursive
```

## Usage

* **AI Workflow Execution**: Direct AI agents to read and execute specific workflow files
* **Reference Guides**: Consult guides for development standards and best practices  
* **Templates**: Use templates for consistent project structure and documentation
* **Getting Started**: See `workflow-instructions/README.md` for workflow guidance

## Relationships

**`dev-taskflow`**: This toolkit provides the standardized processes, while your project-specific content (tasks, architecture docs, decisions) lives in a separate `dev-taskflow/` directory at your project root.

**`dev-tools`**: Companion Ruby gem providing CLI tools for LLM integration, Git automation, and development utilities that complement these workflows.