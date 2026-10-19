---
id: 8xhzno
status: done
title: "RFC: Per-PR flow-diagram integration (PR Lens adopt)"
tags: [rfc, ace-git, developer-experience, review]
created_at: "2026-10-18 23:46:18"
---

# RFC: Per-PR flow-diagram integration (adopt PR Lens)

> Superseded on 2026-10-19 by draft task `8xi.t.0um`, “Explain PR changes with grounded Mermaid maps.” The accepted design is plain Markdown/Mermaid in the existing PR description, with agent/code handoffs, source-grounded boundary checks and existing review integration. The PR Lens dependency, hosted assets, interactive viewer and cumulative baseline map below are historical proposals and are not implementation requirements. The pilot on PRs #391 and #383 established enough practical value to proceed with the simpler approach.

Replacement task: `.ace-tasks/8xi.t.0um-explain-pr-changes-with-grounded/8xi.t.0um-explain-pr-changes-with-grounded-mermaid-maps.s.md`.

## Summary

Every PR created or updated through the ACE workflows (`wfi://git/pr/create`, `wfi://git/pr/update`) carries an **architecture blast-radius diagram and a data-flow diagram of the change**, with per-node diff status (green = added, amber = changed, red = removed) drawn against the surrounding system. We adopt the MIT-licensed [PR Lens](https://github.com/coldteadotai/pr-lens) toolkit (CLI + renderer + agent-skill loop) instead of building a renderer ourselves, and wrap it in a new workflow fragment `wfi://git/pr/diagram` with two output surfaces:

1. **PR body** — sanitizer-safe animated SVG pair (light/dark) embedded via the existing `--body-file` description flow.
2. **nervus thread artifact** — a single-file interactive HTML (viewer + graph + geometry atlas inlined) giving full pan/zoom, clickable payload panels, and walkthroughs.

No GitHub App, no hosted dependency, no mandatory model key.

## Motivation

Today `create.wf.md` step 1 and `update.wf.md` step 1 compress the committed diff into prose. Reviewers — human and agent — reconstruct the system shape in their heads on every review. The prlens.dev demonstration shows the alternative: understand the *flow* and the *diff in the flow* before reading a line of code. That is a review artifact, not documentation, and it compounds: a committed baseline map gives every new PR longitudinal "whole codebase" context.

Value split:

- **For reviewing agents** (`as-review-pr`, independent review gate): the GraphDoc is a machine-readable map of what moved — reviewer agents can start from the graph instead of re-deriving structure from hunks, and the merge gate's "independent reviewer verdict" gets a shared structural object to verify against.
- **For human reviewers**: animated in-PR summary for orientation; one click to the interactive artifact for payload-level detail.

## Research findings (decision basis)

- PR Lens is MIT, CLI-first, BYOK, forge-capable (GitHub/GitLab/Bitbucket comment targets), works pre-PR locally.
- Pipeline: merge-base diff → LLM extraction → **strict schema validation** (git-sourced facts overwrite model output; one correction round; bounded arrays) → **byte-deterministic renderer** (custom SVG, lanes/badges/animated edges) → race-safe single updating comment; post-merge `export` → committed baseline map + patch format.
- **Agent-authored mode**: the agent that wrote the diff authors the GraphDoc itself; `pr-lens validate` closes the loop with path-level errors. No provider call; **the diff never leaves the machine**. This is our default.
- GitHub/GitLab/Bitbucket sanitize JS in PR bodies → in-PR interactivity is impossible on forges; animated SVGs (SMIL/CSS) survive. Full interactivity requires an HTML+JS surface — nervus artifacts qualify.
- Alternatives: CodeBoarding (static-analysis-first maps, complementary, possible grounding source later); Archie/visual-recap (lighter, text-derived); CodeSee (sunset — cautionary tale for heavy non-diff-centric maps). Building our own renderer duplicates the hardest 80% of an MIT codebase.

## Proposed design

### New workflow fragment: `wfi://git/pr/diagram`

Location: `ace-git/handbook/workflow-instructions/git/pr/diagram.wf.md`. Consumed as a step by both `create.wf.md` (after step 1) and `update.wf.md` (after step 1).

Steps:

1. **Ground truth**: compute the merge-base diff of the candidate SHA against `pr_provenance.base_ref`. Changed files, hunks, and SHAs come from git only — never from a model.
2. **Author**: the agent writes `.pr-lens/graph.json` (GraphDoc) from the diff it already understands. Fallback: `npx @coldtea/pr-lens-cli analyze --base <base_ref>` with a configured BYOK provider (`openai-compatible` covers DeepSeek et al.) for human-made or out-of-band changes.
3. **Validate**: `npx @coldtea/pr-lens-cli validate .pr-lens/graph.json pr-lens.yml` — fix loop closes without human intervention; failure after the loop degrades to prose-only description (never blocks PR creation).
4. **Render**: `render` → light/dark SVG pair + manifest.
5. **Attach**:
   - PR surface: embed in the description file the existing `ace-git pr create/update --body-file` already posts; re-rendered on every update (the body is rewritten idempotently by `pr update`, replacing the App's self-updating comment).
   - nervus surface: emit a single-file HTML artifact (canvas viewer + GraphDoc + geometry atlas inlined) and publish it to the delivery thread.
6. **Correct**: persistent naming/fix knowledge lives in a committed `pr-lens.yml` per repository (rename/exclude/pin/group). Generated files are never hand-edited — one write location, matching ACE state-owner rules.

### Surfaces and their guarantees

| Surface | Content | Interactive |
|---|---|---|
| PR body (any forge) | Animated light/dark SVGs, foldable drill-downs (GitHub/GitLab) | No (forge sanitizer) — by platform limit |
| nervus thread artifact | Full canvas: pan/zoom, edge→payload panels, walkthroughs | Yes |
| Self-hosted canvas (optional) | Same as nervus, on own infra | Yes |

### Post-merge baseline maps

On merge, `npx @coldtea/pr-lens-cli export` writes/advances `pr-lens.map.json` committed to the repo. Each subsequent PR is drawn against this baseline — unchanged context nodes come from the stored map, not from model memory. This is the mechanism that makes "understanding the flow" compound over time instead of restarting per PR.

### What we deliberately do NOT adopt

- **GitHub App** — hosted convenience; we own PR-body updates already via `ace-git pr update`. Checkboxes/view-switching inside the comment are the only loss.
- **Paid `analyze` as default** — agent-authored graphs keep diffs local; analyze is a BYOK fallback only.
- **Building a renderer** — MIT code exists; our engineering goes into workflow integration and artifact emission.

## Non-goals

- No new ACE state: `.pr-lens/` is scratch (gitignored by the CLI), `pr-lens.yml` + `pr-lens.map.json` are the only committed files.
- No CI gating — diagrams are review aids; the merge gate remains executed tests + independent review.
- No static-analysis grounding pass in v1 (CodeBoarding-style evidence injection into GraphDoc is a possible later extension).

## Open questions

1. **Forge asset hosting for SVGs**: orphan branch à la GitHub Action vs MR attachments (GitLab) vs links-only on forges where hosting is awkward. Needs one decision per forge adapter (`ace-git-github`, `ace-git-forgejo` — note Forgejo has no pr-lens target; SVG links + body embedding must be verified there).
2. **Node runtime dependency**: pr-lens CLI needs Node ≥ 20.11. ACE is Ruby-first; decide between npx-on-demand, a pinned dev dependency, or agent-side invocation only.
3. **Artifact size caps**: monorepo-scale GraphDocs can produce multi-MB single-file HTML; define a degradation threshold (views/nodes caps already exist in the schema).
4. **Reviewer-agent contract**: define how `as-review-pr` consumes the GraphDoc (prompt section? file reference?) so the review gate benefits structurally, not just cosmetically.
5. **nervus artifact sandbox verification**: confirm `allow-scripts` iframe/CSP so the canvas viewer runs.

## Rollout

1. Spike: run the CLI loop manually on one real ACE PR (this repo); validate agent-authored mode end-to-end.
2. Land `diagram.wf.md` + create/update integration behind per-repo opt-in (presence of `pr-lens.yml`).
3. Add nervus artifact emission; verify sandbox.
4. Add baseline-map export on merge; flip default to on for ACE repos.
5. Extend `as-review-pr` to consume the GraphDoc.

## Alternatives considered

- **Build our own** (static-analysis graph + custom renderer): rejected — duplicates the hardest parts (schema contract, deterministic animated renderer, race handling, patch-format maps) of an MIT codebase.
- **CodeSee-style full-system maps**: rejected — CodeSee's shutdown is the cautionary tale; diff-centric blast radius is the proven PR-value shape.
- **Mermaid-in-PR-body**: rejected — static, no diff coloring/badges/payloads, layout instability.
- **GitHub App only**: rejected — hosted dependency, no agent control, loses forge neutrality.

## References

- Repo: https://github.com/coldteadotai/pr-lens · Site: https://prlens.dev · Rationale: https://www.coldtea.ai/blog/reducing-cognitive-load-ai-generated-prs
- Agent skill package: `packages/agent-skill` (SKILL.md loop: author → validate → fix → render → attach)
- Canvas self-hosting: `docs/canvas-api.md`
