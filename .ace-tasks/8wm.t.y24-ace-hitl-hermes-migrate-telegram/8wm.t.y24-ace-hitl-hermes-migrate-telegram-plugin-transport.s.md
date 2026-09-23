---
id: 8wm.t.y24
status: pending
priority: high
created_at: "2026-09-23 22:42:16"
estimate: 
dependencies: [8wm.t.vs1]
tags: [ace-hitl-hermes, migration, telegram, plugin, lab-config, gad]
---

# ace-hitl-hermes: migrate Telegram plugin transport logic from lab-config

## Provenance (Kapitan goals reminder 2026-09-23)

Brief migracyjny z audytu warstwowego `8wl.t.gad.6` §3 (lab-config).
Delegacja: CO, nie JAK. Kolejność twarda: migracje zielone **przed**
koszem `8wl.t.gad.3` (usuwanie plików źródłowych w lab-config).

## MIGRUJ → ace-hitl-hermes

- `hermes-lab-hitl/` w całości (plugin + plugin.yaml + README):
  generyczny plugin transportu HITL — korelacja Reply, /hitl-reply,
  group=address, captain-allowlist, reakcje statusowe, fail-closed.
- Z `lab-hitl-broker.py` (odzysk przed koszem): korelacja
  Telegram↔request (correlations + tombstones 24h, dopasowanie
  Reply/komendy, scoping po kanale); intake group=address
  (registered_channel + captain allowlist); teksty powiadomień/statusów.
- Z `lab-hitl-channels.py` (odzysk ról): rejestr kanałów + routing
  (chat→target, default, routing po projekcie, walidacja rejestru
  fail-closed, captain allowlist) z publiczną projekcją kanałów —
  właściciel rejestru po koszu gad.3.
- Dokumentacja użycia transportu: `hermes-lab-skill/SKILL.md`
  (treść roli/umiejętności — docs pakietu).
- Testy-następcy: pokrycie z `tests/test_hitl_channels.py`.

## ZOSTAJE w lab-config (domena laba — NIE migrować)

- Konfiguracja konkretnych kanałów laba (dane, nie logika).

## Bramka końcowa

Scenariusz E2E z `8wl.t.gad.2` przechodzi na artefaktach ace-** bez
plików lab-config z listy MIGRUJ.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera,
review z executed checks, merge, release testowanym publisherem.
