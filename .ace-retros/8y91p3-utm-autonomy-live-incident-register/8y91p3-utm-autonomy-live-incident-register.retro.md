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

Żywy rejestr dla `8y0.t.x27`. Wpisy startowe obejmują przebiegi od `utm122` z 8 listopada do aktualnego `utm128` z 10 listopada 2026, UTC. Szczegóły SHA, manifestów i sesji są w [dzienniku dowodów taska](../../.ace-tasks/8y0.t.x27-odtwarzalne-stanowisko-testowe-ace-na/docs/2026-11-05-checkout-recovery.md). Surowe sesje i obrazy zostają w prywatnych artefaktach lokalnych.

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
| UTM-12 | `8y8u9mc`: zlecenie podało `scope: project` w eyes JSON. Worker wykrył błąd i opublikował raport. Po korekcie gotowość przyszła po 48 min 50 s. | Overseer i Coworker, `3c31ef1bf`. Start używa `project`, eyes używa `current`. Worker i weryfikator sprawdzają plik zainstalowanym walidatorem. | `8y909wx` osiągnął uwierzytelnioną gotowość po 38 min 36 s. Odbiór pełnego cyklu w toku. |
| UTM-13 | `8y8u9mc`: odczyty timing helpera chwilowo blokował lock lifecycle, wyjątek ScriptingBridge `virtualMachines` lub UTM RPC. Kolejne odczyty odzyskały dostęp. | Harness. Obserwować częstotliwość i zachować wynik z właściciela. | Odzyskane w tej próbie. Brak dowodu trwałej naprawy ScriptingBridge. |
| UTM-14 | `8y8xyf4`: HTTP 503 od przypiętego Debian Snapshot przed startem fixture. | Harness, `83bf3d40b`. Do trzech prób pobrania tego samego Release, z zachowaniem SHA-256. | Test kontrolowany zielony. Ponowienie `8y909wx` przeszło pełny setup i bramkę bootstrapu na tym samym snapshocie. |
| UTM-15 | `8y909wx`: synteza `review-8y94jh` zwróciła poprawny obiekt z czterema kompletnymi uwagami i unikatowymi kluczami. Parser pomylił bloki kodu wewnątrz tekstu uwagi z opakowaniem odpowiedzi. W pierwszych ponowieniach lista uwag nadal nie powstała. | `ace-review`, `9e59575e8`. Surowy obiekt trafia w całości do parsera, a opakowanie Markdown rozpoznaje wyłącznie znaczniki w osobnych liniach. | Regresja czerwony → zielony, 918 testów pakietu i niezależne review przeszły. Dwa buildy `utm129` mają ten sam SHA-256. Na `utm128` recenzent sam odzyskał syntezę, o 03:38 UTC zapisał pierwszą pełną rundę, a po trzech pełnych rundach opublikował aprobatę. Osobny integrator scalił PR 5 o 04:32:39 UTC. |
| UTM-16 | `8y909wx`: pierwsza próba narzędzia review przekroczyła 900 s przed uzyskaniem raportu. Później próby ratowania syntezy przez Claude i Antigravity nie znalazły ich CLI, a próba alternatywnego Z.AI nie zwróciła wyniku. Osobne generowanie opisu commita także przekroczyło limit. | Runtime dostawcy. Pi/Z.AI na tej samej sesji zwrócił pełny raport oraz kompletną syntezę w kolejnych próbach. Recenzent ponowił commit. | Osobny pomiar od błędu parsowania. Przyczyna pierwszego timeoutu jeszcze nieustalona. |
| UTM-17 | W osobnym checkoutcie do naprawy `ace-test` nie widział lokalnych gemów. Ustawienie ścieżki w powłoce uruchamiało CLI, ale nie proces testu w izolowanym środowisku. | Środowisko deweloperskie. Udostępniono istniejący bundle pod ścieżką oczekiwaną przez runnera w nowym checkoutcie. | Test bazowy 34/146, potem test regresji wykazał właściwy błąd. Żadnej zmiany w działającej VM. |
| UTM-18 | `8y909wx` 03:38–03:40 UTC: recenzent najpierw użył nieobsługiwanych opcji w `ace-coworker rounds record`, a potem nazwy kroku i pozycyjnego `STEP` tam, gdzie `ace-assign` oczekuje numeru w `--after` lub samego `--assignment` przy starcie. | Coworker i Assign. Zapis rundy i wykonanie kroków doszły do skutku po odczytaniu rzeczywistego interfejsu. | Odzyskane samodzielnie. Wywołania rozpoznane w zapisie Pi. |
| UTM-19 | `8y909wx`: cel dostawy w Pi o `01:59:06.917Z`. Po 180 minutach Forgejo potwierdzał tylko bazowy PR 5. CLI, dokumentacja i release były otwarte. Runner nadal odpytywał stan po terminie. | Właściciele ścieżki review i harness. Kandydat `utm129` usuwa potwierdzony błąd parsowania UTM-15. Werdykt zależy od dokładnego czasu wszystkich wymaganych merge’ów. | Próba bez kredytu odbioru. O 05:08 UTC przerwano przeterminowany runner. Zachowano zapisy poleceń i odczyt Forgejo. Standardowy raport nie zdążył powstać. |

## Key Learnings

- Uprawnienia i komunikacja muszą wynikać z właściciela operacji. Adres odbiorcy raportu nie oznacza prawa zapisu do jego skrzynki. Gotowość projektu potwierdza Lab Overseer po niezależnej weryfikacji.
- Licznik czasu ma wiązać dokładny cel i potwierdzony efekt z tą samą instancją testu. Suma godzin pracy nie zastępuje dowodu zaakceptowanej roli, przydziału, wersji i wyniku.
- Przy ponowieniu odczytu można zachować istniejący uchwyt lub przypięty adres. Ponowienie skutku, takiego jak start procesu, publikacja raportu czy merge, wymaga sprawdzenia, czy skutek już zaszedł.
- Niezależne review wykryło zbyt szerokie dopasowanie komendy reconcile w helperze czasu. Test regresyjny odrzuca teraz komentarz i cytowaną komendę z odtworzonym wynikiem. Nie ma porównywalnych danych, żeby liczyć odsetek fałszywych alarmów per model.

## Action Items

- Dopisywać problem w chwili wykrycia. Jeden ID na przyczynę, a nawroty dopisywać z UTC, ID przebiegu i skutkiem. Oddzielać stan poprawki od dowodu na działającej VM.
- Linkować do minimalnego dowodu z właściciela stanu. Nie kopiować surowych sesji ani poświadczeń.
- Po każdym werdykcie uzupełniać wpisy i rozróżniać awarię setupu, błąd zachowania ról i błąd harnessu. Do odbioru liczyć wyłącznie dwa pełne przebiegi `003 → 004` na tym samym źródle i manifeście, z resetem pomiędzy.
