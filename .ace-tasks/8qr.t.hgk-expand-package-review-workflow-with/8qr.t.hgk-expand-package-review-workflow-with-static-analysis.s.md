---
id: 8qr.t.hgk
status: draft
priority: medium
created_at: "2026-03-28 11:38:24"
estimate: S
dependencies: []
tags: [ace-review, workflow, static-analysis]
bundle:
  presets: ["project"]
  files:
    - ace-review/handbook/workflow-instructions/review/package.wf.md
    - ace-review/handbook/workflow-instructions/review/run.wf.md
    - ace-review/handbook/workflow-instructions/review/verify-feedback.wf.md
    - ace-review/handbook/guides/code-review-process.g.md
    - .ace-ideas/_review/
  commands: []
---

# Expand Package Review Workflow with Static-Analysis Hygiene, Health, and Doc-Drift Checks

## Behavioral Specification

### User Experience

- **Input**: Agent or developer invokes `/as-review-package <package-name>`
- **Process**: The workflow guides a structured package review across three dimensions — hygiene (tool-driven), health (agent judgment), and documentation drift (cross-reference). Static analysis tools run first to collect objective metrics before any LLM-based evaluation.
- **Output**: A prioritized findings report organized by dimension, with summary counts table and actionable recommendations grouped by urgency (Immediate / Next Release / Backlog).

### Expected Behavior

The workflow replaces the current 3-line placeholder in `package.wf.md` with a comprehensive ~280-300 line review workflow that:

1. **Loads package context** via `ace-bundle <package>/project` and runs a static analysis suite to collect baseline metrics (LOC, test ratio, RuboCop offenses, complexity scores)
2. **Hygiene Review (9 tool-driven checks)** — deterministic checks using static analysis tools with objective thresholds:
   - Test coverage ratio (target 0.8:1, thresholds for 🔴/🟡/🟢)
   - File size compliance (<400 lines target, >600 = 🔴)
   - Code duplication (Flay mass scores, or grep-based fallback)
   - Complexity hotspots (RuboCop Metrics cops, optional Flog)
   - Code smells (optional Reek, or RuboCop style cops)
   - ATOM architecture compliance (layer directories, cross-layer imports)
   - Dead code / technical debt (TODO/FIXME counts)
   - Dependency hygiene (explicit requires vs gemspec)
   - Changelog maintenance (format, recency)
3. **Health Review (7 agent-judgment checks)** — design quality requiring LLM evaluation:
   - CLI flag consistency (reserved flags, short flags, cross-package naming)
   - Error message quality (actionable, recovery suggestions)
   - Exit code documentation
   - API surface consistency
   - Help text quality (examples, completeness)
   - Extensibility (plugin/hook points where warranted)
   - Performance (streaming vs loading, large-input handling)
4. **Documentation vs Implementation Drift (6 checks)** — cross-referencing docs against code:
   - README accuracy (documented flags/commands vs actual CLI)
   - Usage docs drift (docs/usage.md vs implementation)
   - CHANGELOG completeness (git log vs entries)
   - Help text accuracy (--help output vs docs)
   - Config documentation (config keys in code vs documented)
   - ADR compliance (referenced ADRs vs actual implementation)
5. **Compiles findings** into structured tabular report by dimension and priority
6. **Prioritizes recommendations** into Immediate/Next Release/Backlog with effort estimates

Tools already available: RuboCop (v1.84.2), SimpleCov (v0.22). Optional tools (gracefully skipped if absent): RubyCritic, Flay, Flog, Reek.

### Interface Contract

```bash
# Invocation (unchanged skill interface)
/as-review-package ace-review

# Workflow loads via existing protocol
ace-bundle wfi://review/package
```

Output format — structured findings table per dimension:

```
| # | Priority | Check | Finding | File(s) | Recommendation |
```

Summary table:

```
| Dimension | 🔴 | 🟡 | 🟢 | 🔵 | Total |
```

Error Handling:
- Missing optional tools (RubyCritic, Flay, Reek): note as unavailable, suggest install, continue with available tools
- Package not found: clear error message with available package list
- No `ace-bundle <package>/project` preset: fall back to manual directory inspection

### Success Criteria

1. `package.wf.md` expanded from 3 instructions to ~280-300 lines
2. Hygiene checks use static analysis tools with deterministic thresholds (no LLM for metrics)
3. Health checks specify evidence-gathering commands (grep patterns) before agent judgment
4. Doc-drift checks cross-reference docs against implementation with concrete comparison methods
5. Output template produces consistent, tabular findings with priority emoji
6. Follows existing .wf.md conventions (frontmatter, numbered steps, Quick Reference, Success Criteria)
7. Loads successfully via `ace-bundle wfi://review/package`
8. Passes `ace-lint`

### Validation Questions

- None remaining — requirements gathered from 15 historical review ideas and confirmed by user.

## Vertical Slice Decomposition

- **Slice**: Standalone task (single file rewrite)
- **Outcome**: `package.wf.md` rewritten with full 3-dimension review structure
- **Advisory size**: Small — single workflow file, ~280 lines, well-defined structure from sibling workflows
- **Context**: Sibling workflows (`run.wf.md`, `verify-feedback.wf.md`) provide structural template

## Verification Plan

### Unit/Component Validation

- [ ] File follows .wf.md frontmatter conventions (doc-type, title, purpose, ace-docs)
- [ ] All 9 hygiene checks have concrete bash commands and priority thresholds
- [ ] All 7 health checks specify evidence-gathering approach
- [ ] All 6 doc-drift checks define cross-reference method
- [ ] Output template includes both per-finding table and summary table
- [ ] Quick Reference section with example commands
- [ ] Success Criteria checklist present

### Integration/E2E Validation

- [ ] `ace-bundle wfi://review/package` loads the workflow successfully
- [ ] `ace-lint ace-review/handbook/workflow-instructions/review/package.wf.md` passes
- [ ] Workflow structure is consistent with `run.wf.md` and `verify-feedback.wf.md`

### Failure/Invalid Path Validation

- [ ] Workflow handles missing optional tools gracefully (noted, not blocked)
- [ ] Workflow handles missing package context (fallback documented)

## Objective

The current `package.wf.md` is a 3-line placeholder that gives no structured guidance for package reviews. Analysis of 15 historical package review ideas revealed systemic patterns (test coverage gaps, file size violations, CLI inconsistencies, doc drift) that recur across the ecosystem. Encoding these patterns into a detailed workflow ensures future reviews catch the same issues consistently, using static analysis tools for objective metrics and reserving LLM judgment for design quality questions.

## Scope of Work

- **Included**: Rewrite of `ace-review/handbook/workflow-instructions/review/package.wf.md`
- **Included**: Three review dimensions with specific checks, thresholds, and output format

## Deliverables

### Behavioral Specifications
- Expanded `package.wf.md` with 3-dimension review structure

### Validation Artifacts
- Lint pass, protocol load verification

## Out of Scope

- Adding new Ruby gems (RubyCritic, Flay, Reek) to the project — workflow handles them as optional
- Changes to the `/as-review-package` skill definition
- Changes to other review workflows (run.wf.md, pr.wf.md, etc.)
- Implementing any findings from the historical reviews themselves

## References

- Plan: `.claude/plans/lovely-weaving-goose.md`
- Source ideas: all 15 files in `.ace-ideas/_review/` (comprehensive review improvements)
- Sibling workflows: `ace-review/handbook/workflow-instructions/review/run.wf.md`, `verify-feedback.wf.md`, `apply-feedback.wf.md`
- Code review guide: `ace-review/handbook/guides/code-review-process.g.md`
