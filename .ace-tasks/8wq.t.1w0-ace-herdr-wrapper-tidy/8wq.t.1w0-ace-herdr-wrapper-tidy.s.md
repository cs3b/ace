---
id: 8wq.t.1w0
status: pending
priority: medium
created_at: "2026-09-27 01:15:35"
estimate: TBD
dependencies: [8wm.t.vs0]
tags: [ace-herdr, tidy]
position: 6o0002
---

# ace-herdr tidy (rescoped 2026-09-27)

## Kontekst

Zrekreowane z listy priorytetyzacji Kapitana (2026-09-27; oryginalne ID
8wq.t.1cb nie istnieje w tym store) jako "wrapper+tidy".

## Rescope (2026-09-27, po doręczeniu 8wm.t.vs0)

Część "wrapper" została pokryta: vs0 dostarczył dispatch/wait/close
(1-komendowy dispatch, monitor, domknięcie), a resztę intencji wrapperowych
(list/send/capture/wait-output/presety) przejmuje **8wq.t.k84** (intent
parity) — tam jest ich właściciel. To zadanie zostaje **tylko tidy**:

## Zakres (behavioral)

Sprzątanie po zakończonych agentach/pane'ach i artefaktach ace-herdr.
Zasada bezpieczeństwa: **tylko dowód pozytywny zamyka** — wiek sam w
sobie NIE jest warunkiem zamknięcia pane'u.

1. **Martwe pane'y/agenti** — kwalifikacja wymaga dowodu zakończenia:
   - agent w stanie `done` (zaobserwowany, nie `unknown`), LUB
   - dowód wyjścia procesu (`pane process-info`: proces nie żyje).
   - stan `unknown` / brak odczytu = **preserve** (tylko raport, brak
     zamknięcia) — brak dowodu ≠ martwy.
   - Przed każdym zamknięciem: **re-walidacja** eligibility świeżym
     probe'em (close tylko jeśli drugi probe potwierdza); kandydat,
     który w międzyczasie ożył (working/idle), zostaje usunięty z listy
     i zaznaczony w raporcie.
   - Zamknięcie = rename → close (jak vs0 `close`).
2. **Artefakty dostaw**: rekordy `.ace-local/herdr/deliveries/` —
   rekordy `delivered` starsze niż konfigurowalny próg
   (`tidy.delivered_retention_days`, domyślnie 7) są archiwizowane/
   usuwane; rekordy failed/retryable NIE są ruszane bez wyraźnej flagi
   (audyt/odzyskiwanie). Wiek = `updated_at` rekordu.
3. **Dry-run domyślnie**: tidy niczego nie zamyka/usuwa bez `--apply`;
   raport deterministyczny (JSON), zero tokenów.

## Kryteria sukcesu

- [ ] `ace-herdr tidy` (dry-run) raportuje kandydatów do sprzątania
      (pane'y + rekordy) z zerowym efektem ubocznym; kandydaci
      niepewni (`unknown`, brak odczytu) widoczni jako preserve.
- [ ] `--apply` zamyka wyłącznie pane'y z dowodem zakończenia
      potwierdzonym re-walidacją; failed/retryable rekordy chronione
      bez flagi nadpisującej; delivered starsze niż próg (7d domyślnie)
      archiwizowane.
- [ ] Test: kandydat, który ożył między discovery a apply, NIE jest
      zamykany (raport go wyklucza).
- [ ] Ścieżki błędów: brak runtime herdr → jawny błąd; brak kandydatów →
      pusty, jawny stan (nie błąd).

## Out of scope

- Wrapper/intents (list/send/capture/presety) → 8wq.t.k84.
- Queue/broker → 8wm.t.y23.

## References

- Foundation: 8wm.t.vs0 (delivered surface: deliver/dispatch/wait/close,
  delivery records under `.ace-local/herdr/deliveries/`)
- Wrapper intents owner: 8wq.t.k84 (intent parity)
