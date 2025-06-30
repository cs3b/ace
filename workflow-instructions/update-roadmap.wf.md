# Workflow Instruction: Update Roadmap

**Goal:** Propose, review, and apply updates to `dev-taskflow/roadmap.md` ensuring the roadmap remains an accurate strategic guide.

## Prerequisites

* Write access to `dev-taskflow/roadmap.md`
* Understanding of semantic versioning (v.X.Y.Z format)
* Access to project folder structure (`dev-taskflow/backlog/`, `current/`, `done/`)

## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`

## Process Steps

1. **Load and Validate Roadmap**
   * Confirm the file exists at `dev-taskflow/roadmap.md`
   * Load its content and validate structure against embedded format requirements (see below)
   * If validation fails, note specific violations for correction

2. **Validate Roadmap Structure**
   The roadmap MUST contain these sections in order:

   ```yaml
   ---
   title: Project Roadmap
   last_reviewed: YYYY-MM-DD
   status: [draft|active|archived]
   ---
   ```

   Required sections:
   1. **Project Vision** - Inspirational statement of long-term mission
   2. **Strategic Objectives** - Measurable 6-12 month outcomes
   3. **Key Themes & Epics** - Grouped work areas
   4. **Planned Major Releases** - Concrete release targets
   5. **Cross-Release Dependencies** - Dependencies between releases
   6. **Update History** - Change tracking

3. **Update Release Status**
   * Check current release folder locations:
     * `dev-taskflow/backlog/` - Future releases (should appear in roadmap)
     * `dev-taskflow/current/` - Active releases (should be linked in roadmap)
     * `dev-taskflow/done/` - Completed releases (should be removed from roadmap)
   * Update roadmap links to reflect current release status
   * Remove completed releases from "Planned Major Releases" section
   * Update cross-release dependencies if they reference completed releases

4. **Draft Changes**
   * Source proposed changes from the input document or prompt
   * Create a markdown checklist of proposed changes:

   ```markdown
   - [ ] Add Objective: "Simplify contributor onboarding" (metric: onboarding ≤30 min)
   - [ ] Add Release v.0.4.0 "Autopilot" Q1 2026
   - [ ] Remove completed release v.0.2.0 from roadmap (moved to done/)
   ```

5. **Apply Updates Using Embedded Formats**

   Use the roadmap table templates:

6. **Apply Specific Updates**
   * Edit `roadmap.md` following the format requirements:
     * Increment `last_reviewed` date in front matter
     * Apply all drafted changes to relevant sections
     * Add new entry to Update History table with today's date
     * Ensure version format follows v.X.Y.Z pattern
     * Use "QX YYYY" format for target windows

7. **Validate Post-Update**
   * Verify roadmap sections are complete and in correct order
   * Check that all tables have correct column headers
   * Confirm release folders match roadmap entries:
     * All releases in `backlog/` appear in roadmap
     * No releases in `done/` appear in roadmap
     * Active releases in `current/` are properly represented
   * Validate no broken references remain
   * Ensure Update History includes new entry

8. **Commit Changes**
   * Use specific commit messages based on change type:
     * New release: `docs(roadmap): add release v.X.Y.Z-codename to planned releases`
     * Remove completed: `docs(roadmap): remove completed v.X.Y.Z-codename from planned releases`
     * Update objectives: `docs(roadmap): update strategic objectives for Q3 2025`
     * General updates: `docs(roadmap): [specific change description]`

9. **Notify Stakeholders**
   * Post link to changes in communication channel
   * Highlight significant strategic changes

## Roadmap Format Requirements

### Front Matter Validation

* MUST use YAML format with exactly these fields
* `title` must be "Project Roadmap"
* `last_reviewed` must use ISO date (YYYY-MM-DD)
* `status` must be one of: draft, active, archived

### Content Guidelines

* **Vision**: 1-3 sentences, inspirational, avoid technical jargon
* **Objectives**: Outcome-focused (not activity-focused), measurable metrics
* **Themes**: 2-4 word names, 1-2 sentence descriptions
* **Releases**: Semantic versioning, memorable codenames in quotes
* **Dependencies**: Focus on blocking dependencies only
* **History**: Add entry for every significant change

### Quality Criteria

* Language must be clear and professional
* All content should support the project vision
* Information must be current and relevant
* Cross-references must be accurate

## Error Handling

**Format Validation Failures:**

* Halt process and report specific violations
* List each section that doesn't meet requirements
* Require corrections before proceeding

**Release Status Inconsistencies:**

* Report which releases are in wrong locations
* List discrepancies between folders and roadmap
* Require manual reconciliation

**Cross-Reference Errors:**

* Identify all broken references
* List dependencies that reference non-existent items
* Update or remove broken references

**Git Operation Failures:**

* Preserve roadmap changes locally
* Report specific Git error
* Allow manual commit if needed

## Integration with Release Workflows

This workflow is called by:

* **Draft-Release Workflow**: After creating new release structure (step 7)
* **Publish-Release Workflow**: When archiving completed releases (step 15)

Requirements:

* Roadmap updates MUST be committed separately from other changes
* Failed updates in release workflows should halt the process
* Always validate against actual folder structure

## Output / Success Criteria

* Updated `dev-taskflow/roadmap.md` with all changes applied
* Release status accurately reflects project folder structure
* Completed releases removed and noted in Update History
* All validation checks pass
* Commit successfully merged

## Common Patterns

### Adding a New Release

```markdown
| v.0.4.0 | "Autopilot" | Q1 2026 | Enable autonomous task execution | AI Integration, Workflow Engine |
```

### Removing Completed Release

1. Delete entire row from Planned Major Releases table
2. Remove any references from Cross-Release Dependencies
3. Add Update History entry: "Remove completed v.X.Y.Z from roadmap"

### Updating Objectives

```markdown
| 3 | Improve developer onboarding experience | Average setup time ≤ 30 minutes |
```

## Usage Example
>
> "Update the roadmap to add the new v.0.4.0 'Autopilot' release and remove the completed v.0.2.0 release"

---

This workflow maintains the strategic roadmap document, ensuring it accurately reflects project direction and current release status through structured validation and updates.

<templates>
    <template path="dev-handbook/templates/release-planning/release-readme.template.md"># v.x.x.x [Codename]

## Release Overview

Brief description of the release's main purpose and value proposition.

## Release Information

* **Type**: [Major | Feature | Bug Fix]
* **Start Date**: YYYY-MM-DD
* **Target Date**: YYYY-MM-DD
* **Release Date**: YYYY-MM-DD
* **Status**: [Planning | In Progress | Released]

## Goals & Requirements

### Primary Goals

* [ ] Goal 1
  * Success Metrics:
  * Acceptance Criteria:
  * Implementation Strategy:
  * Dependencies & Status:
  * Risks & Mitigations:

## Implementation Plan

### Core Components

1. **Design & Architecture**:
   * [ ] Public interfaces
   * [ ] Class/module structure
   * [ ] Breaking changes & migrations

   ```ruby
   # Core interfaces/components needed
   ```

2. **Dependencies**:
   * [ ] External gems
   * [ ] Internal components
   * [ ] Configuration changes

3. **Implementation Phases**:
   * [ ] Phase 1: Preparation
     * Setup & infrastructure
     * Interface definitions
   * [ ] Phase 2: Core Development
     * Component implementations
     * Integration work
   * [ ] Phase 3: Testing & Validation
     * Unit & integration tests
     * Performance benchmarks
   * [ ] Phase 4: Documentation & Release
     * API docs & examples
     * Release preparation

## Quality Assurance

### Test Coverage

* [ ] Unit Tests
  * Core functionality
  * Edge cases
* [ ] Integration Tests
  * Component interaction
  * System integration
* [ ] Performance Tests
  * Benchmarks
  * Load testing

## Release Checklist

* [ ] All features implemented
* [ ] Tests passing & coverage met
* [ ] Documentation complete
  * API documentation
  * Usage examples
  * Migration guide
* [ ] Performance verified
* [ ] Security review complete
* [ ] CHANGELOG updated
* [ ] Release notes prepared
</template>

</templates>
