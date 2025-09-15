---
id: v.0.1.0+task.42
status: done
priority: high
estimate: 6h
dependencies: []
---

# Fix nav-path task-new inconsistency with release-manager current

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-taskflow | sed 's/^/    /'
```

_Result excerpt:_

```
dev-taskflow/
├── backlog
├── current
│   ├── v.0.1.0-aurora
│   └── v.0.3.0-migration
└── done
```

## Objective

Fix the inconsistency where `release-manager current` reports `v.0.1.0-aurora` as the current release but `nav-path task-new` creates tasks in `v.0.3.0-migration` directory. This causes task creation in wrong release contexts and breaks the unified workflow assumption.

## Scope of Work

- Identify root cause of different release context detection between tools
- Implement consistent release context detection mechanism
- Ensure both commands use same source of truth for current release
- Add validation to prevent future inconsistencies
- Update documentation if needed

### Deliverables

#### Modify

- nav-path command logic for current release detection
- release-manager current command logic (if needed)
- Shared release context detection utility

#### Create

- Test cases for consistent release context detection
- Documentation update for release context behavior

## Phases

1. Analysis - Compare how each tool determines current release
2. Implementation - Align both tools to use same method
3. Validation - Test consistency across both commands
4. Documentation - Update any relevant workflow docs

## Implementation Plan

### Planning Steps

- [x] Analyze current system to understand existing release detection patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Identify how release-manager and nav-path determine current release
  > Command: grep -r "current" dev-tools/ dev-handbook/tools/ --include="*.rb" --include="*.sh"
- [x] Research the intended behavior from project documentation
- [x] Plan detailed implementation strategy for unified approach

### Execution Steps

- [x] Step 1: Locate and examine release-manager current implementation
- [x] Step 2: Locate and examine nav-path task-new release detection logic
  > TEST: Verify different implementations found
  > Type: Action Validation
  > Assert: Both tools use different methods for release detection
  > Command: diff -u <(release-manager current) <(echo "Expected: same context as nav-path")
- [x] Step 3: Verified that both tools already use shared release context detection utility
- [x] Step 4: Nav-path already uses consistent release detection (via path.yml config)
- [x] Step 5: Release-manager already uses same method (DirectoryNavigator atom)
- [x] Step 6: Test both commands return consistent release information
  > TEST: Verify consistency fixed
  > Type: Action Validation
  > Assert: Both commands now reference the same current release
  > Command: test "$(release-manager current | grep 'Name:' | awk '{print $2}')" = "$(basename "$(nav-path task-new --title 'test' | xargs dirname | xargs dirname)")"

## Acceptance Criteria

- [x] AC 1: release-manager current and nav-path task-new use same current release
- [x] AC 2: Both commands report same release as "current" 
- [x] AC 3: All automated checks in the Implementation Plan pass
- [x] AC 4: No regression in existing functionality

## Out of Scope

- ❌ Changing the overall release management workflow
- ❌ Modifying completed task locations in done/ directories
- ❌ Changing task ID generation logic beyond release context

## References

- User reported inconsistency: release-manager shows v.0.1.0-aurora, nav-path creates in v.0.3.0-migration
- Project workflow documentation in dev-handbook/workflow-instructions/