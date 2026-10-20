# Before-and-after change impact maps — draft usage

## API surface

- [x] Agent API: existing task draft/review/plan and PR create/update/review workflows.
- [ ] New CLI commands or flags.
- [ ] New developer API.
- [ ] New configuration.

## Scenario 1: plan impact, then compare with the implementation

**Goal:** humans and agents spot missing boundaries before work and unexpected impact after work.

Use `/as-task-draft` and `/as-task-review` for the behavioral proposal, then `/as-task-plan` for the reviewed task. For a hypothetical reporting change, the proposed map identifies the current state owner and proposes saving the event identity before sending, with delivery retries reusing that identity. Record the inspected revision and proposal reference, affected consumers, assumptions and verification needs. Task review checks whether the intended CLI → agent → reporting handoffs and failure paths are complete.

Planning returns its proposed map within normal inline plan output; its caller handles existing persistence. The planning workflow does not write the task spec or introduce a map store.

After implementation, invoke `/as-git-pr-create` with the existing task/candidate/forge context and the selected proposal reference.

**Expected output:** one `Change map` section shows the actual flow, candidate SHA, source references and a compact comparison. For example, if saving identity matches the proposal but retries unexpectedly allocate another ID, the comparison calls out that difference and its duplicate-delivery consequence. A newly affected notification consumer is also recorded even if absent from the proposal. Accepted design adjustments include their reason; missing behavior remains visible.

The original proposal remains identifiable. The actual map is checked against code and Markdown, rather than copied from the plan. For a change like #391, it identifies agent guidance and existing runner behavior without implying an atomic runtime guard. Spelling-only tasks use concise prose at both stages.

## Scenario 2: update after behavior changes or evidence becomes unavailable

**Goal:** the explanation remains current as the PR evolves.

Invoke `/as-git-pr-update` with the existing PR identity and a new committed candidate.

**Expected output:** the author revalidates the diagram and proposed-versus-actual comparison against that candidate, updates meaningful changes and source links, and replaces the existing section. The prepared description contains one current map, not an appended history of maps. A same-head evidence-only update can retain the valid diagram. If intent changed, name the selected revised proposal and explain the material change without silently overwriting original intent.

If a relationship is unsupported or Mermaid cannot be made usable, the section gives a current textual explanation and a short limitation, such as `Diagram omitted: the retry handoff could not be verified from this candidate.` It does not publish a stale or invented edge. Normal delivery continues under the existing rules.

If the earlier proposal is unavailable, state `Before/after comparison unavailable: no recorded proposal`. Continue reviewing actual behavior; do not manufacture a historical plan.

## Scenario 3: review a cross-package PR

**Goal:** the reviewing agent quickly locates high-level boundaries while retaining independent judgment.

Invoke `/as-review-pr` for a change like #383.

**Expected experience:** the existing review context includes the PR's current Markdown map. The reviewer can trace prepared config → brief → executor agent → assignment commands, and inspect a focused reporting sequence where outcome is persisted and event identity is retained before sending. The boundary table points to source and representative tests.

The reviewer compares the selected proposal with actual impact, checking both whether intended behavior was delivered and whether the implementation affects unplanned consumers or contracts. Claims, missing paths, state ownership and retry semantics are verified against the actual diff and code/instructions. Mermaid layout changes are not behavioral differences, and a justified design adjustment is not automatically a defect.

The map cannot narrow review scope or substitute for executed tests or an independent verdict. If absent or stale, review still proceeds from the actual candidate and notes the limitation where relevant.

## Notes for implementation

The two examples and posted GitHub comments are post-implementation acceptance references; the hypothetical before/after scenario above still needs to be exercised. Complete normal workflow usage documentation during task execution. Reuse the same Markdown technique across stages; add no renderer, graph store, graph-diff engine or standalone publishing path.
