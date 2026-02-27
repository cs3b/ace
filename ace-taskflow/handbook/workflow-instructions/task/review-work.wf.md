---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2026-02-27'
---

# Review Work Workflow Instruction

## Goal

Critically evaluate work execution output for completeness, credibility, and delivery readiness. This workflow acts as the adversarial quality gate between execution and delivery. Work that passes this review should be complete enough to serve as a PR description or implementation report.

## When to Use

- As Phase 2 (self-critique) in a work execution step
- After any implementation report is produced, before declaring work complete
- When reviewing execution quality in ace-assign pipeline phases

## Evaluation Dimensions

Evaluate the work output against these six dimensions. Score each as **PASS**, **WEAK**, or **FAIL**.

### 1. Plan Adherence

Every item from the implementation plan must be addressed in the execution output. No silent drops.

**PASS:** Every plan item has a corresponding execution result — completed, modified with rationale, or explicitly deferred.
**WEAK:** Most plan items addressed but 1-2 minor items not mentioned.
**FAIL:** Plan items silently dropped with no explanation.

**Check for:**
- Plan items with no corresponding execution mention
- Scope changes without documented rationale
- New work introduced that wasn't in the plan (scope creep)
- Deferred items without justification

### 2. Change Credibility

Every claimed change must reference specific file paths, use valid code patterns, and match the project's actual structure.

**PASS:** All changes reference real file paths, use correct syntax, and match project conventions.
**WEAK:** Most changes are specific but some lack file paths or use approximate descriptions.
**FAIL:** Vague claims like "updated the module" or references to non-existent patterns.

**Check for:**
- Changes described without file paths
- Code snippets that don't match the project's language or framework conventions
- References to files or modules that don't exist in the project
- Descriptions too vague to verify ("improved error handling")

### 3. Test Coverage Verification

Tests must include concrete assertions and cover edge cases, not just happy paths.

**PASS:** Test scenarios named with specific inputs, expected outputs, and edge case coverage.
**WEAK:** Tests cover happy paths but edge cases are thin or unspecified.
**FAIL:** Generic "tests added" claims or no test evidence for code changes.

**Check for:**
- "Tests pass" without listing what was tested
- Missing edge case coverage for boundary conditions
- No error path testing
- Test file paths not specified

### 4. Convention Compliance

Naming, style, error messages, and patterns must match established project conventions.

**PASS:** All changes follow project naming patterns, code style, and error message conventions.
**WEAK:** Minor deviations that don't affect functionality.
**FAIL:** Systematic convention violations or introduction of inconsistent patterns.

**Check for:**
- Naming that breaks established conventions (snake_case vs camelCase, prefixes, etc.)
- Error messages that don't follow project patterns
- File placement that violates project structure
- New patterns introduced without justification when existing patterns apply

### 5. Risk Mitigation Evidence

Risks identified in the plan must have corresponding mitigation actions in the execution.

**PASS:** Each identified risk has a documented mitigation action or resolution.
**WEAK:** Most risks addressed but some mitigations are implicit rather than explicit.
**FAIL:** Risks from the plan ignored in execution, or new risks introduced without mitigation.

**Check for:**
- Plan risks with no corresponding mitigation evidence
- New risks introduced during execution without acknowledgment
- Cross-package impacts not verified
- Breaking changes without backward compatibility consideration

### 6. Delivery Readiness

The execution output must be complete enough that a reviewer can assess the full scope of changes.

**PASS:** Output includes complete change manifest, test results, and remaining work (if any) clearly documented.
**WEAK:** Output covers main changes but missing minor details a reviewer would need.
**FAIL:** Output is incomplete — missing change descriptions, no test evidence, or unclear what was actually done.

**Check for:**
- Missing summary of what changed and why
- No test execution evidence
- Unclear boundary between completed and remaining work
- Missing information a PR reviewer would need

## Output Format

Produce the critique in this structure:

```markdown
## Work Critique

**Verdict:** SHIP IT | NEEDS REVISION | INCOMPLETE

### Dimension Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| Plan Adherence | PASS/WEAK/FAIL | One-line finding |
| Change Credibility | PASS/WEAK/FAIL | One-line finding |
| Test Coverage Verification | PASS/WEAK/FAIL | One-line finding |
| Convention Compliance | PASS/WEAK/FAIL | One-line finding |
| Risk Mitigation Evidence | PASS/WEAK/FAIL | One-line finding |
| Delivery Readiness | PASS/WEAK/FAIL | One-line finding |

### Critical Findings
- [List specific issues that MUST be fixed before delivery]

### Strengths
- [List what the execution does well]
```

## Verdict Criteria

- **SHIP IT:** No FAIL scores, at most one WEAK score
- **NEEDS REVISION:** No more than two FAIL scores, or three+ WEAK scores
- **INCOMPLETE:** Three or more FAIL scores

## Review Principles

- Be adversarial. Your job is to find gaps between the plan and the execution, not to validate effort.
- Compare the plan and execution item-by-item. Every plan item needs a resolution.
- Demand specificity. "Updated the code" is not evidence of a change.
- A shipped report is a commitment. Ensure every claim is verifiable.
