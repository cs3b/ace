# Wyniki — 8xg.t.sbz.6.1 „Zebrać konfigurowalny status overseera" (L7.2)

Data: 2026-10-19 · Worktree: `t-sbz-wave-3` · Zakres: `ace-overseer/**` (+ powiązane doky), bez `ace-herdr/ace-handbook-integration-pi` (właściciel równoległy .6.2).

## Co zrobiono

Rozszerzono istniejący `ace-overseer status` (StatusCollector) o konfigurowalne źródła — bez konkurencyjnego dashboardu, bez nowego stanu (status liczony na żywo, nic nie jest utrwalane; ADR-034).

- Nowy organizm `ace-overseer/lib/ace/overseer/organisms/status_sources.rb` (`Organisms::StatusSources`): sześć adapterów read-only nad interfejsami właścicieli:
  - `worktrees` — istniejący pipeline StatusCollector (WorktreeManager + kontekst przydziałów; publiczna powierzchnia `ace-git-worktree list`),
  - `forge` — forge-neutralny kontrakt ace-git `Providers#recent_pull_requests` (ten sam registry, którego używają ace-review/ace-git); **domyślnie wyłączony** w `.ace-defaults/overseer/config.yml` (`status_sources.forge.enabled: false`),
  - `project_tasks` — `ace-task` TaskManager, `.ace-tasks/` (`list(in_folder: "all")`): id, status, tytuł, priorytet, zależności,
  - `overseer_tree` — ten sam właściciel, folder prywatny `--in _overseer`,
  - `herdr` — READ-ONLY przez bibliotekę ace-herdr: `ControlSurface` (list_workspaces/tabs/panes) + `StatusComposer` — dokładnie ta sama kompozycja co `ace-herdr status`,
  - `coworkers` — `ace-coworker WorktreeExecutorProbe` (skonfigurowany config + inwentarz przydziałów) + `ActiveExecutorRule`.
- `StatusCollector#collect_sources` agreguje źródła wg `status_sources` z konfiguracji; każde źródło zwraca `{status: "ok", origin:, data:}` / `{status: "disabled"}` / `{status: "error", origin:, error:}`. `to_sources_table` renderuje sekcje `-- <source>` z jawnym originem, markerami `disabled`/`ERROR`; `to_sources_h` daje kontrakt JSON.
- CLI `status` (run_once) używa widoku źródeł; `--format json` emituje `{sources: {...}}` z pochodzeniem per źródło. `--watch` odświeża dashboard worktree (sekcja quick-refresh), bez zmiany semantyki.
- Domyślna konfiguracja: `ace-overseer/.ace-defaults/overseer/config.yml` + sekcja `status_sources`.
- Doky: `ace-overseer/docs/usage.md` (sekcja status: tabela źródeł, konfiguracja, kontrakt JSON), wpis [Unreleased] w CHANGELOG. `docs/lab-flow.md` — bez zmian (żaden nowy rodzaj artefaktu; status jest wyliczany na żywo).

## Dekomisja błędów źródła (offline forge)

Źródło `forge` jest domyślnie wyłączone. Po włączeniu w projekcie/użytkowniku, przy braku skonfigurowanego serwera, braku CLI providera lub sieci — `fetch` rzuca (np. `AmbiguousRemoteError`, `ProviderCliMissingError`), a agregator zamienia to na wpis `{status: "error", origin:, error:}` renderowany OBOK zdrowych wyników; nigdy jako „brak otwartych PR".

## Mapowanie kryteriów odbioru

1. **Jeden widok: trwające kroki, gotowa praca, zależności, zasoby; wyłączenie źródła respektowane.**
   - Implementacja: `collect_sources` + render tabeli (sekcje per źródło: postępy kroków przydziałów w `worktrees`, statusy+zależności w `project_tasks`/`overseer_tree`, PR-y w `forge`, żywy layout w `herdr`, executory w `coworkers`).
   - Testy: `status_sources_test.rb#test_all_sources_ok_report_status_origin_and_data`, `#test_disabled_source_in_config_is_respected`, `#test_source_without_configured_entry_defaults_to_enabled`; CLI: `status_command_test.rb` (json/table).
2. **Awaria źródła pokazana obok dostępnych wyników; brak danych ≠ wolny worktree/zakończone zadanie.**
   - Testy: `#test_one_failing_source_shows_error_next_to_available_results`, `#test_table_renders_disabled_and_error_markers`, `#test_worktrees_source_failure_is_error_not_empty_list`, `#test_forge_source_offline_raises_and_aggregates_as_error`, `#test_herdr_source_unreachable_runtime_raises`, `#test_coworkers_source_unknown_commissioned_assignment_reads_busy_unknown`, `#test_coworkers_source_unparseable_config_reads_busy`, `#test_coworkers_source_per_worktree_failure_shows_next_to_results` (nieznany przydział → `active: true, state: "unknown"` — przez regułę właściciela ace-coworker, bez reimplementation).
3. **Zgodność z kontraktem i używalność przez następną rolę/narzędzie.**
   - JSON: `{sources: {<name>: {status: ok|disabled|error, origin:, data:|error:}}}`; test `#test_all_sources_ok_report_status_origin_and_data` (parsowanie JSON) + `status_command_test.rb#test_one_shot_json_output`. Zweryfikowano też żywe wywołanie `bin/ace-overseer status --format json` w worktree (poprawny JSON, origin per źródło).

## Weryfikacja

- `bin/ace-test ace-overseer all` → **327 testów, 1363 asercji, 0 błędów** (baseline 310; +17 nowych testów w `test/fast/organisms/status_sources_test.rb` i zaktualizowanym `test/fast/commands/status_command_test.rb`).
- Smoke na żywo: `bin/ace-overseer status --format json` zwraca pełny agregat (sekcje sources, origin, dane).

## Zmienione pliki

- `ace-overseer/lib/ace/overseer/organisms/status_sources.rb` (nowy)
- `ace-overseer/lib/ace/overseer/organisms/status_collector.rb`
- `ace-overseer/lib/ace/overseer/cli/commands/status.rb`
- `ace-overseer/lib/ace/overseer.rb` (require ace-herdr + status_sources)
- `ace-overseer/.ace-defaults/overseer/config.yml`
- `ace-overseer/test/fast/organisms/status_sources_test.rb` (nowy)
- `ace-overseer/test/fast/commands/status_command_test.rb`
- `ace-overseer/test/test_helper.rb` (ścieżka ace-herdr)
- `ace-overseer/docs/usage.md`, `ace-overseer/CHANGELOG.md`

## Decyzje / otwarte pytania

- `forge` listuje PR-y przez `recent_pull_requests`; listowanie issues nie istnieje w kontrakcie providera (tylko `issue(number:)` per sztuka), więc sekcja forge = PR-y; pojedyncze issues wchodzą przez tracking ace-task po id.
- `--watch` pozostaje na dashboardzie worktree (quick-refresh `collect_quick`); pełny widok źródeł to jednorazowy `status`. Pełne odświeżanie źródeł w watch pozostaje poza zakresem.
- Otwarte (dla fali): czy `ace-lab status` (równoległa .6.x) ma konsumować ten sam JSON `sources` — kontrakt jest gotowy do użycia.

## Poprawki po review (runda 1)

Zastosowano 5 zweryfikowanych ustaleń z `.ace-local/review/sessions/review-8xijh6/review-report-review-default.md`:

1. **(Medium, 8xijm9wp)** Wiersz głównego repozytorium tracił etykietę `main` w tabeli źródeł: `context_to_h`/`context_from_h` serializują i odtwarzają teraz `location_type` (i `tmux_window` dla symetrii). Test: `test_sources_table_keeps_main_label_and_sorts_main_last`, `test_worktrees_payload_serializes_location_type` — main renderuje się z przygaszoną etykietą i sortuje ostatni.
2. **(Medium, 8xijm9wq)** Nieznane klucze w `status_sources` nie są już cicho ignorowane: literówka w nazwie źródła (`herder:`) renderuje `-- herder: unknown source (ignored)`, literówka w opcji (`enabeld: false`) renderuje `-- forge.enabeld: unknown option (ignored)`; oba trafiają też do `unknown_keys` w JSON (obok `sources`), zgodnie z kontraktem trójstanowym. Testy: `test_unknown_source_and_option_keys_render_warnings`, `test_known_config_keys_are_not_reported_unknown`.
3. **(Low, 8xijm9wr)** `to_sources_table`: dodano `next if result.nil?` — `filter_map` faktycznie filtruje, a częściowy snapshot (brak wpisu źródła) już nie wybucha. Test: `test_to_sources_table_skips_missing_snapshot_entries`.
4. **(Low, 8xijm9ws)** CLI `Status#initialize` przekazuje wstrzykiwany `config` do domyślnego kolektora (`Organisms::StatusCollector.new(config: config)`). Test: `status_command_test.rb#test_injected_config_is_forwarded_to_default_collector`.
5. **(Low, 8xijm9wt)** `ForgeSource` waliduje `limit` przez `Integer(...)` z fallbackiem do `DEFAULT_LIMIT` (literówki/brak), jawne `0` → pusta lista, ujemne → `0`. Testy: `test_forge_limit_config_is_wired_through`, `test_forge_limit_typo_falls_back_to_default`, `test_forge_explicit_zero_limit_lists_nothing`, `test_forge_negative_limit_clamps_to_zero`.

Weryfikacja po poprawkach: `bin/ace-test ace-overseer all` → **337 testów, 1395 asercji, 0 błędów** (+10 testów względem 327 przed rundą). CHANGELOG `[Unreleased]` zaktualizowany (sekcja Fixed).
