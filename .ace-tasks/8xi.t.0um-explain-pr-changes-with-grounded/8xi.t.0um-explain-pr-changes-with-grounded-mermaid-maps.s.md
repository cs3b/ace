---
id: 8xi.t.0um
status: draft
priority: medium
created_at: "2026-10-19 00:34:01"
estimate: TBD
dependencies: []
tags: [ace-git, ace-review, developer-experience, workflow]
bundle:
  presets: [project]
  files:
    - ace-task/handbook/workflow-instructions/task/draft.wf.md
    - ace-task/handbook/workflow-instructions/task/plan.wf.md
    - ace-task/handbook/workflow-instructions/task/review.wf.md
    - ace-git/handbook/workflow-instructions/git/pr/create.wf.md
    - ace-git/handbook/workflow-instructions/git/pr/update.wf.md
    - ace-review/handbook/workflow-instructions/review/pr.wf.md
    - .ace-tasks/8xi.t.0um-explain-pr-changes-with-grounded/ux-usage.md
    - .ace-tasks/8xi.t.0um-explain-pr-changes-with-grounded/examples/pr-391.md
    - .ace-tasks/8xi.t.0um-explain-pr-changes-with-grounded/examples/pr-383.md
  commands: []
---

# Plan and review change impact with grounded Mermaid maps

## Objective

Make task impact easier for humans and agents to reason about both before and after implementation. Use ordinary Markdown, rendered as Mermaid where supported, to explain current behavior, proposed changes and actual changes, then compare expected impact with observed impact. Expose affected boundaries and high-level mistakes early and make implementation deviations visible during PR review.

The source-grounded pilot on PRs #391 and #383 demonstrated practical value: it made agent instructions versus runtime enforcement, prompt handoffs, state ownership, and outcome-versus-delivery ordering explicit. The user accepted this evidence as sufficient to adopt the simple approach now and improve through use. Further comparative research or a quantified productivity claim is not a prerequisite.

This replaces the PR Lens adoption proposal. The deliverable is one lightweight analysis technique carried through task drafting/review/planning and PR create/update/review. The before-and-after comparison is qualitative and source-grounded; it requires no analytics service or graph-diff engine.

## Behavioral specification

### User experience

- **Input:** before implementation, the task intent and inspected current code/Markdown at an identified revision; after implementation, the selected proposed map/plan reference, exact candidate and base, committed diff, and relevant surrounding sources.
- **Process:** explain current → proposed behavior, review its expected impact, then derive current → implemented behavior from the candidate and compare it with the proposal. Humans and agents use the same Markdown and source references.
- **Output:** a clearly labeled `Proposed change map` in existing task/plan output and one current `Change map` section in the PR description. The PR section contains the actual behavioral delta, candidate SHA, a Mermaid diagram when useful, a small boundary table, and a concise proposed-versus-actual comparison.

### Expected behavior

1. Include a map when the change affects interactions between components, state ownership, ordering/failure behavior, or agent instructions governing execution. Markdown-only changes qualify when they alter behavior. Trivial edits such as spelling or version metadata use concise prose without a compulsory diagram or empty map section.
2. Explain what changed and show only the surrounding context necessary to understand it. Identify added/changed behavior and distinguish existing context through readable labels or adjacent prose; color is optional and never carries meaning alone.
3. Make actors explicit: human/agent, CLI, subprocess, instruction or prompt source, and persisted state when relevant. Distinguish resolving a Markdown reference, loading prompt content, printing a brief, invoking a model, and executing a command. Show existing/implemented operations only when supported by source; clearly mark proposed operations as intent with a requirement or plan reference. A prompt does not imply a model invocation.
4. Label meaningful arrows with verbs such as resolves, prints, reads, invokes, writes, or delivers. For flowcharts, use labeled dashed arrows for instructions an agent follows and solid arrows for execution/data transfer, with a short legend. Sequence diagrams retain normal call/return notation and explicitly identify instruction handoffs in text or notes.
5. Prefer one overview with roughly 5–10 meaningful nodes as a readability guide. Add one focused sequence or flow only when it explains important ordering, retry, or failure behavior missing from the overview. Do not force a diagram per package or per changed file. State significant changed behavior outside the chosen view briefly in prose.
6. Accompany the map with a short table of relevant boundaries: contract/invariant, concrete review question, and supporting source or test reference. Ground current-state relationships in the inspected revision and implemented relationships in the actual candidate; distinguish proposed relationships and their assumptions. Use immutable source links where supported. Keep expected behavior and historical/reported validation distinct from checks actually executed.
7. On PR creation, include the map in the prepared description before the existing publication operation. On update, replace the existing section rather than appending another. A changed candidate requires source revalidation and refreshed provenance; unchanged behavior may retain its diagram after revalidation. Description/evidence-only updates at the same candidate do not require unnecessary regeneration.
8. Reviewing agents receive the current map as part of the existing PR review context and use it to orient checks for omitted components, ownership, contract mismatches, ordering and failure paths. Verify the author's claims against the source. Actual requirements and changes still define review scope; a diagram is not independent review evidence or a coverage certificate.
9. If a relationship cannot be established, say it is unknown or omit the unsupported claim. If a useful current diagram cannot be produced or rendered, use a concise current textual explanation with the limitation stated. Remove any stale diagram rather than carrying it forward as current. Diagram availability does not add a PR/merge gate.


10. Before implementation, describe the relevant current flow and explicitly proposed changes, recording the inspected revision, task/plan reference, assumptions and unknowns. Review the impact on consumers, state owners, CLI/prompt/instruction handoffs, contracts, failure/retry paths and verification needs. Task review uses this view to challenge omissions and scope; JIT planning refines it against current sources. Do not invent implementation facts or force a technical plan into a behavioral draft.
11. After implementation, rebuild or revalidate the actual flow from the candidate and compare it with the selected pre-implementation proposal. Use a compact table: `Boundary / proposed impact / actual impact / difference and evidence`. Summarize matched behavior briefly; emphasize missing intended behavior, unplanned effects, changed assumptions and justified design adjustments. Keep recognizable actor/boundary names where still accurate; diagram layout differences are not behavioral differences.
12. Preserve the proposal's identity and distinguish original intent from later accepted revisions; do not rewrite the before view to make the implementation appear to match. Explain material deviations and whether they satisfy the task or need follow-up. A mismatch prompts source/requirement checks, not an automatic rejection. When no recoverable proposal exists, state `Before/after comparison unavailable: no recorded proposal` and review actual impact normally; never reconstruct a retrospective proposal and present it as prior intent. Changes to task intent or candidate require revalidation of the comparison as well as the map.

## Interface contract

The existing `/as-task-draft`, `/as-task-review`, `/as-task-plan`, `/as-git-pr-create`, `/as-git-pr-update`, and `/as-review-pr` experiences gain this behavior. Their existing forge selection, exact-candidate checks, publication permissions, test requirements and independent review rules continue to apply. No new command, flag, configuration key or required dependency is introduced.

Before implementation, the map belongs in existing task specification/review or plan output, according to that workflow's existing ownership rules. `/as-task-plan` continues to return inline output with persistence handled by its caller; it does not write the task spec. Preserve a reference to the selected pre-implementation proposal through existing artifacts or Git history so comparison does not depend on silently overwriting intent. Do not add a new store or require automatic synchronization of task and PR documents.

After implementation, the normal publication surface is the PR body through the existing description flow. A body contains at most one current `Change map` section. Agents consume the same Markdown text; there is no separate graph representation or reviewer-only map. On a forge without native Mermaid rendering, the prose/table and readable diagram source remain usable; hosted images and forge-specific renderers are outside this task.

The comments posted to #391 and #383 are an explicitly authorized pilot, not a new automatic-comment workflow. Existing PR discussion is not rewritten by this feature.

See `ux-usage.md` for concrete before/after comparison, PR update and review scenarios.

## Success criteria

- [ ] Task review/planning exposes the current flow, proposed changes, affected consumers/owners, failure paths and verification needs, clearly separating source facts from intent and assumptions.
- [ ] The PR comparison identifies both missing intended behavior and unplanned effects, with evidence and explanations for justified adjustments; matched behavior is summarized concisely.
- [ ] The selected before proposal remains identifiable through existing artifact references or Git history and is not silently rewritten to match the implementation.
- [ ] Missing proposal evidence is reported explicitly without inventing prior intent or blocking ordinary review; trivial tasks remain prose-only at both stages.

- [ ] A behavioral Markdown-only change like #391 produces a map that attributes the change to agent instructions and identifies the pre-existing test-runner behavior accurately.
- [ ] A cross-package change like #383 shows the brief-to-agent handoff, state owners and reporting boundaries without implying a new runtime scheduler or model call.
- [ ] A second diagram is used only when it adds useful ordering/failure information, demonstrated by the report-ID-before-send sequence.
- [ ] Both human-facing output and reviewing-agent context contain the same current map, provenance, boundary checks and supporting references.
- [ ] Updating a changed candidate refreshes/revalidates its map and leaves exactly one current section; stale or ungrounded diagrams are removed or corrected.
- [ ] Trivial changes remain concise, while meaningful Markdown workflow changes are eligible for diagrams.
- [ ] Missing evidence or rendering failure yields an explicit, current prose explanation without blocking normal PR delivery or claiming successful rendering.
- [ ] Ordinary Mermaid blocks render on GitHub; meaningful labels and arrow semantics remain readable in source form.
- [ ] No PR Lens/Node dependency, asset publication service, repository-wide architecture baseline, new state owner, graph schema, or extra review gate is introduced.

## Scope and exclusions

Includes task impact analysis before implementation, comparison against actual impact during PR preparation/review, the existing PR description preparation/update experience, concise author/reviewer guidance, and the two accepted pilot examples as post-implementation acceptance references. The historical pilots do not establish that pre-implementation comparison has already been exercised.

Excludes interactive viewers, animations, payload inspectors, HTML/Nervus artifacts, uploaded SVGs, repository-wide architecture baselines, automatic graph comparison/extraction, custom renderers, JSON graph documents, an additional CLI, a scheduler, default comments on every PR, new opt-in configuration, and a benchmark project. Improve the wording and examples through normal use; future enhancements require separately justified scope.

## Vertical slice

**Standalone task; advisory size: medium.** One complete slice: explain proposed impact, review its assumptions, derive actual impact from the implementation, and compare the two in the existing PR workflow. This is one change-analysis lifecycle; no separate analytics product or child capability is introduced.

Fresh-session context is listed explicitly in the frontmatter bundle. The archived idea is historical rationale only; its old design and rollout are superseded by this spec.

## Verification plan

- **Component/equivalent checks:** inspect author/reviewer guidance for the same eligibility, notation, provenance and fallback rules. Check the two supplied examples against their pinned source; do not invent a parser or implementation-mirroring tests for prose.
- **Before/after integration:** walk one representative task through draft/review/planning and PR preparation with an identifiable proposal. Include one matched boundary, one missing planned behavior and one unplanned consumer impact. Verify that humans and reviewing agents receive the comparison, source evidence and reasons for any accepted change. Confirm proposed state ownership and instruction-versus-runtime assumptions are challenged before work starts, and that planning retains its existing inline-output/persistence contract.
- **Comparison failures:** missing proposal produces the explicit unavailable note; revised intent identifies which proposal is being compared; a changed candidate refreshes the comparison. Reworded labels or Mermaid layout alone must not be reported as behavioral drift. A justified deviation is explained rather than automatically rejected.
- **Integration:** exercise existing description preparation and reviewer-context preparation with the two pilot scopes; verify the map survives the existing body-file path and reaches the reviewer as readable Markdown. Confirm the reviewer can distinguish a printed brief from agent execution and work outcome from delivery outcome.
- **Update:** prepare an updated candidate with changed behavior and repeat description preparation. Confirm one refreshed map section, current references and preserved non-map description content. Same-head evidence updates retain valid maps without duplicate sections.
- **Failure/invalid cases:** an unverified edge is marked unknown or omitted; a stale candidate map is refreshed or removed; invalid Mermaid is repaired or replaced by current prose; a spelling-only change produces no compulsory map. An author claim is not accepted as a reviewer verdict.
- **Rendering:** inspect the actual GitHub pilot comments, including the sequence diagram and normal flowcharts. Record what was observed. Use the existing artifact/review flow; no new renderer infrastructure is required.
- **Commands/checks:** use `bin/ace-bundle` for the affected workflows; if executable code changes prove necessary, run the appropriate `bin/ace-test` / `bin/ace-test-suite` checks. Drafting itself adds no runtime code and runs no package suites.

## Validation decisions

Behavioral choices are settled for this draft: analysis before and after implementation, preserved proposal provenance, a qualitative proposed-versus-actual comparison, conditional maps, one overview by default with one optional detail per stage, a single current PR-body section, raw Markdown for agents, source verification, non-blocking prose fallback, and no additional infrastructure. Task review may refine clarity; it should not reopen the rejected adoption scope without new requirements.

## References

- [Draft usage](ux-usage.md)
- [Small accepted example](examples/pr-391.md)
- [Large accepted example](examples/pr-383.md)
- [Pilot evidence](pilot-evidence.md)
- [Posted #391 comment](https://github.com/cs3b/ace/pull/391#issuecomment-6257146226)
- [Posted #383 comment](https://github.com/cs3b/ace/pull/383#issuecomment-6257148020)
- Archived source idea: `.ace-ideas/_archive/8x/y/8xhzno-rfc-per-pr-flow-diagram/8xhzno-rfc-per-pr-flow-diagram-integration-pr.idea.s.md` (superseded).
