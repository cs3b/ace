---
id: 8wm.t.vrz
status: pending
priority: high
created_at: "2026-09-23 21:11:05"
estimate: TBD
dependencies: []
tags: [ace-hitl, hitl, adapter, lab]
---

# ace-hitl: adapter interface + provider=lab contract (ask, deliver, reverse address)

## Kapitan dictation (A1)

ace-hitl: adapter interface + provider=lab — kontrakt.

- `ask` = local event + transport send w jednym;
- zapis reverse address pytającego z env herdr: session + pane;
- `deliver`;
- `wait` tylko opcjonalnie, dla skryptów bez pane.

## Acceptance

- `ace-hitl ask` z `provider=lab` tworzy event + request;
- zero `lab-hitl` w kodzie agenta.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera, review z
executed checks, merge, release testowanym publisherem.
