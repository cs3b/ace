# 8xg.t.sbz.1.0 — wynik realizacji (2026-10-18)

## Zakres

Pierwszy lokalny wycinek L2: ten sam plikowy interfejs `ace-hitl` obsługuje
raport zakończenia/błędu oraz pytanie/eskalację. Tylko prośba wymagająca
decyzji oczekuje na odpowiedź.

Rozszerzono istniejący interfejs `create/show/list/update/wait` (bez odtwarzania
usuniętego `overseer-send`):

- `ace-hitl create "..." --type report --result success|error [--body ...]... [--task REF]`
  — raport: własne ID, status `recorded`, sekcja `## Report`, referencje
  task/assignment/step, bez oczekiwania na odpowiedź.
- Pytania: jawny `type: question` w nowych plikach; cykl pending → answered
  bez zmian; pliki bez `type` wczytywane jako pytania.
- Raport nigdy nie jest zablokowanym pytaniem: `wait`, `update --answer`,
  `update --resume` na raporcie kończą się exit 1 z jawnym błędem;
  generyczne `--set/--add/--remove/--move-to` działają (archiwizacja przez
  overseera). Bibliotecznie: `NotAnswerableError` przed mutacją pliku,
  `wait_for_answer`/`dispatch_resume` zwracają `{status: :report}` bez sleepu.
- `list --type question|report`, `show` z `Type:`/`Result:`, symbol `▪` dla
  statusu `recorded`. Help CLI utrwala publiczną składnię.
- Zapis lokalny ≠ dostarczenie: `recorded` oznacza zapis w `.ace-local/hitl/`.
  Zdalne adresowanie i adaptery to liście .1.1–.1.3.

## Kryteria odbioru

- [x] Raport work done trafia do overseera bez oczekiwania na Reply; pytanie
  pozostaje oczekujące i może wstrzymać assignment — raport tworzony lokalnie
  ze statusem `recorded`, `wait` natychmiast kończy się błędem; pytanie pozostaje
  `pending` (test `test_report_is_never_a_blocked_question`,
  `test_question_cycle_unchanged_and_silence_is_not_consent`).
- [x] Brak odpowiedzi na pytanie nie jest zgodą ani sukcesem; raport bez
  odpowiedzi nie staje się zablokowanym pytaniem — `wait --timeout` na pytaniu
  kończy się exit 1 „Timed out”; raport nie pojawia się na `list --status pending`.
- [x] Wynik zgodny z kontraktem programu i użyteczny przez następną rolę —
  rozszerzony interfejs w help/usage/README/wf przed integracją konsumentów
  (8xg.t.sbz.2.2 czeka na całe L2).

## Weryfikacja

- Testy pakietu: `bin/ace-test ace-hitl all` — 239 testów, 0 failures
  (raport z: `.ace-local/test/reports/hitl/934c9066-470b-4ebf-b4ee-40ec0fbfc77d/`),
  w tym nowe `test/fast/organisms/hitl_manager_report_test.rb` (8 testów) i
  rozszerzone `test/fast/commands/hitl_cli_test.rb`.
- Manualny przebieg (katalog /tmp/hitl-walk, bin/ace-hitl z tego checkoutu):
  create report → `Status: recorded`, `Type: report`, `Result: success`;
  `wait`/`--answer` exit 1 z komunikatem „reports do not await an answer”;
  `--move-to archive` exit 0; pytanie pozostaje `pending` na liście.
- Lint: `bin/ace-lint` — usage.md, README.md, CHANGELOG.md czyste;
  hitl.wf.md ma 3 wstępne błędy frontmatter (name/description/allowed-tools)
  obecne także na HEAD — nie wprowadzone przez ten task.
- `bin/ace-test-suite` — uruchomione po zmianach (wynik w raporcie poniżej
  przy odbiorze).

## Uwagi

- Wersja ace-hitl 0.18.0 → 0.19.0; `ace-hitl-hermes` pin `~> 0.19.0`
  (standardowy bump zależności w mono-repo).
- Równoległa sesja modyfikowała Gemfile (ace-coworker, task .2.0) — tij
  stan tła, nie ruszany; testy pakietu wykonano po jego ustabilizowaniu.
