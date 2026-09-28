---
id: 8wj.t.ocz
title: Verify installed overseer workflow resolution and lifecycle contracts
status: in-progress
priority: medium
created_at: "2026-09-20 16:15:48"
estimate: medium
dependencies: []
tags: [ace-overseer, workflow-instructions, nav, packaging]
needs_review: false
position: 6o000g
bundle:
  presets: [project]
  files: [ace-overseer/ace-overseer.gemspec, ace-overseer/.ace-defaults/nav/protocols/wfi-sources/ace-overseer.yml, ace-overseer/handbook/workflow-instructions/overseer.wf.md, ace-overseer/test/fast/molecules/gem_packaging_test.rb]
  commands: []
worktree:
  branch: ocz-verify-installed-overseer-workflow-resolution-and-lifecycle-contracts
  path: .ace-wt/ace-t.ocz
  created_at: "2026-09-28 20:02:46"
  updated_at: "2026-09-28 20:02:46"
  target_branch: main
---

# Verify installed overseer workflow resolution and lifecycle contracts

## Behavioral Specification

### User Experience

A fresh installed consumer resolves wfi://overseer and receives the actual lifecycle workflow without depending on ACE monorepo overrides.

### Expected Behavior

- Source already contains workflow registration, substantive payload and packaging test. Invalidate the old claim that all are absent; do not recreate delivered files. A failed /tmp probe proves only that the current local installed environment does not resolve it, not that current source still lacks registration.
- Build/install the current intended gem set into an isolated consumer environment and execute ace-nav resolve plus ace-bundle. If successful, record package/version/contents/probe evidence and close without unnecessary code edits. If unsuccessful, reproduce and fix the specific packaging/resolution gap.
- Workflow exposes work-on/status/prune and executed status-truth/preservation checks. Generic Lab-engine removal and charter content changes belong qk0; this task owns discoverability/packaging only.
- Prune requires positive preservation proof and no active writer. Do not establish squash/cherry-pick preservation solely from a matching commit subject: require matching accepted artifact/tree or patch equivalence in the verified destination; preserve on ambiguity.
- Installed and source behavior must match without a project-local wfi registration masking an absent gem entry. Version update is needed only for actual shipped changes; publication/deployment is recorded separately.

### Interface Contract

Existing `ace-nav resolve wfi://overseer` and `ace-bundle wfi://overseer` resolve from a clean installed consumer. Public command semantics remain unchanged by packaging verification.

### Success Criteria and Verification Plan

- [ ] SC1: Fresh temporary gem home and unrelated cwd: resolve/bundle succeed from the built package; archive includes workflow and nav registration.
- [ ] SC2: Negative fixture without registration demonstrates the probe would detect masking; contents include status-truth and preservation proof rules.
- [ ] SC3: Run `ace-test ace-overseer all` when implementing a fix, plus executed installed probes in all cases. Record tested gem versions; do not claim lab deployment from a local pass.

### Scope and Decisions

Owner: ace-overseer packaging. Single small vertical verification/fix slice, no dependency. Corrects stale 2026-09-20 assumptions in ocz; keeps original outcome and historical evidence. No fresh live Lab state was verified during specification review. No unresolved behavioral questions. CI advisory; executed tests and independent review apply. Cross-repo program lab-config:8wl.t.gad. Historical text below is superseded, not active.

### Usage and Review

Scenarios in ux/usage.md; independent review required before promotion.
