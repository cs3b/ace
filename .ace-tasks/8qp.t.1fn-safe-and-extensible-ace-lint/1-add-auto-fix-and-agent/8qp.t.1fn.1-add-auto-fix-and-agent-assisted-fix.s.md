---
id: 8qp.t.1fn.1
status: draft
priority: medium
created_at: "2026-03-26 00:57:58"
estimate: TBD
dependencies: [8qp.t.1fn.0]
tags: [ace-lint, auto-fix, agent, doctor-pattern]
parent: 8qp.t.1fn
bundle:
  presets: [project]
  files: [ace-lint/lib/ace/lint/cli/commands/lint.rb, ace-lint/lib/ace/lint/organisms/lint_orchestrator.rb, ace-task/lib/ace/task/cli/commands/doctor.rb, ace-task/lib/ace/task/molecules/task_doctor_fixer.rb, ace-task/lib/ace/task/molecules/task_doctor_reporter.rb]
  commands: []
needs_review: true
---

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions

- [ ] **[HIGH-B1a] Agent prompt scope.** Should the agent receive full file content for files with remaining violations, or just violation context (surrounding lines + file path for agent to read more)?
  - **Research conducted:** ace-task doctor builds a formatted issue list with rules per issue type — no full file content. ace-retro doctor follows same pattern.
  - **Suggested default:** Violation context with surrounding lines, plus file path. Matches doctor pattern, controls token usage, avoids exposing full file content.
  - **Why needs human input:** Security posture (full content may include sensitive code) and token cost implications.

- [ ] **[HIGH-B1b] Dry-run scope for agent.** Should `--auto-fix-with-agent --dry-run` show the agent prompt that would be sent, without launching the agent?
  - **Research conducted:** ace-task doctor's dry-run only previews deterministic fixes, does not show agent prompt.
  - **Suggested default:** Yes, show the agent prompt for transparency. This diverges from doctor pattern but aids debugging.
  - **Why needs human input:** User-visible output format decision.

- [ ] **[HIGH-B2] Bundle.files missing QueryInterface.** `Ace::LLM::QueryInterface` is the integration point with 37 options. File exists at `ace-llm/lib/ace/llm/query_interface.rb`. Without it, implementer can't build agent integration.
  - **Resolution:** Add `ace-llm/lib/ace/llm/query_interface.rb` to bundle.files. (This can be done without human input.)

### [MEDIUM] Design Decisions with Suggested Defaults

- [ ] **[MED-B1] Consumer packages not listed.** These reference `--fix` behavior and need updating:
  - `ace-lint/docs/usage.md`, `ace-lint/docs/getting-started.md`, `docs/tools.md`
  - `ace-lint/lib/ace/lint/cli/commands/lint.rb` help text and examples
  - E2E test: `ace-lint/test/e2e/TS-LINT-001-lint-pipeline/TC-003-fix-mode.runner.md`

- [ ] **[MED-B2] `--dry-run` alias `-n` not specified.** Both ace-task doctor and ace-retro doctor use `-n` for `--dry-run`. Ecosystem consistency requires this.
  - **Suggested default:** Add `-n` alias.

- [ ] **[MED-B3] Interactive confirmation prompt.** Doctor pattern prompts "Apply fixes? (y/N):" before auto-fix. Spec shows no prompt in examples.
  - **Suggested default:** Non-interactive (matches `--fix` fire-and-forget expectation). Note divergence from doctor pattern.

- [ ] **[MED-B4] Re-lint after fix is new behavior.** Currently `--fix` on markdown returns early WITHOUT running lint (orchestrator line 117). Spec says `--auto-fix` should re-lint. This is a significant orchestrator flow change.
  - **Suggested default:** Explicitly note as new behavior in spec, flag that orchestrator control flow must change.

- [ ] **[MED-B5] `--format` + `--auto-fix-with-agent` interaction.** Spec covers `--auto-fix + --format` but not the agent variant.
  - **Suggested default:** Same rule — agent fix takes precedence, `--format` ignored with warning.

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
   - Agent receives: violation list with file paths, line numbers, messages, and relevant surrounding context
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
ace-lint --fix --dry-run README.md               # same behavior
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

Edge Cases:

- All violations fixable by `--auto-fix`: Agent is not launched for `--auto-fix-with-agent` (reports "All violations resolved")
- Zero violations found: Report "No violations found" and exit 0
- Mixed file types (markdown + Ruby): Each type uses its own fix strategy, combined report
- `--dry-run` without `--auto-fix` or `--fix`: Ignored (no effect on lint-only mode)

### Success Criteria

- [ ] `ace-lint --fix` and `ace-lint --auto-fix` produce identical behavior (fix + re-lint + report)
- [ ] `ace-lint --auto-fix --dry-run` shows preview without modifying files
- [ ] `ace-lint --auto-fix-with-agent` launches agent for remaining violations (mirrors ace-task doctor)
- [ ] `--auto-fix`, `--auto-fix-with-agent`, `--dry-run`, `--model` appear in `ace-lint --help`
- [ ] `--model` flag works for agent provider selection
- [ ] Behavioral parity with ace-task doctor's `--auto-fix` / `--auto-fix-with-agent` pattern
- [ ] `-f` alias maps to `--auto-fix` (not legacy `--fix` behavior)

### Validation Questions

- [x] **Flag naming:** `--auto-fix` / `--auto-fix-with-agent` (hyphenated, matching ecosystem convention). Confirmed.
- [x] **`--fix` aliases `--auto-fix`:** Single behavior, no separate low-level flag. Confirmed.
- [ ] **Agent prompt scope:** Should the agent receive full file content for files with remaining violations, or just violation context (surrounding lines)? Recommend: violation context with surrounding lines, plus file path for the agent to read more if needed.
- [ ] **`--dry-run` scope for agent:** Should `--dry-run` with `--auto-fix-with-agent` show the agent prompt without launching? Recommend: yes, for transparency.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type:** Subtask of orchestrator 8qp.t.1fn (depends on subtask 8qp.t.1fn.0)
- **Slice outcome:** `ace-lint --auto-fix` and `ace-lint --auto-fix-with-agent` flags working end-to-end
- **Advisory size:** Medium
- **Context dependencies:** See bundle.files in frontmatter

## Verification Plan

### Unit / Component Validation

- [ ] `--auto-fix` applies fixes and re-lints, reporting correct counts
- [ ] `--auto-fix --dry-run` does not modify any files
- [ ] `--fix` and `--auto-fix` produce identical results
- [ ] `--auto-fix-with-agent` calls LLM query interface with structured prompt
- [ ] `--model` flag is passed through to agent invocation
- [ ] `--auto-fix` with zero violations exits 0 with "No violations found"
- [ ] `-f` alias triggers auto-fix behavior

### Integration / E2E Validation

- [ ] `ace-lint --auto-fix` on a mixed markdown+Ruby file set fixes both types and reports combined results
- [ ] `ace-lint --auto-fix-with-agent` end-to-end with a test model
- [ ] `ace-lint --help` includes all new flags with descriptions

### Failure / Invalid-Path Validation

- [ ] `ace-lint --auto-fix-with-agent` without ace-llm: clear error message
- [ ] `ace-lint --auto-fix-with-agent --model invalid:model`: clear error with provider hint
- [ ] `ace-lint --auto-fix --format`: warning that `--format` is ignored under `--auto-fix`

### Verification Commands

- [ ] `ace-test ace-lint` — full test suite passes
- [ ] `ace-lint --auto-fix --dry-run README.md` — shows preview without modifications
- [ ] `ace-lint --help` — new flags visible
