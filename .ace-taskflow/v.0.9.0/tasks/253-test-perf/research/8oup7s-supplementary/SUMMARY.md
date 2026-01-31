# ACE Testing Guide Index

Navigation index for all testing guides, workflows, and templates in the 8oup7s research.

## Quick Start

| Need | Guide |
|------|-------|
| Decide where to test | [Test Layer Decision](test-layer-decision.g.md) |
| Plan tests before coding | [Plan Tests Workflow](plan-tests.wf.md) |
| Review test PR | [Test Review Checklist](test-review-checklist.g.md) |
| Audit test health | [Verify Test Suite Workflow](verify-test-suite.wf.md) |
| Fix slow tests | [Optimize Tests Workflow](optimize-tests.wf.md) |

## Guides

### Core Testing Guides

| Guide | Protocol | Description |
|-------|----------|-------------|
| Test Layer Decision | `guide://test-layer-decision` | Unit vs Integration vs E2E decision matrix |
| Test Mocking Patterns | `guide://test-mocking-patterns` | Stubs, zombies, contracts, composite helpers |
| Test Suite Health | `guide://test-suite-health` | Metrics, CI integration, periodic audits |
| Test Responsibility Map | `guide://test-responsibility-map` | Behavior→layer mapping, risk-based coverage |
| Test Review Checklist | `guide://test-review-checklist` | PR review checklist for tests |

### Related Existing Guides

| Guide | Package | Description |
|-------|---------|-------------|
| Testing Philosophy | ace-test | IO isolation principle, test pyramid |
| Test Performance | ace-test | Performance targets, zombie mocks |
| Test Organization | ace-test | Flat structure, naming conventions |
| Mocking Patterns | ace-test | MockGitRepo, WebMock, subprocess |
| E2E Testing | ace-test-e2e-runner | E2E conventions, `.mt.md` format |
| Testable Code Patterns | ace-test | Avoiding exit calls, status codes |

## Workflows

| Workflow | Protocol | Description |
|----------|----------|-------------|
| Plan Tests | `wfi://plan-tests` | Create test responsibility map before coding |
| Verify Test Suite | `wfi://verify-test-suite` | Audit suite health (quick/standard/deep) |
| Optimize Tests | `wfi://optimize-tests` | Semi-automated performance optimization |
| E2E Sandbox Setup | `wfi://e2e-sandbox-setup` | Safe E2E environment setup |

## Templates

| Template | Purpose | When to Use |
|----------|---------|-------------|
| [test-responsibility-map.template.md](templates/test-responsibility-map.template.md) | Behavior→layer mapping | New feature, coverage audit |
| [test-performance-audit.template.md](templates/test-performance-audit.template.md) | Monthly audit report | Periodic health check |
| [test-review-checklist.template.md](templates/test-review-checklist.template.md) | PR review | Reviewing test PRs |
| [e2e-sandbox-checklist.template.md](templates/e2e-sandbox-checklist.template.md) | E2E setup | Setting up E2E tests |

## Key Concepts

### The 100ms Rule

Any unit/integration test >100ms is a **bug**, not just slow.

| Threshold | Status | Action |
|-----------|--------|--------|
| <10ms | Healthy | None |
| 10-100ms | Warning | Review |
| >100ms | **Bug** | Must fix |
| >200ms | **Critical** | Block PR |

### Test Responsibility Map

Each behavior → exactly one test layer. Map at lowest layer possible.

| Behavior Type | Preferred Layer |
|---------------|-----------------|
| Pure logic | Unit (atoms) |
| Component wiring | Integration |
| User workflow | E2E |

### Planner vs Writer Roles

| Role | Focus | Output |
|------|-------|--------|
| **Planner** | WHAT + WHERE to test | Responsibility map |
| **Writer** | HOW to implement | Test files |

### Stub the Boundary

Always stub the outermost method that triggers I/O:

```ruby
Runner.stub(:available?, true) do  # Boundary
  Runner.stub(:run, result) do      # Inner
    subject.process
  end
end
```

## File Organization

```
8oup7s-supplementary/
├── SUMMARY.md                      # This file
├── test-layer-decision.g.md        # Layer decision guide
├── test-mocking-patterns.g.md      # Mocking patterns guide
├── test-suite-health.g.md          # Health metrics guide
├── test-responsibility-map.g.md    # Responsibility mapping guide
├── test-review-checklist.g.md      # Review checklist guide
├── plan-tests.wf.md                # Test planning workflow
├── verify-test-suite.wf.md         # Health audit workflow
├── optimize-tests.wf.md            # Optimization workflow
├── e2e-sandbox-setup.wf.md         # E2E setup workflow
├── test-performance-updates.md     # Updates for existing guide
└── templates/
    ├── test-responsibility-map.template.md
    ├── test-performance-audit.template.md
    ├── test-review-checklist.template.md
    └── e2e-sandbox-checklist.template.md
```

## Integration Points

### Where These Guides Fit

```
Feature Request
    │
    ▼
/ace:plan-tests ──────► Test Responsibility Map
    │
    ▼
Implementation
    │
    ▼
Write Tests ◄───────── Test Layer Decision Guide
    │                  Test Mocking Patterns Guide
    ▼
PR Review ◄─────────── Test Review Checklist
    │
    ▼
CI ◄────────────────── Test Performance Guide (existing)
    │
    ▼
Monthly Audit ◄─────── Verify Test Suite Workflow
                       Test Suite Health Guide
```

## See Also

- [Main Research Report](../8oup7s-report.md)
- [ace-test package](../../../../../../ace-test/)
- [ace-test-e2e-runner package](../../../../../../ace-test-e2e-runner/)
