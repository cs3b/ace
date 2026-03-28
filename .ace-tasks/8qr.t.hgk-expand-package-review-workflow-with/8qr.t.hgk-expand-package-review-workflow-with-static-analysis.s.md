---
id: 8qr.t.hgk
status: pending
priority: medium
needs_review: false
created_at: "2026-03-28 11:38:24"
estimate: S
dependencies: []
tags: [ace-review, workflow, static-analysis]
bundle:
  presets: [project]
  files: [ace-review/handbook/workflow-instructions/review/package.wf.md, ace-review/handbook/workflow-instructions/review/run.wf.md, ace-review/handbook/workflow-instructions/review/verify-feedback.wf.md, ace-review/handbook/guides/code-review-process.g.md]
  commands: []
---

## Review Questions (Resolved 2026-03-28)

### [RESOLVED] Source-of-truth references in this task are stale or non-reproducible

- **Decision**: Remove the stale historical-source references and ground the task entirely in current repository artifacts.
- **Research conducted**: Checked the referenced plan path and historical-idea directory during review.
- **Findings**:
  - `.claude/plans/lovely-weaving-goose.md` does not exist.
  - `.ace-ideas/_review/` exists but contains no review source files, so it cannot support the prior provenance claim.
- **Resolution applied**:
  - Removed the stale `References` entries.
  - Rewrote the `Objective` section to rely on current `ace-review` workflow gaps and sibling workflow patterns.
- **Rationale**: This keeps the task reproducible from the current repo state and avoids blocking implementation on missing historical context.

# Expand Package Review Workflow with Quality and Doc-Drift Checks

## Behavioral Specification

### User Experience

- **Input**: Agent or developer invokes `/as-review-package <package-name>`
- **Process**: The workflow guides a structured package review across three dimensions — Maintainability (tool-driven), Interface Quality (agent judgment), and Documentation Fidelity (cross-reference). Static analysis tools run first to collect objective metrics before any LLM-based evaluation.
- **Output**: A prioritized findings report organized by dimension, with summary counts table and actionable recommendations grouped by urgency (`Immediate` / `Next Release` / `Backlog` / `Advisory`).

### Expected Behavior

The workflow replaces the current 3-line placeholder in `package.wf.md` with a comprehensive ~280-300 line review workflow that:

1. **Loads review context** via `ace-bundle project`, then inspects the target package directly; if a package-specific preset such as `ace-bundle <package>/project` exists, the workflow may use it as an optimization rather than assuming it exists
2. **Maintainability Review (9 tool-driven checks)** — deterministic checks using baseline tools first, with objective thresholds where appropriate:
   - Test coverage ratio (target 0.8:1, thresholds for 🔴/🟡/🟢)
   - File size compliance (<400 lines target, >600 = 🔴)
   - Code duplication (Flay mass scores, or grep-based fallback)
   - Complexity hotspots (RuboCop Metrics cops, optional Flog)
   - Code smells (optional Reek, or RuboCop style cops)
   - ATOM architecture compliance (layer directories, cross-layer imports)
   - Dead code / technical debt (TODO/FIXME counts)
   - Dependency hygiene (explicit requires vs gemspec)
   - Changelog maintenance (format, recency)
3. **Interface Quality Review (7 agent-judgment checks)** — design quality requiring LLM evaluation after evidence collection:
   - CLI flag consistency (reserved flags, short flags, cross-package naming)
   - Error message quality (actionable, recovery suggestions)
   - Exit code documentation
   - API surface consistency
   - Help text quality (examples, completeness)
   - Extensibility (plugin/hook points where warranted)
   - Performance (streaming vs loading, large-input handling)
4. **Documentation Fidelity Review (6 checks)** — cross-referencing docs against code and CLI behavior:
   - README accuracy (documented flags/commands vs actual CLI)
   - Usage docs drift (docs/usage.md vs implementation)
   - CHANGELOG completeness (git log vs entries)
   - Help text accuracy (--help output vs docs)
   - Config documentation (config keys in code vs documented)
   - ADR compliance (referenced ADRs vs actual implementation)
5. **Compiles findings** into structured tabular report by dimension and priority
6. **Prioritizes recommendations** into `Immediate` / `Next Release` / `Backlog` / `Advisory` with effort estimates

Baseline tools expected in the workflow: RuboCop plus repo-native search and file inspection. Optional tools, gracefully skipped when absent: RubyCritic, Flay, Flog, Reek, Bundler Audit, SimpleCov artifacts, Vale, and reviewdog-style CI surfacing.

### Interface Contract

```bash
# Invocation (unchanged skill interface)
/as-review-package ace-review

# Workflow loads via existing protocol
ace-bundle wfi://review/package
```

Output format — structured findings table per dimension:

```
| # | Dimension | Check | Priority | Evidence | File(s) | Recommendation | Tool |
```

Summary table:

```
| Dimension | Immediate | Next Release | Backlog | Advisory | Total |
```

Error Handling:
- Missing optional tools (RubyCritic, Flay, Reek): note as unavailable, suggest install, continue with available tools
- Package not found: clear error message with available package list
- No package-specific `ace-bundle <package>/project` preset: fall back to project bundle plus manual package inspection
- No existing coverage artifact: note coverage as unavailable unless the operator explicitly chooses to run tests

### Success Criteria

1. `package.wf.md` expanded from 3 instructions to ~280-300 lines
2. Maintainability checks use deterministic evidence and thresholds where applicable (no LLM-only metrics)
3. Interface Quality checks specify evidence-gathering commands before agent judgment
4. Documentation Fidelity checks cross-reference docs against implementation with concrete comparison methods
5. Output template produces consistent, tabular findings with priority emoji
6. Follows existing .wf.md conventions (frontmatter, numbered steps, Quick Reference, Success Criteria)
7. Loads successfully via `ace-bundle wfi://review/package`
8. Passes `ace-lint`

### Validation Questions

- None remaining — requirements grounded in current `ace-review` workflow gaps, sibling workflows, and the resolved review decisions in this task.

## Vertical Slice Decomposition

- **Slice**: Standalone task (single file rewrite)
- **Outcome**: `package.wf.md` rewritten with full 3-dimension review structure
- **Advisory size**: Small — single workflow file, ~280 lines, well-defined structure from sibling workflows
- **Context**: Sibling workflows (`run.wf.md`, `verify-feedback.wf.md`) provide structural template

## Verification Plan

### Unit/Component Validation

- [ ] File follows .wf.md frontmatter conventions (doc-type, title, purpose, ace-docs)
- [ ] All 9 Maintainability checks have concrete commands and thresholds or explicit fallback behavior
- [ ] All 7 Interface Quality checks specify evidence-gathering approach
- [ ] All 6 Documentation Fidelity checks define cross-reference method
- [ ] Output template includes both per-finding table and summary table
- [ ] Quick Reference section with example commands
- [ ] Success Criteria checklist present

### Integration/E2E Validation

- [ ] `ace-bundle wfi://review/package` loads the workflow successfully
- [ ] `ace-lint ace-review/handbook/workflow-instructions/review/package.wf.md` passes
- [ ] Workflow structure is consistent with `run.wf.md` and `verify-feedback.wf.md`
- [ ] Default review path remains usable in repos that do not ship package-specific `ace-bundle <package>/project` presets

### Failure/Invalid Path Validation

- [ ] Workflow handles missing optional tools gracefully (noted, not blocked)
- [ ] Workflow handles missing package context (fallback documented)

## Objective

The current `package.wf.md` is a 3-line placeholder that gives no structured guidance for package reviews. Current repository evidence shows a gap between that minimal workflow and the richer review expectations already expressed elsewhere in `ace-review`, especially around evidence gathering, feedback verification, CLI/documentation consistency, and repeatable operator guidance. Encoding those recurring review concerns into a detailed workflow ensures future package reviews are more consistent, use deterministic signals where possible, and reserve LLM judgment for design-quality questions that cannot be measured mechanically.

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
- Implementing package-level findings discovered while using the workflow

## References

- Sibling workflows: `ace-review/handbook/workflow-instructions/review/run.wf.md`, `verify-feedback.wf.md`, `apply-feedback.wf.md`
- Code review guide: `ace-review/handbook/guides/code-review-process.g.md`

## Review Summary

**Readiness Checklist:** Previously blocked by stale provenance references; blocking question now resolved in favor of current repo artifacts.  
**Questions Generated:** 1 total (1 high, 0 medium), now resolved.  
**Critical Blockers:** None remaining from the provenance review pass.  
**Advisories:** Prefer standards-first dimension naming (`Maintainability`, `Interface Quality`, `Documentation Fidelity`) and a baseline-tool-first workflow design with optional enrichments.  
**Decision:** Remains draft but no longer marked `needs_review`.  
**Recommended Next Steps:** Re-run `/as-task-review 8qr.t.hgk` to reassess promotion readiness now that the provenance issue is resolved.
