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
   (3 nowe testy; poprawka po review — pierwotnie zapisano 4):
   - URL forge nigdy nie jest przepisywany na github.com ani zgadywany co do hosta
     (dokładne wartości `repository_url` pinują host, port i base path jednocześnie),
   - parsowanie bez żadnych wywołań sieciowych (host `.invalid` parsuje się poprawnie offline),
   - wszystkie akceptowane kształty (liczba, `owner/repo#liczba`, GitHub `/pull/`,
     Forgejo `/pulls/`, URL z portem i base pathem) rozbierane na number +
     repository_url/owner_repo — zachowany właściwy target.
   Dodatkowo istniejące testy qkc.0 (w tym odrzucenie `0`/`not-a-reference`
   przed ekstrakcją bundle) przechodzą bez zmian — to pokrycie PRZEJĘTE z qkc.0,
   ponownie zweryfikowane, a nie nowe w tym tasku.
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
- `ace-review/test/fast/molecules/subject_extractor_test.rb` (+3 nowe testy, w tym
  przypadek portu i base pathu z dokładną wartością oczekiwaną)
- `ace-review/CHANGELOG.md` (wpis [Unreleased])
- ten plik results.md

## Testy

`bin/ace-test ace-review all`: **929 testów, 2779 asercji, 0 failures, 0 errors,
4 skipped** (deterministycznie). Inne pakiety nie były modyfikowane.

## Mapowanie kryteriów odbioru

- [x] `pr:REFERENCE` przyjmuje liczby, `owner/repo#liczba`, URL GitHub `/pull/` i
      Forgejo `/pulls/` z zachowaniem targetu — `test_pr_reference_shapes_extract_number_and_repository_identity` (nowy),
      `test_pr_github_url_accepted`, `test_pr_forgejo_urls_preserve_selected_server_and_repository`,
      `test_pr_mixed_formats_accepted` (pokrycie qkc.0, przejęte i ponownie zweryfikowane).
      Przypadek qkc.0 przechodzi pełny suite (929/0).
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

## Poprawki po review (runda 1)

Session `review-8xiex6`, 4 findingi (2 Medium, 2 Low), wszystkie applied:
1. Liczba nowych testów skorygowana 4→3; pokrycie qkc.0 oznaczone jako przejęte/zweryfikowane, nie nowe.
2. Dodany dokładny przypadek portu+base path (`forge.example:3443/git/team/repo/pulls/25`) do mapy kształtów.
3. Usunięte „forge kind" z nazwy testu (`test_pr_reference_shapes_extract_number_and_repository_identity`), CHANGELOG i results.
4. Prefiksowe `start_with?` zastąpione dokładnymi wartościami `repository_url` per URL.
Retest: `bin/ace-test ace-review all` → 929/2780/0; `bin/ace-test ace-git all` → 591/1824/0.


## Formal approval implementation — verification friction, 2026-10-23

A targeted invocation from the monorepo root,
`bin/ace-test ace-git/test/fast/organisms/formal_approval_test.rb`, aborted
before tests: `cannot load such file -- test_helper` (0 tests, exit 1). This
is a test invocation/context failure, not a passing run or product failure.
The package-scoped `bin/ace-test ace-git all` already loaded this test and
passed; use that documented package-scoped command for the final check after
namespace-lock clarification. No package tests were bypassed or counted from
the aborted invocation.


## Formal provider approval — source implementation, 2026-10-23

Base: independently accepted spec `95196fbed8b391eef973ea36a3b9c1c3c7db6d13`,
promoted as `432e03f352926c24ae88ae25dbb9e86740405541` after root/main READY
and the five-package verification clarification. Existing dependency tasks
`.4.0`, `.4.2`, `.4.3` were read with `bin/ace-task show` and are done.
Task `.4.4` remains in-progress; source verification is not public live acceptance.

Execution plan (no model-generated plan or provider/model requests): shared
neutral approval receipt/policy; provider-specific authenticated I/O; CLI and
read-only integrator consumption; existing role workflows; focused package
tests and independent review. Root explicitly confirmed target-scoped correlation as routine clarification;
the read-only consumption surface implements the accepted integrator contract.

Implemented: `ace-git pr approve` and read-only `ace-git pr approval`; exact
repository/PR/head, authenticated nonauthor actor, report digest, correlation,
normalized formal-review receipt (including Forgejo official status). Both
Forgejo and GitHub create a pending formal review, submit it through their own
API vocabulary, and read back effective approval. The generic policy consumes
provider ports; no provider logic was added to ace-lab. The report travels on
stdin for GitHub and JSON request body for Forgejo, not argv. Same-account
local publication uses a private, owner/mode/symlink-checked flock; no delivery
state or credentials are persisted there. Existing provider errors classify
refusals and uncertain post-send results. Lost responses reconcile the exact
visible remote review before any subsequent effect.

Reviewer workflow publishes only after accepted independent rounds and tests.
Integrator compares the read-only current receipt against the reviewer's
existing artifact and existing gate; it never issues approval on their behalf.
Role purpose remains separate from OS/provider account permissions.

Executed final package verification (hermetic mode, no live provider/model calls):

```text
$ bin/ace-test ace-git all
609 tests, 1895 assertions, 0 failures, 0 errors (2.08s)
report: ace-git/.ace-local/test/reports/git/0ff68dd5-e7a3-4dc5-be79-2bc0b047d242/

$ bin/ace-test ace-git-forgejo all
182 tests, 835 assertions, 0 failures, 0 errors (904.29ms)
report: ace-git-forgejo/.ace-local/test/reports/git-forgejo/891aacee-9e2c-419d-bbf8-b3c1f63dfdd1/

$ bin/ace-test ace-git-github all
95 tests, 336 assertions, 0 failures, 0 errors (744.81ms)
report: ace-git-github/.ace-local/test/reports/git-github/38055f3a-3a3e-4167-a922-0abee2a6141e/

$ bin/ace-test ace-coworker all
396 tests, 1860 assertions, 0 failures, 0 errors (1m 10s)
report: ace-coworker/.ace-local/test/reports/coworker/db2ba22c-00e5-4c8a-9d75-f923ac761695/

$ bin/ace-test ace-review all
929 tests, 2780 assertions, 0 failures, 0 errors, 4 skipped (4.88s)
report: ace-review/.ace-local/test/reports/review/2903a648-45af-4b22-a3bf-3d6af05dc661/
```

The four review skips are existing optional performance/example tests in
`test/feat/performance_regression_test.rb`, not passing live scenarios.
The final core run includes the later namespace-lock clarification and real
filesystem ownership/mode/symlink refusal test. Provider suite runs exercise
the same common decision policy plus their actual transport construction;
all transport responses are scripted rather than remote observations.

New coverage includes same-target changed report/actor collisions, malformed
identity/list/URL, nonofficial/stale/dismissed or superseded approval, own PR,
wrong head/repository/draft, head movement after submission, missing capability,
unknown create/submit/readback outcomes, pending resume, no automatic POST
retry, same-account concurrency, private lock fixtures, bounded UTF-8 report
input, CLI JSON success/failure and read-only invocation. Existing coworker
round/gate tests remain green; workflow changes preserve their 3/2/10 rules.

Limits/open acceptance: no actual public GitHub/Forgejo approval or merge was
performed, no account/credential/permission/protection change, no publication
or deployment. `gad.b` still owns real reviewer/integrator account mapping,
worker secret-denial proof and runtime/public-artifact acceptance. Providers
may hide other accounts' pending reviews; separate hosts do not share the
local lock. No global hidden-review uniqueness, global correlation registry,
new broker, receiver, authority layer, journal or fake legacy Work is claimed.
Independent source review is required before integration.


Final documentation/source checks:

```text
$ git diff --no-ext-diff | gitleaks stdin --redact --no-banner
scanned ~67346 bytes (67.35 KB) in 110ms
no leaks found

$ bin/ace-task doctor --check frontmatter --errors-only --no-color
Tasks scanned: 860
Folders checked: 0
✅ All tasks healthy
📈 Health Score: 0/100 (Poor)
505 warnings
Completed in 223ms
[exit 0]

$ git diff --check
[exit 0, empty output]

$ python3 [metadata and bundle assertions]
Existing task identity/dependencies/creation preserved; in-progress/review metadata: PASS
Bundle files: 23 of 23 exist
Changed files: 26
```

Full `bin/ace-task doctor --no-color` also exited 0 (860 tasks, 31 folders,
509 existing repository warnings, 3.46s); no clean-doctor claim is made.

Specification setup friction was recorded before continuing in
`/tmp/ace-formal-review-spec-friction.md`: HTTPS Git fetch lacked interactive
authentication; root supplied the existing SSH alias and authenticated fetch
confirmed main `df906`. The new source worktree lacked dependency gems; a
gitignored vendor symlink reused the already prepared dependency tree. No
credentials changed, no gems installed, and both draft/review workflow loaders
subsequently succeeded. Neither workaround changes the product runtime.
