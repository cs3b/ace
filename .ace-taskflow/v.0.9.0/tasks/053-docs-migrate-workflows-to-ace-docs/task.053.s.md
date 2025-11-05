---
id: v.0.9.0+task.053
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Migrate documentation generation workflows to ace-docs

## Behavioral Specification

### User Experience
- **Input**: User invokes documentation generation workflows via ace-docs CLI or slash commands (e.g., `/create-api-docs`, `/create-user-docs`, `ace-docs generate api`)
- **Process**: Workflows orchestrate multiple tools (ace-context for understanding, ace-search for discovery, ace-docs for management) to generate documentation
- **Output**: Updated documentation files (API docs, user guides, blueprints, cookbooks) in standardized formats with proper frontmatter

### Expected Behavior

Users access documentation generation through workflows embedded in ace-docs/handbook/. Each workflow provides:

**API Documentation**: Generate API documentation from code
- Analyzes code structure, interfaces, and contracts
- Extracts docstrings, comments, and type definitions
- Generates structured API reference documentation
- Maintains documentation format consistency

**User Documentation**: Create user-facing documentation
- Analyzes user-facing features and interfaces
- Generates usage examples and tutorials
- Creates getting-started guides
- Documents configuration and setup

**Blueprint Updates**: Maintain architectural documentation
- Analyzes current project structure and patterns
- Updates architectural decision records
- Maintains system design documentation
- Tracks architectural changes over time

**Context Documentation**: Update project context files
- Maintains CONTEXT.md or similar project overview
- Updates component relationships
- Documents project conventions
- Tracks development guidelines

**Cookbook Creation**: Generate practical how-to guides
- Creates task-oriented documentation
- Documents common workflows and patterns
- Provides code examples and recipes
- Maintains troubleshooting guides

**ADR Creation**: Document architectural decisions (already in ace-docs)
- Creates Architecture Decision Records
- Documents decision context and consequences
- Maintains decision history
- Links decisions to implementation

The workflows use ace-context for project understanding, ace-search for code discovery, and ace-docs for output management.

### Interface Contract

**Workflows to migrate** (from dev-handbook to ace-docs/handbook):

```bash
# API Documentation Workflow
/create-api-docs
# Location: ace-docs/handbook/workflow-instructions/create-api-docs.wf.md
# Invocation: ace-nav wfi://create-api-docs or slash command
# Output: API documentation in docs/api/

# User Documentation Workflow
/create-user-docs
# Location: ace-docs/handbook/workflow-instructions/create-user-docs.wf.md
# Invocation: ace-nav wfi://create-user-docs or slash command
# Output: User guides in docs/user/

# Blueprint Update Workflow
/update-blueprint
# Location: ace-docs/handbook/workflow-instructions/update-blueprint.wf.md
# Invocation: ace-nav wfi://update-blueprint or slash command
# Output: Updated BLUEPRINT.md or architecture docs

# Context Documentation Workflow
/update-context-docs
# Location: ace-docs/handbook/workflow-instructions/update-context-docs.wf.md
# Invocation: ace-nav wfi://update-context-docs or slash command
# Output: Updated CONTEXT.md or similar files

# Cookbook Creation Workflow
/create-cookbook
# Location: ace-docs/handbook/workflow-instructions/create-cookbook.wf.md
# Invocation: ace-nav wfi://create-cookbook or slash command
# Output: Cookbook entry in docs/cookbook/

# ADR Creation (already exists in ace-docs)
/ace:create-adr
# Location: ace-docs/handbook/workflow-instructions/create-adr.wf.md ✓
# Status: Already migrated
```

**Error Handling:**
- Code analysis failure: Report partial results, suggest manual review
- Missing documentation directory: Create structure automatically
- Template not found: Use default template, warn user
- Outdated documentation: Highlight stale sections, suggest updates

**Edge Cases:**
- No docstrings found: Generate basic structure from signatures
- Large codebase: Process incrementally with progress updates
- Multiple documentation formats: Support format conversion
- Missing architectural context: Prompt for initial decisions

### Success Criteria

- [ ] **Automated Generation**: Documentation generates automatically from code and project structure
- [ ] **Accuracy**: Generated documentation accurately reflects current codebase state
- [ ] **Consistency**: All documentation follows project conventions and formats
- [ ] **Completeness**: Documentation covers all public interfaces and features
- [ ] **Maintainability**: Documentation updates easily when code changes

### Validation Questions

- [ ] **Documentation Scope**: What documentation types are included (API, user, architecture, all)?
- [ ] **Update Triggers**: When should documentation auto-update vs. manual regeneration?
- [ ] **Format Standards**: What documentation formats and conventions should be enforced?
- [ ] **Code Analysis**: How deep should code analysis go for documentation generation?
- [ ] **Version Tracking**: Should documentation track versions separately from code?

## Objective

Migrate documentation generation workflows from dev-handbook (legacy) to ace-docs/handbook, establishing ace-docs as the single source for all documentation management and generation capabilities. This consolidates documentation workflows in their proper architectural home.

## Scope of Work

### Workflow Migration
Migrate workflows from **dev-handbook** to **ace-docs/handbook**:
- Source: `dev-handbook/workflow-instructions/` (legacy)
- Destination: `ace-docs/handbook/workflow-instructions/`
- Integration: Workflows use ace-context for understanding, ace-search for discovery, ace-docs CLI for management
- Total workflows to migrate: 5 (create-api-docs, create-user-docs, update-blueprint, update-context-docs, create-cookbook)

### Workflows to Migrate
1. **create-api-docs** (dev-handbook → ace-docs)
   - Source: `dev-handbook/workflow-instructions/create-api-docs.wf.md`
   - Destination: `ace-docs/handbook/workflow-instructions/create-api-docs.wf.md`
   - Invocation: `/create-api-docs` or `ace-nav wfi://create-api-docs`
   - Purpose: Generate API documentation from code structure

2. **create-user-docs** (dev-handbook → ace-docs)
   - Source: `dev-handbook/workflow-instructions/create-user-docs.wf.md`
   - Destination: `ace-docs/handbook/workflow-instructions/create-user-docs.wf.md`
   - Invocation: `/create-user-docs` or `ace-nav wfi://create-user-docs`
   - Purpose: Create user-facing guides and tutorials

3. **update-blueprint** (dev-handbook → ace-docs)
   - Source: `dev-handbook/workflow-instructions/update-blueprint.wf.md`
   - Destination: `ace-docs/handbook/workflow-instructions/update-blueprint.wf.md`
   - Invocation: `/update-blueprint` or `ace-nav wfi://update-blueprint`
   - Purpose: Maintain architectural documentation

4. **update-context-docs** (dev-handbook → ace-docs)
   - Source: `dev-handbook/workflow-instructions/update-context-docs.wf.md`
   - Destination: `ace-docs/handbook/workflow-instructions/update-context-docs.wf.md`
   - Invocation: `/update-context-docs` or `ace-nav wfi://update-context-docs`
   - Purpose: Update project context documentation

5. **create-cookbook** (dev-handbook → ace-docs)
   - Source: `dev-handbook/workflow-instructions/create-cookbook.wf.md`
   - Destination: `ace-docs/handbook/workflow-instructions/create-cookbook.wf.md`
   - Invocation: `/create-cookbook` or `ace-nav wfi://create-cookbook`
   - Purpose: Generate practical how-to guides

**Already Migrated:**
- **create-adr** ✓ Already in `ace-docs/handbook/workflow-instructions/create-adr.wf.md`
- **maintain-adrs** ✓ Already in `ace-docs/handbook/workflow-instructions/maintain-adrs.wf.md`
- **update-docs** ✓ Already in `ace-docs/handbook/workflow-instructions/update-docs.wf.md`

### Migration Scope
- Move 5 workflow files from dev-handbook to ace-docs/handbook
- Update workflow frontmatter with ace-docs specific metadata
- Ensure workflows follow ADR-001 self-containment principle
- Create slash command mappings in .claude/commands/ (optional)
- Test workflows with ace-nav wfi:// protocol
- Update workflow documentation and examples

### Deliverables

#### Migrated Workflows
- `ace-docs/handbook/workflow-instructions/create-api-docs.wf.md`
- `ace-docs/handbook/workflow-instructions/create-user-docs.wf.md`
- `ace-docs/handbook/workflow-instructions/update-blueprint.wf.md`
- `ace-docs/handbook/workflow-instructions/update-context-docs.wf.md`
- `ace-docs/handbook/workflow-instructions/create-cookbook.wf.md`

#### Integration
- Workflows accessible via `ace-nav wfi://workflow-name`
- Optional slash commands for common workflows
- Documentation in ace-docs about available generation workflows
- Examples showing workflow usage patterns

## Out of Scope

- ❌ **CLI Extension**: No new ace-docs CLI commands needed (workflows are self-contained)
- ❌ **Code Implementation**: No Ruby code changes to ace-docs gem
- ❌ **Documentation Hosting**: Web servers, documentation sites, search functionality
- ❌ **Visual Documentation**: Diagrams, flowcharts, architecture visualizations
- ❌ **Workflow Modification**: Use existing workflows as-is, only migrate location
- ❌ **New Templates**: No new documentation templates (use existing embedded templates)
- ❌ **ace-context Extension**: This task does NOT extend ace-context functionality

## References

### Source Workflows (dev-handbook - legacy)
- `dev-handbook/workflow-instructions/create-api-docs.wf.md`
- `dev-handbook/workflow-instructions/create-user-docs.wf.md`
- `dev-handbook/workflow-instructions/update-blueprint.wf.md`
- `dev-handbook/workflow-instructions/update-context-docs.wf.md`
- `dev-handbook/workflow-instructions/create-cookbook.wf.md`

### Destination (ace-docs)
- `ace-docs/handbook/workflow-instructions/` (target directory)
- `ace-docs/handbook/workflow-instructions/create-adr.wf.md` (example of already migrated workflow)
- `ace-docs/handbook/workflow-instructions/maintain-adrs.wf.md` (example of ace-docs workflow)

### Architecture References
- ADR-001: Workflow Self-Containment Principle (`docs/decisions/ADR-001-workflow-self-containment-principle.md`)
- ADR-016: Handbook Directory Architecture (`docs/decisions/ADR-016-handbook-directory-architecture.md`)
- ace-docs gem: `ace-docs/` (destination package)
- ace-nav: `ace-nav/` (for wfi:// protocol support)
