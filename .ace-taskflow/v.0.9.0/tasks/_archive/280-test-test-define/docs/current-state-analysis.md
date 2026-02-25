# Current State Analysis: E2E Test Scenarios

## Context

Inventory and gap analysis of all 33 existing E2E scenarios as of 2026-02-24 (post-280.01 pilot consolidation).

## Scenario Inventory

### ace-assign (9 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-ASSIGN-001 | Workflow Lifecycle | high | standard | Core workflow, good smoke candidate |
| TS-ASSIGN-002 | — | medium | standard | |
| TS-ASSIGN-003a | — | medium | standard | |
| TS-ASSIGN-003b | — | medium | standard | |
| TS-ASSIGN-003c | — | medium | standard | |
| TS-ASSIGN-003d | — | medium | standard | |
| TS-ASSIGN-004 | — | medium | standard | |
| TS-ASSIGN-005 | — | medium | deep | |
| TS-ASSIGN-006 | — | medium | deep | |

### ace-b36ts (1 scenario)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-B36TS-001 | Goal-mode pilot | medium | smoke | Consolidated from 4 procedural scenarios |

### ace-bundle (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-BUNDLE-001 | — | high | smoke | Core bundle resolution |
| TS-BUNDLE-002 | — | medium | standard | |
| TS-BUNDLE-003 | — | medium | standard | |

### ace-git-commit (3 scenarios)
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

### ace-support-nav (3 scenarios)
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

### ace-prompt-prep (1 scenario)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-PREP-001 | — | medium | smoke | Simple prompt preparation |

### ace-review (3 scenarios)
| ID | Title | Priority | Cost-Tier | Notes |
|----|-------|----------|-----------|-------|
| TS-REVIEW-001 | — | high | standard | Core review flow |
| TS-REVIEW-002 | — | medium | standard | |
| TS-REVIEW-005 | — | medium | deep | |

### ace-git-secrets (3 scenarios)
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
| Total scenarios | 33 |
| Packages covered | 11 |
| High priority | ~6 |
| Medium priority | ~27 |
| Low priority | ~0 |
| Existing cost-tier field | Varies (some have it, some don't) |
| Existing tags field | 1 (pilot only) |

## Gaps Identified

### Minimal Tag Infrastructure
- Only one scenario currently has a `tags` field (b36ts pilot)
- No CLI option for tag-based filtering
- Cannot run "just smoke tests" or "just lint-related tests"

### No Standard Grouping
- Priority and cost-tier exist but are inconsistently applied outside the pilot
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
- Some packages have thin coverage (ace-prompt-prep: 1 scenario)
- No cross-package integration scenarios
- Error recovery paths under-tested

## Recommendations

1. **Phase 1** (280.02): Research and vision alignment — define principles and tier semantics
2. **Phase 2** (280.03): Add scenario-level tag infrastructure — low risk, high value
3. **Phase 3** (280.04): Classify existing scenarios with tags — immediate utility
4. **Phase 4** (280.05): Convert selected TCs to goal-mode — prove the pattern
5. **Phase 5** (280.06): Verifier pattern — highest complexity, optional for initial release

## Validation Commands Used

```bash
# Total scenarios
find . -path '*/test/e2e/*/scenario.yml' | wc -l

# Per-package distribution
find . -path '*/test/e2e/*/scenario.yml' | sed 's#^./##' | cut -d/ -f1 | sort | uniq -c

# Current goal/tag baseline
rg -n '^tags:|^mode:' */test/e2e/*/scenario.yml
```
