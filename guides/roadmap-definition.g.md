# Roadmap Definition Guide

## Purpose

This guide establishes the deterministic format requirements, validation criteria, and content guidelines for the project roadmap document (`docs-project/roadmap.md`). It serves as the authoritative specification that workflow instructions and other roadmap-related processes should reference to ensure consistent roadmap structure and quality.

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

## Cross-References

- [Strategic Planning Guide](strategic-planning.g.md) - Conceptual framework and lifecycle
- [Manage Roadmap Workflow](../workflow-instructions/manage-roadmap.wf.md) - Process for making updates (references this guide)
- [Current Roadmap](../../docs-project/roadmap.md) - Live roadmap document

## Last Updated

2025-06-02