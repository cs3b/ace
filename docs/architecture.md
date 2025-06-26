# Coding Agent Tools Ruby Gem - Architecture

## Overview

This document outlines the architectural design and technical implementation details for the Coding Agent Tools (CAT) Ruby Gem. It provides a structured view of the system for developers and AI agents, explaining how the different components interact to provide automated development workflows.

## Technology Stack

### Core Technologies

- **Primary Language**: Ruby
- **Runtime/Framework**: MRI (C Ruby) version 3.2 or later
- **Database**: N/A (Gem does not have a primary database; interacts with Git, files, and external APIs)
- **Package Manager**: Bundler

### Development Tools

- **Build System**: Standard Ruby Gem build (`gemspec`)
- **Testing Framework**: RSpec (for unit and integration tests), Aruba (for CLI tests)
- **Linting/Formatting**: RuboCop (likely used for style enforcement)
- **Type System**: Native Ruby (Sorbet not explicitly mentioned in PRD v1)

### Infrastructure & Deployment

- **Containerization**: Optional (e.g., Docker for running LM Studio)
- **Cloud Platform**: N/A (Gem runs locally or in CI environments)
- **CI/CD**: GitHub Actions (used for automated testing and building)
- **Monitoring**: Basic opt-in analytics via Snowplow collector (v1)

## System Architecture

### High-Level Components

The gem's architecture is designed for modularity and testability. The code within `lib/coding_agent_tools/` specifically follows an ATOM-based hierarchy (Atoms, Molecules, Organisms, Ecosystems) inspired by Atomic Design principles for composing functionality.

```mermaid
flowchart TD
    subgraph Ruby Gem (CAT)
        direction TB
        CLI[Executables / bin/*]
        ServiceObjects[🔧 Service Objects]
        Adapters[🌐 Adapters]
        Models[(Data Models)]
    end
    CLI --> ServiceObjects --> Adapters
    Adapters -->|Gemini REST| GeminiAPI((Google Gemini))
    Adapters -->|LM Studio| LMStudio((Local Model))\n(localhost:1234)
    Adapters -->|Git CLI / GitHub API| GitHub((Git/GitHub))
    ServiceObjects --> Models
    Models -->|Reads from/Writes to| LocalFS[(Local File System)\n(e.g., dev-taskflow tasks)]
```

### Component Descriptions

#### CLI (Action Layer)
- **Purpose**: Provides the command-line interface for user and agent interaction.
- **Technology**: Ruby, potentially using libraries like Thor or Dry-CLI.
- **Key Responsibilities**: Parsing command-line arguments, initial input validation, invoking the appropriate Service Objects.
- **Interfaces**: Communicates with Service Objects.

#### Service Objects (Transformation Layer)
- **Purpose**: Contains the core business logic and orchestrates operations.
- **Technology**: Pure Ruby classes.
- **Key Responsibilities**: Implementing specific workflows (e.g., generating a commit message, finding the next task), transforming data between models and adapters.
- **Interfaces**: Interacts with Adapters and Models. Designed to be testable in isolation.

#### Adapters (Operation Layer)
- **Purpose**: Provides interfaces to external systems or tools (LLMs, Git, file system).
- **Technology**: Ruby classes wrapping external libraries or system calls.
- **Key Responsibilities**: Handling communication protocols (HTTP, system commands), error handling for external interactions, translating external responses into internal data models.
- **Interfaces**: Communicates with external APIs/tools and is used by Service Objects.

#### Models (Model Layer)
- **Purpose**: Represents the data structures used within the gem.
- **Technology**: Plain Old Ruby Objects (POROs) or simple data structures.
- **Key Responsibilities**: Defining the structure of data related to Git objects, task items, API responses, etc.
- **Interfaces**: Used by Service Objects and Adapters.

### ATOM-Based Code Structure in `lib/coding_agent_tools/`

The internal structure of the gem's library code (`lib/coding_agent_tools/`) adheres to an ATOM-based hierarchy, promoting reusability and clear separation of concerns:

-   **Atoms (`lib/coding_agent_tools/atoms/`)**: The smallest, indivisible units of behavior or functionality. They have no dependencies on other parts of this gem and are highly reusable (e.g., a utility function for string normalization, a basic file reader).
-   **Molecules (`lib/coding_agent_tools/molecules/`)**: Simple compositions of Atoms that form a meaningful, reusable operation (e.g., a configuration loader using file access and parsing atoms, a basic Git client using command execution atoms).
-   **Organisms (`lib/coding_agent_tools/organisms/`)**: More complex units that perform specific business-related functions or features of the gem. They orchestrate Molecules and Atoms to achieve a distinct goal (e.g., an LLM querier, a commit message suggester). These often correspond to Service Objects.
-   **Ecosystems (`lib/coding_agent_tools/ecosystems/`)**: Cohesive groupings of Organisms and other components that deliver a larger, bounded context or subsystem. The overall CLI application, orchestrated by `dry-cli`, can be considered the primary ecosystem.
-   **Models (`lib/coding_agent_tools/models/`)**: Plain Old Ruby Objects (POROs) or simple data structures used across various layers to represent entities and data (e.g., `Task`, `LLMResponse`).
-   **CLI Commands (`lib/coding_agent_tools/cli/` and `lib/coding_agent_tools/cli.rb`)**: These are the entry points for the command-line interface, built using `dry-cli`. Commands typically delegate their core logic to Organisms.

## Data Flow

Data typically flows from the CLI (user input) to a Service Object, which uses Adapters to interact with external systems (LLM, Git, file system). The Adapters return data, potentially mapped to internal Models, back to the Service Object for processing. The final result is returned through the Adapter layer back to the Service Object, and finally outputted via the CLI. For task utilities, data might be read from local files (`dev-taskflow/`) via an Adapter/Service Object and formatted for CLI output.

### Request Processing Flow (Example: git-commit-with-message)

1.  **Input**: User/agent invokes `bin/git-commit-with-message` with arguments (`--intention`, `--files`, etc.).
2.  **Processing (CLI)**: The CLI executable parses arguments, calls the relevant Service Object.
3.  **Processing (Service Object)**: Service Object gathers necessary context (diff from Git via Adapter), prepares prompt for LLM.
4.  **External Interaction (Adapter)**: Service Object calls the LLM Adapter (e.g., `GeminiAdapter`) with the prompt.
5.  **External Service**: LLM API processes the prompt and returns a message.
6.  **Processing (Adapter)**: Adapter receives the LLM response, potentially validates/formats it, returns to Service Object.
7.  **Processing (Service Object)**: Service Object takes the generated message, stages files (via Git Adapter), and performs the Git commit (via Git Adapter).
8.  **Output**: CLI confirms the commit or reports errors.

## Command-line Tools (bin/)

The `bin/` directory contains executable scripts that serve as the primary interface for the gem. These are often thin wrappers (binstubs) that invoke the main gem logic.

### Key Commands (as per PRD):

-   `bin/llm-gemini-query`: Query Google Gemini.
-   `bin/lms-studio-query`: Query local LM Studio.
-   `bin/github-repository-create`: Create a GitHub repository.
-   `bin/git-commit-with-message`: Generate and perform a Git commit.
-   `bin/tr`: List recent tasks.
-   `bin/tn`: Find the next actionable task.
-   `bin/rc`: Get current release path and version.
-   `bin/test`: Run the test suite.
-   `bin/lint`: Run code quality checks.
-   `bin/build`: Build the gem.
-   `bin/run`: (Context dependent, potentially runs gem commands or a sample usage).
-   `bin/tree`: Display project directory structure (likely wraps `dev-tools/exe-old/tree.sh`).

These scripts are intended to be idempotent where possible and provide a consistent, predictable interface for automation.

## File Organization

```
.
├── bin/                   # Executable command-line scripts (binstubs/wrappers)
├── dev-handbook/              # Submodule: Development resources, guides, templates, tools
│   ├── guides/            # Best practices, patterns, templates
│   ├── tools/             # Utility scripts (e.g., for task management, tree display)
│   └── workflow-instructions/ # AI workflow definitions
├── dev-taskflow/          # Project-specific documentation and management files
│   ├── backlog/           # Task files for future releases
│   ├── current/           # Task files for the current release
│   ├── done/              # Completed task files
│   ├── decisions/         # Architecture Decision Records (.keep file ensures directory exists)
│   ├── architecture.md    # This document
│   ├── blueprint.md       # Project structure overview and AI guidelines
│   └── what-do-we-build.md # Project vision and goals
├── dev-tools/exe/                   # Gem executables (e.g., coding_agent_tools)
├── lib/                   # Ruby gem source code
│   ├── coding_agent_tools.rb # Main gem file, loads components
│   └── coding_agent_tools/
│       ├── atoms/         # Smallest, indivisible units (utilities, transformations)
│       ├── cli/           # Dry-CLI command definitions and subcommands
│       ├── ecosystems/    # Complete subsystems or major features
│       ├── molecules/     # Simple compositions of atoms
│       ├── models/        # Data structures (POROs)
│       ├── organisms/     # Business logic handlers, orchestrating molecules/atoms
│       ├── cli.rb         # Main Dry-CLI registry
│       ├── error.rb       # Custom gem-specific error classes
│       └── version.rb     # Gem version definition
├── spec/                  # RSpec test files (unit, integration, CLI)
├── .github/               # GitHub specific files (e.g. workflows)
│   └── workflows/
│       └── main.yml       # CI workflow
├── .gitignore             # Specifies intentionally untracked files
├── .rspec                 # RSpec configuration
├── .standard.yml          # StandardRB configuration
├── CHANGELOG.md           # Record of changes
├── Gemfile                # Bundler dependency file
├── LICENSE.txt            # Project license
├── PRD.md                 # Product Requirements Document (primary source of truth)
├── Rakefile               # Rake tasks
├── README.md              # Project overview and quick start guide
└── coding_agent_tools.gemspec # Gem specification file
```

The primary Ruby source code resides in the `lib/coding_agent_tools/` directory, organized according to the ATOM pattern. Tests are located in the `spec/` directory.

## Development Patterns

-   **ATOM-Based Hierarchy**: The core library implementation (`lib/coding_agent_tools/`) follows an Atoms, Molecules, Organisms, Ecosystems hierarchy to ensure modularity, reusability, testability, and maintainability.
-   **Test-Driven Development (TDD)**: A strong emphasis is placed on writing tests (`spec/`) before or alongside implementation code, aiming for high test coverage.
-   **Dependency Injection**: Components are designed to accept dependencies (like adapters) via initialization, facilitating easier testing and flexibility.
-   **CLI-First Design**: The architecture prioritizes a robust and predictable command-line interface as the primary interaction method.

## Security Considerations

-   **API Key/Token Handling**: The gem avoids hardcoding secrets. API keys and tokens (e.g., `GEMINI_API_KEY`, `GITHUB_TOKEN`) are read from environment variables or standard configuration locations (`~/.gemini/config`, macOS keychain).
-   **No Plaintext Secrets in Logs**: Logging is designed to avoid exposing sensitive information.
-   **Input Validation**: Basic input validation is performed, particularly at the CLI/Action layer, to prevent command injection or other security vulnerabilities.

## Performance Considerations

-   **Startup Latency**: Target low startup latency (≤ 200 ms for CLI commands) for responsiveness, especially when invoked by agents.
-   **Caching**: Potential for implementing caching strategies (e.g., for LLM responses or frequently accessed data) to improve performance.
-   **Profiling**: Standard Ruby profiling tools can be used to identify performance bottlenecks.

## Deployment Architecture

The gem is deployed as a standard RubyGem.

-   **Installation**: Users install via `gem install coding_agent_tools` or by adding `gem 'coding_agent_tools'` to their `Gemfile` and running `bundle install`.
-   **Binstubs**: Bundler generates binstubs in the project's `bin/` directory (or globally if installed system-wide), providing convenient wrappers for executables.
-   **CI/CD**: GitHub Actions are used to build the gem, run tests, and potentially publish new versions.

## Extension Points

The ATOM architecture provides several extension points:

-   **New Commands**: Add new executables in `bin/` and corresponding Action/Service Object logic in `lib/`.
-   **New Adapters**: Implement new Adapters in `lib/coding_agent_tools/operations/` to integrate with different external APIs, LLM providers, or tools. These can then be used by existing or new Service Objects.
-   **New Models**: Define new data structures in `lib/coding_agent_tools/models/` as needed for new features or data representations.
-   **Custom Scripts**: Users can create their own scripts in the project's `bin/` directory that utilize the gem's internal API or CLI commands.

## Dependencies

### Runtime Dependencies

-   Ruby (>= 3.2)
-   Bundler
-   Specific gems for API interactions (e.g., HTTP clients, JSON parsers) and potentially Git interaction libraries.

### Development Dependencies

-   RSpec
-   Aruba
-   RuboCop / StandardRB
-   Potentially VCR for recording API interactions in tests.
-   `dev-tools/exe-old/*` scripts: Dependencies for certain `bin/` utilities that wrap scripts from the `dev-handbook` submodule.

## Decision Records

Significant architectural decisions are documented as Architecture Decision Records (ADRs).

For detailed decision records, see [dev-taskflow/decisions/](../../../coding-agent-tools/dev-taskflow/decisions/).

## Troubleshooting

(This section is a placeholder and should be populated with common issues and their solutions as they are identified.)

-   **Issue**: Command not found after installation.
    -   **Symptoms**: Running `bin/tn` or other commands results in "command not found".
    -   **Solution**: Ensure Bundler binstubs are set up and your PATH includes the project's `bin/` directory. Run `bundle install` if using Bundler.

-   **Issue**: LLM query fails.
    -   **Symptoms**: Commands like `bin/llm-gemini-query` report API errors or connection issues.
    -   **Solution**: Check environment variables (`GEMINI_API_KEY`), network connectivity, and the status of the LM Studio server if using the local model.

## Future Considerations

-   **Multi-language bindings**: Explore providing SDKs or libraries in languages other than Ruby (post v1).
-   **Streaming LLM responses**: Investigate if agents require streaming output from LLMs rather than waiting for a full reply.
-   **Encrypted local storage**: Consider if caching or storing sensitive data locally requires encryption.
-   **Rubocop plugin**: Assess the value of a Rubocop plugin to enforce ATOM directory boundaries and other architectural conventions.
-   **Advanced Task Management Integration**: Explore deeper integrations with external task management systems.