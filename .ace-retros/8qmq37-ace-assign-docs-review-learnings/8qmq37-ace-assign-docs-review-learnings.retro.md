---
id: 8qmq37
title: ace-assign-docs-review-learnings
type: standard
tags: [docs, ace-assign, lint, readme]
created_at: "2026-03-23 17:23:33"
status: active
---

# Learnings from ace-assign Documentation Review and README Refresh

## What Went Well

- **Implementation-first review caught real issues** -- reviewing READMEs against actual CLI commands, flags, and code (not just reading the text) found concrete accuracy bugs: broken links in exit-codes.md, undocumented executables (ace-review-feedback, ace-test-e2e-sh), false protocol claims (task:// in ace-support-nav).
- **Parallel agent exploration scaled well** -- 3 agents reviewing ~13 packages each covered all 39 READMEs in one pass, each comparing README claims to implementation files.
- **Step terminology migration was nearly complete** -- the phases-to-steps rename done earlier was thorough in code. Only 4 doc lines and 2 fixture directory names were missed, easily caught by grep.
- **Gemspec summary/description update** -- caught that the gemspec still said "Phase-based" after the README was rewritten. Small but would show wrong text on RubyGems.org.

## What Could Be Improved

- **`ace-lint --fix` on markdown is destructive** -- running `ace-lint --fix` on ace-assign/ damaged 57 markdown files. Kramdown round-trip rewrites entire files: breaks YAML frontmatter, converts fenced code blocks to indented blocks with Kramdown annotations, mangles tables, escapes pipes, adds `markdown="1"` to HTML. All had to be reverted. Ruby `--fix` (StandardRB) was fine -- it makes surgical corrections. Idea captured: `8qmpfo`.
- **Logo path breaks outside monorepo** -- all 42 READMEs used relative `../docs/brand/Logo.S.png` which only works on GitHub monorepo browsing. Breaks on RubyGems.org and standalone installs. Switched to raw GitHub URL with a smaller XS JPG variant (42KB vs 489KB PNG).
- **`## Documentation` section confusion** -- the earlier plan said to add a `## Documentation` H2 section to all READMEs. The canonical template actually has NO such section (just the footer). This caused a back-and-forth where the section was added then had to be removed. Root cause: stale plan from a prior conversation context was followed without re-checking the template.
- **Lint autofix committed before review** -- Kramdown damage got committed in 2 commits (polish + spacing) before anyone noticed. Had to trace back through git log to find the clean pre-damage version and restore from there.

## Key Learnings

- **Never run `ace-lint --fix` on markdown without reviewing the diff first.** The Kramdown serializer is lossy. Use `ace-lint` (no --fix) for validation, then fix issues manually. Ruby `--fix` is safe.
- **Always verify template before adding structural sections.** The canonical template at `ace-docs/handbook/templates/project-docs/README.template.md` is the source of truth for README layout. Don't rely on plans from prior conversations -- read the template.
- **Raw GitHub URLs are required for gem READMEs with images.** Pattern: `https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/...`. Relative paths only work in monorepo GitHub browsing.
- **Gemspec summary/description should match README tagline.** After rewriting a README, always check if the gemspec needs updating too.
- **StandardRB autofix is safe but noisy.** It touches many files with style-only changes. Best committed as a separate "normalize formatting" commit so it doesn't pollute feature diffs.

## Action Items

- **stop**: Running `ace-lint --fix` on markdown files without diff review
- **stop**: Relying on stale plan context for structural decisions -- always re-read the template
- **continue**: Implementation-first README review (check exe/, cli/, lib/ against README claims)
- **continue**: Parallel agent exploration for broad cross-package reviews
- **start**: Consider adding a `--dry-run` mode to ace-lint markdown fix that shows what would change without writing (idea 8qmpfo)
- **start**: After any README rewrite, check the gemspec summary/description alignment

