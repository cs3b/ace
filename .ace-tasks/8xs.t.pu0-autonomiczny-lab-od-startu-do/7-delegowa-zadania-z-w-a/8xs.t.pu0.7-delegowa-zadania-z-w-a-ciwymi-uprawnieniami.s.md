---
id: 8xs.t.pu0.7
status: pending
priority: medium
created_at: "2026-10-29 17:13:43"
estimate: large
dependencies: [8xs.t.pu0.6]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-coworker/docs/usage.md, ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md, ace-lab/docs/usage.md, ace-coworker/handbook/workflow-instructions/coworker/worker.wf.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/8xs.t.pu0.6-zamyka-sprawy-hitl-bez-sierot.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md, ace-git/lib/ace/git/providers.rb, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
---

## Review Questions — rozstrzygnięte 2026-10-29

Kapitan wskazał docelowe `ace-lab auth`, pluginy Forgejo (issue/revoke), GitHub i env
oraz krótkotrwały dostęp dla ról developer/reviewer. Potwierdził, że istnieją mechaniki
do uporządkowania. Odnaleziono je w lab-config: wydawanie i odwołanie tokenów Forgejo,
GitHub App leases oraz bezpieczne przekazanie. Źródła i ograniczenia: docs/auth-mechanics.md.
Brak otwartych pytań HIGH/MEDIUM. Jest to zakres implementacji tego kroku, nie deklaracja
istnienia gotowego CLI ani aktualnej gotowości środowiska.

# Delegować zadania z właściwymi uprawnieniami

## Cel

Nadzorca deleguje zadanie, a agent uzyskuje przez `ace-lab auth` ograniczony dostęp
właściwej roli, używa go bez ujawnienia sekretu i kończy przydział po pracy.

## Specyfikacja zachowania

Krok 08/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: odebrany poprzednik, zadanie/assignment i skonfigurowane profile dostępu hosta.
Wyjście: realna praca coworkera, raport i potwierdzony stan końcowy jego dostępu.

- Istniejące commission/prepare/start/resume pozostają drogą delegacji. Brief zawiera
  task, worktree/cwd, assignment, rolę, instrukcje, nadzorcę, kryteria i zasady raportowania.
  Niesie identyfikatory profilu/lease, nigdy wartości sekretów. Resume zachowuje
  ACE_TOOLCHAIN=installed i sprawdza dostęp ponownie przed pracą.
- `ace-lab auth` jest publicznym interfejsem request/status/exec/revoke/reconcile.
  Agent prosi o profil dla zadania i roli; nie musi znać skryptów hosta ani obsługi API issuera.
  Core zarządza kontraktem i cyklem przydziału; pluginy obsługują Forgejo, GitHub i env.
  Wszystkie trzy działają w tym wycinku, z instrukcjami i instalowalnymi pakietami.
- Profile rozróżniają developer (istniejąca rola coworkera worker), reviewer, integrator,
  publisher i doradcę. Zakres to przecięcie profilu hosta, zadania/repo i żądania.
  Agent może żądać węższego zakresu/czasu, ale nie rozszerza praw edycją taska lub configu.
- Zachować odrębność autor/reviewer/formalny approver/merger. Konfiguracja mapuje role
  na rzeczywiste tożsamości providera. Wzorzec laba: lab-overseer autor/merger,
  lab-merge-ace formalny approver po niezależnym review. Nie współdzielić ich tokenu.
  GitHub App jest tożsamością aplikacji; nie udaje konta człowieka ani niezależnego reviewera.
- Brak profilu, scope, issuera albo cleanup oznacza konkretną odmowę/HITL.
  Nadzorca nie przejmuje operacji ani nie podaje swojego stałego tokenu.

## Kontrakt CLI i konfiguracji

Poniższe wywołania definiują docelowy interfejs. `TASK`, `ASSIGNMENT`, `PROFILE`, `LEASE`
i `COMMAND` to istniejące identyfikatory/komenda z kontekstu, nie identyfikatory do wymyślenia.
W repo używać bin/ace-*; w installed — instalowanych executables.

| Scenariusz | Wywołanie / wejście | Obserwowalny wynik |
|---|---|---|
| Prośba agenta | `ace-lab auth request --profile PROFILE --role developer --task TASK --assignment ASSIGNMENT --ttl 30m --format json` | Metadata lease: ID, provider, principal, role, task/assignment, scope/repositories, issued_at, use_until, provider_expires_at (jeśli istnieje), expiry_mode i status. Bez tokena. |
| Użycie | `ace-lab auth exec LEASE -- COMMAND ...` | Dostęp wstrzyknięty tylko do procesu wykonawcy przez kanał profilu; rzeczywisty cwd i konto coworkera; po wyjściu zakończenie przydziału. Nie jest to dowolne wykonywanie poleceń jako issuer/root. |
| Stan | `ace-lab auth status LEASE --format json` | Bezpieczne metadata i potwierdzenie/niepewność stanu zdalnego. Odczyt nie odświeża lease ani nie wydaje tokena. |
| Koniec / przerwanie | `ace-lab auth revoke LEASE` lub cleanup po exec/cancel/pause | Zdalny revoke dla tokenu, usunięcie przekazania i wynik. Powtórzenie jest bezpieczne; obcy lease jest odrzucony. |
| Recovery hosta | `ace-lab auth reconcile` | Uprawniony host rozstrzyga przerwane issue/revoke i przeterminowane przydziały w tym samym magazynie; nie odtwarza assignmentów. |
| Brak / przekroczenie praw | Zły profil, repo, rola, TTL albo wznowienie wygasłego lease | Odmowa przed operacją; powód i adresat eskalacji, bez fallbacku do innej tożsamości. |

Request jest idempotentny dla tego samego żywego task/assignment/profilu/roli i scope;
współbieżne request nie wydają dwóch aktywnych tokenów. Zmiana zakresu lub zakończony
lease wymaga nowego przydziału po ponownej kontroli. Domyślny TTL 30 min, domyślne maksimum
60 min; host może ustawić inny jawny limit profilu. Przekroczenie limitu jest odmową,
nie cichym obcięciem. Brak automatycznego odświeżania w nieskończoność.
Wynik zawsze pokazuje faktyczny termin użycia i osobno termin gwarantowany przez providera.

Normalny output jest table/json; błędy są niezerowe z kodem przyczyny. Exec zachowuje kod
procesu, a przy sukcesie procesu i błędzie cleanup zwraca błąd cleanup; raport zachowuje
oba wyniki. Nie dodawać komendy drukującej token ani eksportu do shell history.
Pusty/nieznany profil, niezgodna para task/assignment, terminalny assignment oraz
próba równoległego exec na tym samym lease są odmową. Różne assignmenty mają osobne
lease. Quiet/verbose nie ujawniają sekretów ani nie ukrywają błędu; force i dry-run
request/exec są poza zakresem. Read-only readiness realizują status i ace-lab verify.

Zaufana konfiguracja hosta, zarządzana przez ace-lab install, rozszerza istniejący
`/etc/lab/ace-lab/authorization.yml` o profile auth: provider, dozwolone principal/role,
repo/scopes, TTL, sposób przekazania i referencje do sekretów issuera. Istniejące principals
pozostają mapą widoczności, nie nadają automatycznie prawa wydawania tokenów.
Config projektu/coworkera tylko wskazuje profil; jego wpis nie może rozszerzyć polityki.
Weryfikować rzeczywiste konto wywołujące. Używać istniejącej granicy kont/plików hosta
oraz wąskiego wywołania instalowanego auth jako issuera (lokalnie lub przez skonfigurowane
SSH), bez nowego serwisu admission i bez dowolnej komendy root z parametrów agenta.

## Pluginy i wykorzystanie istniejącej mechaniki

Kontrakt pluginu obejmuje capabilities, issue, sprawdzenie scope/principal, status i revoke;
wyniki rozróżniają odmowę, brak wsparcia, błąd przejściowy i outcome-unknown. Sekret jest
prywatnym wynikiem handoff, poza serializowanym raportem. Użyć wzorca jawnej rejestracji
providerów obecnego w ACE; nie budować marketplace ani ogólnego silnika workflow.

- **Forgejo**: wydawać osobny token dla przydziału na skonfigurowanym koncie roli,
  z ograniczonym repo i scopes, potem usuwać dokładny ID tokena. Punktem wyjścia są
  `create_token`, `lease_integrator` i revoke z lab-config. Sprawdzić API/wersję serwera
  i realnie egzekwowany zakres; nie zakładać obsługi ograniczeń z najnowszych docs.
  Nie zmieniać globalnych praw konta przy każdym request/revoke i nie odwoływać tokenów
  innych zadań. Tożsamość reviewera nie może być tożsamością autora.
- **GitHub**: wykorzystać mechanikę GitHub App JWT → installation access token,
  wybrane repo i permissions, odczyt rzeczywistego expires_at oraz jawny revoke.
  Każdy przydział ma osobny token; klucz App nie trafia do wykonawcy. Token jest opaque.
  Krótsze use_until niż natywne expiry wymaga hostowego revoke o terminie use_until.
- **Env**: profil wskazuje dozwolone nazwy i bezpieczne źródła zmiennych; tylko
  child process otrzymuje wartości. Nie eksportować całego środowiska hosta ani
  odziedziczonych credential overrides omijających profil. Dla tokenu od providera env
  jest handoffem tego samego lease. Samodzielny statyczny env ma wyłącznie
  process-scoped exposure i jest odrzucony, gdy profil wymaga remote expiry/revoke.

Nie włączać wycofanego lab-forgejo-admin-lease ani kopiowania stałego admin PAT jako
implementacji krótkotrwałego tokenu. Uogólnić i przenieść mechaniki do ACE, a ich
konfigurację domenową pozostawić hostowi. Usunąć zastępowane ścieżki w odbieranym wdrożeniu;
nie utrzymywać równolegle dwóch właścicieli cyklu dostępu.

## Cykl, stan i odporność

Ace-lab auth jest jedynym właścicielem minimalnego rekordu lease: domyślnie
`/var/lib/lab/ace-lab/auth/leases/<id>.json`, prywatny dla issuera. Rekord zawiera
korelację, provider token ID, terminy i wynik cleanup, nie task progress, kolejkę ani
wartość sekretu. Przekazanie sekretu jest efemeryczne pod `/run/lab/credentials/`,
odrębne dla lease i odbiorcy, z weryfikacją właściciela/trybu oraz symlinków.
Issuer credentials zostają w obecnym chronionym magazynie hosta. Coworker zapisuje
wyłącznie referencję w swoim obecnym configu; assignment pozostaje właścicielem raportu.
Zaktualizować canonical owner map i ADR-034 w tym kroku o jawnie zatwierdzony zakres auth.
Nie dodawać ledger Work/Attempt, osobnego journala ani cache'u stanu innych narzędzi.

`expiry_mode` ma wartości provider, host-revoke lub process. Użycie jest ograniczone
przez najwcześniejsze: use_until, native expiry, zakończenie/przerwanie/pause assignmentu.
Host rejestruje termin cleanup przed handoff. Dla host-revoke użyć zainstalowanego
jednorazowego zadania schedulera hosta wywołującego auth revoke po ID (na labowym Linux:
systemd), niezależnego od procesu coworkera. Jest to cleanup poświadczeń, nie heartbeat
modelu ani nowy daemon. Gdy scheduler jest niedostępny, request wymagający go nie jest ready.
Przy starcie hosta reconcile rozstrzyga zaległe przydziały przed dopuszczeniem nowych.

Po SIGKILL wykonawcy cleanup nadal następuje najpóźniej w terminie; zwykły exit/cancel
odwołuje dostęp od razu. Po śmierci całego hosta token z natywnym TTL wygasa po stronie
providera; host-revoke wymaga powrotu hosta i łączności. Przy awarii sieci nie twierdzić,
że token zdalny wygasł. Użycie lokalne jest zablokowane, zapis pozostaje revoke-pending,
retry robi host przez reconcile i jest jawna eskalacja. Nie deklarować odebranego cleanup,
zanim nieważność tokenu zostanie potwierdzona. Brak natywnego TTL jest widoczny przed
handoff, nie ukryty za use_until. Profil wymagający gwarancji expiry także przy awarii
hosta odrzuca provider bez tej zdolności.

Utracona odpowiedź issue nie powoduje ślepego ponownego mint. Zapisać korelację przed
wywołaniem; Forgejo może odnaleźć/odwołać własny token po jednoznacznej nazwie/ID.
Gdy provider nie pozwala odzyskać/odwołać nieznanego tokenu, request pozostaje unknown
i czeka na potwierdzoną nieważność, np. granicę natywnego TTL; nie wydaje drugiego tokenu.
Crash między issue a handoff powoduje cleanup bez startu pracy. Nie usuwać materiału
potrzebnego do revoke, zanim provider potwierdzi skutek; przy utracie efemerycznego
sekretu GitHub po reboot wynik czeka na native expiry, zamiast pozorować zdalny revoke.
Revoke jest idempotentny; 401/404 mają znaczenie tylko w kontekście właściwego endpointu
oraz zaufanej tożsamości. Nie każdy błąd uwierzytelnienia issuera dowodzi revoke.
Resume po expiry wymaga nowego lease w tym samym uprawnionym profilu, bez automatycznej
zmiany roli ani przywracania zakończonego tokenu.

## Kryteria akceptacji

- [ ] Coworker otrzymuje pełny brief, sam uzyskuje dostęp przez auth, wykonuje pracę i raportuje do nadzorcy; installed zachowane także na resume.
- [ ] Brak/wygasły/niezgodny dostęp daje odmowę i eskalację; nie rozszerza roli, repo ani praw przez config/argv/fallback.
- [ ] Forgejo, GitHub i env mają działające pluginy oraz zgodne z ich capabilities ograniczenie czasu, cleanup i brak sekretów w promptach/dowodach.
- [ ] Każdy lease ma jednego właściciela, jednoznaczną korelację i potwierdzenie zakończenia albo jawny stan pending/unknown; zaktualizowano owner map i ADR.
- [ ] Wykonano producent → konsument, przypadki błędów i instalowany odbiór; usage, role guides i manifesty odpowiadają faktycznemu zachowaniu.

## Plan weryfikacji i mapa dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | prepare → start → auth request/exec → realna operacja → report/cleanup; poprawny task/root/assignment, konto oraz installed; resume z nowym lease po expiry. |
| 2 | Próby innego repo, roli, issuera, cudzej referencji, nadmiernego TTL i podmienionego config/env; brak skutku zdalnego, konkretny HITL. Developer nie może wykonać formalnego approval własnej pracy. |
| 3 | Osobne testy kontraktu wszystkich pluginów; live Forgejo issue/use/revoke z odrzuceniem ponownej operacji; live GitHub scope, native expiry i revoke; env podany tylko childowi. Osobno próba odmowy static env jako remote lease. |
| 4 | Wyjście, cancel/pause, SIGKILL, host restart, awaria sieci podczas revoke, crash po issue przed handoff i utrata odpowiedzi; retry bez dubli i bez skasowania dostępu innego zadania. Pełny owner map i kontrola praw plików na realnym FS. |
| 5 | Opublikowane pakiety core/pluginów i instrukcji w instalowanym runtime, wykonana delegacja pod docelowymi kontami oraz status z prawdziwymi terminami/expiry_mode. Brak pluginu/issuera/schedulera daje not-ready. |

Uruchomić `bin/ace-test ace-lab all`, `bin/ace-test ace-coworker all`,
`bin/ace-test ace-overseer all`, testy nowych pakietów pluginów oraz `bin/ace-test-suite`
według workflow verification. Nie ograniczać dowodu revoke do mocka lub usunięcia pliku.
Próby deterministyczne sterują zegarem; próba live osobno dowodzi natywnego expiry.
Sekrety do probe są używane poza modelem i nie trafiają do zachowanego outputu.

## Kontekst, granice i rezultaty

Poprzednik: 8xs.t.pu0.6. Następny krok: 8xs.t.pu0.8.
Wykorzystać role/delegację sbz.2/.3/.4. Dokładnie 16 bezpośrednich dzieci pozostaje
bez zmian. Ten krok dostarcza auth wraz z instalacją i odbiorem, nie odkłada pluginów
ani cleanup do nowego taska. .8/.9 konsumują ten kontrakt dla review/merge/publish;
.e/.f sprawdzają go w pełnym cyklu i przy awarii.

Rezultaty: kod i pakiety auth/pluginów, integracja coworkera, konfiguracja hosta bez
sekretów w Git, aktualne docs/owner map/role guides, dowody i jawne ograniczenia providerów.
Nie rozszerzać przyznanej autonomii, nie przejmować zadania przez nadzorcę i nie tworzyć
ogólnego brokera mutacji. Inne provider plugins niż Forgejo/GitHub/env są rozszerzeniem
kontraktu, nie wymaganiem implementowania nieokreślonego „etc”.

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-coworker/docs/usage.md
- ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md
- ace-lab/docs/usage.md
- ace-coworker/handbook/workflow-instructions/coworker/worker.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/8xs.t.pu0.6-zamyka-sprawy-hitl-bez-sierot.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md
- ace-git/lib/ace/git/providers.rb
- docs/decisions/ADR-034-file-based-lab-state-ownership.md
