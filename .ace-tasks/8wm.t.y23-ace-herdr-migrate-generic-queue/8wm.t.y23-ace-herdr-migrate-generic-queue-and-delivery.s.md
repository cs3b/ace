---
id: 8wm.t.y23
status: pending
priority: high
created_at: "2026-09-23 22:42:16"
estimate: 
dependencies: [8wm.t.vs0]
needs_review: false
tags: [ace-herdr, migration, queue, delivery, lab-config, gad]
position: 6o0003
bundle:
  presets: ["project"]
  files:
    - ace-herdr/lib/ace/herdr/molecules/herdr_executor.rb
    - ace-herdr/lib/ace/herdr/organisms/deliverer.rb
    - ace-herdr/lib/ace/herdr/organisms/control_surface.rb
    - ace-herdr/lib/ace/herdr/molecules/delivery_record_store.rb
    - ace-herdr/lib/ace/herdr/models/delivery_record.rb
    - ace-herdr/docs/usage.md
  commands: []
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

## Reality Check (review 2026-09-28, post-vs0+k84)

Zweryfikowane względem rzeczywistości na dzień 2026-09-28:

- **Źródła wciąż istnieją**: lab-config @ Forgejo HEAD `230b395`
  ("retro: labd deletion map") — wszystkie 8 plików z listy MIGRUJ
  obecne (`lab-hitl.py`, `lab-hitl-broker.py`, `pi-overseer-queue.ts`,
  `pi-operator-queue.ts`, `pi-overseer-queue-client.py`,
  `tests/test_native_queue_transport.py`,
  `tests/test_broker_pane_resolution.py`, `lab_root_broker.py`).
  `8wl.t.gad.3` (kosz) **jeszcze nie ruszył** — ale ostatni commit w
  lab-config to mapa migracji/delecji, więc twarda kolejność
  (migracje zielone przed koszem) jest realnym zegarem, nie formalnością.
  lab-config NIE jest sklonowany w workspace ace — plan/implimentacja
  zaczyna od shallow clone (np. do `/tmp/` lub `~/Ps/lab-config`).
- **Warstwa docelowa teraz konkretna** (spec powstał 2026-09-23, przed
  dostarczeniem vs0/k84):
  - vs0 dostarczył `Deliverer` + `DeliveryRecord`/`DeliveryRecordStore`
    (idempotencja per event id, write-ahead rekordy 0600 pod
    `.ace-local/herdr/deliveries/`, `--resume`, ambiguous-crash
    reporting) — kolejka inbox/wake ma na tym budować, nie dublować
    per-event idempotencji.
  - k84 dostarczył `HerdrExecutor` (wyłączny seam argv do herdr, typed
    errors z machine codes) + `ControlSurface` (agent-aware routing,
    `agent get`/`agent prompt`/`agent_status` z listy pane'ów) —
    pane→thread identity resolution podpina się pod executor probe
    (`agent get`/`agent explain`), nie pod raw herdr calls.
  - Tożsamości natywnie dostępne w JSON herdr: `terminal_id`,
    `agent_status` (panes), HERDR_SESSION/HERDR_PANE eksportowane przez
    dispatcher/tidy bootstrap — reverse address już działa.
- **Delegacja bez zmian**: nadal CO-nie-JAK; pełną spec behavioralną
  robi pipeline architekta (sekcja Pipeline), tą sekcją tylko
  dokumentujemy stan świata na start.

## Bramka końcowa

Scenariusz E2E z `8wl.t.gad.2` przechodzi na artefaktach ace-** bez
plików lab-config z listy MIGRUJ.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera,
review z executed checks, merge, release testowanym publisherem.
