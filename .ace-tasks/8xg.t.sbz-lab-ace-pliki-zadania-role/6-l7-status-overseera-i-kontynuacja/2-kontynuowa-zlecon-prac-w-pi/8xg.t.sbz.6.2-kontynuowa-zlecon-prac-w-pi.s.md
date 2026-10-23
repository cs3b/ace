---
id: 8xg.t.sbz.6.2
status: pending
priority: medium
created_at: "2026-10-17 18:54:23"
estimate: medium
dependencies: [8xg.t.sbz.5, 8xg.t.sbz.1]
tags: [lab, lab-l7, file-based]
parent: 8xg.t.sbz.6
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-overseer/docs/usage.md, ace-herdr/README.md, ace-git-worktree/docs/usage.md, ace-handbook-integration-pi/handbook/extensions/ace-wake/index.js, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/2-kontynuowa-zlecon-prac-w-pi/ux/usage.md, .ace-tasks/8xg.t.k9y-ace-git-worktree-list-active/8xg.t.k9y-ace-git-worktree-list-active-worktree-table.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-herdr/lib/ace/herdr/molecules/native_queue_executor.rb]
  commands: []
title: Kontynuować zleconą pracę w pi
---

# Kontynuować zleconą pracę w pi

## Cel

Overseer widzi rzeczywistą sytuację i kontynuuje już zlecony proces po wiadomości lub restarcie. Ten subtask dostarcza następujący wycinek: Mechanizmy w pi przyjmują wiadomości podczas pracy i oczekiwania oraz wznawiają zlecony proces. Po restarcie overseer czyta _overseer i aktualną prawdę o projekcie.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

Mechanizmy w pi przyjmują wiadomości podczas pracy i oczekiwania oraz wznawiają zlecony proces. Po restarcie overseer czyta _overseer i aktualną prawdę o projekcie.

## Kryteria odbioru

- [ ] Raport budzi oczekującego overseera; po restarcie kontynuuje on ten sam proces i istniejące assignmenty.
- [ ] Powtórzone powiadomienia nie tworzą drugiej egzekucji; brak nowej zleconej pracy nie prowadzi do samodzielnego szukania kolejnych zadań.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Raport budzi oczekującego overseera; po restarcie kontynuuje on ten sam proces i istniejące assignmenty.
- Scenariusz błędu / niepoprawnego wejścia: Powtórzone powiadomienia nie tworzą drugiej egzekucji; brak nowej zleconej pracy nie prowadzi do samodzielnego szukania kolejnych zadań.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.0](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md)
- [8xg.t.qn6.1](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)
- [8xd.t.cm3](.ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Status worktree korzysta z ukończonego `8xg.t.k9y`; obecnym publicznym wejściem jest `ace-git-worktree list`. Nie tworzyć drugiej implementacji tylko dla nazwy status. L7.1 może być wykonany wcześniej niż cała rodzina L7.

## Review gotowości — 2026-10-18, po PR #379

Wykorzystać istniejący transport pi wskazany konfiguracją Herdr (`ACE_HERDR_PI_QUEUE_CLIENT` / obecny adapter). Kod integracji pozostaje po stronie istniejącego adaptera/rozszerzenia pi, bez drugiej kolejki w ACE. Dostarczenie podczas aktywnej tury nie uruchamia drugiego overseera; oczekująca sesja podejmuje zlecony proces.
Po restarcie sesji prompt wznowienia odczytuje zadania _overseer, assignmenty i stan projektu. Test aktywnej i oczekującej sesji, restartu i powtórzonego raportu. Weryfikacja prawdziwego pi jest częścią odbioru; brak dostępnego runtime to niewykonany scenariusz, nie powód do budowania zastępczego serwisu. Nie szukać nowych zadań poza zleceniem.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-herdr/lib/ace/herdr/molecules/native_queue_executor.rb`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.

## Ponowne otwarcie: zdarzeniowe „oczy” overseera (2026-10-23)

Status `draft` / `needs_review: true` dotyczy nowych kryteriów poniżej. Poprzedni
zakres kontynuacji został zapisany jako `done`; jego historia, wyniki i dowody
pozostają zachowane. Nie oznacza to odbioru poniższych ograniczeń kosztu ani
wdrożenia ich w opublikowanych gemach. Rozmiar rozszerzenia: medium.

### Zachowanie wymagane

1. Żywy overseer obserwuje zlecony proces deterministycznie, wewnątrz istniejącej
   integracji pi. Brak zmiany oznacza **zero wywołań modelu**, nie turę LLM
   odpowiadającą „bez zmian”. Odczyt plików i upływ interwału nie są zdarzeniem
   wymagającym decyzji. Bez nowego demona, crona, systemd timera, drugiego
   harmonogramu, kolejki wykonania ani journala. Martwego procesu nie wskrzesza
   ten mechanizm; pozostaje to decyzją nadrzędnego overseera.
2. Pierwszy kompletny wycinek obejmuje prawdziwe wiadomości/odpowiedzi HITL i
   raporty coworkerów. Nowa treść wymagająca decyzji budzi właściwego właściciela
   przez istniejący transport. Zdarzenia spoza projektu/zlecenia nie uruchamiają
   jego pracy. Decyzja co dalej pozostaje u agenta, nie w obserwatorze.
3. Tożsamość zmiany opiera się na stabilnej semantyce: źródle, projekcie,
   identyfikatorze wiadomości/raportu i istotnej rewizji treści/stanu. Wyklucza
   czas ostatniego odpytywania, kolejność serializacji i inne zmienne metadane
   obserwacyjne. Powtórzony odczyt, zmiana mtime bez zmiany treści lub zapis
   własnego potwierdzenia nie wywołuje kolejnej tury. Faktyczna nowa odpowiedź,
   zmieniony wynik lub jawna zmiana decyzji pozostaje widoczna.
4. Seria zmian scala się w jedno oczekujące powiadomienie, zachowując wszystkie
   nieprzyjęte identyfikatory/rewizje. Aktywna tura dostaje istniejący follow-up,
   bez drugiego agenta i bez równoległego wykonania tego samego kroku. Zmiana
   przychodząca w trakcie przyjęcia poprzedniej nie może zostać utracona.
5. Sam odczyt ani próba wysłania wake nie oznaczają przyjęcia. Oczekujący stan
   przetrwa błąd transportu, przerwanie i restart. Wznowienie uzgadnia go z
   istniejącym potwierdzeniem właściciela; nie uznaje wszystkich obecnych plików
   za nowe i nie pomija nieprzyjętych. Potwierdzenie ma jasno odróżniać dostarczenie
   powiadomienia od zastosowania wyniku. Przyjęcie raportu i jego ID pozostają
   własnością `8xg.t.sbz.5.4` w istniejącym tasku zarządzającym; nie kopiować
   jego logiki lub zakładać dodatkowego magazynu prawdy. Implementacja wybiera
   istniejący mechanizm trwałości i wykazuje brak luki między zmianą a ack.
6. Ponowione powiadomienie nie jest pozwoleniem na powtórny merge/publish/start.
   Niepewny wynik operacji wymaga odczytania jej istniejącego identyfikatora i
   uzgodnienia skutku przed decyzją o dalszym działaniu. Brak danych nie jest
   sukcesem, nowym zadaniem ani automatycznym retry efektu zewnętrznego.
7. Termin zapisany dla konkretnej decyzji może stać się osobnym zdarzeniem raz
   dla danej tożsamości i rewizji terminu. Nie tworzyć sztucznych terminów tylko
   po to, aby budzić model. Zmiana/anulowanie terminu unieważnia stary sygnał;
   restart nie odtwarza już przyjętych alarmów. Nie zmieniać istniejących zasad
   autoryzacji, w tym warunków użycia okna HITL.
8. Obserwacja ma jawny skończony budżet pracy w bezczynności (częstotliwość,
   zakres źródeł, czas i limit błędów); przekroczenie pokazuje konkretny stan
   ograniczenia bez pętli eskalacji przez LLM. Własne metryki nie generują wake.
   Potwierdzone wyczerpanie quota/budżetu zamyka bramkę wywołań modelu: brak
   automatycznych ponowień, zmiany providera/modelu lub powiększenia budżetu.
   Zdarzenia pozostają oczekujące; jeden zapis blokady wskazuje przyczynę i
   właściciela. Wznowienie wymaga jawnej decyzji uprawnionego właściciela po
   sprawdzeniu dostępności; restart sam nie resetuje blokady.
9. Przy wycofaniu aktora usuwa się jego stare loop/watch oraz przywiązania
   powiadomień, zachowując nieprzyjęte zdarzenia i przekazanie odpowiedzialności.
   Nie uruchamiać ponownie odstawionych pętli GLM dla testu. Ogólne usunięcie
   starego przepływu pozostaje w `8xg.t.sbz.0.1`; ten liść odpowiada za własne
   źródła pobudzeń. Rollout nie utrzymuje równoległych starych cyklicznych tur
   LLM jako fallbacku do nowych oczu.

### Odbiór nowego zakresu (niewykonany)

- [ ] 24 godziny logicznego czasu bez zmiany źródeł, bez zadanego terminu i bez
  poleceń użytkownika: 0 wywołań modelu, także przy zmianach poll timestamps,
  mtime i własnych ack; pomiary obserwatora pozostają w zadanym budżecie.
- [ ] Jeden rzeczywisty raport i dokładna odpowiedź HITL w opublikowanym runtime
  budzą właściwego idle overseera; przy aktywnej turze wynik trafia do tego
  samego procesu. Seria zmian jest scalona bez utraty identyfikatorów.
- [ ] Awaria przed wysłaniem, po wysłaniu przed ack i podczas przyjęcia oraz
  restart zachowują oczekujące zmiany; odebrane raporty nie uruchamiają nowego
  assignmentu. Niepewny merge/publish nie jest automatycznie powtarzany.
- [ ] Nowa zmiana w trakcie ack nie ginie; cudzy projekt nie budzi tego aktora;
  zmieniony/anulowany termin i restart dają wyłącznie właściwy nowy sygnał.
- [ ] Quota failure zamyka bramkę przed następnym wywołaniem; 100 kolejnych
  odczytów i restart dają 0 prób LLM. Jawne wznowienie zachowuje pending oraz
  wymaga sprawdzenia dostępności, bez cichego fallbacku modelu.
- [ ] Wycofany aktor nie ma aktywnych loop/watch ani dostarczeń; właściciel
  przejmujący przyjmuje zachowane zdarzenia bez podwójnych efektów.

Testy deterministyczne mogą przyspieszać czas, ale nie zastępują odbioru na
prawdziwym pi. W dowodach oddzielić testy źródłowe, publikację i instalację
oraz rzeczywisty czas obserwacji; nie deklarować 24h live na podstawie zegara
w teście. Podczas odbioru zachować zatrzymanie legacy i skończony budżet.

### Pochodzenie incydentu, nie definicja kontraktu

Obserwacja hosta za 22 października 2026, Canary (21.10 23:00 UTC–22.10
23:00 UTC): 12 694 wpisy assistant, w tym 10 161 poprawnych unikalnych ID
oraz 2 533 błędy quota z zerowym użyciem; 5 712 wpisów wake i 5 080 odpowiedzi
końcowych sklasyfikowanych jako idle/no-change. Nowe dwie sesje wykonały
4 930 HITL sync; stare sesje: 151 tool calls, 129 Git, 22 inne. Liczniki tokenów:
input 21 535 913, output 637 134, cache read 5 005 307 648, cache write 0.
Lokalna estymata pi: 153,70818339 USD — **nie faktura dostawcy**. Zapisany/
żądany model GLM-5.3-Flash nie dowodzi modelu użytego do rozliczenia serwerowego.
Źródło audytu: lab-config commit `707d805`; nie utrwalać kluczy ani prywatnych
wiadomości w tym tasku. Cztery loop w trzech sesjach usunięto 23.10 o
09:10:36 UTC, dwie trwające tury zatrzymano o 09:11:30; ostatnie odczyty
wykazały puste loops/watches. Jest to stan obserwowany, nie odbiór nowej funkcji.


## Review gotowości rozszerzenia — 2026-10-23

Niezależny review specyfikacji na head
`937ee0dbe1d16bd9a8c0d0d52e693846ddaf1dd2`: **VERDICT: READY**.
Workflow `as-task-review` / `wfi://task/review` wykonany; brak pytań blokujących.
Task promowano narzędziem do `pending`, `needs_review: false`; opis draftu powyżej
zachowuje historię ponownego otwarcia. Rodzic pozostaje `in-progress`.
Dowody gotowości zapisano w `results.md` w tym folderze. Nowe kryteria pozostają
niewykonane; review nie jest odbiorem implementacji, publikacji ani 24h live.
Przed startem implementacji sprawdzić zadeklarowane dependencies.
