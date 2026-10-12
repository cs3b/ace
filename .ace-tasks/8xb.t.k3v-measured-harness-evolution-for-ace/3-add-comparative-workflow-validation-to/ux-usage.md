# Comparative Workflow Validation - Draft Usage

## API Surface

- [x] CLI (`ace-sim run --compare-*`)
- [ ] Developer API
- [ ] Agent API (usable from skills/assignments as a plain CLI step)
- [x] Configuration (variant paths, task-set reference)

## Usage Scenarios

### Scenario 1: Compare a workflow revision against its baseline

**Goal**: Decide whether a proposed workflow edit is worth adopting.

```bash
ace-sim run --compare-old wfi://git/commit --compare-new .ace-local/plans/git-commit-v2.wf.md --tasks .ace-local/plans/validation-set.yml
```

Expected output:

```text
Comparison report: .ace-local/sim/compare-2026-10-12/git-commit.md
Result: 8 tasks, new variant 7/8 pass vs old 5/8 — recommendation: ADOPT
```

### Scenario 2 (Edge): Inconclusive comparison

**Goal**: Small task set yields no reliable signal.

```bash
ace-sim run --compare-old a.wf.md --compare-new b.wf.md --tasks tiny-set.yml
```

Expected output:

```text
Result: 2 tasks — sample too small for a reliable signal — recommendation: INCONCLUSIVE
```

### Scenario 3 (Error): Unknown variant path

**Goal**: Fail fast before running anything.

```bash
ace-sim run --compare-old missing.wf.md --compare-new b.wf.md --tasks set.yml
```

Expected output:

```text
Error: variant 'missing.wf.md' not readable. No comparison started.
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`.
