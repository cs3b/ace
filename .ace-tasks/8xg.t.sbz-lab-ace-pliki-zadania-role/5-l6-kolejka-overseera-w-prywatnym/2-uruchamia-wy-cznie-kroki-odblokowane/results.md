# Wyniki: Uruchamiać wyłącznie kroki odblokowane zależnościami (8xg.t.sbz.5.2)

Data: 2026-10-19. Worktree: `.ace-wt/t-sbz-wave-3` (branch `t-sbz-wave-3`).

## Zakres i decyzja o umiejscowieniu

Runtime'owy gate'owanie startu kroków przez zależności zaimplementowane w
pakiecie **ace-overseer** — tam, gdzie predecessors L6.0/L6.1 ulokowali powierzchnię
L6 (prywatne drzewo `_overseer` via `ace-task --in _overseer`, workflow
`overseer/queue.wf.md`, start przez `ace-overseer work-on`). Nie tworzę nowego
pakietu, silnika kolejki ani cache — gotowość liczona jest wyłącznie z istniejącego
stanu drzewa tasków (pola `dependencies` + `status`).

Kształt zgodny z rekomendacją: czysty atom + wpięcie w istniejącą ścieżkę startu:

- **Atom** `Ace::Overseer::Atoms::DependencyReadiness` (czysta funkcja:
  task + lookup zależności → `{status: :ready}` | `{status: :blocked, reasons: [...]}`).
  Reguła spełnienia: zależność jest spełniona **wyłącznie** gdy poprzednik ma
  status `done` (odebrany i zintegrowany wynik). Pozostałe przypadki:
  - `pending` / `in-progress` / `blocked` / `draft` → „predecessor not integrated yet”,
  - `skipped` / `cancelled` (terminalne bez wyniku) → „no accepted/integrated result”,
  - brakujący ref → „dependency not found”,
  - bezpośrednia pętla (self-dep) → „cyclic dependency”; głębsze cykle pozostają
    zablokowane pod powodem „not integrated yet” (decyzja identyczna — członek
    cyklu nigdy nie osiągnie `done`).
- **Wpięcie** w `WorkOnOrchestrator` (przed jakimkolwiek skutkiem ubocznym):
  `guard_dependencies_satisfied!` sprawdza każdy krok, który miałby wystartować
  (liście oraz aktywne subtaski managera), czyta stan przez `TaskManager#show`
  i przy zablokowaniu rzuca `Error` z powodami; komunikat przypomina, że ukończony
  worker / otwarty PR nie odblokowuje.

Model merge: wymóg wcześniejszego integracji wyraża się zależnością od kroku
integracji poprzednika (np. `grn.0 depends: grm.3`), nie od końca implementacji —
to wymusza sam gate, bo `grm.1 done` nie satysfakcjonuje zależności od `grm.3`.

## Zmienione pliki

- `ace-overseer/lib/ace/overseer/atoms/dependency_readiness.rb` — nowy atom (L6.3).
- `ace-overseer/lib/ace/overseer.rb` — require atomu.
- `ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb` —
  `guard_dependencies_satisfied!` przed provisioningiem worktree/assignmentu.
- `ace-overseer/test/fast/atoms/dependency_readiness_test.rb` — 8 testów atomu.
- `ace-overseer/test/fast/organisms/work_on_orchestrator_test.rb` — 6 nowych
  testów (odmowa/przejście/scenariusze); FakeTask rozszerzony o `id`/`dependencies`.
- `ace-overseer/CHANGELOG.md` — wpis [Unreleased] / Added.
- `ace-overseer/docs/usage.md` — dokumentacja gate'u w sekcji `work-on`.
- `ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md` — reguła 3
  odnotowuje, że `work-on` wymusza ten sam gate mechanicznie.

## Testy

`bin/ace-test ace-overseer all` → **245 tests, 1015 assertions, 0 failures, 0 errors**
(w tym 14 nowych: 8 atomowych + 6 orchestratorowych). Raport:
`.ace-local/test/reports/overseer/` (ostatni run).

## Mapowanie kryteriów odbioru (ze specyfikacji)

1. **„Zadanie B czeka na integrację A mimo ukończenia workera A, a po
   potwierdzeniu integracji staje się odblokowane.”**
   - `test_finished_worker_does_not_unlock_dependent_step`: `grm.1` (Implement A)
     = done, `grm.3` (Integrate A) = pending → start `grn.0` (B) odrzucony,
     worktree/assignment nieutworzone (assert pustych calls).
   - `test_rejects_step_whose_dependency_is_not_integrated_before_side_effects`:
     zależność `in-progress` → odmowa z powodem „not integrated yet”.
   - `test_starts_step_after_dependency_integration_confirmed`: `grm.3` = done
     → start przechodzi, worktree + assignment utworzone.
2. **„Błąd, brak wyniku lub anulowanie wymaganego poprzednika nie są traktowane
   jako udane spełnienie zależności.”**
   - `test_cancelled_dependency_predecessor_is_not_satisfaction` (cancelled),
     atomowy `test_terminal_without_result_is_not_satisfaction` (skipped/cancelled),
     `test_missing_dependency_is_reported` (brak wyniku/refu).
3. **„Wynik jest zgodny z kontraktem programu i możliwy do użycia przez
   następną rolę lub narzędzie.”**
   - Gate w istniejącej ścieżce `ace-overseer work-on` (bez nowych komend,
     silnika, journala, cache, guardów ról w ace-task/ace-assign); decyzja
   oparta o realny stan drzewa `_overseer`; workflow `overseer/queue.wf.md`
   (kontrakt roli) zaktualizowany o wymuszenie; kolejna rola używa tej samej
   powierzchni planner/coworker (L4) — brak nowych ścieżek uruchomieniowych.

Dodatkowo (review gotowości): brakujący i cykliczny poprzednik —
`test_missing_and_cyclic_dependencies_block_start`,
`test_blocked_subtask_blocks_manager_start` (gate działa też na subtaski managera).

## Uwagi / otwarte pytania

- Gate liczy spełnienie wyłącznie ze statusu `done` w drzewie tasków; „proof”
  (testy/review) to nadal odpowiedzialność roli overseera per queue.wf.md —
  status `done` na kroku integracji jest rejestrowany dopiero po potwierdzeniu
  merge (reguła 5 workflowu), więc nie dodaję drugiego mechanizmu dowodowego.
- Nie zmieniono ogólnych reguł ace-task (sorter/TaskValidationRules bez zmian).

## Poprawki po review (runda 1)

Session `review-8xih9y`, 7 findingów (1 Medium, 6 Low; 1 skipped). Applied:
1. (M1) Gate sprawdza też WŁASNE dependencies managera (rodzic z aktywnymi subtaskami = [task] + subtaski); +test manager-own-deps.
2. (+test) multi-ref z jednym zablokowanym krokiem odmawia ALL-OR-NOTHING (gotowy krok też nie startuje).
3. Docstring: „DIRECT cycle detection only"; `dependency_reason` → private_class_method.
4. docs/usage.md: nota o odmowie re-attach do wystartowanego kroku z niespełnionymi deps.
5. docs/usage.md: nota o rozjazdzie z `ace-task list --sort smart` (archived ≠ done; work-on jest authority).
6. Wspólny helper `active_subtasks_of` zamiast 3 kopii filtra terminal-subtask.
Skipped: memoizacja lookupów per inwokacja — wydajność doradcza, poprawna priorytetowo (D×S skanów, akceptowalne).
Retest: `bin/ace-test ace-overseer all` → 247/1027/0.
