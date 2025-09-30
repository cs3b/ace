---
id: v.0.9.0+task.054
status: draft
priority: low
estimate: TBD
dependencies: []
---

# Create ace-git package for git operations

## Behavioral Specification

### User Experience
- **Input**: User invokes git operation commands via ace-git CLI (e.g., `ace-git rebase-against <branch>`)
- **Process**: System performs safe, guided git operations with validation and conflict detection
- **Output**: Successful git operations with clear feedback, or detailed error messages with recovery guidance

### Expected Behavior

Users experience enhanced git operations that provide safety checks, guidance, and automation for complex git workflows. The system provides:

**Rebase Against Branch**: Safely rebase current branch against target branch
- Validates current branch state (clean working directory, no uncommitted changes)
- Fetches latest changes from remote
- Performs interactive rebase with conflict detection
- Provides step-by-step guidance for conflict resolution
- Validates successful rebase completion
- Offers rollback on failure

The workflow prioritizes safety and clarity, preventing data loss and guiding users through complex git operations that might otherwise be error-prone.

### Interface Contract

```bash
# Rebase current branch against target branch
ace-git rebase-against <branch-name> [--interactive] [--preserve-merges]
# Executes: wfi://rebase-against
# Pre-checks: Clean working directory, valid branch
# Output: Rebased branch or detailed error with recovery steps

# Validate rebase safety (pre-flight check)
ace-git rebase-against <branch-name> --dry-run
# Output: Validation report without performing rebase

# Abort rebase in progress
ace-git rebase-abort
# Output: Rebase aborted, branch restored to pre-rebase state
```

**Error Handling:**
- Uncommitted changes: Report files, suggest stashing or committing
- Invalid branch name: List available branches, suggest corrections
- Merge conflicts: Provide file list, guide through resolution
- Remote fetch failure: Check network, suggest retry
- Rebase failure: Offer abort and restore to previous state

**Edge Cases:**
- Already up to date: Report success, no changes needed
- Detached HEAD: Warn and suggest creating branch first
- Diverged branches: Explain implications, confirm action
- Protected branch: Prevent rebase, explain why

### Success Criteria

- [ ] **Safe Operations**: System prevents data loss through validation and pre-checks
- [ ] **Clear Guidance**: Users receive step-by-step instructions for complex operations
- [ ] **Conflict Support**: System provides actionable guidance for conflict resolution
- [ ] **Rollback Capability**: Failed operations can be safely rolled back
- [ ] **Status Transparency**: Users always understand current state and next steps

### Validation Questions

- [ ] **Operation Scope**: Should ace-git handle only rebase, or expand to other git operations?
- [ ] **Safety Level**: How aggressive should pre-checks be (warn vs. block)?
- [ ] **Conflict Resolution**: Should system attempt auto-resolution or always require manual input?
- [ ] **Remote Operations**: Should package handle push/pull operations or only local git?
- [ ] **Integration**: Should package integrate with other ace tools (taskflow, context)?

## Objective

Create a dedicated git operations package (ace-git) that provides safe, guided workflows for complex git operations, starting with rebase-against functionality, with potential to expand to other git workflows.

## Scope of Work

### Package Structure
New package: **ace-git** (Ruby gem or standalone tool)
- Location: `dev-tools/ace-git/`
- CLI namespace: `ace-git`
- Initial focus: rebase operations

### Workflows to Migrate
1. **rebase-against** (dev-handbook → ace-git)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/rebase-against.wf.md`
   - Integration: `ace-git rebase-against` calls wfi://rebase-against
   - Command: `ace-git rebase-against <branch>`

### Interface Scope
- CLI commands under `ace-git` namespace
- wfi:// protocol integration for workflow delegation
- Git state validation and safety checks
- Conflict detection and resolution guidance
- Error handling and rollback support

### Deliverables

#### Behavioral Specifications
- Rebase operation workflow
- Safety validation behavior
- Conflict resolution guidance
- Error handling and recovery

#### Package Structure
- Ruby gem or standalone CLI tool
- Workflow integration layer
- Git operations wrapper
- Safety validation framework
- Configuration management
- Documentation and examples

## Out of Scope

- ❌ **Implementation Details**: Ruby git library integration, command execution, state management
- ❌ **Advanced Git Operations**: Cherry-pick, bisect, subtree, filter-branch operations
- ❌ **GUI Interface**: Visual merge tools, interactive conflict resolution UI
- ❌ **GitHub/GitLab Integration**: Pull requests, issues, CI/CD workflows
- ❌ **Other Operations**: Beyond rebase (can be added in future iterations)

## References

- Workflow file: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/rebase-against.wf.md`
- Git documentation: Standard git rebase behavior and best practices
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`

## Notes

This task creates a minimal ace-git package focused on rebase operations. Future iterations can expand to include other git workflows (commit, push, pull, merge, etc.) based on user needs and workflow requirements.
