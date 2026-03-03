---
:input_tokens: 45991
:output_tokens: 1142
:total_tokens: 47133
:took: 8.144
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-14T23:14:16Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45991
:cost:
  :input: 0.004599
  :output: 0.000457
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005056
  :currency: USD
source: legacy
id: output
status: pending
title: Limit CLI Output to 100 Lines
tags: []
created_at: '2074-07-30 17:14:13'
---

# Limit CLI Output to 100 Lines

## Intention

Globally configure a default output line limit of 100 for all CLI commands, with overriding capabilities via configuration files or environment variables, saving truncated output to temporary files.

## Problem It Solves

**Observed Issues:**
- CLI commands can produce excessively long output, overwhelming the terminal and making it difficult to find relevant information.
- Unbounded output can consume significant terminal buffer space and slow down user interaction.
- There is no consistent mechanism to manage and truncate output across all CLI tools.
- Users may want to control the verbosity of CLI output based on their needs or environment.

**Impact:**
- Users may miss critical information buried within large outputs.
- Terminal performance can degrade when dealing with very long command outputs.
- Inconsistent output handling across different CLI tools leads to a fragmented user experience.
- Difficulty in automating CLI output processing when unexpected large outputs occur.

## Key Patterns from Reflections

- **Global Configuration**: The idea of a global configuration file (`.coding-agent/config.yml`) aligns with ADR-005 (Universal Document Embedding System) and ADR-004 (Consistent Path Standards) which emphasize centralized, consistent configuration.
- **Environment Variable Overrides**: This pattern is common in CLI tools and software configuration, providing flexibility for CI/CD environments or specific user preferences, similar to how `DEBUG=true` might override default logging levels.
- **Temporary File Storage**: The concept of saving truncated output to a temporary file aligns with the XDG Base Directory Specification (ADR-014) and the general principle of managing temporary data. The project already uses XDG compliant caching (`$XDG_CACHE_HOME/coding-agent-tools/temp/`).
- **CLI Tooling**: The project has a strong emphasis on CLI tools (.ace/tools gem, 25+ executables) and the need for consistent behavior across them is paramount.
- **ATOM Architecture**: This feature should be implemented as a Molecule or a cross-cutting concern managed by a higher-level component that wraps CLI command execution.

## Solution Direction

1. **Global Configuration Management**: Implement a mechanism to load and parse a global configuration file (e.g., `.coding-agent/config.yml`) to retrieve the default output line limit.
2. **Environment Variable Override**: Prioritize an environment variable (e.g., `CODING_AGENT_OUTPUT_LINES`) to override the value set in the configuration file.
3. **CLI Output Limiting and File Saving**: Create a wrapper or middleware that intercepts the output of CLI commands, limits it to the configured number of lines, displays a truncated output, saves the full output to a temporary file (e.g., in `$XDG_CACHE_HOME/coding-agent-tools/temp/`), and informs the user about the saved file.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact format and location for the global configuration file (e.g., `.coding-agent/config.yml` or within the XDG config home)?
2. What is the standard environment variable name for overriding the output line limit?
3. How will this output limiting be integrated across all 25+ CLI commands without excessive code duplication (e.g., a shared library, a common wrapper script, or within the `dry-cli` framework)?

**Open Questions:**
- What specific temporary directory should be used, and how should files be named to avoid conflicts (e.g., including command name, timestamp, PID)?
- Should there be a mechanism to automatically clean up old temporary output files?
- How should interactive prompts or commands that expect continuous input be handled if output limiting is applied?

## Assumptions to Validate

**We assume that:**
- Users want a default behavior that limits potentially verbose CLI output for better readability. - *Needs validation through user feedback or pilot testing.*
- The chosen configuration and environment variable names are intuitive and unlikely to conflict with other tools. - *Needs validation through documentation and community feedback.*
- The overhead of processing and saving output to temporary files will not significantly impact CLI performance. - *Needs performance testing.*

## Expected Benefits

- **Improved Readability**: Users can easily view essential output directly in the terminal.
- **Enhanced Terminal Performance**: Prevents terminal slowdowns caused by excessive output.
- **Consistent User Experience**: Standardized output management across all CLI tools.
- **Configurable Verbosity**: Users can tailor output limits to their specific needs.
- **Preserved Full Output**: No data is lost; the complete output is available for detailed inspection.

## Big Unknowns

**Technical Unknowns:**
- The most efficient way to intercept and process stdout/stderr from various Ruby CLI executables to implement line limiting and file saving.
- Potential edge cases with commands that use complex terminal output manipulation or non-standard output streams.

**User/Market Unknowns:**
- The optimal default line limit that balances information density and readability across a wide range of CLI commands.
- User adoption rate of global configuration and environment variables for managing output limits.

**Implementation Unknowns:**
- The exact implementation strategy for the output limiting wrapper (e.g., using pipes, `IO.popen`, or a more integrated approach within `dry-cli`).
- The process for cleaning up temporary files and managing disk space.
```

> SOURCE

```text
for all the exe/cmds we should have a limit for the output - configure globally in .coding-agent/config.yml - to print up to 100 lines of ouput by default - can be configured by config, or env varialbe (env variable overwrite the config). and the rest is saved to a file and we return on top and bottom info that the full results are on the file ( project tmp/tool-call-results/...)
```