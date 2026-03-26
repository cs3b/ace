---
id: 8qp.t.1fn.1
status: done
priority: medium
created_at: "2026-03-26 00:57:58"
estimate: TBD
dependencies: [8qp.t.1fn.0]
tags: [ace-lint, auto-fix, agent, doctor-pattern]
parent: 8qp.t.1fn
bundle:
  presets: [project]
  files: [ace-lint/lib/ace/lint/cli/commands/lint.rb, ace-lint/lib/ace/lint/organisms/lint_orchestrator.rb, ace-task/lib/ace/task/cli/commands/doctor.rb, ace-task/lib/ace/task/molecules/task_doctor_fixer.rb, ace-task/lib/ace/task/molecules/task_doctor_reporter.rb, ace-llm/lib/ace/llm/query_interface.rb]
  commands: []
needs_review: false
---

## Review Questions (Resolved 2026-03-26)

All questions resolved. Answers integrated into spec below.

- [x] **[HIGH-B1a] Agent prompt scope:** Full file content for files with remaining violations (user decision).
- [x] **[HIGH-B1b] Dry-run agent scope:** Yes, show the agent prompt without launching (transparency).
- [x] **[HIGH-B2] Bundle.files:** Added `ace-llm/lib/ace/llm/query_interface.rb`.
- [x] **[MED-B1] Consumer packages:** Listed in spec.
- [x] **[MED-B2] `--dry-run` alias:** `-n` added for ecosystem consistency.
- [x] **[MED-B3] Interactive prompt:** Non-interactive (diverges from doctor pattern intentionally).
- [x] **[MED-B4] Re-lint after fix:** Noted as new behavior requiring orchestrator flow change.
- [x] **[MED-B5] `--format` + agent:** Same precedence rule — agent wins, format ignored with warning.

# Add Auto-Fix and Agent-Assisted Fix Flags

## Objective

Align ace-lint with the ecosystem's doctor repair pattern by adding `--auto-fix` and `--auto-fix-with-agent` flags. This reduces friction for resolving linting violations — standard fixes are handled deterministically, while complex issues can be delegated to an LLM-powered agent. The `--fix` flag becomes an alias for `--auto-fix`, providing a single unified behavior: surgical fix, then re-lint and report.

## Behavioral Specification

### User Experience

- **Input:** User runs `ace-lint --fix <files>`, `ace-lint --auto-fix <files>`, or `ace-lint --auto-fix-with-agent <files>`
- **Process (`--fix` / `--auto-fix`):** The system applies surgical fixes to all files, then re-lints to verify. Reports what was fixed and what remains. Supports `--dry-run` to preview changes.
- **Process (`--auto-fix-with-agent`):** Runs `--auto-fix` first. If violations remain, formats them into a structured prompt and launches an LLM agent session. The agent receives the violation list with file context and attempts to fix remaining issues.
- **Output:** Report showing: (1) violations auto-fixed, (2) violations remaining, (3) agent session results if applicable.

### Expected Behavior

1. `ace-lint --fix <files>` and `ace-lint --auto-fix <files>` are identical:
   - Apply surgical fixes on all files (markdown: line-level edits; Ruby: StandardRB)
   - Re-lint all files to check for remaining violations
   - Report: "Fixed N violations in M files. K violations remain in J files."
   - Exit code 0 if all violations resolved, exit code 1 if violations remain

2. `ace-lint --auto-fix --dry-run <files>`:
   - Show what fixes would be applied without modifying any files
   - List each file and the fixes that would be made
   - Exit code 0 always (dry-run never fails)

3. `ace-lint --auto-fix-with-agent <files>`:
   - Run `--auto-fix` first (deterministic fixes)
   - If violations remain, format them into a structured prompt
   - Launch agent via `Ace::LLM::QueryInterface` (same pattern as ace-task doctor)
   - Agent receives: full file content for files with remaining violations, plus violation list with file paths, line numbers, and messages
   - Supports `--model` flag for provider:model selection (default from config cascade)
   - Reports agent results
   - If all violations fixed by auto-fix, agent is not launched

4. `ace-lint --auto-fix-with-agent --dry-run <files>`:
   - Show what deterministic fixes would be applied
   - Show the agent prompt that would be sent (without launching)
   - Exit code 0 always

### Interface Contract

```bash
# Deterministic auto-fix (surgical for all file types)
ace-lint --fix README.md lib/**/*.rb
ace-lint --auto-fix README.md lib/**/*.rb        # same behavior
# Output:
#   Fixed 3 violations in 2 files.
#   1 violation remains in 1 file.
# Exit 0: all fixed; Exit 1: remaining violations

# Preview fixes without applying
ace-lint --auto-fix --dry-run README.md
ace-lint --auto-fix -n README.md                  # -n alias for --dry-run
ace-lint --fix --dry-run README.md                # same behavior
# Output:
#   Would fix: README.md:5: Em-dash character -> double hyphens
#   Would fix: README.md:12: Smart double quote -> ASCII quote
#   2 fixes would be applied in 1 file

# Deterministic + agent for remaining
ace-lint --auto-fix-with-agent README.md
# Output:
#   Fixed 2 violations in 1 file.
#   1 violation remains (launching agent)...
#   [Agent output]

# Agent with specific model
ace-lint --auto-fix-with-agent --model gemini:flash-latest README.md

# Help output shows new flags
ace-lint --help
# ...includes --auto-fix, --auto-fix-with-agent, --dry-run, --model...
```

Exit Codes:

| Code | Meaning |
|------|---------|
| 0 | All violations resolved (or dry-run) |
| 1 | Violations remain after auto-fix |
| 2 | Fatal error (invalid arguments, agent failure) |

Error Handling:

- `--auto-fix-with-agent` without ace-llm gem available: Clear error message pointing to installation
- Agent session timeout: Report timeout, show violations that remain
- `--model` with invalid provider: Error with available providers hint (same pattern as ace-task doctor)
- No files specified: Same error as today
- `--auto-fix` with `--format`: `--auto-fix` takes precedence, `--format` is ignored with a warning
- `--auto-fix-with-agent` with `--format`: same rule — agent fix takes precedence, `--format` ignored with a warning

Edge Cases:

- All violations fixable by `--auto-fix`: Agent is not launched for `--auto-fix-with-agent` (reports "All violations resolved")
- Zero violations found: Report "No violations found" and exit 0
- Mixed file types (markdown + Ruby): Each type uses its own fix strategy, combined report
- `--dry-run` without `--auto-fix` or `--fix`: Ignored (no effect on lint-only mode)

Implementation Notes:

- **`--dry-run` alias:** `-n` (ecosystem consistency with ace-task doctor, ace-retro doctor)
- **Non-interactive:** `--auto-fix` does NOT prompt for confirmation (diverges from doctor pattern; matches user expectation of `--fix` as fire-and-forget)
- **Re-lint after fix is new behavior:** Currently `--fix` on markdown returns early without running lint (orchestrator line 117). `--auto-fix` introduces fix → re-lint → report flow. This requires restructuring the orchestrator's `lint_single_file_by_type` control flow.
- **Consumer packages needing updates:** `ace-lint/docs/usage.md`, `ace-lint/docs/getting-started.md`, `docs/tools.md`, `ace-lint/lib/ace/lint/cli/commands/lint.rb` (help text/examples), `ace-lint/test/e2e/TS-LINT-001-lint-pipeline/TC-003-fix-mode.runner.md`

### Success Criteria

- [x] `ace-lint --fix` and `ace-lint --auto-fix` produce identical behavior (fix + re-lint + report)
- [x] `ace-lint --auto-fix --dry-run` shows preview without modifying files
- [x] `ace-lint --auto-fix-with-agent` launches agent for remaining violations (mirrors ace-task doctor)
- [x] `--auto-fix`, `--auto-fix-with-agent`, `--dry-run` / `-n`, `--model` appear in `ace-lint --help`
- [x] `--model` flag works for agent provider selection
- [x] Behavioral parity with ace-task doctor's `--auto-fix` / `--auto-fix-with-agent` pattern
- [x] `-f` alias maps to `--auto-fix` (not legacy `--fix` behavior)

### Validation Questions

- [x] **Flag naming:** `--auto-fix` / `--auto-fix-with-agent` (hyphenated, matching ecosystem convention). Confirmed.
- [x] **`--fix` aliases `--auto-fix`:** Single behavior, no separate low-level flag. Confirmed.
- [x] **Agent prompt scope:** Agent receives full file content for files with remaining violations. Confirmed 2026-03-26.
- [x] **`--dry-run` scope for agent:** Yes, `--dry-run` with `--auto-fix-with-agent` shows the agent prompt without launching. Confirmed 2026-03-26.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type:** Subtask of orchestrator 8qp.t.1fn (depends on subtask 8qp.t.1fn.0)
- **Slice outcome:** `ace-lint --auto-fix` and `ace-lint --auto-fix-with-agent` flags working end-to-end
- **Advisory size:** Medium
- **Context dependencies:** See bundle.files in frontmatter

## Verification Plan

### Unit / Component Validation

- [x] `--auto-fix` applies fixes and re-lints, reporting correct counts
- [x] `--auto-fix --dry-run` does not modify any files (also works with `-n` alias)
- [x] `--fix` and `--auto-fix` produce identical results
- [x] `--auto-fix-with-agent` calls LLM query interface with structured prompt
- [x] `--model` flag is passed through to agent invocation
- [x] `--auto-fix` with zero violations exits 0 with "No violations found"
- [x] `-f` alias triggers auto-fix behavior

### Integration / E2E Validation

- [x] `ace-lint --auto-fix` on a mixed markdown+Ruby file set fixes both types and reports combined results
- [ ] `ace-lint --auto-fix-with-agent` end-to-end with a test model
- [x] `ace-lint --help` includes all new flags with descriptions

### Failure / Invalid-Path Validation

- [ ] `ace-lint --auto-fix-with-agent` without ace-llm: clear error message
- [x] `ace-lint --auto-fix-with-agent --model invalid:model`: clear error with provider hint
- [x] `ace-lint --auto-fix --format`: warning that `--format` is ignored under `--auto-fix`
- [x] `ace-lint --auto-fix-with-agent --format`: same warning that `--format` is ignored
- [x] `ace-lint --auto-fix-with-agent --dry-run`: shows deterministic fix preview AND agent prompt without launching

### Verification Commands

- [x] `ace-test ace-lint` — full test suite passes
- [x] `ace-lint --auto-fix --dry-run README.md` — shows preview without modifications
- [x] `ace-lint --help` — new flags visible
