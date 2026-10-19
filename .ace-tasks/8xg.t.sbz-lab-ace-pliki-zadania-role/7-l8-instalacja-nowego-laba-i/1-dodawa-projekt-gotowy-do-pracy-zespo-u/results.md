# Wyniki — 8xg.t.sbz.7.1 „Dodawać projekt gotowy do pracy zespołu" (L8.2)

Data: 2026-10-19 · Branch: `t-sbz-wave-3` (worktree `.ace-wt/t-sbz-wave-3`)

## Co zostało zrobione

Nowa komenda `ace-lab project add <id> --path <katalog> [--remote URL] [--label L]`
(--dry-run, --format table|json, -q) — właścicielem jest ace-lab, czyli pakiet,
w którym żyje powierzchnia instalatora (`ace-lab prepare`, L8.1). Trzy idempotentne
kroki w stałej kolejności (organizm `Ace::Lab::Organisms::ProjectAdd`):

1. **repository** (`Molecules::RepositoryProvisioner`) — brakujący/pusty katalog
   jest klonowany z `--remote`; istniejące repozytorium bez origin dostaje origin;
   repozytorium z *innym* origin oraz niepusty katalog niebędący repozytorium są
   odrzucane („refusing to overwrite" / „refusing to take over") — nic nie jest
   nadpisywane ani przejmowane.
2. **overseer** (`Molecules::OverseerProvisioner`) — przygotowanie prywatnego,
   nieśledzonego `.ace-tasks/_overseer/` oraz wpisu w `.gitignore` (ADR-034);
   istniejąca zawartość `.gitignore` i folderu nigdy nie jest modyfikowana ani
   wyliczana.
3. **registry** (`Molecules::ProjectRegistry`) — rejestracja projektu
   (id/label/path/remote) w `<projekt>/.ace/lab/config.yml`, czyli w projektkowym
   poziomie zwykłej kaskady konfiguracji laba (ADR-022). Przed zapisem:
   walidacja całego dokumentu przez `TopologySchema`, odmowa przy sprzecznej
   rejestracji (ten sam id, inny path/remote), konflikcie lokalizacji (ta sama
   ścieżka, inny id), nieczytelnym dokumencie lub obcym `schema_version`.

Zależności: nieudany krok repository oznacza kroki overseer/registry jako
„dependency failure" zamiast je wykonywać (wzorzec z `ace-lab prepare`).
`--dry-run` przewiduje (`would_*`) bez mutacji i kończy się 0; mokry błąd
drukuje raport i kończy się niezerowo z listą kroków.

## Mapowanie kryteriów odbioru (z taska)

- **„Dodany projekt jest widoczny w statusie, a planner może przygotować jego
  pierwszy task bez ręcznego naprawiania katalogów."**
  - `ace-lab status` uruchomiony z korzenia dodanego projektu: `configured —
    <path>/.ace/lab/config.yml (topology: 1 project(s)…)` + `overseer prepared`
    (potwierdzone ręcznie E2E i w testach przez `ConfigStateClassifier`).
  - Listing projects przez istniejącą powierzchnię topologii:
    `TopologyService#projects` (to, co wywołuje `ace-lab projects` i
    `ace-overseer projects`) zwraca dodany id — test
    `test_registered_project_is_listed_by_the_topology_query_surface`.
  - Planner (`ace-coworker prepare`, L4) potrzebuje: repozytorium (klon z
    origin, z którego `ace-git-worktree` tworzy taskowe worktree), `.ace-tasks/`
    (w repo) i przygotowanego `_overseer` — test
    `test_full_flow_makes_the_project_ready_for_team_work` weryfikuje
    `git check-ignore .ace-tasks/_overseer` i obecność `.git`.
- **„Ponowne dodanie nie niszczy konfiguracji ani zmian istniejącego projektu;
  konflikt lokalizacji jest zgłaszany przed nadpisaniem."**
  - Re-add: wszystkie kroki `exists`, rejestr i `.gitignore` bajt w bajt
    niezmienione, prywatne pliki overseera nienaruszone
    (`test_re_add_revalidates_without_destroying_anything`).
  - Odmowy przed zapisem: obcy origin repozytorium, obcy niepusty katalog,
    ten sam id z innym path/remote, ta sama ścieżka pod innym id, nieczytelny
    lub obcy rejestr — testy w `repository_provisioner_test.rb`,
    `project_registry_test.rb`, `project_add_test.rb`,
    `project_add_test.rb` (CLI).
- **„Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną
  rolę lub narzędzie."**
  - Kontrakt: lab przygotowuje środowisko i projekty, nie prowadzi kolejki;
    jedyny trwały artefakt to projektkowy dokument kaskady `.ace/lab/config.yml`
    (zmapowany w `docs/lab-flow.md` z właścicielem `ace-lab project add`);
    zero nowego właściciela stanu, zero journala/rejestru topologii poza kaskadą.
  - Następni konsumenci bez zmian po stronie odczytu: `ace-lab status`,
    `ace-lab projects`, `ace-overseer projects`, `ace-coworker prepare`.

## Decyzja o umiejscowieniu

`ace-lab project add` w ace-lab — tam, gdzie żyje L8.1 (`prepare`) i jego
wzorce (manifest, idempotentne provisionery, raport + kody wyjścia).
**ace-overseer nie wymagał zmian**: jego `projects` czyta topologię przez
`Ace::Lab::Organisms::TopologyService`, a ta czyta tę samą kaskadę, do której
pisze `project add`. Pola `path`/`remote` w wpisach projektów są ignorowane
przez `TopologySchema` (nieznane klucze) i nie wyciekają przez
`PublicProjection` (allowlista id/label).

## Zmienione pliki

Implementacja: `ace-lab/lib/ace/lab/molecules/repository_provisioner.rb` (nowy),
`.../molecules/overseer_provisioner.rb` (nowy), `.../molecules/project_registry.rb`
(nowy), `.../organisms/project_add.rb` (nowy), `.../cli/commands/project_add.rb`
(nowy), `.../cli.rb` i `.../lab.rb` (rejestracja/wymagania).
Testy: `ace-lab/test/molecules/{repository_provisioner,overseer_provisioner,project_registry}_test.rb`,
`ace-lab/test/organisms/project_add_test.rb`, `ace-lab/test/commands/project_add_test.rb` (nowe).
Dokumentacja: `ace-lab/CHANGELOG.md` ([Unreleased]/Added), `ace-lab/docs/usage.md`
(sekcja „Project add (L8.2)"), `docs/lab-flow.md` (wiersz rejestru + status fali L8).

## Testy

`bin/ace-test ace-lab all` → **408 tests, 1710 assertions, 0 failures, 0 errors,
4 skipped** (przed zmianą: 297 tests). Nowych testów: 41 (9 repository, 5 overseer,
10 registry, 6 organism, 6 CLI). Żaden inny pakiet nie był zmieniony.
Dodatkowe ręczne E2E (smoke): pełny obieg add → re-add → `ace-lab status`
z korzenia projektu (patrz wyżej).

## Otwarte kwestie / granice

- „Presety ról i komunikacja" z opisu zachowania to fakty maszynowe: role,
  konta i klucze zwięzie konwerguje `ace-lab prepare` (L8.1) z zaufanego
  manifestu; konfiguracja adapterów HITL i pełna orkiestracja instalacji
  należą do `ace-lab install` (7.2/L8.3). `project add` celowo tego nie
  dubluje — rejestruje projekt i przygotowuje jego pliki.
- Wpisy `path`/`remote` w rejestrze są danymi instalatora; publiczna
  projekcja topologii ich nie ujawnia (świadomie).
- Nie wykonano `bin/ace-test-suite` na całym monorepo (poza zakresem tej
  tury; zmiany ograniczone do ace-lab + dokumentów) — do wykonania przed
  merge zgodnie z kontraktem.
