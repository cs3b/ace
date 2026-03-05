---
title: Add `--diff` flag to `ace-review` for Git range-based code reviews
filename_suggestion: feat-review-diff-flag
enhanced_at: 2025-11-27 22:14:07.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-12-09 00:24:44.000000000 +00:00
id: 8mqxcl
tags: []
created_at: '2025-11-27 22:13:58'
---

# Add `--diff` flag to `ace-review` for Git range-based code reviews

## Problem
Currently, `ace-review` allows users to specify files or rely on the current working directory for code reviews. While a `--subject` flag can guide the review, there isn't a direct, standardized mechanism to instruct `ace-review` to specifically analyze changes within a given Git diff range (e.g., `main..HEAD`, `commit_sha`, or `commit_sha1..commit_sha2`). This limitation forces agents or human users to manually identify, stage, or select files corresponding to a diff, which is inefficient and can lead to incomplete or inaccurate reviews, especially for complex changes or when reviewing pull requests locally.

## Solution
Introduce a new `--diff` flag to the `ace-review` CLI. This flag will accept a standard Git diff range (e.g., `main..HEAD`, `commit_sha`, `commit_sha1..commit_sha2`). When the `--diff` flag is provided, `ace-review` will automatically:
1.  Identify all files that have changed within the specified Git range.
2.  Construct the review context by either providing the raw `git diff` output or by loading the relevant file versions and highlighting changes.
3.  Implicitly set or augment the review subject to reflect the nature of the diff (e.g., "Review changes from `main..HEAD`"), similar to how the `--pr` flag provides context for pull requests.
This enhancement will provide a deterministic and efficient way to scope code reviews precisely to specific Git changes.

## Implementation Approach
1.  **`ace-review` CLI Update**: The `ace-review` gem's `lib/ace/review/commands/cli.rb` (Thor CLI) will be updated to include the `--diff` option, accepting a string argument for the Git range.
2.  **Git Interaction (Molecules/Organisms)**: A new `Molecule` or `Organism` within `ace-review` will be developed to handle Git interactions. This component will leverage existing Git utilities (potentially from `ace-git-commit`'s underlying logic or direct `git` command execution) to:
    *   Parse and validate the provided diff range.
    *   Execute `git diff --name-only <range>` to obtain the list of affected files.
    *   Execute `git diff <range>` to retrieve the actual diff content, ensuring deterministic and parseable output.
3.  **Context Generation (Organisms)**: The `Organism` responsible for assembling the LLM prompt will utilize the identified files and diff content to construct the `user.prompt.md`. It will establish clear precedence rules for how `--diff` interacts with other file selection flags (e.g., `--files`) and the `--subject` flag.
4.  **Prompt Caching**: The `PromptCacheManager` from `ace-support-core` will be used to cache the generated system and user prompts, along with metadata detailing the Git range used for the review, in the standard `.cache/ace-review/sessions/{operation}-{timestamp}/` structure.

## Considerations
-   **Flag Precedence**: Define clear rules for how `--diff` interacts with other flags like `--files` or `--subject`. `--diff` should primarily define the *scope* of files, potentially overriding or augmenting the *subject* if not explicitly provided.
-   **Error Handling**: Implement robust error handling for invalid Git ranges, non-existent SHAs, or scenarios where the Git repository is not clean or accessible.
-   **LLM Context Management**: For very large diffs, consider strategies to summarize, chunk, or prioritize parts of the diff content to fit within LLM context windows, potentially integrating with `ace-context`'s capabilities.
-   **CLI Documentation**: Ensure the `--diff` flag's behavior, usage examples, and interactions with other flags are thoroughly documented in `ace-review/docs/usage.md` and relevant `ace-review/handbook/workflow-instructions/*.wf.md` files.
-   **Testing**: Comprehensive unit and integration tests (leveraging `ace-test-support`) will be developed to cover various Git range scenarios, edge cases, and flag combinations.

## Benefits
-   **Enhanced Precision**: Allows agents and human developers to precisely scope code reviews to specific changes, significantly reducing noise and improving focus on relevant modifications.
-   **Streamlined Workflow**: Automates the process of identifying and preparing files for review based on Git history, saving time and reducing manual effort for both human and AI users.
-   **Improved Agent Autonomy**: Provides a deterministic and programmatic way for AI agents to initiate targeted code reviews, enabling seamless integration into automated CI/CD pipelines or advanced development workflows.
-   **Consistency**: Aligns `ace-review` with common Git-based development practices and enhances its consistency with other `ace-*` tools that interact with Git.
-   **Debugging and Auditability**: The standardized prompt caching mechanism will allow easy inspection of the exact diff content and prompts sent to the LLM for review, aiding in debugging and understanding agent behavior.

---

## Original Idea

```
ace-review should have a shortcut flag --diff where we can pass range ir sha (then sha...HEAD) and it should overwrite subject, similar to have --pr have a special use case
```