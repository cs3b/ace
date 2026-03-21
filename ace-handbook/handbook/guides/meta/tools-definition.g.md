---
doc-type: guide
title: Development Tools Guide
purpose: Documentation for ace-handbook/handbook/guides/meta/tools-definition.g.md
ace-docs:
  last-updated: 2026-01-08
  last-checked: 2026-03-21
---

# Development Tools Guide

This guide outlines best practices for creating, maintaining, and using development tools located within the tools directory. These tools are helper scripts and utilities designed to automate common tasks, enforce standards, and support the overall development workflow for both human developers and AI agents.

## Goal of Tools

The primary goal of development tools is to:
- Automate repetitive or complex development tasks.
- Ensure consistency in project operations (e.g., task management, documentation checks).
- Provide support for workflows defined via `wfi://` protocol.
- Enhance developer productivity and reduce manual error.
- Be easily usable by both human developers and AI agents.

## Core Principles for Tool Development

1.  **Clarity & Simplicity:** Tools should have a clear purpose and be straightforward to use.
2.  **Reliability:** Tools must be robust and produce consistent, predictable results.
3.  **Well-Documented:** Each tool should have clear usage instructions, either as comments within the script or as part of this guide if complex. Simple tools often have a `print_usage` function or respond to `--help`.
4.  **Idempotency (where applicable):** If a tool modifies state, it should ideally be idempotent, meaning running it multiple times has the same effect as running it once.
5.  **Single Responsibility:** Each tool should focus on a single task or a small set of closely related tasks.
6.  **Standard Naming Conventions:** Adhere to the naming conventions outlined below.
7.  **Cross-Platform Compatibility (where feasible):** Strive to make tools runnable on common development operating systems (Linux, macOS). If a tool has specific OS dependencies (e.g., `tree` command), document them.
8.  **Error Handling:** Tools should provide clear error messages and exit with non-zero status codes on failure.
9.  **Minimal Dependencies:** Prefer tools written in standard scripting languages (e.g., Bash, Ruby, Python) that are commonly available or have minimal external dependencies. If dependencies are required, document them.
10. **Project-Relative Paths**: Tools should assume they are run from the project root (an assumption typically ensured by `bin/` wrappers). Paths within tools (e.g., to access `dev-taskflow/` files) should be constructed relative to this root (e.g., `dev-taskflow/current/vX.Y.Z/tasks/001.md`) and not include the top-level project directory name.

## Naming Conventions

To ensure clarity and consistency, tools within the tools directory should follow these naming conventions:

1.  **Verb-Prefix:** Tool names should start with a verb that describes their primary action.
    *   Examples: `get-next-task`, `build-contextual-prompt`, `lint-md-links`, `show-directory-tree`.
2.  **Lowercase & Hyphenated:** Use lowercase letters and separate words with hyphens.
    *   Example: `fetch-github-pr-data` (not `fetchGithubPRData` or `fetch_github_pr_data`).
3.  **Descriptive:** The name should clearly indicate the tool's purpose.
4.  **File Extension (if applicable):** Include the appropriate file extension (e.g., `.rb` for Ruby scripts, `.sh` for shell scripts). For executable scripts without an extension, ensure the shebang line (e.g., `#!/usr/bin/env ruby`) is present.

## Standard Tool Structure (Example for a script)

```bash
#!/usr/bin/env ruby
# tool-name: Brief description of what the tool does.
# (Additional comments about usage, dependencies, or important notes)

# require 'optparse' # For command-line option parsing
# require 'other_libs'

# Default options or constants
# DEFAULT_SETTING = "value"

# Function to print usage instructions
# def print_usage
#   puts "Usage: tool-name [OPTIONS] [ARGUMENTS]"
#   puts ""
#   puts "Options:"
#   puts "  -o, --option  Description of option"
#   puts "  -h, --help    Display this help message"
# end

# Parse command-line arguments (using OptParse or similar)
# options = {}
# OptionParser.new do |opts|
#   opts.banner = "Usage: tool-name [options] [arguments]"
#   opts.on("-h", "--help", "Prints this help") do
#     print_usage
#     exit
#   end
#   # Define other options
# end.parse!

# Main logic of the tool
# begin
#   # ... tool implementation ...
# rescue => e
#   warn "Error: #{e.message}"
#   exit 1
# end

# Exit with success
# exit 0
```

## `bin/` Wrappers

Simple, frequently used tools from the tools directory may have thin wrapper scripts in the project's root `bin/` directory for easier access from anywhere in the project.

- **Naming:** Wrappers in `bin/` should typically be short, memorable, and reflect the tool's purpose (e.g., `bin/tn` for the get-next-task tool, `bin/gl` for the get-recent-git-log tool).
- **Functionality:** These wrappers should primarily set up the correct execution path to the actual tool in the tools directory and pass along any arguments. These wrappers should be kept as minimal as possible. If no special environment setup or argument manipulation is needed beyond what the target script handles, a simple `exec` call (like the example below for Ruby scripts, or its shell script equivalent) is preferred.

Example `bin/tn` wrapper:
```ruby
#!/usr/bin/env ruby
# bin/tn: Thin wrapper for get-next-task utility
exec(File.expand_path('../tools/get-next-task', __dir__), *ARGV)
```

## Adding a New Tool

1.  **Define Purpose:** Clearly define what the tool will do and why it's needed.
2.  **Choose Language:** Select an appropriate scripting language.
3.  **Implement Logic:** Write the tool, adhering to the core principles and naming conventions.
4.  **Add Usage Info:** Include a help option (`-h`, `--help`) or clear comments explaining how to use the tool.
5.  **Test Thoroughly:** Ensure the tool works as expected in various scenarios, including edge cases and error conditions. Document example invocations or create test cases if the tool's logic is complex. Verify that the tool produces correct output and handles failures gracefully (e.g., proper exit codes, informative error messages).
6.  **Place in the tools directory:** Add the new tool to the tools directory.
7.  **(Optional) Create `bin/` Wrapper:** If the tool is frequently used, consider adding a wrapper in the root `bin/` directory.
8.  **Update Documentation:**
    *   If the tool is significant or complex, add a section to this guide describing it.
    *   Update the guides README if necessary to reflect the new tool's availability, especially if it supports a key workflow.
    *   Mention the tool in relevant workflow instructions or other guides if it automates a step.

## Maintaining Tools

- **Keep Them Updated:** As project structures or workflows evolve, update tools accordingly.
- **Refactor for Clarity:** If a tool becomes too complex, consider refactoring it or splitting its functionality.
- **Address Issues:** Fix bugs or issues reported in tools promptly.
- **Version Control:** All tools must be version-controlled within the `docs-dev` repository.

## Current Development Tools

### Documentation Review Tools

#### `generate-doc-review-prompt`
**Purpose:** Creates comprehensive AI agent prompts for reviewing code diffs and updating related documentation.

**Usage:**
```bash
# Basic usage - generate prompt from diff file
generate-doc-review-prompt -d changes.diff

# Specify custom output location
generate-doc-review-prompt -d changes.diff -o review-prompt.md

# Include full documentation content for detailed analysis
generate-doc-review-prompt -d changes.diff --include-content
```

**Options:**
- `-d, --diff FILE`: Path to the diff file (required)
- `-o, --output FILE`: Output file for the prompt (optional, auto-generates if not specified)
- `-r, --root DIR`: Project root directory (default: current directory)
- `-c, --include-content`: Include full content of documentation files (default: just list files)
- `-h, --help`: Show help message

**Wrapper:** Available as `bin/cr-docs` for convenient access.

**Dependencies:** Standard Ruby libraries only (optparse, pathname, fileutils).

**Related Documentation:** See [Code Review: Diff-Based Documentation Updates](./code-review-diff-for-docs-update.g.md) for comprehensive workflow guidance.

By following these guidelines, we can build a robust and useful set of development tools that enhance our workflow.
