# Wynik 8xg.t.sbz.9.1 — publikacja gemów w kolejności zależności (2026-10-20)

## Wykonanie

Publikacji dokonał operator narzędziem projektowym
`ace-rubygems-publish --interactive` (live, OTP), na main `d9c7d3af1`
(merge PR #394). Narzędzie rozstrzygnęło kolejkę fresh z drzewa (prepared
queue było stale) i opublikowało **16 gemów w 8 falach ≤5 concurrent**
(według zależności), w 16,9 s. Wszystkie 16 potwierdzone na RubyGems
(`gem list --remote --exact` + versions API): wersja, `created_at`
i `sha` gemu zgodne z wydaniami.

## Zestaw opublikowany vs manifest 9.0

- **13/13 paczek manifestu opublikowane** (support-config 0.18.3,
  review 0.62.1, git-worktree 0.27.3, handbook 0.36.0, task 0.41.0,
  hitl 0.23.1, assign 0.73.0, herdr 0.8.0, coworker 0.6.0,
  handbook-integration-pi 0.6.0, lab 0.13.0, overseer 0.25.0,
  hitl-hermes 0.9.0).
- **Odchylenie od manifestu (zapisane uczciwie):** narzędzie opublikowało
  dodatkowo 3 paczki spoza uzgodnionego zestawu — `ace-git 0.30.1`,
  `ace-runtime 0.4.1`, `ace-support-items 0.15.15` (lokalne wersje
  wyprzedzały RubyGems; w manifeście 9.0 były świadomie pominięte jako
  niewymagane). Publikacja tych wersji jest nieszkodliwa dla zestawu
  (constraintry się rozwiązywały także bez nich), ale decisions-record
  9.0 nie ich dotyczył — stąd ta adnotacja.
- **Artefakty:** narzędzie zbudowało gemy fresh z main („16 newly built,
  0 reused”), nie z weryfikowanych artefaktów `.ace-local/release/wave4/`
  (bramka shasum-przed-pushem z 9.0 nie obowiązała w tym trybie — decyzja
  operatora). Buildy okazały się replikowalne: 12 z 13 hashy manifestu
  pokrywa się 1:1 z SHA z API RubyGems. Wyjątek: `ace-git-worktree 0.27.3`
  — SHA z API (`0f559a90…`) zgadza się dokładnie ze ŚWIEŻYM buildem z
  main (zweryfikowane ponownym `gem build` + `shasum`), a różni od
  artefaktu z worktree fali (`9b6bd83c…`); opublikowany gem odpowiada
  wprost zmergowemu drzewu, co jest gwarantującym dowodem źródła.
- Autorytatywne hashe opublikowanych gemów (z API RubyGems) w
  `receipts/<package>.md` — po jednym receipcie na paczkę.

## Kolejność faktyczna (fale narzędzia)

1. support-config · 2. git, runtime · 3. handbook, herdr, support-items ·
4. handbook-integration-pi, hitl, lab, task · 5. git-worktree,
hitl-hermes, review · 6. assign · 7. coworker · 8. overseer — zgodna
z porządkiem zależności (manifest 9.0 — deliberowanie dopuszcza fale
równoległe w tych samych punktach odcięcia).

## Wnioski dla 9.2

Świeży lab może teraz używać wyłącznie RubyGems: `gem install ace-lab`
pociągnie `ace-lab 0.13.0` + wszystkie zależności (w tym niegdyś
nieopublikowane floory). Weryfikacja odbioru: wersje i ścieżki z RubyGems,
bez checkoutowych binstubów i lokalnych override.
