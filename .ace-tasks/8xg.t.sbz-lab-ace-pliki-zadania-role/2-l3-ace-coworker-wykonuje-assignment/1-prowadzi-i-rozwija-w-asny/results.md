# Wyniki wykonania — 8xg.t.sbz.2.1 (Prowadzi i rozwija własny ace-assign)

Data: 2026-10-18. Zakres: faza B planu (krok 04) w gemie `ace-coworker`.

## Co powstało

- Deterministyczny werdykt ukończenia w
  `ace-coworker/lib/ace/coworker/models/assignment_snapshot.rb`:
  `complete` tylko gdy stan assignmentu to `completed`, plan nie jest pusty
  i każdy krok jest `done`; pusty plan, kroki `failed`/`pending`/`active`
  dają `incomplete` z konkretnymi powodami (widoczne w `ace-coworker status`).
- `status` renderuje postęp z `ace-assign status --assignment <id> --format
  json` (jedyne źródło prawdy) — bez kopiowania kroków, bez drugiej kolejki
  (config coworkera nigdy nie przechowuje kroków).
- Sekcja drive briefu odsyła do istniejącego zbioru komend
  `assign/drive.wf.md` przypiętych do assignmentu z configu
  (`--assignment <id>`; start/finish/fail/add/retry).

## Kryteria odbioru

- [x] Dodane sprawdzenie zostaje częścią tego samego planu, jest wykonane
  i widoczne przez ace-assign — test integracyjny
  `test_drive_to_completion_and_verdict_complete`
  (`ace-coworker/test/commands/integration_test.rb`): `ace-assign add`
  dokłada krok `extra-check`, `start`+`finish` wykonują oba kroki,
  `ace-coworker status --format json` pokazuje 2 kroki i `complete: true`.
- [x] Prowadzenie assignmentu do końca — smoke run w
  `/tmp/coworker-smoke.lHoQ`: stan `paused (0/1 done) — incomplete` → po
  `ace-assign start/finish` → `completed (1/1 done) — complete`.

## Weryfikacja

- `bin/ace-test ace-coworker all` — 54 testy, 0 błędów.
- `bin/ace-test ace-assign` — 633 testy, 0 błędów (regresja).

Raportowanie przez HITL i wznawianie po przerwaniu: liście `.2.2`/`.2.3`
(`.2.2` czeka na zintegrowane L2 — 8xg.t.sbz.1).
