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

## Spec review findings (review-8wmw3q, codex gpt-5.6-luna)

Wymagania dla buildera spec (A1):

- pin concrete adapter operations: arguments, return values, error model,
  provider selection/configuration;
- define `ref` semantics (typed reverse-address object: herdr session +
  pane) and the meaning of `deliver(ref, answer)`; retry, idempotency,
  unavailable-provider behavior;
- name herdr env variables, validation rules, persisted event fields;
  versioned reverse-address schema; fail closed on absent/invalid target;
- acceptance hardening: automated guard that agent-facing ace-hitl paths
  contain zero direct lab-hitl invocation; provider-dispatch acceptance
  tests; explicit disposition of legacy Lab adapter code (retained only as
  provider adapter).
