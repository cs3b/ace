# Coding Agent Tools Ruby Gem - Architecture

## Overview

This document outlines the architectural design and technical implementation details for the Coding Agent Tools (CAT) Ruby Gem. It provides a structured view of the system for developers and AI agents, explaining how the different components interact to provide automated development workflows. For a more high-level overview of the project structure and organization, refer to the [Project Blueprint](./blueprint.md).

## Technology Stack

### Core Technologies

- **Primary Language**: Ruby
- **Runtime/Framework**: MRI (C Ruby) version 3.2 or later
- **Database**: N/A (Gem does not have a primary database; interacts with Git, files, and external APIs)
- **Package Manager**: Bundler

### Development Tools

- **Build System**: Standard Ruby Gem build (`gemspec`)
- **Testing Framework**: RSpec (for unit and integration tests), Aruba (for CLI integration tests)
- **Linting/Formatting**: RuboCop (likely used for style enforcement)
- **Type System**: Native Ruby (Sorbet not explicitly mentioned in PRD v1)

### Infrastructure & Deployment

- **Containerization**: Optional (e.g., Docker for running LM Studio)
- **Cloud Platform**: N/A (Gem runs locally or in CI environments)
- **CI/CD**: GitHub Actions (used for automated testing and building)


## System Architecture

### High-Level Components

The gem's architecture is designed for modularity and testability. The code within `lib/coding_agent_tools/` specifically follows an ATOM-based hierarchy (Atoms, Molecules, Organisms, Ecosystems) inspired by Atomic Design principles for composing functionality. This high-level component breakdown is also reflected in the project's directory structure, as detailed in the [Project Blueprint's Project Organization section](./blueprint.md#project-organization).

```mermaid
flowchart TD
    subgraph Ruby Gem (CAT)
        direction TB
        CLI[CLI Commands<br/>exe/* & cli/]
        Organisms[🧬 Organisms<br/>Business Logic]
        Molecules[🔬 Molecules<br/>Composed Operations]
        Atoms[⚛️ Atoms<br/>Basic Utilities]
        Models[(Models<br/>Data Structures)]
    end
    CLI --> Organisms
    Organisms --> Molecules
    Molecules --> Atoms
    Organisms --> Models

    Atoms -->|HTTP| GeminiAPI((Google Gemini))
    Atoms -->|HTTP| LMStudio((LM Studio))<br/>(localhost:1234)
    Atoms -->|System Calls| FileSystem[(File System)]
    Atoms -->|ENV| Environment[Environment Variables]
```

### Component Descriptions

#### CLI (Command Layer)
- **Purpose**: Provides the command-line interface for user and agent interaction.
- **Technology**: dry-cli framework with command classes in `cli/commands/`.
- **Key Responsibilities**: Parsing command-line arguments, initial input validation, invoking the appropriate Organisms.
- **Location**: `exe/*` scripts and `lib/coding_agent_tools/cli/`.

#### Organisms (Business Logic Layer)
- **Purpose**: Contains the core business logic and orchestrates operations.
- **Technology**: Pure Ruby classes that coordinate Molecules and handle complex workflows.
- **Key Components**: `GeminiClient`, `LMStudioClient`, `PromptProcessor`.
- **Key Responsibilities**: Implementing specific workflows (e.g., querying LLMs, processing prompts), coordinating multiple Molecules, managing business rules.
- **Location**: `lib/coding_agent_tools/organisms/`.

#### Molecules (Composition Layer)
- **Purpose**: Simple compositions of Atoms that form reusable operations.
- **Technology**: Ruby classes that combine multiple Atoms for specific tasks.
- **Key Components**: `APICredentials`, `HTTPRequestBuilder`, `APIResponseParser`, `ExecutableWrapper`.
- **Key Responsibilities**: Building HTTP requests, parsing API responses, managing credentials, wrapping system executables.
- **Location**: `lib/coding_agent_tools/molecules/`.

#### Atoms (Utility Layer)
- **Purpose**: Smallest, indivisible units of functionality with no dependencies on other gem components.
- **Technology**: Simple Ruby classes or modules providing basic utilities.
- **Key Components**: `EnvReader`, `HTTPClient`, `JSONFormatter`.
- **Key Responsibilities**: Reading environment variables, making HTTP requests, formatting JSON data.
- **Location**: `lib/coding_agent_tools/atoms/`.

#### Models (Data Layer)
- **Purpose**: Represents the data structures used within the gem.
- **Technology**: Plain Old Ruby Objects (POROs) or simple data structures.
- **Key Components**: `LlmModelInfo` and other data carriers.
- **Key Responsibilities**: Defining the structure of data for LLM models, API responses, configuration.
- **Location**: `lib/coding_agent_tools/models/`.

### ATOM-Based Code Structure in `lib/coding_agent_tools/`

The internal structure of the gem's library code (`lib/coding_agent_tools/`) adheres to an ATOM-based hierarchy, promoting reusability and clear separation of concerns. For detailed classification rules and practical guidelines, see the [ATOM Component Classification House Rules](docs-dev/guides/atom-house-rules.md):

-   **Atoms (`lib/coding_agent_tools/atoms/`)**: The smallest, indivisible units of behavior or functionality. They have no dependencies on other parts of this gem and are highly reusable (e.g., `EnvReader` for environment variables, `HTTPClient` for external API calls, `JSONFormatter` for data serialization/deserialization, utility functions for string normalization, basic file readers).
-   **Molecules (`lib/coding_agent_tools/molecules/`)**: Simple compositions of Atoms that form a meaningful, reusable operation or behavior. They encapsulate a single, focused piece of logic and are behavior-oriented helpers (e.g., `ExecutableWrapper` for CLI script execution, `APICredentials` for managing authentication details, `HTTPRequestBuilder` for constructing API requests, `APIResponseParser` for handling API responses, configuration loaders using file access and parsing atoms, basic Git clients using command execution atoms).
-   **Organisms (`lib/coding_agent_tools/organisms/`)**: More complex units that perform specific business-related functions or features of the gem. They orchestrate Molecules and Atoms to achieve a distinct goal (e.g., `GeminiClient` for interacting with the Gemini API, `LMStudioClient` for local LLM interactions, `PromptProcessor` for preparing and parsing LLM prompts, LLM queriers, commit message suggesters). These handle the core business logic and workflows.
-   **Ecosystems (`lib/coding_agent_tools/ecosystems/`)**: Cohesive groupings of Organisms and other components that deliver a larger, bounded context or subsystem. The overall CLI application, orchestrated by `dry-cli`, can be considered the primary ecosystem.
-   **Models (`lib/coding_agent_tools/models/`)**: Plain Old Ruby Objects (POROs), typically implemented as Structs, that act as pure, immutable data carriers. They have no external dependencies or I/O operations and focus solely on data representation (e.g., `LlmModelInfo` for language model metadata, `Task` for task representation, `LLMResponse` for API response data).
-   **CLI Commands (`lib/coding_agent_tools/cli/` and `lib/coding_agent_tools/cli.rb`)**: These are the entry points for the command-line interface, built using `dry-cli`. Commands typically delegate their core logic to Organisms.
-   **Cross-Cutting Concerns (`lib/coding_agent_tools/`)**: Modules that provide shared functionalities used across different layers, ensuring consistency and centralized handling of aspects like logging, error reporting, and middleware processing (e.g., `middlewares/` for request/response processing, `notifications.rb` for system-wide alerts, `error.rb` for custom error definitions, `cli.rb` for command registration).

## Data Flow

Data typically flows from the CLI (user input) to an Organism, which orchestrates Molecules and Atoms to interact with external systems (LLM, Git, file system). The Atoms handle basic operations and return data, potentially structured using Models, back to the Molecules for composition. The Molecules return processed data to the Organism for business logic processing. The final result flows back through the layers and is outputted via the CLI. For task utilities, data might be read from local files (`docs-project/`) via Atoms and processed through the ATOM layers for CLI output.

### Request Processing Flow (Example: llm-gemini-query)

1.  **Input**: User/agent invokes `exe/llm-gemini-query` with a prompt and optional model selection.
2.  **Processing (CLI)**: The CLI command class parses arguments, validates input, and calls the relevant Organism.
3.  **Processing (Organism)**: GeminiClient Organism orchestrates the request by using Molecules to build HTTP requests and manage credentials.
4.  **External Interaction (Molecules/Atoms)**: HTTPRequestBuilder Molecule creates the request structure, HTTPClient Atom executes the API call to Google Gemini.
5.  **External Service**: Gemini API processes the prompt and returns a response.
6.  **Processing (Molecules/Atoms)**: APIResponseParser Molecule processes the JSON response, JSONFormatter Atom structures the data.
7.  **Processing (Organism)**: GeminiClient receives the formatted response, applies any business rules, and prepares output.
8.  **Output**: CLI displays the formatted response or reports errors with appropriate error handling.



## File Organization

The gem follows the ATOM architecture pattern with this essential structure:

```
lib/coding_agent_tools/
├── atoms/         # Basic utilities (HTTP, JSON, ENV reading)
├── molecules/     # Composed operations (credentials, request building)
├── organisms/     # Business logic (GeminiClient, LMStudioClient)
├── ecosystems/    # Future: Complete workflows orchestrating organisms
├── models/        # Data structures (LlmModelInfo, etc.)
├── cli/           # dry-cli command definitions
├── middlewares/   # Cross-cutting concerns (logging, monitoring)
└── *.rb           # Core files (version, error, notifications)
```

Other key directories:
- `exe/` - Gem executables (user-facing commands)
- `bin/` - Development tools and binstubs
- `spec/` - RSpec test suite
- `docs/` - Product documentation (architecture, vision, blueprint)
- `docs-project/` - Project management (tasks, roadmap)

For a complete directory structure and file listings, see the [Project Blueprint](./blueprint.md#project-organization).

## Development Patterns

-   **ATOM-Based Hierarchy**: The core library implementation (`lib/coding_agent_tools/`) follows an Atoms, Molecules, Organisms, Ecosystems hierarchy to ensure modularity, reusability, testability, and maintainability. This pattern promotes a clear separation of concerns, making components easier to understand, test, and adapt.
-   **Test-Driven Development (TDD)**: A strong emphasis is placed on writing tests (`spec/`) before or alongside implementation code, aiming for high test coverage. This approach ensures code correctness and facilitates refactoring.
-   **Dependency Injection**: Components are designed to accept dependencies (like Atoms and Molecules) via initialization rather than creating them internally. This facilitates easier testing by allowing mock objects to be injected, and promotes flexibility by decoupling components from their concrete implementations.
-   **CLI-First Design**: The architecture prioritizes a robust and predictable command-line interface as the primary interaction method. However, the CLI is designed as a thin layer over the Organisms, which can be reused in other contexts (e.g., web services, other Ruby applications). This allows the gem to be easily integrated into automated workflows and used directly by developers or other agents.
-   **Testing with VCR**: HTTP interactions with external APIs are recorded and replayed using VCR. This ensures tests are fast, reliable, and deterministic, as they do not rely on live external services, making the test suite robust against network issues or API changes.
-   **Observability with dry-monitor**: Key events and operations within the gem are instrumented using `dry-monitor`. This allows for centralized logging, error reporting, and performance monitoring by decoupling the event emitters from their consumers, thus avoiding tightly coupled concerns and promoting a flexible monitoring setup.

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

-   **New Commands**: Add new executables in `exe/` and corresponding CLI command classes in `lib/coding_agent_tools/cli/commands/`.
-   **New Organisms**: Implement new Organisms in `lib/coding_agent_tools/organisms/` to integrate with different external APIs, LLM providers, or tools (e.g., OpenAI, Anthropic, Mistral). These encapsulate business logic and can be reused across different contexts.
-   **New Ecosystems**: Create Ecosystems in `lib/coding_agent_tools/ecosystems/` to orchestrate multiple Organisms for complex workflows (e.g., git commit workflow, code review automation).
-   **New Models**: Define new data structures in `lib/coding_agent_tools/models/` as needed for new features or data representations.
-   **Custom Development Scripts**: Developers can create their own scripts in the project's `bin/` directory for development automation.

## Dependencies

### Runtime Dependencies

-   Ruby (>= 3.2)
-   Bundler
-   `faraday`: Flexible HTTP client library.
-   `zeitwerk`: Efficient and thread-safe code loader.
-   `dry-monitor`: Event-based monitoring and instrumentation toolkit.
-   `dry-configurable`: Provides configuration capabilities for Ruby objects.
-   `addressable`: URI manipulation library, replacing Ruby's URI.
-   Standard system **Git CLI**
-   Optional: **LM Studio** for offline LLM support

### Development Dependencies

-   RSpec: Testing framework.
-   RuboCop / StandardRB: Code style linter and formatter.
-   `vcr`: Records and replays HTTP interactions for tests.
-   `webmock`: Stubs and sets expectations on HTTP requests.
-   `docs-dev/tools/*` scripts: Dependencies for certain `bin/` utilities that wrap scripts from the `docs-dev` submodule.
-   **SimpleCov** - Code coverage analysis
-   **Pry** - Interactive debugging

For a comprehensive and up-to-date list of dependencies, refer to the `coding_agent_tools.gemspec` and `Gemfile`.

## Decision Records

Significant architectural decisions are documented as Architecture Decision Records (ADRs).

For detailed decision records, see [docs/architecture-decisions/](./architecture-decisions/).

## Troubleshooting

(This section is a placeholder and should be populated with common issues and their solutions as they are identified.)

-   **Issue**: Command not found after installation.
    -   **Symptoms**: Running `bin/tn` or other commands results in "command not found".
    -   **Solution**: Ensure Bundler binstubs are set up and your PATH includes the project's `bin/` directory. Run `bundle install` if using Bundler.

-   **Issue**: LLM query fails.
    -   **Symptoms**: Commands like `bin/llm-gemini-query` report API errors or connection issues.
    -   **Solution**: Check environment variables (`GEMINI_API_KEY`), network connectivity, and the status of the LM Studio server if using the local model.
