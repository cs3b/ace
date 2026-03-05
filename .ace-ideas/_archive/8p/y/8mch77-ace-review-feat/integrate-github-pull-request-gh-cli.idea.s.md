---
title: Enhance `ace-review` for GitHub Pull Request Integration with `gh` CLI
filename_suggestion: feat-review-pr-gh-comments
enhanced_at: 2025-11-13 11:28:55.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-11-16 14:07:04.000000000 +00:00
id: 8mch77
tags: []
created_at: '2025-11-13 11:27:59'
---

# Enhance `ace-review` for GitHub Pull Request Integration with `gh` CLI

## Problem
Currently, `ace-review` primarily focuses on local diffs or specified files, requiring manual steps for AI agents to review remote GitHub Pull Requests (PRs). This creates a disconnect in the AI-assisted development workflow, as agents cannot directly fetch PR diffs, apply review logic, and post comments back to the PR without external orchestration. This limits the autonomy and efficiency of `ace-review` in a collaborative, GitHub-centric environment.

## Solution
Extend `ace-review` to natively support GitHub Pull Request integration. This will involve adding new CLI options, such as `--pull-request <PR_NUMBER_OR_URL>` or `-pr <PR_NUMBER_OR_URL>`, to enable `ace-review` to fetch the diff of a specified PR directly. The `gh` CLI tool will be leveraged for robust interaction with the GitHub API to retrieve PR details and diffs. After performing the LLM-powered analysis using `ace-llm`, `ace-review` will have an option to post the generated review comments directly to the GitHub PR, in addition to saving the review output locally.

## Implementation Approach
1.  **`ace-review` Extension**: The core `ace-review` gem will be modified to include new `Thor` commands or options within `lib/ace/review/commands/cli.rb` to accept PR identifiers.
2.  **`gh` CLI Integration**: A new `molecule` or `organism` within `ace-review` (e.g., `lib/ace/review/molecules/github_pr_fetcher.rb` and `lib/ace/review/organisms/github_pr_commenter.rb`) will be responsible for:
    *   Executing `gh pr diff <PR_IDENTIFIER>` to retrieve the PR's diff.
    *   Executing `gh pr comment <PR_IDENTIFIER> --body "<REVIEW_COMMENT>"` to post the review.
    *   Error handling and parsing `gh` CLI output.
3.  **LLM Integration**: The fetched PR diff will be passed to `ace-llm` via `ace-review`'s existing LLM integration points for analysis, generating the review content.
4.  **Configuration**: Utilize `ace-support-core` for managing configuration related to GitHub (e.g., `GITHUB_TOKEN` environment variable, default review presets for PRs, dry-run options).
5.  **Handbook Updates**: Update `ace-review/handbook/workflow-instructions/*.wf.md` and `ace-review/handbook/agents/*.ag.md` to provide examples and guidance for AI agents on how to use this new PR review capability.

## Considerations
-   **Authentication**: Ensure seamless integration with `gh` CLI's authentication mechanisms (e.g., `GITHUB_TOKEN` environment variable or `gh auth login`).
-   **Permissions**: Clearly document the necessary GitHub permissions (read access for diffs, write access for comments) for the token used.
-   **Output Format**: Design the generated review comment to be clear, concise, and formatted appropriately for GitHub (e.g., Markdown, code suggestions).
-   **Idempotency & Updates**: Implement logic to prevent duplicate comments or to update existing comments if a review is re-run on the same PR.
-   **Error Handling**: Robust error handling for `gh` CLI failures, network issues, and LLM processing errors.
-   **Rate Limiting**: Consider GitHub API rate limits when fetching diffs or posting comments, potentially with retry mechanisms.
-   **Configuration Cascade**: Allow project-specific overrides for PR review behavior via `.ace/review/config.yml`.

## Benefits
-   **Enhanced Agent Autonomy**: Enables AI agents to fully participate in the GitHub Pull Request workflow, from fetching diffs to posting comments.
-   **Streamlined Workflow**: Significantly reduces the manual effort required to integrate `ace-review` into PR review processes.
-   **Improved Code Quality**: Facilitates earlier and more consistent AI-assisted code reviews directly within the development cycle.
-   **Increased Efficiency**: Accelerates the review process by automating the diff retrieval and comment posting steps.
-   **Completeness**: Positions `ace-review` as a more comprehensive and indispensable tool within the ACE ecosystem for AI-driven development.

---

## Original Idea

```
ace-review should have option to run review on the -pr --pull-request, using gh so we can review any PR diff (as subject) and save to review also to PR as comment
```