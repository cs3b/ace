# Wynik 8xg.t.sbz.9.0 — spójny zestaw wersji do wydania (2026-10-20)

Przygotowanie lokalne (bez publikacji) zgodnie z `wfi://release/local`.
Podstawa: main `68788da20` (fala 3 zmergowana w #393 + odbiór L9).
Rewizja po review `review-8xjirg` (naprawa pustych sekcji wydania, arytmetyki
audytu, atrybucji floorów, kategoryzacji root CHANGELOG, checkboxów odbioru).

## Manifest wydania — 13 paczek do publikacji, w kolejności zależności

| # | Pakiet | Wersja | Bump | Artefakt (SHA256) |
|---|--------|--------|------|-------------------|
| 1 | ace-support-config | 0.18.3 | patch | `fa2928638a7df3b2496e0f4d8225983aa5c05acb036ee0deeae3329f72a5f260` |
| 2 | ace-review | 0.62.1 | patch | `916c79bd8cfaab1933de90da86c3027c8ea17f716bee0422bb9824e4bfd51b67` |
| 3 | ace-git-worktree | 0.27.3 | patch | `9b6bd83cfa995dbd0fc35f5ec7622c4852c74c251bd6b1ccb4e98a768c589cc3` |
| 4 | ace-handbook | 0.36.0 | minor | `3c01bdc99e9413830f2b6e9b7b000218082dacaecb1928c6d8eb19343090a935` |
| 5 | ace-task | 0.41.0 | floor* | `d75785ce5cf15027b96788aa9261d068ee722573d006ab9642848f407d73a66e` |
| 6 | ace-hitl | 0.23.1 | floor* | `6900a830d3cd95a5fc1e7b7fb412e272816788814e39bcf1ef41bdaf4b7da56c` |
| 7 | ace-assign | 0.73.0 | minor | `b7c49073651a958a636143fd496f904079335223c7ce7f7fc455bd889254aff2` |
| 8 | ace-herdr | 0.8.0 | minor | `46ff6ea42d18ebc91e8d3bd28f38541c12d5b6c2d04ae88e47e6e72fdab342b4` |
| 9 | ace-coworker | 0.6.0 | minor | `32726c1fd498591f7db5e3cd2343399e282cd536c53ed570899aa54dd5f1bdeb` |
| 10 | ace-handbook-integration-pi | 0.6.0 | minor | `7190231c59a41979f3b1663eeb9433091e350f474e5898cedca810c8e8ec3cb2` |
| 11 | ace-lab | 0.13.0 | (wersja ustawiona wcześniej; wpis CHANGELOG dodany teraz) | `42c9725b9199d9b26d155c0f56d1c4e668e6d71dc04d8a176f8028b668460b1a` |
| 12 | ace-overseer | 0.25.0 | minor | `e90a26cfa9c3c38595a766325a771a7521d1292fb73656350cb43a40f69a3b84` |
| 13 | ace-hitl-hermes | 0.9.0 | floor* | `878e98d0bfbd48f68b3575f68f7b6c8fd31c615f2329d032d07d6187482ba974` |

\* „floor”: wersja była już przygotowana w repo (version.rb + wpis
CHANGELOG), ale nigdy nieopublikowana; jest twardym wymogem gemspeców
zestawu (`ace-coworker` → `ace-task ~> 0.41` i `ace-hitl ~> 0.22`;
`ace-overseer` → `ace-hitl ~> 0.23` przy `ace-task ~> 0.40` — floor 0.41
wymusza coworker; `ace-herdr` → `ace-hitl-contract ~> 0.3.0`;
`ace-hitl-hermes` → `ace-hitl ~> 0.23.0`). Bez tych paczek zestaw nie
rozwiązuje zależności — potwierdzone eksperymentalnie (scenariusz błędu).

- `ace-hitl-contract 0.3.0` jest już opublikowany na RubyGems (audyt:
  lokalnie = zdalnie) i NIE wchodzi do zestawu publikacji.
- Źródło: worktree `t-sbz-wave-4`, branch `t-sbz-wave-4`, commit
  przygotowania wydania (coordinated release commit, patrz historia).
- Artefakty: `gem build` z katalogów pakietów; pliki `.gem` w
  `.ace-local/release/wave4/`. Hasze 10 artefaktów spoza floorów dotyczą buildów PO
  wszystkich naprawach CHANGELOGów (ruch treści pod nagłówki wersji,
  usunięcie stray-line, kategoryzacja root) — 9.1 publikuje wyłącznie te
  pliki, bez przebudowy między weryfikacją hasha a pushem. Przebudowano
  wszystkie 10 artefaktów spoza floorów (identyczna treść też zmienia hash —
  stąd nowy hash ace-review bez zmiany źródła w zakresie delty); floory
  (ace-task, ace-hitl, ace-hitl-hermes) zachowują wcześniejsze buildy;
  żródła pakietów floorów nie zmieniły się po ich buildach (diff
  origin/main..HEAD nie dotyka ace-task/ace-hitl/ace-hitl-hermes).

## Wykonana weryfikacja

- Skład zestawu: audyt wszystkich `ace-*` — porównanie version.rb z
  RubyGems (`gem list --remote --exact`). Wynik: 17 luk lokalna > zdalna;
  z tego 13 wymaga publikacji (zestaw + floory), pozostałe 4 (ace-b36ts
  0.2.0, ace-git 0.30.1, ace-runtime 0.4.1, ace-support-items 0.15.15)
  świadomie pominięte — constraintry gemspeców zestawu rozwiązuje je z
  RubyGems (13 + 4 = 17; `ace-hitl-contract` luki nie ma).
- Struktura CHANGELOG: każdy z 10 ciętych wpisów wersji zawiera pełną
  treść z dotychczasowego [Unreleased] (liczby bulletów 2/23/1/1/14/2/35/
  23/2/1 — zgodne z audytem); [Unreleased] puste.
- Followerzy: żaden gemspec spoza zestawu nie wymaga aktualizacji
  constraintra (`~> 0.6` herdr ⊇ 0.8.0, `~> 0.8` lab ⊇ 0.13.0,
  `~> 0.72` assign ⊇ 0.73.0, `~> 0.62.0` review ⊇ 0.62.1,
  `~> 0.5` coworker ⊇ 0.6.0, `~> 0.32/0.33` handbook ⊇ 0.36.0,
  `~> 0.27` git-worktree ⊇ 0.27.3, `~> 0.18` support-config ⊇ 0.18.3).
- Dowód instalacji: czysty `GEM_HOME` (`/tmp/wave4-gemhome2`), instalacja
  lokalnych artefaktów w kolejności zależności (`ace-hitl-contract`
  pobrany z RubyGems). Wynik: 14/14 OK (13 lokalnych + contract zdalnie),
  łącznie 31 gemów ace; binarki zainstalowanych gemów raportują właściwe
  wersje (`ace-lab 0.13.0`, `ace-overseer 0.25.0`, `ace-coworker 0.6.0`,
  `ace-herdr 0.8.0`, `ace-task 0.41.0`, `ace-hitl 0.23.1`,
  `ace-assign 0.73.0`, `ace-review 0.62.1`).
- Scenariusz błędu (wykonany): instalacja bez toru hitl/task kończy się
  błędem `Could not find a valid gem 'ace-hitl' (~> 0.22)` /
  `'ace-task' (~> 0.41)` — niezgodny floor zatrzymuje przygotowanie;
  po rozszerzeniu zestawu o floory instalacja przechodzi. `gem install
  --local` (zakaz zdalnych zależności) odrzuca zestaw zależny — publikacja
  musi iść w kolejności zależności (tabela powyżej).
- `ruby -c` na wszystkich zmienionych `version.rb`; `bundle install`
  odświeżył `Gemfile.lock`; pełny suite: 52 pakiety, 12 701 testów,
  43 627 asercji, 0 failures (ALL TESTS PASSED) przed review.
- Review: sesja `review-8xjirg`, 5 ustaleń — wszystkie zweryfikowane
  `--valid` i naprawione w tej rewizji.

## Granice

- Samo przygotowanie NIE oznacza publikacji (9.1 wykonuje `gem push`
  dopiero po odebraniu tego przygotowania).
- Publikacja jest nieodwracalna: wersji z tabeli nie wolno ponownie
  użyć po `gem push`; przy częściowym niepowodzeniu kontynuować brakujące
  publikacje po sprawdzeniu dostępnych wersji (nie deklarować pełnego
  release bez potwierdzeń).

## Weryfikacja zewnętrzna — powtórna, po review `review-8xjj3w` (2026-10-20)

- `gem list --remote --exact ace-hitl-contract` → `ace-hitl-contract
  (0.3.0)` — potwierdza redukcję zestawu 14 → 13 (contract opublikowany).
- Audyt luk ponowiony komendą z sekcji „Wykonana weryfikacja": wynik
  ponownie **17 luk** (13 do publikacji + 4 pominięte; arytmetyka 13+4=17).
- Suite: raporty per-pakiet w `.ace-local/test/reports/*/` (worktree),
  podsumowanie 52/0 failed w logu fali.
- Instrukcja dla 9.1 (z review): przed KAŻDYM `gem push` porównać
  `shasum -a 256` pliku z `.ace-local/release/wave4/` z hashem w manifeście
  i NIE przebudowywać artefaktów między weryfikacją a pushem; wyjścia
  komend shasum zachować jako dowód w ścieżce trackowanej
  `9-l10-wydanie-gemow-i-odbior/1-opublikowa-gemy-w-kolejno-ci/receipts/<package>.md`.
