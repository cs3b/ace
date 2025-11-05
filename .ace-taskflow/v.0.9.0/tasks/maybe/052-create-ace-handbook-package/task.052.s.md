---
id: v.0.9.0+task.052
status: draft
priority: medium
estimate: 1-2 days
dependencies: []
needs_review: false
---

## Updated Direction (2025-11-05)

**Package Type**: Pure workflow package (no CLI interface)
- Similar approach to planned ace-git task
- Contains workflows, templates, guides, agents with configured protocols
- Access via wfi:// protocol through ace-nav
- No need for dedicated CLI commands

## Open Questions

- [ ] **Workflow Naming**: Should we remove "meta-" prefix from workflow names?
  - Current: `wfi://meta-manage-guides`, `wfi://meta-review-workflows`
  - Proposed: `wfi://manage-guides`, `wfi://review-workflows`
  - Context: "meta" prefix was used to distinguish handbook management workflows from regular workflows

## Research Findings (2025-10-05)

### Project Context Discovery
- **ACE Architecture**: Mono-repo of modular ace-* Ruby gems following ATOM pattern (atoms/, molecules/, organisms/, models/)
- **All Target Workflows Exist**: All 8 meta workflows are present in `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/`
- **Existing Legacy CLI**: Found active `handbook` CLI in dev-tools/exe/handbook with sync-templates and claude commands
- **Established Patterns**: ace-* gems follow consistent CLI structure with simple exe/ scripts delegating to lib/ace/*/cli.rb

### Critical Dependencies Identified
1. **ace-nav Integration**: wfi:// protocol provides workflow discovery and execution
2. **ace-core Configuration**: Established .ace/ cascade pattern used across all gems
3. **Template System**: ADR-002 mandates XML template embedding within workflows
4. **Migration Path**: Need strategy for transitioning from dev-tools/handbook to ace-handbook

### Implementation Readiness Assessment
- **Ready with assumptions**: Can proceed with ace-handbook gem creation using standard patterns
- **Blocked on decisions**: CLI naming, legacy migration strategy, and workflow integration approach need clarification
- **Templates available**: Can use ace-gem creation patterns from docs/ace-gems.g.md

# Create ace-handbook package

## Behavioral Specification

### User Experience
- **Input**: AI agents or developers invoke handbook workflows via wfi:// protocol (e.g., `ace-nav wfi://manage-guides`, `ace-nav wfi://review-workflows`)
- **Process**: Workflows manage development guides, workflow instructions, and agent definitions with validation and consistency checks
- **Output**: Well-structured, validated handbook artifacts following standardized formats and conventions

### Expected Behavior

Users access handbook management through wfi:// protocol workflows that maintain development guides, workflow instructions, and agent definitions:

**Guide Management** (`wfi://manage-guides`, `wfi://review-guides`)
- Create, update, and validate development guides
- Ensure guides follow standardized structure and formatting
- Track guide versions and update requirements

**Workflow Management** (`wfi://manage-workflow-instructions`, `wfi://review-workflows`)
- Create and update workflow instructions in .wf.md format
- Validate workflow structure and required sections
- Ensure wfi:// protocol compatibility

**Agent Management** (`wfi://manage-agents`)
- Create and update agent definitions in .ag.md format
- Validate agent contracts and behavior specifications
- Manage agent discovery and documentation

**Documentation Sync** (`wfi://update-handbook-docs`, `wfi://update-tools-docs`, `wfi://update-integration-claude`)
- Maintain handbook README and structure documentation
- Synchronize handbook documentation with implementation
- Update Claude Code integration files

### Protocol Access

```bash
# Access via ace-nav wfi:// protocol
ace-nav wfi://manage-guides
ace-nav wfi://review-guides
ace-nav wfi://manage-workflow-instructions
ace-nav wfi://review-workflows
ace-nav wfi://manage-agents
ace-nav wfi://update-handbook-docs
ace-nav wfi://update-tools-docs
ace-nav wfi://update-integration-claude
```

### Success Criteria

- [ ] **Workflow Package**: Installable gem containing workflows, templates, guides, and agents
- [ ] **Protocol Integration**: All workflows accessible via wfi:// protocol
- [ ] **Template Embedding**: Templates embedded in workflows per ADR-002
- [ ] **Quality Standards**: Workflows enforce handbook standards and conventions
- [ ] **Documentation**: Clear documentation for using handbook workflows

## Objective

Create a pure workflow package (ace-handbook gem) containing handbook management workflows, templates, guides, and agents accessible via wfi:// protocol. Similar to planned ace-git approach - no CLI interface, just packaged workflows with protocol configuration.

## Scope of Work

### Package Structure
New gem: **ace-handbook** (Ruby gem containing workflows and templates)
- Location: `ace-handbook/` (at repository root following mono-repo pattern)
- Type: Workflow package (no exe/ directory, no CLI)
- Access: Via `ace-nav wfi://workflow-name` protocol

### Workflows to Package
Migrate 8 workflows from dev-handbook/.meta/wfi/ to ace-handbook/handbook/workflow-instructions/:

1. **manage-guides.wf.md** → `wfi://manage-guides` (or `wfi://handbook-manage-guides`)
   - Create, update, and maintain development guides
   - Source: `dev-handbook/.meta/wfi/manage-guides.wf.md`

2. **review-guides.wf.md** → `wfi://review-guides`
   - Review guides for quality and consistency
   - Source: `dev-handbook/.meta/wfi/review-guides.wf.md`

3. **manage-workflow-instructions.wf.md** → `wfi://manage-workflow-instructions`
   - Create, update, and validate workflow files
   - Source: `dev-handbook/.meta/wfi/manage-workflow-instructions.wf.md`

4. **review-workflows.wf.md** → `wfi://review-workflows`
   - Review workflow instructions for quality
   - Source: `dev-handbook/.meta/wfi/review-workflows.wf.md`

5. **manage-agents.wf.md** → `wfi://manage-agents`
   - Create, update, and validate agent definitions
   - Source: `dev-handbook/.meta/wfi/manage-agents.wf.md`

6. **update-handbook-docs.wf.md** → `wfi://update-handbook-docs`
   - Maintain handbook README and structure docs
   - Source: `dev-handbook/.meta/wfi/update-handbook-docs.wf.md`

7. **update-tools-docs.wf.md** → `wfi://update-tools-docs`
   - Update tool documentation from implementation
   - Source: `dev-handbook/.meta/wfi/update-tools-docs.wf.md`

8. **update-integration-claude.wf.md** → `wfi://update-integration-claude`
   - Synchronize Claude Code integration files
   - Source: `dev-handbook/.meta/wfi/update-integration-claude.wf.md`

### Content to Package
- **Workflows**: 8 handbook management workflows in `handbook/workflow-instructions/`
- **Templates**: Handbook artifact templates embedded per ADR-002
- **Guides**: Development guides in `handbook/guides/` (if applicable)
- **Agents**: Handbook-related agents in `handbook/agents/` (if applicable)
- **Configuration**: wfi:// protocol registration for ace-nav discovery

### Deliverables
- ace-handbook gem structure following ace-gems.g.md pattern
- 8 migrated and validated workflow files
- Templates embedded in workflows (ADR-002 compliance)
- Protocol configuration for ace-nav discovery
- README and usage documentation
- CHANGELOG.md with initial release notes

## Out of Scope

- ❌ **CLI Interface**: No dedicated CLI commands (access via ace-nav wfi:// only)
- ❌ **Ruby Logic**: No atoms/molecules/organisms (pure workflow package)
- ❌ **Content Generation**: AI-powered guide writing, workflow generation
- ❌ **Version Control Integration**: Git integration, change tracking, diff views
- ❌ **Collaboration Tools**: Multi-user editing, comments, approval workflows
- ❌ **Legacy CLI Migration**: Not replacing dev-tools/exe/handbook (separate concern)

## References

### Existing Workflows
- Source location: `/Users/mc/Ps/ace-meta/dev-handbook/.meta/wfi/`
  - manage-guides.wf.md
  - review-guides.wf.md
  - manage-workflow-instructions.wf.md
  - review-workflows.wf.md
  - manage-agents.wf.md
  - update-handbook-docs.wf.md
  - update-tools-docs.wf.md
  - update-integration-claude.wf.md

### Similar Patterns
- **ace-git** (planned): Similar pure workflow package approach
- **ace-taskflow**: Example gem with embedded workflows
- **docs/ace-gems.g.md**: Gem structure and patterns guide
- **ADR-002**: XML template embedding architecture

### Templates
- Current location: `dev-handbook/templates/`
- To be embedded in workflows per ADR-002
