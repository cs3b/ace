---
id: v.0.9.0+task.057
status: draft
priority: high
estimate: TBD
dependencies: []
---

# fix(taskflow): --current flag should save ideas to current release

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow idea create -llm --current 'idea description'`
- **Process**: The command should detect the current release and save the idea file to that release's ideas directory
- **Output**: Idea file created at `.ace-taskflow/v.X.Y.Z/ideas/TIMESTAMP-idea-description.md` with confirmation message showing correct path

### Expected Behavior

When a user provides the `--current` flag to `ace-taskflow idea create`, the system should:
1. Determine the current active release (e.g., v.0.9.0)
2. Create the ideas directory within that release if it doesn't exist
3. Save the idea file to `.ace-taskflow/v.X.Y.Z/ideas/` instead of `.ace-taskflow/backlog/ideas/`
4. Display the correct path in the confirmation message

**Current Incorrect Behavior:**
```bash
❯ ace-taskflow idea create -llm --current 'we should add retro management'
Idea captured: .ace-taskflow/backlog/ideas/20250930-104840-feat-taskflow-retro-management.md
```

**Expected Correct Behavior:**
```bash
❯ ace-taskflow idea create -llm --current 'we should add retro management'
Idea captured: .ace-taskflow/v.0.9.0/ideas/20250930-104840-feat-taskflow-retro-management.md
```

### Interface Contract

```bash
# CLI Interface
ace-taskflow idea create -llm --current 'idea description'

# Expected output
Idea captured: .ace-taskflow/v.X.Y.Z/ideas/TIMESTAMP-SLUG.md

# Error cases
ace-taskflow idea create -llm --current 'idea'
# When no current release exists:
Error: No current release found. Use 'ace-taskflow release create' first or omit --current flag to save to backlog.
```

**Error Handling:**
- When `--current` flag is used but no current release exists: Display clear error message and suggest creating a release or using backlog
- When ideas directory creation fails: Report permission or filesystem errors
- When idea file write fails: Report the error with full path

**Edge Cases:**
- Multiple active releases: Use the most recently created active release
- Release with no ideas directory: Create the directory automatically
- Backlog should only be used when `--current` flag is NOT provided or no release exists

### Success Criteria

- [ ] **Correct Path Resolution**: When `--current` flag is used, idea files are saved to current release's ideas directory
- [ ] **Directory Creation**: Ideas directory is created automatically if it doesn't exist in the current release
- [ ] **Error Messages**: Clear error messages when no current release exists with actionable suggestions
- [ ] **Backward Compatibility**: Without `--current` flag, ideas still save to backlog as before
- [ ] **Path Display**: Confirmation message shows the actual path where the idea was saved

### Validation Questions

- [ ] **Release Detection**: How should the system determine "current release" when multiple releases exist?
- [ ] **Backlog Fallback**: Should the system fall back to backlog if release directory isn't writable, or fail with error?
- [ ] **Flag Naming**: Is `--current` the right name, or should it be `--release` with optional release version argument?
- [ ] **Backward Compatibility**: Are there existing workflows that depend on the current (incorrect) behavior?

## Objective

Fix the bug where the `--current` flag in `ace-taskflow idea create` incorrectly saves idea files to the backlog instead of the current release's ideas directory. This ensures ideas are properly organized within their target release from the moment of capture.

## Scope of Work

- **User Experience Scope**: Fix the path resolution logic when `--current` flag is provided
- **System Behavior Scope**: Correct idea file placement, directory creation, and error handling for current release scenarios
- **Interface Scope**: `ace-taskflow idea create` command with `--current` flag behavior

### Deliverables

#### Behavioral Specifications
- User experience flow for idea creation with `--current` flag
- System behavior for determining current release location
- Error handling specifications for missing or invalid releases

#### Validation Artifacts
- Success criteria validation through manual testing
- Test scenarios for normal operation, error cases, and edge cases
- Behavioral test cases (if test suite exists)

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby code structure or method organization
- ❌ **Technology Decisions**: Choice of file I/O libraries or path manipulation approaches
- ❌ **Performance Optimization**: Caching of release paths or optimization strategies
- ❌ **Future Enhancements**: Enhanced release management features or bulk idea operations

## References

- Source idea file: `.ace-taskflow/v.0.9.0/docs/ideas/057-20250930-104948-fix-bug-when-we-use-current-flag-and-idea-is-sav.md`
- Related feature: `ace-taskflow idea create` command
- Related concept: Current release detection and management
