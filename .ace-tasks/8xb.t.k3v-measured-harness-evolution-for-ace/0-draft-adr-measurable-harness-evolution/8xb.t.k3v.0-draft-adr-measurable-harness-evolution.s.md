---
id: 8xb.t.k3v.0
status: draft
priority: medium
created_at: "2026-10-12 13:24:26"
estimate: S
dependencies: []
tags: []
parent: 8xb.t.k3v
bundle:
  presets: ["project"]
  files:
    - ".ace-tasks/8xb.t.k3v-measured-harness-evolution-for-ace/research-harness-learning-paper-and-gap-map.md"
  commands: []
---

# Draft ADR measurable harness evolution

## Behavioral Specification

### User Experience

- Input: the research file in the parent task folder (paper analysis + gap map) and existing ADR corpus.
- Process: run `as-docs-create-adr`; write the decision, mark it active, add the actionable section to `docs/decisions.md`.
- Output: a new ADR ("Measured Harness Evolution") that any agent or developer can read before proposing a harness change.

### Expected Behavior

The ADR establishes, at decision level (not implementation):

1. **One harness revision per cycle**: a proposer (human or agent) proposes a single workflow/skill edit at a time; mass rewrites of the handbook are out of policy.
2. **Fresh-task validation**: a harness revision is adopted only when validated against fresh tasks, not the tasks that motivated it.
3. **Cascade promotion** (ADR-022): validated revisions promote through gem defaults → user → project levels.
4. **Evidence gate** (ADR-032 spirit): completion requires rerun evidence on the failure surface the revision claims to fix.
5. Cites arXiv:2609.35738 as motivation: single-round harness revisions improve reliably; multi-round compounding does not, hence the one-revision-per-cycle rule.

## Success Criteria

- New ADR file exists under `docs/decisions/`, status active, numbered next in sequence.
- `docs/decisions.md` gains a corresponding actionable RULE/FACT section.
- The decision covers all four points above with explicit defaults where behavior could be ambiguous.

## Verification Plan

- Unit-equivalent: `ace-lint docs/decisions.md` passes; ADR frontmatter follows existing ADR conventions.
- Review check: cross-reference that each gap-map gap (1–4) is governed by some clause of the ADR.

## Validation Questions

- ADR number and final title (next free number at implementation time).
- Should the one-revision-per-cycle rule allow exceptions via explicit human approval?
