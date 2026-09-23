---
id: 8wm.t.y23
status: pending
priority: high
created_at: "2026-09-23 22:42:16"
estimate: 
dependencies: [8wm.t.vs0]
tags: [ace-herdr, migration, queue, delivery, lab-config, gad]
---

# ace-herdr: migrate generic queue and delivery logic from lab-config

## Provenance (Kapitan goals reminder 2026-09-23)

Brief migracyjny z audytu warstwowego `8wl.t.gad.6` §3 (lab-config).
Delegacja: CO, nie JAK. Kolejność twarda: migracje zielone **przed**
koszem `8wl.t.gad.3` (usuwanie plików źródłowych w lab-config).

## MIGRUJ → ace-herdr

- Trwała kolejka inbox/wake (z `lab-hitl.py`): enqueue/claim/mark/bind/
  reconcile, broker-generations, rekordy transportu z digestem payloadu,
  immutable bind, fail-closed uncertain, reconciliation
  consumed/superseded z dowodem niekonsumpcji.
- Z `lab-hitl-broker.py` (odzysk przed koszem):
  - rozpoznanie celu doręczenia: pane→thread identity dla codex/pi
    (agent_session, terminal_id, live identity probe);
  - dyscyplina bind-then-send-once (brak resend, pre-send retry vs
    uncertain, fail-closed-unresolved, recovery orphaned claim);
  - komendy kolejek provider-native (codex queue / klient pi).
- Protokół kolejki provider-native: `pi-overseer-queue.ts`,
  `pi-operator-queue.ts` (endpointy TS, digest-bound, idle vs followUp,
  identity probe), `pi-overseer-queue-client.py` (klient CLI).
- Testy-następcy: `tests/test_native_queue_transport.py` (negatywy
  transport/bind/reconcile), logika `test_broker_pane_resolution.py`
  (pane→thread).

## ZOSTAJE w lab-config (domena laba — NIE migrować)

- `lab_root_broker.py` (operacje domenowe catalog/registry/forgejo/
  integrator/promote-runtime/restart labd) — ginie z gad.3 bez migracji.

## Bramka końcowa

Scenariusz E2E z `8wl.t.gad.2` przechodzi na artefaktach ace-** bez
plików lab-config z listy MIGRUJ.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera,
review z executed checks, merge, release testowanym publisherem.
