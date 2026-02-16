# Phased Review Presets - Usage Guide

## Overview

Three laser-focused review presets enable phased code review, where each phase examines a distinct dimension of code quality. A fourth preset (`code-deep`) provides backward compatibility with existing workflows.

### Available Presets

| Preset | Phase | Key Question | Format |
|--------|-------|-------------|--------|
| `code-correctness` | 1 - Does it work? | "Does this code work correctly and completely?" | Detailed |
| `code-quality` | 2 - Is it well-structured? | "Is this code well-structured and performant?" | Detailed |
| `code-polish` | 3 - Can we simplify? | "How can we make this code more elegant?" | Standard |
| `code-deep` | All | Comprehensive review (backward compat) | Detailed |

## Command Structure

All presets are invoked via the standard `ace-review --preset` interface:

```bash
ace-review --preset <preset-name> --pr <pr-number>
ace-review --preset <preset-name> --pr <pr-number> --dry-run  # validate without executing
```

## Usage Scenarios

### Scenario 1: Sequential Phased Review

Goal: Review a PR in three focused passes, fixing issues between each phase.

```bash
# Phase 1: Fix correctness issues first
ace-review --preset code-correctness --pr 123
# Author addresses bugs, missing functionality, error handling gaps

# Phase 2: Address structural and performance concerns
ace-review --preset code-quality --pr 123
# Author addresses N+1 queries, architecture violations, test gaps

# Phase 3: Polish pass (all suggestions non-blocking)
ace-review --preset code-polish --pr 123
# Author optionally addresses naming, simplification, readability
```

### Scenario 2: Targeted Single-Phase Review

Goal: Only check correctness on a hotfix PR (skip quality and polish).

```bash
ace-review --preset code-correctness --pr 456
```

### Scenario 3: Backward-Compatible Deep Review

Goal: Run a comprehensive review matching the previous `code` preset behavior with detailed format.

```bash
ace-review --preset code-deep --pr 789
```

This is equivalent to running the `code` preset but with `detailed` format output. Existing ace-assign configurations referencing `code-deep` will continue to work.

### Scenario 4: Dry-Run Validation

Goal: Verify a preset loads correctly before running a full review.

```bash
ace-review --preset code-correctness --dry-run
# Output shows resolved prompt:// references and configuration
```

## What Each Phase Covers

### code-correctness (Phase 1)
**Reviews:** Logic errors, missing functionality, error handling gaps, security vulnerabilities affecting correctness, broken API contracts
**Ignores:** Style, formatting, performance optimization, naming, documentation, refactoring

### code-quality (Phase 2)
**Reviews:** Performance issues (N+1, allocations), architecture compliance (ATOM pattern), standards adherence, test coverage gaps
**Ignores:** Cosmetic improvements, alternative approaches, polish, documentation style

### code-polish (Phase 3)
**Reviews:** Simplification opportunities, naming clarity, dead code/duplication, documentation gaps, readability
**Note:** All findings are NON-BLOCKING suggestions

### code-deep (Comprehensive)
**Reviews:** Everything from the `code` preset (all focus areas)
**Format:** Detailed output

## Tips and Best Practices

- Run phases in order (correctness -> quality -> polish) for best results; earlier phases surface issues that would obscure later-phase feedback
- Phase 1 (correctness) is the most critical; do not skip it
- Phase 3 (polish) findings are all non-blocking; treat them as optional improvements
- Use `--dry-run` to verify preset configuration before running actual reviews
- The `code-deep` preset is for backward compatibility; prefer phased presets for new workflows
