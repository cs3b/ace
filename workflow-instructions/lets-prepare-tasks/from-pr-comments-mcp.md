# Prepare Tasks: From PR Comments (MCP Fetch)

This document outlines the steps to fetch GitHub Pull Request comments and reviews using Model Context Protocol (MCP) server functions and then analyze this data to extract structured requirements. These requirements serve as input for creating actionable development tasks using the main `lets-prepare-tasks` workflow.

## Goal
To utilize MCP server functions (`get_pull_request_comments`, `get_pull_request_reviews`) for retrieving PR feedback and process it into a structured format suitable for use as input for the `breakdown-notes-into-tasks` workflow, typically for a Patch release addressing the feedback.

## Prerequisites
*   Access to an MCP server with GitHub integration and necessary functions enabled.
*   A valid GitHub Pull Request URL.
*   A target release directory path identified (e.g., `docs-project/current/vX.Y.Z-feedback-to-pr-NNN/`).

## Input
*   GitHub Pull Request URL.
*   Target release directory path.

## Process Steps

1.  **Determine Release Path:**
    *   Use the provided target release directory path.
    *   If not provided, determine the appropriate path (e.g., based on current project version and PR number, typically `docs-project/current/v{current_patch+1}-feedback-to-pr-{pr_number}/`). Confirm with the user and create if necessary.
    *   Ensure the target directory structure exists or create it: `{release_path}/docs/comments/` and `{release_path}/docs/reviews/`.

2.  **Fetch PR Data via MCP:**
    *   Parse the PR URL to get the owner, repository, and PR number.
    *   Call the MCP server function `get_pull_request_comments` with the PR details.
    *   For each comment returned, save it as an individual JSON file in `{release_path}/docs/comments/` using the naming convention `comment-{YYYY-MM-DD-HHMM}-{id}.json` (extracting timestamp and ID from the comment data).
    *   Call the MCP server function `get_pull_request_reviews` with the PR details.
    *   For each review returned, save it as an individual JSON file in `{release_path}/docs/reviews/` using the naming convention `review-{YYYY-MM-DD-HHMM}-{id}.json` (extracting timestamp and ID from the review data).
    *   Verify that the JSON files have been created in the correct locations.
        ```bash
        tree {release_path}/docs -L 2 # Verify structure
        ```

3.  **Analyze Fetched Data:**
    *   Scan the individual JSON files within `{release_path}/docs/comments/` and `{release_path}/docs/reviews/`.
    *   Read the content of each comment and review JSON.
    *   Extract key information: author, content, context (file/line if applicable), review status (approved, changes requested), comment/review ID.

4.  **Structure Requirements for Task Definition:**
    *   Group related comments and review feedback by topic, scope, or file affected.
    *   For each logical group, synthesize the feedback into a clear statement of required action or change.
    *   Note the original comment/review IDs associated with each requirement for traceability.
    *   Identify any dependencies between the identified requirements based on the feedback.

5.  **Prepare Output for Breakdown Workflow:**
    *   With the structured requirements extracted from the PR comments, prepare the output in a format suitable for the `breakdown-notes-into-tasks` workflow.
    *   Include the analysis (groupings, associated comment IDs, and identified dependencies) as input for the next step.

## Output
*   Fetched PR data stored in structured JSON files within `{release_path}/docs/comments/` and `{release_path}/docs/reviews/`.\n*   A structured summary of requirements derived from the PR feedback, including groupings, associated comment IDs, and identified dependencies.
*   This summary serves as structured input for the `breakdown-notes-into-tasks` workflow.

## Considerations
{{ ... }}
