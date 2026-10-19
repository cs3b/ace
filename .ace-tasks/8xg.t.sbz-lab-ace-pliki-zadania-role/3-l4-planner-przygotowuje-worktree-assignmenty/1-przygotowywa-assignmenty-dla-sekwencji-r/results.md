# Wynik wykonania — 8xg.t.sbz.3.1 (L4.2) — Przygotowywać assignmenty dla sekwencji ról

Data: 2026-10-19. Worktree: `.ace-wt/t-sbz-wave-3` (branch `t-sbz-wave-3`).

## Zakres i umiejscowienie

Planner przygotowuje assignmenty dla CAŁEJ znanej sekwencji ról od razu, przy
preparacji worktree. Powierzchnia `prepare` pochodzi z .3.0 i znajduje się w
**ace-coworker** (nie ace-lab — tak zrealizowano .3.0, patrz results .3.0;
ace-lab `prepare` to L8: konta/katalogi/klucze z manifestu instalacji), więc
rozszerzenie wylądowało w ace-coworker. Sekwencja wyrażona jest WYŁĄCZNIE
przez istniejący magazyn planów ace-assign (`.ace-local/assign/` w worktree) —
bez nowej kolejki, journala ani kopii kroków w konfiguracji coworkera
(ADR-034, kontrakt „Właściciele i miejsca zapisu").

## Dostarczenie

`ace-coworker prepare --task REF --roles worker,reviewer[,spec][,integrator]`:
po zapewnieniu worktree (created/recovered/reuse, konflikty bez zmian z .3.0)
komponuje **po jednym assignmencie ace-assign na rolę, w kolejności
zależności**, jednym przebiegiem — po starcie role przekazują sobie pracę
sekwencyjnie, bez ponownego komisjonowania preparacji przez overseera:

- każdy assignment: `task_id` (weryfikacja task↔assignment w `commission`
  działa bez zmian), nazwa `<task>-<role>`, opis z pozycją `sequence N/M`
  i oczekiwanym wynikiem zlecenia; każdy leg po pierwszym otwiera jawny
  warunek wejścia (entry condition) wymieniający poprzedni assignment i rolę;
- proces każdej roli pochodzi z własnej definicji sekwencji: shippowane
  `.ace-defaults/coworker/sequences/<role>.yml`, nadpisanie projektowe
  `.ace/coworker/sequences/<role>.yml` (cały plik wygrywa, `role` musi się
  zgadzać) — worker i reviewer dostają RÓŻNE procesy pod ten sam task;
- reviewer: instrukcje osadzają regułę 3/2/10 i narzędzie
  `ace-coworker rounds record` (RoundRule z .4.2 — bez nowej logiki);
  integrator: kontrole `ace-coworker gate` (.4.3) przed merge; spec: luki
  wymagań jako pytanie ace-hitl, nie zgadywanie; worker: implementacja +
  `bin/ace-test <pkg> all` jako warunek sukcesu;
- brak procesu roli (brak presetu → `unknown role`, albo preset bez
  definicji sekwencji → `role '<x>' has no assignment process … refusing to
  substitute another role's process`) jest raportowany, exit 1,
  **all-or-nothing**: nie powstaje żaden częściowy zestaw; worktree zostaje
  zachowany;
- idempotencja: re-prepare wykrywa istniejące assignmenty sekwencji po
  nazwie `<task>-<role>` + zgodnemu `task_id` i raportuje je jako
  `existing` (zero zbędnych zapisów); dokłada tylko brakujące nogi
  sekwencji; `--dry-run` nie komponuje (worktree jeszcze nie istnieje) →
  `assignments: []`;
- wynik JSON/table zyskał uporządkowaną listę `assignments`
  (role, position/of, assignment id, disposition created/existing, liczba
  kroków, oczekiwany wynik).

## Pliki

- `ace-coworker/.ace-defaults/coworker/sequences/{worker,spec,reviewer,integrator}.yml`
  — nowe definicje procesów ról (shipped defaults).
- `ace-coworker/lib/ace/coworker/molecules/role_sequence_composer.rb` — nowy
  molekuł `RoleSequenceComposer` (kaskada definicji sekwencji jak w
  RolePresetLoader, zapis przez `Ace::Assign::Molecules::{AssignmentManager,
  StepWriter}` + `Atoms::NumberGenerator`; wykrywanie istniejących
  assignmentów tylko odczytem plików ace-assign).
- `ace-coworker/lib/ace/coworker/models/preparation.rb` — pole `assignments`.
- `ace-coworker/lib/ace/coworker/organisms/prepare_orchestrator.rb` —
  kompozycja sekwencji po sukcesie provision (konflikty/dry-run pomijają).
- `ace-coworker/lib/ace/coworker/cli/commands/prepare.rb` — render
  `sequence:` (table) i `assignments` (JSON); `lib/ace/coworker.rb` —
  rejestracja autoload.
- Testy: `test/molecules/role_sequence_composer_test.rb` (13), rozszerzone
  `test/organisms/prepare_orchestrator_test.rb` (+3), `test/commands/
  prepare_test.rb` (+1/rozszerzone asercje), `test/commands/
  prepare_integration_test.rb` (+3 integracyjne na prawdziwym git+binstubach,
  w tym konsumpcja skomponowanego assignmentu przez `commission` w worktree).
- `ace-coworker/CHANGELOG.md` ([Unreleased]/Added, EN), `README.md`,
  `docs/usage.md` (sekcja `prepare` rozszerzona, nie przepisana; wiersz
  exit codes; przykład JSON). Plik workflow plannera `prepare` nie istnieje
  (prepare dokumentuje usage.md) — rozszerzono istniejące opisy.

## Kryteria odbioru → dowody

1. **„Worker i reviewer dostają różne procesy, dopasowane do tego samego
   taska; kolejność i warunki odbioru są jawne."**
   - `role_sequence_composer_test.rb#test_worker_and_reviewer_get_different_processes_for_the_same_task`
     (różne kroki; worker: `bin/ace-test`; reviewer: 3/2/10 + `rounds record`),
     `#test_entry_conditions_make_the_order_and_handoff_explicit` (warunek
     wejścia z id poprzedniego assignmentu), `#test_composes_one_assignment_per_role_in_dependency_order`
     (pozycje 1..N, `sequence N/M`, oczekiwany wynik w opisie),
     `#test_integrator_step_references_the_gate_and_spec_step_references_hitl`;
   - integracyjnie: `prepare_integration_test.rb#test_prepare_composes_the_whole_role_sequence_usable_by_commission`
     (trzy assignmenty w kolejności, inne procesy worker/reviewer/integrator,
     reviewer osadza 3/2/10 i wskazuje assignment workera).
2. **„Brak wymaganego procesu projektu/roli jest raportowany, a planner nie
   podstawia procesu innej roli bez podstaw."**
   - `#test_missing_role_process_is_reported_and_nothing_is_written` (preset
     projektowy `tailor` bez definicji sekwencji → raport + zero zapisów),
   - `#test_unknown_role_is_reported_without_substitution`,
   - `#test_invalid_project_override_is_reported_not_substituted`,
   - `#test_existing_assignment_of_a_foreign_task_is_not_reused`;
   - integracyjnie: `#test_missing_role_process_reports_and_writes_no_assignments`
     (rola projektowa bez procesu → exit 1, komunikat „refusing to
     substitute", brak częściowej sekwencji, zero zdarzeń HITL — nieważna
     komisja nie wymaga decyzji overseera) oraz
     `#test_unknown_role_in_sequence_is_reported`.
3. **„Wynik jest zgodny z kontraktem programu i możliwy do użycia przez
   następną rolę lub narzędzie."**
   - Kolejność sekwencji żyje tylko w planach ace-assign (jeden właściciel
     stanu; kontrakt: „Istniejący ace-assign przechowuje plan wykonania.
     Nie kopiujemy jego kroków…"); `commission` pozostaje jedynym
     zapisującym `.ace-local/coworker/` — prepare nie pisze konfiguracji
     roli (po starcie driver może rozwijać własny assignment w granicach
     reguł roli, jak w kontrakcie „Proces i role").
   - Użyteczność dla następnego narzędzia: `commission --role worker
     --task … --assignment <id>` wykonywany W worktree przechodzi weryfikację
     task↔assignment i pisze config (test integracyjny pkt 1);
     pending-assignmenty nie blokują re-prepare (aktywne: running/stalled/
     skomisjonowane nieukończone — bez zmian z .3.0).
   - Reguła 3/2/10 w sekwencjach clean/clean/clean oraz error/clean/clean
     (rozwiązane High) kończy się rundą 3 — to istniejąca logika RoundRule
     (.4.2; `round_rule_test.rb`), którą assignmenty reviewera osadzają/
     przywołują; w tym tasku NIE dodano nowej logiki rund.

## Weryfikacja

- `bin/ace-test ace-coworker all` → **354 testy, 1510 asercji, 0 failed**
  (atoms 98, molecules 116, organisms 65, models 1, commands 74).
- `bin/ace-lint` na zmienionym markdown: „All files passed".
- ace-lab nietyczny (jego `prepare` to zakres L8). Pakiety poza ace-coworker
  niezmienione.

## Decyzje / otwarte pytania

- Umiejscowienie w **ace-coworker**, nie ace-lab — zgodnie ze stanem faktycznym
  po .3.0 (powierzchnia planner-`prepare` żyje w ace-coworker; zakres w treści
  tasku zakładał ace-lab). Brak edycji krzyżowych pakietów: ace-assign użyty
  wyłącznie przez jego istniejące API biblioteczne (zależność runtime już
  istnieje w gemspec).
- Definicje procesów ról jako dane w kaskadzie config (sequences/*.yml), nie
  allowlista ról — projekt może dodać własną rolę z własnym procesem
  (presety pozostają „convenience defaults", ADR-034).
- prepare celowo NIE rezolwuje `wfi://` instrukcji presetów — to kontrola
  `start` (istniejąca); prepare raportuje brak PROCESU (preset/definicja
  sekwencji), nie brak rezolucji nav w świeżym worktree.
- Dry-run nie komponuje planów (worktree nie istnieje; nadpisywania projektowe
  i presety czytałby z niewłaściwego korzenia) — wynik `assignments: []`.
- Po commission re-prepare daje konflikt `active_executor` (zachowanie .3.0,
  celowe: jeden aktywny wykonawca) — ponowna kompozycja/dokończenie sekwencji
  wypada przed commission lub po zakończeniu executed roli.
