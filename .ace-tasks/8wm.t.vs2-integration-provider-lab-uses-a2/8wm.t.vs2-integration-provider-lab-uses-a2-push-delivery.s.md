---
id: 8wm.t.vs2
status: pending
priority: high
created_at: "2026-09-23 21:11:12"
estimate: TBD
dependencies: [8wm.t.vs0, 8wm.t.vs1]
needs_review: false
tags: [ace-hitl, integration, lab, hermes]
---

# Integration: provider=lab uses A2 push delivery + A3 folder contract (single source-of-truth spec)

## Kapitan dictation (A4)

Integracja: provider=lab używa doręczenia z A2 (8wm.t.vs0) + kontraktu
folderowego z A3 (8wm.t.vs1).

- jedna wspólna spec kontraktu folderowego jako źródło prawdy.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera, review z
executed checks, merge, release testowanym publisherem.

## Spec review findings (review-8wmw3q, codex gpt-5.6-luna)

Wymagania dla buildera spec (A4):

- name the canonical shared-contract file (path in this repo), its owner,
  and versioning policy; lab-config 8wm.t.vp9 consumes it;
- require A2 (8wm.t.vs0) and A3 (8wm.t.vs1) to consume the same contract;
- add shared contract tests exercised by Hermes, Herdr, and the
  provider=lab adapter.
