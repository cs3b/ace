---
doc-type: template
title: "Agent Experience Report: {test-id}"
purpose: Documentation for ace-test-runner-e2e/handbook/templates/agent-experience-report.template.md
ace-docs:
  last-updated: 2026-02-14
  last-checked: 2026-03-21
---

# Agent Experience Report: {test-id}

## Summary

{Brief 2-3 sentence summary of the test execution experience. Note overall friction level: smooth, minor issues, significant friction, or blocking issues. If no friction was encountered, state "No significant friction encountered" and briefly note what worked well.}

## Friction Points

| Severity | Category | Issue | Suggested Fix |
|----------|----------|-------|---------------|
| high/medium/low | docs/tool/cli | {Brief description} | {Actionable fix} |

### Documentation Gaps

{List any documentation that was missing, unclear, incomplete, or outdated. Include specific files/sections where improvements would help.}

- {Documentation gap 1}
- {Documentation gap 2}

### Tool Behavior Issues

{Describe any unexpected tool behavior, confusing error messages, or surprising results. Include the command and what was unexpected.}

- {Tool issue 1}
- {Tool issue 2}

### API/CLI Friction

{Note any API or CLI friction: inconsistent flags, missing options, awkward workflows, or verbose output.}

- {CLI friction 1}
- {CLI friction 2}

## Root Cause Analysis

{For any failures or significant friction, analyze WHY the issue occurred, not just WHAT happened. Consider: missing validation, unclear error messages, documentation gaps, design decisions, edge cases.}

### {Issue 1 Title}

**What happened:** {Description}
**Why it happened:** {Root cause analysis}
**Impact:** {How it affected test execution}

## Improvement Suggestions

{Concrete, actionable suggestions for improving the developer/agent experience. Prioritize by impact.}

### High Priority

- [ ] {Suggestion 1}
- [ ] {Suggestion 2}

### Medium Priority

- [ ] {Suggestion 3}

### Low Priority

- [ ] {Suggestion 4}

## Workarounds Used

{Document any workarounds the agent had to employ to complete the test. These indicate areas needing improvement.}

- **Issue:** {What required a workaround}
  **Workaround:** {What was done instead}

## Positive Observations

{Note what worked well, was well-documented, or provided good DX. This helps identify patterns to replicate.}

- {Positive observation 1}
- {Positive observation 2}

## Recommendations for Test Scenario

{Suggestions for improving this specific test scenario based on execution experience.}

- {Recommendation 1}
- {Recommendation 2}