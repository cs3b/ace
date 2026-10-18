# Wynik realizacji — 8xg.t.sbz.2.2 (L3.3: zapisywać wynik i raportować przez HITL)

Data: 2026-10-18. Ten sam worktree i ten sam PR #383.

## Co powstało

- **`ace-coworker report`** (nowa komenda, coworker 0.1.0 → 0.2.0):
  - **Pochodzenie wyniku**: jedyną prawdą jest werdykt ace-assign. Wymuszone
    `--result success` na niekompletnym assignmencie → odmowa przed
    jakimkolwiek zapisem; wynik `error` wymaga przyczyny (`--message` albo
    pole `error:` z pliku stanu nieudanego kroku
    `.ace-local/assign/<id>/steps/<n>-*.st.md`) i niesie listę niedokończonych
    kroków — nigdy fałszywe work done.
  - **Kolejność zapisu**: najpierw trwały rekord w folderze taska
    (`<task>/coworker/<assignment>.md`, atomowo; granica ADR-034 — coworker
    nie dotyka specyfikacji tasków), pomocniczy stan w
    `.ace-local/coworker/reports/<assignment>.json`, dopiero potem raport
    przez interfejs ace-hitl (`create --type report --result … --task
    --assignment --step --to <overseer>` + `send`).
  - **Oddzielenie wyniku od dostawy**: ukończony assignment z niedostarczonym
    raportem zachowuje sukces pracy + jawny błąd dostawy (exit 1); rerun z
    tym samym wynikiem robi send-only (ponawianie dostawy ≠ ponawianie
    zadania, zero duplikatów zdarzeń); zmiana wyniku tworzy nowe zdarzenie.
    `--no-send`, `--dry-run` (zero zapisów), `errors.on_failure: stop`
    (błędy tylko lokalnie, zero subprocessów HITL).
  - `ace-hitl ~> 0.22` jako zależność runtime; brief `start` wskazuje
    `report with:`; overseer = skonfigurowana nazwa odbiorcy ace-hitl.

## Kryteria odbioru

- [x] Zakończony assignment pozostawia wynik i raport do overseera; błąd
  zawiera przyczynę i stan umożliwiający dalsze działanie — integracyjny
  `test_completed_assignment_creates_success_report_event` (realne
  `bin/ace-assign` + `bin/ace-hitl`: zdarzenie `type: report, result:
  success` z task/assignment + rekord w folderze taska) i
  `test_failed_step_reports_error_with_cause` (przyczyna z pola `error:`
  nieudanego kroku + unfinished steps).
- [x] Samo zakończenie procesu lub wysłanie raportu nie oznacza wykonania
  nieukończonych kroków; niedostarczenie raportu nie gubi lokalnego wyniku —
  `test_pending_assignment_with_forced_success_is_refused` (odmowa,
  zero zapisów), `test_delivery_failure_preserves_outcome_and_rerun_resends`
  (rekord trzyma success, rerun bez duplikatu zdarzenia), werdykt
  completion deterministyczny z .2.1.
- [x] Wynik zgodny z kontraktem i użyteczny — rekord markdown w folderze
  taska (Outcome/Cause/Unfinished/Evidence/Delivery + next steps) czytelny
  dla następnej roli; stan pomocniczy w `.ace-local/coworker/`; raport przez
  wspólny interfejs HITL z retencją dostawy z L2.4.

## Weryfikacja

- `bin/ace-test ace-coworker all` — 95 testów, 0 błędów (nowe: outcome 1,
  planner 7, molekuły 10, orchestrator 8, integracyjne 4 z realnymi
  binstubami ace-assign/ace-hitl/ace-coworker).
- `bin/ace-test ace-hitl all` — 337 testów, 0 błędów (regresja).
- Lint: usage/README/CHANGELOG coworker + README/usage ace-assign — passed.
