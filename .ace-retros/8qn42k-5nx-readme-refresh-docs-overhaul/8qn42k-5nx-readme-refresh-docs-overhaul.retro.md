---
id: 8qn42k
title: "5nx Branch: README Refresh and Documentation Overhaul"
type: standard
tags: [docs, readme, quick-start, user-facing, dx]
created_at: "2026-03-24 02:42:52"
status: active
---

# 5nx Branch: README Refresh and Documentation Overhaul

Date: 2026-03-24
Context: Full documentation refresh across all 40+ ACE packages — READMEs, quick-start guide, demos, releases, and root-level positioning. Branch `5nx-readme-refresh-align-all-package-readmes-with-new-layout-patterns` with 238 commits, 1372 files changed, PR #263.
Author: mc + agents
Type: Standard

## What Went Well

- **Consistent layout pattern emerged organically and scaled.** The first few package READMEs (ace-b36ts, ace-bundle, ace-compressor) established a pattern — centered header, badges, tagline, "How It Works" numbered steps, "Use Cases" bullets — that applied cleanly to all 40+ packages without forced uniformity. Each README adapted the template to its domain while remaining scannable.

- **Root README rewrite crystallized the project pitch.** The original 53-line README listed features; the rewrite (117 lines) follows Pain → Solution → Proof → Action. Specific improvements: symptom-based problem bullets that name real developer frustrations, 4 workflow journeys with inline command examples instead of 8 abstract capability bullets, lifecycle-organized toolkit (Plan → Build → Review → Context → Secure) instead of code-taxonomy categories, and an install section that was entirely missing before.

- **Quick-start now delivers on its promise.** Fixed the incorrect `ace-overseer work-on 8r3` command to the actual `ace-overseer work-on -t 8r3` syntax. Added the "quick win" install path (ace-git-commit) before the full orchestrator stack. Tightened Section 5 (pipeline details) from prose paragraphs to a scannable bullet list. Mentioned all available presets (fix-bug, quick-implement, release-only, work-on-docs).

- **Demo recording migrated to YAML sandbox format.** VHS tapes moved from bare `.tape` scripts to `.tape.yml` with sandbox setup, scenes, and teardown — making demos reproducible and self-documenting. All GIFs were re-recorded.

- **Releases kept pace with docs.** Every package that got a README refresh also got a version bump and CHANGELOG entry. 37 chore commits tracked releases alongside 127 docs commits — no drift between docs and published versions.

- **Agent-parallel exploration worked well for the root README.** Three Explore agents ran in parallel — one reading A-G package READMEs, one reading H-Z, one analyzing the root README + vision + quick-start. Combined output gave a complete picture in ~30 seconds that would have taken sequential reading much longer.

## What Could Be Improved

- **No demo GIFs in the root README.** The package READMEs all have demos, but the root README has no animated walkthrough. The "Your First Five Minutes" section shows a code block, but a GIF of `ace-git-commit` or `ace-overseer work-on` in action would be more compelling. This is the single biggest gap in the current README.

- **Quick-start is still 273 lines.** While tighter than before (was 284), it's a big jump from a 117-line README. There's no intermediate "2-minute quickstart" for users who want to try one command without committing to a 15-minute walkthrough. The ace-git-commit install in the quick-start partially addresses this but could be its own standalone section.

- **Package count discrepancy went unnoticed for a while.** The original README said "35 packages" but the actual count is 41 directories. We caught and fixed it to "40+" but this suggests the count wasn't validated against `ls -d ace-*/` during the original docs batch.

- **Integration package READMEs are thin.** The 5 ace-handbook-integration-* packages got refreshed but their READMEs remain minimal (provider shim descriptions). Since these are the first thing a user of a specific agent platform sees, they could do more to explain the value proposition for that platform.

- **The branch accumulated 238 commits.** While each commit is well-scoped, the PR diff (20K+ insertions) is hard to review as a whole. Earlier PRs in this branch (docs batches, demo migration, test runner refactors) could have been merged separately to keep review surface manageable.

## Key Learnings

- **"Pain → Solution → Proof → Action" is the right README structure for developer tools.** Values-first positioning (the old README) appeals to people who already know they need the tool. Problem-first positioning catches people who don't know the category exists yet. For a project like ACE where the category "workflow infrastructure for coding agents" is still being defined, leading with the pain is critical.

- **Lifecycle grouping > code taxonomy for tool discovery.** Organizing the toolkit as Plan → Build → Review → Context → Secure maps to how developers think about their workflow. The old grouping (Git and security, LLM and prompts, Simulation and demos, Internals) maps to how the code is organized — useful for contributors, not for users deciding what to install.

- **One concrete command example is worth ten feature descriptions.** The inline `ace-overseer work-on -t 8r3` in the README communicates more about ACE's value than the paragraph that surrounds it. The quick-start's step-by-step commands are its strongest content.

- **Taglines matter more than you'd expect.** Changing from "CLI tools designed for developers, ready for agents" to "Workflow infrastructure for coding agents — and the developers who work with them" names the category, the audience, and the relationship in one line. The old tagline could describe any CLI tool; the new one can only describe ACE.

- **Install sections are table stakes.** The original README had no install section at all — a significant gap that was only visible in comparison. Every developer tool README needs: one command to try it, one command to install the full stack, and Ruby/Node/Python version requirement.

## Action Items

### Continue Doing

- Parallel agent exploration for large-surface research tasks — the three-agent README scan was highly efficient
- Inline command examples in every feature description (README and quick-start)
- Releasing alongside docs changes so published versions match documented behavior
- Lifecycle-based grouping (Plan/Build/Review/Context/Secure) for user-facing tool organization

### Start Doing

- Add a demo GIF to the root README showing `ace-overseer work-on` or `ace-git-commit` in action — this is the highest-impact visual gap
- Consider a "30-second quickstart" section or standalone page for users who want to try one command without the full walkthrough
- Validate package counts against filesystem (`ls -d ace-*/`) when referencing them in docs
- Enrich integration package READMEs with platform-specific value propositions

### Stop Doing

- Accumulating 200+ commits on a single branch before merging — split into thematic PRs earlier
- Using code-taxonomy groupings (by what the code is) in user-facing docs — always use workflow-phase groupings (by when you use it)

## Additional Context

- PR #263: https://github.com/cs3b/ace/pull/263
- Branch: `5nx-readme-refresh-align-all-package-readmes-with-new-layout-patterns`
- Commit breakdown: 127 docs, 37 chore, 20 refactor, 9 fix, 7 feat, 9 spec, 5 style, 2 test
- Packages touched: all 41 ace-* directories plus root docs/
- Previous retros from this branch: `98eb7f8fe spec(retro-specs): capture retrospectives from the README refresh batch`
