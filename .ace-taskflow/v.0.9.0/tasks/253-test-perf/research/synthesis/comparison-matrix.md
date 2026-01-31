# Research Comparison Matrix

## Overview

| Field | Value |
|-------|-------|
| **Task** | 253 - Test Performance Strategy |
| **Date** | 2026-01-31 |
| **Research Folder** | .ace-taskflow/v.0.9.0/tasks/253-test-perf/research |
| **Agents** | 8oup7s (Claude Opus 4.5), 8oup93 (Gemini), 8oupdg (Codex) |

## Quality Rating Scale

| Rating | Meaning |
|--------|---------|
| 5 | Comprehensive - thorough, well-structured, actionable |
| 4 | Good - covers main points with useful detail |
| 3 | Adequate - covers basics, some gaps |
| 2 | Basic - incomplete or surface-level |
| 1 | Minimal - significant gaps or issues |

---

## Artifact Inventory

### Reports

| Artifact | 8oup7s (Claude) | 8oup93 (Gemini) | 8oupdg (Codex) | Best | Action |
|----------|-----------------|-----------------|----------------|------|--------|
| Main report | 5 (476 lines, comprehensive) | 4 (94 lines, focused) | 4 (87 lines, synthesis focus) | 8oup7s | Use as base, merge unique insights |

### Guides

| Artifact | 8oup7s (Claude) | 8oup93 (Gemini) | 8oupdg (Codex) | Best | Action |
|----------|-----------------|-----------------|----------------|------|--------|
| test-layer-decision.g.md | 5 | — | — | 8oup7s | Use |
| test-mocking-patterns.g.md | 5 | — | — | 8oup7s | Use |
| test-suite-health.g.md | 5 | — | — | 8oup7s | Use |
| test-responsibility-map.g.md | 5 | 3 | — | 8oup7s | Use 8oup7s, note 8oup93 additions |
| test-review-checklist.g.md | 4 | — | — | 8oup7s | Use |
| testing-strategy.g.md | — | 4 | — | 8oup93 | Use (fast/slow loop focus) |
| SUMMARY.md | 4 | — | — | 8oup7s | Use as index |

### Workflows

| Artifact | 8oup7s (Claude) | 8oup93 (Gemini) | 8oupdg (Codex) | Best | Action |
|----------|-----------------|-----------------|----------------|------|--------|
| plan-tests.wf.md | 5 | — | 4 (as test-plan.wf.md) | 8oup7s | Use 8oup7s |
| verify-test-suite.wf.md | 5 | 4 | 4 | 8oup7s | Merge 8oup93's zombie mock detection |
| optimize-tests.wf.md | 5 | — | 4 | 8oup7s | Use |
| e2e-sandbox-setup.wf.md | 5 | — | 4 | 8oup7s | Use |
| create-test-cases.wf.md | — | 5 | — | 8oup93 | Use (comprehensive) |
| test-performance-audit.wf.md | — | — | 3 | 8oupdg | Use as starting point |
| test-review.wf.md | — | — | 3 | 8oupdg | Use as starting point |

### Templates

| Artifact | 8oup7s (Claude) | 8oup93 (Gemini) | 8oupdg (Codex) | Best | Action |
|----------|-----------------|-----------------|----------------|------|--------|
| test-responsibility-map.template.md | 4 | — | 3 | 8oup7s | Use |
| test-performance-audit.template.md | 4 | — | 3 | 8oup7s | Use |
| test-review-checklist.template.md | 4 | — | 3 | 8oup7s | Use |
| e2e-sandbox-checklist.template.md | 4 | — | 3 | 8oup7s | Use |

### Skills

| Artifact | 8oup7s (Claude) | 8oup93 (Gemini) | 8oupdg (Codex) | Best | Action |
|----------|-----------------|-----------------|----------------|------|--------|
| ace_plan-tests | Proposed | — | 4 (as ace_test-plan) | 8oupdg | Use, rename to plan-tests |
| ace_verify-test-suite | Proposed | Proposed | 4 | 8oupdg | Use |
| ace_optimize-tests | Proposed | — | 4 | 8oupdg | Use |
| ace_test-review | Proposed | — | 3 | 8oupdg | Use |
| ace_e2e-sandbox-setup | Proposed | — | 3 | 8oupdg | Use |
| ace_test-performance-audit | Proposed | — | 3 | 8oupdg | Use |

---

## Comparison by Type

### Reports Comparison

#### Coverage Analysis

| Topic | 8oup7s (Claude) | 8oup93 (Gemini) | 8oupdg (Codex) | Notes |
|-------|-----------------|-----------------|----------------|-------|
| PR #187 Analysis | ✓ detailed (5 packages) | ✓ brief | ✓ brief | 8oup7s most thorough |
| 100ms Rule | ✓ detailed with thresholds | ✓ as bug | ✓ as budget | All agree, 8oup7s most detailed |
| Subprocess Stubbing | ✓ detailed with code | ✓ "Stub the Boundary" | ✓ outer-boundary | All covered similarly |
| Zombie Mocks | ✓ case study | ✓ detection | — | 8oup7s + 8oup93 aligned |
| Cache Architecture | ✓ detailed (2 caches) | — | ✓ cache-driven flakiness | 8oup7s detailed, 8oupdg mentioned |
| Test Pyramid | ✓ industry research | ✓ Fast/Slow Loop | ✓ external research | All covered |
| Behavior vs Implementation | ✓ anti-pattern examples | ✓ "Testing the Mock" | ✓ state vs interaction | 8oup7s + 8oup93 complementary |
| Contract Testing | ✓ | — | ✓ | 8oup7s detailed |
| Test Responsibility Map | ✓ template + rules | ✓ "lowest layer" rule | ✓ matrix concept | All agree, 8oup7s most complete |
| Planner/Writer Roles | ✓ | ✓ (introduced) | — | 8oup93 originated, 8oup7s expanded |
| Composite Helpers | ✓ detailed with code | ✓ mentioned | — | 8oup7s most detailed |
| E2E Test Structure | ✓ with directory layout | — | ✓ migration pattern | 8oup7s detailed |
| Automation (CI gates) | ✓ YAML examples | ✓ mentioned | ✓ cadence | 8oup7s most actionable |

#### Depth Assessment

- **8oup7s (Claude)**: Most comprehensive at 476 lines. Covers both PR #187 analysis and industry research. Includes detailed code examples, case studies (ace-docs zombie mock), and actionable templates. Self-enhanced with cross-report synthesis.
- **8oup93 (Gemini)**: Focused at 94 lines. Introduced the "Fast Loop vs Slow Loop" framing and the Planner/Writer role separation. Integrated findings from other reports (8oup7s, 8oupdg).
- **8oupdg (Codex)**: Synthesis-focused at 87 lines. Strong on internal repo evidence and practical coverage model. Less detailed on implementation patterns.

### Guides Comparison

| Guide | Comparison Notes | Selected Source | Rationale |
|-------|-----------------|-----------------|-----------|
| test-layer-decision.g.md | Only 8oup7s produced | 8oup7s | Complete with decision matrix |
| test-mocking-patterns.g.md | Only 8oup7s produced | 8oup7s | Detailed patterns + code examples |
| test-suite-health.g.md | Only 8oup7s produced | 8oup7s | Metrics and targets defined |
| test-responsibility-map.g.md | 8oup7s: detailed; 8oup93: brief | 8oup7s | More complete |
| test-review-checklist.g.md | Only 8oup7s produced | 8oup7s | Practical checklist format |
| testing-strategy.g.md | Only 8oup93 produced | 8oup93 | Fast/Slow loop focus |
| SUMMARY.md | Only 8oup7s produced | 8oup7s | Navigation index |

### Workflows Comparison

| Workflow | Comparison Notes | Selected Source | Rationale |
|----------|-----------------|-----------------|-----------|
| plan-tests.wf.md | 8oup7s: comprehensive phases; 8oupdg: shorter | 8oup7s | Better Planner/Writer structure |
| verify-test-suite.wf.md | 8oup7s: complete; 8oup93: zombie focus; 8oupdg: basic | 8oup7s + 8oup93 | Merge zombie detection from 8oup93 |
| optimize-tests.wf.md | 8oup7s: comprehensive; 8oupdg: basic | 8oup7s | More actionable |
| e2e-sandbox-setup.wf.md | 8oup7s: complete; 8oupdg: basic | 8oup7s | Includes API safety patterns |
| create-test-cases.wf.md | Only 8oup93 produced | 8oup93 | Unique contribution |

---

## Conflict Log

### Conflict #1: Workflow Naming

| Aspect | Description |
|--------|-------------|
| **Topic** | Name for test planning workflow |
| **8oup7s Position** | `plan-tests.wf.md` (imperative verb-first) |
| **8oup93 Position** | — |
| **8oupdg Position** | `test-plan.wf.md` (noun-first) |
| **Research/Verification** | ACE convention uses imperative verb-first (e.g., `create-pr.wf.md`, `commit.wf.md`) |
| **Resolution** | `plan-tests.wf.md` |
| **Rationale** | Follows ACE naming conventions; 8oupdg's updates.md also suggests renaming to match |

### Conflict #2: Performance Threshold Classification

| Aspect | Description |
|--------|-------------|
| **Topic** | How to classify slow tests |
| **8oup7s Position** | Explicit thresholds: <10ms healthy, 10-100ms warning, >100ms bug, >200ms critical |
| **8oup93 Position** | >100ms is a bug (binary) |
| **8oupdg Position** | Time budgets per layer: atoms <10ms, molecules <50ms, organisms <100ms |
| **Research/Verification** | All positions are compatible; 8oupdg's layer-specific budgets add nuance |
| **Resolution** | Adopt 8oupdg's layer-specific budgets within 8oup7s's classification framework |
| **Rationale** | More precise guidance; atoms should be faster than organisms |

### Conflict #3: Skill Naming Convention

| Aspect | Description |
|--------|-------------|
| **Topic** | Skill names for test planning |
| **8oup7s Position** | `/ace:plan-tests` (verb-first) |
| **8oup93 Position** | — |
| **8oupdg Position** | `ace_test-plan` (noun-first) |
| **Research/Verification** | ACE skills use verb-first when action-oriented (e.g., `ace_commit`, `ace_review`) |
| **Resolution** | `ace_plan-tests` (verb-first) |
| **Rationale** | Consistent with ACE skill naming patterns; planning is an action |

---

## Synthesis Decisions

### Report Synthesis

| Decision | Source(s) | Rationale |
|----------|-----------|-----------|
| Use 8oup7s as base structure | 8oup7s | Most comprehensive (476 lines), covers both internal + external research |
| Preserve Fast/Slow Loop framing | 8oup93 | Clear mental model, well-received |
| Add layer-specific budgets | 8oupdg | More precise than single threshold |
| Include Planner/Writer roles | 8oup93 | Novel contribution, useful separation |

### Artifact Synthesis

| Artifact | Decision | Source(s) | Rationale |
|----------|----------|-----------|-----------|
| Guides (6) | Use 8oup7s | 8oup7s | Most complete, well-structured |
| testing-strategy.g.md | Use 8oup93 | 8oup93 | Fast/Slow Loop focus is unique |
| Workflows (5) | Use 8oup7s | 8oup7s | Most actionable |
| create-test-cases.wf.md | Use 8oup93 | 8oup93 | Unique contribution |
| Templates (4) | Use 8oup7s | 8oup7s | Better structure |
| Skills (6) | Use 8oupdg as base | 8oupdg | Only agent with SKILL.md drafts |

---

## Gaps Identified

| Gap | Description | Follow-up Needed |
|-----|-------------|------------------|
| Contract testing implementation | All reports mention it; none provide implementation examples | Create contract testing guide with Pact/VCR examples |
| CI/CD pipeline integration | YAML snippets provided but not tested | Validate in actual .github/workflows |
| Test coverage metrics | Mentioned but no tooling | Evaluate SimpleCov integration for coverage enforcement |
| E2E test scheduling | Not addressed | Consider nightly E2E runs vs per-PR |

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| **Total Artifacts Reviewed** | 35 |
| **Artifacts Merged** | 2 (verify-test-suite.wf.md, performance thresholds) |
| **Artifacts Used As-Is** | 28 |
| **Artifacts Skipped** | 5 (8oupdg duplicates of 8oup7s) |
| **Conflicts Resolved** | 3 |
| **Gaps Identified** | 4 |

---

## Attribution

All synthesis decisions credit original sources:
- 8oup7s (Claude Opus 4.5): 8oup7s-report.md, 8oup7s-supplementary/
- 8oup93 (Gemini): 8oup93-report.md, 8oup93-supplementary/
- 8oupdg (Codex): 8oupdg-report.md, 8oupdg-supplementary/
