# Wynik 8xg.t.sbz.9.0 — spójny zestaw wersji do wydania (2026-10-20)

Przygotowanie lokalne (bez publikacji) zgodnie z `wfi://release/local`.
Podstawa: main `68788da20` (fala 3 zmergowana w #393 + odbiór L9).

## Manifest wydania — 14 paczek, w kolejności publikacji

| # | Pakiet | Wersja | Bump | Artefakt (SHA256) |
|---|--------|--------|------|-------------------|
| 1 | ace-support-config | 0.18.3 | patch | `1c8c332bb8aaeb84e79a83d900365da3442de366543bcdd406a703f29a63b207` |
| 2 | ace-review | 0.62.1 | patch | `0d831e534a5f1036cb9215896af65aabb38ad86d8a3a3869884dbd963582cc3c` |
| 3 | ace-git-worktree | 0.27.3 | patch | `b2ab68c24a04794a06ca13535045041742a35ea3b2a8472ad317829f9970da84` |
| 4 | ace-handbook | 0.36.0 | minor | `83b3d2064e620cf715c3bc7f2457263eb2852329bc1ad644a72469ee708a10ac` |
| 5 | ace-task | 0.41.0 | floor* | `d75785ce5cf15027b96788aa9261d068ee722573d006ab9642848f407d73a66e` |
| 6 | ace-hitl-contract | 0.3.0 | floor* | `14ec7da839e70d545b0b2281ba4872a5dc6443424a4799ec151a37171e750ffb` |
| 7 | ace-hitl | 0.23.1 | floor* | `6900a830d3cd95a5fc1e7b7fb412e272816788814e39bcf1ef41bdaf4b7da56c` |
| 8 | ace-assign | 0.73.0 | minor | `4bd72959d7e379c8ef48112fb71111425d6211a109a7c2ce561422f63427ec99` |
| 9 | ace-herdr | 0.8.0 | minor | `6b4cfbd5de9088b0f90654174bde061604a3285eb878644229b496eabb730264` |
| 10 | ace-coworker | 0.6.0 | minor | `c013fa5d7524e5541442238230d01b9b9a6db960faef4d25c1b5f0b0a54fbe20` |
| 11 | ace-handbook-integration-pi | 0.6.0 | minor | `4efa7d1d7d4d73fb19b9921f976931aef52c4fbee3558b6133fceace9cfc0a66` |
| 12 | ace-lab | 0.13.0 | (ustawiona wcześniej; dodano wpis CHANGELOG) | `c73f2a992bb2b506da75f2cbebd3059e560bed767db2ef523031386ab3dca573` |
| 13 | ace-overseer | 0.25.0 | minor | `671e41ee16f79d3d97cfd9f4da040323560233f732e4b2857b808e640e593c16` |
| 14 | ace-hitl-hermes | 0.9.0 | floor* | `878e98d0bfbd48f68b3575f68f7b6c8fd31c615f2329d032d07d6187482ba974` |

\* „floor”: wersja była już przygotowana w repo (version.rb + wpis
CHANGELOG), ale nigdy nieopublikowana; jest twardym wymogiem gemspeców
zestawu (`ace-coworker`/`ace-overseer` → `ace-task ~> 0.41`,
`ace-hitl ~> 0.22/0.23`; `ace-herdr` → `ace-hitl-contract ~> 0.3.0`;
`ace-hitl-hermes` → `ace-hitl ~> 0.23.0`). Bez tych paczek zestaw nie
rozwiązuje zależności — potwierdzone eksperymentalnie (scenariusz błędu).

- Źródło: worktree `t-sbz-wave-4`, branch `t-sbz-wave-4`, commit
  przygotowania wydania (coordinated release commit, patrz historia).
- Artefakty: `gem build` z katalogów pakietów; pliki `.gem` w
  `.ace-local/release/wave4/` (niebranchowane, tymczasowe).
- Minimalność: 4 pozostałe luki wersji (ace-b36ts 0.2.0, ace-git 0.30.1,
  ace-runtime 0.4.1, ace-support-items 0.15.15) NIE wchodzą do zestawu —
  constraintry gemspeców zestawu rozwiązuje je z RubyGems.

## Wykonana weryfikacja

- Skład zestawu: audyt wszystkich `ace-*` — porównanie version.rb z
  RubyGems (`gem list --remote --exact`); 17 luk, 14 wymaganych przez
  zestaw/zależności, pozostałe 4 świadomie pominięte (powyżej).
- Followerzy: żaden gemspec spoza zestawu nie wymaga aktualizacji
  constraintra (`~> 0.6` herdr ⊇ 0.8.0, `~> 0.8` lab ⊇ 0.13.0,
  `~> 0.72` assign ⊇ 0.73.0, `~> 0.62.0` review ⊇ 0.62.1,
  `~> 0.5` coworker ⊇ 0.6.0, `~> 0.32/0.33` handbook ⊇ 0.36.0,
  `~> 0.27` git-worktree ⊇ 0.27.3, `~> 0.18` support-config ⊇ 0.18.3).
- Dowód instalacji: czysty `GEM_HOME` (`/tmp/wave4-gemhome2`), instalacja
  14 lokalnych artefaktów w kolejności zależności; zależności zewnętrzne
  rozwiązywane z RubyGems. Wynik: 14/14 OK, łącznie 31 gemów ace;
  binarki zainstalowanych gemów raportują właściwe wersje
  (`ace-lab 0.13.0`, `ace-overseer 0.25.0`, `ace-coworker 0.6.0`,
  `ace-herdr 0.8.0`, `ace-task 0.41.0`, `ace-hitl 0.23.1`,
  `ace-assign 0.73.0`, `ace-review 0.62.1`).
- Scenariusz błędu (wykonany): instalacja bez toru hitl/task kończy się
  błędem `Could not find a valid gem 'ace-hitl' (~> 0.22)` /
  `'ace-task' (~> 0.41)` — niezgodny floor zatrzymuje przygotowanie;
  po rozszerzeniu zestawu o floory instalacja przechodzi. `--local`
  (zakaz zdalnych zależności) odrzuca zestaw zależny — publikacja musi
  iść w kolejności zależności (tabela powyżej).
- `ruby -c` na wszystkich zmienionych `version.rb`; `bundle install`
  odświeżył `Gemfile.lock` (9 par wersji).

## Granice

- Samo przygotowanie NIE oznacza publikacji (9.1 wykonuje `gem push`
  dopiero po odebraniu tego przygotowania).
- Publikacja jest nieodwracalna: wersji z tabeli nie wolno ponownie
  użyć po `gem push`; przy częściowym niepowodzeniu kontynuować brakujące
  publikacje po sprawdzeniu dostępnych wersji (nie deklarować pełnego
  release bez potwierdzeń).
