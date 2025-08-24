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

**Mode 1: Regular Integration (default - run often)**
```bash
coding-agent-tools integrate claude
```
- Updates all Claude components (agents, commands, hooks, dotfiles)
- Safe to run repeatedly for getting latest updates
- Never overwrites without --force flag
- Reports what was updated/skipped

**Mode 2: Project Initialization (run once per project)**
```bash
coding-agent-tools integrate claude --init-project
```
- Performs all regular integration PLUS:
- Creates dev-taskflow/ structure if missing (idempotent)
- Generates core docs from templates if missing (idempotent)
- Creates v.0.0.0-bootstrap if dev-taskflow is new (conditional)
- Creates docs/tools.md symlink if source exists (idempotent)
- Extracts project info from existing files (PRD.md, README.md, package.json)
- Provides clear next-steps guidance based on what was created

### Interface Contract

```bash
# CLI Interface
coding-agent-tools integrate claude [OPTIONS]

# New option (only one needed):
--init-project        # Initialize project structure and documentation (run once per project)

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
  - Answer: Use defaults, guide user to complete manually afterward
- [ ] **Edge Case Handling**: How should we handle projects with custom directory structures?
  - Answer: Respect existing structure, only add missing pieces (idempotent)
- [ ] **User Experience**: Should --init-project be the default behavior or require explicit flag?
  - Answer: Require explicit flag to avoid surprises (opt-in)
- [ ] **Success Definition**: What constitutes "sufficient" project initialization for productive work?
  - Answer: Structure + templates created, user can run task-manager next

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
1. Add single --init-project flag to integrate command
2. Create template directory structure in dev-handbook
3. Implement project detection methods with idempotent checks
4. Leverage existing file-checking logic (no skip flags needed)
5. Enhance output with mode-specific guidance

### Why No Skip Flags Needed
- Existing code already checks file existence before creating
- Never overwrites without --force flag  
- Automatically skips what exists (idempotent by design)
- Simpler mental model: two clear modes instead of complex flag combinations

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
- [ ] Add single CLI option to integrate command
  ```ruby
  option :init_project, type: :boolean, default: false,
    desc: "Initialize project structure and documentation (run once per project)"
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
- [ ] Implement structure creation methods with idempotent checks
  ```ruby
  def create_project_structure
    return if @project_root.join("dev-taskflow").exist?
    # Create directories
  end
  
  def generate_core_docs
    # Only create missing docs
    create_doc("what-do-we-build") unless doc_exists?("what-do-we-build")
    create_doc("architecture") unless doc_exists?("architecture")
    create_doc("blueprint") unless doc_exists?("blueprint")
  end
  ```
- [ ] Add template processing with ERB
- [ ] Implement conditional v.0.0.0 creation (only if dev-taskflow is new)
- [ ] Enhance output with clear guidance for both modes
- [ ] Test with new project scenario
- [ ] Test with existing project scenario
- [ ] Test idempotent behavior
- [ ] Update documentation

## Acceptance Criteria

### Mode 1: Regular Integration (default)
- [ ] Updates Claude components without creating project structure
- [ ] Safe to run repeatedly without side effects
- [ ] Reports what was updated/skipped

### Mode 2: Project Initialization (--init-project)
- [ ] Single flag enables all initialization features
- [ ] dev-taskflow structure created only when missing (idempotent)
- [ ] Core docs generated from templates only when missing (idempotent)
- [ ] docs/tools.md symlink created only if source exists (idempotent)
- [ ] v.0.0.0 bootstrap created ONLY when dev-taskflow is new
- [ ] Existing files NEVER overwritten without --force
- [ ] Clear mode-specific guidance provided
- [ ] initialize-project-structure.wf.md remains workflow (not command)

### Testing Requirements
- [ ] Test Mode 1: Regular integration updates components only
- [ ] Test Mode 2: New project gets full initialization
- [ ] Test Mode 2: Existing project skips what exists
- [ ] Test Mode 2: Partial project gets only missing pieces
- [ ] Verify idempotent behavior in all scenarios

## References

- Current integration workflow: dev-handbook/workflow-instructions/initialize-project-structure.wf.md
- Integration command: dev-tools/lib/coding_agent_tools/cli/commands/integrate.rb
- Discussion context: User feedback on integration automation needs
- Related idea: Simplifying one-time initialization workflows