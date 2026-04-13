---
name: bug/analyze
description: Systematically analyze bugs to identify root cause, reproduction status,
  and fix plan
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
argument-hint: ''
estimate: 1-2h
doc-type: workflow
purpose: analyze-bug workflow instruction
ace-docs:
  last-updated: '2026-03-21'
---

# Analyze Bug Workflow Instruction

## Goal

Systematically analyze bug reports to identify root cause, verify reproduction, propose regression tests, and create a structured fix plan. This workflow focuses on analysis and planning - use the fix-bug workflow for execution.

## Prerequisites

- Bug description, error logs, stack traces, or reproduction steps provided
- Access to the codebase where the bug exists
- Development environment set up correctly
- Understanding of the project's testing approach

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

**Before starting bug analysis:**

1. Check recent changes: `git log --oneline -10`
2. Review related code areas mentioned in the bug report
3. Understand testing framework: Check `Gemfile`, `package.json`, or `requirements.txt`
4. For testing guidelines, use `ace-bundle guide://testing-philosophy` or `ace-bundle guide://mocking-patterns`

## When to Use This Workflow

**Use this workflow for:**

- Bug reports with error logs, stack traces, or reproduction steps
- Unexpected behavior in the application
- Regressions after code changes
- Intermittent or race condition issues
- Environment-specific bugs

**NOT for:**

- Test failures (use fix-tests workflow instead)
- Feature development or new requirements
- Performance optimization (unless it's causing bugs)
- Code refactoring without specific bugs

## Process Steps

### 1. Gather Bug Information

**Collect all available bug context:**

- Error messages and stack traces
- Screenshots or screen recordings
- Reproduction steps
- Environment details (OS, browser, versions)
- When the bug started occurring
- Any recent changes that might be related

**If information is missing, ask the user for:**

- Exact error message or unexpected behavior
- Steps to reproduce the issue
- Expected vs actual behavior
- Environment where bug occurs

### 2. Initial Analysis

**Analyze the bug report:**

1. **Categorize the bug type:**
   - Runtime error (null reference, type error, timeout)
   - Logic error (incorrect calculation, wrong flow)
   - Data error (invalid state, corruption)
   - Integration error (API mismatch, protocol issue)
   - Environment error (configuration, dependency)

2. **Identify affected components:**
   ```bash
   # Search for related code based on error message
   ace-search "[error message or key term]"

   # Find files related to the component
   ace-search "[component name]" --file
   ```

3. **Review recent changes to affected areas:**
   ```bash
   # Check recent commits for affected files
   git log --oneline -20 -- path/to/affected/files

   # View specific changes
   git diff HEAD~10 -- path/to/affected/files
   ```

### 3. Reproduction Attempt

**Try to reproduce the bug:**

1. **Set up reproduction environment:**
   - Match reported environment as closely as possible
   - Use same data/inputs from bug report
   - Enable verbose logging if available

2. **Execute reproduction steps:**
   - Follow exact steps from bug report
   - Document any deviations or additional context
   - Capture logs and error output

3. **Record reproduction status:**
   - **Confirmed**: Bug reproduces consistently
   - **Intermittent**: Bug reproduces sometimes (note frequency)
   - **Not reproducible**: Bug does not reproduce (request more context)

**If bug cannot be reproduced:**

- Request additional environment details
- Ask for more specific reproduction steps
- Check if bug is environment-specific
- Look for timing or race conditions

### 4. Root Cause Analysis

**Investigate the root cause:**

1. **Trace the execution path:**
   - Start from the error location
   - Work backward through the call stack
   - Identify where the unexpected behavior originates

2. **Analyze the code:**
   ```bash
   # Read the file where error occurs
   # Read related files for context
   # Search for similar patterns in codebase
   ace-search "[pattern from error]" --content
   ```

3. **Identify contributing factors:**
   - Missing validation or error handling
   - Incorrect assumptions about data
   - Race conditions or timing issues
   - External dependency changes
   - Configuration mismatches

4. **Document the root cause:**
   - Primary cause (the direct source of the bug)
   - Contributing factors (conditions that enable the bug)
   - Impact scope (what else might be affected)

### 5. Propose Regression Tests

**Design tests to catch this bug:**

1. **Unit test for the specific case:**
   - Test the exact scenario that causes the bug
   - Include edge cases revealed by analysis
   - Test error handling paths

2. **Integration test for the flow:**
   - Test the complete workflow where bug manifests
   - Include related components in scope
   - Verify correct behavior end-to-end

3. **Test considerations:**
   - Use project's existing test patterns
   - Follow framework conventions (RSpec, Jest, pytest, etc.)
   - Consider existing test coverage in the area

**Example test proposal format:**

```markdown
### Proposed Tests

**Unit Test: [test name]**
- Location: test/[layer]/[component]_test.rb
- Purpose: Verify [specific behavior] handles [edge case]
- Scenario: When [condition], expect [result]

**Feature Test: [test name]**
- Location: test/feat/[flow]_test.rb
- Purpose: Verify [workflow] completes correctly
- Scenario: Given [setup], when [action], then [verification]
```

### 6. Create Fix Plan

**Document the fix strategy:**

1. **Files to modify:**
   - List each file that needs changes
   - Describe the type of change for each

2. **Fix approach:**
   - Describe the technical solution
   - Explain why this approach was chosen
   - Note any alternative approaches considered

3. **Risks and side effects:**
   - What else might be affected by the fix
   - Potential regressions to watch for
   - Backward compatibility considerations

4. **Rollback plan:**
   - How to revert if issues arise
   - What to check after reverting

### 7. Save Analysis Results

**Cache the analysis for fix-bug workflow:**

Create the cache directory and save analysis output:

```bash
# Create session directory
mkdir -p .ace-local/task/bug-analysis/{session}
```

```yaml
# .ace-local/task/bug-analysis/{session}/analysis.yml
root_cause: "Description of root cause"
repro_status: confirmed | not_reproducible | intermittent
affected_files:
  - path: path/to/file.rb
    change_summary: "Description of what change is needed"
proposed_tests:
  - description: "Test case description"
    file: test/path_test.rb
    type: unit | integration
fix_plan_id: "session-timestamp"
risks:
  - "Potential side effect description"
rollback_plan: "How to revert if issues arise"
```

## Bug Type Decision Tree

**Error Type → Investigation Focus:**

- **NullReferenceError / nil** → Check data flow, missing validation
- **TypeError / ArgumentError** → Check type conversions, API contracts
- **Timeout / Deadlock** → Check loops, async operations, resource locks
- **Permission / Access Error** → Check authentication, authorization, file permissions
- **Network / API Error** → Check connectivity, API changes, error handling
- **Data Corruption** → Check concurrent access, transaction handling
- **Environment Error** → Check configuration, dependencies, versions

## Common Bug Patterns

### 1. Nil/Null Reference Bugs

**Symptoms**: NoMethodError, NullPointerException, undefined is not a function
**Investigation**:

- Trace where the nil value originates
- Check if data is optional but treated as required
- Look for missing initialization or loading

**Common fixes**:

- Add nil checks with early returns
- Use safe navigation operators
- Validate input at boundaries

### 2. Race Condition Bugs

**Symptoms**: Intermittent failures, order-dependent results
**Investigation**:

- Identify shared mutable state
- Check async operation sequencing
- Look for missing synchronization

**Common fixes**:

- Add proper locking/synchronization
- Use immutable data structures
- Redesign to avoid shared state

### 3. State Management Bugs

**Symptoms**: Incorrect values, stale data, unexpected state
**Investigation**:

- Map state transitions
- Check update propagation
- Look for side effects

**Common fixes**:

- Centralize state management
- Add state validation
- Implement proper cleanup

### 4. Integration Bugs

**Symptoms**: API errors, protocol mismatches, format issues
**Investigation**:

- Compare expected vs actual API behavior
- Check for version mismatches
- Review error handling

**Common fixes**:

- Update API contracts
- Add compatibility layers
- Improve error handling

## Output / Success Criteria

The analysis is complete when you have:

- [ ] **Root Cause Identified**: Clear explanation of why the bug occurs
- [ ] **Reproduction Status**: Confirmed, intermittent, or not reproducible with evidence
- [ ] **Affected Files Listed**: All files that may need changes
- [ ] **Tests Proposed**: Specific test cases that would catch this regression
- [ ] **Fix Plan Created**: Step-by-step plan for implementing the fix
- [ ] **Risks Documented**: Potential side effects and rollback strategy
- [ ] **Analysis Cached**: Results saved for fix-bug workflow

## Analysis Report Template

Present the analysis to the user in this format:

```markdown
## Bug Analysis Report

### Summary
[One-sentence description of the bug and root cause]

### Reproduction Status
**Status**: [Confirmed | Intermittent | Not Reproducible]
**Evidence**: [Description of reproduction attempt]

### Root Cause
[Detailed explanation of why the bug occurs]

**Primary Cause**: [Direct source of the bug]
**Contributing Factors**: [Conditions that enable the bug]

### Affected Files
- `path/to/file1.rb` - [Type of change needed]
- `path/to/file2.rb` - [Type of change needed]

### Proposed Tests
1. **[Test Name]** (unit)
   - File: `test/path_test.rb`
   - Purpose: [What it validates]

2. **[Test Name]** (integration)
   - File: `test/feat/flow_test.rb`
   - Purpose: [What it validates]

### Fix Plan
1. [Step 1 description]
2. [Step 2 description]
3. [Step 3 description]

### Risks
- [Risk 1]
- [Risk 2]

### Rollback Plan
[How to revert if issues arise]

---
*Run `ace-bundle wfi://bug/fix` to execute this fix plan*
```

## Usage Example

> "I'm getting a NoMethodError on line 45 of user_service.rb when trying to fetch user preferences. Here's the stack trace: [stack trace]. It happens when the user hasn't set any preferences yet."

**Response Process:**

1. Gather context from the error message and stack trace
2. Read the affected file and understand the code
3. Identify that nil preferences are not handled
4. Propose a nil check fix and a test case
5. Document the analysis and fix plan
6. Cache results for fix-bug workflow

---

This workflow provides systematic bug analysis that ensures proper investigation, clear documentation, and actionable fix plans.

<documents>
<template id="analysis-report">
## Bug Analysis Report

### Summary
[One-sentence description of the bug and root cause]

### Reproduction Status
**Status**: [Confirmed | Intermittent | Not Reproducible]
**Evidence**: [Description of reproduction attempt]

### Root Cause
[Detailed explanation of why the bug occurs]

**Primary Cause**: [Direct source of the bug]
**Contributing Factors**: [Conditions that enable the bug]

### Affected Files
- `path/to/file1.rb` - [Type of change needed]
- `path/to/file2.rb` - [Type of change needed]

### Proposed Tests
1. **[Test Name]** (unit)
   - File: `test/path_test.rb`
   - Purpose: [What it validates]

2. **[Test Name]** (integration)
   - File: `test/feat/flow_test.rb`
   - Purpose: [What it validates]

### Fix Plan
1. [Step 1 description]
2. [Step 2 description]
3. [Step 3 description]

### Risks
- [Risk 1]
- [Risk 2]

### Rollback Plan
[How to revert if issues arise]

---
*Run `ace-bundle wfi://bug/fix` to execute this fix plan*
</template>

<template id="analysis-yml">
# .ace-local/task/bug-analysis/{session}/analysis.yml
root_cause: "Description of root cause"
repro_status: confirmed | not_reproducible | intermittent
affected_files:
  - path: path/to/file.rb
    change_summary: "Description of what change is needed"
proposed_tests:
  - description: "Test case description"
    file: test/path_test.rb
    type: unit | integration
fix_plan_id: "session-timestamp"
risks:
  - "Potential side effect description"
rollback_plan: "How to revert if issues arise"
</template>
</documents>
