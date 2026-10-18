# Wynik realizacji — 8xg.t.sbz.6.0 (L7.1: statusy laba Herdr i worktree)

Data: 2026-10-18. Ten sam worktree i ten sam PR #383 (fala 1).

## Co powstało

- **`ace-herdr status`** (0.6.1 → 0.7.0): nowy organizm
  `Ace::Herdr::Organisms::Status` składa istniejące `list_workspaces` /
  `list_tabs` / `list_panes` w jedno drzewo workspaces > tabs > panes;
  klasyfikuje stan runtime: `available` (w tym poprawnie pusty układ — zero
  countów, nie „unavailable"), `unavailable` (brak binarki/runtimeu — nigdy
  jako pusty gotowy lab; z podpowiedzią), `error` (runtime odpowiedział
  błędem). Sieroty z race'u snapshotu (tab bez workspace, pane bez tab)
  trafiają do `unattached` i liczą się do totali. Tabela domyślnie,
  `--format json`, exit 0 zawsze gdy raport się renderuje; nic nie startuje,
  nic nie zapisuje.
- **`ace-lab status`** (0.10.0 → 0.11.0): `Ace::Lab::Organisms::Status`
  w trzech sekcjach. `configuration`: tri-state `configured` (jawne źródła
  kaskady + zagregowane county projects/agents/services, bez id/endpointów),
  `not_configured` (brak jawnej konfiguracji — wyraźnie oznaczone, nie pusty
  gotowy lab), `error` (niepoprawny YAML/schema; komunikat z ścieżką, bez
  treści). `state_files`: obecność i liczba wpisów canonicalnych lokalizacji
  z docs/lab-flow.md; nieobecny coworker/`_overseer` to informacja, nie
  gotowość. `worktree_view`: wskaźnik na istniejące `ace-git-worktree list`
  (k9y) — bez duplikacji implementacji i bez subprocessu.
- Rejestracja obu komend w CLI + help; dokumentacja usage/README/CHANGELOG.

## Kryteria odbioru

- [x] Bez starego procesu właściciela laba widać konfigurację i lokalny stan;
  Herdr pokazuje rzeczywisty układ, a worktree zachowują skojarzenia z
  taskami — `ace-lab status` czyta kaskadę + pliki; `ace-herdr status`
  renderuje żywe drzewo; skojarzenia tasków dostarcza istniejące
  `ace-git-worktree list` (k9y, done), wskazane w sekcji worktree_view.
- [x] Nieobecny runtime lub niepełna konfiguracja są oznaczone, a nie
  przedstawione jako pusty i gotowy lab. Nie dublować funkcji k9y —
  tri-state ściśle rozdzielone (testy 2/3/4 w herdr; 7/8/9 w lab); widok
  worktree to pointer, nie druga implementacja.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez
  następną rolę lub narzędzie — schema JSON udokumentowana w usage;
  L7.2 (konfigurowalny status overseera) konsumuje te wyjścia.

## Scenariusze odbiorowe (realne wywołania, 2026-10-18)

- Konfiguracja + dostępny Herdr: w projekcie z `.ace/lab/config.yml`
  (1 project, 1 agent, 1 service) `ace-lab status` → `configured (...)`,
  sekcja Local state z obecnością katalogów; `ace-herdr status` przy żywym
  runtime → `available`, `Workspaces: 0 Tabs: 0 Panes: 0`,
  `No herdr workspaces, tabs, or panes.` (poprawnie pusty zbiór ≠ brak
  runtimeu). `--format json` parsuje się zgodnie ze schema.
- Niedostępny Herdr (PATH bez /opt/homebrew/bin): `Herdr runtime:
  unavailable - herdr CLI not found or not executable: herdr` + podpowiedź,
  exit 0.
- Brak konfiguracji laba (root repozytorium): `Lab configuration: not
  configured (no .ace/lab/config.yml or ~/.ace/lab/config.yml)`, exit 0.

## Weryfikacja

- `bin/ace-test ace-herdr` — 603 testy, 0 błędów (nowe:
  `test/fast/organisms/status_test.rb` — 5 przypadków,
  `test/fast/commands/status_test.rb` — 7 przypadków).
- `bin/ace-test ace-lab` — 187 testów, 0 błędów (nowe:
  `test/organisms/status_test.rb` — 6 przypadków,
  `test/commands/status_test.rb` — 5 przypadków).
- Lint: usage/README/CHANGELOG obu gemów — passed (tylko ostrzeżenia).
