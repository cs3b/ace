---
doc-type: user
title: ace-test Documentation Reference
purpose: Documentation for ace-test/docs/usage.md
ace-docs:
  last-updated: 2026-04-11
  last-checked: 2026-04-11
---

# ace-test Usage Reference

`ace-test` is a workflow package. It does not provide a runtime test execution CLI itself.

## Package Scope

- Documentation and guidance for testing strategies
- Protocol-discoverable guides and workflows
- Agent skills for planning, coverage, optimization, and review tasks

## Common Commands

| Command | Purpose |
|---------|---------|
| `ace-bundle guide://quick-reference` | Open top-level testing knowledge reference |
| `ace-bundle guide://testing-philosophy` | Read testing philosophy and boundaries |
| `ace-bundle guide://testing` | Open the broad testing guide |
| `ace-bundle wfi://test/plan` | Plan testing changes |
| `ace-bundle wfi://test/create-cases` | Create structured test cases |
| `ace-bundle wfi://test/fix` | Fix failing tests using ACE workflow |
| `ace-bundle wfi://test/improve-coverage` | Find coverage gaps and add tasks |
| `ace-bundle wfi://test/verify-suite` | Verify suite health |
| `ace-bundle wfi://test/optimize` | Optimize slow tests |
| `ace-bundle wfi://test/performance-audit` | Run performance-focused review |

## Discovery (`ace-nav`)

- `ace-nav resolve guide://quick-reference`
- `ace-nav resolve guide://test-organization`
- `ace-nav resolve wfi://test/plan`
- `ace-nav resolve wfi://test/review`
- `ace-nav list 'guide://*'`
- `ace-nav list 'wfi://test/*'`

## Testing

`ace-test` is currently a **fast-only** package in the ACE testing model.

- Deterministic coverage lives under `test/fast/`.
- This package does not introduce `test/feat/` or `test/e2e/` in this migration.

Verification commands:

```bash
ace-test ace-test
ace-test ace-test all
```

## Note on execution

For the actual CLI for running tests, use `ace-test-runner` (not part of this package).
