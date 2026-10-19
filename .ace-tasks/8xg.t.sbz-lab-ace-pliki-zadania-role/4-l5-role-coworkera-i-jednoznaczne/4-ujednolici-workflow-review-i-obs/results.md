# Wyniki: 8xg.t.sbz.4.4 — Ujednolicić workflow review i obsługę forge

Data: 2026-10-19. Worktree: `.ace-wt/t-sbz-wave-3` (branch `t-sbz-wave-3`).

## Zakres zaimplementowany

1. **Adopcja poprawki qkc.0 (commit 9b9d72d65)** — zweryfikowana, nie reimplementowana.
   `git merge-base --is-ancestor 9b9d72d65 HEAD` → poprawka JEST już na gałęzi
   (ancestor HEAD). Kod w `ace-review/lib/ace/review/molecules/subject_extractor.rb`
   waliduje `pr:REFERENCE` przez `Ace::Git::Atoms::PrReference` (parser forge-neutral,
   czysto tekstowy) i odrzuca zero/błędne referencje przez `ArgumentError` przed
   zwróceniem konfiguracji bundle (ekstrakcja ace-bundle nie jest wywoływana).
2. **Rozszerzone pokrycie testów** w `ace-review/test/fast/molecules/subject_extractor_test.rb`
   (4 nowe testy):
   - URL forge nigdy nie jest przepisywany na github.com ani zgadywany co do hosta
     (host, port i base path zachowane; `repository_url` bez `github`),
   - parsowanie bez żadnych wywołań sieciowych (host `.invalid` parsuje się poprawnie offline),
   - wszystkie akceptowane kształty (liczba, `owner/repo#liczba`, GitHub `/pull/`,
     Forgejo `/pulls/`) rozbierane na number + repository_url/owner_repo — zachowany
     właściwy target (rodzaj forge, base URL, repo, numer),
   - dotychczasowe testy qkc.0 (Forgejo `/pulls/` i `/pull/`, port 3443, ścieżka bazowa
     `/git/`, odrzucenie `0`/`not-a-reference`) przechodzą bez zmian.
3. **Ujednolicenie workflow** `ace-review/handbook/workflow-instructions/review/pr.wf.md`
   (= `wfi://review/pr`, źródło skilla as-pr-review):
   - reguła zakończenia sformułowana jako wspólna **3/2/10** (min. 3 pełne rundy,
     ostatnie 2 kolejne czyste, maks. 10 — dziesiąta spełniająca kończy sukcesem,
     w przeciwnym razie eskalacja do zlecającego overseera) — zgodnie z kontraktem
     programu i `reviewer.wf.md`,
   - sekcja „Role workflow (planned L5.5)" zastąpiona odwołaniem (bez duplikacji)
     do `wfi://coworker/reviewer` oraz deterministycznych liczników
     `ace-coworker rounds record` (`Ace::Coworker::Atoms::RoundRule`).
   - zachowana neutralna obsługa forge (`--server`/`--default-server`, brak wnioskowania
     hosta; identyfikatory: liczba, `owner/repo#liczba`, URL GitHub `/pull/` i Forgejo `/pulls/`).
4. **Presety** — sprawdzone: `.ace-defaults/review/presets/` (`code-valid`, `code-fit`,
   `code-shine`, `docs`, `integration`, `spec`) oraz preset_validator/preset_manager nie
   zawierają żadnych protected receipt gates ani śladów campaign/receipt (powierzchnia
   usunięta w 0.62.0); etykieta `protected-candidate` w `prepared_candidate_review.rb`
   to nazwa sesji pojedynczego modelu, brama niedostępna z presetów. ace-coworker
   pozostał nietknięty (reviewer.wf.md już zawiera reguły — tylko odwołanie z pr.wf.md).

## Zmienione pliki

- `ace-review/handbook/workflow-instructions/review/pr.wf.md` (ujednolicenie 3/2/10 + odwołanie do roli)
- `ace-review/test/fast/molecules/subject_extractor_test.rb` (+4 testy)
- `ace-review/CHANGELOG.md` (wpis [Unreleased])
- ten plik results.md

## Testy

`bin/ace-test ace-review all`: **929 testów, 2779 asercji, 0 failures, 0 errors,
4 skipped** (deterministycznie). Inne pakiety nie były modyfikowane.

## Mapowanie kryteriów odbioru

- [x] `pr:REFERENCE` przyjmuje liczby, `owner/repo#liczba`, URL GitHub `/pull/` i
      Forgejo `/pulls/` z zachowaniem targetu — `test_pr_reference_shapes_extract_forge_kind_base_url_repo_and_number`,
      `test_pr_github_url_accepted`, `test_pr_forgejo_urls_preserve_selected_server_and_repository`,
      `test_pr_mixed_formats_accepted`. Przypadek qkc.0 przechodzi pełny suite (929/0).
- [x] Zero i błędne referencje odrzucone przed ekstrakcją bundle; brak sieci i zgadywania
      github.com — `test_pr_zero_and_unrecognized_references_are_rejected_before_bundle_extraction`,
      `test_pr_url_parsing_never_rewrites_to_github_or_guesses_a_host`,
      `test_pr_url_parsing_performs_no_network_calls` (walidacja w `parse_typed_subject`
      przed `use_ace_bundle`). Stare protected receipt gates nie wracają przez presety
      (zweryfikowane grep-em presety + walidator).
- [x] Zgodność z kontraktem: workflow wskazuje te same reguły 3/2/10 i narzędzia ról
      co `reviewer.wf.md`/`integrator.wf.md`; wynik parsera (liczba + repository_url/
      owner_repo) konsumowany przez cykl forge ace-git; brak nowych właścicieli stanu.

## Co z qkc.0 przyjęto/zweryfikowano

- Commit `9b9d72d65` istnieje w historii i jest ancestor HEAD → przyjęty w całości,
  bez reimplementacji. Niniejszy task dodał brakujące pokrycie (no-network,
  no-github-guess, dekompozycja kształtów) i ujednolicił pr.wf.md z regułami ról.
- Otwarte (poza tym taskiem): niezależny finalny review i integracja wave — właścicielem
  jest lead/overseer (commity poza zakresem tego wykonawcy).
