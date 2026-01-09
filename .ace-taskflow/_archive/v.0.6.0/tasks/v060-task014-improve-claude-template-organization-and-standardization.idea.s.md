---
id: v.0.6.0+task.014
status: done
priority: high
estimate: 2h
dependencies: []
---

# Improve Claude template organization and standardization

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents working with Claude integration templates in the .ace/handbook repository
- **Process**: Discovering, referencing, and maintaining Claude command templates with clear organization and consistent naming conventions
- **Output**: Well-organized template structure that is intuitive to navigate, eliminates duplication, and follows consistent naming patterns

### Expected Behavior
The system should provide a clear, consistent template organization for Claude integrations where:

1. **Template Discovery**: Developers and AI agents can easily locate Claude templates in a predictable location (`.ace/handbook/.integrations/claude/templates/`)
2. **Naming Consistency**: All template files follow a consistent naming convention with `.tmpl` extension to clearly distinguish them from regular markdown files
3. **No Duplication**: Each template serves a unique purpose with no overlapping functionality or duplicated content
4. **Clear Purpose**: Template names and content clearly indicate their specific use case (e.g., workflow commands vs general commands)
5. **Tool Integration**: The Ruby gem's ClaudeCommandGenerator can reliably find and use templates in their new standardized location

### Interface Contract
```bash
# File System Interface
.ace/handbook/.integrations/claude/templates/
├── command.md.tmpl                 # General command template
├── workflow-command.md.tmpl        # Workflow-specific command template
└── agent-command.md.tmpl          # Agent-specific command template

# Ruby Gem Interface (ClaudeCommandGenerator)
@template_path = @project_root / ".ace/handbook/.integrations/claude/templates/command.md.tmpl"

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
- [ ] **Organizational Clarity**: All Claude templates reside in `.ace/handbook/.integrations/claude/templates/` directory
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
  - `.ace/handbook/.integrations/claude/command.template.md`
  - `.ace/handbook/.integrations/claude/templates/workflow-command.md.tmpl`
- Ruby gem usage: `.ace/tools/lib/coding_agent_tools/organisms/claude_command_generator.rb`

## Technical Approach

### Architecture Pattern
- [ ] Consolidate template functionality into a single, standardized location
- [ ] Follow existing project patterns for template organization (all templates use `.template.md` extension)
- [ ] Ensure backward compatibility during migration with deprecation warnings

### Technology Stack
- [ ] Ruby ERB templating (existing in ClaudeCommandGenerator)
- [ ] FileUtils for file operations
- [ ] Pathname for cross-platform path handling
- [ ] YAML for front-matter parsing and validation

### Implementation Strategy
- [ ] Move template to standardized location with proper naming
- [ ] Update ClaudeCommandGenerator to use new template location
- [ ] Remove duplicate/obsolete templates
- [ ] Update all documentation references
- [ ] Ensure tests continue to pass

## File Modifications

### Create
- `.ace/handbook/.integrations/claude/templates/command.md.tmpl`
  - Purpose: Consolidated command template with YAML front-matter
  - Key components: YAML front-matter variables, workflow reference, commit command
  - Dependencies: ERB templating in ClaudeCommandGenerator

### Modify
- `.ace/tools/lib/coding_agent_tools/organisms/claude_command_generator.rb`
  - Changes: Update template path from `command.template.md` to `templates/command.md.tmpl`
  - Impact: All generated commands will use new template location
  - Integration points: Template loading in `load_template` method

- `.ace/tools/spec/coding_agent_tools/organisms/claude_command_generator_spec.rb`
  - Changes: Update test expectations for new template path
  - Impact: Tests will validate new template location
  - Integration points: Template path setup in test fixtures

- `.ace/tools/docs/development/claude-integration.md`
  - Changes: Update documentation to reflect new template organization
  - Impact: Developer documentation accuracy
  - Integration points: Template usage examples

### Delete
- `.ace/handbook/.integrations/claude/command.template.md`
  - Reason: Replaced by standardized template in templates directory
  - Dependencies: ClaudeCommandGenerator after it's updated
  - Migration strategy: Move content to new location first

- `.ace/handbook/.integrations/claude/templates/workflow-command.md.tmpl`
  - Reason: Duplicate functionality with main command template
  - Dependencies: None currently in use
  - Migration strategy: Verify no active usage before removal

- `.ace/handbook/.integrations/claude/templates/agent-command.md.tmpl`
  - Reason: Not currently used, adds unnecessary complexity
  - Dependencies: None found in codebase
  - Migration strategy: Direct removal after verification

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing command generation functionality
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Update paths carefully, run full test suite
  - **Rollback:** Git revert if generation fails

### Integration Risks
- **Risk:** Documentation references become outdated
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Comprehensive grep search for all references
  - **Monitoring:** Review generated commands after change

## Implementation Plan

### Planning Steps

* [x] Analyze template content differences and consolidation approach
  > TEST: Template Analysis
  > Type: Pre-condition Check
  > Assert: All template variations and their purposes are documented
  > Command: diff -u .ace/handbook/.integrations/claude/command.template.md .ace/handbook/.integrations/claude/templates/workflow-command.md.tmpl

* [x] Search for all references to old template paths in codebase
  > TEST: Reference Search
  > Type: Pre-condition Check
  > Assert: All files referencing old paths are identified
  > Command: grep -r "command\.template\.md\|workflow-command\.md\.tmpl\|agent-command\.md\.tmpl" . --include="*.rb" --include="*.md" --include="*.yml" | grep -v ".git"

* [x] Plan test execution strategy to ensure no regression

### Execution Steps

- [x] Create consolidated template at new location
  ```bash
  mkdir -p .ace/handbook/.integrations/claude/templates
  cp .ace/handbook/.integrations/claude/command.template.md .ace/handbook/.integrations/claude/templates/command.md.tmpl
  ```
  > TEST: Template Creation
  > Type: Action Validation
  > Assert: New template file exists with correct content
  > Command: test -f .ace/handbook/.integrations/claude/templates/command.md.tmpl && grep -q "description:" .ace/handbook/.integrations/claude/templates/command.md.tmpl

- [x] Update ClaudeCommandGenerator to use new template path
  - Change line 18: `@template_path = @project_root / ".ace/handbook/.integrations/claude/templates/command.md.tmpl"`
  > TEST: Ruby Syntax Check
  > Type: Action Validation
  > Assert: Ruby file has valid syntax after modification
  > Command: cd .ace/tools && ruby -c lib/coding_agent_tools/organisms/claude_command_generator.rb

- [x] Update ClaudeCommandGenerator spec file for new path
  - Update all occurrences of `command.template.md` to `templates/command.md.tmpl`
  > TEST: Spec Syntax Check
  > Type: Action Validation
  > Assert: Spec file has valid syntax
  > Command: cd .ace/tools && ruby -c spec/coding_agent_tools/organisms/claude_command_generator_spec.rb

- [x] Run ClaudeCommandGenerator tests to ensure functionality
  > TEST: Generator Tests
  > Type: Integration Test
  > Assert: All ClaudeCommandGenerator tests pass
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/claude_command_generator_spec.rb

- [x] Update documentation in claude-integration.md
  - Update template paths and examples
  - Remove references to duplicate templates
  > TEST: Documentation Consistency
  > Type: Action Validation
  > Assert: No references to old template paths remain
  > Command: grep -c "command\.template\.md\|workflow-command\.md\.tmpl\|agent-command\.md\.tmpl" .ace/tools/docs/development/claude-integration.md | grep -q "0"

- [x] Remove old template file
  ```bash
  rm .ace/handbook/.integrations/claude/command.template.md
  ```
  > TEST: Old Template Removal
  > Type: Action Validation
  > Assert: Old template file no longer exists
  > Command: test ! -f .ace/handbook/.integrations/claude/command.template.md

- [x] Remove duplicate template files
  ```bash
  rm .ace/handbook/.integrations/claude/templates/workflow-command.md.tmpl
  rm .ace/handbook/.integrations/claude/templates/agent-command.md.tmpl
  ```
  > TEST: Duplicate Removal
  > Type: Action Validation
  > Assert: Duplicate templates no longer exist
  > Command: test ! -f .ace/handbook/.integrations/claude/templates/workflow-command.md.tmpl && test ! -f .ace/handbook/.integrations/claude/templates/agent-command.md.tmpl

- [x] Generate a test command to verify functionality
  > TEST: Command Generation
  > Type: End-to-End Test
  > Assert: Commands can be generated successfully with new template
  > Command: cd .ace/tools && bin/claude generate --dry-run

- [x] Run full test suite to ensure no regression
  > TEST: Full Test Suite
  > Type: Regression Test
  > Assert: All tests pass
  > Command: cd .ace/tools && bundle exec rspec

## Acceptance Criteria

- [x] AC 1: All Claude templates consolidated in `.ace/handbook/.integrations/claude/templates/` with `.tmpl` extension
- [x] AC 2: ClaudeCommandGenerator successfully uses new template location
- [x] AC 3: All duplicate templates removed
- [x] AC 4: Documentation updated to reflect new template organization
- [x] AC 5: All tests pass with new template structure