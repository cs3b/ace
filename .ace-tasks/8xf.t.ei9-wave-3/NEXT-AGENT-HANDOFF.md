# 8xf.t.ei9 — przekazanie kolejnemu agentowi

Stan: 2026-10-16, Atlantic/Canary. Użytkownik poprosił o zakończenie obecnych
prac na bezpiecznym checkpointcie i przygotowanie przekazania. Nie uruchamiać
kolejnych podagentów po zakończeniu obecnych. Nie zmieniono statusów na done.

## Zacznij tutaj

Główny worktree do kontynuacji:
`/Users/mc/Ps/ace/.ace-wt/ei9-program-integration`

Branch `codex/ei9-program-integration`, HEAD `214dfbb81c14c0e6bc32f3eb05d8416c7db8eae8`.
**Ma niezacommitowane zmiany źródłowe opisane poniżej — nie resetować ani nie
nadpisywać.** Najpierw przeczytaj `git status`, `git diff` i pliki untracked.

Najważniejsze dokumenty w tym worktree:
- `.ace-tasks/8xf.t.ei9-wave-3/delivery-map.md` — mapa odpowiedzialności i historia dowodów.
- `.ace-tasks/8xf.t.ei9-wave-3/0-execute-authorized-forgejo-integration-with/candidate-resource-contract.md`.
- Podkatalogi `evidence/` rodzica i dzieci — surowe testy, review, instalacja i blokady.

Draft PR: https://github.com/cs3b/ace/pull/375 . Zdalny branch PR
`codex/ei9-routing-release` był ostatnio wypchnięty do `20b5897d0`;
lokalny integration jest dalej. Sprawdź aktualne refy przed push.
Nie scalać przed wykonanymi testami oraz niezależnym werdyktem.

`/Users/mc/Ps/ace` to main `2e9005f39fdd12a5cf3c1d831e3dcad1bfdc4bc0`.
Przy przekazaniu ma obce zmiany `ace-design/README.md`, `docs/usage.md`,
untracked `docs/getting-started.md`, `docs/handbook.md`. Nie dotykać ich.

## Co jest już zrobione

1. Rebase i uzgodnienie publikacji z main. Użytkownik opublikował:
   Herdr0.6.0, Bundle0.45.1, Task0.40.0, Review0.60.3, Assign0.70.0,
   HITL0.16.0, Lab0.8.0, Overseer0.22.0. SHA publicznych archiwów zgadza się
   z archiwami main. Nie publikować tych wersji ponownie. Zachować też
   wcześniejsze lint0.30.11, providers-cli0.36.2, design0.2.0.
2. Instalacja i wybór dokładnych grafów service45/coordinator59 na Labie.
   `TS-MONO-001`, run `8xfqwqr`, PASS4/4 dla 50 wersji /246 krawędzi.
   To dowód propagacji ręcznego release, nie autonomicznego publishera.
3. Ordinary Assign owner z kanonicznym dziennikiem i socketami Assign/HITL/merge
   faktycznie działa. Sprawdzono dostęp UID1000 i odmowę UID1001.
4. W integration: canonical ordinary execution/result/replay/CAS, natywna
   tożsamość i role, canonical candidate/review/merge ingress, zachowanie
   protected checks; wspólny fixed service/publication lifecycle bez udawania
   protected origin; niejawne sekrety nie trafiają do receiptów.
5. W integration: nie-sekretowa część `ace-lab run`, kontrola procesu i cleanup
   jego własnego drzewa. Prywatne testy Linux R6:9/75 PASS; adapter domenowy
   40 PASS. To dowód statycznego zamrożonego źródła, nie aktualnego dynamicznego
   kandydata ani produkcyjnej instalacji.
6. W integration: Hermes runtime/v2, kontrakty i operator-question; review
   i testy źródłowe wykonane. Pełny transport/grupy nie są wdrożone.
7. W integration: accepted-head campaign foundation, v2 rozdziela reviewed
   head od accepted head; pełne porównanie dwóch zweryfikowanych Git bundles.
   Commity integration `43672a5c7`, `beb42f77c`, `ce8ea4089`, `545ffb68e`.
8. W integration: retain_release_artifact, dokładny manifest gem metadata/SHA,
   kanoniczny binarny blob i autoryzacja przed uploadem. Commity
   `457fd1ae5`, `543918db9`, `f656f93e5`, `82953156e`, `c25960c30`.
   Natywny Unix/Git test9/112 PASS, manifest/transport28/167 PASS,
   kompozycja12/96 PASS. Dwa rzeczywiste Pi review APPROVE bez high/medium.
   Retencja nie oznacza istniejącego ordinary publisher dispatch.

Ostatni pełny default suite obejmuje źródło **521066be3**, nie późniejsze zmiany:
51 pakietów PASS,12412 passed,43526 assertions,42 skips,0 failures/errors.
Dowody w `evidence/suite-521-green/`. Wcześniejszy RED zachowany osobno.

## Niezacommitowane WIP w integration — najbliższa praca

Rzeczywisty ACE nie mieścił się w starym limicie64MiB. Kandydat c259 ma
bundle82,809,675 bajtów,9203 wpisy,71,583,200 bajtów po rozwinięciu.
Aktualne WIP wprowadza osobny limit128MiB candidate/assignment snapshot i
review head context; reporty pozostają64KiB/256KiB, gem release64MiB,
prepared source/review snapshot64MiB.

Nowe pliki:
- `ace-assign/lib/ace/assign/atoms/candidate_limits.rb`
- `ace-assign/lib/ace/assign/atoms/git_blob_batch.rb`
- `ace-assign/lib/ace/assign/authority/candidate_blob_batch.rb`
- `ace-assign/test/fast/atoms/git_blob_batch_test.rb`
- `ace-assign/test/feat/candidate_project_readiness_test.rb`

Zmodyfikowane: CandidateTransfer/HeadComparison, TransferCodec, Endcap,
PreparedWork, SubmitCandidate, EvidenceJournal/JournalMutation i testy;
Review CampaignContract/HeadAssessments i test. Parser Git batch został
wydzielony z istniejącego EvidenceJournal i współdzielony; fixed cat-file
batch zastępuje proces na każdy plik. Nadal pełne inventories i byte proofs,
bez filtrowania repozytorium i bez osłabiania symlink/path kontroli.

Wykonane testy tego WIP:
- `b3cb606e-c3b8-47ac-9af4-68e5a42dd7b9`:68/620 PASS — batch, transfer,
  candidate i istniejący EvidenceJournal.
- `2ae7db50-99af-4477-87cf-5cc6b6fd8a93`: Review7/54 PASS.
- `961d15dc-6b35-4320-9dab-756e3e6c4fd2`: real ACE1/14 PASS, materialize13.72s,
  comparison22.43s, pełny context96,720,212 bajtów.
- **NAJNOWSZY** `7993070e-b250-4f26-9a25-d9dcdc58e451`:1test/9assert,
  ERROR `EvidenceUnavailable: head comparison deadline expired`,50.60s.
  Test poszerzono o `materialize_repository` i roundtrip dużego Git blobu;
  wyjątek nastąpił na `ReadView#context`, przed ukończeniem roundtrip.
  Nie uznawać wcześniejszego PASS za zamknięcie aktualnego źródła.
- Poprzednie diagnostyczne RED: pierwszy oversized descriptor run znajdziesz
  w raportach readiness. Kolejne pewne IDs: `93517815-cd9f-4e5e-93fa-3a6f541df722`
  (cap-only deadline), `e8182d79-d5cd-41e4-8462-449d1e6bd69e`
  (pośredni NameError/test stub; poprawione), `1ceb3135-fab7-43a9-8f5e-cd7ce3a0c387`
  (17/305 PASS). Nie usuwać raportów.

Raporty są pod `.ace-local/test/reports/{assign,review}/<ID>/`.
Fixture manifest `.ace-local/ei9-candidate-readiness/manifest.json` wiąże
niezmienne bundles w głównym repo `.ace-local/ei9-candidate-readiness/`.
Test pomija się bez manifestu; jest offline, nie oznacza canonical wykonania.

Do dokończenia WIP:
1. Wyjaśnić deadline najnowszego real-project testu; nie podnosić go bez
   pomiaru. Zachować RED, rzeczywiste czasy i dokładny source freeze.
2. W parserze ścieżek dodać skończone bounds długości ścieżki/komponentów
   **przed** tworzeniem prefiksów inventory; dynamic-agent wskazał możliwy
   kwadratowy koszt bardzo długiej ścieżki (np.4096/255 bytes, decyzja jawna).
3. Dokończyć negatywne testy, changelogi i trwałe dowody; commit tylko własnych
   ścieżek i niezależny review. WIP nie ma jeszcze review ani finalnego suite.
4. Nowa stała Review `MAX_HEAD_CONTEXT_BYTES` jest zależnością Assign:
   uwzględnić Review w source fixture i podnieść floor przy release.
   Nie dodawać fallbacku do starego installed Review0.60.3.

## Gotowe osobno do integracji / aktualne checkpointy agentów

### Canonical campaign reviewer execution — gotowe, reviewed

Worktree `/Users/mc/Ps/ace/.ace-wt/ei9-ordinary-campaign-owner`,
HEAD `54096540fcb9b495bda02b7deb65a7e4d78da697`, clean.
Cherry-pick kolejno: `d5b11b93e`, `6ffb9e691`, `e4ec61ad2`, `22dd780f2`, `54096540f`.

Genuine review-collect canonical results/artifacts, historical approval-by-ID,
reservation replay bez podwójnego dispatch. Collection nie daje approval.
Actual Pi delta APPROVE, bez high/medium/blockerów. Review fast1007/3327 PASS;
reservation16/108 PASS; końcowy realUnix2/20 PASS. Dowody w child.8.

### Dynamic command candidate — gotowe źródło + mały follow-up

Worktree `/Users/mc/Ps/ace/.ace-wt/ei9-candidate-git-root`,
HEAD `9d33acd5a71bed085d1c4d2fa21dc10326b7ce2b`, clean przy odczycie.

Podstawa do cherry-pick względem integration: `e22baf4b5`, `5488862bc`,
`1cb4010be`, `38a88dc50`, `2b0925d85` — sprawdź ancestry najpierw.
Następnie `25b738091` RED test, `638148235` fix, `9d33acd5a` evidence.

Zapewnia dokładne candidate_reference, materializowany retained Git source,
root-sealed source/config, zamknięty runtime/source closure, rzeczywisty argv
i native session, historyczny read-only reader bez ponownej autoryzacji
starego candidate, zabezpieczenia świeżych katalogów i limity wpisów.
Review exact2b: Pi APPROVE bez high/medium, SHA
`5846ecc689fde91acef17bfb300f5c0493e6b0466648702e13db009b48836290`.
Lab45/259 PASS z jednym prawdziwym Linux skip; historical Assign8/72 PASS.

Follow-up naprawia rzeczywisty Git safe.directory: trzeba ufać source_root,
nie package cwd. RED3/23/1error, GREEN9/32 PASS/1skip.
W chwili checkpointu wcześniejszy już uruchomiony Pi review session86282
jeszcze pracował; nie zakładać werdyktu dla638 na podstawie review2b.
Ewentualne końcowe powiadomienie agenta jest nowsze niż ten dokument.

Konflikty przy integracji z root WIP: CandidateTransfer batch/caps versus
max_entries preflight. Zachować oba, sprawdzić zarówno latest jak historical
readers. Dynamic source-only Linux acceptance nadal do wykonania.

### Campaign composition — NIEZATWIERDZONE WIP

Worktree `/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition`, branch
`codex/ei9-campaign-composition`, HEAD przy odczycie `69e742e14`.
Zmiany w ordinary lifecycle/reviews, nowe ordinary_campaign_{execution,owner},
ordinary_campaigns; Lab config/client/composition i Review prepared manager.
Nie cherry-pickować jako zatwierdzonego bloku; sprawdzić końcowy checkpoint.

Real Unix/native begin:1/22 PASS (`6305a789-5a57-4a74-a24f-449539e33224`),
replay obserwuje istniejący begin, nowy request i zły reviewer/head odmawiane.
Końcowy checkpoint agenta: Lab20/128 PASS, istniejący prepared Review16/57
PASS; syntax/diff-check PASS. To nie są testy nowego kompletnego join.
Dokładne12 ścieżek i stan WIP opisuje
`/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition/.ace-tasks/8xf.t.ei9-wave-3/8-enforce-package-ownership-and-accepted/ordinary-campaign-composition-handoff.md`.
Manifest `.ace-local/ei9-campaign-handoff/source-manifest.json` SHA256
`3ecd8dbdc815e4d7228d805f9dc70db76383f96c973d8722b8935e28a3e70b74`.
Brakuje kompletnego review execution authority join i pełnych artifact proofs.
Campaign config ma używać `{repository,store_root,policy}`, prywatnych,
rozłącznych stanów; Assign jest jedynym wykonawczym journal ownerem.
Bez Review→Assign dependency, drugiego journalu i lokalnego fallback managera.

Otwarta decyzja: ordinary generic result caps64KiB/artifact nie pomieszczą
pełnych campaign system/user prompts. Propozycja agenta: zamknięte kind i
purpose `review_context` wyłącznie owner-selected `review-collect`, limit
powiązany z Review context128MiB, pełne bajty promptów i digesty, zwykłe
report/metadata/feedback nadal małe. Nie jest jeszcze zatwierdzona ani
zaimplementowana. Nie zwiększać globalnych report/gem limitów ani nie ucinać
promptów. Wykorzystać te same kanoniczne artefakty w CampaignRoundTransfer.

## Co jeszcze musi powstać / zostać odebrane

- .0: instalacja finalnego ordinary code i dwa prawdziwe serial PR merge;
  nowa decyzja PR2 po PR1 bez restartu, revoke/head race/uncertain outcome.
- .1–.4: kompletny installed context/capabilities; queue recovery i restart,
  zgubiona odpowiedź/duplicate wake bez nowego execution, no-start/wrong
  callback; rzeczywisty audit600s/cleanup3600s w delivery workflow.
- .5: zwykły fixed publication consumer, staging/publisher/OTP i reconciliation
  po błędzie/partial/unknown; instalacja wszystkich consumers i bezpieczny sync.
  Retention i wspólny engine są gotowe; ordinary publication nie jest gotowy.
  ProtectedPublicationInput ma inny zamknięty schema — nie udawać protected
  launch/origin. Secret refs z iy6 rozwiązywać wyłącznie w child po drop UID/GID,
  bez sekretów w root daemon/journal; interactive OTP oddzielnie.
- .6: actual accepted cleanup z dowodem zachowania commits/files/results;
  exit procesu sam nie oznacza done. Bez masowego Tidy --apply.
- .7: dwa workers→dwa PR→review→dwa serial merge→jeden autoryzowany release→
  install/sync/cleanup, potem izolowany drugi projekt; blokada pierwszego
  nie blokuje drugiego. Wspólny installed receipt z lab-config gad.2.
- .8: domknąć ordinary campaign composition/genuine reviewer/collect/approve,
  historical/delta evidence i limity; substantial/uncertain niezależny review.
- .9: actual grupy/reply correlation/mTLS/jeden poller; tylko wcześniej
  delegowane klasy mają timeout16h.

Po złożeniu: właściwe `bin/ace-test`, obowiązkowy `bin/ace-test-suite`, actual
configured independent verdict; dopiero potem PR merge i nowe archiwa z main.
Wersje i dependency floors nie są finalne. Zrobić świeży registry audit;
nowych wersji nie publikować z worktree. CI jest advisory.

## Lab i granice operacyjne

Rozwój na hoście, Lab do instalacji/odbioru. Root remote tylko przez
`ssh mo@omarchy` i `sudo -n incus exec lab -- ...`; zwykły odczyt `ssh mo@lab`.
Najpierw `/Users/mc/Ps/lab-config/AGENTS.md`. Nie restartować legacy labd ani
nie nadpisywać obcych worktree/checkoutów; nie aktywować healthcheck w Work.

Ostatnie fakty (PIDs trzeba odczytać ponownie): ordinary owner554643 UID966/GID964;
native Herdr514709; legacy labd1858726 zachowany. Journal
`/var/lib/lab-assign-journals/ace`, state `/var/lib/lab-assign-owner/ace/state`.
Sockety `/run/lab/ordinary/ace/endpoints/{assign,hitl,merge}.sock`.
Runtime selection `/etc/lab/ace-runtime/{service,coordinator}.env`.
Lab project checkout stary32f1, nie robić blind sync. Istniejące legacy pins
celowe. Owner nie został zrestartowany na nowe źródła z tego przekazania.

Nowy Linux source-only fixture musi pinować **pięć** source packages:
Lab/Assign/Runtime/Herdr/**Review**. Stary four-package R3 export nie zawiera
nowej Review constant. R6 test-only dependencies już istnieją w
`/run/ei9-command-run-kernel-r2/.local/share/gem/ruby/3.4.0`;
szablon runnera w child.5/evidence/command-cleanup-r6/runner.Gemfile.
Fresh export/file hashes i root-owned modes konieczne; to nadal źródłowy
fixture, nie substytut maintained installed runtime acceptance.

## Zewnętrzne blokady — zachować, nie obchodzić

Automatic approval review odrzucił (possible cybersecurity risk) działania:
1. .9 different-UID filesystem check, następnie oddzielną defensive layout
   preparation. WIP zachowany w
   `/Users/mc/Ps/lab-config/.ace-wt/ei9-hitl-all-groups`; bez aktywacji.
2. Osobną .5 maintained exact test-runtime dependency profile preparation,
   przed zwróceniem planu/zmian/testów.

Nie ponawiać, nie przerzucać innym agentem/narzędziem i nie tworzyć zastępczego
installera/profilu. Wskazania dowodów: child.9/evidence/preparation-blocker.json
oraz child.5/evidence/test-runtime-preparation-blocker.json.
Nie twierdzić, że odtworzono exploit ani że konfiguracja jest wdrożona.
Niezależne źródłowe prace pozostają możliwe; pełny installed odbiór jest otwarty.

## Zasady dla kontynuacji

Używać istniejących mechanizmów; bez nowego orchestratora, brokera Python,
drugiego wykonawczego journalu i zewnętrznego schedulera. Poza programem cm3,
ig5 i pełny protected boot/network/runtime. Skill-first z `.agents/skills/`.
W repo `bin/ace-*`; nie pipe/redirect/postprocess ich output. Testy tylko przez
ace-test/suite. Path-scoped commits, zachować WIP i wszystkie RED receipts.
Rodzic i dzieci pozostają otwarte aż do ich rzeczywistych installed wyników.
