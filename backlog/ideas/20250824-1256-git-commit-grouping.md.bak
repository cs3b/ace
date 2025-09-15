---
:input_tokens: 115057
:output_tokens: 1018
:total_tokens: 116075
:took: 3.827
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-24T11:57:04Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 115057
:cost:
  :input: 0.011506
  :output: 0.000407
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.011913
  :currency: USD
---

# Improve Git Commit Handling for Large Changes

## Intention

To enhance the `git-commit` tool to group files by commit message intention when dealing with large changes, thereby improving the clarity and organization of commit histories.

## Problem It Solves

**Observed Issues:**
- When making numerous changes to many files, `git-commit` currently creates a single commit for all changes, potentially leading to a very large and unfocused commit message.
- Users lack a mechanism to automatically group related files into multiple logical commits within a single `git-commit` command execution.
- The current output for large changes is a single, monolithic commit, making it difficult for reviewers and future developers to understand the distinct logical units of work.

**Impact:**
- Large, unfocused commits obscure the intent behind different sets of changes.
- Code reviews become more challenging as reviewers must sift through unrelated changes in a single commit.
- Reverting specific logical changes within a large commit is difficult and error-prone.
- Maintaining a clean and understandable Git history becomes a manual and tedious process.

## Key Patterns from Reflections

- **ATOM Architecture**: The `git-commit` tool is an `Organism` that likely uses `Molecules` for Git interaction (e.g., `CommitMessageGenerator`, `GitCommandExecutor`) and `Atoms` for basic utilities.
- **LLM Integration**: The tool likely uses LLMs to generate commit messages based on code diffs and user intentions. This enhancement will require LLM to understand and group changes.
- **CLI Tool Patterns**: The tool follows established CLI patterns with flags and arguments for customization.
- **Workflow Self-Containment**: Any new functionality should ideally be executable within a single workflow, making the grouped commit output a desirable feature for AI agents.
- **Documentation-Driven Development**: This improvement should be reflected in the `git-commit` tool's documentation and potentially new workflow instructions.

## Solution Direction

1. **Grouped Commit Generation**: Implement logic to analyze the staged changes and identify logical groupings of files based on their modifications or user-specified intentions.
2. **LLM-Assisted Grouping**: Leverage the LLM to suggest and generate separate commit messages for each identified group of files.
3. **Multi-Commit Execution**: Execute multiple `git commit` commands sequentially, one for each generated group of files and message.

## Critical Questions

**Before proceeding, we need to answer:**
1. How will the tool intelligently identify logical groupings of files for separate commits? (e.g., by directory, by feature, by specific intent provided by the user?)
2. What user input or flags will be required to trigger this grouped commit behavior, and how will users specify intentions for each group?
3. How will the tool present the proposed grouped commits to the user for confirmation before execution?

**Open Questions:**
- What is the optimal strategy for determining logical groupings when changes span multiple directories or touch related but distinct functionalities?
- How should the tool handle conflicts or edge cases where grouping is ambiguous or impossible?
- Will this feature require significant changes to the LLM prompt strategy for commit message generation?

## Assumptions to Validate

**We assume that:**
- The underlying Git system can handle multiple `git commit` operations in sequence for staged changes. - *Needs validation*
- An LLM can reliably identify logical groupings of file changes and generate appropriate, distinct commit messages for each group. - *Needs validation*
- Users will find value in having the tool automatically suggest or create multiple commits for large changes, rather than a single large one. - *Needs validation*

## Expected Benefits

- **Improved Commit History**: Git history becomes cleaner, more organized, and easier to navigate.
- **Enhanced Reviewability**: Code reviews are simplified as changes are broken down into logical, digestible commits.
- **Simplified Reverting**: Reverting specific logical changes becomes straightforward.
- **Increased Developer Productivity**: Automates a tedious manual process of splitting large changes into multiple commits.
- **AI Agent Usability**: Enables AI agents to produce more structured and actionable commit histories.

## Big Unknowns

**Technical Unknowns:**
- The specific algorithms or LLM prompting techniques required to accurately group files and generate distinct commit messages for large changes.
- The complexity of managing the staging area and executing multiple commits in a transaction-like manner.

**User/Market Unknowns:**
- How users will prefer to specify intentions for different groups of files (e.g., explicit grouping, implicit suggestions).
- The user interface/UX for confirming and potentially modifying the proposed grouped commits.

**Implementation Unknowns:**
- The impact on the `git-commit` tool's performance when processing very large numbers of staged files.
- The required modifications to the `CommitMessageGenerator` molecule or organism to support this new functionality.
```

> SOURCE

```text
in dev-tools/exe/git-commit - improve handling of large changes - allow to tool return a groups of commits - this files with this message, and this files with this message ...
```
