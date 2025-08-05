---
id: v.0.6.0+task.014
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Improve Claude template organization and standardization

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents working with Claude integration templates in the dev-handbook repository
- **Process**: Discovering, referencing, and maintaining Claude command templates with clear organization and consistent naming conventions
- **Output**: Well-organized template structure that is intuitive to navigate, eliminates duplication, and follows consistent naming patterns

### Expected Behavior
The system should provide a clear, consistent template organization for Claude integrations where:

1. **Template Discovery**: Developers and AI agents can easily locate Claude templates in a predictable location (`dev-handbook/.integrations/claude/templates/`)
2. **Naming Consistency**: All template files follow a consistent naming convention with `.tmpl` extension to clearly distinguish them from regular markdown files
3. **No Duplication**: Each template serves a unique purpose with no overlapping functionality or duplicated content
4. **Clear Purpose**: Template names and content clearly indicate their specific use case (e.g., workflow commands vs general commands)
5. **Tool Integration**: The Ruby gem's ClaudeCommandGenerator can reliably find and use templates in their new standardized location

### Interface Contract
```bash
# File System Interface
dev-handbook/.integrations/claude/templates/
├── command.md.tmpl                 # General command template
├── workflow-command.md.tmpl        # Workflow-specific command template
└── agent-command.md.tmpl          # Agent-specific command template

# Ruby Gem Interface (ClaudeCommandGenerator)
@template_path = @project_root / "dev-handbook/.integrations/claude/templates/command.md.tmpl"

# Template Usage Pattern
template = load_template('command.md.tmpl')          # For general commands
template = load_template('workflow-command.md.tmpl') # For workflow commands
```

**Error Handling:**
- Missing template file: Clear error message indicating expected template location and filename
- Invalid template format: Validation error with specific formatting issue details
- Duplicate template purpose: Warning during build/test phase about overlapping template functionality

**Edge Cases:**
- Legacy template references: Automatic migration or clear deprecation warnings
- Cross-repository template usage: Clear documentation on template scope and boundaries

### Success Criteria
- [ ] **Organizational Clarity**: All Claude templates reside in `dev-handbook/.integrations/claude/templates/` directory
- [ ] **Naming Standardization**: 100% of template files use `.tmpl` extension consistently
- [ ] **Duplication Elimination**: Zero duplicate templates with overlapping functionality
- [ ] **Tool Compatibility**: Ruby gem ClaudeCommandGenerator successfully uses templates from new location
- [ ] **Documentation Accuracy**: All references to templates in documentation reflect new organization

### Validation Questions
- [ ] **Template Purpose Clarity**: Is the distinction between `command.template.md` and `workflow-command.md.tmpl` clear, or do they serve the same purpose?
- [ ] **Extension Implications**: What are the tooling implications of standardizing on `.tmpl` extension? Will editors/IDEs still provide proper syntax highlighting?
- [ ] **Migration Impact**: How many existing references to the old template location need to be updated across the codebase?
- [ ] **Template Discovery**: Should we add a template index or README in the templates directory to help developers understand each template's purpose?

## Objective

Improve the developer and AI agent experience when working with Claude integration templates by establishing clear organizational standards, eliminating confusion from duplicated or misplaced templates, and creating predictable patterns for template discovery and usage.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Template discovery, template selection, template maintenance workflows for both human developers and AI agents
- **System Behavior Scope**: File organization standards, naming conventions, duplication detection, migration handling
- **Interface Scope**: File system structure, Ruby gem template loading interface, documentation references

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Clear template organization structure specification
- Template naming convention guidelines  
- Template purpose and usage documentation

#### Validation Artifacts
- Template organization validation checklist
- Duplication detection methodology
- Migration success criteria

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Template engine selection, ERB vs other templating systems
- ❌ **Performance Optimization**: Template loading performance, caching strategies
- ❌ **Future Enhancements**: Additional template types, dynamic template generation, template versioning

## References

- Feedback context: Template organization improvement request
- Current template locations: 
  - `dev-handbook/.integrations/claude/command.template.md`
  - `dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl`
- Ruby gem usage: `dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb`