---
id: 8xf.t.e1q.2
status: done
priority: medium
created_at: "2026-10-16 09:22:08"
estimate: TBD
dependencies: [8xf.t.e1q.0]
tags: []
parent: 8xf.t.e1q
bundle:
  presets: [project]
  files: [.ace-tasks/_archive/8x/x/8xf.t.e1q-deliver-fast-web-design-and/design-plan.md]
  commands: []
needs_review: false
---

# Curate inspiration into reviewed design improvements

## Behavioral Specification

### User Experience

User invokes a periodic research workflow and receives either no actionable changes, a partial-source report, or a tested concrete package improvement ready for review.

Input: explicit brief/target and available project context. Process: follow the agreed stage boundary. Output: concrete preview, evidence or proposal appropriate to the entrypoint.

### Expected Behavior

User invokes a periodic research workflow and receives either no actionable changes, a partial-source report, or a tested concrete package improvement ready for review.

### Interface Contract

/as-design-look-for-inspiration [--surface shared|site|app]; ace-design validate; use documented weekly prompt with external scheduler.

Invalid input must produce an actionable error without altering existing artifacts. Empty or failed evidence cannot imply success.

## Success Criteria

- [x] Manual/weekly workflow tracks revisions, prior decisions and partial failures without duplicate proposals.
- [x] Curated shared/site/app cards contain applicability, avoidance, source and verification date.
- [x] A candidate change includes comparison against existing guidance on identical brief/model/data and an independent review handoff.
- [x] No auto-merge, release, daemon or required paid connector; external content cannot authorize actions.
- [x] Reproducible site/app benchmark fixtures and reporting distinguish objective measurements, human and model judgments.

## Validation Questions

Web requirements resolved in the user-approved design plan. Native platform tooling is deliberately deferred to its future task review. Defaults: web-only, local core, one-language mockups, three directions, shared fixtures, targeted feedback, external weekly research, review before adoption.

## Vertical Slice Decomposition

Size: medium. Standalone end-to-end capability; context and scope are in design-plan.md.

## Verification Plan

Validate shipped catalog and deliberately broken cards; verify inspiration workflow contract and source ledger/proposal templates; exercise unchanged source, changed source and unavailable source using local evidence fixtures.

Package checks: `bin/ace-test ace-design all`; final integration: `bin/ace-test-suite`. New runtime behavior requires executed evidence.

## Objective

Enable fast interactive direction-setting followed by reliable production engineering.

## Scope of Work

Implement this slice's interface and acceptance criteria, including documentation and usable errors.

## Deliverables

- Working behavior and usage examples.
- Verification evidence mapped to the success criteria.

## Out of Scope

Native platforms in the web release; mandatory hosted services; automated publication; production rigor during mockup exploration.

## References

- Shared plan: .ace-tasks/_archive/8x/x/8xf.t.e1q-deliver-fast-web-design-and/design-plan.md
- Usage contract: ux/usage.md
