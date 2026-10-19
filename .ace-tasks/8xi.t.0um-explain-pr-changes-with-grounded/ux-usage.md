# Grounded PR change maps — draft usage

## API surface

- [x] Agent API: existing PR create/update/review workflows.
- [ ] New CLI commands or flags.
- [ ] New developer API.
- [ ] New configuration.

## Scenario 1: create a PR for a behavioral workflow change

**Goal:** a human and reviewer agent understand an instruction-level change without mistaking it for a new code guard.

Invoke `/as-git-pr-create` with the existing task/candidate/forge context for a change like #391.

**Expected output:** the normal description includes one `Change map` section with the behavioral delta, candidate SHA, Mermaid flowchart, and a small boundary table. The map shows `drive.wf.md` instructing an agent to check `ace-assign status` before finishing; it labels the existing hermetic runner as existing context. It does not claim that Markdown creates an atomic runtime guard. Relevant references point at the candidate source.

For a spelling-only change, the same invocation produces a concise description without a compulsory diagram. No new configuration is needed.

## Scenario 2: update after behavior changes or evidence becomes unavailable

**Goal:** the explanation remains current as the PR evolves.

Invoke `/as-git-pr-update` with the existing PR identity and a new committed candidate.

**Expected output:** the author revalidates the diagram against that candidate, updates meaningful changes and source links, and replaces the existing section. The prepared description contains one map, not an appended history of maps. A same-head evidence-only update can retain the valid diagram.

If a relationship is unsupported or Mermaid cannot be made usable, the section gives a current textual explanation and a short limitation, such as `Diagram omitted: the retry handoff could not be verified from this candidate.` It does not publish a stale or invented edge. Normal delivery continues under the existing rules.

## Scenario 3: review a cross-package PR

**Goal:** the reviewing agent quickly locates high-level boundaries while retaining independent judgment.

Invoke `/as-review-pr` for a change like #383.

**Expected experience:** the existing review context includes the PR's current Markdown map. The reviewer can trace prepared config → brief → executor agent → assignment commands, and inspect a focused reporting sequence where outcome is persisted and event identity is retained before sending. The boundary table points to source and representative tests.

The reviewer checks claims, missing paths, state ownership and retry semantics against the actual diff and code/instructions. The map cannot narrow review scope or substitute for executed tests or an independent verdict. If absent or stale, review still proceeds from the actual candidate and notes the limitation where relevant.

## Notes for implementation

The two examples and posted GitHub comments are acceptance references. Complete normal workflow usage documentation during task execution. Keep this a small addition to existing experiences; add no renderer, graph store or standalone publishing path.
