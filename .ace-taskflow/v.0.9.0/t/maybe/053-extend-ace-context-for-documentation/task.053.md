---
id: v.0.9.0+task.053
status: draft
estimate: TBD
dependencies: []
---

# Extend ace-context for documentation workflows

## Behavioral Specification

### User Experience
- **Input**: User invokes documentation commands via ace-context CLI (e.g., `ace-context docs api`, `ace-context docs user`, `ace-context blueprint update`)
- **Process**: System generates or updates documentation based on current codebase, project structure, and existing documentation
- **Output**: Updated documentation files (API docs, user guides, blueprints, cookbooks, ADRs) reflecting current project state

### Expected Behavior

Users experience automated documentation workflows that keep project documentation synchronized with code and architecture. The system provides:

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

**ADR Creation**: Document architectural decisions
- Creates Architecture Decision Records
- Documents decision context and consequences
- Maintains decision history
- Links decisions to implementation

The workflows integrate with ace-context package structure, using context understanding to generate accurate, up-to-date documentation.

### Interface Contract

```bash
# Generate/update API documentation
ace-context docs api [--path <directory>] [--format <markdown|html>]
# Executes: wfi://create-api-docs
# Output: API documentation in docs/api/

# Create user documentation
ace-context docs user [--topic <topic>] [--template <template>]
# Executes: wfi://create-user-docs
# Output: User guides in docs/user/

# Update blueprint
ace-context blueprint update [--section <section>]
# Executes: wfi://update-blueprint
# Output: Updated BLUEPRINT.md or architecture docs

# Update context documentation
ace-context docs context [--target <component>]
# Executes: wfi://update-context-docs
# Output: Updated CONTEXT.md or similar files

# Create cookbook entries
ace-context cookbook create <topic> [--category <category>]
# Executes: wfi://create-cookbook
# Output: Cookbook entry in docs/cookbook/

# Create architectural decision record
ace-context adr create <decision-title> [--status <proposed|accepted|rejected>]
# Executes: wfi://create-adr
# Output: ADR document in docs/adr/
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

Extend ace-context package with comprehensive documentation generation capabilities, enabling automated creation and maintenance of API docs, user guides, architectural documentation, and decision records that stay synchronized with project evolution.

## Scope of Work

### Package Extension
Extend existing package: **ace-context** (part of dev-tools)
- Location: `dev-tools/ace-context/` (or similar)
- CLI namespace: `ace-context docs`, `ace-context blueprint`, `ace-context cookbook`, `ace-context adr`
- Workflows to integrate (7 documentation commands):

### Workflows to Integrate
1. **create-api-docs** (dev-handbook → ace-context)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-api-docs.wf.md`
   - Integration: `ace-context docs api` calls wfi://create-api-docs
   - Command: `ace-context docs api`

2. **create-user-docs** (dev-handbook → ace-context)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-user-docs.wf.md`
   - Integration: `ace-context docs user` calls wfi://create-user-docs
   - Command: `ace-context docs user`

3. **update-blueprint** (dev-handbook → ace-context)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/update-blueprint.wf.md`
   - Integration: `ace-context blueprint update` calls wfi://update-blueprint
   - Command: `ace-context blueprint update`

4. **update-context-docs** (dev-handbook → ace-context)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/update-context-docs.wf.md`
   - Integration: `ace-context docs context` calls wfi://update-context-docs
   - Command: `ace-context docs context`

5. **create-cookbook** (dev-handbook → ace-context)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-cookbook.wf.md`
   - Integration: `ace-context cookbook create` calls wfi://create-cookbook
   - Command: `ace-context cookbook create`

6. **create-adr** (dev-handbook → ace-context)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-adr.wf.md`
   - Integration: `ace-context adr create` calls wfi://create-adr
   - Command: `ace-context adr create`

7. **save-session-context** (dev-handbook → ace-context)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/save-session-context.wf.md`
   - Integration: `ace-context session save` calls wfi://save-session-context
   - Command: `ace-context session save`

### Interface Scope
- CLI commands under `ace-context` namespace with doc-related subcommands
- wfi:// protocol integration for workflow delegation
- Code analysis and documentation extraction
- Template management for different doc types
- Documentation format validation and consistency

### Deliverables

#### Behavioral Specifications
- Documentation generation workflows
- Update and synchronization behavior
- Template and format management
- Integration with project structure

#### Package Extension
- New CLI commands and subcommands
- Workflow integration layer
- Code analysis capabilities
- Documentation generators
- Template system
- Format validators

## Out of Scope

- ❌ **Implementation Details**: Ruby class structure, parsers, template engines, AST analysis
- ❌ **Documentation Hosting**: Web servers, documentation sites, search functionality
- ❌ **Visual Documentation**: Diagrams, flowcharts, architecture visualizations
- ❌ **Localization**: Multi-language documentation, translation workflows

## References

- Workflow files:
  - `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-api-docs.wf.md`
  - `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-user-docs.wf.md`
  - `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/update-blueprint.wf.md`
  - `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/update-context-docs.wf.md`
  - `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-cookbook.wf.md`
  - `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-adr.wf.md`
  - `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/save-session-context.wf.md`
- Existing ace-context package (if exists in dev-tools)
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
