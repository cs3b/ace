---
id: 8xf.t.e1x
status: draft
priority: medium
created_at: "2026-10-16 09:22:08"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [.ace-tasks/8xf.t.e1q-deliver-fast-web-design-and/design-plan.md]
  commands: []
---

# Extend design workflows to native platforms

## Behavioral Specification

### User Experience

Future users explore and implement native UI using the same brief/variants/feedback process with platform-specific conventions and verification.

Input: explicit brief/target and available project context. Process: follow the agreed stage boundary. Output: concrete preview, evidence or proposal appropriate to the entrypoint.

### Expected Behavior

Future users explore and implement native UI using the same brief/variants/feedback process with platform-specific conventions and verification.

### Interface Contract

Future family: /as-design-native-ios, /as-design-native-android, /as-design-native-mac, /as-design-native-linux. Not implemented by web release.

Invalid input must produce an actionable error without altering existing artifacts. Empty or failed evidence cannot imply success.

## Success Criteria

- [ ] Separate as-design-native-ios/android/mac/linux entrypoints are specified.
- [ ] Shared mock data, fast direction exploration and explicit engineering handoff are retained.
- [ ] Each platform has native preview, interaction/accessibility verification and tooling prerequisites.

## Validation Questions

Web requirements resolved in the user-approved design plan. Native platform tooling is deliberately deferred to its future task review. Defaults: web-only, local core, one-language mockups, three directions, shared fixtures, targeted feedback, external weekly research, review before adoption.

## Vertical Slice Decomposition

Size: large. Standalone end-to-end capability; context and scope are in design-plan.md.

## Verification Plan

Future task review must establish runnable platform acceptance for all four targets and unavailable-tool behavior before promotion.

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
