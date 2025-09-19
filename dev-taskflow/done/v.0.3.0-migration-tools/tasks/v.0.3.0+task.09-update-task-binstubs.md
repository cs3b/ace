---

id: v.0.3.0+task.09
status: obsolete
priority: high
estimate: 3h
dependencies: [v.0.3.0+task.08]
resolution: superseded-by-task-31
---

# Update Task Management Binstubs

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la bin/t* | grep -E "tn|tr|tal|tnid|rc" | sed 's/^/    /'
```

_Result excerpt:_

```
    bin/tn
    bin/tr
    bin/tal
    bin/tnid
    bin/rc
```

## Objective

Update all task management binstubs to use the new gem commands while maintaining exact backward compatibility for existing workflows.

## Scope of Work

* Update bin/tn to use `coding_agent_tools task next`
* Update bin/tr to use `coding_agent_tools task recent`
* Update bin/tal to use `coding_agent_tools task all`
* Update bin/tnid to use `coding_agent_tools task generate-id`
* Update bin/rc to use `coding_agent_tools task current-release`
* Test all binstubs for compatibility

### Deliverables

#### Create

* None

#### Modify

* bin/tn
* bin/tr
* bin/tal
* bin/tnid
* bin/rc

#### Delete

* None

## Phases

1. Update each binstub
2. Test backward compatibility
3. Verify workflows remain intact

## Implementation Plan

### Planning Steps

* [ ] Review current binstub implementations
  > TEST: Current Implementation
  > Type: Pre-condition Check
  > Assert: Current binstubs are understood
  > Command: head -5 bin/tn bin/tr bin/tal bin/tnid bin/rc
* [ ] Design binstub update pattern for consistency
* [ ] Plan testing strategy for compatibility

### Execution Steps

- [ ] Update bin/tn to exec coding_agent_tools task next
  > TEST: TN Compatibility
  > Type: Integration Test
  > Assert: bin/tn produces same output as before
  > Command: bin/tn --help 2>&1 || echo "No help available"
- [ ] Update bin/tr to exec coding_agent_tools task recent
- [ ] Update bin/tal to exec coding_agent_tools task all
- [ ] Update bin/tnid to exec coding_agent_tools task generate-id
- [ ] Update bin/rc to exec coding_agent_tools task current-release
  > TEST: RC Compatibility
  > Type: Integration Test
  > Assert: bin/rc returns release path
  > Command: bin/rc | grep -E ".ace/taskflow|backlog"
- [ ] Test all binstubs with various arguments
- [ ] Verify output format remains identical

## Acceptance Criteria

* [ ] All task binstubs use new gem commands
* [ ] Backward compatibility is 100% maintained
* [ ] No changes to user workflows required
* [ ] Arguments are properly passed through
* [ ] Exit codes are preserved

## Out of Scope

* ❌ Adding new functionality to binstubs
* ❌ Changing binstub names or locations
* ❌ Modifying output formats

## RESOLUTION NOTE

**Status: OBSOLETE - Superseded by Task 31**

This task has been made obsolete by the implementation of v.0.3.0+task.31 (Implement Binstub Installation System), which took a superior architectural approach:

**Task 31's Solution:**
- Created configuration-driven binstub installation system (`.ace/tools/config/binstub-aliases.yml`)
- Implemented ATOM-based architecture for binstub generation
- Used `task-manager` executable instead of direct `coding_agent_tools` CLI calls
- Provided extensible system for future binstub additions
- Already completed all deliverables this task aimed to achieve

**Current State:**
- All task binstubs (tn, tr, tal, tnid) are working and use `task-manager` executable
- bin/rc was removed as planned
- Configuration system allows easy management of binstubs
- Shell binstub patterns are properly implemented

**Cross-Reference:** See v.0.3.0+task.31 for the comprehensive solution that addressed this scope.

## References

* Dependency: v.0.3.0+task.08 (CLI commands implementation)
* Superseded by: v.0.3.0+task.31 (Implement Binstub Installation System)
* Binstub pattern example from task.03 guide
* Current binstubs: bin/tn, bin/tr, bin/tal, bin/tnid, bin/rc