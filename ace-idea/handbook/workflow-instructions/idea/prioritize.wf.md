---
doc-type: workflow
title: Prioritize and Align Ideas
purpose: Documentation for ace-idea/handbook/workflow-instructions/idea/prioritize.wf.md
ace-docs:
  last-updated: 2026-03-01
  last-checked: 2026-03-21
---

# Prioritize and Align Ideas

## Goal

Systematically organize, prioritize, and align queued ideas with current project architecture to create an actionable implementation roadmap.

## Prerequisites

* Access to the project's ideas directory and current queue folders
* Understanding of project's architecture patterns
* Access to project documentation in `docs/` directory
* Knowledge of existing tools and workflows

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Process Steps

### 1. **Analyze Current Ideas:**
   * List all files in the project's current idea queues
   * Read each idea file to understand:
     - Problem being solved
     - Proposed solution
     - Expected impact
     - Implementation complexity
   * Group ideas by theme or category
   
   **Validation:**
   * All idea files have been read and cataloged
   * Ideas are grouped into logical categories

### 2. **Determine Prioritization Scope:**
   * Define number of ideas to prioritize:
     - Default: Top 10 most impactful
     - Configurable: `--count N` for specific number
     - All: `--all` to process entire backlog
   * Apply prioritization criteria:
     - Impact: Critical > High > Medium > Low
     - Complexity: Hours > Days > Weeks
     - Dependencies: Independent > Few > Many
   
   **Validation:**
   * Clear list of ideas to be processed
   * Prioritization rationale documented

### 3. **Research Project Architecture:**
   * Identify project's technical patterns:
     ```bash
     # For Ruby projects
     ls -1 exe/ lib/*/
     
     # For Node.js projects  
     ls -1 src/ bin/
     
     # For generic projects
     find . -type f -name "*.md" | head -20
     ```
   * Review existing tools and utilities
   * Understand naming conventions and structure
   * Identify workflow instruction patterns (if applicable)
   
   **Validation:**
   * Project structure documented
   * Key architectural patterns identified
   * Existing tools inventory complete

### 4. **Prioritize Ideas Using Folder Updates:**
   * Use `ace-idea update --move-to` to place ideas into priority folders
   * Priority levels:
     - **High priority** (Critical impact, low complexity): Move to `_next`
     - **Medium priority** (High impact or medium complexity): Move to `_maybe`
     - **Lower priority** (remaining ideas): Move to `_anytime`

   * Update pattern:
     ```bash
     # Place highest priority ideas in next queue
     ace-idea update <idea-1> --move-to next

     # Place medium priority ideas in maybe folder
     ace-idea update <idea-2> --move-to maybe

     # Place lower priority ideas in anytime folder
     ace-idea update <low-priority-idea> --move-to anytime
     ```

   **How it works:**
   * Updates move idea files between folders (`_next`, `_maybe`, `_anytime`)
   * Ideas are listed per folder when using `ace-idea list --in <folder>`
   * The same command can also update metadata such as `status` when needed

   **Validation:**
   * Running `ace-idea list --in next` shows high-priority ideas
   * Can re-prioritize later by moving ideas between folders again

### 5. **Align Ideas with Project Architecture:**
   For each prioritized idea:
   * Update file paths to match project structure
   * Reference existing tools and utilities
   * Align with project's architectural patterns
   * Include implementation approach specific to project
   * Add testing strategy appropriate to project
   * Define measurable success metrics
   
   Template for aligned idea:
   ```markdown
   # [Improvement Name]
   
   ## Intention
   [Clear problem statement]
   
   ## Problem It Solves
   **Current Issues:**
   **Impact:**
   
   ## Solution Direction
   ### Implementation Approach
   [Project-specific implementation details]
   
   ### Integration Points
   [How it fits with existing architecture]
   
   ## Implementation Plan
   Phase 1: [Core functionality]
   Phase 2: [Enhancements]
   
   ## Testing Strategy
   [Project-appropriate testing approach]
   
   ## Success Metrics
   [Measurable outcomes]
   ```
   
   **Validation:**
   * Ideas reference correct project paths
   * Implementation aligns with project patterns
   * Testing approach matches project standards

### 6. **Create Implementation Roadmap:**
   Generate `000-implementation-roadmap.md` containing:
   * Executive summary of prioritized improvements
   * Ordered list with effort estimates
   * Implementation timeline (weekly/sprint-based)
   * Technical dependencies and risks
   * Success metrics and governance
   
   **Validation:**
   * Roadmap provides clear action plan
   * Timeline is realistic and achievable
   * Dependencies clearly identified

### 7. **Clean Up and Finalize:**
   * Remove any temporary files created during process
   * Verify prioritized ideas are in the expected folders
   * Verify folder contents with `ace-idea list --in next`, `ace-idea list --in maybe`, and `ace-idea list --in anytime`
   * Create summary of changes for commit message

   **Validation:**
   * No temporary files remain
   * Folder listings reflect the intended priorities
   * `ace-idea list --in next` shows the most actionable ideas
   * Git status shows the expected renamed or moved idea directories
   * Ready for review and commit

## Success Criteria

* All selected ideas are placed in the intended priority folders
* Ideas aligned with current project architecture
* Implementation roadmap created with clear timeline
* No broken references or missing dependencies
* `ace-idea list --in next` displays the highest-priority ideas
* Changes ready for version control commit

## Error Handling

**Missing Architecture Documentation:**
* **Symptoms:** No docs/ directory or architecture files
* **Solution:** Infer from project structure and existing code

**Conflicting Priorities:**
* **Symptoms:** Multiple ideas with same impact/complexity
* **Solution:** Use additional criteria (dependencies, risk, user value)

**Large Backlogs (>50 ideas):**
* **Symptoms:** Too many ideas to process effectively
* **Solution:** Focus on top 20, schedule remaining for future cycles

## Usage Example

> "Organize and prioritize our backlog of 47 improvement ideas, focusing on the top 10 most impactful ones that we can implement this quarter"

## Common Patterns

### For Different Project Types

**Ruby/Rails Projects:**
* Look for `exe/`, `lib/`, `spec/` directories
* Reference Gemfile for dependencies
* Align with RSpec testing patterns

**Node.js Projects:**
* Look for `src/`, `bin/`, `test/` directories
* Reference package.json for dependencies
* Align with Jest/Mocha testing patterns

**Python Projects:**
* Look for `src/`, `tests/`, `scripts/` directories
* Reference requirements.txt/pyproject.toml
* Align with pytest patterns

**Generic Projects:**
* Focus on `docs/` directory structure
* Identify primary language from file extensions
* Use general software patterns
