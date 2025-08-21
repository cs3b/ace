---
:input_tokens: 91203
:output_tokens: 1133
:total_tokens: 92336
:took: 3.938
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-21T20:26:24Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 91203
:cost:
  :input: 0.00912
  :output: 0.000453
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.009574
  :currency: USD
---

# Implement --dry-run for all `dev-tools` Executables and Standardize Parameters

## Intention

To ensure all executable tools within `dev-tools/exe/` support a `--dry-run` flag for safe previewing of operations, and to standardize parameter definitions (flags, positional arguments) and internal command invocation patterns across the CLI.

## Problem It Solves

**Observed Issues:**
- Not all `dev-tools` executables support a `--dry-run` flag, preventing users from previewing the effects of their commands.
- Parameter definitions (flags, positional arguments) and command invocation patterns vary across executables, leading to inconsistency and a steeper learning curve.
- Some commands might directly call other commands via `system()` or `exec()`, bypassing internal Ruby library usage and making testing and integration more difficult.
- Lack of a standardized way to check if commands can be directly used as Ruby libraries without needing to be invoked via the command line.

**Impact:**
- Users cannot safely preview potentially destructive or complex operations, leading to accidental errors or data loss.
- Inconsistent CLI interfaces make the toolkit harder to learn and use effectively for both humans and AI agents.
- Internal command dependencies on command-line execution rather than direct library calls create coupling issues and hinder modularity and testability.
- Difficulty in integrating these tools into broader Ruby applications or workflows without shelling out.

## Key Patterns from Reflections

- **ATOM Architecture**: The gem is structured using ATOM principles, implying components should ideally be usable as libraries.
- **CLI Framework (`dry-cli`)**: The project uses `dry-cli`, which provides a structured way to define commands, arguments, and flags, facilitating standardization.
- **Existing `--dry-run` Implementations**: Some commands already implement `--dry-run` (e.g., `git-commit`, `git-push`), providing a pattern to follow.
- **Multi-Repository Coordination**: The `dev-tools` gem is a core component, and its consistency impacts the entire toolkit.
- **Test-Driven Development**: A robust testing strategy is in place, which can be leveraged to verify `--dry-run` functionality and parameter consistency.

## Solution Direction

1. **Implement `--dry-run` Flag**: For every executable in `dev-tools/exe/`, add a `--dry-run` flag. This flag should simulate the command's actions without making actual changes, printing what *would* happen instead.
2. **Standardize Parameter Definitions**: Review and standardize the definition of flags (options) and positional arguments for all commands. Ensure consistent naming, types, and required/optional status. Leverage `dry-cli`'s capabilities for this.
3. **Internal Command Invocation**: Refactor any commands that currently call other commands via shell execution to instead directly invoke the corresponding Ruby library classes or methods. This ensures modularity and testability.

## Critical Questions

**Before proceeding, we need to answer:**
1. Which specific commands currently lack a `--dry-run` flag?
2. What is the expected output format for `--dry-run` for each command? Should it be a simple print statement, or a more structured output?
3. Are there any commands where implementing `--dry-run` is technically infeasible or would significantly deviate from their intended purpose?

**Open Questions:**
- What is the process for identifying and refactoring commands that incorrectly call other commands via shell?
- How will the consistency of parameter definitions (flags, positional arguments) be enforced across existing and new commands?
- Should there be a common "atom" or "molecule" responsible for handling the `--dry-run` logic, or should it be implemented within each command?

## Assumptions to Validate

**We assume that:**
- All commands can technically support a `--dry-run` flag without fundamentally altering their core logic or becoming overly complex. - *Needs validation*
- Direct Ruby library calls can replace all instances of shell-based command execution within the `dev-tools` gem. - *Needs validation*
- `dry-cli`'s capabilities are sufficient to enforce parameter consistency and define `--dry-run` flags effectively. - *Needs validation*

## Expected Benefits

- **Enhanced Safety**: Users can preview operations, reducing the risk of unintended consequences.
- **Improved Consistency**: A standardized CLI interface makes the toolkit more predictable and easier to use.
- **Increased Modularity**: Commands are more reusable as Ruby libraries, facilitating integration and testing.
- **Better Testability**: Direct library calls are easier to mock and test than shell commands.
- **Streamlined Development**: Clearer rules for parameter definition and command structure improve the development process.

## Big Unknowns

**Technical Unknowns:**
- The exact implementation details for `--dry-run` for each specific tool (e.g., how to simulate file operations, Git actions, or LLM queries).
- The scope of refactoring required for commands that currently call other commands via shell.

**User/Market Unknowns:**
- How frequently users will utilize the `--dry-run` feature.
- Whether the standardization of parameters will conflict with existing user expectations for specific commands.

**Implementation Unknowns:**
- The estimated time required to audit and implement changes across all ~25+ executables.
- The process for ensuring adherence to these standards for future commands.
```

> SOURCE

```text
in conxtext of dev-tools/exe/* :: each should have --dry-run, we should review the --help and consistenncy of other params (flag, and positional), and next check if that any cmd the reuse other cmd, never call by cmd line, but run it dirrectly as ruby lib, we have review if all commands are defined the way that allows that
```
