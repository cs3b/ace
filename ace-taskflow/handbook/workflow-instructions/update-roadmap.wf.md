---
name: update-roadmap
allowed-tools: Read, Write, Edit, Bash
description: Update project roadmap with current release information and synchronize
  with .ace-taskflow structure
argument-hint: ''
doc-type: workflow
purpose: update-roadmap workflow instruction
update:
  frequency: on-change
  last-updated: '2025-10-02'
---

# Update Roadmap Workflow

## Goal

Synchronize the project roadmap (`.ace-taskflow/roadmap.md`) with the current state of releases and tasks in the `.ace-taskflow/` directory structure. This workflow analyzes release folders, updates the Planned Major Releases table, synchronizes cross-release dependencies, and maintains roadmap format compliance per the Roadmap Definition Guide.

## Prerequisites

* `.ace-taskflow/roadmap.md` exists and follows roadmap-definition.g.md structure
* `.ace-taskflow/` directory contains release folders with release.md files
* `ace-taskflow` CLI tool available for release queries
* `ace-nav` available for workflow protocol support
* Git repository in clean state for committing changes

## Project Context Loading

- Read and follow: `ace-nav wfi://load-project-context`

## Process Steps

### 1. Load Current Roadmap

**Read the existing roadmap document:**

```bash
# Get roadmap path
cat .ace-taskflow/roadmap.md
```

**Capture current state:**
- Front matter metadata (title, last_reviewed, status)
- Existing Planned Major Releases entries
- Cross-Release Dependencies content
- Update History entries

### 2. Validate Roadmap Structure

**Verify roadmap format compliance against roadmap-definition.g.md:**

**Required Sections Check:**
- [ ] Front Matter (YAML with title, last_reviewed, status)
- [ ] Section 1: Project Vision
- [ ] Section 2: Strategic Objectives (table format)
- [ ] Section 3: Key Themes & Epics (table format)
- [ ] Section 4: Planned Major Releases (table format)
- [ ] Section 5: Cross-Release Dependencies
- [ ] Section 6: Update History (table format)

**Front Matter Validation:**
- `title` must be "Project Roadmap"
- `last_reviewed` must use ISO date format (YYYY-MM-DD)
- `status` must be one of: draft, active, archived

**Table Format Validation:**
- Planned Major Releases: 5 columns (Version, Codename, Target Window, Goals, Key Epics)
- Strategic Objectives: 3 columns (#, Objective, Success Metric)
- Key Themes & Epics: 3 columns (Theme, Description, Linked Epics)
- Update History: 3 columns (Date, Summary, Author)

**If validation fails:**
1. Report specific format violations with line references
2. Reference roadmap-definition.g.md for correction requirements
3. HALT process and require manual correction before proceeding

### 3. Analyze Release State

**Discover all releases in .ace-taskflow structure:**

```bash
# Get current release
ace-taskflow release

# List all release directories
ls -d .ace-taskflow/v.*/ 2>/dev/null || echo "No releases found"
```

**For each release found, extract:**
- Version number (from directory name or release.md)
- Codename (from release.md front matter)
- Target window/timeline (from release.md)
- Primary goals (from release.md overview)
- Key epics/themes (from task analysis or release.md)
- Release status (based on folder location and release.md status)

**Categorize releases:**
- **Active/Current**: Releases with in-progress tasks
- **Planned/Future**: Releases with pending tasks
- **Completed**: Releases marked as done (to be removed from roadmap)

### 4. Update Planned Major Releases Table

**Synchronization Rules:**

1. **Add New Releases:**
   - If release exists in `.ace-taskflow/` but NOT in roadmap table
   - Extract release information from release.md
   - Add row to Planned Major Releases table with proper format

2. **Update Existing Releases:**
   - If release exists in both roadmap and `.ace-taskflow/`
   - Compare current information with release.md
   - Update any changed fields (goals, target window, epics)

3. **Remove Completed Releases:**
   - If release is marked done/completed in `.ace-taskflow/`
   - Remove entire row from Planned Major Releases table
   - Ensure release information captured in changelog
   - Document removal in Update History

**Table Format Requirements:**
```markdown
| Version | Codename | Target Window | Goals | Key Epics |
|---------|----------|---------------|-------|-----------|
| v.X.Y.Z | "[Name]" | QX YYYY | [Primary goals] | [Related epics] |
```

**Format Compliance:**
- Version: Semantic versioning (v.X.Y.Z)
- Codename: Quoted string
- Target Window: Quarter and year format
- Goals: Concise description
- Key Epics: Comma-separated if multiple

### 5. Synchronize Cross-Release Dependencies

**Review dependency statements:**

1. **Check for obsolete references:**
   - Identify dependencies mentioning removed releases
   - Identify dependencies mentioning non-existent epics
   - Remove or update obsolete statements

2. **Add new dependencies:**
   - Analyze task dependencies from `.ace-taskflow/` structure
   - Identify cross-release blocking dependencies
   - Add clear dependency statements to Section 5

3. **Maintain dependency clarity:**
   - Each dependency should link specific releases or epics
   - Focus on blocking dependencies only
   - Keep concise and actionable

**Dependency Statement Format:**
```markdown
- [Epic/Release Name] in [Release Version] depends on [Dependency] from [Release Version].
- [Feature] requires completion of [Prerequisite] before [Action].
```

### 6. Update Metadata and History

**Update Front Matter:**
```yaml
---
title: Project Roadmap
last_reviewed: [Today's Date in YYYY-MM-DD]
status: active
---
```

**Add Update History Entry:**

Add new row to Update History table (Section 6) at the TOP:

```markdown
| Date | Summary | Author |
|------|---------|--------|
| YYYY-MM-DD | [Description of changes made] | AI Assistant |
| [Previous entries...] | [...] | [...] |
```

**Summary Guidelines:**
- Mention specific releases added/updated/removed
- Note significant dependency changes
- Keep concise but descriptive
- Example: "Added v.0.9.0 to planned releases; removed completed v.0.8.0"

### 7. Validate Updated Roadmap

**Post-Update Validation:**

1. **Structure Check:**
   - All required sections present
   - All tables properly formatted
   - No broken Markdown syntax

2. **Content Check:**
   - No references to non-existent releases
   - Cross-references are accurate
   - Dates use ISO format
   - Version numbers use semantic versioning

3. **Consistency Check:**
   - Releases in table match `.ace-taskflow/` structure
   - Dependencies reference valid releases/epics
   - Update history reflects changes made

**If validation fails:**
- Report specific issues with line references
- Fix issues before proceeding to commit
- Re-validate after corrections

### 8. Commit Changes

**Stage and commit roadmap updates:**

```bash
# Review changes before committing
git diff .ace-taskflow/roadmap.md

# Stage roadmap file
git add .ace-taskflow/roadmap.md

# Commit with descriptive message
git commit -m "docs(roadmap): update planned releases and synchronize with current state"
```

**Commit Message Format:**
- Use conventional commit format: `docs(roadmap): [description]`
- Be specific about changes (added/updated/removed releases)
- Examples:
  - `docs(roadmap): add v.0.9.0 Mono-Repo to planned releases`
  - `docs(roadmap): remove completed v.0.8.0 from planned releases`
  - `docs(roadmap): synchronize release status with .ace-taskflow structure`

## Error Handling

### Format Validation Errors

**Symptoms:**
- Roadmap structure doesn't comply with roadmap-definition.g.md
- Missing required sections or incorrect table formats
- Invalid front matter or metadata

**Recovery Steps:**
1. Report specific format violations with line numbers
2. Reference roadmap-definition.g.md for correct format
3. HALT process and require manual correction
4. Re-run workflow after corrections

### File System Inconsistencies

**Symptoms:**
- Release folders don't match roadmap entries
- Missing release.md files
- Inconsistent release naming

**Recovery Steps:**
1. Report discrepancies between `.ace-taskflow/` and roadmap
2. Determine authoritative source (usually `.ace-taskflow/` structure)
3. Update roadmap to match actual release state
4. Document assumptions in Update History

### Cross-Reference Failures

**Symptoms:**
- Broken links to releases or epics
- Dependencies referencing non-existent items
- Inconsistent naming across sections

**Recovery Steps:**
1. Identify all broken references
2. Update references to use correct names/versions
3. Remove references to deleted releases
4. Validate all cross-references after fixes

### Git Commit Failures

**Symptoms:**
- Merge conflicts with roadmap.md
- Permission issues
- Repository not in clean state

**Recovery Steps:**
1. Preserve roadmap changes (copy to temp file)
2. Resolve Git conflicts manually
3. Re-apply roadmap updates
4. Re-validate before committing

## Integration with Other Workflows

### Draft-Release Workflow Integration

**Trigger Point:** After step 6 (Populate Overview Document) in draft-release workflow

**Integration Steps:**
1. Draft-release workflow creates new release folder and release.md
2. Call update-roadmap workflow to add release to roadmap
3. Commit roadmap changes separately from release scaffolding
4. Proceed with draft-release workflow step 8

**Commit Message:** `docs(roadmap): add release [version] [codename] to planned releases`

### Publish-Release Workflow Integration

**Trigger Point:** During step 15 (Update Roadmap) in publish-release workflow

**Integration Steps:**
1. Publish-release workflow marks release as done
2. Call update-roadmap workflow to remove release from roadmap
3. Ensure release info captured in changelog before removal
4. Commit roadmap cleanup before final archival

**Commit Message:** `docs(roadmap): remove completed [version] [codename] from planned releases`

### Manual Roadmap Updates

**Use Cases:**
- Adjusting target windows or timelines
- Updating strategic objectives or themes
- Reorganizing release priorities
- Correcting roadmap inconsistencies

**Process:**
1. Make manual edits to roadmap.md
2. Run update-roadmap workflow for validation and sync
3. Workflow will detect manual changes and validate format
4. Commit changes with appropriate message

## Success Criteria

- [ ] Roadmap format validated against roadmap-definition.g.md
- [ ] Planned Major Releases table synchronized with `.ace-taskflow/` structure
- [ ] Completed releases removed from roadmap table
- [ ] Cross-release dependencies updated and accurate
- [ ] Front matter `last_reviewed` date updated to today
- [ ] Update History entry added documenting changes
- [ ] All cross-references validated and accurate
- [ ] Changes committed with conventional commit format
- [ ] No format violations or broken references remain

## Output / Response Template

**Roadmap Update Summary:**

```
✓ Roadmap Updated Successfully

Changes Made:
- [Added/Updated/Removed] release [version] [codename]
- [Updated dependencies: description]
- [Other changes]

Releases in Roadmap:
- v.X.Y.Z "[Codename]" (QX YYYY) - [Status]
- v.X.Y.Z "[Codename]" (QX YYYY) - [Status]

Validation: ✓ All checks passed
Commit: [commit hash] "docs(roadmap): [commit message]"
```

## Embedded Templates

<documents>
<template path="tmpl://project-docs/roadmap">
---
title: Project Roadmap
last_reviewed: YYYY-MM-DD
status: [draft|active|archived]
---

# Project Roadmap

## 1. Project Vision

[Inspirational statement describing the long-term mission and value the project brings to users. Keep concise (1-3 sentences) and focused on outcomes rather than technical details.]

## 2. Strategic Objectives

| # | Objective | Success Metric |
|---|-----------|----------------|
| 1 | [Outcome-focused objective] | [Measurable criteria] |
| 2 | [Outcome-focused objective] | [Measurable criteria] |

## 3. Key Themes & Epics

| Theme | Description | Linked Epics |
|-------|-------------|-------------|
| [Theme Name] | [Brief description of theme purpose] | [Epic identifiers] |
| [Theme Name] | [Brief description of theme purpose] | [Epic identifiers] |

## 4. Planned Major Releases

| Version | Codename | Target Window | Goals | Key Epics |
|---------|----------|---------------|-------|-----------|
| v.X.Y.Z | "[Name]" | QX YYYY | [Primary goals] | [Related epics] |
| v.X.Y.Z | "[Name]" | QX YYYY | [Primary goals] | [Related epics] |

## 5. Cross-Release Dependencies

- [Dependency description linking specific epics/releases]
- [Dependency description linking specific epics/releases]

## 6. Update History

| Date | Summary | Author |
|------|---------|--------|
| YYYY-MM-DD | [Brief change description] | [Author name] |
| YYYY-MM-DD | Initial roadmap creation | [Author name] |
</template>
</documents>

## References

- **Roadmap Definition Guide**: `dev-handbook/guides/roadmap-definition.g.md`
- **Current Roadmap**: `.ace-taskflow/roadmap.md`
- **Draft Release Workflow**: `ace-taskflow/handbook/workflow-instructions/draft-release.wf.md`
- **Publish Release Workflow**: `ace-taskflow/handbook/workflow-instructions/publish-release.wf.md`
- **ace-taskflow CLI**: For release queries and task analysis

---

**Last Updated:** 2025-10-02
