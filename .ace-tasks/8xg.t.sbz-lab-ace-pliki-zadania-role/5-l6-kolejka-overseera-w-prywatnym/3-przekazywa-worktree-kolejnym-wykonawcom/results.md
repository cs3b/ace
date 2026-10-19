# Wyniki — 8xg.t.sbz.5.3 Przekazywać worktree kolejnym wykonawcom (L6.4)

Data: 2026-10-19. Branch `t-sbz-wave-3`, worktree `.ace-wt/t-sbz-wave-3`.

## Co powstało

Nowa komenda **`ace-overseer handoff --task <ref>`** — overseer przekazuje TEN SAM worktree
zadania następnej roli w przygotowanej sekwencji ról, pilnując jednego aktywnego wykonawcy.
Brama czyta wyłącznie rzeczywisty stan (bez nowego stanu/kolejki — ADR-034):

- przydziały sekwencji ról z plików ace-assign w worktree (`.ace-local/assign/*/assignment.yaml`,
  `task_id` zadania, kolejność wg `created_at` — kolejność kompozycji plannera),
- aktualny stan każdego assignmentu (inwentarz przez `WorktreeExecutorProbe`),
- config startowe nóg `.ace-local/coworker/prepare/<role>.yml` (rola ↔ assignment),
- prawdę o wykonawcy worktree przez istniejącą regułę `Ace::Coworker::Atoms::ActiveExecutorRule`
  (commissioned config / in-flight / unparseable).

Zasady egzekwowane mechanicznie (atom `Atoms::HandoffReadiness`):

- następna noga = pierwsza niedokończona; handoff gotowy tylko, gdy wszystkie wcześniejsze
  nogi mają stan ace-assign `completed` (istniejący model stanów — bez nowych semantyk),
- noga `failed` / `running` / `stalled` / nieznany/nieczytelny stan ⇒ odmowa z powodami
  (nieznany stan NIE jest wolnym zasobem i nie pozwala nadpisać pracy),
- aktywny wykonawca w worktree (commissioned/in-flight/unparseable) ⇒ odmowa — dwóch
  aktywnych wykonawców jest niemożliwych,
- brak configu startowego dla następnej nogi ⇒ odmowa (idempotentne `ace-coworker prepare`
  jest drogą naprawy); nic nie jest przygotowywane ponownie — następna rola startuje
  z istniejącego configu,
- sukces: otwiera okno terminalu w tym samym worktree (ta sama powierzchnia `WindowOpener`
  co work-on, preset `window_presets.handoff`) i drukuje dokładne polecenie
  `ace-coworker start --config .ace-local/coworker/prepare/<role>.yml`; `--dry-run` = pełny
  check bez efektów; `sequence_complete` gdy cała sekwencja ukończona,
- handoff nigdy nie tworzy worktree (tylko istniejący; `WorktreeManager#switch`) i dotyczy
  wyłącznie worktree wskazanego zadania — dwa różne taski handoffują niezależnie we własnych
  worktree.

## Zmienione pliki

Implementacja (ace-overseer):
- `ace-overseer/lib/ace/overseer/atoms/handoff_readiness.rb` (nowy, czysty atom gate)
- `ace-overseer/lib/ace/overseer/molecules/handoff_probe.rb` (nowy, read-only sonda nóg)
- `ace-overseer/lib/ace/overseer/organisms/handoff_orchestrator.rb` (nowa orkiestracja)
- `ace-overseer/lib/ace/overseer/cli/commands/handoff.rb` (nowa komenda CLI + rejestracja w `cli.rb`)
- `ace-overseer/lib/ace/overseer.rb` (requires), `ace-overseer/.ace-defaults/overseer/config.yml` (`window_presets.handoff`)
- `ace-overseer/ace-overseer.gemspec` — **jedyna zmiana międzypakietowa**: nowa zależność
  runtime `ace-coworker (~> 0.5)`, uzasadniona poniżej.

Testy: `test/fast/atoms/handoff_readiness_test.rb` (9), `test/fast/molecules/handoff_probe_test.rb` (4),
`test/fast/organisms/handoff_orchestrator_test.rb` (9), `test/fast/commands/handoff_command_test.rb` (8).

Dokumentacja: `ace-overseer/CHANGELOG.md` [Unreleased], `ace-overseer/docs/usage.md`
(sekcja `ace-overseer handoff` + Command Surface + L6), `ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md`
(sekcja 4 odtwarza teraz mechaniczną bramę). Bez nowego rodzaju artefaktu ⇒ bez nowego wiersza w `docs/lab-flow.md`.

## Decyzje projektowe

1. **Handoff = brama + raport/start, nie nowy stan.** Zakończenie poprzedniej nogi to stan
   `completed` jej assignmentu w ace-assign (istniejący właściciel stanu); przejęcie nie
   zapisuje żadnego nowego faktu. Następna rola startuje z istniejącego configu
   `prepare/<role>.yml` — dokładnie ta sama powierzchnia, którą pisze `ace-coworker prepare`.
2. **Zależność `ace-coworker`** w gemspec: reuse jednej, istniejącej reguły aktywnego
   wykonawcy (`ActiveExecutorRule`) i sondy (`WorktreeExecutorProbe`) zamiast drugiej,
   rozbieżnej kopii tej polityki w ace-overseer (read-only; coworker nie zależy od overseera,
   brak cyklu). Zmiana minimalna: jeden wiersz gemspec + require + wpis w test_helper.
3. **Kolejność nóg** z `created_at` assignmentów (rzeczywista kolejność kompozycji), nie z
   parsowania opisów ani z drugiej listy sekwencji.
4. **Odmowa zamiast milczenia**: każdy przypadek braku gotowości kończy się błędem z konkretnymi
   powodami (exit ≠ 0), zgodnie z regułą „brak danych ⇒ wyjaśnienie/wznowienie, nie drugi agent".

## Mapowanie kryteriów odbioru

- „Worker kończy, następnie startuje reviewer, potem integrator; dwa różne taski mogą
  korzystać z różnych worktree" — pozytywny:
  `HandoffOrchestratorTest#test_finished_worker_hands_worktree_to_reviewer_in_same_worktree`
  (worker `completed` → next reviewer, okno w tym samym worktree, `start_config` prepare/reviewer.yml),
  `#test_second_task_in_its_own_worktree_hands_off_independently` (task B handoffuje we własnym
  worktree, gdy worktree tasku A zajęte — równoległość), atom: `test_finished_predecessor_unlocks_next_leg`,
  sonda: `test_reads_ordered_legs_with_states_and_roles` (sekwencja worker→reviewer→…).
- „Zajęte worktree nie otrzymuje drugiego wykonawcy; nieznany stan nie oznacza wolnego zasobu
  ani pozwolenia na nadpisanie zmian" — negatywny:
  `#test_commissioned_active_executor_never_gets_a_second_one` (commissioned `running`),
  `#test_predecessor_not_terminal_refuses_and_starts_nothing` (noga `running`),
  `#test_unreadable_worktree_state_is_not_a_free_resource` (config `unparseable`),
  atom: `test_active_executor_refuses_regardless_of_states`, `test_predecessor_not_terminal_refuses_instead_of_handing_off`,
  `test_failed_predecessor_is_not_a_finished_leg`, `test_unknown_state_is_not_a_free_resource`,
  `test_stalled_next_leg_refuses_too`, `test_next_leg_without_start_config_refuses`,
  `test_empty_sequence_refuses`; CLI: `test_refused_handoff_surfaces_the_reason_as_cli_error`.
- „Wynik zgodny z kontraktem i możliwy do użycia przez następną rolę lub narzędzie" —
  wynik `handoff` to status + `{role, assignment, start_config}` i drukowane polecenie
  `ace-coworker start --config …` (komenda CLI jest konsumentem), `--dry-run` bez efektów
  (`test_dry_run_reports_next_leg_without_effects`, `#test_dry_run_flag_reaches_the_orchestrator`),
  `sequence_complete` zamyka obieg (`test_completed_sequence_reports_sequence_complete`).

## Weryfikacja

- `bin/ace-test ace-overseer all` → **277 tests, 1138 assertions, 0 failures, 0 errors**
  (baseline 247; +30 nowych testów). Pakiet ace-coworker/ace-assign/ace-task nietknięte
  (odczyt istniejących powierzchni).

## Otwarte pytania

- Czy reviewer ma własną regułę akceptu 3/2/10 mapowaną na stan assignmentu — w L6.4
  zakończenie nogi to `completed` assignmentu; ewentualne węższe bramy (np. liczniki rund)
  zostają w competencji roli w jej assignmentie (bez nowych semantyk statusów po stronie overseera).

## Poprawki po review (runda 1)

Session `review-8xihst`, werdykt Approve, 9 findingów (1 Medium, 8 Low; 2 skipped). Applied:
1. (M1) Fail-closed: puste role/brak configu odrzucane przed :ready; probe przenosi WŁAŚCIWIE znalezioną ścieżkę pliku (glob), orchestrator/CLI używają jej zamiast budować zgadywaną.
2. Guard na `result[:next]` w CLI (odmowa wydruku zgadywanej komendy).
3. Renderowanie nil evidence ("unknown" zamiast pustego id przy unparseable).
4. PREPARE_DIR reuse: HandoffProbe używa constanty StartConfigWriter (jedna definicja lokalizacji).
5. Asercja `handoff` w CLI help test; „four primary commands" w usage.md.
Skipped: E2E TS scenario (propozycja na kolejną falę), kolekcja wielu powodów (niepotrzebna przy obecnej wielkości).
Retest: `bin/ace-test ace-overseer all` → 278/1143/0.
