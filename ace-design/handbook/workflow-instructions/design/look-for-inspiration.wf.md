---
doc-type: workflow
name: design-look-for-inspiration
description: Research design evidence and prepare a tested proposal for review
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - WebFetch
  - WebSearch
title: Curate design inspiration for review
purpose: Curate design inspiration for review
ace-docs:
  last-updated: 2026-10-16
  last-checked: 2026-10-16
---

# Curate design inspiration for review

## Goal
Convert useful new design evidence into a small, tested package change for review without automatically merging or publishing it.

## Prerequisites
Access to the ace-design source checkout and internet research. Accept optional `--surface shared|site|app`; reject other values before writing artifacts. Omission considers all surfaces. This workflow can be invoked manually or by a separately configured weekly scheduler. It does not create a schedule by itself. External services such as Mobbin/Figma/Stitch are optional; absence must not block local research and catalog maintenance.

## Project Context Loading
Read the existing catalog, the source ledger, prior proposals and package tests. Establish the previous checked revision/date per source. If no prior state exists, create a baseline rather than claiming everything is new. Keep research scope small: at most five credible changes per run.

## Process Steps
1. **Find meaningful changes.** Check primary repositories, release notes, official design systems and accessibility standards. Seed sources include Taste, Impeccable, UI UX Pro Max, Anthropic frontend-design, Playwright and W3C WAI. Record URL, observed date, commit/tag when applicable, license and a precise claim. Compare with the previous ledger revision. Research popularity is not proof of better design; reject unsupported benchmark claims, universal style bans and copying third-party assets/code without suitable licensing.
2. **Select by benefit.** For each candidate explain the problem it solves, surface (`shared`, `site`, `app`), use/avoid conditions and compatibility with fast exploration. Dedupe against existing cards. Reject generic trends without a testable use case. Keep the core local and make service integrations optional. If no candidate passes, update only the checked-source ledger and return a concise no-change result; a scheduler should stay quiet for non-actionable unchanged state.
3. **Prepare a concrete patch.** Use an isolated branch/worktree where available. Change only relevant catalog cards, workflows or templates; never edit active user mockups or silently change installed skills. A card requires frontmatter `id`, `surface`, `title`, `use_when`, `avoid_when`, `source` (http(s) URL), `verified_at` (ISO date), and explanatory body. Record license and revision in body/ledger where relevant. Keep short skill entry points and place detail in shared workflows/cards. Update embedded template and source together if changed.
4. **Validate the proposal.** Run `ace-design validate --catalog PATH` and the relevant package tests. For changed process/design guidance compare baseline and candidate on the six packaged benchmark briefs (three site and three app), same fixtures per brief and same environment. Generate or inspect actual mockups; record time to first comparable variants, distinct hierarchy/composition, shared-data compliance, visual usefulness and feedback effort. For narrowly scoped guidance select applicable cases and explain exclusions; do not claim the full matrix ran. Never fabricate measurements or use a model's self-rating as proof. If execution is unavailable, mark proposal experimental with unexecuted checks and do not call it validated.
5. **Submit for review.** Produce `proposal.md`: source changes, rationale, exact patch summary, before/after evidence, executed checks, tradeoffs, rejected candidates and suggested accept/reject decision. Obtain independent review and resolve verified findings when review tooling is available; otherwise explicitly mark review pending. Present the local diff/commit or an authorized draft PR for the maintainer to review. Do not merge, publish a gem, install the modified skills globally, or promote experimental advice automatically. Update ledger with checked revisions and proposal path; preserve previous entries.

## Success Criteria
Run either reports no actionable change with updated ledger or leaves a concrete reviewable patch with provenance, validation evidence and honest pending checks. No automatic merge/publish occurs.

## Error Handling
Unavailable source: retain last successful revision, record error and continue other sources; never overwrite it with a failed fetch. Unknown license: summarize ideas in original language, link source, avoid copying code/assets. Conflicting advice: preserve context-specific alternatives rather than asserting one universal rule. Scheduler repeats should dedupe by source revision and proposal status.
