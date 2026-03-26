---
id: 8qp.t.1fn.0
status: draft
priority: medium
created_at: "2026-03-26 00:57:55"
estimate: TBD
dependencies: []
tags: [ace-lint, fix, markdown, bug]
parent: 8qp.t.1fn
bundle:
  presets: [project]
  files: [ace-lint/lib/ace/lint/organisms/lint_orchestrator.rb, ace-lint/lib/ace/lint/molecules/kramdown_formatter.rb, ace-lint/lib/ace/lint/molecules/markdown_linter.rb, ace-lint/lib/ace/lint/molecules/ruby_linter.rb, ace-lint/lib/ace/lint/atoms/kramdown_parser.rb, ace-lint/test/molecules/markdown_linter_test.rb, ace-lint/lib/ace/lint/cli/commands/lint.rb]
  commands: []
needs_review: true
---

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions

- [ ] **[HIGH-A1] Should `--fix` auto-fix missing blank lines?** Missing blank line warnings (before/after headings, lists, code blocks) are structural insertions — a fundamentally different code path from typography replacement. The spec recommends "yes" but is unchecked. The implementer cannot scope the surgical fixer without this answer.
  - **Suggested default:** Yes, include them — low-risk and high-value for users.

- [ ] **[HIGH-A2] `check_markdown_style` false positives inside code blocks.** The style checker (`markdown_linter.rb:93-157`) does NOT track fenced code block state. A `# heading` inside a code block triggers "Missing blank line after heading." If the surgical fixer acts on this, it inserts blank lines inside code blocks — recreating the exact damage the task prevents.
  - **Research conducted:** Confirmed by reading `check_markdown_style` — no code block tracking. The `check_typography` method correctly tracks code blocks (line 172+), proving the pattern exists.
  - **Suggested default:** Add "fix `check_markdown_style` to track code block state" as a deliverable of this subtask. The bug also produces false lint warnings today.

- [ ] **[HIGH-A3] Trailing whitespace listed as fixable but never detected.** Spec lists "Trailing whitespace removal" as a surgical fix, but `MarkdownLinter` has zero trailing whitespace detection (searched entire ace-lint codebase).
  - **Research conducted:** No trailing whitespace check exists for markdown. Only Ruby has it via StandardRB's `Layout/TrailingWhitespace`.
  - **Suggested default:** Add trailing whitespace detection to `MarkdownLinter` as a deliverable, since it's a simple line-level check.
  - **Why needs human input:** Scope decision — adding detection expands the subtask.

- [ ] **[HIGH-A4] Exit code 2 contradiction.** Spec says "0 success, 1 remaining violations, 2 fatal errors" but `ResultReporter.exit_code` only returns 0 or 1. Exit code 2 exists only in `--doctor` path.
  - **Research conducted:** Confirmed `result_reporter.rb` line 42-44 returns only 0/1. The CLI help text at `lint.rb:38` already documents exit code 2 for "fatal error" but the main lint path never produces it.
  - **Suggested default:** Remove "2 for fatal errors" from this subtask's success criteria. The existing help text documents it; introducing it for the main path is separate scope.

### [MEDIUM] Design Decisions with Suggested Defaults

- [ ] **[MED-A1] `--fix --format` combined in single invocation.** Currently both route to kramdown. After this subtask, `--fix` = surgical and `--format` = kramdown-with-guardrails. What happens with `ace-lint --fix --format README.md`?
  - **Suggested default:** `--fix` runs surgical first, then `--format` applies kramdown-with-guardrails on the already-fixed file.

- [ ] **[MED-A2] Skill/workflow/agent file types.** `apply_formatting` (orchestrator line 269) handles `:skill, :workflow, :agent` alongside `:markdown`. Spec only mentions "markdown."
  - **Suggested default:** Same surgical treatment for all markdown-based types.

- [ ] **[MED-A3] Ordered list detection gap.** `check_markdown_style` matches unordered lists only (`*-`). Spec says "lists" without qualifying.
  - **Suggested default:** Note that only unordered lists are currently detected; expanding to ordered lists is a separate enhancement.

- [ ] **[MED-A4] `-f` alias semantics transition.** Currently `-f` → destructive kramdown rewrite. After this subtask: `-f` → safe surgical edits. Same flag, different behavior. While intentional, spec should note this.

- [ ] **[MED-A5] Exit codes imply re-lint (subtask B's deliverable).** "Exit code 1 if unfixable violations remain" requires knowing about remaining violations, which requires re-linting — that's subtask B.
  - **Suggested default:** Simplify A's exit codes to: 0 if fix succeeded, 1 if fix encountered errors. Reserve violation-counting for B.

# Make Markdown Fix Safe with Surgical Edit Model

## Objective

Fix the destructive behavior of `ace-lint --fix` on markdown files. Currently, `--fix` routes markdown through a Kramdown parse-and-serialize round-trip that rewrites entire files, destroying frontmatter, code blocks, tables, HTML structure, and link styles. This was discovered 2026-03-23 when it damaged 57 files in ace-assign/. The fix should make `--fix` for markdown work like Ruby's `--fix` — applying surgical, line-level edits to specific violations only.

## Behavioral Specification

### User Experience

- **Input:** User runs `ace-lint --fix <markdown-files>` or `ace-lint --format <markdown-files>`
- **Process (`--fix`):** Each markdown file is scanned for fixable violations. Only the specific lines containing violations are modified. The file's overall structure (frontmatter, code blocks, tables, HTML, links) is never altered.
- **Process (`--format`):** The Kramdown round-trip is applied, but with a structural integrity check before writing. If the round-trip would damage frontmatter, code blocks, tables, or HTML, the write is aborted and the user is warned.
- **Output (`--fix`):** Files are updated in place with only targeted fixes. The report shows which violations were fixed. Exit code 0 if all fixable violations corrected, exit code 1 if unfixable violations remain.
- **Output (`--format`):** Files are rewritten with Kramdown normalization if safe. If unsafe, a per-file warning is emitted and the file is skipped.

### Expected Behavior

1. `ace-lint --fix` on markdown applies surgical fixes for these specific violations:
   - **Em-dash replacement:** Replace `—` with `--` (outside code blocks and inline code)
   - **Smart quote replacement:** Replace `"` `"` `'` `'` with ASCII equivalents (outside code blocks and inline code)
   - **Trailing whitespace removal:** Remove trailing spaces/tabs from lines
   - **Missing trailing newline:** Append `\n` if file doesn't end with one
   - **Missing blank lines:** Insert blank line before/after headings, lists, and code blocks where the linter reports them missing

2. `ace-lint --fix` on markdown does **NOT**:
   - Reparse and serialize the entire file through Kramdown
   - Alter YAML frontmatter in any way
   - Convert fenced code blocks to indented blocks
   - Change link styles (inline vs. reference)
   - Escape pipe characters
   - Add Kramdown annotations (`{: .language-*}`)
   - Modify HTML structure or attributes
   - Modify content inside fenced code blocks or inline code spans

3. `ace-lint --format` retains Kramdown behavior but adds structural integrity pre-check:
   - Before writing, compare original vs. formatted content for structural damage signatures
   - If frontmatter would be altered (compare frontmatter section pre/post), skip file and warn
   - If fenced code block count changes, skip file and warn
   - If table row count changes, skip file and warn
   - If HTML blocks would gain new attributes, skip file and warn

4. Ruby `--fix` behavior is completely unchanged.

### Interface Contract

```bash
# Surgical fix — safe for all markdown files
ace-lint --fix README.md docs/**/*.md
# Fixes specific violations only, never alters structure
# Exit 0: all fixable violations corrected
# Exit 1: some violations remain (unfixable by --fix)

# Full Kramdown rewrite — opt-in, with safety guardrails
ace-lint --format README.md
# "Formatted: README.md" or "Skipped: README.md (structural change detected: frontmatter, code blocks)"
# Exit 0: all files formatted or safely skipped
# Exit 1: formatting errors

# Combined workflow
ace-lint --fix README.md     # fix violations
ace-lint README.md           # verify remaining violations
```

Error Handling:

- File not found: Same behavior as today (error in result)
- Fix would create invalid markdown: Do not write, report as unfixable violation
- `--format` structural damage detected: Skip file, emit warning with specific damage category, continue to next file
- File with zero violations: `--fix` is a no-op (does not write identical content)

Edge Cases:

- File with only frontmatter and no body: `--fix` is a no-op
- File with nested code blocks (triple-backtick inside a code block): Surgery respects code block nesting depth
- Binary or non-UTF8 file: Skip with warning
- Em-dash inside inline code (`\`code—here\``): Not fixed (correctly skipped)

### Success Criteria

- [ ] `ace-lint --fix` on the 57 previously-damaged ace-assign markdown files produces zero structural changes (frontmatter, code blocks, tables, HTML, links all preserved)
- [ ] `ace-lint --fix` correctly fixes em-dashes and smart quotes without altering surrounding content
- [ ] `ace-lint --fix` correctly inserts missing blank lines at precise locations
- [ ] `ace-lint --fix` does not modify content inside code blocks or inline code
- [ ] `ace-lint --format` skips files where Kramdown round-trip would damage structure, with clear warning
- [ ] Ruby `--fix` behavior is completely unchanged
- [ ] Exit codes are consistent: 0 for success, 1 for remaining violations, 2 for fatal errors

### Validation Questions

- [x] **`--fix` vs `--format` semantics:** `--fix` = surgical for violations, `--format` = full rewrite with guardrails. Confirmed.
- [ ] **Missing blank line fixes:** Should missing-blank-line warnings be auto-fixable by `--fix`? These are structural insertions but low-risk. Recommend: yes, include them.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type:** Subtask of orchestrator 8qp.t.1fn
- **Slice outcome:** `ace-lint --fix` on markdown produces only surgical, line-level edits; `--format` has guardrails
- **Advisory size:** Medium
- **Context dependencies:** See bundle.files in frontmatter

## Verification Plan

### Unit / Component Validation

- [ ] Surgical fixer on content with em-dash returns content with `--`, nothing else changed
- [ ] Surgical fixer on content with smart quotes returns content with ASCII quotes, nothing else changed
- [ ] Surgical fixer on content with missing blank lines inserts blank lines at correct positions only
- [ ] Surgical fixer on content with no violations returns identical content (no mutation)
- [ ] Surgical fixer never alters frontmatter section
- [ ] Surgical fixer never alters content inside fenced code blocks
- [ ] Surgical fixer respects inline code spans (no fixes inside backticks)
- [ ] `KramdownFormatter.format_file` with structural damage detection skips file and returns warning

### Integration / E2E Validation

- [ ] `ace-lint --fix` on a file with known em-dashes and smart quotes fixes them without altering frontmatter
- [ ] `ace-lint --fix` on a file with complex structure (tables, HTML, code blocks, frontmatter) fixes only typography and whitespace violations
- [ ] `ace-lint --format` on a file with YAML frontmatter skips it when frontmatter would be damaged

### Failure / Invalid-Path Validation

- [ ] `ace-lint --fix` on a non-existent file returns error result
- [ ] `ace-lint --format` on a file where Kramdown would destroy frontmatter: file is not modified, warning emitted
- [ ] `ace-lint --fix` on a binary file: skipped with warning

### Verification Commands

- [ ] `ace-test ace-lint` — full test suite passes
- [ ] `ace-lint --fix ace-assign/**/*.md && git diff` — confirm only targeted violations changed, no structural damage
