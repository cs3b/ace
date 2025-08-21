---
:input_tokens: 91288
:output_tokens: 1086
:total_tokens: 92374
:took: 3.741
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-21T20:56:26Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 91288
:cost:
  :input: 0.009129
  :output: 0.000434
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.009563
  :currency: USD
---

# Enhance Git Diff Command for Multi-Repository Awareness

## Intention

To enhance the `git-diff` command to be repository-aware, allowing it to show diffs for specific repositories or across all managed repositories within the toolkit.

## Problem It Solves

**Observed Issues:**
- The current `git-diff` command operates only on the current repository context.
- There is no built-in mechanism to easily view diffs across all submodules (dev-handbook, dev-taskflow, dev-tools) simultaneously.
- Developers need to manually `cd` into each repository to check for changes, which is inefficient.

**Impact:**
- Increased manual effort and time spent checking for changes across the multi-repository structure.
- Potential for missed changes in submodules if manual checks are not thorough.
- Inconsistent visibility into the overall state of the project.

## Key Patterns from Reflections

- **Multi-Repository Architecture**: The project explicitly uses Git submodules (`dev-handbook`, `dev-taskflow`, `dev-tools`) coordinated by `handbook-meta`. This structure necessitates tools that can operate across these repositories.
- **CLI Tooling**: The `dev-tools` gem provides a suite of CLI commands, adhering to ATOM architecture principles, designed to automate developer workflows. Enhancing existing tools like `git-diff` aligns with this pattern.
- **Command Enhancement**: Existing commands can be extended with new flags or functionalities to better serve developer needs, as seen with other `git-*` commands in `dev-tools`.
- **`git-status` Behavior**: The `git-status --short` command already displays status for multiple repositories when sourced correctly. This suggests a precedent for multi-repo awareness in CLI tools.

## Solution Direction

1. **Repository Context Flag**: Introduce a `--repository` flag to the `git-diff` command.
    - This flag would accept a repository name (e.g., `dev-tools`, `dev-handbook`, `dev-taskflow`, `all`) to specify the target for the diff operation.
    - If `--repository all` is used, the command would iterate through all submodule directories and execute `git diff` for each, aggregating the results.
    - If a specific repository name is provided, it would `cd` into that repository's directory before executing `git diff`.
    - If no flag is provided, it would default to operating on the current repository context.
2. **Standardize `git-diff` Usage**: Ensure that `--name-only` and `--repository` flags work seamlessly together, and that the output remains consistent with standard `git diff` output.
3. **Error Handling**: Implement robust error handling for invalid repository names or when Git commands fail within submodules.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact mechanism for identifying all managed submodules in the project? Should this be hardcoded, discovered dynamically, or configured?
2. How should the output be aggregated and presented when diffing across multiple repositories (e.g., prefixing file paths with repository names)?
3. What existing CLI patterns in `dev-tools` can be leveraged for handling repository context or iterating over submodules?

**Open Questions:**
- Should the `--repository` flag accept multiple repository names (e.g., `--repository dev-tools,dev-handbook`)?
- How should diffs be handled if a submodule is not a Git repository or is in an unexpected state?
- What is the desired default behavior if the user is not in the root of the `handbook-meta` repository?

## Assumptions to Validate

**We assume that:**
- All relevant repositories are managed as Git submodules within the `handbook-meta` repository. - *Needs validation*
- Developers using this tool will have Git installed and configured correctly. - *Needs validation*
- The primary use case is to quickly check for uncommitted changes across the entire project ecosystem. - *Needs validation*

## Expected Benefits

- **Increased Developer Efficiency**: Significantly reduces the time and effort required to check for changes across multiple repositories.
- **Improved Project Visibility**: Provides a clear, consolidated view of the current state of all managed repositories.
- **Enhanced Workflow Integration**: Enables more robust automation scripts that depend on knowing the status of all project components.
- **Consistency with `git-status`**: Aligns the behavior of `git-diff` with existing multi-repo awareness patterns in the toolkit.

## Big Unknowns

**Technical Unknowns:**
- The precise method for dynamically discovering all submodule directories and their status.
- The best approach for presenting aggregated diff output from multiple repositories in a clear and actionable format.

**User/Market Unknowns:**
- How frequently developers will need to diff across all repositories versus specific ones.
- Whether developers prefer explicit repository selection or an "all" option.

**Implementation Unknowns:**
- The impact of this change on the existing `git-diff` command's test suite.
- The best way to integrate this functionality into the existing CLI framework (`dry-cli`).

> SOURCE

```text
michalczyz  …/handbook-meta   master !⇡   v24.5.0 on ☁️  admin@gcp.cs3b.com
 ♥ 21:32 ➜ git-diff df8f6e2..HEAD --name-only --repository dev-tools
No changes found across repositories

michalczyz  …/handbook-meta   master !⇡   v24.5.0 on ☁️  admin@gcp.cs3b.com
 ♥ 21:50 ➜ git-diff -C dev-tools df8f6e2..HEAD --name-only
No changes found across repositories
```
