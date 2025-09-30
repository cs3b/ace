---
id: v.0.9.0+task.047
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Migrate idea and feature workflows to ace-taskflow

## Behavioral Specification

### User Experience
- **Input**: User invokes idea management commands via ace-taskflow CLI (e.g., `ace-taskflow idea prioritize`, `ace-taskflow idea capture-features`)
- **Process**: System executes workflow instructions through wfi:// protocol, providing clear progress feedback and validation
- **Output**: Organized idea files, enhanced ideas with context, and actionable feature captures stored in .ace-taskflow structure

### Expected Behavior

Users experience seamless idea management workflows that are centrally available through the ace-taskflow command. When users need to organize ideas, capture features, or document unplanned work, they invoke ace-taskflow commands that delegate to workflow instructions using the wfi:// protocol.

The system provides:
- Idea prioritization that ranks and aligns ideas with project goals
- Feature capture that extracts capabilities from applications into structured documentation
- Unplanned work documentation that captures ad-hoc changes for future planning

All workflows maintain consistent behavior with existing patterns while being accessible through the unified ace-taskflow interface.

### Interface Contract

```bash
# Prioritize and align ideas
ace-taskflow idea prioritize
# Reads ideas from .ace-taskflow/backlog/ideas/
# Executes: wfi://prioritize-align-ideas
# Output: Ranked ideas with alignment scores

# Capture application features
ace-taskflow idea capture-features [--app-path <path>]
# Executes: wfi://capture-application-features
# Output: Feature documentation in .ace-taskflow/backlog/features/

# Document unplanned work
ace-taskflow idea document-unplanned <description>
# Executes: wfi://document-unplanned-work
# Output: Unplanned work captured in .ace-taskflow/backlog/ideas/
```

**Error Handling:**
- Missing .ace-taskflow directory: Report error and suggest initialization
- No ideas found: Inform user and suggest creating ideas first
- Workflow file not found: Report missing wfi:// resource and suggest installation

**Edge Cases:**
- Empty idea directory: Return informative message, exit gracefully
- Malformed idea files: Skip with warning, continue processing valid files
- Concurrent modifications: Use file locking or atomic operations

### Success Criteria

- [ ] **Unified CLI Access**: Users can invoke all three workflows through ace-taskflow command
- [ ] **Workflow Delegation**: Commands properly delegate to wfi:// protocol handlers
- [ ] **Consistent Behavior**: Workflows maintain existing functionality and output formats
- [ ] **Clear Feedback**: Users receive progress updates and error messages during execution
- [ ] **Documentation**: Command help text clearly describes workflow purposes and usage

### Validation Questions

- [ ] **Command Structure**: Should commands be under `ace-taskflow idea` namespace or separate subcommands?
- [ ] **Workflow Location**: Where should workflow .wf.md files reside - ace-taskflow/handbook/ or project-local?
- [ ] **Backward Compatibility**: Should old workflow locations continue working or redirect to new ones?
- [ ] **Configuration**: Are there workflow-specific settings users need to configure?

## Objective

Enable centralized idea management workflows through ace-taskflow CLI, providing users with consistent access to idea prioritization, feature capture, and unplanned work documentation capabilities.

## Scope of Work

### Workflows to Migrate
1. **prioritize-align-ideas** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/prioritize-align-ideas.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/prioritize-align-ideas.wf.md`
   - Command: `ace-taskflow idea prioritize`

2. **capture-application-features** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/capture-application-features.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/capture-application-features.wf.md`
   - Command: `ace-taskflow idea capture-features`

3. **document-unplanned-work** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/document-unplanned-work.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/document-unplanned-work.wf.md`
   - Command: `ace-taskflow idea document-unplanned`

### Interface Scope
- CLI commands under `ace-taskflow idea` namespace
- wfi:// protocol integration for workflow delegation
- Help text and usage documentation
- Error messages and user feedback

## Out of Scope

- ❌ **Implementation Details**: Ruby class structure, file organization patterns
- ❌ **New Features**: Additional idea management capabilities beyond migration
- ❌ **UI Changes**: Visual interfaces, interactive prompts (unless existing)
- ❌ **Performance Optimization**: Workflow execution speed improvements

## References

- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/prioritize-align-ideas.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/capture-application-features.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/document-unplanned-work.wf.md`
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
