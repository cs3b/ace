---
id: 8xf.t.e1q.1
status: done
priority: medium
created_at: "2026-10-16 09:22:07"
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

# Implement chosen directions with browser evidence

## Behavioral Specification

### User Experience

User hands selected direction to engineering or audits an existing URL; receives functioning implementation and inspectable browser evidence with honest coverage.

Input: explicit brief/target and available project context. Process: follow the agreed stage boundary. Output: concrete preview, evidence or proposal appropriate to the entrypoint.

### Expected Behavior

User hands selected direction to engineering or audits an existing URL; receives functioning implementation and inspectable browser evidence with honest coverage.

### Interface Contract

/as-design-site-implement SESSION; /as-design-app-implement SESSION; /as-design-site-audit URL; /as-design-app-audit URL; ace-design inspect URL --surface site|app [--out DIR].

Invalid input must produce an actionable error without altering existing artifacts. Empty or failed evidence cannot imply success.

Audit accepts optional project path in the request; match source to target or explicitly report source checks unavailable. URL-only browser audit is supported.

## Success Criteria

- [x] Four implement/audit entrypoints reuse shared processes and apply site/app criteria.
- [x] Selected direction, user feedback, existing components and real data contracts guide implementation.
- [x] Local inspection produces screenshots and structured findings at 390, 768 and 1440px.
- [x] Accessibility scan, overflow and load failures are distinguishable from subjective design critique.
- [x] Missing runtime/browser, invalid URL, timeouts and partial inspection never report a clean pass.
- [x] Pinned runtime setup and installed-gem invocation are documented and tested.

## Validation Questions

Web requirements resolved in the user-approved design plan. Native platform tooling is deliberately deferred to its future task review. Defaults: web-only, local core, one-language mockups, three directions, shared fixtures, targeted feedback, external weekly research, review before adoption.

## Vertical Slice Decomposition

Size: large. Standalone end-to-end capability; context and scope are in design-plan.md.

## Verification Plan

Verify an implemented success and failure/empty interaction, loading states, keyboard operation and required project languages. Ruby adapter contract tests with fake runner only at process boundary; real Playwright/axe feature run against local good and broken HTML; timeout and missing-runtime cases; installed package CLI and four skill bindings.

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
