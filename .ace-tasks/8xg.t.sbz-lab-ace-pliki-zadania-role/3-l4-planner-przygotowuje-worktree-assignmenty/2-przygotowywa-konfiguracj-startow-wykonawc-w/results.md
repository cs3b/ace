# Wyniki — 8xg.t.sbz.3.2 Przygotowywać konfigurację startową wykonawców (L4.3)

Data: 2026-10-19. Worktree: `.ace-wt/t-sbz-wave-3` (branch `t-sbz-wave-3`).

## Zakres

Tylko `ace-coworker` (lib/models/organisms/cli + testy + docs + CHANGELOG). Zmiany w `ace-lab`/`ace-assign` nie były potrzebne.

## Decyzja o własności (dekonflikt z `commission`)

Wybrano wariant: **prepare pisze konfigurację per rola** w `.ace-local/coworker/prepare/<role>.yml` w worktree zadania, rozwijaną **przez tę samą prymitywę `commission`** (preset → sprawdzenie tożsamości task↔assignment → walidacja schematem startowym → atomowy zapis). Dzięki temu gwarancja round-trip („co commission pisze, start akceptuje") obowiązuje z konstrukcji — potwierdzona testem integracyjnym `start --config .ace-local/coworker/prepare/worker.yml`. Podział: **prepare jest jedynym pisarzem `prepare/<role>.yml`; `commission` pozostaje jedynym pisarzem domyślnego celu `config.yml`** (`--config`/kaskada) — prepare nigdy go nie dotyka. Zaktualizowano docs/usage.md i docs/lab-flow.md (nowy rodzaj artefaktu w wierszu coworker).

Adres overseera dla nóg: `--to`, w przeciwnym razie pole `overseer` z configu coworkera (odczyt lenientny, jak przy eskalacji konfliktów). Brak adresu = twardy błąd `cannot prepare start configs: no overseer address (--to or coworker config)` — nigdy konfiguracja z pustym overseerem ani ciche pominięcie. Błąd powstaje PO kompozycji assignmentów (błędy walidacji ról — unknown role / brak procesu — mają pierwszeństwo), re-prepare z `--to` idempotentnie dopisuje brakujące konfigi.

Idempotencja: identyczna treść → `reused` (zero zapisów), zmieniona treść (np. inny overseer) → `updated`; `--dry-run` → `planned` bez zapisów (dla worktree, który by nie istniał: `start_configs: []`). Nie rusza aktywnego drivera: konflikty `active_executor`/`mismatched_worktree` wykrywane są PRZED jakimkolwiek zapisem konfiguracji. Konfiguracja nogi zawiera wyłącznie udokumentowane pola (bez sekretów, bez kroków assignmentu — odwołanie to id w ace-assign).

## Zmienione pliki

Implementacja:
- `ace-coworker/lib/ace/coworker/organisms/start_config_writer.rb` — NOWY: `Organisms::StartConfigWriter` (jedna konfiguracja na nogę przez prymitywę commission; dispositions created/reused/updated/planned).
- `ace-coworker/lib/ace/coworker/organisms/prepare_orchestrator.rb` — po kompozycji sekwencji: rozwiązanie overseera nóg (`leg_config_overseer`, błąd przy braku), zapis konfiguracji przez writer (`write_start_configs`), injekcja `start_config_writer:`.
- `ace-coworker/lib/ace/coworker/models/preparation.rb` — nowe pole `start_configs` (rola, assignment, ścieżka, disposition) w wyniku JSON/table.
- `ace-coworker/lib/ace/coworker.rb` — autoload `StartConfigWriter`.
- `ace-coworker/lib/ace/coworker/cli/commands/prepare.rb` — sekcja `start configs:` w tabeli.

Testy:
- `ace-coworker/test/organisms/start_config_writer_test.rb` — NOWY (4 testy: created per leg / reused bez zapisu / updated / planned dry-run).
- `ace-coworker/test/organisms/prepare_orchestrator_test.rb` — FakeStartConfigWriter; happy path z asercjami `start_configs`; fallback overseera z configu; błąd braku overseera po kompozycji; dry-run `planned`; `--to` tam, gdzie wymagane.
- `ace-coworker/test/commands/prepare_test.rb` — fixture + asercje renderu tabeli/JSON `start_configs`.
- `ace-coworker/test/commands/prepare_integration_test.rb` — NOWE: `test_prepare_writes_start_configs_that_start_accepts` (round-trip `start --config prepare/worker.yml`, dokładnie udokumentowane pola, brak wycieków), `test_prepare_without_overseer_writes_no_start_configs`; `--to overseer` w przygotowaniach; `.gitignore` `.ace-local/` w fixture (porównania porcelain); asercja `reused` dla konfiguracji nóg.
- `ace-coworker/test/commands/prepare_nested_task_integration_test.rb` — `--to` + `.gitignore` (re-prepare pozostaje zero-write).

Dokumentacja:
- `ace-coworker/CHANGELOG.md` — wpis [Unreleased] (angielski).
- `ace-coworker/docs/usage.md` — nowa sekcja „Start configs per role leg"; prepare (usunięta nota „later leaf" dla L4.3, opis kroków, przykład JSON ze `start_configs`), start (`--config` z prepare), commission (podział własności), tabela exit codes.
- `docs/lab-flow.md` — nowy wiersz mapy kanonicznej: per-role start configs → `.ace-local/coworker/prepare/<role>.yml` → owner `ace-coworker` (planner, przez prepare).

## Testy

`bin/ace-test ace-coworker all`: **367 testów, 1592 asercji, 0 porażek, 0 błędów** (baseline 357 → +10: 4 nowy organism writer, 4 nowe/rozszerzone testy orchestratora, 2 nowe integracyjne; reszta to rozszerzenia asercji istniejących).

## Mapowanie kryteriów odbioru (ze specyfikacji)

1. **„Kolejna rola startuje z własnym kontekstem w worktree zadania; dane assignmentu są referencją do ace-assign."** — `prepare` pisze `.ace-local/coworker/prepare/<role>.yml` (rola, źródło instrukcji, prompt startowy z presetu, task, `assignment: <id>` jako referencja do `.ace-local/assign/`, overseer, reguły raportowania/błędów); test integracyjny `test_prepare_writes_start_configs_that_start_accepts` wykonuje pełną ścieżkę: prepare → `start --config .ace-local/coworker/prepare/worker.yml` w worktree → exit 0.
2. **„Przygotowanie kolejnej roli nie nadpisuje bieżącego stanu aktywnego drivera ani nie przenosi sekretów do taska."** — konflikty `active_executor`/`mismatched_worktree` wykrywane przed zapisem konfiguracji (`test_active_executor_conflict_escalates_without_overwriting` nadal przechodzi, snapshot worktree niezmieniony); prepare nigdy nie pisze domyślnego `config.yml`; zawartość nóg ograniczona do udokumentowanych pól (asercja „no undocumented fields"); brak sekretów — dane wejściowe to task/role/assignment/overseer.
3. **„Wynik jest zgodny z kontraktem i możliwy do użycia przez następną rolę lub narzędzie."** — format identyczny z `config.yml` (kontrakt L3), rozwijany przez prymitywę `commission` (round-trip gwarantowany i testowany); jeden pisarz na plik (prepare: `prepare/<role>.yml`; commission: domyślny cel); `start --config` to oficjalny interfejs konsumpcji; mapa lab-flow zaktualizowana.

## Uwagi / pytania otwarte

- Porządek błędów: brak overseera sygnalizowany jest PO kompozycji assignmentów (assignmenty L4.2 pozostajądeliverable), więc prepare bez `--to` zapisuje assignmenty, ale nie konfigi; re-prepare z `--to` idempotentnie je dopisuje. Jeśli review uzna, że powinno być all-or-nothing przed kompozycją, zmiana jest trywialna, ale odwróciłaby pierwszeństwo błędów ról (unknown role / brak procesu).
- Raport gotowości (L4.4) pozostaje osobnym liściem, jak w specyfikacji.
- `bin/ace-test-suite` całego monorepo oraz niezależny review — poza zakresem tego wykonawcy (wg zasad fali).
