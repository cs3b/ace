# Supplementary: Proposed Files to Update or Create

Date: 2026-01-31
Purpose: Track documentation / workflow changes suggested by the research.

## Updates (Existing Files)
- ace-test/handbook/guides/testing-philosophy.g.md
  - Add explicit mapping rules for behavior -> test layer, and clarify "real IO only in E2E" boundary with examples.
  - Add 100ms performance rule and zombie mock detection guidance.

- ace-test/handbook/guides/test-performance.g.md
  - Add outer-boundary stubbing guidance, cache pre-warm pattern, and test-size budget table tied to ACE tests.
  - Add zombie mock detection and composite helper guidance.

- ace-test/handbook/guides/mocking-patterns.g.md
  - Add "stub availability/guard methods" and "avoid hidden subprocess" examples; add cache-safe stub helper pattern.
  - Add contract testing and mock drift detection guidance.

- ace-test-e2e-runner/handbook/guides/e2e-testing.g.md
  - Add explicit safe third-party API guidance (test tokens, limited scopes, cleanup) and sandbox project setup checklist.

## New Guides (Suggested)
- ace-test/handbook/guides/test-responsibility-map.g.md
  - A coverage matrix template: behavior -> layer -> rationale -> source of truth.

- ace-test/handbook/guides/test-review-checklist.g.md
  - Short reviewer checklist for: behavior focus, mock realism, IO boundaries, redundancy, perf budgets.

- ace-test/handbook/guides/test-layer-decision.g.md
  - Decision matrix for layer selection (unit vs integration vs E2E).

- ace-test/handbook/guides/test-suite-health.g.md
  - Suite health metrics, cadence, and targets (flake rate, DRE, MTDetect).

- ace-test/handbook/guides/test-mocking-patterns.g.md
  - Advanced patterns: zombie mocks, composite helpers, contract testing.

## New Workflows (Suggested)
- ace-test/handbook/workflow-instructions/test-plan.wf.md
  - Planner -> writer -> verifier flow; outputs a test responsibility map + mock plan.
  - Consider renaming to `plan-tests.wf.md` for alignment with other drafts.

- ace-test/handbook/workflow-instructions/test-performance-audit.wf.md
  - Run `ace-test --profile 10`, capture top offenders, and create follow-up tasks.
  - Enforce 100ms rule for unit/integration tests.

- ace-test/handbook/workflow-instructions/verify-test-suite.wf.md
  - Enforce performance budgets and track suite health.

- ace-test/handbook/workflow-instructions/optimize-tests.wf.md
  - Refactor slow tests using boundary stubs, cache pre-warm, and E2E migration.

- ace-test-e2e-runner/handbook/workflow-instructions/e2e-sandbox-setup.wf.md
  - Standardized safe E2E sandbox process: temp project creation, token scoping, cleanup, and failure triage.

## New Skills (Suggested)
- .claude/skills/ace_test-plan/SKILL.md
- .claude/skills/ace_test-review/SKILL.md
- .claude/skills/ace_test-performance-audit/SKILL.md
- .claude/skills/ace_e2e-sandbox-setup/SKILL.md
- .claude/skills/ace_verify-test-suite/SKILL.md
- .claude/skills/ace_optimize-tests/SKILL.md


## Drafts Created (Supplementary Only)

- Proposed workflows:
  - proposed-workflows/ace-test/handbook/workflow-instructions/test-plan.wf.md
  - proposed-workflows/ace-test/handbook/workflow-instructions/test-performance-audit.wf.md
  - proposed-workflows/ace-test/handbook/workflow-instructions/test-review.wf.md
  - proposed-workflows/ace-test/handbook/workflow-instructions/verify-test-suite.wf.md
  - proposed-workflows/ace-test/handbook/workflow-instructions/optimize-tests.wf.md
  - proposed-workflows/ace-test-e2e-runner/handbook/workflow-instructions/e2e-sandbox-setup.wf.md

- Proposed templates:
  - proposed-templates/ace-test/handbook/templates/test-responsibility-map.template.md
  - proposed-templates/ace-test/handbook/templates/test-performance-audit.template.md
  - proposed-templates/ace-test/handbook/templates/test-review-checklist.template.md
  - proposed-templates/ace-test/handbook/templates/test-suite-health.template.md
  - proposed-templates/ace-test-e2e-runner/handbook/templates/e2e-sandbox-checklist.template.md

- Proposed skills:
  - proposed-skills/.claude/skills/ace_test-plan/SKILL.md
  - proposed-skills/.claude/skills/ace_test-performance-audit/SKILL.md
  - proposed-skills/.claude/skills/ace_test-review/SKILL.md
  - proposed-skills/.claude/skills/ace_e2e-sandbox-setup/SKILL.md
  - proposed-skills/.claude/skills/ace_verify-test-suite/SKILL.md
  - proposed-skills/.claude/skills/ace_optimize-tests/SKILL.md
