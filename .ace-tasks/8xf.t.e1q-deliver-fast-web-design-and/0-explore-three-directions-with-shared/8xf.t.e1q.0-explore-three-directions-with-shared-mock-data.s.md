---
id: 8xf.t.e1q.0
status: draft
priority: medium
created_at: "2026-10-16 09:22:07"
estimate: TBD
dependencies: []
tags: []
parent: 8xf.t.e1q
bundle:
  presets: [project]
  files: [.ace-tasks/8xf.t.e1q-deliver-fast-web-design-and/design-plan.md]
  commands: []
---

# Explore three directions with shared mock data

## Behavioral Specification

### User Experience

User supplies a brief or existing interface, receives three lightweight directions, gives feedback and selects a direction without production engineering overhead.

Input: explicit brief/target and available project context. Process: follow the agreed stage boundary. Output: concrete preview, evidence or proposal appropriate to the entrypoint.

### Expected Behavior

User supplies a brief or existing interface, receives three lightweight directions, gives feedback and selects a direction without production engineering overhead.

### Interface Contract

/as-design-site BRIEF; /as-design-app BRIEF; ace-design preview SESSION [--port PORT]; ace-design doctor; ace-design validate.

Invalid input must produce an actionable error without altering existing artifacts. Empty or failed evidence cannot imply success.

## Success Criteria

- [ ] Both site and app entrypoints share one process and specialize the design objective.
- [ ] All variants consume the same fixtures; subset use is allowed; one language and mocked interactions are default.
- [ ] Three agents may operate in disjoint variant directories; sequential operation is supported; partial failures preserve completed previews.
- [ ] Preview gallery serves only session artifacts; invalid/missing sessions return an actionable error.
- [ ] Feedback and selection persist; unchanged variants remain untouched.
- [ ] No full review, backend, translation matrix or production audit runs in exploration.

## Validation Questions

Web requirements resolved in the user-approved design plan. Native platform tooling is deliberately deferred to its future task review. Defaults: web-only, local core, one-language mockups, three directions, shared fixtures, targeted feedback, external weekly research, review before adoption.

## Vertical Slice Decomposition

Size: medium. Standalone end-to-end capability; context and scope are in design-plan.md.

## Verification Plan

Fast/feature CLI tests for sessions, traversal refusal, gallery, malformed input; installed skill resolution; local browser smoke on site and app preview fixtures. Workflow contract checks enforce lightweight exploration and variant isolation.

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
