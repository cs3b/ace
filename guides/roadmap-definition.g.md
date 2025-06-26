# Roadmap Definition Guide

## Purpose

This guide establishes the deterministic format requirements, validation criteria, and content guidelines for the project roadmap document (`dev-taskflow/roadmap.md`). It serves as the authoritative specification that workflow instructions and other roadmap-related processes should reference to ensure consistent roadmap structure and quality.

## Overview

The project roadmap is a living strategic document that translates the project vision into concrete objectives, themes, and planned releases. It follows a structured format with required sections and standardized table formats to ensure clarity, consistency, and effective communication of strategic direction.

## Document Structure Requirements

The roadmap document MUST contain the following sections in order:

1. **Front Matter** (YAML metadata)
2. **Project Vision** (Section 1)
3. **Strategic Objectives** (Section 2)
4. **Key Themes & Epics** (Section 3)
5. **Planned Major Releases** (Section 4)
6. **Cross-Release Dependencies** (Section 5)
7. **Update History** (Section 6)

## Section Specifications

### Front Matter

**Purpose**: Document metadata and status tracking

**Required Format**:

```yaml
---
title: Project Roadmap
last_reviewed: YYYY-MM-DD
status: [draft|active|archived]
---
```

**Validation Criteria**:

- MUST use YAML front matter format
- `title` field MUST be "Project Roadmap"
- `last_reviewed` field MUST use ISO date format (YYYY-MM-DD)
- `status` field MUST be one of: draft, active, archived

### 1. Project Vision

**Purpose**: Inspirational statement describing long-term mission and value

**Required Format**:

- Single paragraph or short statement
- Should be concise and aspirational
- May include relevant quote or motto

**Content Guidelines**:

- Focus on long-term mission and value proposition
- Keep concise (1-3 sentences recommended)
- Avoid technical jargon
- Should inspire and guide decision-making

**Example**:

```markdown
## 1. Project Vision

A concise, inspirational statement describing the long-term mission and value the Coding-Agent Workflow Toolkit brings to developers.
```

### 2. Strategic Objectives

**Purpose**: Define measurable 6-12 month outcomes aligned with vision

**Required Table Format**:

```markdown
| # | Objective | Success Metric |
|---|-----------|----------------|
| 1 | [Outcome-focused objective] | [Measurable criteria] |
| 2 | [Outcome-focused objective] | [Measurable criteria] |
```

**Column Specifications**:

- `#`: Sequential number (integer)
- `Objective`: Clear, outcome-focused statement
- `Success Metric`: Specific, measurable criteria for success

**Validation Criteria**:

- Table MUST have exactly 3 columns with specified headers
- Each objective MUST be outcome-focused, not activity-focused
- Success metrics MUST be specific and measurable
- Numbering MUST be sequential starting from 1

**Content Guidelines**:

- Focus on outcomes, not activities (e.g., "Improve developer experience" not "Write documentation")
- Success metrics should be quantifiable where possible
- Typically 3-7 objectives (avoid too many competing priorities)
- Review and update quarterly

### 3. Key Themes & Epics

**Purpose**: Group related work into coherent themes with linked epics

**Required Table Format**:

```markdown
| Theme | Description | Linked Epics |
|-------|-------------|-------------|
| [Theme Name] | [Brief description] | [Epic identifiers] |
```

**Column Specifications**:

- `Theme`: Short, descriptive name for the theme
- `Description`: Brief explanation of the theme's purpose
- `Linked Epics`: Comma-separated list of epic identifiers

**Validation Criteria**:

- Table MUST have exactly 3 columns with specified headers
- Theme names SHOULD be 2-4 words, descriptive
- Descriptions SHOULD be 1-2 sentences
- Epic identifiers SHOULD follow project naming conventions

**Content Guidelines**:

- Themes represent major areas of focus
- Epics within themes should be logically related
- Descriptions should clarify the theme's strategic importance

### 4. Planned Major Releases

**Purpose**: Map strategic work to concrete release targets

**Required Table Format**:

```markdown
| Version | Codename | Target Window | Goals | Key Epics |
|---------|----------|---------------|-------|-----------|
| v.X.Y.Z | "[Name]" | [Quarter Year] | [Primary goals] | [Related epics] |
```

**Column Specifications**:

- `Version`: Semantic version number (v.X.Y.Z format)
- `Codename`: Memorable name in quotes
- `Target Window`: Quarter and year (e.g., "Q3 2025")
- `Goals`: Primary objectives for the release
- `Key Epics`: Related epics from Themes table

**Validation Criteria**:

- Table MUST have exactly 5 columns with specified headers
- Version MUST follow semantic versioning (v.X.Y.Z)
- Target Window MUST use "QX YYYY" format
- Goals SHOULD be concise and specific
- Key Epics SHOULD reference themes from section 3

**Content Guidelines**:

- Plan 2-4 releases ahead maximum
- Codenames should be memorable and thematic
- Goals should align with strategic objectives
- Dates are indicative and subject to change

**Release Status Tracking Format**:
Releases should be included in the roadmap based on their location in the project folder structure:

- **Future Releases** (`dev-taskflow/backlog/`): Listed in table with target dates
- **Active Releases** (`dev-taskflow/current/`): Listed in table with current status indication
- **Completed Releases** (`dev-taskflow/done/`): Removed from table, delegated to changelog

When releases move between folders during lifecycle management:

1. **Draft → Current**: Update table to reflect active development status
2. **Current → Done**: Remove from roadmap table entirely
3. **Backlog reorganization**: Update target windows and dependencies as needed

Release folder links should follow the pattern:

- Backlog: `dev-taskflow/backlog/v.X.Y.Z-codename/`
- Current: `dev-taskflow/current/v.X.Y.Z-codename/`
- Done: `dev-taskflow/done/v.X.Y.Z-codename/`

### 5. Cross-Release Dependencies

**Purpose**: Document dependencies between releases and epics

**Required Format**:

- Prose section with bullet points or short paragraphs
- Each dependency should be clearly stated
- Use consistent epic/release naming

**Content Guidelines**:

- Focus on blocking dependencies
- Keep concise and clear
- Update when dependencies change
- Link to specific epics/releases mentioned in previous sections

**Example**:

```markdown
## 5. Cross-Release Dependencies

- `ai-sdk` epic underpins features planned for "Autopilot" (v.0.4.0).
- Documentation enhancements in "Compass" must complete before public launch.
```

### 6. Update History

**Purpose**: Track roadmap changes and maintain accountability

**Required Table Format**:

```markdown
| Date | Summary | Author |
|------|---------|--------|
| YYYY-MM-DD | [Brief change description] | [Author name] |
```

**Column Specifications**:

- `Date`: ISO date format (YYYY-MM-DD)
- `Summary`: Brief description of changes made
- `Author`: Name or identifier of person making changes

**Validation Criteria**:

- Table MUST have exactly 3 columns with specified headers
- Date MUST use ISO format (YYYY-MM-DD)
- Summary SHOULD be concise but descriptive
- Author SHOULD be consistent identifier

**Content Guidelines**:

- Add entry for every significant change
- Summaries should be helpful for future reference
- Keep most recent entries at top
- Include initial creation entry

## Validation Criteria

### Structure Validation

- **Section Completeness**: All required sections present in correct order
- **Front Matter Format**: Properly formatted with required fields
- **Table Headers**: All tables have correct column headers
- **Formatting Consistency**: Numbering and formatting consistency maintained

### Content Validation

- **Vision Quality**: Vision is inspiring and clear
- **Objective Focus**: Strategic objectives are outcome-focused and measurable
- **Theme Organization**: Themes are logically organized with linked epics
- **Release Planning**: Releases have realistic timelines and clear goals
- **Dependency Documentation**: Dependencies are clearly documented
- **History Tracking**: Update history is current and complete

### Quality Validation

- **Language Clarity**: Language is clear and professional
- **Strategic Alignment**: Strategic alignment is evident throughout
- **Information Currency**: Information is current and relevant
- **Reference Accuracy**: Cross-references are accurate

## Content Guidelines & Best Practices

### Writing Style

- Use clear, professional language
- Avoid jargon and technical details
- Be concise but complete
- Maintain consistent terminology

### Strategic Alignment

- All content should support the project vision
- Objectives should be prioritized and focused
- Releases should deliver meaningful value
- Dependencies should be realistic

### Maintenance

- Review quarterly at minimum
- Update `last_reviewed` date when changes made
- Add update history entry for all changes
- Validate structure after each update

## Examples

### Correct Strategic Objective

```markdown
| 2 | Improve onboarding developer experience | Average onboarding time ≤ 30 min |
```

- Outcome-focused objective
- Specific, measurable success metric
- Clear value proposition

### Incorrect Strategic Objective

```markdown
| 2 | Write better documentation | More documentation exists |
```

- Activity-focused instead of outcome-focused
- Vague success metric
- No clear value measurement

### Correct Release Entry

```markdown
| v.0.3.0 | "Compass" | Q3 2025 | Publish public beta documentation site | Documentation Excellence |
```

- Proper semantic versioning
- Memorable codename
- Specific timeline
- Clear, achievable goal
- Links to defined theme

### Incorrect Release Entry

```markdown
| 0.3 | Compass | Summer 2025 | Make docs better | docs stuff |
```

- Invalid version format
- Missing quotes on codename
- Vague timeline
- Unclear goal
- No theme linkage

## Integration with Workflows

### Workflow References

Workflow instructions should reference this guide for format validation rather than embedding format rules. Example reference:

```markdown
2. **Validate Structure**
   * Validate roadmap format against [Roadmap Definition Guide](../guides/roadmap-definition.g.md)
   * If validation fails, refer to definition guide for correction requirements
```

### Validation Process

1. Load roadmap document
2. Check structure against this guide's requirements
3. Validate each section format and content
4. Report specific violations with guide references
5. Require fixes before proceeding with updates

## Release Removal Process

When releases are completed and moved to `dev-taskflow/done/`, they must be systematically removed from the roadmap to prevent staleness and maintain focus on future work.

### Process Steps

1. **Identify Completed Releases**
   - Check `dev-taskflow/done/` for newly archived releases
   - Verify release completion status in project tracking

2. **Remove from Planned Releases Table**
   - Delete the entire row for the completed release from Section 4 table
   - Maintain proper table formatting and numbering

3. **Update Cross-Release Dependencies**
   - Review Section 5 for any references to the completed release
   - Remove or update dependency statements that reference completed work
   - Maintain dependencies that still affect future releases

4. **Delegate to Changelog**
   - Ensure completed release information is captured in project changelog
   - Include release achievements and key deliverables
   - Reference changelog for historical information about completed releases

5. **Update Metadata**
   - Update `last_reviewed` date in front matter
   - Add entry to Update History (Section 6) documenting the removal
   - Include specific release version and removal rationale

### Example Removal Entry

```markdown
| 2025-06-15 | Remove completed v.0.2.0 "Foundation" from roadmap, delegated to changelog | AI assistant |
```

### Validation Checklist

- [ ] Release row removed from Planned Major Releases table
- [ ] Cross-release dependencies updated or removed as appropriate
- [ ] Release information captured in changelog
- [ ] Front matter `last_reviewed` date updated
- [ ] Update History entry added
- [ ] No broken references to removed release remain

## Integration Triggers and Workflow Dependencies

The roadmap must be kept synchronized with release lifecycle changes through automated triggers during specific workflow events.

### Trigger Events

**1. Draft Release Creation**

- **When**: After completing step 4 (Populate Overview Document) in draft-release workflow
- **Action**: Add new release to roadmap "Planned Major Releases" table
- **Trigger**: Execute update-roadmap workflow with new release information
- **Commit**: Separate roadmap commit with message "docs(roadmap): add release v.X.Y.Z-codename to planned releases"

**2. Release Publication**

- **When**: During step 15 (Update Roadmap) in publish-release workflow
- **Action**: Remove completed release from roadmap table
- **Trigger**: Execute release removal process defined above
- **Commit**: Separate roadmap commit with message "docs(roadmap): remove completed v.X.Y.Z-codename from planned releases"

**3. Release Status Changes**

- **When**: Releases move between backlog → current → done folders
- **Action**: Update roadmap to reflect current status
- **Trigger**: Manual execution of update-roadmap workflow step 3 (Update Release Status)
- **Commit**: Include in relevant release lifecycle commits

### Cross-Workflow Dependencies

**Draft-Release → Update-Roadmap**

- Draft-release workflow MUST call update-roadmap workflow after step 6
- Roadmap updates MUST be committed separately from release scaffolding
- Roadmap commit MUST complete successfully before proceeding to step 8

**Publish-Release → Update-Roadmap**

- Publish-release workflow MUST update roadmap before final archival
- Roadmap cleanup MUST complete before documentation archival commit
- Failed roadmap updates SHOULD trigger rollback consideration

**Update-Roadmap Integration Points**

- Step 3 (Update Release Status) MUST check all project folder locations
- Workflow MUST validate roadmap consistency with current project state
- Updates MUST maintain roadmap format compliance per this guide

### Automation Requirements

**Mandatory Checks**

- Verify release exists in expected folder location before roadmap updates
- Validate roadmap format compliance after all updates
- Ensure changelog integration for removed releases
- Confirm no broken cross-references remain after changes

**Error Handling**

- If roadmap update fails during draft-release: halt process and report error
- If roadmap cleanup fails during publish-release: consider rollback of archival
- If format validation fails: require manual correction before proceeding
- If cross-reference validation fails: require dependency resolution

### Validation Requirements

**Pre-Update Validation**

- Confirm target release exists in expected project folder
- Verify roadmap format compliance using this guide
- Check for existing release entries to prevent duplicates

**Post-Update Validation**

- Validate updated roadmap format against this guide
- Verify all cross-references are accurate and reachable
- Confirm changelog integration for removed releases
- Check that update history entry was added correctly

## Error Handling and Recovery

When roadmap updates fail during release lifecycle management, specific recovery procedures must be followed to maintain process integrity.

### Error Categories

**1. Format Validation Errors**

- **Cause**: Roadmap structure doesn't comply with this guide
- **Detection**: During step 2 (Validate Structure) or step 7 (Validate Synchronization)
- **Response**: Halt process, report specific validation failures, require manual correction
- **Recovery**: Fix format issues before retrying workflow

**2. File System Inconsistencies**

- **Cause**: Release folders don't match expected locations or roadmap entries
- **Detection**: During step 3 (Update Release Status) validation
- **Response**: Report discrepancies, require manual reconciliation
- **Recovery**: Move releases to correct folders or update roadmap to match reality

**3. Cross-Reference Failures**

- **Cause**: Broken links to releases, epics, or dependencies
- **Detection**: During step 7 (Validate Synchronization)
- **Response**: Report broken references, require dependency resolution
- **Recovery**: Update or remove broken references before proceeding

**4. Commit/Push Failures**

- **Cause**: Git conflicts, permission issues, or network problems
- **Detection**: During step 8 (Commit Changes)
- **Response**: Report Git error, preserve changes for manual resolution
- **Recovery**: Resolve Git issues and manually commit roadmap changes

### Workflow-Specific Error Handling

**Draft-Release Workflow Failures**

- **When**: Roadmap update fails during step 7 of draft-release
- **Impact**: New release not added to roadmap
- **Response**:
  1. Complete release scaffolding without roadmap update
  2. Log roadmap update failure with specific error details
  3. Require manual roadmap update before proceeding to user review
- **Recovery**: Execute update-roadmap workflow separately with new release information

**Publish-Release Workflow Failures**

- **When**: Roadmap cleanup fails during step 15 of publish-release
- **Impact**: Completed release remains in roadmap (creates staleness)
- **Response**:
  1. Consider halting archival process if roadmap consistency is critical
  2. Log cleanup failure with specific error details
  3. Allow archival to proceed but flag roadmap inconsistency
- **Recovery**: Execute roadmap cleanup manually after archival completion

### Recovery Procedures

**Immediate Recovery Actions**

1. **Document Error State**: Record exact error message, workflow step, and system state
2. **Preserve Work**: Ensure no completed work is lost due to error
3. **Assess Impact**: Determine if process can continue or must be halted
4. **Escalate if Needed**: Report critical errors that require human intervention

**Manual Reconciliation Process**

1. **Identify Discrepancies**: Compare roadmap state with actual project folder structure
2. **Determine Correct State**: Decide whether roadmap or project structure should be updated
3. **Apply Corrections**: Make necessary changes to achieve consistency
4. **Validate Resolution**: Ensure all validation checks pass after corrections
5. **Resume Process**: Continue with original workflow from appropriate step

### Prevention Strategies

**Pre-Workflow Validation**

- Always run release status validation before major roadmap changes
- Verify Git repository is in clean state before starting workflows
- Check for existing roadmap format compliance before updates

**Atomic Operations**

- Commit roadmap changes separately from other workflow changes
- Use descriptive commit messages that enable easy rollback
- Validate roadmap after each logical change before proceeding

**Monitoring and Alerts**

- Log all roadmap modifications with timestamps and change details
- Monitor for discrepancies between roadmap and project structure
- Alert on validation failures or inconsistent states

## Cross-References

- [Strategic Planning Guide](strategic-planning.g.md) - Conceptual framework and lifecycle
- [Update Roadmap Workflow](../workflow-instructions/update-roadmap.wf.md) - Process for making updates (references this guide)
- [Current Roadmap](../../dev-taskflow/roadmap.md) - Live roadmap document

## Last Updated

2025-06-02
