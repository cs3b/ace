---
id: 8vb.t.ey3.1
status: draft
priority: medium
created_at: "2026-08-12 09:58:02"
estimate: TBD
dependencies: []
tags: []
parent: 8vb.t.ey3
bundle:
  presets:
  - project
  files:
  - docs/quick-start.md
  - docs/tools.md
  - ace-support-core/.ace-defaults/project-root/AGENTS.md
  - ace-support-core/.ace-defaults/project-root/CLAUDE.md
  - ace-support-core/.ace-defaults/project-root/docs/tools.md
  commands:
  - ace-config sync ace-support-core
  - ace-handbook sync
---

# Make quick-start default to AGENTS and agents

## Behavioral Specification

### User Experience

- **Input:** A developer opens `docs/quick-start.md` to set up ACE in a new or existing repository.
- **Process:** The default walkthrough installs gems, syncs config, seeds root `AGENTS.md` (+ `docs/tools.md`), and projects skills to `.agents/skills/`, then verifies readiness.
- **Output:** The project is agents-ready without reading harness-specific projection docs. Optional Claude/Codex/etc. setup lives in a separate document linked once from quick-start.

### Expected Behavior

`docs/quick-start.md` presents the **default** setup path as:

1. Install gems
2. Sync needed provider/config packages
3. Sync `ace-support-core` so root **`AGENTS.md`** (and `docs/tools.md`) exist
4. Run `ace-handbook sync` → **`.agents/skills/`**
5. Verify with doctor / bundle / provider listing as already documented

Rules:

- Harness-native trees (`.claude/skills`, `.codex/skills`, …), `CLAUDE.md`-as-primary guidance, and `ace-handbook-integration-*` installs are **not** first-viewport / peer-default setup content.
- A separate doc named `docs/agent-harnesses.md` holds optional other-agent / provider projection setup; quick-start links to it once.
- Starter language matches principles-first templates: `AGENTS.md` is the main instruction file; `CLAUDE.md` (if generated) is a thin pointer, not a parallel primary guide.
- Syncing `ace-support-core` for `AGENTS.md` is part of the **default** path, not an optional afterthought beside harness trees.

### Interface Contract

```bash
# Default path (documented in docs/quick-start.md):
bundle exec ace-config sync ace-support-core
# Expected documented outcome: root AGENTS.md (+ docs/tools.md); CLAUDE.md only as thin pointer if present

bundle exec ace-handbook sync
# Expected documented outcome: .agents/skills/ as the default projection

# Optional (docs/agent-harnesses.md only):
bundle exec ace-handbook sync --provider <harness>
# Expected: harness-native skill tree; not required for default setup
```

Error Handling:

- Quick-start must not imply that missing harness projections block default readiness.
- If a reader needs Claude/Codex-native trees, the harness doc gives the explicit provider sync path.

Edge Cases:

- Full-stack vs minimal gem install lists may still differ for workflow packages, but agent-surface guidance stays agents-first in both.
- Existing customized `AGENTS.md` preservation/`--force` semantics are unchanged; this slice is documentation orientation.

## Success Criteria

- A reader can complete default setup without reading harness docs.
- Searching quick-start no longer presents Codex/Claude skill trees as peer defaults beside `.agents/`.
- `docs/agent-harnesses.md` exists and is the home for optional provider projection guidance.
- Quick-start language aligns with principles-first `AGENTS.md` as the main instruction file.

## Validation Questions

- None open. Separate harness doc name locked to `docs/agent-harnesses.md`.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Quick-start default path is cleanly agents-first; other agents are optional and separate
- **Advisory size:** Small–medium
- **Context dependencies:** `docs/quick-start.md`, `docs/tools.md`, `ace-support-core` project-root starters

## Verification Plan

### Unit/Component Validation

- Doc review checklist: default install section mentions `AGENTS.md` + `.agents/skills/` as primary; no peer-default harness trees in that section.
- Confirm `docs/agent-harnesses.md` covers provider sync and is linked from quick-start once.
- Align any bootstrap/doctor string assertions only if quick-start or starter wording they assert changes.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Not required unless quick-start fixtures embed outdated harness-first wording.

### Failure/Invalid Path Validation

- N/A for docs-first slice beyond checklist (harness doc missing would fail the success criteria).

### Verification Commands

- Manual/doc review of `docs/quick-start.md` and `docs/agent-harnesses.md`
- Existing `ace-test` targets only if starter/bootstrap assertions must track wording

## Objective

Make first-use documentation present `.agents/` + `AGENTS.md` as the default ACE agent setup path, with other harness guidance optional and separate.

## Scope of Work

- Reorient `docs/quick-start.md` default path
- Add `docs/agent-harnesses.md` for optional provider/harness setup
- Keep starter semantics aligned with principles-first `AGENTS.md`

## Deliverables

### Behavioral Specifications

- This subtask contract

### Validation Artifacts

- Doc review checklist results during implementation

## Out of Scope

- Shipping release WFI baselines (owned by `8vb.t.ey3.0`)
- Changing handbook sync default projection away from `.agents/skills/`
- Redesigning assign/overseer walkthrough content beyond agent-setup orientation

## References

- Parent `8vb.t.ey3`
- https://github.com/cs3b/ace/issues/310 (umbrella)
- `../ux-usage.md`
