# Prepare Tasks: From PR Comments (API Fetch)

This document outlines the steps to fetch GitHub Pull Request comments and reviews using the API (via the `docs-dev/tools/get-github-pr-data.rb` script) and then analyze this data to extract structured requirements. These requirements serve as input for creating actionable development tasks using the main `lets-prepare-tasks` workflow.

## Goal
To automate the retrieval of PR feedback using the GitHub API and process it into a structured format suitable for task definition, typically for a Patch release addressing the feedback.

## Prerequisites
*   Ruby environment and required gems installed (for the `get-github-pr-data.rb` script).
*   A `.env` file in `docs-dev/tools/` with a valid `GITHUB_TOKEN`.
*   A valid GitHub Pull Request URL.
*   A target release directory path identified (e.g., `docs-project/current/vX.Y.Z-feedback-to-pr-NNN/`).

## Input
*   GitHub Pull Request URL.
*   Target release directory path.

## Process Steps

1.  **Determine Release Path:**
    *   Use the provided target release directory path.
    *   If not provided, determine the appropriate path (e.g., based on current project version and PR number, typically `docs-project/current/v{current_patch+1}-feedback-to-pr-{pr_number}/`). Confirm with the user and create if necessary.

2.  **Fetch PR Data via API:**
    *   Parse the PR URL to get the owner, repository, and PR number.
    *   Execute the fetching script:
        ```bash
        ruby docs-dev/tools/get-github-pr-data.rb \
          --owner {owner} \
          --repo {repo} \
          --pr {number} \
          --dir {release_path}
        ```
    *   Verify the script successfully created the timestamped subdirectory (e.g., `pr-{number}-YYYYMMDD-HHMMSS/`) within `{release_path}/docs/` containing the `comments/`, `reviews/`, and `pr/` subdirectories with individual JSON files.
        ```bash
        tree {release_path}/docs -L 3 -I raw # Verify structure
        ```

3.  **Analyze Fetched Data:**
    *   Scan the individual JSON files within `{release_path}/docs/{pr_path}/comments/` and `{release_path}/docs/{pr_path}/reviews/`.
    *   Read the content of each comment and review.
    *   Extract key information: author, content, context (file/line if applicable), review status (approved, changes requested).

4.  **Structure Requirements for Task Definition:**
    *   Group related comments and review feedback by topic, scope, or file affected.
    *   For each logical group, synthesize the feedback into a clear statement of required action or change.
    *   Note the original comment/review IDs associated with each requirement for traceability.
    *   Identify any dependencies between the identified requirements based on the feedback.

5.  **Proceed to Task Creation:**
    *   With the structured requirements extracted from the PR comments, proceed to the main [../prepare-tasks.md](../prepare-tasks.md) workflow.
    *   Use this analysis (including comment IDs and dependencies) as input to define clear, actionable task(s) adhering to the [write-actionable-task.md](docs-dev/guides/write-actionable-task.md) guide.

## Output
*   Fetched PR data stored in structured JSON files within `{release_path}/docs/{pr_path}/`.
*   A structured summary of requirements derived from the PR feedback, including groupings, associated comment IDs, and identified dependencies.
*   This summary serves as direct input for the task creation process defined in `../prepare-tasks.md`.

### Deliverables

*   A structured summary document (`PR_ANALYSIS_summary.md`) outlining key requirements, scope, and acceptance criteria derived from the PR comments.
*   This summary serves as direct input for the task creation process defined in `../prepare-tasks.md`.

## Considerations
{{ ... }}
