---
id: 8wm.t.vs2
status: pending
priority: high
created_at: "2026-09-23 21:11:12"
estimate: TBD
dependencies: [8wm.t.vs0, 8wm.t.vs1]
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
