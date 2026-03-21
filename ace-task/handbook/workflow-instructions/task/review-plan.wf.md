---
doc-type: workflow
purpose: Review implementation plans before execution
ace-docs:
  last-updated: '2026-02-27'
---

# Review Plan Workflow Instruction

## Goal

Critically evaluate an implementation plan for completeness, specificity, and autonomous executability. This workflow acts as the adversarial quality gate between planning and execution. A plan that passes this review should be executable by an agent without asking a single clarifying question.

## When to Use

- As Phase 2 (self-critique) in a plan generation step
- After any implementation plan is produced, before handing off to execution
- When reviewing plan quality in ace-assign pipeline steps

## Evaluation Dimensions

Evaluate the plan against these six dimensions. Score each as **PASS**, **WEAK**, or **FAIL**.

### 1. Decision Completeness

Every decision point must be resolved. No "TBD", "consider X or Y", "to be determined", or "depends on" left unresolved.

**PASS:** All decisions made with clear rationale.
**WEAK:** Minor open questions that won't block execution.
**FAIL:** Unresolved choices that would force the executor to guess.

**Check for:**
- Ambiguous phrasing: "could use X or Y", "might need", "possibly"
- Deferred decisions: "TBD", "decide later", "to be determined"
- Missing rationale for key choices

### 2. Behavioral Spec Coverage

Every section of the behavioral specification must map to at least one plan element. No spec requirement silently dropped.

**PASS:** Every spec section (Success Criteria, Interface Contract, Edge Cases, Error Handling) has corresponding plan items.
**WEAK:** Minor spec details not explicitly addressed but inferable.
**FAIL:** Entire spec sections with no corresponding plan items.

**Check for:**
- Success criteria without implementation steps
- Interface contract details missing from file modification plan
- Error handling requirements with no planned implementation
- Edge cases mentioned in spec but absent from test planning

### 3. File Modification Exhaustiveness

Every file to be created, modified, or deleted must be listed. Cross-package impacts identified.

**PASS:** Complete file manifest with specific changes per file, cross-package references audited.
**WEAK:** Core files listed but minor ancillary files missing (docs, configs).
**FAIL:** Vague references like "update related files" or missing entire categories of changes.

**Check for:**
- "Update related files" or "modify as needed" without specifics
- Missing test files for new implementations
- Cross-package consumers of changed interfaces not listed
- Renamed/moved files without import/require update plan

### 4. Test Strategy Adequacy

Test scenarios must be named and specific, not generic placeholders.

**PASS:** Named test scenarios with concrete inputs, expected outputs, and edge cases.
**WEAK:** Test categories identified but individual scenarios lack specificity.
**FAIL:** Generic statements like "write tests for X" or "add appropriate tests".

**Check for:**
- "Add tests" without specifying what scenarios
- Missing edge case scenarios for boundary conditions
- No error/failure path test scenarios
- Test file locations not specified

### 5. Risk Assessment Honesty

Risks must be specific to this plan, not generic software warnings.

**PASS:** Risks tied to specific plan decisions with concrete mitigation steps.
**WEAK:** Risks identified but mitigations are vague.
**FAIL:** Generic risks ("performance could be affected") or no risks identified for a non-trivial plan.

**Check for:**
- Boilerplate risks copied from templates
- Mitigations that just restate the risk ("mitigate by being careful")
- Missing risks for cross-package changes, data migrations, or API changes

### 6. Autonomous Executability

Could an agent execute this plan without asking a single clarifying question?

**PASS:** Every step is unambiguous with clear inputs, actions, and verification criteria.
**WEAK:** Most steps clear but 1-2 require minor interpretation.
**FAIL:** Multiple steps require judgment calls or clarification to proceed.

**Check for:**
- Steps that assume knowledge not present in the plan
- Missing ordering or dependency information between steps
- Verification criteria that require subjective judgment
- References to external resources not included in the plan

## Output Format

Produce the critique in this structure:

```markdown
## Plan Critique

**Verdict:** READY | NEEDS WORK | INSUFFICIENT

### Dimension Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| Decision Completeness | PASS/WEAK/FAIL | One-line finding |
| Behavioral Spec Coverage | PASS/WEAK/FAIL | One-line finding |
| File Modification Exhaustiveness | PASS/WEAK/FAIL | One-line finding |
| Test Strategy Adequacy | PASS/WEAK/FAIL | One-line finding |
| Risk Assessment Honesty | PASS/WEAK/FAIL | One-line finding |
| Autonomous Executability | PASS/WEAK/FAIL | One-line finding |

### Critical Findings
- [List specific issues that MUST be fixed before execution]

### Strengths
- [List what the plan does well]
```

## Verdict Criteria

- **READY:** No FAIL scores, at most one WEAK score
- **NEEDS WORK:** No more than two FAIL scores, or three+ WEAK scores
- **INSUFFICIENT:** Three or more FAIL scores

## Review Principles

- Be adversarial. Your job is to find what's missing, not to praise what's present.
- Cite specific plan sections when noting issues.
- A vague plan produces vague execution. Demand specificity.
- "Good enough" plans produce mediocre implementations. Push for completeness.
