---
id: v.0.9.0+task.052
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Create ace-handbook package

## Behavioral Specification

### User Experience
- **Input**: User invokes handbook management commands (e.g., `ace-handbook guide create`, `ace-handbook workflow update`, `ace-handbook agent review`)
- **Process**: System manages development guides, workflow instructions, and agent definitions with validation and consistency checks
- **Output**: Well-structured, validated handbook artifacts following standardized formats and conventions

### Expected Behavior

Users experience comprehensive handbook management through a dedicated CLI that maintains development guides, workflow instructions, and agent definitions. The system provides:

**Guide Management**: Create, update, and maintain development guides
- Create new guides from templates with standardized structure
- Update existing guides while preserving format consistency
- Validate guide structure and content
- Track guide versions and changes

**Workflow Management**: Create, update, and maintain workflow instructions
- Create new workflow instructions following .wf.md format
- Update workflows with validation of required sections
- Ensure workflow compatibility with wfi:// protocol
- Validate workflow prerequisites and steps

**Agent Management**: Create, update, and maintain agent definitions
- Create new agents from standardized templates
- Update agent definitions with behavior validation
- Ensure agent contracts are well-defined
- Manage agent discovery and documentation

**Review and Validation**: Ensure quality and consistency
- Review guides for completeness and clarity
- Review workflows for correctness and usability
- Validate agents against behavior specifications
- Generate quality reports and improvement suggestions

**Documentation Updates**: Maintain handbook-related documentation
- Update handbook README and structure documentation
- Synchronize handbook documentation with tools
- Generate handbook usage guides
- Maintain handbook changelog

All workflows maintain strict adherence to handbook conventions, ensuring consistent developer experience across all handbook artifacts.

### Interface Contract

```bash
# Guide management
ace-handbook guide create <guide-name> [--category <category>]
ace-handbook guide update <guide-path>
ace-handbook guide list [--category <category>]

# Workflow management
ace-handbook workflow create <workflow-name> [--category <category>]
ace-handbook workflow update <workflow-path>
ace-handbook workflow validate <workflow-path>

# Agent management
ace-handbook agent create <agent-name> [--type <type>]
ace-handbook agent update <agent-path>
ace-handbook agent validate <agent-path>

# Review and validation
ace-handbook review guides [--path <directory>]
ace-handbook review workflows [--path <directory>]
ace-handbook review agents [--path <directory>]

# Documentation updates
ace-handbook docs update [--target <handbook|tools|readme>]
ace-handbook docs sync

# All commands execute through wfi:// protocol:
# - wfi://meta-manage-guides
# - wfi://meta-manage-workflow-instructions
# - wfi://meta-manage-agents
# - wfi://meta-review-guides
# - wfi://meta-review-workflows
# - wfi://meta-update-handbook-docs
# - wfi://meta-update-tools-docs
# - wfi://meta-update-integration-claude
```

**Error Handling:**
- Invalid template: Report error and list available templates
- Validation failure: Provide detailed error messages with fix suggestions
- Missing required sections: Highlight missing content with examples
- Format inconsistency: Auto-fix where possible, report manual fixes needed

**Edge Cases:**
- Empty handbook directory: Initialize with default structure
- Conflicting updates: Detect conflicts, prompt for resolution
- Legacy format artifacts: Provide migration guidance

### Success Criteria

- [ ] **Artifact Creation**: Users can create guides, workflows, and agents from validated templates
- [ ] **Quality Validation**: System enforces handbook standards and conventions
- [ ] **Consistent Format**: All artifacts follow standardized formats and structures
- [ ] **Documentation Sync**: Handbook documentation stays synchronized with artifacts
- [ ] **Integration Support**: Claude Code integration files stay current with handbook changes

### Validation Questions

- [ ] **Package Boundary**: Should ace-handbook be standalone or integrate with ace-taskflow?
- [ ] **Template Location**: Where should artifact templates be stored and managed?
- [ ] **Validation Rules**: What validation rules are required vs. recommended?
- [ ] **Migration Support**: Should package support migrating legacy handbook formats?
- [ ] **Multi-Project**: How to support multiple project handbooks from one tool?

## Objective

Create a dedicated handbook management package (ace-handbook) that provides a unified interface for creating, updating, validating, and maintaining development guides, workflow instructions, and agent definitions with consistent quality and format adherence.

## Scope of Work

### Package Structure
New package: **ace-handbook** (Ruby gem or standalone tool)
- Location: `dev-tools/ace-handbook/`
- CLI namespace: `ace-handbook`
- Workflows to integrate (8 meta commands):

### Workflows to Integrate
1. **meta-manage-guides** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/manage-guides.wf.md`
   - Integration: `ace-handbook guide` commands call wfi://meta-manage-guides
   - Commands: `create`, `update`, `list`

2. **meta-review-guides** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/review-guides.wf.md`
   - Integration: `ace-handbook review guides` calls wfi://meta-review-guides

3. **meta-manage-workflow-instructions** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/manage-workflow-instructions.wf.md`
   - Integration: `ace-handbook workflow` commands call wfi://meta-manage-workflow-instructions
   - Commands: `create`, `update`, `validate`

4. **meta-review-workflows** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/review-workflows.wf.md`
   - Integration: `ace-handbook review workflows` calls wfi://meta-review-workflows

5. **meta-manage-agents** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/manage-agents.wf.md`
   - Integration: `ace-handbook agent` commands call wfi://meta-manage-agents
   - Commands: `create`, `update`, `validate`

6. **meta-update-handbook-docs** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/update-handbook-docs.wf.md`
   - Integration: `ace-handbook docs update --target handbook` calls wfi://meta-update-handbook-docs

7. **meta-update-tools-docs** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/update-tools-docs.wf.md`
   - Integration: `ace-handbook docs update --target tools` calls wfi://meta-update-tools-docs

8. **meta-update-integration-claude** (dev-handbook → ace-handbook)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/update-integration-claude.wf.md`
   - Integration: `ace-handbook docs sync` calls wfi://meta-update-integration-claude

### Interface Scope
- CLI commands under `ace-handbook` namespace
- wfi:// protocol integration for all meta workflows
- Template management and validation
- Format checking and enforcement
- Documentation generation and synchronization

### Deliverables

#### Behavioral Specifications
- Artifact creation and update workflows
- Validation rules and enforcement
- Review processes and quality checks
- Documentation synchronization behavior

#### Package Structure
- Ruby gem or standalone CLI tool
- Workflow integration layer
- Template system
- Validation framework
- Configuration management
- Documentation and examples

## Out of Scope

- ❌ **Implementation Details**: Ruby class structure, file parsing, template engines
- ❌ **Content Generation**: AI-powered guide writing, workflow generation
- ❌ **Version Control**: Git integration, change tracking, diff views
- ❌ **Collaboration**: Multi-user editing, comments, approval workflows

## References

- Meta workflow files in: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/`
  - manage-guides.wf.md
  - review-guides.wf.md
  - manage-workflow-instructions.wf.md
  - review-workflows.wf.md
  - manage-agents.wf.md
  - update-handbook-docs.wf.md
  - update-tools-docs.wf.md
  - update-integration-claude.wf.md
- Handbook structure: `/Users/mc/Ps/ace-meta/dev-handbook/`
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
