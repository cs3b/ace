# Prepare Tasks: From Concepts in Backlog

This document outlines the steps to refine vague concept notes (typically files starting with `xx-` in a release `backlog/` directory) into clear requirements, preparing them as input for the main `breakdown-notes-into-tasks` workflow.

## Goal
To process vague concept notes into a structured format suitable for use as input for the `breakdown-notes-into-tasks` workflow, eliciting necessary details through analysis and user interaction.

## Prerequisites
*   A target release directory with a `backlog/` subfolder containing `xx-*.md` concept files.
*   Relevant project context is loaded or available.
*   Optional: A `researches/` subfolder in the release directory may contain related documents.

## Input
*   Path to the target release directory (e.g., `docs-project/backlog/vX.Y.Z/`).

## Process Steps

1.  **Identify Concept Files:**
    *   Scan the `{release_path}/backlog/` directory.
    *   List all files matching the pattern `xx-*.md`. If none, inform the user and stop.

2.  **Gather Information:**
    *   Read the content of each identified `xx-*.md` file.
    *   If a `{release_path}/researches/` directory exists, read the content of relevant files within it.

3.  **Analyze and Generate Clarification Questions:**
    *   For each `xx-*.md` concept file, analyze its content along with project context and research materials.
    *   Identify ambiguities and missing information needed to define an actionable task according to [write-actionable-task.md](docs-dev/guides/write-actionable-task.md).
    *   Generate specific questions focusing on:
        *   **Objective:** What is the primary, measurable outcome?
        *   **Scope:** What is explicitly in and out?
        *   **Key Requirements/Features:** What must the solution achieve?
        *   **Acceptance Criteria:** How will completion and success be verified?
        *   **Dependencies:** Any prerequisites or follow-up work?
        *   **Motivation:** What problem does this solve or value does it add?

4.  **Elicit User Feedback:**
    *   Present the generated questions clearly grouped by the source `xx-*.md` file.
    *   Wait for and record the user's detailed answers.

5.  **Synthesize Requirements:**
    *   Compile the original concept, research findings, and user answers into a clear set of requirements for *each* potential task derived from the concept(s).

6.  **Prepare Output for Breakdown Workflow:**
    *   With the clarified requirements, structure the extracted information into a clear format suitable for the `breakdown-notes-into-tasks` workflow.
    *   **Note:** The handling (deletion/archiving) of the original `xx-*.md` file should occur *after* the corresponding actionable task(s) have been successfully created using the output of this workflow, based on user confirmation.

## Output
*   A set of structured notes for each concept, containing clarified requirements (objective, scope, features, acceptance criteria), ready to be used as input for the `breakdown-notes-into-tasks` workflow.
*   User confirmation regarding the disposition of the original `xx-*.md` files (to be acted upon later).
