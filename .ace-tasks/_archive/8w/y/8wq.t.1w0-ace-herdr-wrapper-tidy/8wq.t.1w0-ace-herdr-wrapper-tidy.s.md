---
id: 8wq.t.1w0
status: done
priority: medium
created_at: "2026-09-27 01:15:35"
estimate: TBD
dependencies: [8wm.t.vs0]
tags: [ace-herdr, tidy]
position: 6o0002
bundle:
  presets: [project]
  files: [ace-herdr/lib/ace/herdr/molecules/herdr_executor.rb, ace-herdr/lib/ace/herdr/organisms/control_surface.rb, ace-herdr/lib/ace/herdr/molecules/delivery_record_store.rb, ace-herdr/lib/ace/herdr/models/delivery_record.rb, ace-herdr/lib/ace/herdr/cli/commands/close.rb, ace-herdr/docs/usage.md]
  commands: []
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

- [x] `ace-herdr tidy` (dry-run) raportuje kandydatów do sprzątania
      (pane'y + rekordy) z zerowym efektem ubocznym; kandydaci
      niepewni (`unknown`, brak odczytu) widoczni jako preserve.
- [x] `--apply` zamyka wyłącznie pane'y z dowodem zakończenia
      potwierdzonym re-walidacją; failed/retryable rekordy chronione
      bez flagi nadpisującej; delivered starsze niż próg (7d domyślnie)
      archiwizowane.
- [x] Test: kandydat, który ożył między discovery a apply, NIE jest
      zamykany (raport go wyklucza).
- [x] Ścieżki błędów: brak runtime herdr → jawny błąd; brak kandydatów →
      pusty, jawny stan (nie błąd).

## Implementation Context (review 2026-09-28, post-8wq.t.k84)

Zweryfikowane względem aktualnego kodu (k84 dostarczone: PR #340, merged
2026-09-27; 202 testów zielonych):

- **Owner layer gotowy**: tidy buduje na istniejących_warstwach —
  `HerdrExecutor` (wyłączne seam do binary; dodać jeden argv-method dla
  `herdr pane process-info <PANE_ID>`), wzorzec orkiestracji z
  `Organisms::ControlSurface`, konwencje komend z `cli/commands/` (JSON
  output, `--quiet`, `translate_errors`, raise ACE CLI error).
- **`pane process-info` istnieje natywnie** w herdr 0.9.1 (potwierdzone
  w `herdr pane --help`) — dowód wyjścia procesu jest dostępny bez
  zewnętrznych zależności.
- **Rekordy dostaw**: `DeliveryRecord` ma pola `state` + `updated_at`
  (zweryfikowane w `models/delivery_record.rb`) — wiek rekordu = treść
  `updated_at`, jak w zakresie. Store: `DeliveryRecordStore` (atomic
  writes, per-event lock) — tidy archiwizuje przez ten sam store, nie
  przez raw `File` ops.
- **`close` nie ruszać**: tidy reuse'uje vs0 semantics (rename → close)
  przez executor; komenda `close` zostaje bez zmian.
- **Kaskada config (ADR-022)**: nowy klucz `tidy.delivered_retention_days`
  do `.ace-defaults/herdr/config.yml` (default 7) + override w
  `~/.ace/herdr/`, `.ace/herdr/` — standardowy wzorzec z
  `Ace::Herdr.config`.

## Out of scope

- Wrapper/intents (list/send/capture/presety) → 8wq.t.k84.
- Queue/broker → 8wm.t.y23.

## References

- Foundation: 8wm.t.vs0 (delivered surface: deliver/dispatch/wait/close,
  delivery records under `.ace-local/herdr/deliveries/`)
- Wrapper intents owner: 8wq.t.k84 (intent parity) — **delivered
  2026-09-27** (PR #340 merged to main; `list`/`send`/`capture`/
  `wait --for output`/presets live in `ControlSurface` + executor)
- Queue/broker owner: 8wm.t.y23 (tidy nie dotyka kolejki inbox/wake)
