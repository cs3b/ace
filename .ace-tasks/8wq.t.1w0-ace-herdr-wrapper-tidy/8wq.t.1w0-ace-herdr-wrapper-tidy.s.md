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

Sprzątanie po zakończonych agentach/pane'ach i artefaktach ace-herdr:

1. **Martwe pane'y/agenti**: wykrycie pane'ów z agentami w stanach
   terminalnych (done/unknown) lub bez żywego procesu; zamknięcie
   (rename → close, jak vs0 `close`) po potwierdzeniu wieku/Ownership.
2. **Artefakty dostaw**: rekordy `.ace-local/herdr/deliveries/` —
   dostarczone (delivered) rekordy starsze niż konfigurowalny próg
   są archiwowane/usuwane; rekordy failed/retryable NIE są ruszane
   bez wyraźnej flagi (audyt/odzyskiwanie).
3. **Dry-run domyślnie**: tidy niczego nie zamyka/usuwa bez `--apply`;
   raport deterministyczny (JSON), zero tokenów.

## Kryteria sukcesu

- [ ] `ace-herdr tidy` (dry-run) raportuje kandydatów do sprzątania
      (pane'y + rekordy) z zerowym efektem ubocznym.
- [ ] `--apply` zamyka/usuwa tylko wskazane kategorie; failed/retryable
      rekordy chronione bez flagi nadpisującej.
- [ ] Ścieżki błędów: brak runtime herdr → jawny błąd; brak kandydatów →
      pusty, jawny stan (nie błąd).

## Out of scope

- Wrapper/intents (list/send/capture/presety) → 8wq.t.k84.
- Queue/broker → 8wm.t.y23.

## References

- Foundation: 8wm.t.vs0 (delivered surface: deliver/dispatch/wait/close,
  delivery records under `.ace-local/herdr/deliveries/`)
- Wrapper intents owner: 8wq.t.k84 (intent parity)
