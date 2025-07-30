---
---
:input_tokens: 45591
:output_tokens: 1400
:total_tokens: 48894
:took: 20.005
:provider: google
:model: gemini-2.5-flash
:timestamp: '2025-07-30T12:02:53Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45591
:cost:
  :input: 0.013677
  :output: 0.0035
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.017177
  :currency: USD
---

# Add Support for YAML Configuration Files

## Intention

To enable flexible, human-readable, and structured configuration for the Coding Agent Workflow Toolkit via YAML files.

## Problem It Solves

**Observed Issues:**
- Current configuration relies heavily on environment variables or hardcoded defaults, which is cumbersome for complex or frequently changing settings.
- There is no standardized, easy-to-edit file format for persistent application-wide or user-specific configurations.
- Managing multiple layers of configuration (e.g., system defaults, user overrides, project-specific settings) is challenging without a hierarchical file structure.

**Impact:**
- Developers and AI agents must rely on less flexible configuration methods, leading to more manual effort or less customizable behavior.
- Complex configurations become difficult to share, document, and maintain across different environments or users.
- Lack of a structured config file limits the ability to easily define and persist application-specific settings for various tools (e.g., LLM defaults, Git preferences).

## Key Patterns from Reflections

*   **XDG Compliance**: The project already adheres to XDG Base Directory Specification for caching (`$XDG_CACHE_HOME`). This pattern should extend to configuration, utilizing `$XDG_CONFIG_HOME` for configuration files. (Referenced in `ADR-014: LLM Integration Architecture` for `XDGDirectoryResolver` Atom and `CacheManager` Molecule).
*   **ATOM Architecture**: A new `Atom` for basic YAML parsing, and a `Molecule` for managing configuration loading and merging, align with the ATOM house rules for clear separation of concerns (e.g., `ADR-011: ATOM Architecture House Rules`).
*   **Security-First Development**: Loading external configuration files mandates the use of `SecurePathValidator` (Molecule) to prevent path traversal attacks and `SecurityLogger` (Atom) for secure logging of file access, especially if sensitive data is involved. (Referenced in `docs/architecture-tools.md` and `docs/architecture.md`).
*   **CLI Tool Patterns**: The existing 25+ CLI executables will need to consume this configuration, requiring a defined precedence order for CLI flags, environment variables, and YAML configurations. (Referenced in `docs/tools.md`).
*   **EnvReader (Atom)**: The existing `EnvReader` for environment variables suggests a complementary `ConfigReader` or `ConfigurationManager` that can integrate with or extend its functionality.

## Solution Direction

1.  **Introduce a `YamlParser` Atom**: Develop a low-level component (Atom) solely responsible for parsing YAML content from strings or files into Ruby hashes, handling basic YAML syntax and error cases. This will ensure a single point of responsibility for YAML parsing.
2.  **Develop a `ConfigurationManager` Molecule**: Create a higher-level component (Molecule) that orchestrates the loading and merging of configuration from multiple sources. This manager would load system-wide YAML (e.g., from `/etc/xdg/coding-agent-tools/config.yaml`), user-specific YAML (from `$XDG_CONFIG_HOME/coding-agent-tools/config.yaml`), environment variables, and finally apply CLI flag overrides. It would leverage `XDGDirectoryResolver` and `SecurePathValidator`.
3.  **Integrate into CLI Commands**: Update relevant CLI commands to retrieve their configuration parameters from the `ConfigurationManager`. This allows commands to be more flexible, using the defined precedence rules to determine effective settings.

## Critical Questions

**Before proceeding, we need to answer:**
1.  What is the definitive precedence order for configuration sources (CLI flags, environment variables, user-specific YAML, system-wide YAML, and default code values)?
2.  What specific configuration parameters will initially be supported via YAML files, and what is their expected hierarchical structure within the YAML?
3.  How will sensitive information (e.g., API keys, tokens) be handled if stored in YAML files? Will encryption, environment variable injection, or strict warnings be implemented?

**Open Questions:**
- Should configuration files support dynamic reloading if modified while the application is running, or will they only be loaded on application startup?
- What level of validation should be applied to YAML configuration file content (e.g., schema validation for expected data types, ranges, or allowed values)?
- How will the new `ConfigurationManager` interact with the existing `EnvReader` atom to avoid redundancy and ensure a consistent fallback mechanism for all configuration parameters?

## Assumptions to Validate

**We assume that:**
- Users prefer YAML over other structured text formats (e.g., JSON, TOML) for configuration files due to its human-readability and support for comments. - *Needs validation*
- The primary use case for YAML configuration is to persist user-specific settings and common defaults, rather than highly dynamic or frequently changing parameters that would be better suited for environment variables. - *Needs validation*
- The performance overhead of parsing one or more YAML files on application startup is acceptable for typical CLI command execution, meeting the ≤ 200ms startup latency target. - *Needs validation*

## Expected Benefits

- Provides a more flexible, human-readable, and user-friendly way to manage and persist configurations beyond environment variables.
- Enhances the maintainability and shareability of complex application settings across different development environments and team members.
- Improves the predictability and consistency of tool behavior by centralizing and standardizing configuration logic with clear precedence rules.

## Big Unknowns

**Technical Unknowns:**
- How to robustly handle complex YAML features (e.g., anchors, aliases, custom tags) if they are allowed in configuration files, and what Ruby YAML parser library (`Psych` or an alternative) best supports this without introducing security vulnerabilities (e.g., arbitrary code execution)?
- What is the precise impact on CLI command startup time and overall memory footprint, especially if multiple configuration files are loaded and merged, and how can this be optimized?

**User/Market Unknowns:**
- What are the most critical configuration parameters that users currently struggle to manage or find cumbersome with existing methods, and would benefit most from YAML file support?
- Are there any existing user workflows or integrations with third-party tools that assume a specific configuration file format that YAML might conflict with or disrupt?

**Implementation Unknowns:**
- What is the most effective strategy for integrating the new `ConfigurationManager` with the existing `dry-cli` command structure for automatic parameter overrides and default value provision?
- How will versioning of configuration file schemas be managed to ensure backward compatibility, guide users through necessary upgrades, or gracefully handle outdated formats?