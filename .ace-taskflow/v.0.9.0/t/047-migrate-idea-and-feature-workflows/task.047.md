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
- Idea prioritization that ranks and aligns ideas with project goals using `ace-taskflow idea reschedule` (sort metadata, not file renaming)
- Feature capture that creates detailed/comprehensive idea documentation for application features
- Unplanned work documentation that captures completed work as done tasks

**Output locations:**
- Ideas (quick & detailed): `.ace-taskflow/backlog/ideas/` - feature capture creates "beefy" ideas with comprehensive specs
- Unplanned work: `.ace-taskflow/v.X.X.X/t/done/` - creates completed task files with status `done`

### Interface Contract

**Claude Code Commands** (Slash commands):

```
# Prioritize and align ideas
/ace:prioritize-ideas
# Reads ideas from .ace-taskflow/backlog/ideas/
# Executes: wfi://prioritize-align-ideas
# Uses: ace-taskflow idea reschedule commands to set priority order
# Output: Ideas with sort metadata showing priority order

# Capture application features (as detailed ideas)
/ace:capture-features [app-path]
# Executes: wfi://capture-application-features
# Output: Detailed/beefy idea file in .ace-taskflow/backlog/ideas/
# Note: Creates comprehensive idea with components, interactions, tracking specs

# Document unplanned work
/ace:document-unplanned [description]
# Executes: wfi://document-unplanned-work
# Output: Completed task in .ace-taskflow/v.X.X.X/t/done/ with status done
```

**Command File Locations**:
- `.claude/commands/ace/prioritize-ideas.md` → wfi://prioritize-align-ideas
- `.claude/commands/ace/capture-features.md` → wfi://capture-application-features
- `.claude/commands/ace/document-unplanned.md` → wfi://document-unplanned-work

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
   - Implementation: Uses `ace-taskflow idea reschedule` to set priority order via sort metadata (no file renaming)

2. **capture-application-features** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/capture-application-features.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/capture-application-features.wf.md`
   - Command: `ace-taskflow idea capture-features`
   - Output: Detailed idea files in `.ace-taskflow/backlog/ideas/` (same as capture-idea, but more comprehensive)

3. **document-unplanned-work** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/document-unplanned-work.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/document-unplanned-work.wf.md`
   - Command: `ace-taskflow idea document-unplanned`
   - Output: Completed task files in `.ace-taskflow/v.X.X.X/t/done/` with status `done`

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
