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


## Independent source review REJECT — 2026-10-23 (recorded before fixes)

Reviewed head `9bcc26015a9c0916d2a529640e9fc90b1187d8a7`; independent report
`/tmp/ace-formal-approval-code-review.md`, VERDICT: REJECT. Four findings
are the remaining implementation work (no fix or live acceptance asserted):

- R1 High: Forgejo pending-submit resolves the current PR head and can publish
  approval for an unreviewed commit during a push race. Post-send unknown does
  not undo the effect; old mock preserved commit incorrectly. Inspect official
  supported-version source; use a commit-preserving mutation or refuse before effects.
- R2 High: valid REQUEST_REVIEW user/team rows can lack commit/user fields;
  generic all-rows requirements reject the whole PR. Normalize documented row
  types in the Forgejo adapter; test approval publication and consumption.
- R3 High: Forgejo create reuses an actor's pending review and can overwrite
  unrelated body/comments. Refuse unrelated pending and model actual reuse,
  concurrent correlations and lost responses.
- R4 Medium: GitHub /user cannot resolve deployment App installation credentials.
  Explicitly support verified actor resolution or refuse the credential
  capability before mutation; integration HTTP403 is not network unreachability.

Initial append command used the default lab-config cwd and failed with
FileNotFoundError before mutation; corrected to this absolute task result path
before any fixes. Official Codeberg raw pages were unavailable through the web
reader; inspecting anonymous upstream source through another read-only transport
is the next research step, not permission for provider API/model calls.


R2 regression fixture correction recorded before retry: the first revised
`bin/ace-test ace-git all` stopped with 439 tests / 1443 assertions / 1 error
(report `d53a25e8-64b0-453d-a7ca-705d9d0d8f44`). The null-actor-comment case
created fixture review ID2 after existing ID1 but then requested ID42. This
is a fixture ID allocation mismatch, not provider semantics. Correct the
fixture allocator to reserve approval IDs from42; keep the failing run and
verify the null-actor scenario in the next package run.


R3 concurrency fixture correction before retry: Forgejo package run
`bc46a1ad-37ac-4aec-9b6f-85dba7d4bf3a` stopped at150 tests /639 assertions /
1 error. Concurrent calls attempted Minitest `stub(:pull_request)` on the same
object, whose alias bookkeeping is not thread-safe. Move the single stub
outside the concurrent provider calls; preserve real shared-policy flock and
actual pending-reuse protocol fixture. Do not treat the aborted run as green.


## REJECT fixes and verified protocol scope — 2026-10-23

R1: formal publication now directly creates the provider approval with an
explicit accepted commit ID. Forgejo never calls pending-submit by ID, whose
source replaces the commit with current HEAD. Regression fixtures implement
that distinction and assert the actual provider review commit after a push
race, not merely the local unknown exception. Formal Forgejo capability floor
is separately guarded at 11.0.0; v11.0.0 and deployed-target v16.0.5 router/model/
service sources were anonymously downloaded and inspected.

R2: Forgejo adapter excludes documented user/team REQUEST_REVIEW rows, which
have no reviewed commit and may have no user. Generic list validation no longer
requires every unrelated comment to identify a current actor/commit; selected
approval and relevant revocations still require full evidence. User requests,
team requests, null-actor comments, and invalid selected actors are tested in
publish/readback paths.

R3: a dedicated automation reviewer and one writer per actor/repo/PR are now
MANDATORY deployment preconditions owned by gad.b, per root decision. The local
lock covers all correlations and worktrees for the same OS account/normalized
provider/repo/PR, independent of server alias, cwd and worktree TMPDIR. Visible
unrelated pending refuses before mutation. Exact own comment-free pending can
recover through Forgejo's verified direct-create reuse, retaining original
body/commit/review ID; comments or uncertain identity are preserved with a
refusal. Tests model actual pending reuse, concurrency and lost recovery reply.
No server-side pending CAS or exclusion of other host/manual clients is claimed.
Those clients sharing the automation identity violate the deployment contract;
no broker or new state registry was introduced.

R4: GitHub actor proof now uses GraphQL viewer login/databaseId with the same
configured token, a path explicitly demonstrated in official installation-auth
documentation. PAT/App user and App installation identities use the same proof;
REST /user is never used for installation-token actor resolution. Unverified
viewer and integration 403 yield capability/authentication refusal before
approval, rather than guessed identity, token borrowing or network error.
Tests use a bot viewer plus realistic /user 403, GraphQL 403 and null/error
responses. Current deployment App live proof remains the root operator's
bounded read-only acceptance, not a passing fixture claim.

Source URLs, pinned source hashes, protocol guarantees and unavoidable API
limits are preserved in `formal-approval-protocol-evidence.md`.

Re-executed affected package suites after fixes (hermetic mode; no authenticated
provider/model requests):

```text
$ bin/ace-test ace-git all
609 tests, 1931 assertions, 0 failures, 0 errors (2.12s)
report: ace-git/.ace-local/test/reports/git/9b6345c3-d181-481a-ae32-59fb322af2b1/

$ bin/ace-test ace-git-forgejo all
188 tests, 931 assertions, 0 failures, 0 errors (1.02s)
report: ace-git-forgejo/.ace-local/test/reports/git-forgejo/254c2b3c-8be3-457c-8a44-aed92a7a4fa3/

$ bin/ace-test ace-git-github all
98 tests, 396 assertions, 0 failures, 0 errors (838.82ms)
report: ace-git-github/.ace-local/test/reports/git-github/c6c4ec26-1981-443f-b99f-b5646d745eca/

$ bin/ace-test ace-coworker all
396 tests, 1860 assertions, 0 failures, 0 errors (1m 11s)
report: ace-coworker/.ace-local/test/reports/coworker/7253104a-463b-4868-b126-0c869863497f/

$ bin/ace-test ace-review all
929 tests, 2780 assertions, 0 failures, 0 errors, 4 skipped (4.85s)
report: ace-review/.ace-local/test/reports/review/0dc53074-3c8e-4011-ac05-178475b7edd6/
```

Total 2220 tests / 7898 assertions; four unchanged optional performance/example
skips. No actual public approval/merge, account change, publication or deployment
was performed. Live permissions/public artifacts remain open in gad.b.
GitHub known-pending recovery remains an explicit unverified capability limit:
no safe recovery protocol is asserted, pending is retained, and its acceptance
criterion stays open. Normal GitHub direct approval and lost-submitted-response
reconciliation are implemented. Source candidate awaits fresh independent
review; this record does not erase the earlier REJECT or claim APPROVE.
