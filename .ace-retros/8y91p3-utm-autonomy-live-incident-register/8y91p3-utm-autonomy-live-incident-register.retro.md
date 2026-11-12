---
id: 8y91p3
title: utm-autonomy-live-incident-register
type: standard
tags: [utm, e2e, overseer, 8y0-t-x27]
created_at: "2026-11-10 01:07:54"
status: active
---

# utm-autonomy-live-incident-register

## What Went Well

- Na `utm122` oba scenariusze przeszły raz na rzeczywistym UTM ARM64 z lokalnym Forgejo. W `utm125` ponownie potwierdzono trzy autonomiczne merge’e w wymaganej kolejności, otwarty release i pięć minut zdrowej obserwacji bez dodatkowej tury. Ostatni merge przekroczył limit testu.
- Eksport natywny UTM pozwolił przejść reset, instalację i konfigurację Forgejo bez obsługi ręcznej. Izolowany worker skutecznie opublikował raport we własnym worktree, a Lab Overseer odebrał go przez eyes.
- Powtarzalne buildy, przypięte manifesty i dowody z właścicieli stanu pozwalają odróżnić awarię infrastruktury od błędu delegacji oraz od fałszywego zaliczenia testu.

## Zakres

Żywy rejestr dla `8y0.t.x27`. Obejmuje przebiegi od `utm122` z 8 listopada do `utm131` z 10 listopada 2026, UTC. Szczegóły SHA, manifestów i sesji są w [dzienniku dowodów taska](../../.ace-tasks/8y0.t.x27-odtwarzalne-stanowisko-testowe-ace-na/docs/2026-11-05-checkout-recovery.md). Surowe sesje i obrazy zostają w prywatnych artefaktach lokalnych.

## What Could Be Improved

### Rejestr problemów

| ID | Obserwacja i skutek | Właściciel i działanie | Stan |
| --- | --- | --- | --- |
| UTM-01 | Reset `utm122` przerwany restartem Maca, `8y791n6`. Log zasilania z tej nocy pokazuje też uśpienie przy 1% baterii. | Host. Zachowano VM i uruchomiono runner w tmux z `caffeinate`. | Ponowienia przeszły poza ten punkt. Restart hosta przerywa aktywny przebieg. |
| UTM-02 | `8y7dooz`: setki odczytów zadania ACE z `/lab`, mimo że właścicielem jest `/lab/ace`. Worker nie ruszył. | Overseer, `104dfe746`. Odczyt z jawnego katalogu projektu oraz zakończenie po nieudanej korekcie. | Potwierdzone na żywo w `8y7ians`. |
| UTM-03 | `8y7ians`: pierwsza tura Overseera ACE obsługiwała backlog. Gotowość potwierdzona po ok. 51 min przy limicie 45. | Overseer, `250f49d42`. Pierwsza tura uzbraja eyes, oczekujące zmiany dostają własną turę. | Potwierdzone komponentowo. Powtarzalność w limicie otwarta. |
| UTM-04 | `8y7lzdv`: zlecenie kazało workerowi użyć hostowego `ace-lab prepare`. Próby 120 i 600 s wygasły, weryfikator nie ruszył. | Overseer i Coworker, `06859ef82`. Oddzielono kontrole projektu od operacji hosta. | `8y7p8qi` potwierdził osobnego workera i weryfikatora bez poleceń hostowych. |
| UTM-05 | `8y7p8qi`: worker CLI stracił 961 s na `bundle install`, choć test działał przez zainstalowany `ace-test`. Ostatni merge po 195 min 38 s przy limicie 180. | Coworker, `4cd5898c1`. Instrukcje ról respektują tryb `installed`, pełne testy i review pozostają wymagane. | Testy pakietów zielone. Dowód E2E w limicie otwarty. |
| UTM-06 | Runner w `8y7p8qi` zapisał `expired=false` mimo czasu merge’u. W `8y7ypp8` użył czasu startu workera jako początku bootstrapu i wszedł do TC-002. | Harness, `4cd5898c1`, `9cb8f92f1`. Weryfikator używa czasu z Pi i Forgejo. Bootstrap ma helper, który wiąże dokładny cel i sukces reconcile z natywną sesją. | Fałszywy pozytyw bootstrapu odrzucony na żywo. Pełna powtórka otwarta. |
| UTM-07 | `8y7xizu`: macOS przerwał odczyt katalogu pakietu bazowego przed klonowaniem. | Harness, `38af6e172`. Odczyty pakietu przejęła aplikacja UTM przez eksport. | Kolejne resety przeszły na żywo. |
| UTM-08 | `8y7h5et`, `8y7xjmr`: UTM zwrócił `-2700` podczas odpytywania wyniku procesu. Przy jednej awarii nie udało się od razu potwierdzić zamknięcia VM. | Harness, `21ca397a7`. Ponawiany jest odczyt istniejącego wyniku w dotychczasowym limicie. | Próby kontrolowane i kolejne instalacje przeszły. Sporadyczne błędy transportu nadal obserwowane. |
| UTM-09 | `8y7ypp8`, `8y8g1xk`: monity macOS App Data wstrzymywały setup i zbieranie dowodów. Zgoda nie zapobiegła kolejnym monitom. | Harness, `0cb95abc4`, `38af6e172`. Polecenia gościa używają rejestru UTM. Reset sprawdza kopię w prywatnej ścieżce dowodowej, której UUID i nazwa zgadzają się z rejestrem. | Reset, runtime i lokalny Forgejo przeszły bez klikania w `8y8q8hb` i `8y8u9mc`. |
| UTM-10 | `8y8q8hb`: worker przygotował projekt, ale zlecenie wymagało zapisu do niewidocznej skrzynki Lab Overseera. Raport opublikowano z worktree, a próba odzyskania zachowała failed step, więc sukces został odrzucony. | Overseer i Coworker, `e133d9ad4`. Raport jest publikowany po stronie projektu. Wymóg zapisu do skrzynki usunięto z kontraktu zlecenia. | `8y8u9mc` potwierdził odbiór raportów workera i weryfikatora. |
| UTM-11 | `8y8q8hb`: worker uruchomił zbędne `ace-task plan`, a nadzorca ponownie uruchamiał eyes przy przekazaniu. Obserwacja chwilowo raportowała `observationUnavailable`. | Overseer i Coworker, `e133d9ad4`. Przygotowany przydział wystarcza do wykonania, zdrowy obserwator pozostaje uzbrojony. | Instrukcje i testy sprawdzone. Dokładny przebieg odzyskania obserwacji pozostaje w odbiorze. |
| UTM-12 | `8y8u9mc`: zlecenie podało `scope: project` w eyes JSON. Worker wykrył błąd i opublikował raport. Po korekcie gotowość przyszła po 48 min 50 s. | Overseer i Coworker, `3c31ef1bf`. Start używa `project`, eyes używa `current`. Worker i weryfikator sprawdzają plik zainstalowanym walidatorem. | `8y909wx` osiągnął uwierzytelnioną gotowość po 38 min 36 s, a `8y97qxq` na świeżym `utm129` po 38 min 5 s. Odbiór pełnego cyklu w toku. |
| UTM-13 | `8y8u9mc`: odczyty timing helpera chwilowo blokował lock lifecycle, wyjątek ScriptingBridge `virtualMachines` lub UTM RPC. Kolejne odczyty odzyskały dostęp. | Harness. Obserwować częstotliwość i zachować wynik z właściciela. | Odzyskane w tej próbie. Brak dowodu trwałej naprawy ScriptingBridge. |
| UTM-14 | `8y8xyf4`: HTTP 503 od przypiętego Debian Snapshot przed startem fixture. | Harness, `83bf3d40b`. Do trzech prób pobrania tego samego Release, z zachowaniem SHA-256. | Test kontrolowany zielony. Ponowienie `8y909wx` przeszło pełny setup i bramkę bootstrapu na tym samym snapshocie. |
| UTM-15 | `8y909wx`: synteza `review-8y94jh` zwróciła poprawny obiekt z czterema kompletnymi uwagami i unikatowymi kluczami. Parser pomylił bloki kodu wewnątrz tekstu uwagi z opakowaniem odpowiedzi. W pierwszych ponowieniach lista uwag nadal nie powstała. | `ace-review`, `9e59575e8`. Surowy obiekt trafia w całości do parsera, a opakowanie Markdown rozpoznaje wyłącznie znaczniki w osobnych liniach. | Regresja czerwony → zielony, 918 testów pakietu i niezależne review przeszły. Dwa buildy `utm129` mają ten sam SHA-256. Na `utm128` recenzent sam odzyskał syntezę, o 03:38 UTC zapisał pierwszą pełną rundę, a po trzech pełnych rundach opublikował aprobatę. Osobny integrator scalił PR 5 o 04:32:39 UTC. |
| UTM-16 | `8y909wx`: pierwsza próba narzędzia review przekroczyła 900 s przed uzyskaniem raportu. Później próby ratowania syntezy przez Claude i Antigravity nie znalazły ich CLI, a próba alternatywnego Z.AI nie zwróciła wyniku. Osobne generowanie opisu commita także przekroczyło limit. | Runtime dostawcy. Pi/Z.AI na tej samej sesji zwrócił pełny raport oraz kompletną syntezę w kolejnych próbach. Recenzent ponowił commit. | Osobny pomiar od błędu parsowania. Przyczyna pierwszego timeoutu jeszcze nieustalona. |
| UTM-17 | W osobnym checkoutcie do naprawy `ace-test` nie widział lokalnych gemów. Ustawienie ścieżki w powłoce uruchamiało CLI, ale nie proces testu w izolowanym środowisku. | Środowisko deweloperskie. Udostępniono istniejący bundle pod ścieżką oczekiwaną przez runnera w nowym checkoutcie. | Test bazowy 34/146, potem test regresji wykazał właściwy błąd. Żadnej zmiany w działającej VM. |
| UTM-18 | `8y909wx` 03:38–03:40 UTC: recenzent użył nieobsługiwanych opcji w `ace-coworker rounds record` oraz złych argumentów kierujących `ace-assign` do kroku. `8y97qxq`: runner o 06:22 użył `herdr agent list --json`, weryfikator o 06:48 nieobsługiwanej opcji `--report`, a Overseer o 06:50 przecinka w wartości `ace-task update --set`, która jest listą `key=value`. | Coworker, Assign, Task i runner. W sesjach wrócono do rzeczywistych interfejsów. `herdr agent list` domyślnie zwraca JSON. | Odzyskane samodzielnie. Wywołania rozpoznane w zapisie Pi i `commands.exit`. |
| UTM-19 | `8y909wx`: cel dostawy w Pi o `01:59:06.917Z`. Po 180 minutach Forgejo potwierdzał tylko bazowy PR 5. CLI, dokumentacja i release były otwarte. Runner nadal odpytywał stan po terminie. | Właściciele ścieżki review i harness. Kandydat `utm129` usuwa potwierdzony błąd parsowania UTM-15. Werdykt zależy od dokładnego czasu wszystkich wymaganych merge’ów. | `8y909wx` przerwano o 05:08 UTC. W `8y9cdr3` runner zapisał brak merge’u dokumentacji po 180 min, pominął test bezczynności i potwierdził zatrzymanie VM. Obie próby bez kredytu odbioru. |
| UTM-20 | `8y97qxq` 06:53:54 UTC: Lab Overseer próbował potwierdzić rewizję, której eyes nie rozpoznawało jako oczekującej lub dostarczonej. Wywołanie odmówiło potwierdzenia. | Eyes i Lab Overseer. Kontrola rewizji zadziałała. Sesja ponownie odczytała stan. | Odmowa nie zablokowała bootstrapu. Uwierzytelniona gotowość projektu o 07:00:08 UTC. |
| UTM-21 | `8y97qxq` 07:19 i 07:20 UTC: `ace-task create` pod dzierżawą Forgejo kończył się `invalid byte sequence in US-ASCII`, mimo argumentów ASCII. Sesja Pi ma UTF-8, a wykonanie przez dostawcę nadpisuje `LC_ALL` wartością `C`. | `ace-lab` i projekcja dostawcy Forgejo. Nowa projekcja ustawia `C.UTF-8` i zachowuje angielskie monity Git używane przez askpass. | Overseer sam utworzył zadanie o 07:21 po jawnym ustawieniu kodowania Ruby na UTF-8, po czym wysłał przydział. Poprawka przeszła regresję i niezależne review. UTM nadal używa `utm129`. |
| UTM-22 | `8y97qxq`: zainstalowany `ace-test` nie uruchomił pełnego pakietu z powodu brakujących zależności checkoutu. Test licznika przeszedł 3 testy i 4 asercje, a pełny pakiet nadal blokował PR. Nawrót w `8y9cdr3`: o 10:19 UTC test wymagany przez zgłoszenie przeszedł 4 testy i 6 asercji. Potem instrukcja skomponowanego kroku 020 ponownie wymusiła pełny pakiet. Worker sam zainstalował zależności i ponowił test. | Coworker i fixture Forgejo. Zgłoszenia deklarują wymagane sprawdzenia. Instrukcja roli zachowuje domyślny pełny pakiet, gdy zakres jest nieokreślony. Krok `verify-test` ma korzystać z tej samej reguły zamiast powielać politykę zakresu. | W `8y97qxq` worker zgłosił `error` w zdarzeniu `8y9bzf`. Potwierdzono `verify-test=failed` i zero PR-ów. Próbę zakończono o 08:14 UTC z zachowaniem zapisów. `utm130` nadal działa. Regresja skomponowanego kroku wykazała pozostałą sprzeczność. |
| UTM-23 | `8y97qxq` 08:01:58 i 08:02:16 UTC: dwie próby wznowienia przez Herdr wysłały `--wait --until --timeout`. Chroniona ścieżka sesji odrzuca pole `wait`; właściwy terminal i żywy proces potwierdzono osobnym odczytem. | Instrukcje Overseera i kontrola sesji. Instrukcja podaje `herdr agent prompt <terminal> "<text>"`; eyes obserwuje następny stan. Ochrona promptu i limit jednej próby odzyskania pozostają egzekwowane. | Przeszło niezależne review. Odbiór ścieżki na kolejnym kandydacie otwarty. |
| UTM-24 | `8y9cdr3`: pełny pakiet workera zwrócił 116 testów i 1 błąd. `lab_vm_lease_evidence_test.rb` nie doszedł do sprawdzenia odmowy Forgejo po awarii. | Harness. Symulowany czas sprzątania pochodził z początku testu, a czas awarii z bieżącego zegara. Granica sekundy mogła zmienić oczekiwany powód odmowy. Poprawka ustala zegar wyłącznie w teście. | Worker powtórzył pełny pakiet o 10:31 UTC: 116 testów, zero błędów, 19 pominiętych. Poprawka w osobnym drzewie przeszła 112 testów harnessu i niezależne review. |
| UTM-25 | `8y9cdr3`: projektowy Overseer odkłada niezależne zgłoszenie dokumentacji do czasu merge’u CLI. Pi o 12:08 UTC opisuje tę kolejność, a prywatne zadanie ma tylko dwa przygotowane zestawy przydziałów. | Overseer. Graf fixture wiąże CLI z bazą i release z trzema zmianami. Dokumentacja nie ma poprzednika. `cbfb4a929` kieruje gotową niezależną pracę do osobnego worktree. | W `8y9cdr3` dokumentacja nie miała PR po terminie. W `8y9k1ix` baza i dokumentacja dostały osobne przydziały i cele odpowiednio o 15:24:21 i 15:26:00 UTC. Oba PR-y powstały przed pierwszym merge’em. Pełny odbiór trwa. |
| UTM-26 | `8y9k1ix` 15:31:51 UTC: worker dokumentacji dostał `Permission denied` przy `rg`. Pi pobrało binarium do własnego katalogu pod `/run`, zamontowanym jako `noexec`. Obraz gościa nie miał `/usr/bin/rg`. | Runtime obrazu testowego. `055041138` instaluje `ripgrep` z przypiętego obrazu pakietów Debiana i sprawdza ścieżkę i wykonanie przed zapisem gotowości. | Świeży klon `62a7d67222860af2` przeszedł instalację. Rzeczywisty worker Pi przez Herdr wykonał `grep` przy nadal aktywnym `noexec` na `/run`. |
| UTM-27 | `8y9k1ix` 16:22–16:23 UTC: Lab Overseer, Overseer projektu i integrator otrzymali HTTP 429 od Z.AI. Gość zapisał kod `1310` oraz datę odnowienia limitu `2026-11-12 01:03:54` bez strefy. O 16:23:28 runner zgłosił brak końcowej odpowiedzi Pi, bez werdyktu. | Dostawca Z.AI. Kod 1310 oznacza wyczerpany limit użycia. Odczyt stanu Forgejo wykazał dwie aprobaty, brak merge’ów i otwarty release. | Brak kredytu odbioru. Zachowano VM i raport. Drugi skonfigurowany dostęp Z.AI, sprawdzony osobno z tym samym modelem, zwrócił ten sam kod i termin. |
| UTM-28 | Raport hosta dla `8y9k1ix` pominął dowód niepewnego wyniku wykonania. Parser strumienia Pi rzucał wyjątek przed dołączeniem tego dowodu. | Adapter Pi. `aecd158cf` dołącza istniejące ograniczone metadane dowodu także po błędzie parsowania. | Regresja czerwony → zielony. Niezależne review i 459 testów pakietu, zero błędów, 11 pominiętych. Wyczerpanie limitu pozostaje oddzielnym zdarzeniem. |
| UTM-29 | Świeży klon `62a7d67222860af2` nie miał `fd` ani `fdfind`. Zainstalowane Pi 0.86.1 potwierdziło brak narzędzia w próbie offline. Jego narzędzie `find` korzysta z tej samej ścieżki pobierania do `/run` co `grep`. | Runtime obrazu testowego. `e05c92ed6` instaluje `fd-find` z przypiętego obrazu pakietów i sprawdza wykonywalny `/usr/bin/fdfind`. Pi rozpoznaje nazwę Debiana. | Rzeczywisty worker Pi wykonał `find`. Kolejny świeży klon `27d89c111762acc3` automatycznie zainstalował oba pakiety i przeszedł kontrolę gotowości bez doinstalowywania. |
| UTM-30 | `27d89c111762acc3` około 19:20 UTC: sonda operatora wysłała drugi lokalny skrót powłoki Pi w trakcie działania pierwszego. Pi odmówiło, zostawiło tekst w edytorze, a następny wpis się do niego dopisał. | Sonda diagnostyczna. Odpowiedź Herdr potwierdza dostarczenie wejścia. Skutek wymaga osobnego wyniku Pi i odczytu stanu dzierżawy. | Na tej samej, niewykorzystanej dzierżawie ponowiono wykonanie po ustaniu wcześniejszego polecenia. Odczyt Forgejo, cofnięcie i ponowienie `revoke` potwierdzone. |
| UTM-31 | Przy aktywnym poleceniu ogólna odmowa obcej sesji mogłaby wynikać z blokady pojedynczego użycia. Dodatkowo lokalna sonda po awarii uznała wyłącznie wynik `revoked`, choć `already_invalid` również oznacza potwierdzone cofnięcie przy stanie `revoked` i odmowie Forgejo. | Weryfikator E2E. `a47a931fc` wymaga odmowy z powodu innej tożsamości na niewykorzystanej dzierżawie, późniejszego uruchomienia przez właściciela oraz potwierdzenia HTTP dla obu wyników sprzątania. | Próba na żywo potwierdziła odmowę odczytu i `different principal` przed pierwszym użyciem dzierżawy przez jej właściciela. Próby wygaśnięcia i awarii dały 200 → 401. Testy i review zielone. |
| UTM-32 | `27d89c111762acc3` 19:26 UTC: ukrycie programu Pi dało `blocked` i kod 1. Raport publiczny podał ogólny `Ace::Herdr::CommandError` bez nazwy brakującego elementu. | Diagnostyka startu Overseera. Próba odróżnia właściwą odmowę startu od komunikatu przydatnego do samodzielnego znalezienia przyczyny. | Herdr zachował pustą listę agentów, a plik przywrócono z identycznym SHA-256. Komunikat pozostaje ogólny. |

## Key Learnings

- Uprawnienia i komunikacja muszą wynikać z właściciela operacji. Adres odbiorcy raportu nie oznacza prawa zapisu do jego skrzynki. Gotowość projektu potwierdza Lab Overseer po niezależnej weryfikacji.
- Licznik czasu ma wiązać dokładny cel i potwierdzony efekt z tą samą instancją testu. Suma godzin pracy nie zastępuje dowodu zaakceptowanej roli, przydziału, wersji i wyniku.
- Przy ponowieniu odczytu można zachować istniejący uchwyt lub przypięty adres. Ponowienie skutku, takiego jak start procesu, publikacja raportu czy merge, wymaga sprawdzenia, czy skutek już zaszedł.
- Niezależne review wykryło zbyt szerokie dopasowanie komendy reconcile w helperze czasu. Test regresyjny odrzuca teraz komentarz i cytowaną komendę z odtworzonym wynikiem. Nie ma porównywalnych danych, żeby liczyć odsetek fałszywych alarmów per model.

## Action Items

- Dopisywać problem w chwili wykrycia. Jeden ID na przyczynę, a nawroty dopisywać z UTC, ID przebiegu i skutkiem. Oddzielać stan poprawki od dowodu na działającej VM.
- Linkować do minimalnego dowodu z właściciela stanu. Nie kopiować surowych sesji ani poświadczeń.
- Po każdym werdykcie uzupełniać wpisy i rozróżniać awarię setupu, błąd zachowania ról i błąd harnessu. Do odbioru liczyć wyłącznie dwa pełne przebiegi `003 → 004` na tym samym źródle i manifeście, z resetem pomiędzy.

## Contract correction and local release work — 2026-11-10

| ID | Observed problem | Correction / owner | Evidence status |
| --- | --- | --- | --- |
| UTM-33 | Systemd issuer, DynamicUser and idmapped mounts became prerequisites for ordinary delegation despite the intended trusted worktree/process/env contract. | Captain explicitly replaced the contract. Remove the OS-session branch while retaining provider scope checks and existing state owners. | Baseline preserved at `8db86b703a49b8a73a90ebafe8c0cd755b1bc749`; local ace-lab suite 784 tests passed after simplification. VM not run. |
| UTM-34 | work-on/handoff could prepare assignments and windows without starting an executor. The isolated report path returned another instruction to the coordinator instead of dispatching. | Existing orchestration calls ordinary Herdr and records native identity on the coworker commission. | Implementation and restart/replay regressions in progress. |
| UTM-35 | Re-preparing a commission compared its full YAML with generated fields and could erase the newly recorded executor binding. | Coworker config writer must preserve binding for identical commission and refuse identity replacement. | Found by independent integration review before release; regression in progress. |
| UTM-36 | Private Forgejo observation lacked enduring project read credentials; issue body and labels were absent from revisions. | Session role environment supplies repository-scoped observer access; normalized provider evidence includes body and labels. | Forgejo package 197 tests / 1005 assertions passed. Live private-Forgejo wake remains unverified. |
| UTM-37 | Reusing full OS reset for every debugging attempt lengthened feedback unnecessarily. | Separate scenario-data repeat from explicit cold-reset acceptance. | Harness deterministic checks pass; no VM actions performed. |
| UTM-38 | Ordinary command cleanup hit macOS EPERM when signaling a group containing only the parent's unreaped zombie. | Reap the owned child before checking surviving group members. | Actual local subprocess regression and ace-lab suite pass. |
| UTM-39 | Local eyes readiness only recognized Linux process birth, so ordinary macOS sessions could never become ready. | Reuse portable process identity at the existing eyes/readiness boundary. | Exact Darwin birth reused from the existing owner; actual Node/Ruby readiness and exited-process rejection pass locally (18 tests), full wake wrapper passes. VM not run. |

| UTM-40 | LocalCommand could reap a leader just before interruption, then ECHILD skipped KILL of remaining descendants; failure while installing TERM handling was outside cleanup coverage. | Narrow ECHILD rescue to the reap attempt and always kill the remaining group; protect trap setup with cleanup. | Independent review finding. 7 local tests / 13 assertions, including actual TERM-ignoring descendant and trap setup failure, pass. No VM claim. |
| UTM-41 | An error report was persisted before failed executor retirement; repeat error reports then skipped retirement permanently. | Retry cleanup for every recorded report without advancing a failed assignment or rewriting its accepted record. | 22 ReportProcessor tests / 173 assertions pass, including repeated error and dry-run cases. |
| UTM-42 | Failed installed coordinator starts could leave copied credentials without confirmed process cleanup. | Close the newly created native pane before removing auth; preserve credentials and report blocked when closure is unconfirmed. | Start/report tests 60 / 361 assertions pass with one existing skip. Successful coordinator exit cleanup separately assigned to native process owner. |
| UTM-43 | Lab first-turn guide told the coordinator to dispatch before ending the turn, while dispatch readiness required that first turn to be complete. | Arm healthy observation and END the first turn; retain initial revisions for an eyes wake, then commission bootstrap. | Confirmed integration contradiction. Instruction-contract regression and existing readiness branch tests cover order; model/VM acceptance deferred. |
| UTM-44 | Launcher recipient lookup used `.ace/overseer/eyes.json`, while the canonical project configuration is `.ace-local/overseer/eyes.json`. | Launcher reviewer aligned lookup and its regression fixture with the armed canonical source. | Independently identified and handed to launcher owner; local regression in progress. |
| UTM-45 | Reviewer/bootstrap guides retained mandatory lease/service/OS masking language after architecture simplification. | Conditional temporary auth only; configured static scoped credentials remain valid; private tasks remain coordinator-owned without same-UID isolation claims. | Shipped instruction and canonical state-map review; no VM claim. |

| UTM-46 | Two foreground CLI tests still required exec/PID replacement after startup changed to wait for a separate process and clean its auth. One fixture omitted the required scope/root. | Correct the tests to run a real child, assert explicit environment and distinct PID, parent return after credential cleanup, and retained transcript directory. | 11 start-command tests / 49 assertions pass. Product semantics unchanged by test fix. |
| UTM-47 | Hermes integration acknowledged only the first event of a delivered batch, then assumed all observations were handled after restart. Added source-health revisions correctly remained pending and caused a second wake. | Assert the answered case is present exactly once, acknowledge every handled event in the batch, then verify unchanged restart silence. | Original test confirmed unchanged from origin/main; observer's new healthy markers explain the failure. 12 native-sync tests / 79 assertions pass without a model or broker. |

| UTM-48 | Scenario repeat retained the pinned native Pi integration in the installed runtime, but fixture setup required that file to be absent. Every second setup would stop before starting an agent. | Keep the root-owned runtime asset, reject symlinks, reinstall it with the pinned Herdr native installer and require current integration status. | Independently identified before release. Local executable setup sequence succeeds twice; noncurrent status and symlink reject. Combined reset/install run: 5 tests / 9 Ruby assertions plus Python filesystem assertions, report `609bee79-60cd-4d86-988b-5d37a6fde872`. No VM acceptance claim. |
| UTM-49 | Reset cleared the Herdr socket but retained `~/.config/herdr/session.json` and `~/.local/state/herdr`, allowing old panes and workspaces to reappear in the next scenario. | Export both native state directories as private evidence and remove them with scenario data; keep installed tools. | Local temporary-filesystem regression clears actual snapshot files on two distinct runs and confirms the runtime survives both resets. No VM run. |
| UTM-50 | Runtime provisioning retained `libnss-systemd` and forced Yama ptrace scope 2 solely for the removed DynamicUser/isolated-session path. | Remove the explicit obsolete dependency and kernel-policy mutation; ordinary session tests do not claim OS isolation. | Provisioning shell syntax checked. No guest packages or kernel settings changed in this session. |

The release stage must not consume a paid model or count deterministic test doubles as autonomous acceptance. Full current-candidate UTM acceptance remains outstanding.

| UTM-51 | Four scripted real-Pi SDK cases manually fired a timer without advancing observation time. The reload case also used an unbound SDK `ctx.reload`, which silently did nothing. Proper timing exposed a real same-process recovery bug: explicit resume retained the sent revision of an unconfirmed notification and never retried it. | Advance the injected clock by the configured schedule interval; bind actual SDK reload. On explicit reconciliation of `notification-unconfirmed`, clear only its delivery suppression, retaining pending business revisions and suppressing confirmed deliveries. | New same-process regression proves no blind retries, one explicit retry and no duplicate confirmed delivery. Pi SDK acceptance passes all 13 scripted cases (wrapper 1 test / 6 assertions), report `c0202546-1c90-4b10-99e6-66f8c2df7799`; wake wrapper passes 2 tests / 7 assertions, report `2ecb73eb-5bb6-4f7b-bd77-431a77c950f2`. No provider or VM used. |

| UTM-52 | Independent review caught that clearing all delivery suppression during uncertain resume would also resend earlier confirmed but unacknowledged batches. | Keep only the latest delivery batch in ephemeral memory; explicit reconciliation releases matching uncertain key/revisions and preserves prior confirmed suppression. No additional persisted state. | Mixed confirmed-A/uncertain-B regression passes: resume sends only B and neither event is acknowledged implicitly. Final wake and scripted SDK targets both pass with the reports in UTM-51. |

| UTM-53 | Screenshots confirm Max Legacy V2, weekly quota 0%, 2.1B recent tokens (mostly Flash) and a 16.2B historical weekly tile. Captain confirms annual-plan expiry around 4 November, then possible complimentary months. This fits Z.AI's documented migration from no-weekly-limit legacy plans to two complimentary months on the current plan. | Treat weekly ceiling after annual expiry as the leading cause, not the new credit tariff. V2 weekly allowance equals five short-window allowances versus 33.6 periods/week, illustrating a possible ~6.7x sustained-capacity cut. Separately measure wasted work and align chart/quota windows. | Updated [quota audit](../../.ace-tasks/8y0.t.x27-odtwarzalne-stanowisko-testowe-ace-na/docs/2026-11-11-glm-quota-audit.md). No model or VM invoked. Exact old entitlement and grant history remain unverified. |
| UTM-54 | Pi adapter returns the last assistant message's measured usage, not a sum over all model/tool rounds. E2E reports inspected do not reconcile all host and guest agents with account consumption. | Distinguish response usage from run totals; aggregate actual request evidence without double-counting terminal copies, retries or exported sessions. Include nested calls and explicit unknowns. | Confirmed by source inspection; correction and deterministic multi-round accounting tests remain pending. Does not explain a number taken directly from Z.AI's dashboard. |

## Prepared-VM update correction — 2026-11-11

- **Repeated dependency work:** a prepared VM update spent over 30 minutes in per-gem dependency probes and automatic final diagnostics. Replace the install resolver with one Bundler installation; keep verification explicit. Single probes measured 0.501–0.647 seconds; total subprocess count is unknown. Local suites pass; VM resume pending.
- **Lost terminal visibility:** QEMU's 120-second host deadline did not stop the guest installation. Use SSH and persistent native terminals for ongoing work; QEMU remains a recovery/bootstrap interface. Never duplicate a timed-out installation without checking its process.
- **Unverified startup advice:** `ace-herdr start` was described as existing although the public command did not exist. Implemented it and tested configured startup; stop presenting hypothetical commands as verified instructions.
- **Failed-update review finding:** replacing a live Gemfile before successful resolution can disable existing binstubs. Restore prior Gemfile/lock/config on failure; actual offline CLI regression proves continued operation.
- **Configuration propagation review finding:** configured installed mode must reach Pi extension selection, not just native process environment. Fixed effective environment propagation and preserve inherited installed mode.
- **Read-only diagnostics review finding:** Bundler's ordinary check may write a lockfile. Use frozen `bundle check --dry-run`; never claim diagnostics are read-only without checking the underlying tool.

Implementation and local evidence: [runtime correction record](../../.ace-tasks/8y0.t.x27-odtwarzalne-stanowisko-testowe-ace-na/docs/2026-11-11-runtime-start-simplification.md). This is not a live-autonomy acceptance.

## Live resume after PR405 publication — 2026-11-11

- Published/installed lab0.16.0, herdr0.11.0, overseer0.30.0 from main `2d0eb676a5cf1053345dab667973bf5a1011c487`. One VM bundle install completed successfully in39seconds,19:15:54–19:16:33UTC. Existing VM/Forgejo preserved.
- Native workspace creation returns `result.workspace.workspace_id`; overseer expected the flat pane-current shape. Correcting the fake to native shape produced12failures+1error. Fix parses the workspace object; project start had previously received nil.
- Lab fixture stored eyes in `.ace/overseer`, while delegation reads `.ace-local/overseer/eyes.json`; vague startup prompt made GLM search for configuration. Move fixture to canonical path and name it explicitly. Stop only the unproductive turn with Escape; preserve pane `w2:p2`. Native Herdr and GLM started successfully; autonomy NOT accepted. Last visible usage approximately9.6k input,1.9k output,20k cache-read; account quota not measured.
- Independent reviewer caught root ownership of newly copied fixture `.ace-local`; converge ownership with other fixture directories.
- Operator provisioning initially used `bundle exec ruby` without Ruby on SSH PATH; exited before changes. Use configured absolute Ruby executable. No reinstall needed.

## Local candidate continuation

- Lab eyes armed, healthy6required sources; first turn completed. Goal delivered once. Manager8ya.t.tcy and3direct children created; executable task8ya.t.tdu, assignment8yatf4, worktree/lab/ace/.ace-wt/ace-t.tdu.
- Nadzorca initially created an executable task in the private tree, cancelled it and corrected its location autonomously. Preserve cancelled record8ya.t.tdc as evidence.
- Worker w2:p4 started without model credentials. Session evidence: coordinator invoked nonexistent `ace-bundle read`, then read stale bootstrap instructions directly from /lab/ace checkout and used raw ace-herdr dispatch rather than current handoff. Stopped that worker and unused shell w2:p3; preserved assignment/worktree. No model work completed by worker.
- Fix: supported exact bundle invocation plus explicit refusal of checkout instructions in installed lab guide. Local candidate0.30.2.pre.1, source8ee0138267f33abf589c3acb3dd151bc5180dfa1, gem SHA2567a40c7c7871f82d8c81436bce18934ec2888ffa606f8fb2b4fff2bb43d054c88. Built/installed via local vendor/cache and one bundle install --local; no publication. Guide-only change; package build succeeded. Existing coordinator notified of updated installed guide and preserved commission. Result of resumed handoff pending.

- Correct handoff started worker w2:p5 with GLM and assignment8yatf4. Worker prepared both canonical configuration files and completed its assignment; eyes woke the coordinator. Coordinator stayed idle during execution.
- New integration defect: lab observation enumerated configured project reports, but process-reports enumerated only lab Git worktrees. Worker result was visible yet could not be accepted/retired. Fix reuses existing ProjectObservations; completion and handoff run in project context, private tasks remain lab-owned. No copied reports or new state owner.
- Review caught cross-project error reports bypassing success-only binding and WorktreeManager constructor not anchoring actual Git lookup. Fixed matching for every outcome; actual lookup runs in project cwd. Real two-repository regression added. Full intermediate suite572tests/2671assertions pass1skip; final changed tests32/212 and atoms77/275 pass. Independent reviewer approved final delta. Local candidate0.30.2.pre.2; live result pending. Coordinator interrupted with Escape, completed worker retained; no reset or duplicate assignment.

- pre.2 live result: process-reports accepted existing reports, retired worker and started independent verifierw2:p6. Verifier completed assignment8yatf41 with report8yau1u; lab eyes woke coordinator, verifier retired. Duplicate-report continuation preserved completed work.
- Confirm-start exposed constant native agent name ace-overseer collision between lab and project on one server. Root cause: test fake accepted duplicate names that native rejects. Fix namespaces name with canonical-root SHA256 prefix; existing session reuse still based on its owning pane. Regression fake now rejects duplicates; startup61tests/343assertions pass1skip. Local candidate0.30.2.pre.3, live recheck pending. No config/preparation/verifier repeat required.

- pre.3 live result: project coordinator started in w3:p3 with unique native name ace-overseer-74c3a6d409e9; first turn and six eyes sources healthy. Bootstrap manager8ya.t.tcy and its three direct children completed by coordinator after worker8yatf4 and verifier8yatf41 reports.
- Project issue1 initially stalled on anonymous Forgejo requests and unnecessary lease discovery despite prepared static role credentials. Packaged start guide now directs configured fj client/role environment first; temporary leases only when deployment explicitly requires them. Candidate0.30.2.pre.4 source0bbcca0e491bd6ac579f08e5e177f516d25ab9b7, SHA2566d8c504efd87852256907ab69beb2e3507f46c88b85da5d0c3f148e4ba170533. Installed locally, same session resumed; agent created executable8ya.t.ucr, coordination8ya.t.uea and worker assignment8yaudt in w3:p4.
- Worker issue1 commit e8d8b95ee32d2f426d0803a8589b745484b0edcf: required direct counter test reports5tests/8assertions; broader direct fast suite117tests/354assertions,19skips. These are worker-reported evidence, pending independent review and integration. Broader subprocess test failed with `bundler: command not found: ruby`; worker reproduced on untouched ace-support-core. Host inspection finds CommandBuilder defaults to PATH-resolved ruby and bundle while test environment removes bundle/gem variables. Precise root cause and repair remain open; do not count failed subprocess run as passing.

- Reviewer8yaudt1 started independently after worker retirement. Context loading `ace-bundle project` invokes agent compression per tracked project preset; first120second command timed out, retry exceeded175seconds before host stopped the turn at five minutes without review progress. Host instructed same reviewer to use existing exact compressor for context only and resume its existing review. This is an operator-assisted recovery, not autonomous recovery evidence. No VM/task/PR reset, no implementation review performed by host. Need deterministic context preparation policy to avoid repeating this cost in later roles.

- Review scope conflict: full PR review flagged inherited bootstrap task files as unrelated; reviewer removed them in9353f5f52ab06aa18616787ea2cd55e8018d8b43. Delta review flagged deletion of active task state. Reviewer initially treated that as invalid because origin/main lacks files. Host read-only check established canonical /lab/ace main0aa64b9 already contains those files through6379a19/1c5f327 and is ancestor of deletion: subsequent fast-forward can remove canonical records. Host sent this factual preservation risk to reviewer before approval. Resolution pending; this is a second operator-assisted review intervention, not unassisted autonomy.

- Durable correction for context latency: all four coworker role guides now select existing `ace-bundle project --compressor-mode exact`; explicit commissioned agent compression remains available. Independent review approved command and precedence, package build passed (guide-only, no new code tests). Local candidate ace-coworker0.9.1.pre.1 sourcee7edf85a9, gemSHA256ab61f99df954ff0775742cf956855e179a1b99d93565b87de24211cdb91afbb2. Copied to existing VM cache with checksum assertion; one bundle install --local succeeded; deployment manifest updated. Existing Pi reviewer retained, next roles will load updated package.

- Live update race: reviewer CLI ran after Gemfile pin changed but before local bundle finished, reporting missing new coworker version. Installation completed, mo CLI version confirmed, operator notified same reviewer to recheck state and retry. Future hot updates should avoid invoking CLI during the short pin/install window; no scenario reset required.
- Reviewer recovery exposed exact-step targeting friction: ace-assign start/finish reject positional STEP together with explicit --assignment, despite executor supporting exact step. Reviewer removed STEP following error guidance and completed active review010 instead of fix011. Existing public retry used to recover; product CLI guard simplification and cross-assignment/multiple-active regression pending.

- Exact assignment step targeting fixed in ace-assign0.73.3.pre.1, sourcea0408f275c110b7f9d8c9b50403fbcb78e993754, gemSHA256a6fb84694c7bdd4ddda9e80d59e572beb1497bb1b99bdefef8dbfa91a151bfd4. Removed only CLI prohibitions; executor keeps identity/scope/state validation. Two regression cases failed before fix, passed after; final22tests117assertions cover multiple active steps, two assignments and scope rejection. Full suite428tests has1failure1error (source_skill expectation and release binding) reproduced identically with original CLI; isolated executor58tests437assertions pass. Independent review approved.
- Local deployment used alternate Gemfile for one bundle install --local before pin switch. Bundler regenerated34 runtime binstubs pointing to Gemfile.next; moving that file broke CLI. Host corrected generated (untracked runtime, not project) binstubs to canonical Gemfile; mo ace-assign --version confirms0.73.3.pre.1. This attempted race avoidance needs binstub-path handling; do not describe it as atomic or failure-free. No VM reset, no task state rewritten. Reviewer notified exact target support is available.

- Issue1 review completed: final PR HEAD20fe7b91f7eae4748069edc7e1d4dc74b4b44a5e restores bootstrap records. Reviewer8yaudt1 recorded3full rounds, verdictaccept; Forgejo API independently confirms review1 APPROVED by e2e-reviewer for that exact SHA. Project coordinator accepted report and launched integrator8yaudt2 pane w3:p6 terminalterm_660068fc3f633d, retiring reviewer. No host merge or implementation.
- Live evidence for new coworker guide: integrator automatically selected `ace-bundle project --compressor-mode exact`, completed context load in16.5seconds (62KB/409lines), with no operator reminder. Compare reviewer's prior120second timeout plus175second retry with model compression. Current integration gate/merge still pending.

- First live delivery merged: Forgejo API confirms PR5 closed/merged, head20fe7b91f7eae4748069edc7e1d4dc74b4b44a5e, merge/main051f957972d6b6c3fd77562326a85682255811ef; issue1closed,2/3/4open. Local read-only git ancestry check passes and counter+test diff reviewed-head..origin/main is empty. Integrator8yaudt2 completed, report8yavr8; coordinator adopted report, retired integrator and closed leg8ya.t.uea.3, then started task/archive closeout through ace-task.
- Next high-level goal delivered to existing coordinatorw3:p3: complete issues2CLI and3docs through own dependency planning/delegation/tests/review/merge; preserve prior work; release4 remainsopen/no publication. Host did not supply implementation steps or perform merges. Remaining acceptance: both deliveries, report replay/restart/interruption, five-minute idle, final evidence audit.

- Next delivery preparation: taskCLI8ya.t.vu0, docs8ya.t.vu8, private managers8ya.t.vv0/8ya.t.vv3. CLI assignments8yavwb/8yavwb1/8yavwb2; docs8yavwq/8yavwq1/8yavwq2. Docs explicitly gated afterCLI by coordinator. Both worktrees created before dependency synchronization; CLI worktree HEAD63642f1 lacks counter.rb even though Forgejo main has it (canonical localmain stale). Do not claim dependency readiness yet; observe worker handling or fix owning preparation path if needed.
- New launch defect: handoff forCLI creates real workerw3:p7 term_66006b88a50ade but errors native executor session identity unavailable. Later native agent get confirms session /tmp/ace-session-20261111-48055-yqh1tf/sessions/--lab-ace-.ace-wt-ace-t.vu0--/2026-11-11T21-17-25-649Z_01a1cc79-0505-712a-b91e-776ad0a562b6.jsonl, idle interactive-ready. CoworkerLauncher checks pane session immediately after dispatcher; session metadata arrives asynchronously. It saves launching before dispatch, but only saves returned pane/terminal after session_identity succeeds, losing recoverable launch receipt on error.
- Host notified coordinatorw3:p3 to preserve exact worker/assignment and refrain from manual resend/new start while product recovery fixed; keep eyes armed. Proposed owner fix: persist native dispatch receipt before awaiting session identity; bounded readiness observation; safely resume unprompted recorded launch without duplicate process or prompt. Current historical launching record has only expected unique agent+assignment+role+credential directory: recovery must match native name/cwd/session directory and idle/interactive state, never blindly relaunch. Prompting uncertainty must still refuse automatic repeat. Tests existing ace-overseer/test/fast/molecules/coworker_launcher_test.rb cover duplicate start/prompt and retirement; extend delayed identity/retry/scope mismatch. No code edits yet.

### Delayed native worker identity: local candidate and continuation (2026-11-11)

- Symptom: handoff created CLI worker 8yavwb / w3:p7, then failed because Pi session identity was not published yet; original record lost the native receipt.
- Fix: persist receipt before bounded identity observation; recover only the same idle native executor with matching cwd, terminal and private session provenance. Uncertain prompt delivery still cannot be automatically replayed.
- Source: fb5666331b9732edf28e6d35cfc24016619e251e; ace-overseer 0.30.2.pre.5; SHA-256 8546219daafdae709dee76c42a01d0fbd28f5d33ee8270b69f43ac7d120ee29b. Built locally, copied to existing VM vendor/cache, one bundle install --local, ordinary mo CLI confirms version. No RubyGems publication or reset.
- Validation: launcher 16 tests / 92 assertions pass (020bdee4-9b8b-4958-850b-1f4717b7d693), independent reviewer approved after tightening provenance. Broader tests are not all green: four failures/errors in lab_start/start_command/event_observation reproduce with original launcher (5846e4ef-9641-49c0-a656-3ff0946a8bdc); macOS eyes process-birth test also reproduced before change. These remain known validation limitations.
- Existing coordinator w3:p3 notified to resume same handoff, not create another worker; live outcome pending.
- Separate coordination incident: docs dependency removed but commission still told worker to wait for CLI. Worker entered minute-long shell polling. Operator interrupted only that turn and asked coordinator to reconcile its own commission. Coordinator resumed same w3:p8 with corrected brief, preserving assignment. This is operator-assisted evidence, not unassisted autonomy.
- GLM quota/cost for this interval: not independently measured.

- Live recovery confirmed: coordinator invoked public handoff, same CLI assignment8yavwb/pane w3:p7 began worker brief/context; no replacement process. Coordinator cleared hold and ended turn with eyes pending0.
- Docs worker8yavwq/w3:p8 then observed provider retry exhaustion (three Request timed out), native status done but no proven assignment completion. Host notified coordinator to inspect owners and resume same executor; no direct worker implementation or synthetic success.

### Worker provider failure invisible to standing observation

- Live symptom: docs assignment8yavwq remained running at020, no final report, native workerw3:p8 remained present with done/completion_seq151 after three provider timeouts. Coordinator resumed the same executor after operator notification and owner-state inspection. No false completion was accepted.
- Root cause: LocalSources executor projection included only terminal/name; a completed turn without a report or panel disappearance did not revise any event.
- Product fix: include native completion_seq in the existing executor event. Unchanged sequence stays quiet; working/idle transitions stay excluded. A completion signals inspection, never assignment success. No new store or polling model turns.
- Test: local_sources regression failed before change (8d4d8784-ef1c-427d-8cb8-b109fbe55592); combined local_sources/launcher25tests141assertions pass (1def507e-8451-4f0b-9959-65820a1084f9). Review/deployment pending.

- Observation fix independently APPROVED, deployed as ace-overseer0.30.2.pre.6 from047d257a4099920c197b8c15d1d610e482dc18c8; gemSHA2565573d3399c4bb45df593b48f9eb45f796c906b464abbc89ea8701ccd555407b7. Local gemcopy+onebundle install successful, no reset. Existing observe subprocesses load candidate on next invocation; no model session restart needed. Docs worker resumed by coordinator after owner inspection; CLI worker autonomously synchronizes missing integrated counter prerequisite before implementation. Completion/liveness acceptance remains pending.

- Live native-contract correction: agent list exposes completion_seq only in done, omits it while working. Thus completion AND resumption each revise once; repeated working/done observations remain silent. Initial test assumed sequence persisted through working, so corrected fixture to the real response and clarified comment (9tests50assertions pass,87f9338a-23dc-495e-b1e3-dab3878acbb1). No runtime behavior change or reinstall required. Live inventory now shows CLI worker done/completion169 and docs working/no sequence; coordinator eyes pending2 and working. Final assignment results still require owner checks.

### Live completion-event recovery verified

After pre.6 installation, CLI worker8yavwb/w3:p7 ended with provider retry exhaustion after deterministic CLI tests (5tests20assertions, report e86c43ba-5488-493e-a07c-8cf27271601f). Native completion_seq169 was visible while the panel remained alive. Without another host prompt, project coordinator woke, inspected actual assignment/worktree state, found uncommitted CLI implementation/test files, and prompted the SAME terminalterm_66006b88a50ade to continue without redoing work. It recorded resume=continuation-prompt-1 in private leg8ya.t.vv0.1. This verifies failure observation and recovery dispatch; final assignment/review/merge still pending.

Forgejo read-only API confirms docs PR6 OPEN at4cf02503559edae9e09c1793347d432a16d0a1af; PR5 remains merged/main051f957972d6b6c3fd77562326a85682255811ef. Issues2/3/4 remain open. No host-authored fixture implementation or merge.

### Review handoff and recurrent provider timeouts

Docs report8yawlk adopted into8ya.t.vv3.1; reviewer8yavwq1 started inw3:p9 terminalterm_6600723896d1f10. It received its brief but exhausted provider retries before any model output. CLIworker8yavwb also timed out after creating PR7 and before final report. Coordinator ended turn with healthy eyes/pending0 despite these incomplete legs; host notified it of both specific errors and required owner-state inspection/same-session continuation. This is another operator intervention, not unassisted completion. The completion signal is now available, but handling it correctly still needs validation.

Read-only Pi usage snapshot (not provider weekly quota, not whole-run totals): project coordinator215assistant messages, input196307/output70292/cacheRead20050304/total20316903,13error messages; CLIworker59messages,input54545/output16526/cacheRead1816000/total1887071,8errors; docsworker77messages,input69174/output29942/cacheRead3054272/total3153388,8errors. Counters come from session usage records; error entries report zero usage and do not prove zero provider billing.

Continuation: CLI report8yawta adopted into8ya.t.vv0.1; worker retired and reviewer8yavwb1 now nativew3:pA terminalterm_660073c3535f811, session/tmp/ace-session-20261111-60124-3banho/sessions/--lab-ace-.ace-wt-ace-t.vu0--/2026-11-11T21-54-14-392Z_01a1cc9a-b8b3-777f-be9c-12356b32fbae.jsonl, working. Docs reviewer8yavwq1w3:p9 progressed through context then timed out again, nativecompletion203; coordinator currently processing revisions (no new host prompt). Workersw3:p7/w3:p8 no longer in native inventory after accepted reports.
Provider diagnosis: unauthenticated GET https://api.z.ai/api/coding/paas/v4/models returned401 in0.550s (DNS0.0095,TCP0.142,TLS0.289); proves reachability only, not inference health. Pi source defaultHTTPidle300000ms; inspected settings had no retry timeout override. Root cause of recurrent Request timed out remains unknown; no speculative timeout change.

### Startup-vs-continuation guide contradiction repaired

Observed coordinator still described docs reviewer as working after actual provider failure/completion203. Existing guide prohibited prompting a session that began work, but only described startup recovery. Updated start guide distinguishes original-commission replay from continuation after proven provider error; requires fresh native/assignment/report inspection before ack, same terminal, preserve progress, existing eyes provider-recovery deadline300000ms, no rearming on repeated failures, escalate no progress. Independent reviewer caught initially missing deadline; fixed and APPROVED. Contract tests19/119 pass (8da163d8-aa95-4c9d-99b7-50e083421fbd).

Candidate ace-overseer0.30.2.pre.7 sourceb1c7c2a58e5aa65b135f85f49fdbd3bcb67c0219; gemSHA256b6ef2dc181ca603ce4e1841a2c50871f44ea8734751b9290d01f73ed7defb7c5. Copied and installed with one local bundle invocation; mo version confirmed. Same coordinatorw3:p3 instructed to load new packaged guide and continue existing goal. No reset/replacement. ReviewerCLIw3:pA had reconciled PRHEAD with local/tested5820ab5 and started required tests; verdict/merge pending.

Pre7 live outcome: coordinator read packaged guide, reconciled docs reviewer completion203 against unfinished assignment, resumed same terminal and armed existing provider-recovery deadline; no replacement. Docs reviewer now verified README examples against primitive and began formal PR6 review. CLIreviewer8yavwb1w3:pA reran required checks (primitive5/8 andCLI5/20 pass), completed first full review sessionreview-8yawy3 and is triaging findings; no approval/merge claimed. First draftsessionreview-8yawx2 also exists. Both current review processes demonstrated forward progress; provider failure is intermittent, not a verified hard blocker.

### Recurrent stream failures after completed review output

Both review outputs were produced: CLIround2review-8yax32 (6087bytes at22:05:55Z), docsround1review-8yax24 (7280bytes at22:05:59Z). CLIreviewer was verifying test findings; docsreviewer loading feedback. Both parent Pi turns and then coordinator ended with repeated Request timed out. Existing reports/process outcomes preserved.

Diagnostics: both API IPv4 endpoints47.245.163.4 and47.245.170.100 returned401 overTLS in0.407/0.355s; current reviewer settings contain no timeout/retry overrides or proxy env. One authorized minimal streaming glm-5.3-flash request (max_tokens16) returned200 and first203-byte stream line after1.25s. This proves inference availability at that instant, not long-stream health or remaining account quota. No speculative timeout change. Host prompted same coordinatorw3:p3 to continue pending eyes/owner-state, preserving completed review rounds. Root cause of intermittent failures remains unknown.

Continuation checkpoint: host clarified actual report paths after coordinator looked only for an assignment-level REVIEW_REPORT and incorrectly inferred no review work existed. Coordinator recorded preserved_rounds in existing private legs and resumed SAME reviewers; native identities unchanged (CLIterm_660073c3535f811/w3:pA, docsterm_6600723896d1f10/w3:p9). Session logs22:18Z prove CLIreviewer adding confirmed-fix steps to existing assignment and docsreviewer verifying disputed forge-state claims. CLIreviewer edited its CLI test (+3/-1) and invoked path-scoped ace-git-commit. No host fixture edits, verdicts or merge. This report-location clarification remains operator-assisted.

Review fixes committed: CLI candidate now099ad61894751ec8424088b0d02291d7cc7248d5 (reviewer amended author after2357c77; records must use finalSHA), full review executing with verified PR inventory and newHEAD. Docsreviewer committedc7c3718a058664f6638cef2f05aa632b65ed963d (drop copied foreignvu0spec) and45bb9a55ae97f7b74b1c7e743756e69bc6a1e80d (exactArgumentError example), pushing only after verifying priorremoteHEAD4cf0250 and ancestry. Final tests/verdicts/merge not yet established. Final audit must verify both integrated task records and fixture files, because removing cross-task copies changes merge topology; no host implementation.

### False stalled-session HITL corrected

Coordinator created HITL8yaxlo asking to restart docs reviewer because working/state_change_seq235 was unchanged and assignment unfinished. Live evidence contradicted it: reviewer committedc7c3718/45bb9a5, pushed PR6HEAD, and ran round2. Host supplied facts via coordinator prompt, NOT a fabricated human reply, and requested lifecycle reconciliation/no restart. This does not count as successful human-answer acceptance.

Product guide now explains transition counters versus progress and requires changed/new owner artifacts relative to recorded recovery baseline; partial review sessions/feedback/commits/PRHEAD count, historical artifacts alone do not cancel deadlines. Independent review found missing baseline qualifier; fixed and APPROVED. Tests19/119pass report02fdef87-ab21-45a0-9cdb-6d0487bbce5d. Candidateace-overseer0.30.2.pre.8 source5b9131e969f8c24b791171d33b8589b2965d6638, gemSHA25610616f440e9ab86bbeadcf72f6f510d7fb60f64ae27b66a30d60cd991c45d996; deployed via singlelocalbundle, mo versionconfirmed; same coordinator told to load packagedguide. CLIround3reportreview-8yaxkc finished; docsround2 still running. No reset.

### Local HITL cancellation CLI gap fixed

Canonical HitlManager.cancel_case existed and was tested, but ace-hitl cancel exposed only relay requests; coordinator could not withdraw false local question8yaxlo without inventing an answer. Added explicit existing-command flag --case (no owner guessing/fallback), required audited --reason, stored under atomic application transition. Duplicates preserve original record and applied cases refuse cancellation. Regression failedbefore1aeeb3e1-0837-4d77-8781-fd24aa28eb78; focused12/69pass; fullhitl410tests2116assertions0failures0errors5skips report4f93f0d5-4734-4d17-957f-4892dd496143. Independent review APPROVED.

ace-hitl0.25.2.pre.1 source19f6fc7801dcdd9b58895abe57dd2dd4f3229655; gemSHA2562f1be53e2c6cbed3dd0fd8df20521938d6696dd377df0c81b594b4c80fa742ce. Copied, one bundleinstalllocal, manifestpinupdated, installedCLIhelp confirms --case. Coordinator notified to cancel only after checking actual evidence; outcome pending. No human reply forged, no reset.

Forgejo API independently confirms PR7OPEN HEAD099ad61894751ec8424088b0d02291d7cc7248d5, review2APPROVED by e2e-reviewer for samecommit. Reviewerassignment8yavwb1 completed4/4, report8yaxte delivered. Merge not yet confirmed. Docsreviewer thirdround active.

Live local cancellation proved:8yaxlo.application.state=cancelled at2026-11-11T22:36:18Z with auditedreason, no fabricated answer. Coordinator reason says no operator intervention was needed; interpret narrowly as no session restart: host DID diagnose, patch/deployCLI and provide evidence, so run remains operator-assisted.

CLIreviewer retired; public handoff started integrator8yavwb2w3:pB terminalterm_66007d4900e8512, session/tmp/ace-session-20261111-77345-d59kk2/sessions/--lab-ace-.ace-wt-ace-t.vu0--/2026-11-11T22-36-51-186Z_01a1ccc1-bc6e-73d6-9937-55f0f441481c.jsonl. Initial handoff encountered BundlerGemNotFound during host's Gemfile-pin/localinstall window; after install completed coordinator retried successfully. No assignment duplicate or loss. This is a known live-update procedure limitation, not evidence of atomic rollout. Docsreviewer completed reviewrounds and is publishingapproval; no docsapproval/merge yet verified.

Forgejo gate checkpoint: PR6OPEN finalHEAD6fd2fd44cb5c88b1e2c439e873a502f8b0e3a5b4 has review3APPROVED by e2e-reviewer for identicalcommit; docsreviewer assignment8yavwq1 allstepscomplete after publish-approval. PR7OPEN HEAD099ad61894751ec8424088b0d02291d7cc7248d5 retains review2APPROVED samecommit. API independently read both. CLIintegrator8yavwb2w3:pB is reading review/test evidence, coordinator processing reports (prior invocationtimedout, bounded retryactive). No merge claimed.

### CLI integrated on main (independently verified)

Forgejo API confirms PR7closed/merged, merge/mainf0854378a94eb4405e357b1e9bba1fd6814cecc3, parents051f957972d6b6c3fd77562326a85682255811ef (already integrated primitive) and099ad61894751ec8424088b0d02291d7cc7248d5 (approved CLI candidate). Contents API blobSHAs for counter_cli.rb andlab_fixture_counter_cli_test.rb exactly match reviewedcandidate gitblobs. Integrator8yavwb2 completed1/1 and publishingreport; coordinator adoption still pending. No host merge.

Host plain SSH gitfetch could not authenticate (no roleenv), so verification used existing project-scoped read token in memory viaAPI, not global credentials or manual source. No need to alter runtime/permissions. PR6stillopen at lastcheck; next acceptance remains docsmerge, reportreplay/restart and5minidle, releaseopen.


### Docs integrated, report replay and restart probe

- Forgejo API independently confirms PR6 merged at `6aa71d99606b9184cb88202faa6242f32d341a40`; main equals that SHA. Issues 1–3 closed, release issue4 open. Coordinator adopted reports `8yay2p`/`8yay5w`, completed private legs and retired executors.
- Repeating `ace-coworker report` with original integrator config and installed mode returned the same event `8yay5w`; no new executor observed before restart.
- Operator ended project session with `/quit`, then mistakenly used bare `start` over noninteractive SSH and again in old pane while lab reconciliation independently restored the managed project session. This produced a temporary duplicate. Source confirms bare start intentionally uses foreground bootstrap and does not discover/reuse managed sessions; this is not yet evidence of a race inside managed reconciliation. CLI description still promises reuse without explaining that distinction.
- Manual pane stopped; managed replacement `w3:pD` / `term_6600809441ad314` remains, with first-turn eyes healthy and owner reconciliation in progress. No VM/data reset. Restart/no-duplicate acceptance is not yet passed.
- Lesson: when testing automatic recovery, stop only the chosen session and observe the lab owner. Do not add a second manual bootstrap. Clarify public command help before repeating this probe.


### Retained dead panel broke observation after restart — repaired

Live `observe` remained degraded because ProjectSessions counted retained tabs, while managed StartOrchestrator already selected the unique live native agent. This is an observer bug separate from the operator-induced foreground duplicate. Added native presence checks for multiple candidates; only AgentNotFound excludes an owner, errors and zero/multiple live candidates remain unavailable.

Regression failed before: bedeaf9a-62b5-461c-af48-48c7a8478acc. After:10tests32assertionspass da2ab3c0-7ffa-43f1-9d03-482aa00fd89a; related start/local sources47tests238assertions0failures0errors1skip 4d0fffd9-9854-4228-bba0-3ddd587902e4. Independent reviewer approved. Source822b69ee60ff8e2f25b1fd06fdad59bf722f9260; ace-overseer0.30.2.pre.9 SHA256bdd75f87d523b4043863d0d832519fb30e3a30334d434dce6a75caceef9754c0. Copied local gem, one bundleinstalllocal completed, manifest pin updated, mo version confirmed. Live public observe now reports project pane w3:pD and ALL source statuses ok without deleting predecessor panels or resetting data.

Project replacement reconciled12 duplicate reports, dispatched nobody, archived completed bootstrap task and committed existing records/configuration. Lab question8yaycc appears statusanswered despite instruction to cancel; canonical lifecycle must be inspected, do not claim a human answer or clean HITL acceptance. Remaining: settled live eyes, clean automatic restart probe if needed, five-minute idle measurement, final audit/report.


### Worker process fault injection

To close the distinct process-interruption check, project coordinator received a high-level verification-only goal for existing integrated main (no product edits/PR/merge/release). It created task8ya.t.yyf, private manager8ya.t.yyg, worktreeace-t.yyf and assignment8yaz1k, then dispatched native coworker8yaz1k pane w3:pF terminalterm_660087b3f371d16. Preparation took about9minutes with repeated CLI discovery and worktree preparation; default worker preset still includes publish-pr, a mismatch for report-only verification to track.

At23:24:28.360UTC operator sent SIGTERM only to Pi PID94521 after verifying /proc cwd=/lab/ace/.ace-wt/ace-t.yyf and comm=pi against native process-info. Native agent list then no longer contains that worker. Assignment was paused0/3 before signal; no completed steps or success report existed. Preserve assignment/panel/session/tmp/ace-session-20261111-94385-7jhyn4/sessions/--lab-ace-.ace-wt-ace-t.yyf--/2026-11-11T23-23-25-330Z_01a1ccec-5f0d-7472-9d0f-760cc1dca26b.jsonl. Await coordinator observation/recovery; do not manually mark success or create another commission.

Post-signal public ace-assign status:running,active010work-on-task,0/3done. Worker had started010 between pre-signal snapshot and termination. Project eyes autonomously woke coordinatorstate324 on missing executor + running assignment; recovery decision pending, no false completion.


### Failed native resume argument routing (local repair, acceptance pending)

ace-overseer0.30.2.pre.10 was installed from source9c3ec4e57fe76b544eb5b37891e65b76227733d9, gem SHA256 faae1debe32d8bede0b3212b660a73314ae98819e5d2ebaf0dabcc35877bab04. Same assignment8yaz1k recovery reached native exec-env, but global Herdr option parsing consumed Pi's --session transcript path and rejected it as a Herdr session name longer than64bytes. No Pi replacement started; binding remained resuming and original shell94487/terminalterm_660087b3f371d16 remained. No false completion.

Fix owner: native main dispatches internal exec-env before global session/remote/help parsing, preserving child argv. Regression failed before with the exact error (nextest5f43ca36-904a-4666-af26-78aeef581e65), then12 environment tests passed317e5a75-8c26-4a58-8780-124234b4188d;158 session tests passed384742f7-be09-4052-b437-b533b99790ac. Selected native source5176d899a567985490682c37eb7f0198eab159b0.

A separate orchestration gap stranded a conclusively failed resuming attempt. pre11 allows retry only after native AgentNotFound plus same pane/terminal/cwd and authoritative guarded original shell as the sole foreground process. Missing/uncertain evidence and resume_prompting remain blocked. Regression failedbefore6fecf278-bda6-4ace-a344-b38a87773bc7; focused23/144pass2310f24d-feca-4f2b-9b66-7ee46be35d0e; related60/342pass6c1a92cb-16a2-41d7-9e10-9999838cea12. Independent reviewer approved both patches. Native ARM64 build ongoing; live resumption not yet credited.

Lesson: ordinary process environment tests must include real child CLI arguments, especially overlapping --session/--help flags. A timeout alone cannot justify restarting, but positive process-owner evidence must permit continuation without editing binding state manually.


### Local candidate deployment completed

Source301b55c613b552a4a77ad5c1b9b43e9d89c32d1f (code commits eb3c9f40a/ff9c1acb0): ace-overseer0.30.2.pre.11 gemSHA256c245aaac9b672b908241d7629484f5362f95231b0fc9fdf9d36ef478375f9771; ace-herdr0.11.1.pre.1 gemSHA2568ba7632f424694508b8ecf800a1fab8dfb1d086da40771f3ffc8cc5dd2238ffa. Native ARM64 source5176d899a567985490682c37eb7f0198eab159b0, binarySHA25602030a0b8fb3598a444b6af97d4b81b5b83336cf192eb4b9992029cf9f23aeb9, provenanceSHA256b3dfcf851d2372c55ba0b40f7acf48876e25bb995576ac672744ab47049c8518. Public native-source build replayed selected patch and verified artifact. Native source builder9/68passed; selection fixture pin updated after intended source change,13/42passed79c42b61-12e5-4555-a800-b70af1770a69.

VM native replaced with prior bytes retained under/var/tmp/ace-herdr-before-child-options. Public native server live-handoff succeeded, preserving lab/project sessions and original worker terminal. This handoff is necessary because a running Linux executable replaced on disk otherwise retains its old executable identity. Native ARM64 exec-env smoke passed for child --session/--remote/--help. Two local gems copied to vendor/cache and installed in one bundle install --local; manifest updated, ordinary mo CLI confirms pre11. No reset, new Forgejo data or publication. Coordinatorw3:pE notified to continue same8yaz1k and reconcile obsolete blocker, not fabricate HITL answer.


### Live native handoff does not preserve terminal identity

Correction to previous deployment wording: native handoff preserved running shell/Pi processes and session UUIDs, but regenerated terminal IDs and discarded guarded-origin metadata. Worker pane w3:pF changed fromterm_660087b3f371d16 toterm_66008dd8105536; shellPID94487 remained. Project changed fromterm_66008305f54d115 toterm_66008dd80e93e5 while keeping Pi88245/session01a1ccd9. pre11 correctly refused old terminal adoption. This was not a VM reset or assignment loss, but claiming preserved terminal identity was incorrect.

Native owner inspected: persist/restore.rs allocates new TerminalId; HandoffRuntimeState does not transfer terminalid/guard. Future handoff identity-retention is separate work and cannot reconstruct already-lost evidence. Minimal current recovery in pre12 resumes the verified Pi transcript and same assignment in a fresh pane after positive shell-only old-pane evidence and healthy inventory proving oldname/session absent. It never inputs to or closes the replaced old terminal. Existing binding records previous_terminal and uncertain replacement intent; lost receipt reconciles exact live session before any continuation. Unknown inventory kinds are blockers. Native global parser fix remains deployed and ARM64 smoke passed. No manual binding edits or fabricated success.


pre12 deployed via one local bundle install --local, manifest updated. Code c4ce37d05, lock9d37df7d1, record9d88c0d51; gemSHA256459cdd783dd8a8b3cc0b933cd0a41303d47c2265170c354af188c40c36b9d8c4. Related63tests379assertions0failures0errors report6704f8fc-8559-4c77-a10a-7628c7050864; reviewer approved after tightening incomplete native inventory handling. Same project coordinator w3:pE resumed existing task8ya.t.yyf/assignment8yaz1k via public work-on. Native server remains5176d899, no further handoff/reset.


Live recovery verified: public work-on resumed SAME assignment8yaz1k and Pi UUID01a1ccec-5f0d-7472-9d0f-760cc1dca26b with original transcript in NEW panew3:pG/terminalterm_66008f7634fd07. Binding state running; previous_terminal explicitly retainsw3:pF/term_660087b3f371d16. New private credentials directory/tmp/ace-session-20261111-104350-vr52zs. Native agent inventory shows exactly one coworker for that session, actively reading verification fixture. Coordinator records recovered-pre12 in private leg. Old pane untouched; no new assignment. Final verification report still pending.


### Final recovered-worker closeout

Same assignment8yaz1k completed3/3, event8yb04e published00:04:58UTC; coordinator privateleg8ya.t.yyg.0 records processed_report8yb04e,success,done; manager8ya.t.yygdone. Binding retired; native worker process gone and fresh auth.jsonabsent confirmed. Verification receipt020 records actual remote main6aa71d99606b9184cb88202faa6242f32d341a40, primitive5/8PASS,CLI5/22PASS,README behavior andrelease4open; host API independently reconfirmedmain/issues.

Report sweep exceeded initial60s coordinator timeout; retry150s completed without lost report. Performance rootcause unknown; pipedoutput hid progress. Two reviewer/integrator preparations8yazfc/8yazfc1 came from defaultthree-rolecomposition at23:37:04; neitherexecuted, retained as unusedhistoricalrecords. No duplicateworker execution, but do NOT claim zeroextraassignmentrecords. Host gave explicit closeout disposition; obsoleteHITL8yazhc canonicalapplicationcancelled00:09:05UTC,answeredfalse,no inventedreply. Coordinator idle/eyesactivepending0. Independent reviewer approved qualifiedacceptancereport. Broaderparenttaskinprogress; nativehandoffidentityretention,role/processcompliance,reportonlyrolepreparation andreportlatency remainfollowups.


Final observation snapshot at2026-11-12T00:10:18UTC: lab eyes enabled, all sources healthy/errors0/breaker null, but wakes20/20 and pending1. Project at00:10:22 has pending0,wakes2/20,healthy. The final lab silence is rate-limited and is NOT another idle pass; the earlier393.514second unthrottled measurement remains the accepted idle evidence. Rate-cap backlog is an operational follow-up; delivery/recovery ownership is complete. Do not describe both coordinators as fully settled/unthrottled at final snapshot.


## 2026-11-12 — owner relevance and handoff repair (in progress)

- Live handoff preserved processes but discarded terminal IDs and guarded origin. Repair transfers original IDs and kernel pidfds; protocol2 requires a controlled first upgrade, then new-to-new handoff verifies retention. macOS handoff tests58pass; Linux live proof pending. Review caught parent PID change after old-server exit, ownership before fallible import, and CLOEXEC on received descriptors; all included in current patch.
- Lab recursively ran full project observation under a project-local interpretation of its recipient alias. This both over-observed progress and could miss actual escalations. Replace with direct HITL owner reads filtered by the lab's resolved address; no credentials or project remote probes needed for reading these local files. Two-config regression passes.
- Default three-role sequence prepared unused review/integration for verification-only work. Require explicit roles before worktree creation; whitespace duplicates refused. Advisor now has its own existing-role sequence and exact case reaches commissioned config.
- Report processor performed repeated private tree scans and completion checks on closed history. Add stage duration/progress, one per-call private index with targeted refresh, and closed accepted-history fast path retaining cleanup recovery. No constant wait added. Tests pass; VM timing pending.
- Project availability revision included ordinary working/idle transitions. Normalize those to available and verify actual agent presence even when only one pane exists. Retained dead shell regression added.

No new GLM work or VM reset has been run in this phase. Provider usage unknown (not measured).


### 2026-11-12 — review catches integration gaps before VM deployment

- Advisor composition existed but installed launch rejected `second-captain` and
  coordinator scope. Added explicit role and scope selection, without inheriting
  worker tokens. Real-child environment tests cover both scopes. Live advisor
  delivery and human decision remain pending.
- Closed-history report shortcut trusted report ID before cleanup. A changed
  allocation could retire the wrong executor. Validate task/assignment/role/result
  against the accepted private step before any shortcut. Altered duplicate tests
  prove no retirement or continuation; incomplete continuations keep normal checks.
- Native received descriptors needed CLOEXEC before any restored shell spawns;
  origin import needed RAII before validation. Corrected both. Test must inspect
  the original incoming fd, not a clone that silently sets CLOEXEC itself.
- Recursive child observation resolved the alias `overseer` in the wrong scope
  and reread unrelated histories. Read existing local HITL owner rows directly,
  compare the lab-resolved address, and project only relevant rows. Two-project
  alias regression and progress-without-revision tests pass. Live timing pending.


### 2026-11-12 — deployment operator corrections

Candidate72ef4dd68062ed82e3db43a0961710f7043d3baa installed with one
`bundle install --local` in4.91s. No VM, Forgejo or task reset.
Installer API invocation for extension projection initially omitted the selected
`ACE_TOOLCHAIN=installed`, assigning declared account mo instead of protected
root ownership. Start correctly refused. Operator restored only projection-owned
paths/receipt to root, reran installed ExtensionProvisioner from manifest; passed.
This was operator error, not permission to relax the guard. Also corrected wrong
`/eyes off` command (refused without state change), native artifact verify directory
(extra files in /var/tmp refused; dedicated artifact directory verified), and
standalone host probe interpreter (mise outside repo chose3.4.9 against3.4.8
native gems; explicit selected3.4.8 passed). These interventions are disclosed.
Old schema1 Herdr stopped only after both Pi sessions quit. Current source
restarted via `ace-herdr start`, retaining task and transcript data; old panels
explicitly require coordinator relaunch because they lack a fresh environment.


### 2026-11-12 — foreground launch removed native terminal context

`ace-herdr start` succeeded after the deployment correction, but foreground
`ace-overseer start` produced a screen-detected Pi with no native session/ready
metadata. Cause: cleaned SessionEnvironment removed HERDR_ENV and PANE_ID,
disabling the installed Pi integration. Preserve four inherited terminal-context
keys only for the foreground launch; delegate destination context remains owned
by native Herdr. Real-child regression failed before fix (ea3d4c94-020b-43d5-bfe7-b40b98f98b86).
Stopped only the new incomplete Pi first turn via /quit; task/eyes files retained.
No autonomous completion credited. Candidate pre.2/live retest pending.


### 2026-11-12 — live worker prerequisites and deadline units

- Worker ace-test failed before any test with `bundler: command not found: ruby`.
  Fixture session_runtime.path included Node and installed CLI wrappers but
  omitted its installed Ruby interpreter directory. Corrected session-fixture.rb
  and the retained VM manifest (backup install.yml.before-ruby-path). Existing
  worker independently diagnosed the same cause and ran with the interpreter
  path;128tests387assertions passed,19skips. Future sessions receive the corrected
  configured path. No source runtime fallback or manual shell-source required.
- Coordinator supplied `at:300000` for a five-minute recovery deadline. Eyes
  correctly interpreted an epoch timestamp, making it immediately due. Tool
  schema only said integer, unlike the terminal command's EPOCH_MS help. Clarify
  absolute milliseconds and current-time-plus-duration in the tool schema.
  No new scheduler or timeout increase. New wake candidate pre.2 pending deploy.
- VM workers piped test output despite repository guidance. Owner reports remain
  available and must be checked for actual run/test status; do not accept truncated
  tails or a no-test target as successful coverage. This instruction-compliance
  limitation is disclosed rather than silently credited as perfect autonomy.


Wakepre.2 deployed from285ee3a82 (6.3s localbundle), extensions refreshed and
coordinator Pi /reload preserved sessions. A concurrently issued worker CLI saw
transient GemNotFound during bundle replacement; retry after update succeeded.
Lesson: an in-place shared-bundle change has a short maintenance interval;
report it honestly and retry the failed public operation after installation.
No queue/registry or permanent workaround added. Worker inferred Overseer ran
tests from process ancestry; actual coordinator transcript has no ace-test calls.


### 2026-11-12 — report acceptance names the missing private allocation field

Worker8ybis5 produced report8ybj75 for tested PR11. Private step8yb.t.irq.1
had assignment/terminal/agent but no role. The guide paragraph required role,
while its copyable update example omitted it. Generic completion refusal named
three fields and no owner record, causing coordinator to inspect project task
history instead. Fix: example includes role; diagnostic names the exact private
record and missing field. Acceptance predicates unchanged; no default inferred.
Focused8tests35assertions pass. Coordinator independently found and filled roles
on all six private legs before this fix was deployed; recovery attempt pending.
No host metadata edit or instruction revealing the answer was sent.


### 2026-11-12 — coordinator restart with retained dead panels

Controlled project Pi exit after both reviewers started woke lab once, correctly.
However both observe and start classified zero live agents among multiple retained
old panels as ambiguous. Reconcile blocked; lab began operational HITL escalation.
The previous fix covered one live replacement but omitted the all-dead case.
Repair zero/one/many semantics: zero live means absent and starts one fresh
session, one live is reused, multiple live remains blocked. No pane is deleted
or chosen arbitrarily. Regressions cover observation and actual start orchestration.
This is a product defect found by the restart acceptance, not a Captain decision.
First fault attempt refused to kill while project was working; the subsequent
idle-only attempt killed Pi232138. VM/workers/Forgejo remained running.


pre.4 deployed from30c41a300 (5.87s). Healthy-source revision triggered lab's
own successful fresh start, no host reconcile call. Lab fabricated a plausible
maintenance cause (operator closed panels); corrected with factual maintenance
message, not consent. No new HITL case was actually created during that ambiguity
(the agent discussed escalation only). This is a reasoning/provenance limitation.
Second reviewer hit the brief GemNotFound deployment window too, then recovered;
shared-bundle hot-update window remains a disclosed maintenance caveat.


- **Readiness transition missing after restart:** lab saw project available but
  no subsequent readiness wake. Normalizing ordinary project activity also hid
  first-turn completion. Added a session-bound readiness confirmation; rejected
  sampled boolean because concurrent transcript writes are inconclusive rather
  than an actual loss of readiness. Existing eyes acknowledgements deduplicate
  the marker; product still rechecks readiness before success. Independent PASS;
  focused regression16/56 and wake suite green; live continuation pending.

- **Local candidate staging overwrote the executable wrapper:** disabling staged
  binstubs let RubyGems replace ace-overseer with env-ruby launcher. Canonical
  bundle binstubs ace-overseer --force restored configured runtime; observations
  recovered. Candidate install5.44s, same live processes. Keep launcher projection
  in the established bundle install configuration; staging must account for it.
- **Readiness continuation proven:** d97fee245 / overseer0.31.0.pre.5 led to lab's
  own ready1/1 at13:21:21UTC; record then ack, no duplicate session.
- **Whitespace-only review delta omitted:** reviewer independently found default
  ace-git whitespace filtering hides newline-only fix delta; inspected raw diff
  and reran checks under the existing reviewer workflow. Product review material
  should preserve exact candidate changes; do not call empty material a clean
  review. Broader filtering correction not claimed in this candidate.

- **Advisor never started:** private ignored coordination task passed to work-on;
  worktree provisioning also omitted existing defer_setup:true and attempted
  project trust/setup in the coordinator. Fixed both provisioning paths, added
  early actionable ignored-task rejection, clarified executable commission vs
  private decision manager. Same case8ybk3j retained, no advisor assignment yet.
  Focused36/213pass and independentPASS; continuation pending.

- **Advisor report manually noted but not adopted:** private manager stored
  advisor_* metadata rather than existing project_task/project_root plus direct
  role/assignment allocation. process-reports correctly returned unmatched;
  coordinator's manual advisor_adopted note is insufficient. Clarified existing
  allocation and same-report cleanup recovery in packaged guides; no new CLI.
  Awaiting actual product acceptance and retirement on the preserved VM.
- **Captain local transport missing:** fixture captain is folder-form and has
  no send adapter. Same decision8ybk3j/recommendation was presented through chat
  user-input as disclosed manual delivery; no delivered status fabricated, no
  human answer supplied by operator. Release4 stays independently gated.

- **Review/coordination cost observations:** repeated exact-HEAD review rounds and
  conflicts in historical task metadata dominate elapsed delivery time, not the
  5–8second local gem update. Single-event eyes acknowledgements also require many
  model/tool turns when a batch is large; transcript cache-read usage grows during
  active reconciliation. Record as measured workflow cost; no quota increase or
  relaxed review scope was used to hide it in this run.

- **Routine step transitions woke the coordinator:** paused/running snapshots
  revised assignment and executor rows although the same native reviewer was
  alive. Normalize only the fingerprint for that exact native identity; preserve
  raw states and actionable failures/death. Independent review rejected a broad
  CWD match and default-config assumption; both corrected. First idle baseline
  invalidated, final silence must be measured again after deployment.
- **Nested review provider timeout:** documentation review returned no report
  after600seconds. Process/output inspection performed; aborted attempt was not
  counted as review evidence. Reviewer continued same candidate in a fresh
  provider attempt; no blanket environment reset or fabricated verdict.

- **Guide ordered lesson after terminal close:** the Captain's actual C answer
  was applied and case8ybk3j closed, then lesson correctly refused by existing
  HITL terminal immutability. Coordinator preserved comparison plus lesson_gap
  on its owning decision task. Cause: packaged step5 listed close before lesson.
  Fix: apply effect, record lesson if suggestion exists, then verified close;
  preserve a truthful owning-task gap for already-closed historical cases. No
  reopening, terminal mutation exception, new case, or invented human answer.

- **Stage evidence discarded by the tested agent:** later process-reports calls
  were piped to tail despite repository guidance. Product emitted stage progress,
  but the transcript retained only the tail; those acceptance/continuation splits
  are unknown, not reconstructed from wall time. Earlier complete stage evidence
  remains available (verification2.051s, acceptance0.177s, retirement0.433s,
  continuation12.099s for base review→integration). Do not rerun external effects
  merely to recreate missing measurements.

- **Private coordination families explicitly moved to public archive:** done
  managers irq/irs/k3f were no longer Git-ignored after ordinary --move-to archive.
  No auto-archive defect: ace-task already excludes ignored families from automatic
  archival; explicit relocation follows the requested destination. Packaged close
  guidance now keeps private done families in _overseer and restores misplaced
  same-ID families through ace-task. No new permission layer/state. pre.10 source
  35b72a6ffb3ea59a04ec45e0f3aab88e01d653a6,11/99 tests+independent PASS+isolated
  artifact probe. Install5.89s. Disclosed maintenance goal sent to actual project
  coordinator; host did not directly move its task records. Restoration proof pending.

  Recovery confirmed: actual coordinator moved all three same-ID private families back; Git ignores their owner location and status is clean for _overseer. Existing case remains closed with C and explicit lesson gap.

- **Worktree report omitted and new revisions acknowledged from stale memory:**
  bootstrap guide prescribed eyes scope=current; docs report8yblu5 remained in
  its linked worktree, unseen as HITL even though report-consumer scopeall could
  read it. Native completion arrived, but coordinator reused an earlier working
  interpretation and acked without fresh owner readback. Fixguide scopeall with
  recipient filter; require current revision/owner evidence before ack. pre.11
  82cef09fbe2277007b0b74b991516481ba1ff4a1,22/128 tests+independentPASS.
  Delegate same-state config repair, no report replay/review restart. Earlier
  project idle observation is not full coverage acceptance; final repeat pending.

- **Recovery allocation typo and transient readiness refusal:** coordinator
  copied iqr into the docs manager instead of iqu; matching refused correctly and
  it self-corrected.8yblu5 accepted, continuation then refused active-eyes proof.
  A same-report retry after owner readback started prepared8ybisn2; no duplicated
  review/report/executor. Exact transient-proof failure cause is unknown.

- **Small configuration verification inherits broad review ceremony:** after the
  scope fix, independent reviewer8ybmhc spent several minutes navigating generic
  review tooling for a two-key local JSON configuration. This is workflow overhead,
  not package installation time. Actual validation must still be independent, but
  future commission design should match the existing role's verification scope to
  the target and preserve explicit report-only/no-PR constraints. Do not bypass
  the current review or claim a measured total until it finishes.

- **Nested model usage differs from the visible Pi model:** coordinator and
  coworker sessions run zai/glm-5.3-flash, while code-valid review invokes
  pi:zai/glm-5.3:high. Confirmed in review8ybmmw and reviewer transcript. Pi-session
  token counters do not include all nested review provider usage; report them as
  partial usage, never total lab consumption. User dashboard aggregates must not
  be attributed wholly to this run without matching its date/account scope.

  Captain changed test policy to Flash-only. Cause was inherited development
  llm.roles, not the visible Pi launcher setting. Fixture now pins all25effective
  roles (including default-gem aliases) and disables fallback; same installed
  configuration readback confirmed on live roots. 120/552 deterministic testsPASS.
  Preserved configs backed up; no VM reset or accepted work repeated.

- **Recovery outcome:** worker8ybm6c report8ybmff and independent verifier8ybmhc
  report8ybn3i were accepted on private manager8yb.t.mgd; verifier retired and
  coordinator re-armed scopeall eyes. Final346.703seconds with five snapshots
  show no model turns/token increase, healthy advancing observations, pending0,
  wakes0/20 and1/20. All three fixture PRs merged with exact-HEAD approvals;
  release4 open; actual Captain C closed in same case. Assisted run complete,
  not unattended autonomy. Missing Captain transport, historical lesson gap and
  incomplete aggregate model-usage accounting remain explicit limitations.
