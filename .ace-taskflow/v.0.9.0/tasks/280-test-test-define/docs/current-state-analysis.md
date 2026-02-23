# Current State Analysis: E2E Test Scenarios

## Context

Inventory and gap analysis of all 36 existing E2E scenarios as of 2026-02-23.

## Scenario Inventory

### ace-assign (6 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-ASSIGN-001 | Workflow Lifecycle | high | standard | Core workflow, good smoke candidate |
| TS-ASSIGN-002 | — | medium | standard | |
| TS-ASSIGN-003 | — | medium | standard | |
| TS-ASSIGN-004 | — | medium | standard | |
| TS-ASSIGN-005 | — | medium | deep | |
| TS-ASSIGN-006 | — | medium | deep | |

### ace-b36ts (4 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-B36TS-001 | — | medium | smoke | Simple encode/decode, fast |
| TS-B36TS-002 | — | medium | smoke | |
| TS-B36TS-003 | — | medium | smoke | |
| TS-B36TS-004 | — | medium | smoke | |

### ace-bundle (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-BUNDLE-001 | — | high | smoke | Core bundle resolution |
| TS-BUNDLE-002 | — | medium | standard | |
| TS-BUNDLE-003 | — | medium | standard | |

### ace-commit (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-COMMIT-001 | — | high | standard | Requires LLM call |
| TS-COMMIT-002 | — | medium | standard | |
| TS-COMMIT-004a | — | medium | standard | |

### ace-lint (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-LINT-001 | Core Lint Pipeline | high | smoke | Well-structured, good example |
| TS-LINT-002 | — | medium | standard | |
| TS-LINT-003 | — | medium | standard | |

### ace-nav (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-NAV-001 | — | medium | smoke | Simple navigation |
| TS-NAV-002 | — | medium | standard | |
| TS-NAV-003 | — | medium | standard | |

### ace-overseer (2 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-OVERSEER-001 | — | medium | standard | Worktree orchestration |
| TS-OVERSEER-002 | — | medium | deep | Complex multi-worktree |

### ace-prep (1 scenario)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-PREP-001 | — | medium | smoke | Simple prompt preparation |

### ace-review (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-REVIEW-001 | — | high | standard | Core review flow |
| TS-REVIEW-002 | — | medium | standard | |
| TS-REVIEW-005 | — | medium | deep | |

### ace-secrets (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-SECRETS-001 | — | high | smoke | Basic secret detection |
| TS-SECRETS-002 | — | medium | standard | |
| TS-SECRETS-003 | — | medium | standard | |

### ace-git-worktree (2 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-WORKTREE-001 | Basic Lifecycle | medium | standard | Create/remove flow |
| TS-WORKTREE-002 | — | medium | deep | Complex lifecycle |

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total scenarios | 36 |
| Packages covered | 11 |
| High priority | ~6 |
| Medium priority | ~28 |
| Low priority | ~2 |
| Existing cost-tier field | Varies (some have it, some don't) |
| Existing tags field | 0 (none) |

## Gaps Identified

### No Tag Infrastructure
- Zero scenarios have a `tags` field
- No CLI option for tag-based filtering
- Cannot run "just smoke tests" or "just lint-related tests"

### No Standard Grouping
- Priority and cost-tier exist but are inconsistently applied
- No formal smoke/happy-path/deep classification
- No use-case tags for workflow-based selection

### Procedural-Only Test Cases
- All TCs use step-by-step procedural format
- No goal-based TCs that test agent problem-solving
- Agent adaptability not measured

### Single-Agent Execution Only
- Executor self-reports results
- No independent verification
- Confirmation bias risk in agent self-assessment

### Missing Scenarios
- Some packages have thin coverage (ace-prep: 1 scenario)
- No cross-package integration scenarios
- Error recovery paths under-tested

## Recommendations

1. **Phase 1** (280.02): Add tag infrastructure — low risk, high value
2. **Phase 2** (280.03): Classify existing scenarios — immediate utility
3. **Phase 3** (280.04): Convert 3 TCs to goal-mode — prove the pattern
4. **Phase 4** (280.05): Verifier pattern — highest complexity, optional for initial release
