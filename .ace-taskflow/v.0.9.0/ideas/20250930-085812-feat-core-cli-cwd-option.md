# Idea

---
title: Implement global -C (change directory) option for ace-* CLI commands
filename_suggestion: feat-core-cli-cwd-option
enhanced_at: 2025-09-30 08:58:12
location: current
llm_model: gflash
---

## Problem
In the ACE mono-repo, executing gem-specific commands (e.g., `ace-test`, `ace-context project`) often requires the user or agent to first `cd` into the target gem's directory (e.g., `ace-nav/`, `ace-context/`). This procedural step breaks workflow fluidity, especially for scripting, automation, or when managing multiple gems simultaneously from the project root. It adds unnecessary overhead and complexity for both human developers and AI agents.

## Solution
Introduce a global `-C <path>` option for all `ace-*` CLI commands, mirroring the behavior of `git -C`. This option would instruct the command to operate as if its current working directory (CWD) were `<path>`, without physically changing the shell's CWD. For example, `ace-test -C ace-nav` would run tests specifically within the `ace-nav` gem, or `ace-context project -C ace-llm` would load project context relevant to the `ace-llm` gem.

## Implementation Approach
This feature would primarily be implemented within the `ace-core` gem, as it handles the foundational CLI parsing and configuration resolution for all `ace-*` tools. 

1.  **CLI Parsing**: The `ace-core`'s CLI parser (likely an Atom or Molecule) would be extended to recognize the global `-C <path>` option across all commands.
2.  **Configuration Resolution**: The `ConfigResolver` (an Organism in `ace-core`) would be enhanced to accept an optional base path (provided by the `-C` argument). When this option is present, all configuration lookups (e.g., the `.ace/` cascade) and relative path resolutions would originate from this specified path instead of the actual shell CWD. This ensures `nearest-wins` config resolution from the `-C` path.
3.  **Command Execution Context**: Each `ace-*` gem's CLI entry point would need to be updated to accept and correctly propagate this global `-C` option to `ace-core`'s configuration and path resolution logic. Commands like `ace-test` would then automatically resolve their internal paths (e.g., `test/` directory, `Rakefile`) relative to the `-C` path.
4.  **Path Normalization**: Ensure that the provided `-C` path is normalized and validated against the project root to prevent security issues or unintended operations outside the mono-repo.

## Considerations
-   **Configuration Cascade Interaction**: The `-C` option must correctly define the starting point for the `.ace/` configuration cascade, ensuring that configurations within the specified gem's directory take appropriate precedence.
-   **Scope**: While the idea suggests "each command," it's crucial to confirm that all `ace-*` commands can meaningfully leverage this, or if some might require specific handling. The aim is for universal applicability.
-   **Internal CWD for Commands**: Commands should internally use the `-C` path for all relevant file operations, not just configuration, to ensure consistent behavior.
-   **Error Handling**: Clear error messages should be provided if the specified `-C` path is invalid or does not exist.

## Benefits
-   **Streamlined Workflow**: Developers and AI agents can execute commands targeting specific gems directly from the project root, significantly improving efficiency and reducing context switching.
-   **Enhanced Scripting and Automation**: Simplifies automation scripts that interact with individual `ace-*` gems, making them more robust, readable, and easier to maintain.
-   **Consistency**: Aligns with common CLI patterns (e.g., `git -C`), making ACE tools more intuitive and familiar to use.
-   **AI-Native Design**: Enables AI agents to orchestrate operations across the mono-repo with greater precision and less procedural overhead, fostering more complex autonomous workflows.

---

## Original Idea

```
each command in ace-* framework should have option -C (current working directory) similar to git -C so we can run tests in cartain gem directory without changing directory -> ace-test -C ace-nav
```

---
Captured: 2025-09-30 08:57:56