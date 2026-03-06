---
title: "Implement Global -C (Change Directory) Option for ace-* CLI Commands"
filename_suggestion: global-cwd-option-for-ace-cli
enhanced_at: 2026-03-05 00:00:00.000000000 +00:00
llm_model: claude-opus-4-6
id: 8ktby7
status: pending
tags:
- cli
- core
- dx
created_at: '2025-09-30 07:57:59'
source: taskflow:v.0.9.0
---

# Implement Global -C (Change Directory) Option for ace-* CLI Commands

## What I Hope to Accomplish

Introduce a global `-C <path>` option for all ace-* CLI commands, mirroring `git -C`. This lets developers and agents execute commands targeting specific gems directly from the project root without physically `cd`-ing first (e.g., `ace-test -C ace-nav`). The option sets the logical working directory for configuration resolution, path lookups, and file operations.

> Additional note: test that commands work correctly from nested directories within the project root tree.

## What "Complete" Looks Like

- **ace-core** CLI parser recognizes `-C <path>` as a global option across all commands
- **ConfigResolver** uses the `-C` path as the starting point for `.ace/` configuration cascade (nearest-wins from specified path)
- **All ace-* gems** propagate `-C` to ace-core's path resolution -- commands like `ace-test`, `ace-bundle`, `ace-review` resolve paths relative to the `-C` target
- **Path normalization**: `-C` path validated against project root to prevent operations outside the mono-repo

## Success Criteria

- `ace-test -C ace-nav` runs tests in ace-nav without changing shell CWD
- `ace-bundle project -C ace-llm` loads ace-llm project context from the root
- Configuration cascade resolves correctly from the `-C` path (gem-level configs take precedence)
- Works from any nested directory within the project root
- Clear error messages for invalid or nonexistent `-C` paths
- All ace-* commands support the option uniformly

## Implementation Approach

1. **CLI Parsing**: extend ace-core's CLI parser to recognize `-C <path>` globally
2. **Configuration Resolution**: ConfigResolver accepts optional base path, all lookups originate from it
3. **Command Propagation**: each ace-* gem's entry point passes `-C` through to ace-core
4. **Path Normalization**: validate and normalize the path against project root

---

## Original Idea

```
each command in ace-* framework should have option -C (current working directory) similar to git -C so we can run tests in certain gem directory without changing directory -> ace-test -C ace-nav
```
