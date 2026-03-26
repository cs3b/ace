---
id: 8qp.t.1fn
status: pending
priority: medium
created_at: "2026-03-26 00:57:24"
estimate: TBD
dependencies: []
tags: [ace-lint, fix, markdown, auto-fix]
bundle:
  presets: [project]
  files: []
  commands: []
needs_review: false
---

# Safe and Extensible ace-lint Fix System

## Objective

Make ace-lint's fix capabilities safe for all file types and align with the ecosystem's doctor repair pattern (`--auto-fix`, `--auto-fix-with-agent`) established in ace-task and ace-retro. Currently, `ace-lint --fix` on markdown files is destructive — Kramdown round-trip rewrites destroy frontmatter, code blocks, tables, HTML, and link styles (57 files damaged on 2026-03-23). This task makes `--fix` safe via surgical edits and adds graduated auto-fix flags.

## Scope of Work

- **User Experience Scope:** Developer runs `ace-lint --fix` on any file type and gets safe, targeted fixes. Developer uses `--auto-fix-with-agent` for LLM-assisted repair of complex violations.
- **System Behavior Scope:** Markdown fix becomes surgical (line-level edits); `--format` retains Kramdown rewrite with guardrails; new flags wire into existing doctor pattern.
- **Interface Scope:** CLI flags `--fix`/`--auto-fix` (aliased), `--auto-fix-with-agent`, `--dry-run`, `--model`, `--format`.

## Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| Surgical markdown fix (line-targeted edits) | Subtask A | -- | KEPT |
| Kramdown round-trip disabled for `--fix` | Subtask A | -- | KEPT |
| `--format` as opt-in full rewrite with guardrails | Subtask A | -- | KEPT |
| `--fix` aliases `--auto-fix` (single behavior) | Subtask B | -- | KEPT |
| `--auto-fix-with-agent` flag | Subtask B | -- | KEPT |
| `--dry-run` for fix preview | Subtask B | -- | KEPT |
| `--model` for agent provider selection | Subtask B | -- | KEPT |

## Deliverables

### Behavioral Specifications

- Safe markdown fix via surgical edits (subtask A)
- `--format` with structural integrity guardrails (subtask A)
- `--auto-fix` / `--auto-fix-with-agent` / `--dry-run` / `--model` flags (subtask B)

### Validation Artifacts

- Unit tests for surgical markdown fixer
- Integration tests for auto-fix workflow
- Regression test: `ace-lint --fix` on ace-assign markdown files produces zero structural damage

## Out of Scope

- Adding new lint checks or validators
- Changes to Ruby fix behavior (already working correctly)
- YAML fix capabilities
- Changes to `--doctor` diagnostic mode
- Performance optimization

## References

- Source ideas: 8qmowi (auto-fix options), 8qmpfo (Kramdown destructive bug)
- ace-task doctor pattern: `ace-task/lib/ace/task/cli/commands/doctor.rb`
- Ruby surgical fix model: `ace-lint/lib/ace/lint/molecules/ruby_linter.rb`
