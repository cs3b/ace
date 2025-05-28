# Prepare Tasks: From Product Requirements Document (PRD)

This document outlines the steps to analyze a high-level Product Requirements Document (PRD) to extract the
product vision, propose a potential release strategy, and identify foundational requirements. This analysis
serves as input for creating the necessary project structure and initial tasks using the main
`breakdown-notes-into-tasks` workflow.

## Goal

To translate a broad product vision from a PRD into a structured analysis, including a suggested release plan
and key initial requirements, producing structured notes suitable for use as input for the
`breakdown-notes-into-tasks` workflow.

## Prerequisites

* A PRD available (file path or pasted content).
* Understanding of the overall project context (if any exists).

## Input

* The PRD content (file path or pasted text).

## Process Steps

1. **Load and Parse PRD:**
    * Access and read the content of the provided PRD.
    * Parse the document to identify core product goals, key features/epics, target audience, high-level
      architectural concepts, and success metrics.

2. **High-Level Analysis & Release Strategy Proposal:**
    * Synthesize the core product vision and goals.
    * Based on the scope and complexity described in the PRD, analyze potential ways to break down the work.
    * Propose a high-level release strategy (e.g., suggesting major milestones like MVP v1.0, followed by
      subsequent feature releases v1.1, v1.2, or major versions v2.0). Include brief justifications for the
      proposed breakdown.
    * Present this proposed strategy to the user for confirmation or modification.

3. **Identify Foundational Requirements:**
    * Based on the PRD and the confirmed release strategy (focusing on the *first* planned release, e.g., v1.0):
        * Identify essential setup tasks (e.g., repository initialization, CI/CD setup, core dependency selection).
        * Identify core architectural components that need to be established early.
        * Identify critical decisions likely needed upfront (potential ADR topics).
        * Identify foundational documentation required (e.g., initial README, core architectural diagrams, `what-do-we-build.md`).

4. **Structure Analysis for Task Definition:**
    * Organize the analysis into a clear structure:
        * Confirmed high-level release plan/roadmap.
        * List of foundational requirements (setup, architecture, decisions, docs) for the initial
          release.
        * High-level goals for subsequent planned releases.

5. **Prepare Output for Breakdown Workflow:**
    * With the structured analysis from the PRD, prepare the output in a format
      suitable for the `breakdown-notes-into-tasks` workflow.
    * Include the analysis (release strategy, foundational requirements, high-level goals
      for subsequent releases) as input for the next step.

* This summary serves as structured input for the `breakdown-notes-into-tasks` workflow.

## Output

* A structured analysis document containing:
  * The confirmed high-level release strategy.
  * A list of foundational requirements (setup, architecture, decisions, documentation) for the initial release.
  * High-level goals for subsequent planned releases.
* This analysis serves as structured input for the `breakdown-notes-into-tasks` workflow.
