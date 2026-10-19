# Wyniki — 8xg.t.sbz.5.4 Przetwarzać raporty i kontynuować kolejkę (L6.5)

Data: 2026-10-19. Branch `t-sbz-wave-3` (worktree `.ace-wt/t-sbz-wave-3`).

## Co zostało zaimplementowane

Nowa komenda `ace-overseer process-reports` (L6.5) plus czysty atom interpretacji:

- `ace-overseer/lib/ace/overseer/atoms/report_interpretation.rb` — czysty atom:
  zdarzenie ace-hitl (raport/pytanie) + prywatne drzewo `_overseer` → akcje.
  Dopasowanie po `assignment` zapisanym na kroku, a w braku po `project_task`
  managera z dokładnie jednym nieterminalnym subtaskiem. Statusy:
  `success` / `error` / `needs_answer` / `duplicate` / `unmatched`.
- `ace-overseer/lib/ace/overseer/molecules/hitl_inbox.rb` — read-only gateway
  do skrzynki ace-hitl (listy raportów i oczekujących pytań, normalizacja do
  hasha; ace-hitl pozostaje właścicielem swoich plików).
- `ace-overseer/lib/ace/overseer/organisms/report_processor.rb` — orkiestrator:
  zapis wyniku wyłącznie przez istniejącą powierzchnię `ace-task update`
  (`processed_report`, `report_result`, `status=done` tylko dla sukcesu),
  następnie kontynuacja kolejki wyłącznie przez istniejące bramki:
  `HandoffOrchestrator` (następna rola w TYM SAMYM worktree, gdy rodzina ma
  zapisany `worktree`) albo `WorkOnOrchestrator`/`DependencyReadiness`
  (kolejny odblokowany krok bez worktree). Odmowa kontynuacji = `blocked`
  z powodami, nigdy sukces.
- `ace-overseer/lib/ace/overseer/cli/commands/process_reports.rb` + rejestracja
  w CLI (`process-reports`, help/przykłady). Opcje: `--dry-run`, `--quiet`,
  `--debug`.
- Zmiana między-pakietowa (uzasadniona): `ace-overseer.gemspec` zależność
  `ace-hitl ~> 0.23` — odczyt zdarzeń ace-hitl w procesie; bez pośredniego
  pliku stanu. `test_helper.rb` dopisuje `ace-hitl` do $LOAD_PATH.

Brak nowego stanu: identyfikator przetworzonego raportu zapisuje się we
frontmatterze kroku przez zwykły `ace-task update`; powtórzone dostarczenie
wykrywane jest ze zapisanego `processed_report` i niczego nie uruchamia
ponownie (ponowienie dostarczenia ≠ ponowienie wykonania).

## Testy

`bin/ace-test ace-overseer all` → **299 testów, 1231 asercji, 0 failures,
0 errors** (baseline 278; przybyło 21 testów):

- `test/fast/atoms/report_interpretation_test.rb` (8): dopasowanie po
  assignment i po project_task; duplikat; error nie zamyka kroku; pytanie
  nie zapisuje nic; nieznany task/assignment → unmatched; niejednoznaczne
  dopasowanie → unmatched; puste drzewo → unmatched.
- `test/fast/organisms/report_processor_test.rb` (10): sukces aktualizuje
  krok i startuje następny odblokowany krok przez work-on; rodzina z
  worktree kontynuuje przez bramkę handoff; powtórzony raport nie uruchamia
  następnego kroku dwa razy (rerun tego samego zdarzenia → duplicate, jeden
  update, jeden work-on); error pozostawia krok otwarty i nie kontynuuje;
  pytanie wskazuje ścieżkę odpowiedzi `ace-hitl update <id> --answer` i nic
  nie zapisuje; raport o nieznanym tasku → clarify bez zapisów; zablokowana
  kontynuacja (niespełniona zależność) → `none` z powodem; odmowa handoff →
  `blocked`; dry-run bez zapisów i kontynuacji; wszystkie kroki terminalne →
  komunikat o możliwości zamknięcia taska zarządzającego.
- `test/fast/commands/process_reports_command_test.rb` (3): przejście
  wyników do CLI, przekazanie `--dry-run`, opakowanie błędów.

## Mapowanie kryteriów odbioru

- **„Jeden realny obieg planner → worker → raport → reviewer działa już w L6;
  wyniki aktualizują właściwy task nadrzędny."** — obieg mechanicznie:
  raport sukcesu wykonawcy jest wiązany z krokiem w drzewie `_overseer`
  (assignment na kroku lub project_task managera), wynik + ID raportu
  zapisywany w tasku zarządzającym/kroku przez `ace-task update`, a kontynuacja
  przechodzi przez te same bramki, których używa sekwencja ról
  (handoff w jednym worktree — test `test_success_report_continues_same_worktree_through_handoff_gate`;
  work-on dla kolejnego odblokowanego kroku — test
  `test_success_report_updates_step_and_starts_next_unblocked_step_via_work_on`).
  Pełny obieg z żywym executorem należy do scenariuszy integracyjnych L9;
  w L6 działa na plikach laba (kontrakt programu, sekcja Odbiór).
- **„Powtórzony raport nie uruchamia następnego kroku dwa razy; raport
  niepasujący do zlecenia lub eskalacja nie są traktowane jako sukces."** —
  testy `test_repeated_report_does_not_start_the_next_step_twice`,
  `test_report_about_unknown_task_is_kept_for_clarification`,
  `test_error_report_keeps_step_open_and_does_not_continue`,
  `test_question_surfaces_answer_path_and_writes_nothing`,
  `test_refused_handoff_continuation_is_blocked_not_success`,
  `test_blocked_next_step_continuation_reports_reason_without_starting`.
- **„Wynik jest zgodny z kontraktem programu i możliwy do użycia przez
  następną rolę lub narzędzie."** — zapis tylko przez `ace-task update`
  (frontmatter kroku) i odczyt tylko przez ace-hitl; brak journala, tabeli
  deduplikacji, silnika kolejki ani nowego właściciela stanu (ADR-034).
  Kontynuacja używa istniejących bramek work-on/handoff i ich wyników
  (start_config następnej nogi, assignment id), czyli tego, co konsument
  (`ace-coworker start`) już rozumie.

Scenariusz przerwania między zapisem wyniku a następnym przydziałem:
po wznowieniu `process-reports` odczytuje drzewo zadań i stan worktree od
nowa; ponownie dostarczony raport tego samego ID wykrywa zapisany
`processed_report` (duplicate) — test rerun w
`test_repeated_report_does_not_start_the_next_step_twice`.

## Dokumentacja

- `ace-overseer/CHANGELOG.md` — wpis [Unreleased] / Added (EN).
- `ace-overseer/docs/usage.md` — sekcja `ace-overseer process-reports`,
  command surface (5 komend), wzmianka w sekcji Private overseer queue.
- `ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md` —
  sekcja 5 wskazuje, że `process-reports` wykonuje reguły 1-3 mechanicznie.
- `docs/lab-flow.md` bez zmian — nie powstał nowy rodzaj artefaktu.

## Decyzje projektowe

1. Deduplikacja w frontmatterze kroku (`processed_report`), nie w osobnej
   tabeli — zgodnie z kontraktem „bez osobnej tabeli deduplikacji/journala".
2. Kontynuacja zawsze przez istniejące orkiestratory (handoff/work-on);
   odmowa bramki jest wynikiem `blocked`, nie błędem całości — kolejne
   zdarzenia w tej samej turze są nadal przetwarzane.
3. Pytanie nie zapisuje nic na kroku — odpowiedź należy do powierzchni
   ace-hitl (`ace-hitl update <id> --answer`); komenda tylko ją wskazuje.
4. Zależność `ace-hitl` w gemspec (in-process `HitlManager`) zamiast
   subprocessów — ten sam wzorzec co `ace-coworker` w handoff.

## Otwarte pytania

- Automatyczne budzenie pi (adresowanie/nervus) należy do .6.2 — poza zakresem.
- Zamykanie taska zarządzającego przy wszystkich krokach terminalnych
  pozostawione roli overseera (reguła 6 queue.wf.md); komenda tylko raportuje.
