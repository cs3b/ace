---
id: 8xg.t.sbz.4.4
status: in-progress
priority: medium
created_at: "2026-10-17 18:54:18"
estimate: medium
dependencies: [8xg.t.sbz.4.0, 8xg.t.sbz.4.2, 8xg.t.sbz.4.3]
tags: [lab, lab-l5, file-based]
parent: 8xg.t.sbz.4
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-review/handbook/workflow-instructions/review/pr.wf.md, ace-review/docs/usage.md, ace-assign/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/4-ujednolici-workflow-review-i-obs/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, ace-git/lib/ace/git/providers/base.rb, ace-git/lib/ace/git/providers/evidence.rb, ace-git/lib/ace/git/organisms/pull_request_lifecycle.rb, ace-git/lib/ace/git/cli/commands/pr.rb, ace-git-forgejo/lib/ace/git/forgejo/provider.rb, ace-git-forgejo/lib/ace/git/forgejo/pull_request_api.rb, ace-git-github/lib/ace/git/github/provider.rb, ace-coworker/handbook/workflow-instructions/coworker/reviewer.wf.md, ace-coworker/handbook/workflow-instructions/coworker/integrator.wf.md, docs/lab-flow.md]
  commands: []
title: Ujednolicić workflow review i obsługę forge
---

# Ujednolicić workflow review i obsługę forge

## Cel

Worker, reviewer, integrator i spec domykają własne zlecenia; planner pozostaje właścicielem przygotowania z L4. Ten subtask dostarcza następujący wycinek: Ujednolicić as-pr-review, workflow i presety z regułami ról. Zachować neutralną obsługę GitHub/Forgejo i przyjąć istniejącą poprawkę qkc.0 zamiast implementować ją ponownie.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Ujednolicić as-pr-review, workflow i presety z regułami ról. Zachować neutralną obsługę GitHub/Forgejo i przyjąć istniejącą poprawkę qkc.0 zamiast implementować ją ponownie.

## Kryteria odbioru

- [ ] Typed pr:REFERENCE przyjmuje numery, owner/repository i poprawne URL GitHub /pull/ oraz Forgejo /pulls/, zachowując właściwy target; przypadek qkc.0 przechodzi finalny review/integrację.
- [ ] Zero i błędne referencje są odrzucane przed ekstrakcją bundle; parsowanie nie odpytuje sieci ani nie zgaduje github.com. Stare protected receipt gates nie wracają przez presety.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Typed pr:REFERENCE przyjmuje numery, owner/repository i poprawne URL GitHub /pull/ oraz Forgejo /pulls/, zachowując właściwy target; przypadek qkc.0 przechodzi finalny review/integrację.
- Scenariusz błędu / niepoprawnego wejścia: Zero i błędne referencje są odrzucane przed ekstrakcją bundle; parsowanie nie odpytuje sieci ani nie zgaduje github.com. Stare protected receipt gates nie wracają przez presety.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L5.1 / 8xg.t.sbz.4.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/0-dostarczy-role-worker-i-spec/8xg.t.sbz.4.0-dostarczy-role-worker-i-spec.s.md), [L5.3 / 8xg.t.sbz.4.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/2-egzekwowa-pe-ne-rundy-i/8xg.t.sbz.4.2-egzekwowa-pe-ne-rundy-i-limit-review.s.md), [L5.4 / 8xg.t.sbz.4.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/3-dostarczy-integratora-zale-nego-od/8xg.t.sbz.4.3-dostarczy-integratora-zale-nego-od-wynik-w.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8wr.t.qkc](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md)
- [8wr.t.qkc.0](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Poprawka qkc.0 ma zapisany commit `9b9d72d65` i wcześniejszy wynik 91 testów / 182 asercji. To historyczny dowód źródła; finalny niezależny review, integracja i wydanie pozostają do sprawdzenia w nowym programie.


## Ponowne otwarcie: formalny approval providera — 2026-10-23

Nowy zakres ma status `draft`, `needs_review: true`, rozmiar medium. Poprzedni
zakres parsowania referencji/workflow był `done`; zachowujemy jego specyfikację,
wyniki i historię. Nie jest to dowód dostarczenia poniższej funkcji. Jeden
wycinek kończy się rzeczywistym formalnym approval i jego użyciem przez
integratora, a nie samym projektem interfejsu lub komentarzem.

### Cel, wejście i wynik

Reviewer po zaakceptowanym niezależnym review publikuje formalny approval
przez istniejącą konfigurację wybranego providera GitHub albo Forgejo.
Integrator odczytuje ten approval dla bieżącego kandydata i wykonuje osobno
już istniejącą integrację. Komentarz, lokalny werdykt, zmiana opisu i `pr ready`
nie zastępują formalnego review. Ta funkcja nie uruchamia LLM i nie decyduje,
czy kod zasługuje na approval; publikuje już przyjęty wynik uprawnionego reviewera.

Kontrakt publiczny planowany, obecnie niedostępny:

```sh
ace-git pr approve PR --expected-head SHA --body-file REVIEW_REPORT --correlation REVIEW_ID --server SERVER --format json
```

`PR` i wybór serwera używają istniejących reguł `ace-git pr`;
`--default-server` pozostaje alternatywą dla `--server`. Wymagane są pełny SHA,
niepusty plik raportu i stabilny identyfikator tej publikacji review. Odczytane
bajty raportu wiąże SHA256. Brak pliku, błędny identyfikator/SHA albo sprzeczny
wybór serwera odmawia przed mutacją. CLI i publiczna metoda providera mają
ten sam kontrakt. Nazwy nie upoważniają do korzystania z nieistniejącej komendy
przed implementacją. Zakres obejmuje wyłącznie approval; request-changes,
wycofanie review i zarządzanie branch protection pozostają poza tym wycinkiem.

### Zachowanie wymagane

1. Przed mutacją ustalić dokładną tożsamość wybranego repozytorium, PR,
   otwarty/niedraftowy stan oraz bieżący head. Weryfikować SHA przed i po
   publikacji. Approval musi być związany przez providera z pełnym przyjętym
   SHA; nie symulować tej własności samym tekstem. Zmiana headu nigdy nie daje
   sukcesu dla nowego headu. Zachować istniejące reguły wyboru forga i repozytorium.
2. Tożsamość reviewera pochodzi z uwierzytelnionego konta providera, nie flagi
   ani treści raportu. Reviewer nie może być autorem PR. Brak możliwości
   potwierdzenia aktora, uprawnień lub tożsamości PR oznacza odmowę. Rola/skill
   określa cel pracy; nie nadaje uprawnień, nie wybiera innego konta i nie
   przekazuje credentiali między workerem, reviewerem i integratorem.
3. Po zaakceptowaniu reguł review reviewer publikuje formalny approval i odczytuje
   go ponownie. Sukces wymaga rzeczywistego, niedismissowanego, niestarego review
   tego aktora i SHA. W Forgejo musi to być oficjalny `APPROVED`; w GitHub
   efektywny `APPROVED` uwierzytelnionego reviewera, z uwzględnieniem aktualnego
   stanu/dismissal i headu. Odpowiedź HTTP lub komentarz nie wystarcza.
4. Wynik normalizuje co najmniej: provider, wybrany serwer, URL/tożsamość
   repozytorium, numer i URL PR, pełny reviewed head, identyfikator i login
   reviewera, identyfikator/URL review, stan `approved`, potwierdzenie efektywności,
   correlation, SHA256 raportu i `created|existing`. Dane pozwalają integratorowi
   odczytać formalne review u jego właściciela. Nie kopiować credentiali ani
   prywatnej konfiguracji do wyniku. Raport i wynik przechowywać w istniejących
   artefaktach review/assignmentu; nie budować nowego journala ani magazynu prawdy.
5. Correlation ma namespace wybranego providera/serwera/repozytorium/PR.
   W tym zakresie jedna correlation oznacza ten sam head/aktor/raport. Ponowienie
   uzgadnia dokładnie pasujące istniejące approval albo oczekujące review;
   zmieniony raport/head/aktor pod tym ID i wiele pasujących review odmawiają.
   Równoległe wywołania tej samej publikacji nie tworzą dwóch approval.
   Awaria po możliwej mutacji pozostaje `unknown_outcome` z identyfikacją do
   odczytu; bez automatycznego ponowienia POST. Wznowienie najpierw odczytuje
   stan providera i kończy istniejące pending tylko gdy tożsamość jest pewna.
6. Workflow reviewera publikuje approval dopiero po zaakceptowanym niezależnym
   review i wymaganych wykonanych sprawdzeniach, zachowując regułę rund.
   Nieudana/niepewna publikacja pozostawia przekazanie do integracji zablokowane,
   z konkretną przyczyną w istniejącym raporcie/HITL. Integrator konsumuje
   formalny approval i sprawdza jego aktualność oraz już istniejący gate;
   nie tworzy approval w zastępstwie reviewera. Sam sukces publikacji nie jest
   merge ani zgodą na pominięcie pozostałych warunków projektu.
7. Nieobsługiwany provider/capability, brak API lub praw nie powoduje komentarza
   jako fallbacku, podmiany konta, obniżenia ochrony brancha ani root obejścia.
   Zwrócić istniejącą sklasyfikowaną odmowę/niepewność. GitHub i Forgejo są
   obydwa wymaganymi implementacjami tego kontraktu, nie cichym fallbackiem.

### Właściciele i granice kont

- `ace-git`: neutralny publiczny interfejs providera, znormalizowany receipt,
  lifecycle i CLI `pr approve`; obecne rozwiązywanie serwera i klasy błędów.
- `ace-git-forgejo`: formalne review przez API, oficjalność, pending/submit,
  idempotentne uzgodnienie i odczyt faktycznego wyniku.
- `ace-git-github`: odpowiednik tego samego kontraktu i dowody efektywności GitHub.
- `ace-coworker` / `ace-review`: istniejące workflow/presety reviewera publikują
  przyjęte review; integrator odczytuje rezultat. Bez zmiany właścicieli rund,
  assignmentów, raportów lub drzewa `_overseer`. `.4.1/.4.2/.4.3` zachowują zakres.
- Wdrożeniowe mapowanie kont, uprawnień do repo i prywatnych plików providera
  oraz rzeczywiste uruchomienie właściwych ról należy do lab-config `gad.b`
  (Execute scoped Lab services without the Python root broker). Użyć istniejących
  możliwości native/SSH do skonfigurowanych kont. Ten liść nie wymyśla brokera,
  receivera, warstwy authority, demona ani nowego `ace-lab run`.

Sekrety pozostają przy kontach wybranych przez deployment i ich chronionych
plikach. Worker nie czyta tokena reviewera/integratora; wspólny role preset
nie implikuje wspólnej tożsamości lub praw. Brak wdrożeniowego mapowania jest
konkretnym brakiem gotowości w `gad.b`, nie pozwoleniem na credential borrowing.
Generic code nie wymaga root; root wykonuje wyłącznie osobno autoryzowane
provisioning/deployment. Ta specyfikacja nie upoważnia do mutacji dowolnego PR.

### Nowy odbiór i weryfikacja — niewykonane

- [ ] Testy obu providerów i neutralnego CLI potwierdzają exact repo/PR/SHA,
  aktora różnego od autora, digest raportu oraz pełny receipt `created|existing`.
- [ ] Formalny review po przyjętym werdykcie przechodzi reviewer → readback →
  integrator na GitHub i Forgejo; komentarz/`pr ready` nie spełnia bramki.
- [ ] Wrong repo/head, author-as-reviewer, dismissed/stale/nonofficial review,
  brak aktora/praw, nieobsługiwany capability i złe wejście nie dają sukcesu;
  test head race obejmuje mutację między sprawdzeniem a odczytem końcowym.
- [ ] Lost reply przed/po create/submit, pending po restarcie, konflikt
  correlation, wiele dopasowań i równoległe ponowienie zachowują niepewność lub
  uzgadniają dokładnie jeden efekt, bez ślepego retry i podwójnego approval.
- [ ] W rzeczywistych, jawnie przeznaczonych do odbioru PR obu providerów
  skonfigurowane konto reviewera publikuje formalny approval; zachować publiczny
  URL review, pełny head, aktora, digest raportu i odczyt stanu. W Forgejo
  wykazać `official=true`. Integrator pod własnym kontem konsumuje to approval
  i w osobno zleconej integracji potwierdza wynik istniejącego exact-head merge.
- [ ] Wykazać odmowę własnego PR i brak dostępu workera do sekretów
  reviewera/integratora na rzeczywistych kontach/plikach (dowody `gad.b`).
  Niedostępne konto/runtime/PR oznacza niewykonany odbiór, nie sukces mocka.

Kontrole implementacji: `bin/ace-test ace-git all`,
`bin/ace-test ace-git-forgejo all`, `bin/ace-test ace-git-github all`,
`bin/ace-test ace-coworker all`, `bin/ace-test ace-review all`,
niezależny review przed integracją. Pełny niepowiązany monorepo suite nie jest bramką tego wycinka. Zachować surowe
wyniki w folderze taska/istniejących raportach. Testy deterministyczne nie
zastępują rzeczywistych publicznych artefaktów; źródło, publikacja gemów,
wdrożenie kont i live acceptance są odrębnymi dowodami.

### Pochodzenie luki, nie definicja kontraktu

PR70 w `cs3b/ace` po review specyfikacji wymagał formalnego approval; publikacja
komentarza go nie dostarczyła. Tymczasowa, ograniczona operacja root wystawiła
oficjalne review 225 jako `lab-admin`, różny od autora `mo`, dla headu `df906`
i digestu raportu `a7859184ec64eae83c253eb0f1ac7670665229d660701fa53e08d75442b7ac40`.
Potem potwierdzono merge. Zachowane źródła: lab-config
`docs/retirement-operations/2026-10-23/README.md` i aktualny wpis `gad.b`.
To receipt migracji, nie generyczny interfejs ani autonomiczne wdrożenie ról.
Nie używać go jako fallbacku ani odtwarzać fikcyjnego legacy Work.


## Review gotowości formalnego approval — 2026-10-23

Niezależny root/main reviewer przeczytał pełny diff trzech plików na head
`95196fbed8b391eef973ea36a3b9c1c3c7db6d13`: **VERDICT: READY**. Jedyna
korekta przed promocją ogranicza obowiązkowe testy do pięciu wskazanych
pakietów zamiast niepowiązanego pełnego monorepo suite; kontrakt zachowania
pozostaje bez zmian. Skill `as-task-review` i workflow `wfi://task/review`
wykonano, następnie `ace-task update` promował istniejący task do `pending`,
`needs_review: false`, z bezpośrednim `show`. Rodzic pozostaje `in-progress`.
To akceptacja specyfikacji, nie implementacji ani rzeczywistych publicznych
approval/merge. Nowe checkboxy pozostają otwarte; historia starego zakresu
zachowana. Wdrożenie tożsamości i dowody dostępu kont pozostają w `gad.b`.


### Doprecyzowanie wykonawcze — 2026-10-23

Integrator odczytuje aktualny formalny approval przez neutralny, niemutujący
`ace-git pr approval PR --expected-head SHA --review-id NUMERIC_ID --server SERVER
--format json`; porównuje zweryfikowany receipt z raportem reviewera. Correlation
ma zakres wybranego providera/serwera/repo/PR, zgodnie z potwierdzeniem main
reviewera; nie zakładać globalnego rejestru correlation ani przeszukiwania obcych PR.
Lokalna blokada serializuje publikację tej samej tożsamości wykonawczej; API może
ukrywać pending innego konta. Nie deklarować globalnej unikalności ukrytych review
lub między hostami, której provider nie pozwala zaobserwować. Ten limit trzeba
zachować w raporcie odbioru; brak możliwości potwierdzenia właściwej tożsamości
lub efektywnego approval nadal oznacza odmowę, nie pozorny sukces.
