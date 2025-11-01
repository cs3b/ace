---
id: v.0.9.0+task.098
status: draft
priority: high
estimate: 4h
dependencies: []
---

# Fix ace-git-commit silent staging failures and misleading error messages

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-git-commit` with unstaged changes, expecting automatic staging
- **Process**: User should see clear status messages about staging attempts, progress, and any failures
- **Output**: Either successful commit with clear confirmation, or actionable error message explaining what went wrong

### Expected Behavior
The ace-git-commit tool should provide transparent feedback throughout the staging and commit process. Users should:
- See when staging is being attempted (not just in debug mode)
- Know immediately if staging fails with a clear explanation
- Receive accurate error messages that match the actual outcome
- Never see "Error" for successful commits
- Get actionable guidance when issues occur (e.g., "Run 'git status' to see unstaged files")

The tool should fail fast with clear messages rather than continuing silently after failures.

### Interface Contract
```bash
# CLI Interface
ace-git-commit [options]
# Normal operation with unstaged files
$ ace-git-commit -i "fix: something"
Staging all changes...
✓ Changes staged successfully
Generating commit message...
Committing...
✓ Committed: abc1234 fix: something

# Staging failure scenario
$ ace-git-commit -i "fix: something"
Staging all changes...
✗ Failed to stage changes
Error: Permission denied for file 'protected.txt'
Suggestion: Fix file permissions or use --only-staged to commit existing staged files

# Pre-commit hook with modifications (not an error)
$ ace-git-commit -i "feat: new feature"
Staging all changes...
✓ Changes staged successfully
Committing...
Note: Pre-commit hook modified files (formatting applied)
✓ Committed: def5678 feat: new feature
```

**Error Handling:**
- Staging permission errors: Clear message about which files failed
- No changes to stage: Inform user no unstaged changes exist
- Pre-commit hook modifications: Show as note, not error
- Git command failures: Display actual git error message

**Edge Cases:**
- Large files exceeding limits: Warn about file size before attempting
- Submodule changes: Inform user about submodule staging requirements
- Mixed staged/unstaged: Clarify what will be committed

### Success Criteria
- [ ] **Visible Staging Status**: Users always see staging attempts and results (not debug-only)
- [ ] **Accurate Failure Detection**: Staging failures are immediately detected and reported
- [ ] **Clear Error Messages**: Error messages accurately reflect what happened and provide next steps
- [ ] **No False Errors**: Successful commits never show "Error" messages
- [ ] **Actionable Guidance**: Failed operations provide specific suggestions for resolution

### Validation Questions
- [ ] **Error Message Priority**: Should warnings (like pre-commit hooks) use different formatting than errors?
- [ ] **Verbosity Levels**: Should there be quiet/normal/verbose modes instead of just debug?
- [ ] **Staging Validation**: Should we verify staged files match expected changes before committing?
- [ ] **Retry Logic**: Should staging failures offer automatic retry with different strategies?

## Objective

Fix the misleading staging behavior in ace-git-commit where the tool reports "Staging all changes" but silently fails, leaving users confused about why their changes aren't committed. Improve error reporting to accurately reflect operation outcomes.

## Scope of Work

- **User Experience Scope**: Staging feedback, error messages, success confirmations
- **System Behavior Scope**: Staging validation, error detection, message accuracy
- **Interface Scope**: CLI output messages, error codes, status indicators

### Deliverables

#### Behavioral Specifications
- Clear staging status messages for all users (not debug-only)
- Accurate error detection and reporting
- Success/failure indicators that match reality

#### Validation Artifacts
- Test scenarios for staging failures
- Error message validation tests
- Pre-commit hook handling tests

## Out of Scope
- ❌ **Implementation Details**: Specific code refactoring approaches
- ❌ **Technology Decisions**: Whether to keep using ace-git-diff dependency
- ❌ **Performance Optimization**: Staging speed improvements
- ❌ **Future Enhancements**: Interactive staging, partial commits, commit templates

## References

- Investigation idea: `.ace-taskflow/v.0.9.0/ideas/done/20251002-222133-investigate-the-issue-with-ace-git-commit.md`
- Previous retrospective: `.ace-taskflow/v.0.9.0/retros/2025-10-05-ace-git-commit-issues.md`
- Investigation report: Comprehensive analysis of current implementation issues