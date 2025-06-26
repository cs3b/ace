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

**Security and Caching Architecture**: The gem now includes comprehensive security hardening and XDG-compliant caching systems. 

For visual representations of the architecture, see [Architecture Diagrams](./architecture/diagrams.md).

### Component Descriptions

#### CLI (Command Layer)
- **Purpose**: Provides the command-line interface for user and agent interaction.
- **Technology**: dry-cli framework with command classes in `cli/commands/`.
- **Key Responsibilities**: Parsing command-line arguments, initial input validation, invoking the appropriate Organisms.
- **Location**: `exe/*` scripts and `lib/coding_agent_tools/cli/`.

#### Organisms (Business Logic Layer)
- **Purpose**: Contains the core business logic and orchestrates operations.
- **Technology**: Pure Ruby classes that coordinate Molecules and handle complex workflows.
- **Key Components**: `GoogleClient`, `LMStudioClient`, `PromptProcessor`.
- **Key Responsibilities**: Implementing specific workflows (e.g., querying LLMs, processing prompts), coordinating multiple Molecules, managing business rules.
- **Location**: `lib/coding_agent_tools/organisms/`.

#### Molecules (Composition Layer)
- **Purpose**: Simple compositions of Atoms that form reusable operations.
- **Technology**: Ruby classes that combine multiple Atoms for specific tasks.
- **Key Components**: `APICredentials`, `HTTPRequestBuilder`, `APIResponseParser`, `ExecutableWrapper`, `SecurePathValidator`, `FileOperationConfirmer`, `FileIOHandler`.
- **Key Responsibilities**: Building HTTP requests, parsing API responses, managing credentials, wrapping system executables, validating file paths for security, confirming file operations safely, handling file I/O with security integration.
- **Location**: `lib/coding_agent_tools/molecules/`.

#### Atoms (Utility Layer)
- **Purpose**: Smallest, indivisible units of functionality with no dependencies on other gem components.
- **Technology**: Simple Ruby classes or modules providing basic utilities.
- **Key Components**: `EnvReader`, `HTTPClient`, `JSONFormatter`, `SecurityLogger`.
- **Key Responsibilities**: Reading environment variables, making HTTP requests, formatting JSON data, security-focused logging with sanitization.
- **Location**: `lib/coding_agent_tools/atoms/`.

#### Models (Data Layer)
- **Purpose**: Represents the data structures used within the gem.
- **Technology**: Plain Old Ruby Objects (POROs) or simple data structures.
- **Key Components**: `LlmModelInfo` and other data carriers.
- **Key Responsibilities**: Defining the structure of data for LLM models, API responses, configuration.
- **Location**: `lib/coding_agent_tools/models/`.

### ATOM-Based Code Structure in `lib/coding_agent_tools/`

The internal structure of the gem's library code (`lib/coding_agent_tools/`) adheres to an ATOM-based hierarchy, promoting reusability and clear separation of concerns. For detailed classification rules and practical guidelines, see the [ATOM Component Classification House Rules](docs-dev/guides/atom-house-rules.md):

-   **Atoms (`lib/coding_agent_tools/atoms/`)**: The smallest, indivisible units of behavior or functionality. They have no dependencies on other parts of this gem and are highly reusable (e.g., `EnvReader` for environment variables, `HTTPClient` for external API calls, `JSONFormatter` for data serialization/deserialization, `SecurityLogger` for security-focused logging with automatic sanitization, utility functions for string normalization, basic file readers).
-   **Molecules (`lib/coding_agent_tools/molecules/`)**: Simple compositions of Atoms that form a meaningful, reusable operation or behavior. They encapsulate a single, focused piece of logic and are behavior-oriented helpers (e.g., `ExecutableWrapper` for CLI script execution, `APICredentials` for managing authentication details, `HTTPRequestBuilder` for constructing API requests, `APIResponseParser` for handling API responses, `SecurePathValidator` for path security validation, `FileOperationConfirmer` for safe file operation confirmations, `FileIOHandler` for secure file I/O operations, configuration loaders using file access and parsing atoms, basic Git clients using command execution atoms).
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

The gem implements a comprehensive, multi-layered security framework designed to protect against common attack vectors while maintaining usability for legitimate operations. The security architecture follows defense-in-depth principles with multiple validation layers, secure defaults, and comprehensive logging.

### Security Architecture Overview

The security framework consists of three core components working together:

1. **SecurityLogger (Atom)**: Provides security-focused logging with automatic sanitization
2. **SecurePathValidator (Molecule)**: Validates and sanitizes file paths to prevent traversal attacks
3. **FileOperationConfirmer (Molecule)**: Handles safe file operation confirmations with CI/interactive detection

These components integrate seamlessly with the `FileIOHandler` molecule to provide secure file operations throughout the application.

### Security Components

#### SecurityLogger (Atom)

**Purpose**: Security-focused logging with automatic sanitization of sensitive information.

**Key Features**:
- **Automatic Redaction**: Removes API keys (20+ character alphanumeric strings), email addresses, and IP addresses from log messages
- **Path Sanitization**: Protects user privacy by hiding home directory details and absolute paths outside current directory
- **Event Classification**: Different log levels for different security events (WARN for traversal attempts, INFO for invalid paths, DEBUG for normal operations)
- **Structured Logging**: Consistent format with event types, sanitized details, and contextual metadata

**Integration**: Used by all security components to ensure sensitive information never appears in logs, even during security violations.

#### SecurePathValidator (Molecule)

**Purpose**: Comprehensive path validation and sanitization to prevent path traversal attacks and unauthorized access.

**Security Features**:
- **Path Traversal Prevention**: Detects and blocks classic traversal patterns (`../`, `..\\`, URL-encoded variants)
- **Allowlist-Based Access Control**: Only permits access to explicitly allowed base paths (current directory, temporary directories)
- **Denylist Protection**: Blocks access to system directories (`/etc`, `/usr/bin`, `/var/log`, `.git`, `.ssh`, etc.)
- **Path Normalization**: Uses `Pathname#cleanpath` and `File.realpath` to resolve symlinks and relative components
- **Input Validation**: Checks for null bytes, control characters, excessive length, and path depth limits

**Configuration Options**:
- `allowed_base_paths`: Base directories where operations are permitted
- `denied_patterns`: Regex patterns for forbidden paths  
- `max_path_depth`: Maximum directory nesting level (default: 20)
- `max_path_length`: Maximum path character length (default: 4096)

**Validation Process**:
1. Basic input validation (null bytes, control characters, length limits)
2. Path traversal pattern detection
3. Path normalization and resolution
4. Denylist pattern matching
5. Allowlist base path verification
6. Security event logging

#### FileOperationConfirmer (Molecule)

**Purpose**: Safe file operation confirmations with intelligent environment detection.

**Key Features**:
- **Environment Detection**: Automatically detects CI environments (GitHub Actions, GitLab CI, Travis, etc.) and TTY availability
- **Safe Defaults**: In non-interactive environments, denies overwrite operations unless `--force` flag is provided
- **Interactive Prompts**: In interactive environments, prompts users for confirmation with timeout protection
- **Security Logging**: All confirmation decisions are logged with context and reasoning

**CI Environment Detection**: Checks for environment variables (`CI`, `GITHUB_ACTIONS`, `GITLAB_CI`, etc.) and TTY availability to determine if user interaction is possible.

### Security Data Flow

The security validation flow follows this pattern for file operations:

```
1. User Request (file path) 
   ↓
2. SecurePathValidator.validate_path()
   ├─ Basic validation (null bytes, length, characters)
   ├─ Path traversal detection
   ├─ Path normalization
   ├─ Denylist pattern checking
   ├─ Allowlist verification
   └─ Security event logging
   ↓
3. FileOperationConfirmer.confirm_overwrite() (if file exists)
   ├─ Environment detection (CI vs interactive)
   ├─ Force flag checking
   ├─ User confirmation (if interactive)
   └─ Security event logging
   ↓
4. FileIOHandler file operation
   └─ Operation success logging
```

### Integration with Existing Architecture

#### FileIOHandler Integration

The `FileIOHandler` molecule serves as the primary integration point for security components:

- **Path Validation**: All file paths are validated through `SecurePathValidator` before any file operations
- **Overwrite Confirmation**: File overwrites are confirmed through `FileOperationConfirmer` unless `--force` is specified
- **Security Logging**: All file operations are logged through `SecurityLogger` with appropriate detail sanitization

#### Component Dependencies

```
FileIOHandler (Molecule)
├─ SecurePathValidator (Molecule)
│  └─ SecurityLogger (Atom)
├─ FileOperationConfirmer (Molecule)  
│  └─ SecurityLogger (Atom)
└─ SecurityLogger (Atom)
```

#### ATOM Architecture Compliance

The security components follow the established ATOM pattern:

- **SecurityLogger (Atom)**: No dependencies on other gem components, purely functional
- **SecurePathValidator (Molecule)**: Composes SecurityLogger atom for event logging
- **FileOperationConfirmer (Molecule)**: Composes SecurityLogger atom for confirmation logging
- **FileIOHandler (Molecule)**: Orchestrates security molecules for comprehensive protection

### Security Configuration

#### Environment Variables

Security behavior is influenced by standard environment variables:

- **`HOME`**: Used for path sanitization to hide user directory details
- **CI Detection Variables**: `CI`, `GITHUB_ACTIONS`, `GITLAB_CI`, `TRAVIS`, etc. for environment detection
- **Temporary Directory Variables**: `TMPDIR`, `TMP`, `TEMP` for allowed path discovery

#### Default Security Settings

- **Allowed Paths**: Current directory (`.`), system temporary directories (`/tmp`, `/var/tmp`, macOS variants)
- **Denied Patterns**: System directories, configuration directories, hidden directories (`.git`, `.ssh`, `.aws`)
- **Limits**: 20 directory levels max, 4096 character path length max
- **Logging Level**: INFO level for security events (configurable)

### Threat Model and Mitigations

#### Path Traversal Attacks
- **Threat**: Malicious paths attempting to access files outside allowed directories
- **Mitigation**: Multi-layer validation including pattern detection, normalization, and allowlist checking
- **Examples**: `../../../etc/passwd`, `..%2f..%2fetc%2fpasswd`, symlink-based traversal

#### Information Disclosure
- **Threat**: Sensitive information (API keys, paths, emails) appearing in logs
- **Mitigation**: Comprehensive sanitization in SecurityLogger before any log output
- **Coverage**: API keys, email addresses, IP addresses, absolute paths, home directory details

#### Unauthorized File Operations
- **Threat**: Accidental or malicious file overwrites in sensitive locations
- **Mitigation**: Overwrite confirmation with safe defaults and environment-aware behavior
- **Protection**: CI environments default to deny, interactive environments prompt for confirmation

#### Privilege Escalation
- **Threat**: Access to system files or directories through gem operations
- **Mitigation**: Strict allowlist and denylist controls preventing access to system directories
- **Coverage**: `/etc`, `/usr/bin`, `/var/log`, `/root`, and other system paths

### Security Testing

The security components include comprehensive test coverage:

- **Unit Tests**: Individual component behavior and security validations
- **Integration Tests**: Component interaction and end-to-end security flows
- **Security Test Cases**: Specific attack vector testing (path traversal, null bytes, etc.)
- **Edge Case Testing**: Boundary conditions, error handling, and failure scenarios

### Security Monitoring

Security events are categorized and logged with appropriate severity levels:

- **WARN Level**: Active attack attempts (path traversal, denied access)
- **INFO Level**: Policy violations (invalid paths, overwrite denials)  
- **DEBUG Level**: Normal operations and successful validations

All security events include sanitized context information for forensic analysis while protecting sensitive data.

For visual representations of the security architecture, see [Architecture Diagrams](./architecture/diagrams.md).

## Performance Considerations

-   **Startup Latency**: Target low startup latency (≤ 200 ms for CLI commands) for responsiveness, especially when invoked by agents.
-   **XDG-Compliant Caching**: `CacheManager` provides structured, standards-compliant caching for model lists and API responses, significantly reducing redundant operations.
-   **HTTP Resilience**: `RetryMiddleware` implements exponential backoff for failed requests, prioritizing reliability over raw speed while preventing API overwhelm.
-   **Cache Migration**: Automatic migration from legacy cache locations ensures no performance regression during upgrades.
-   **Profiling**: Standard Ruby profiling tools can be used to identify performance bottlenecks.

For detailed caching architecture, see the [Architecture Diagrams](./architecture/diagrams.md).

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
-   StandardRB: Code style linter and formatter.
-   `vcr`: Records and replays HTTP interactions for tests.
-   `webmock`: Stubs and sets expectations on HTTP requests.
-   `docs-dev/tools/*` scripts: Dependencies for certain `bin/` utilities that wrap scripts from the `docs-dev` submodule.
-   **SimpleCov** - Code coverage analysis
-   **Pry** - Interactive debugging

For a comprehensive and up-to-date list of dependencies, refer to the `coding_agent_tools.gemspec` and `Gemfile`.

## Decision Records

Significant architectural decisions are documented as Architecture Decision Records (ADRs).

For detailed decision records, see [docs/architecture-decisions/](./architecture-decisions/).
