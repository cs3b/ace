# Wynik 8xg.t.sbz.9.0 — spójny zestaw wersji do wydania (2026-10-20)

Przygotowanie lokalne (bez publikacji) zgodnie z `wfi://release/local`.
Podstawa: main `68788da20` (fala 3 zmergowana w #393 + odbiór L9).
Rewizja po review `review-8xjirg` (naprawa pustych sekcji wydania, arytmetyki
audytu, atrybucji floorów, kategoryzacji root CHANGELOG, checkboxów odbioru).

## Manifest wydania — 13 paczek do publikacji, w kolejności zależności

| # | Pakiet | Wersja | Bump | Artefakt (SHA256) |
|---|--------|--------|------|-------------------|
| 1 | ace-support-config | 0.18.3 | patch | `3355a92a47721a589c593ef54b25aa58c8c9ae4a11fed8f9695f119ac4a6411e` |
| 2 | ace-review | 0.62.1 | patch | `7b896a3f67f9ada2898636cfaa27412dbe926b527b15879d6dafca6b5d2e7edc` |
| 3 | ace-git-worktree | 0.27.3 | patch | `3dbcba6d84cb719193bba01d522626886d8662e32a64d94cade0019285b75f59` |
| 4 | ace-handbook | 0.36.0 | minor | `e3df7fa4d6b8892b0b79ceb6b9ea5b9d5339be016f03e3104b3662aee3b53746` |
| 5 | ace-task | 0.41.0 | floor* | `d75785ce5cf15027b96788aa9261d068ee722573d006ab9642848f407d73a66e` |
| 6 | ace-hitl | 0.23.1 | floor* | `6900a830d3cd95a5fc1e7b7fb412e272816788814e39bcf1ef41bdaf4b7da56c` |
| 7 | ace-assign | 0.73.0 | minor | `1063cd8f8970e996e92c14718f3b15b0dae8963f423f3b5930861ccbc41bdd95` |
| 8 | ace-herdr | 0.8.0 | minor | `4cb5e952455d7c909b9377dfebd11a21a32e62061339d71195ad83df65d474c8` |
| 9 | ace-coworker | 0.6.0 | minor | `6cc6bbad5e718558a2386dc0adc80a7d4ea64e9dcf84924d487db5ecfce44109` |
| 10 | ace-handbook-integration-pi | 0.6.0 | minor | `b35c29c2a3951c7206547c798f20ed0ac742f73b530ea9e69027ddf36c0f941b` |
| 11 | ace-lab | 0.13.0 | (wersja ustawiona wcześniej; wpis CHANGELOG dodany teraz) | `3e510b5adf9673f943a6148f1e3f7c744c51bf763a6e6da463b4b569b638c3ec` |
| 12 | ace-overseer | 0.25.0 | minor | `ee1e6100745f8c52bde8204886ac1ca325c431d1b1bf84017c1046c4d30f874c` |
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
  `.ace-local/release/wave4/`. Hashe dotyczą przebudowanych po naprawie
  CHANGELOGów artefaktów — 9.1 publikuje wyłącznie te pliki.

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
