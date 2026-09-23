---
id: 8wm.t.y21
status: pending
priority: high
created_at: "2026-09-23 22:42:16"
estimate: 
dependencies: [8wm.t.vrz]
tags: [ace-hitl, migration, hitl, lab-config, gad]
---

# ace-hitl: migrate generic HITL core logic from lab-config lab-hitl

## Provenance (Kapitan goals reminder 2026-09-23)

Brief migracyjny z audytu warstwowego `8wl.t.gad.6` §3 (lab-config).
Delegacja: CO, nie JAK. Kolejność twarda: migracje zielone **przed**
koszem `8wl.t.gad.3` (usuwanie plików źródłowych w lab-config).

## MIGRUJ → ace-hitl (z lab-hitl.py + odzysk z brokerów)

- Pełny lifecycle requestu (`request`/`pending`/`states`/`deliver`/
  `consume`/`cancel`): brak wygasania czasowego, audytowane anulowanie.
- Kinds + sekrety/OTP: kształt 6-cyfr, scrubbing secret-shape,
  answers 0400 owner=requester.
- Publiczna projekcja lifecycle: merge-on-write, per-request lock, 0440.
- Warstwa efektów: deklaracja callbacku przez requestera, wykonanie
  AS REQUESTER z privilege-drop, exec-argv + `{answer}`, match regex,
  timeout, redakcja logów, dedupowana eskalacja, stany callback-*.
- Reverse address `overseer-send`/`overseer-ack`: bounded response,
  polityka type-tag ([decyzja]/[pytanie]/[info]), zakaz SHA/Work/ID
  w odpowiedzi.
- Kontrakt projekcji duty (pending + escalated).
- Powierzchnia ask/cancel operatora + respond (odpowiedź na dostawę)
  — z odzysku `lab-hitl-broker.py`/`lab-hitl-channels.py`; zweryfikować
  pokrycie z gem `ask` 0.9.0.
- Testy-następcy: `tests/test_hitl.py` (68 lifecycle),
  `tests/test_hitl_effects.py` (w tym REAL-filesystem) — przenoszą się
  z kodem, którego są kontraktem.

## ZOSTAJE w lab-config (domena laba — NIE migrować)

- Binding requestu do żywego Work/Attempt (W647: `daemon_attempt_binding`/
  `validate_attempt_request`/`require_active_attempt` przez socket labd).
- Glue eskalacyjny do `lab_control` (record_wake + spool).

## Bramka końcowa

Scenariusz E2E z `8wl.t.gad.2` przechodzi na artefaktach ace-** bez
plików lab-config z listy MIGRUJ.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera,
review z executed checks, merge, release testowanym publisherem.
