---
id: v.0.5.0+task.037
status: done
priority: high
estimate: 4h
dependencies: [v.0.5.0+task.036]
---

# Create Cookbook Workflow for Pattern Documentation

## Behavioral Specification

### User Experience
- **Input**: User invokes `/create-cookbook` workflow with source material (reflection note or direct pattern)
- **Process**: Workflow guides through cookbook type selection, content structuring, and documentation generation
- **Output**: Well-structured cookbook file in `dev-handbook/cookbooks/` with consistent naming

### Expected Behavior
The system provides a guided workflow for transforming identified patterns and insights into reusable cookbooks. Users can create cookbooks from:
- Reflection note insights identifying reusable patterns
- Direct observation of repeated complex procedures
- Synthesis reports highlighting common workflows

The workflow ensures consistent structure, proper categorization, and comprehensive documentation of patterns for future reuse.

### Interface Contract
```bash
# Workflow Interface
/create-cookbook
# Workflow prompts for:
# - Source type (reflection note, direct input, synthesis report)
# - Cookbook category (integration, setup, migration, debugging, automation, pattern)
# - Target audience (beginner, intermediate, advanced)
# - Pattern description and context

# Output: Cookbook file in dev-handbook/cookbooks/
# Naming: [category]-[descriptive-name].cookbook.md
# Examples:
#   integration-oauth-provider.cookbook.md
#   setup-development-environment.cookbook.md
#   pattern-error-handling.cookbook.md
```

**Error Handling:**
- Missing source material: Prompt for pattern details
- Duplicate cookbook name: Suggest alternative or version
- Invalid category: Show valid categories and reprompt

**Edge Cases:**
- Multiple patterns in one cookbook: Support composite cookbooks
- Cross-category patterns: Allow primary and secondary categories
- Version updates: Support cookbook versioning

### Success Criteria
- [ ] **Cookbook Structure Complete**: Generated cookbooks follow standard template
- [ ] **Naming Convention Applied**: Files use consistent `[category]-[name].cookbook.md` format
- [ ] **Content Quality**: Step-by-step instructions with embedded templates
- [ ] **Storage Location Correct**: All cookbooks in `dev-handbook/cookbooks/`
- [ ] **Reusability Validated**: Cookbooks are self-contained and actionable

### Validation Questions
- [ ] **Template Structure**: What sections are mandatory vs optional in cookbook template?
- [ ] **Category Taxonomy**: Is the category list comprehensive for all use cases?
- [ ] **Version Management**: How to handle cookbook updates and versions?
- [ ] **Quality Standards**: What criteria define a "complete" cookbook?

## Objective

Create a systematic workflow for transforming identified patterns into high-quality, reusable cookbooks that accelerate future development.

## Scope of Work

- **User Experience Scope**: Guided cookbook creation from various sources
- **System Behavior Scope**: Template application, naming standardization, content structuring
- **Interface Scope**: Workflow prompts and cookbook generation interface

### Deliverables

#### Behavioral Specifications
- Cookbook creation workflow definition
- Standard cookbook template structure
- Category taxonomy and naming conventions

#### Validation Artifacts
- Sample cookbooks for each category
- Quality checklist for cookbook review
- Integration with reflection workflow


## Out of Scope

- ❌ **Implementation Details**: Specific technical implementation of cookbook steps
- ❌ **Automation Execution**: Actual automation of cookbook procedures
- ❌ **Quality Review Process**: Manual review and approval workflows
- ❌ **Cross-Project Sharing**: Publishing cookbooks beyond current project

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work.*

### Planning Steps

*Research and design activities completed during task planning phase.*

- [x] Analyze existing workflow patterns for consistency and integration approach
- [x] Research template embedding system requirements (XML document system ADR-005)
- [x] Plan directory structure and naming conventions following project standards
- [x] Design cookbook template structure with all required sections

### Execution Steps

*Concrete implementation actions that modify code, create files, or change the system state.*

- [ ] Create cookbooks directory structure in `dev-handbook/cookbooks/`
  > TEST: Directory Creation Validation
  > Type: Pre-condition Check
  > Assert: Directory exists and is accessible
  > Command: # ls -la dev-handbook/ | grep cookbooks

- [ ] Create cookbook template at `dev-handbook/templates/cookbooks/cookbook.template.md`
  > TEST: Template Structure Validation
  > Type: Content Validation
  > Assert: Template contains all required sections and follows XML embedding pattern
  > Command: # grep -E "(Purpose|Prerequisites|Steps|Examples)" dev-handbook/templates/cookbooks/cookbook.template.md

- [ ] Create main workflow file at `dev-handbook/workflow-instructions/create-cookbook.wf.md`
  > TEST: Workflow Structure Validation
  > Type: Content Validation
  > Assert: Workflow follows established patterns and includes all required sections
  > Command: # grep -E "(Goal|Prerequisites|Process Steps|Success Criteria)" dev-handbook/workflow-instructions/create-cookbook.wf.md

- [ ] Embed cookbook template within workflow file using XML document system
  > TEST: Template Embedding Validation
  > Type: Integration Validation
  > Assert: Template is properly embedded and accessible within workflow
  > Command: # grep -A 10 -B 2 "<template" dev-handbook/workflow-instructions/create-cookbook.wf.md

- [ ] Validate workflow integrates with existing `create-path` tool patterns
  > TEST: Tool Integration Validation
  > Type: Integration Validation
  > Assert: Workflow references and uses create-path tool correctly
  > Command: # grep "create-path" dev-handbook/workflow-instructions/create-cookbook.wf.md

- [ ] Create sample cookbook files for each category to validate structure
  > TEST: Sample Generation Validation
  > Type: End-to-End Validation
  > Assert: Sample cookbooks generate correctly and follow naming convention
  > Command: # ls dev-handbook/cookbooks/ | grep ".cookbook.md$"

## Technical Approach

### Architecture Pattern
- [ ] Follow self-contained workflow architecture (ADR-001)
- [ ] Integrate with existing template embedding system (ADR-002, ADR-005)
- [ ] Maintain consistency with current workflow patterns

### Technology Stack
- [ ] File system + Markdown (no new dependencies required)
- [ ] XML document embedding for template inclusion
- [ ] Integration with existing `create-path` tool
- [ ] Standard Markdown formatting and structure

### Implementation Strategy
- [ ] Create directory structure following existing project organization
- [ ] Develop comprehensive template covering all cookbook categories
- [ ] Build workflow with guided prompts and category selection
- [ ] Implement naming convention validation

## File Modifications

### Create
- dev-handbook/workflow-instructions/create-cookbook.wf.md
  - Purpose: Main workflow for guided cookbook creation
  - Key components: Category selection, content structuring, file generation
  - Dependencies: Existing workflow patterns, template system

- dev-handbook/templates/cookbooks/cookbook.template.md
  - Purpose: Standard template for cookbook structure
  - Key components: Purpose, prerequisites, steps, examples, validation
  - Dependencies: XML document embedding system (ADR-005)

- dev-handbook/cookbooks/ (directory)
  - Purpose: Storage location for generated cookbook files
  - Key components: Organized directory structure for cookbooks
  - Dependencies: File system organization patterns

### Modify
- None required for core functionality

### Delete
- None required

## Risk Assessment

### Technical Risks
- **Risk:** Template embedding format incompatibility
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Follow existing XML embedding patterns from project templates
  - **Rollback:** Remove malformed templates and use external file references

### Integration Risks
- **Risk:** `create-path` tool compatibility issues
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Test integration thoroughly and provide fallback manual creation steps
  - **Monitoring:** Monitor tool execution and validate file creation results

### Performance Risks
- **Risk:** Large cookbook files impacting workflow performance
  - **Mitigation:** Establish reasonable size limits and structure guidelines
  - **Monitoring:** Track file sizes and workflow execution times
  - **Thresholds:** Cookbook files should not exceed 50KB for optimal performance

## Acceptance Criteria

*Define the conditions that signify the task is complete.*

- [ ] **Cookbook Structure Complete**: Generated cookbooks follow standard template with all required sections
- [ ] **Naming Convention Applied**: Files use consistent `[category]-[descriptive-name].cookbook.md` format
- [ ] **Content Quality**: Cookbooks contain step-by-step instructions with embedded examples
- [ ] **Storage Location Correct**: All cookbooks created in `dev-handbook/cookbooks/` directory
- [ ] **Reusability Validated**: Cookbooks are self-contained and actionable for future use
- [ ] **Workflow Integration**: Create-cookbook workflow integrates with existing tool ecosystem
- [ ] **Template Embedding**: Cookbook template properly embedded using XML document system

## Out of Scope

- ❌ **Implementation Details**: Specific technical implementation of cookbook steps
- ❌ **Automation Execution**: Actual automation of cookbook procedures
- ❌ **Quality Review Process**: Manual review and approval workflows
- ❌ **Cross-Project Sharing**: Publishing cookbooks beyond current project

## References

- Source idea: dev-taskflow/backlog/ideas/008-reflection-cookbook-automation.md
- Related workflow: dev-handbook/workflow-instructions/create-reflection-note.wf.md
- Storage location: dev-handbook/cookbooks/
- Naming convention: [category]-[descriptive-name].cookbook.md