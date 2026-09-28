---
id: 8wq.t.1w4
status: done
priority: medium
created_at: "2026-09-27 01:15:41"
estimate: TBD
dependencies: []
tags: [ace-lab, adresowanie]
position: 6o0004
bundle:
  presets: [project]
  files: [ace-overseer/lib/ace/overseer/molecules/lab_client.rb, ace-herdr/lib/ace/herdr/models/delivery_record.rb]
  commands: []
needs_review: false
title: Address Lab projects agents and services by stable IDs
---

# Address Lab projects agents and services by stable IDs

## Behavioral Specification

### User Experience

An agent resolves an intended project, agent or service from configured topology without knowing transient pane IDs or possessing the service's credentials.

### Expected Behavior

- Introduce the already-planned ace-lab package as a topology/routing CLI, not an execution state engine. Registry entries have stable ID, project, role/capabilities and the runtime binding or service endpoint. Configuration follows ADR-022; lab-config owns deployed values.
- Public inventory never exposes tokens, auth files or secret-bearing endpoint parameters. A user sees authorized topology; caller identity is verified at the boundary, not accepted from a role flag.
- Resolve exact IDs first; labels are display values only and ambiguity is an error. Runtime pane/session IDs remain opaque transient bindings. A replaced process must have fresh identity before routing; stale binding is an explicit unavailable result.
- Routing selects a configured capable service in the requested project. Zero matches -> unavailable; multiple equal matches without an explicit configured default -> ambiguous. Never pick another project or grant credentials as a routing shortcut.
- Do not add Works, assignment state or scheduling. Service invocation belongs 8wr.t.qjx; execution state belongs 8wr.t.qjl.

### Interface Contract

`ace-lab projects --format json`, `ace-lab agents --project PROJECT --format json`, `ace-lab services --project PROJECT --format json`, `ace-lab resolve --id ID --format json`, `ace-lab route --project PROJECT --capability CAPABILITY --format json`. Output identifies selected stable ID and public binding/capabilities or a classified missing/ambiguous/stale error; no implicit pane guesses.

### Success Criteria and Verification Plan

- [x] SC1: Configuration tests cover duplicate IDs, missing project, stale binding and multiple capable services.
- [x] SC2: CLI inventory/resolve/route runs from a fresh install using sanitized Lab fixture config; changing pane identity leaves stable agent ID unchanged.
- [x] SC3: Run `ace-test ace-lab all` once implemented; package/install tests prove topology is usable without /usr/local/bin/lab.

### Scope and Ownership

Owner: **ace-lab**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: none. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

Replaces the title-only 1w4 brief; supersedes missing historical 1ce reference. Domain registry CAS/provisioning stays lab-config.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
