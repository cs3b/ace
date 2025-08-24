---
id: v.0.5.0+task.055
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Enhance integration command with automated project initialization

## Behavioral Specification

### User Experience
- **Input**: Developer runs `coding-agent-tools integrate claude` with optional `--init-project` flag
- **Process**: Integration detects missing project structure, creates directories, generates documentation from templates, and provides clear next steps
- **Output**: Complete project structure with dev-taskflow directories, core documentation files, and Claude integration, plus guidance for remaining manual steps

### Expected Behavior
When a developer runs the integration command in a new or existing project:

1. The system automatically detects the current project state (missing docs, no dev-taskflow, etc.)
2. With `--init-project` flag, it creates the complete project structure automatically
3. Without the flag, it provides clear guidance about what's missing and how to initialize
4. For new projects (no dev-taskflow), it creates v.0.0.0-bootstrap release structure
5. For existing projects, it skips v.0.0.0 creation and preserves existing structure
6. The system extracts project information from existing files (PRD.md, README.md, package.json, etc.)
7. Generated documentation uses templates with detected project information
8. Clear next-steps guidance appears after integration completes

### Interface Contract

```bash
# CLI Interface
coding-agent-tools integrate claude [OPTIONS]

# New options:
--init-project        # Initialize project structure and documentation
--skip-docs          # Skip documentation generation
--skip-bootstrap     # Skip v.0.0.0 release creation

# Expected outputs for new project:
🚀 Starting Claude integration with project initialization...
✓ Creating project structure...
  → Created dev-taskflow/backlog/
  → Created dev-taskflow/current/
  → Created dev-taskflow/done/
✓ Generating core documentation...
  → Created docs/what-do-we-build.md (from template)
  → Created docs/architecture.md (from template)
  → Created docs/blueprint.md (from template)
✓ Setting up v.0.0.0 bootstrap release...
  → Created 4 tasks in dev-taskflow/current/v.0.0.0-bootstrap/
✓ Integration complete!

📝 Next steps:
  1. Complete PRD.md with project requirements
  2. Ask Claude: "Read and follow @dev-handbook/workflow-instructions/initialize-project-structure.wf.md"
  3. Or run: task-manager next

# Note: initialize-project-structure remains a workflow, NOT a Claude command
# This is intentional - it's a one-time setup, not a recurring command

# Expected output when project already initialized:
✓ Core documentation detected, skipping generation
  → docs/architecture.md exists
  → docs/blueprint.md exists
✓ dev-taskflow structure exists, skipping v.0.0.0 creation
```

**Error Handling:**
- Missing submodules: Initialize them automatically with helpful messages
- Existing files: Never overwrite, report what was skipped
- Missing templates: Fall back to basic structure creation
- Permission errors: Provide clear error messages with resolution steps

**Edge Cases:**
- Partial initialization: Detect and complete only missing parts
- Existing v.0.0.0 in done/: Skip bootstrap creation entirely
- No git repository: Still create structure but warn about git integration
- Custom project layouts: Respect existing structure, add only missing pieces

### Success Criteria

- [ ] **Behavioral Outcome 1**: Developers can initialize a complete project structure with a single command
- [ ] **User Experience Goal 2**: Clear detection and reporting of existing vs. missing project components
- [ ] **System Performance 3**: Idempotent operation - safe to run multiple times without damage
- [ ] **User Experience Goal 4**: Actionable next-steps guidance based on project state
- [ ] **Behavioral Outcome 5**: Smart v.0.0.0 creation only for truly new projects

### Validation Questions

- [ ] **Requirement Clarity**: Should the command prompt for project information or use defaults with later customization?
- [ ] **Edge Case Handling**: How should we handle projects with custom directory structures?
- [ ] **User Experience**: Should --init-project be the default behavior or require explicit flag?
- [ ] **Success Definition**: What constitutes "sufficient" project initialization for productive work?

## Objective

Streamline the project initialization process by automating the creation of project structure, documentation templates, and bootstrap releases during Claude integration, reducing manual setup from ~30 minutes to under 1 minute while maintaining flexibility for customization.

### What Gets Automated (~70% of workflow)
- Directory structure creation (dev-taskflow/)
- Core documentation generation from templates
- v.0.0.0 bootstrap release setup (new projects only)
- Claude integration (agents, commands, hooks)
- Symlink creation for docs/tools.md

### What Remains Manual (~30% requiring human input)
- Interactive prompts for missing project information
- PRD completion with specific requirements
- Roadmap creation with strategic planning
- Stakeholder review and approval steps

## Scope of Work

### User Experience Scope
- Automated detection of project initialization needs
- Single-command project structure creation
- Intelligent template selection based on project type
- Clear guidance for remaining manual steps

### System Behavior Scope
- Create dev-taskflow directory structure when missing
- Generate core documentation from templates
- Set up v.0.0.0-bootstrap only for new projects
- Detect and extract project information from existing files
- Provide idempotent operations (safe reruns)

### Interface Scope
- New CLI flags for initialization control
- Enhanced status output during integration
- Clear next-steps guidance in output
- Preserved backward compatibility

### Deliverables

#### Behavioral Specifications
- Automated project structure creation flow
- Smart detection of existing vs. new projects
- Template-based documentation generation
- Conditional v.0.0.0 bootstrap creation

#### Validation Artifacts
- Detection of successful initialization
- Verification of idempotent behavior
- Clear reporting of actions taken vs. skipped

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby code structure or method organization
- ❌ **Technology Decisions**: Template engine choices or file I/O strategies
- ❌ **Performance Optimization**: Specific caching or optimization strategies
- ❌ **Future Enhancements**: Interactive prompts for missing information (future iteration)

## Technical Approach

### Architecture Pattern
- Extend existing integration command with modular initialization components
- Use template-based file generation with ERB processing
- Implement detection logic for existing project state
- Maintain separation between integration and initialization concerns

### Technology Stack
- Ruby (existing dev-tools implementation)
- ERB templates for dynamic content generation
- FileUtils for file system operations
- YAML for configuration management
- Pathname for cross-platform path handling

### Implementation Strategy
1. Add new CLI options to integrate command
2. Create template directory structure in dev-handbook
3. Implement project detection methods
4. Add conditional initialization logic
5. Enhance output with actionable guidance

## Tool Selection

| Criteria | ERB Templates | Liquid Templates | Plain Files | Selected |
|----------|--------------|------------------|-------------|----------|
| Dynamic content | Excellent | Excellent | Poor | ERB |
| Ruby integration | Native | Gem required | N/A | ERB |
| Complexity | Simple | More complex | Simplest | ERB |
| Existing usage | Yes (in project) | No | Yes | ERB |

**Selection Rationale:** ERB is already used in the project, provides native Ruby integration, and handles dynamic content well.

## File Modifications

### Create
- dev-handbook/.meta/tpl/project-structure/taskflow/backlog/.gitkeep
- dev-handbook/.meta/tpl/project-structure/taskflow/current/.gitkeep
- dev-handbook/.meta/tpl/project-structure/taskflow/done/.gitkeep
- dev-handbook/.meta/tpl/project-structure/docs/what-do-we-build.md.erb
- dev-handbook/.meta/tpl/project-structure/docs/architecture.md.erb
- dev-handbook/.meta/tpl/project-structure/docs/blueprint.md.erb
- dev-handbook/.meta/tpl/project-structure/bootstrap/v.0.0.0-bootstrap/release-overview.md.erb
- dev-handbook/.meta/tpl/project-structure/bootstrap/v.0.0.0-bootstrap/tasks/01-setup-structure.md.erb
- dev-handbook/.meta/tpl/project-structure/bootstrap/v.0.0.0-bootstrap/tasks/02-complete-documentation.md.erb
- dev-handbook/.meta/tpl/project-structure/bootstrap/v.0.0.0-bootstrap/tasks/03-complete-prd.md.erb
- dev-handbook/.meta/tpl/project-structure/bootstrap/v.0.0.0-bootstrap/tasks/04-create-roadmap.md.erb

### Modify
- dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb
  - Add new CLI options (--init-project, --skip-docs, --skip-bootstrap)
  - Add create_project_structure method
  - Add generate_core_docs method
  - Add setup_bootstrap_release method
  - Add detect_project_info method
  - Add should_create_bootstrap? logic
  - Enhance output with next-steps guidance

- dev-tools/config/integration.yml
  - Add project_structure component configuration (optional)

### Delete
- None

## Risk Assessment

### Technical Risks
- **Risk:** Template processing errors with missing project information
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Use safe navigation and default values in templates

- **Risk:** File system permission issues during creation
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Check permissions early, provide clear error messages

### Integration Risks
- **Risk:** Breaking existing integration workflow
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Make initialization opt-in with --init-project flag

## Implementation Plan

### Planning Steps

* [x] Analyze current initialize-project-structure workflow
* [x] Identify automatable vs. manual components
* [x] Design template structure and organization

### Execution Steps

- [ ] Create template directory structure in dev-handbook/.meta/tpl/project-structure/
- [ ] Convert workflow templates to ERB templates with dynamic content
- [ ] Create symlink for docs/tools.md from dev-tools/docs/tools.md (if exists)
- [ ] Add CLI options to integrate command
  ```ruby
  option :init_project, type: :boolean, default: false
  option :skip_docs, type: :boolean, default: false
  option :skip_bootstrap, type: :boolean, default: false
  ```
- [ ] Implement project detection logic
  ```ruby
  def detect_project_info
    # Check for PRD.md, README.md, package.json, etc.
  end
  
  def should_create_bootstrap?
    !@project_root.join("dev-taskflow").exist?
  end
  ```
- [ ] Implement structure creation methods
- [ ] Add template processing with ERB
- [ ] Implement conditional v.0.0.0 creation
- [ ] Enhance output with guidance
- [ ] Test with new project scenario
- [ ] Test with existing project scenario
- [ ] Test idempotent behavior
- [ ] Update documentation

## Acceptance Criteria

- [ ] Integration command accepts --init-project flag
- [ ] dev-taskflow structure created when missing (backlog/, current/, done/)
- [ ] Core docs generated from templates when missing
- [ ] docs/tools.md symlink created from dev-tools/docs/tools.md (if source exists)
- [ ] v.0.0.0 bootstrap created ONLY for new projects (when dev-taskflow doesn't exist)
- [ ] Existing files never overwritten (idempotent operation)
- [ ] Clear next-steps guidance provided based on project state
- [ ] initialize-project-structure.wf.md NOT created as Claude command (remains workflow only)
- [ ] All tests pass (new project, existing project, partial project)

## References

- Current integration workflow: dev-handbook/workflow-instructions/initialize-project-structure.wf.md
- Integration command: dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb
- Discussion context: User feedback on integration automation needs
- Related idea: Simplifying one-time initialization workflows