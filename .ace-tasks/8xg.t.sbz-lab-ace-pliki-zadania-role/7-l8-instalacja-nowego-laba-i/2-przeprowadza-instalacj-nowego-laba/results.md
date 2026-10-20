# Wyniki — 8xg.t.sbz.7.2 „Przeprowadzać instalację nowego laba" (L8.3)

Data: 2026-10-19 · Branch: `t-sbz-wave-3` (worktree `.ace-wt/t-sbz-wave-3`) ·
ace-lab 0.12.0 → **0.13.0**.

## Co zostało zrobione

Nowa komenda `ace-lab install [--dry-run] [--format table|json] [-q]` — pełna
instalacja nowego laba z zaufanego manifestu przez ORKIESTRACJĘ istniejących
molekuł (nic ich nie dubluje):

1. **Guard obcego laba — PRZED jakąkolwiek mutacją.** Jeśli zaufany dokument
   `/etc/lab/ace-lab/authorization.yml` istnieje i przydziela projekty,
   których manifest nie deklaruje, instalacja kończy się sklasyfikowanym
   błędem („refusing to install over a foreign lab") bez żadnego zapisu —
   identycznie w trybie wet i `--dry-run` (paritet predykcji). Błąd
   weryfikacji/sparsowania dokumentu zaufanego również = odmowa (fail-closed).
2. **prepare (L8.1)** — ten sam organizm `Organisms::Prepare` (konta →
   katalogi → klucze → role), ten sam per-item raport.
3. **project add (L8.2) per projekt z manifestu** — ten sam organizm
   `Organisms::ProjectAdd` (repository / `_overseer` / rejestr); projekty są
   izolowane (porażka jednego nie blokuje pozostałych); niewyprowadzony
   prepare = dependency-failure zamiast próby.
4. **grants (nowe)** — `Molecules::GrantProvisioner` konwerguje sekcję
   `principals` zaufanego dokumentu autoryzacji z sekcji `grants` manifestu:
   to konfiguracja właścicielska instalatora, dzięki której zainstalowane
   projekty są widoczne w `ace-lab projects` / `ace-overseer projects` (zero
   zmian po stronie odczytu — GrantResolver czyta ten sam plik). Granty tylko
   rosną: manifest próbujący USUNĄĆ istniejący grant → odmowa; principalne
   nieobecne w manifeście i wszystkie inne sekcje dokumentu (np. polityka
   adapterów) są zachowane; zapis atomowy (tmp + rename, 0644). Granty są
   konfigurowane tylko przy wyprowadzonych wcześniejszych fazach (brak
   pozornego sukcesu).
5. **Raport końcowy** `{ok, dry_run, machine, manifest, prepare, projects,
   grants}` — co jest zainstalowane/gotowe; wet porażka: render-then-raise
   z listą `<faza>/<item>: <message>`; dry-run: `would_*`, exit 0.

**Schemat manifestu (nadal v1)** zyskał opcjonalne sekcje: `projects`
(id/path/remote/label; unikalne id i path; ścieżki bezwzględne) oraz `grants`
(principal → zadeklarowane id projektów; odmowa referencji do niezadeklarowanych
projektów i duplikatów). Walidacja w `Atoms::InstallSchema`, fail-closed przez
`InstallManifestLoader` (bez zmian ścieżki/zaufania).

## Mapowanie kryteriów odbioru (z taska)

- **„Na świeżym środowisku kończy instalację gotową do project add i
  uruchomienia coworkera."**
  - `test_full_flow_with_real_molecules_on_a_fresh_environment`
    (test/organisms/install_test.rb): prawdziwe molekuły end-to-end — prepare
    tworzy zadeklarowany katalog, projekt klonuje z realnego lokalnego
    origin, powstaje `.ace-tasks/_overseer` + rejestr `.ace/lab/config.yml`
    + grants; ponowny przebieg konwerguje bez duplikatów.
  - Integracyjnie z fazami przez fake-i: `test_happy_path_orchestrates_…`
    (threading id/path/remote/label/dry_run), `test_dry_run_propagates_…`.
  - „Gotowość do project add i coworkera": repository+`_overseer`+rejestr to
    dokładnie wejścia łańcucha planner/koleg z L8.2 (patrz results 7.1);
    grants domykają widoczność w listingach.
- **„Gotowy lub obcy lab powoduje odmowę nadpisania; brak wymaganych
  uprawnień/narzędzi jest konkretnie zgłoszony, bez pozornego sukcesu."**
  - `test_foreign_labs_are_refused_before_any_mutation` (organizm; prepare
    NIE wywołany, dokument bajt w bajt nietknięty) + parity w CLI
    (`test_foreign_lab_is_refused_before_any_mutation`: dry-run przewiduje
    identyczny błąd). Odmowy per-element (takeover obcego katalogu/klucza,
    obcy origin, obcy rejestr) zostają przy własnych molekułach L8.1/L8.2.
  - Braki uprawnień/narzędzi: klasyfikowane komunikaty z prepare (EPERM,
    enoent, exec_failed) i kroków projektu propagują się do raportu install;
    wet porażka ≠ exit 0; grants nie są pisane nad niewyprowadzoną instalacją.
- **„Wynik jest zgodny z kontraktem programu i możliwy do użycia przez
  następną rolę lub narzędzie."**
  - Kontrakt (ADR-034/contract.md): zero nowego właściciela stanu — install
    pisze wyłącznie przez istniejące molekuły + sekcję `principals` istniejącego
    dokumentu zaufanego (nowy wiersz w docs/lab-flow.md). Brak journala:
    idempotentne kroki + raport per-step to wzorzec, na którym buduje .7.3.
  - Następni konsumenci: `ace-lab projects`/`ace-overseer projects` (grants),
    `ace-lab status` (rejestr), L8.4 (.7.3 resume), L8.5 (.7.4 weryfikacja).

## Decyzje o umiejscowieniu

- Wszystko w ace-lab (tam, gdzie żyją L8.1/L8.2 i ich wzorce raportu).
  **ace-overseer bez zmian** — czyta tę samą kaskadę i ten sam plik grants.
- Tożsamość „obcego laba" = wszechświat projektów w zaufanych grants vs
  manifest (machine-global deploy): proste, zgodne z GranterResolver
  (grants strukturalnie globalne, nie per-katalog). Kaskadowe
  projekty/rejestry chronią własnymi odmowami L8.2.
- HITL adaptery: manifestu/grants nie rozszerzam o politykę adapterów;
  GrantProvisioner ZACHOWUJE istniejące sekcje dokumentu (test). Pełna
  orkiestracja adapterów pozostaje poza tym wycinkiem (patrz granice).
- Wersja 0.13.0 (minor); Gemfile.lock odświeżył wpis PATH automatycznie.

## Zmienione pliki

Implementacja: `ace-lab/lib/ace/lab/atoms/install_schema.rb` (sekcje
projects/grants), `.../molecules/grant_provisioner.rb` (nowy),
`.../organisms/install.rb` (nowy), `.../cli/commands/install.rb` (nowy),
`.../cli.rb`, `.../lab.rb`, `.../version.rb`, `Gemfile.lock`.
Testy: `test/atoms/install_schema_test.rb` (+7), 
`test/molecules/grant_provisioner_test.rb` (nowy, 10),
`test/organisms/install_test.rb` (nowy, 8), `test/commands/install_test.rb`
(nowy, 6).
Dokumentacja: `ace-lab/CHANGELOG.md` ([Unreleased]/Added), 
`ace-lab/docs/usage.md` (sekcja „Install (L8.3)", manifest, fale),
`docs/lab-flow.md` (wiersz trusted-tier principal grants + status fali L8 +
adnotacja install przy wierszu rejestru — nowy rodzaj artefaktu: zapis
`principals` dokumentu zaufanego).

## Testy

`bin/ace-test ace-lab all` → **447 tests, 1954 assertions, 0 failures,
0 errors, 4 skipped** (baseline 417; +30 testów: 7 schema, 10 grants,
8 organizm, 6 CLI — w tym 1 real-molecule E2E z lokalnym `git clone`).
`bin/ace-lint` zmienionych markdown: PASS (77 ostrzeżeń w usage.md — te
same klasy co wcześniej: em-dash/tight-list, obecne już w starszych sekcjach).
`bin/ace-test-suite` poza zakresem tej tury (zmiany ograniczone do
ace-lab + dokumentów) — do wykonania przed merge zgodnie z kontraktem.

## Otwarte kwestie / granice (dla .7.3/.7.4)

- **Na czym buduje .7.3 (resume):** brak journala — konwergencja idempotentna
  (konta `exists`, repo `exists`, grants `exists`) plus raport per-step w
  ustalonym kształcie; guard obcego laba rozróżnia „obcy" (grants poza
  manifestem → twarda odmowa) od „własny częściowy" (grants ⊆ manifest →
  konwerguj). .7.3 dopisze rozpoznanie „własna przerwana vs obcy zasób"
  per-katalog (dziś to odmowy per-element molekuł) i komunikat braku
  możliwości wznowienia.
- **Granice tego wycinka:** brak orkiestracji konfiguracji adapterów HITL
  (zachowanie istniejących sekcji dokumentu zaufanego tak; pisanie polityki
  adapterów — nie), brak końcowej weryfikacji pod docelowymi kontami (.7.4),
  brak flagi `--manifest` (świadomie, jak w prepare).
- Subtelność konwergencji grants: gdy plik istnieje z principalami
  nieobjętymi manifestem (grantują tylko zadeklarowane projekty), są one
  raportowane jako `kept` i nietykane — admin może legalnie dopisać
  principal ręcznie; usunięcie grantu wymaga ręcznej edycji (manifest nie
  odbiera uprawnień).

## Poprawki po review (runda 1)

Zastosowano 8 zweryfikowanych ustaleń z sesji review
`.ace-local/review/sessions/review-8xili2/review-report-review-default.md`:

1. **8xilm664 (Med):** `organisms/install.rb` — `dependency_failed_project`
   otrzymuje teraz efektywną wartość `dry_run` per-wywołanie (nie domyślną
   z konstruktora); hash odmowy gates dla grants dopisuje `dry_run` i `kept`.
2. **8xilm665 (Med):** `molecules/grant_provisioner.rb` — zapis jest
   pomijany, gdy zmergowani principals są głęboko-równi sparsowanym
   istniejącym (skutek: skonwergowany re-run wet nie przepisuje pliku —
   komentarze admina i tożsamość pliku (inode/mtime) zostają nietknięte).
3. **8xilm666 (Med):** pusty manifest `grants` + brak dokumentu → NO-OP
   (`status: "skipped"`, komunikat „nothing to write"); pusty plik
   `authorization.yml` nigdy nie jest tworzony.
4. **8xilm667 (Med):** `read_document` waliduje kształt per-principal
   identycznie jak strona odczytu — wspólna walidacja wyekstrahowana do
   `GrantResolver.validate_principals` (używana przez `parse_grants` i
   provisioner), więc reader/writer nie mogą rozjechać się. Malformed
   policy → odmowa z zaklasyfikowanym błędem (bez cichego przepisania);
   klucze principalów są strippowane (padded klucz nie współistnieje ze
   swoją strippowaną bliźniaczą wersją).
5. **8xilm668 (Low):** `require "fileutils"` przeniesiony na górę pliku.
6. **8xilm669 (Low):** klucz `kept` raportu zawsze obecny (pusta tablica,
   gdy nic) — stabilny schemat dla konsumentów JSON.
7. **8xilm66a (Low):** `atoms/install_schema.rb` — duplikaty principalów
   po strip odrzucane (jak duplikaty id projektów).
8. **8xilm66b (Low):** `test_re_run_over_own_converged_lab_converges_without_rewriting`
   rzeczywiście dowodzi braku przepisania: fixture z komentarzem admina +
   asercje stabilności inode/mtime (analogicznie test molekuły
   `test_converged_re_run_does_not_rewrite_the_document`).

Nowe testy regresyjne: dry-run z przewidywaną porażką prepare (per-project
`dry_run: true`), skonwergowany re-run bez przepisania (inode/mtime +
komentarz), pusty `grants` bez dokumentu (brak pliku), malformed policy →
odmowa, padded klucz → zapis strippowany bez bliźniaka, duplikat
principalów po strip w schemacie.

Dokumentacja: CHANGELOG [Unreleased] (semantyka no-op, ostrojsza walidacja
dokumentu, brak przepisywania przy konwergencji) oraz `docs/usage.md`
(sekcja Install: statusy z `skipped`, `kept` zawsze obecne, opis
wspólnej walidacji i no-op).

Weryfikacja: `bin/ace-test ace-lab all` → **453 tests, 1999 assertions,
0 failures, 0 errors, 4 skipped** (baseline po tej turze: 447 → +6 testów).
