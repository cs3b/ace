---
id: 8xf.t.e1q
status: draft
priority: medium
created_at: "2026-10-16 09:21:56"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [.ace-tasks/8xf.t.e1q-deliver-fast-web-design-and/design-plan.md]
  commands: []
---

# Deliver fast web design and production workflows

## Behavioral Specification

### User Experience

A developer explores web site or web app directions quickly, iterates with feedback, then implements and verifies the selected design.

Input: explicit brief/target and available project context. Process: follow the agreed stage boundary. Output: concrete preview, evidence or proposal appropriate to the entrypoint.

### Expected Behavior

A developer explores web site or web app directions quickly, iterates with feedback, then implements and verifies the selected design.

### Interface Contract

/as-design-site or /as-design-app → previews; choose → /as-design-site-implement or /as-design-app-implement; audit and inspiration are separate entrypoints.

Invalid input must produce an actionable error without altering existing artifacts. Empty or failed evidence cannot imply success.

## Success Criteria

- [ ] All three child capabilities are delivered and independently verified.
- [ ] Seven canonical skills resolve from source and an installed package.
- [ ] Native work remains a separate future draft, not an unfinished web dependency.

## Validation Questions

Web requirements resolved in the user-approved design plan. Native platform tooling is deliberately deferred to its future task review. Defaults: web-only, local core, one-language mockups, three directions, shared fixtures, targeted feedback, external weekly research, review before adoption.

## Vertical Slice Decomposition

Size: large. Orchestrator: children .0 exploration, .1 engineering/audit, .2 inspiration. Each owns an observable capability.

## Verification Plan

Run the exploration, implementation/audit and inspiration child scenarios. Verify package discovery, package deterministic tests and monorepo fast suite.

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

- Shared plan: .ace-tasks/8xf.t.e1q-deliver-fast-web-design-and/design-plan.md
- Usage contract: ux/usage.md
