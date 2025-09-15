---
:input_tokens: 45974
:output_tokens: 1308
:total_tokens: 47282
:took: 8.076
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-13T23:40:21Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45974
:cost:
  :input: 0.004597
  :output: 0.000523
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005121
  :currency: USD
---

```markdown
# Introduce `prun` CLI Tool for Flexible Script Execution

## Intention

To create a new CLI tool named `prun` within the `.ace/tools` gem that allows users to execute any script from the project root, relative to the current working directory, with support for multiple repository roots and configurable execution contexts.

## Problem It Solves

**Observed Issues:**
- Users need to navigate to specific subdirectories (e.g., `.ace/tools/`) to run scripts like `bin/test` or `bin/setup`.
- Executing scripts from different sub-repositories requires understanding their specific directory structures and running them from their respective roots.
- There is no standardized way to define and manage multiple project roots for tools that operate across a multi-repository setup.
- Configuration for which directories to consider as "project roots" is not centralized or easily managed.

**Impact:**
- Increased cognitive load and manual effort for developers and AI agents to locate and execute scripts.
- Inconsistent execution environments when scripts are run from different relative paths.
- Difficulty in managing and executing tooling across a monorepo or multi-repository project structure.
- Lack of a unified entry point for running project-specific scripts regardless of the current directory.

## Key Patterns from Reflections

- **CLI Tool Patterns**: `prun` will follow the established pattern of providing executable commands via the `.ace/tools` gem, leveraging `dry-cli` for command structure and standard argument parsing.
- **Multi-Repository Coordination**: The tool needs to be aware of multiple potential project roots, aligning with the system's multi-repository architecture.
- **Configuration Management**: The tool will use a YAML configuration file (`.coding-agent/prun.yml`) for defining project roots and execution contexts, similar to how other tools might manage settings.
- **ATOM Architecture**: The core logic for `prun` will likely reside in an `Organism` or `Molecule` within `.ace/tools/lib/coding_agent_tools/`, orchestrating file system operations and command execution.
- **Security-First Development**: Path validation and sanitization will be crucial to ensure `prun` only executes scripts in intended directories.

## Solution Direction

1. **`prun` CLI Command**: Introduce a new executable in `.ace/tools/exe/prun`.
    - This executable will parse arguments to identify the script to run and any additional options.
    - It will leverage a configuration file to determine the relevant project roots.
2. **Configuration File (`.coding-agent/prun.yml`)**: Define a standard location and format for the `prun` configuration.
    - This file will specify an array of `project_roots` (e.g., `.` for the current repo, or paths to other sub-repo roots).
    - It may also include default execution contexts or script aliases.
3. **Script Execution Logic**: Implement the core logic to:
    - Read the configuration file to identify potential project roots.
    - For each root, attempt to locate and execute the specified script.
    - Provide clear output indicating which script was run, where, and any errors encountered.
    - Handle cases where the script is not found in any of the configured roots.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact file structure and naming convention for the `.coding-agent/prun.yml` configuration file, and where should it be located relative to the user's current working directory or a known project root?
2. How should `prun` handle ambiguity if a script exists in multiple configured project roots? (e.g., prioritize the closest match, the first found, or prompt the user?)
3. What is the desired error handling strategy if a script is not found in any of the specified project roots, or if the script itself fails to execute?

**Open Questions:**
- Should `prun` support specifying the project root context via a command-line flag, in addition to or instead of the config file?
- How will `prun` handle scripts that require specific environment variables or arguments passed from the user?
- What level of output verbosity is expected, and how will it differ between successful execution, script errors, and file-not-found scenarios?

## Assumptions to Validate

**We assume that:**
- Users will have a `.coding-agent/prun.yml` file in a discoverable location (e.g., the current working directory or a parent directory) that defines the project roots. - *Needs validation*
- Scripts intended to be run via `prun` are executable and located relative to the identified project roots. - *Needs validation*
- The `.ace/tools` gem will be installed and available in the user's Ruby environment. - *Needs validation*

## Expected Benefits

- **Simplified Script Execution**: Users can run project scripts from anywhere within the project structure without needing to `cd` into specific directories.
- **Multi-Repo Support**: Enables consistent script execution across complex multi-repository projects.
- **Centralized Configuration**: Provides a single place to manage project roots and script execution contexts.
- **Improved Developer Experience**: Reduces friction and cognitive overhead for common development tasks.
- **Standardized Tooling**: Establishes a consistent method for running project-specific scripts.

## Big Unknowns

**Technical Unknowns:**
- The precise mechanism for discovering the `.coding-agent/prun.yml` file (e.g., search upwards from CWD, look in a fixed location).
- The exact strategy for disambiguating script locations if the same script exists in multiple roots.

**User/Market Unknowns:**
- How frequently will users need to specify multiple project roots?
- What are the most common use cases for running scripts from arbitrary locations within the project?

**Implementation Unknowns:**
- Which ATOM layer component would be most appropriate for housing the `prun` logic (e.g., a new Organism, or a Molecule used by a CLI command)?
- The precise implementation of path searching and validation to ensure security and correctness.
```

> SOURCE

```text
new tool in .ace/tools -> prun that will run any script from the project root, at whatever level it was executed, it can operate on additional root (if project is multirepo) e.g.: prun bin/test will run bin/test on project root or dev-tools, confing should be in .coding-agetnt/prun.yml)
```
