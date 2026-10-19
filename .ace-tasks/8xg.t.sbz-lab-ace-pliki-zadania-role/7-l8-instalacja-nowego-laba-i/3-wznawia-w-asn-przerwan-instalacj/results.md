# Wyniki — 8xg.t.sbz.7.3 „Wznawiać własną przerwaną instalację" (L8.4)

Data: 2026-10-19 · Branch: `t-sbz-wave-3` (worktree `.ace-wt/t-sbz-wave-3`) ·
ace-lab 0.13.0 (wpis w [Unreleased]; bez bumpu wersji — brak nowego
zachowania runtime, zmiana to udowodnienie + utrwalenie kontraktu resume
w testach/dokumentacji + drobna poprawka schematu raportu).

## Kryteria odbioru (cytat ze specyfikacji) i mapowanie

> - [ ] Przerwanie po kontach lub katalogach i ponowne uruchomienie kończą
>   tę samą instalację bez duplikatów i utraty konfiguracji.
> - [ ] Obcy katalog lub niespójny stan nie są automatycznie przejmowane ani
>   czyszczone; brak możliwości wznowienia daje konkretną informację.
> - [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez
>   następną rolę lub narzędzie.

### 1. Przerwanie i ponowne uruchomienie kończą tę samą instalację

Nowe testy `test/organisms/install_resume_test.rb` (14 testów, PRAWE
molekuły; tylko seam zaufanego odczytu i passwd są stubowane — wzorzec z
install_test) symulują stany po awarii na każdej granicy kroku i dowodzą
konwergencji bez niszczenia wykonanej pracy:

- `test_interrupted_before_directories_completes_the_same_install` —
  konta „gotowe" (passwd seam) → `exists`; katalogi/klucze/role/projekty/
  grants dokończone (`created`); pełny raport ok, `_overseer` + rejestr +
  dokument grants istnieją.
- `test_interrupted_after_directories_reports_exists_without_rework` —
  status `exists` ORAZ ten sam inode skonwergowanego katalogu (brak
  destrukcyjnego przerobu).
- `test_interrupted_after_keys_reports_exists_with_stable_fingerprint` —
  `exists` ze stabilnym fingerprintem; inode klucza prywatnego nietknięty.
- `test_interrupted_mid_key_pair_regenerates_only_the_public_half` — crash
  między prywatnym a publicznym półkluczem: regeneruje TYLKO `.pub`
  z ocalałego klucza prywatnego (inode prywatnego stabilny).
- `test_interrupted_after_first_project_finishes_the_second_without_rework`
  — atlas `exists` (plik roboczy w worktree zachowany), borealis
  `created`, grants `created`.
- `test_interrupted_before_grants_only_writes_the_grants` — cały prepare +
  projekty `exists`, jedyny brakujący krok (grants) jest wykonany.
- `test_partially_written_own_grants_converge_and_keep_foreign_sections` —
  własne częściowe grants (tylko [atlas]) → `updated` do [atlas,
  borealis]; sekcja `hitl` dokumentu zaufanego zachowana.
- `test_ready_own_lab_re_run_is_a_converged_no_op` — odróżnienie od LABA
  GOTOWEGO: pełny re-run = same `exists`, dokument zaufany i klucz bez
  zmiany inode/mtime, rejestr bez duplikatów.

Rozpoznanie „własna przerwana" jest wyprowadzone z realnych artefaktów
(statusy `exists`/`verified` + guard grants ⊆ manifest) — zero journala,
zero markerów, zero nowych właścicieli stanu.

### 2. Obce/niespójne zasoby: odmowa, nie przejęcie; konkretna informacja

- `test_foreign_project_directory_is_refused_without_cleanup` — nie-Git,
  niepusty katalog projektu → „refusing to take over a foreign location";
  zawartość nietknięta; izolacja: borealis dalej konwerguje; grants
  gated (`failed`, plik powstaje dopiero po pełnej konwergencji).
- `test_foreign_repository_origin_is_refused_not_overwritten` — obcy
  origin → „refusing to overwrite an existing registration"; origin
  pozostaje niezmieniony.
- `test_foreign_declared_directory_gates_the_install_concretely` — symlink
  w miejscu deklarowanego katalogu → „symbolic link; refusing";
  zależne projekty jako dependency-failure („fix the prepare phase
  first"), grants gated; symlink i cel nietknięte.
- `test_foreign_grants_document_refuses_even_over_own_partial_state` —
  dokument zaufany z grantem poza manifestem (zephyr) → twarda odmowa
  „refusing to install over a foreign lab" PRZED mutacją, także nad
  własnym stanem częściowym; plik bajt w bajt, zapisy: zero.
- „Brak możliwości wznowienia daje konkretną informację": CLI (`install
  failure` renderuje raport, potem błąd `install failed (N step(s)):
  <faza>/<item>: <message>`). Nowe testy CLI
  `test/commands/install_resume_test.rb` (3): resume renderuje
  `exists`/`created` z `Result: ok`; obcy katalog projektu → błąd z
  `projects/atlas/repository: …refusing to take over a foreign location`;
  `--dry-run` przewiduje dokładnie ten sam resume (`exists` +
  `would_create`, zero mutacji, exit 0) — paritet predykcji na stanie
  częściowym potwierdzony też na poziomie organizmu
  (`test_dry_run_on_own_partial_state_predicts_the_exact_resume`,
  `test_dry_run_predicts_the_foreign_directory_refusal`).

### 3. Zgodność z kontraktem i używalność

- Kontrakt/ADR-034: żadnego nowego właściciela stanu, journala, cache;
  install pisze wyłącznie przez istniejące molekuły; docs/lab-flow.md
  BEZ zmian (nie pojawił się nowy rodzaj artefaktu — zgodnie z
  oczekiwaniem). Komendy tylko `ace-lab install`/`project add` (bez
  nowych flag).
- Następny konsument (.7.4): raport per-krok pozostaje stabilnym JSON
  (schema) — poprawka: `GrantProvisioner#failure` ma teraz zawsze `kept`
  (puste), jak każdy inny status grants, więc konsument JSON widzi jeden
  schemat niezależnie od wyniku (Fixed w CHANGELOG; echo ustaleń review
  r1 z .7.2, punkt 6).

## Decyzje

- **Warstwa rozpoznania już istniała w .7.1/.7.2** (idempotentne kroki +
  guard obcego laba + per-element odmowy). Zadaniem było udowodnienie
  resume na każdej granicy kroku i paritet dry-run — done w testach z
  prawdziwymi molekułami. Jedyne luki implementacyjne znalezione po
  przeglądzie: brak `kept` w failure-raportach grants (naprawiony).
  Żaden krok nie wykonuje destrukcyjnego przerobu (dowody inode/mtime/
  zawartości w testach), więc nie było potrzeby zmieniać semantyki kroków.
- „Interrupted" symulowane budowaniem dokładnie tych artefaktów, które
  dany krok zostawia (helpery `done_directories/done_keys/done_repository`,
  usunięcie `.pub`, częściowy dokument grants) — bez markerów, z których
  test by korzystał a produkcja nie.
- Konta w fixture: `create: false` + passwd seam (stan „faza kont
  zakończona") — tworzenie kont przez dscl/useradd pozostaje pokryte
  testami molekuł L8.1.

## Zmienione pliki

- Implementacja: `ace-lab/lib/ace/lab/molecules/grant_provisioner.rb`
  (`kept: []` w failure — stabilny schemat).
- Testy (nowe): `ace-lab/test/organisms/install_resume_test.rb` (14),
  `ace-lab/test/commands/install_resume_test.rb` (3).
- Dokumentacja: `ace-lab/CHANGELOG.md` ([Unreleased] Added/Fixed),
  `ace-lab/docs/usage.md` (sekcja „Resuming an interrupted install
  (L8.4)" + odświeżony akapit o falach L8).
- Brak zmian: `docs/lab-flow.md` (żaden nowy rodzaj artefaktu), bin/CLI
  (interfejs bez zmian — resume to ten sam `ace-lab install`).

## Testy

`bin/ace-test ace-lab all` → **470 tests, 2147 assertions, 0 failures,
0 errors, 4 skipped** (baseline 453; +17: 14 organizm, 3 CLI — w tym
prawy `git clone`/`ssh-keygen` end-to-end). `bin/ace-lint` zmienionych
markdown: PASS (ostrzeżenia: te same klasy co wcześniej — em-dash/
tight-list). `bin/ace-test-suite` poza zakresem tej tury — do wykonania
przed merge zgodnie z kontraktem.

## Dla weryfikacji .7.4 (L8.5)

- Sprawdzić gotowość pod docelowymi kontami na ŚWIEŻYM i NA WZNOWIONYM
  labie (resume nie może zostawiać ukrytych braków): logowanie konta,
  czytelność instrukcji roli, użyteczność klucza (fingerprint), praca w
  repo (origin), widoczność projektów przez grants (`ace-lab projects` /
  `ace-overseer projects`).
- Konsumować raport install jako JSON (`--format json`); schemat grants
  ma teraz `kept` zawsze (także `failed`).
- Zakres graniczny do pilnowania: .7.4 nie powinno dodawać journala ani
  drugiego właściciela stanu — weryfikacja ma czytać te same artefakty,
  z których resume wyprowadza prawdę.

## Poprawki po review (runda 1)

Session `review-8xim0u`, werdykt Approve, 6 findingów (1 Medium, 5 Low; 2 skipped). Applied:
1. CHANGELOG: sekcja `### Fixed` przywrócona na właściwe miejsce (wpisy Added L8.4/L8.3/L8.2 ponownie razem).
2. +asercja `kept`/`dry_run` na ścieżce failure (stabilność schematu JSON grants).
3. Ujednolicony schemat sekcji grants: `dry_run` obecny w report/failure provisionera (jak w gated hashu organizmu).
4. +test dry-run z obcym dokumentem grants → identyczna twarda odmowa (guard przed dry_run).
Skipped: pełny ace-test-suite (bramka Lead przed merge), ekstrakcja assert_raises z capture_io (kosmetyka CLI-testu).
Retest: `bin/ace-test ace-lab all` → 471/2154/0.
