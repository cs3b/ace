---
doc-type: workflow
name: review-package
description: Structured package review workflow with deterministic evidence checks and prioritized findings output
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-search:*)
  - Bash(ace-lint:*)
  - Bash(ace-idea:*)
title: Review Package Workflow
purpose: Run evidence-first package reviews across maintainability, interface quality, and documentation fidelity
ace-docs:
  last-updated: 2026-03-28
  last-checked: 2026-03-28
---

# Review Package Workflow

## Goal

Review a package with a repeatable, evidence-first process that combines deterministic checks and agent judgment, then output prioritized findings and concrete recommendations.

## Arguments

- `$1`: Package name (required), for example `ace-review`

## Prerequisites

- Target package directory exists in repository root
- `ace-bundle` and `ace-search` available
- `ace-idea` is optional for persisting the full report as an idea attachment


## Priority Model

Use these severity markers in findings:

- `🔴 Immediate`: must address now (correctness, security, severe maintainability risk)
- `🟡 Next Release`: should address in the next release cycle
- `🟢 Backlog`: useful improvements with lower urgency
- `🔵 Advisory`: informational guidance

## Findings Tables

Per-finding table:

```markdown
| # | Dimension | Check | Priority | Evidence | File(s) | Recommendation | Tool |
|---|-----------|-------|----------|----------|---------|----------------|------|
```

Summary counts table:

```markdown
| Dimension | Immediate | Next Release | Backlog | Advisory | Total |
|-----------|-----------|--------------|---------|----------|-------|
```

## Instructions

### Step 1: Validate Package Input

1. Ensure package argument is present:
   These shell blocks are reference command snippets for agent execution flow checks; they are not intended to be run as a standalone script.

```bash
if [ -z "$1" ]; then
  echo "Usage: /as-review-package <package-name>"
  ace-search "^ace-" "." --files
  exit 1
fi
```

2. Ensure target path exists:

```bash
if [ ! -d "$1" ]; then
  echo "Package not found: $1"
  ace-search "^ace-" "." --files
  exit 1
fi
```

3. If missing, list candidate packages and stop:

```bash
ace-search "^ace-" "." --files
```

### Step 2: Load Review Context

1. Load baseline project context:

```bash
ace-bundle project
```

2. Gather package-specific context directly:

```bash
ace-search "." "$1" --files
```

3. Continue with project context and direct package inspection.

4. Initialize deterministic report output target:

```bash
package_slug="$(printf '%s' "$1" | tr '/ ' '-')"
review_timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report_dir=".ace-local/review/package/${package_slug}"
report_path="${report_dir}/raw-review-${review_timestamp}.md"
mkdir -p "$report_dir"
```

### Step 3: Build Evidence Inventory

Collect key files for later cross-checking:

```bash
# Reuse the file inventory collected in Step 2.
ace-search "^#|^##|class |module |desc " "$1" --content
```

Minimum evidence set:

- `README.md` and package `docs/usage.md` (if present)
- `CHANGELOG.md`
- `exe/*` and CLI command files
- `lib/**` implementation files
- `test/**` test files
- `.ace-defaults/**` configuration defaults
- `handbook/**` workflows and guides

### Step 4: Maintainability Review (Deterministic)

Run these checks first. Record evidence and thresholds.

#### M1. Test Coverage Ratio

Goal: test file count to implementation file count at or above `0.8:1`.

```bash
ace-search "\\.rb$" "$1/lib" --files
ace-search "_test\\.rb$" "$1/test" --files
```

Thresholds:

- `🔴`: ratio `< 0.5`
- `🟡`: ratio `>= 0.5` and `< 0.8`
- `🟢`: ratio `>= 0.8`

If SimpleCov artifact exists, include coverage percentage as supporting evidence. If absent, note "coverage artifact unavailable".

#### M2. File Size Compliance

Target: identify oversized implementation hotspots with lint + structure evidence.

```bash
ace-search "\\.rb$" "$1/lib" --files
ace-lint "$1/lib/**/*.rb"
```

Thresholds:

- `🔴`: repeated severe lint hotspots in core files (for example excessive method/class complexity with large files)
- `🟡`: moderate lint hotspots concentrated in a few files
- `🟢`: no major lint hotspots reported

#### M3. Code Duplication

Heuristic scan (not deterministic):

```bash
ace-search "def " "$1/lib" --content
ace-search "TODO: duplicate|duplicate" "$1/lib" --content
```

Interpretation:

- Treat matches as hints and confirm true duplication by reading candidate methods side-by-side before escalating priority.

#### M4. Complexity Hotspots

Baseline:

```bash
# Reuse M2 lint output as baseline; rerun only if the file set changed.
ace-lint "$1/lib/**/*.rb"
```

#### M5. Code Smells

Evidence scan:

```bash
ace-search "TODO|FIXME|HACK|XXX|rescue StandardError|puts\\(|binding\\.pry" "$1/lib" --content
```

Use this check for smell-specific signals; rely on M4's `ace-lint` output for complexity hotspots.

#### M6. ATOM Architecture Compliance

Check expected layering and cross-layer imports.

```bash
ace-search "atoms" "$1/lib" --files
ace-search "molecules" "$1/lib" --files
ace-search "organisms" "$1/lib" --files
ace-search "require .*organisms" "$1/lib" --content
```

Flag atom-to-organism or atom-to-cli coupling as maintainability risk.

#### M7. Dead Code and Technical Debt

```bash
ace-search "TODO|FIXME|HACK|XXX" "$1" --content
ace-search "deprecated|obsolete|legacy" "$1/lib" --content
```

Score by density and stale markers without owners.

#### M8. Dependency Hygiene

Compare gemspec dependencies with runtime requires.

```bash
ace-search "add_dependency|add_runtime_dependency" "$1" --content
ace-search "^require " "$1/lib" --content
```

Flag missing or unused dependencies and hidden runtime dependencies.

#### M9. Changelog Maintenance

```bash
[ -f "$1/CHANGELOG.md" ] && ace-search "^## \[" "$1" --content || echo "CHANGELOG.md not found"
[ -f "$1/CHANGELOG.md" ] && ace-search "Added|Changed|Fixed|Security" "$1" --content || echo "CHANGELOG.md not found"
```

Check format consistency and recency relative to recent commits.

### Step 5: Interface Quality Review (Evidence Then Judgment)

Gather evidence first, then evaluate.

#### I1. CLI Flag Consistency

```bash
ace-search "option .*aliases:" "$1/lib" --content
ace-search "(-v|-q|-d|-h|--help)" "$1/lib" --content
```

Evaluate reserved-flag usage and naming consistency.

#### I2. Error Message Quality

```bash
ace-search "raise|error|fail" "$1/lib" --content
```

Check messages for actionability and recovery guidance.

#### I3. Exit Code Documentation

```bash
ace-search "exit code|Exit codes|status code" "$1" --content
ace-search "Ace::Core::CLI::Error|exit" "$1/lib" --content
```

Evaluate documentation-to-implementation alignment.

#### I4. API Surface Consistency

```bash
ace-search "module Ace::|class .*Command" "$1/lib" --content
ace-search "public|private" "$1/lib" --content
```

Assess naming cohesion and public API boundaries.

#### I5. Help Text Quality

```bash
ace-search "desc \"|argument :|option :" "$1/lib" --content
```

Evaluate completeness, examples, and clarity.

#### I6. Extensibility

```bash
ace-search "hook|plugin|adapter|strategy|provider" "$1/lib" --content
```

Evaluate extension points and coupling tradeoffs.

#### I7. Performance Characteristics

```bash
ace-search "File\\.read|IO\\.read|YAML\\.load|JSON\\.parse|each_slice|each_cons|nested loop|while .*each" "$1/lib" --content
```

Assess patterns for large inputs (streaming vs full load) and potential hotspots.

### Step 6: Documentation Fidelity Review

Cross-check docs against implementation behavior.

#### D1. README Accuracy

```bash
ace-search "ace-" "$1" --content
ace-search "desc \"" "$1/lib" --content
```

Compare documented commands/flags with actual CLI definitions.

#### D2. Usage Docs Drift

```bash
[ -f "$1/docs/usage.md" ] && ace-search "usage|example|command|option" "$1/docs/usage.md" --content || ([ -d "$1/docs" ] && ace-search "usage|example|command|option" "$1/docs" --content || echo "docs/ directory not found")
ace-search "class .*Command|desc \"|option :" "$1/lib" --content
```

If `docs/usage.md` is missing, note as advisory unless required by package conventions. The docs search above intentionally gathers usage context from `docs/` when present.

#### D3. CHANGELOG Completeness

```bash
[ -f "$1/CHANGELOG.md" ] && ace-search "^## \[" "$1" --content || echo "CHANGELOG.md not found"
```

Check whether notable changes appear in changelog entries.

#### D4. Help Text Accuracy

```bash
ace-search "(--help|-h)" "$1" --content
```

Compare docs to command definitions and expected help output.

#### D5. Config Documentation Fidelity

```bash
ace-search "\.ace-defaults|config.yml|resolve_namespace" "$1" --content
ace-search "config|\.ace/" "$1" --content
```

Cross-check config keys and precedence explanations.

#### D6. ADR and Standards Alignment

```bash
ace-search "ADR-|ATOM|workflow|ace-bundle" "$1" --content
```

Verify references point to real practices and files.

### Step 7: Handle Optional Tool Availability

If optional tooling is not installed:

1. Record the tool as unavailable.
2. Record fallback command(s) used.
3. Continue review without failing the workflow.
4. Add advisory recommendation with install guidance where useful.

### Step 8: Compile Findings

1. Build one findings row per issue using the required columns:

- `Dimension`: Maintainability, Interface Quality, or Documentation Fidelity
- `Check`: check id/name (for example `M4 Complexity Hotspots`)
- `Priority`: one of `🔴/🟡/🟢/🔵`
- `Evidence`: concrete command result summary
- `File(s)`: exact file paths
- `Recommendation`: action with scope
- `Tool`: command/tool used (or fallback)

2. Produce summary count table by dimension and priority.

### Step 9: Prioritize Recommendations

Group actions into buckets:

1. `Immediate`: correctness/security/severe quality risks
2. `Next Release`: high-value improvements with moderate risk
3. `Backlog`: incremental maintainability improvements
4. `Advisory`: non-blocking guidance

Add rough effort tags where possible (`S`, `M`, `L`).

### Step 10: Final Review Output and Report Artifact

Your final package review output should contain, in order:

1. Scope and package reviewed
2. Tool availability notes
3. Findings table
4. Summary table
5. Prioritized recommendation list
6. Brief closing note with follow-up suggestion

Use the same content to create a full markdown report file:

```bash
cat <<EOF > "$report_path"
# Package Review Report: $1

Scope and package reviewed: $1

## Tool Availability

## Findings

| # | Dimension | Check | Priority | Evidence | File(s) | Recommendation | Tool |
|---|-----------|-------|----------|----------|---------|----------------|------|

## Summary

| Dimension | Immediate | Next Release | Backlog | Advisory | Total |
|-----------|-----------|--------------|---------|----------|-------|

## Prioritized Recommendations

## Closing Note
EOF

echo "Full report saved to: $report_path"

if command -v ace-idea >/dev/null 2>&1; then
  ace-idea create "Package review report for ${1}. Full report is attached as full-report.md in the idea folder." --title "Review package ${1}" --tags review,package --move-to maybe
  echo "Use the output Path above to attach report artifact:"
  echo "Set idea_file_path to the \"Path:\" value above and run:"
  echo "cp \"$report_path\" \"\$(dirname \"$idea_file_path\")/full-report.md\""
else
  echo "ace-idea not available; full report available at: $report_path"
fi
```

## Error Handling

- Package not found: show clear error and available package list
- Package-specific bundle unavailable: continue with project bundle and direct inspection
- Optional tool missing: continue with fallback and document limitation
- Coverage artifact unavailable: report coverage metric as unavailable (do not block)

## Quick Reference

```bash
# Load context
ace-bundle project
ace-search "\\.rb$" "<package>/lib" --files

# Core evidence scans
ace-search "<pattern>" <package> --content
ace-search "\\.rb$" <package> --files

# Protocol load check for this workflow
ace-bundle wfi://review/package

# Lint this workflow file
ace-lint ace-review/handbook/workflow-instructions/review/package.wf.md
```

## Success Criteria

- [ ] `package.wf.md` is expanded from placeholder instructions to a comprehensive workflow
- [ ] Maintainability section defines 9 deterministic checks with thresholds or clear fallbacks
- [ ] Interface Quality section defines 7 evidence-first checks
- [ ] Documentation Fidelity section defines 6 doc-vs-code cross-checks
- [ ] Findings output includes required per-finding table format
- [ ] Summary output includes required dimension/priority counts table
- [ ] Missing optional tools are handled as non-blocking with explicit notes
- [ ] Workflow loads with `ace-bundle wfi://review/package`
- [ ] File passes `ace-lint`
