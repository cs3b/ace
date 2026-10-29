---
id: 8xs.t.pu0
status: pending
priority: high
created_at: "2026-10-29 17:13:21"
estimate: large
dependencies: []
tags: [lab, autonomy, program]
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-overseer/docs/usage.md, ace-lab/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md]
  commands: []
---

## Review Questions — rozstrzygnięte 2026-10-29

Kapitan zatwierdził ace-lab auth z pluginami Forgejo/GitHub/env i krótkotrwałymi
poświadczeniami ról. Odnalezione mechaniki i kontrakt są w .7 oraz docs/auth-mechanics.md.
Nie pozostają pytania blokujące review rodziny.

# Autonomiczny lab od startu do wdrożenia

## Cel

Z jednego ace-overseer start w katalogu laba uruchomić nadzór skonfigurowanych projektów,
a w katalogu projektu — samodzielny nadzór tego projektu. Doprowadzać zlecenia przez
coworkerów do zweryfikowanego wdrożenia i rekordu w Git, bez ręcznego prowadzenia agentów.
Second Captain proponuje decyzje w HITL i uczy się z rzeczywistych odpowiedzi człowieka.

## Dokumentacja i materiały

- [Zaakceptowany brief](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md).
- [Kontekst i reguły wykonania](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md).
- [Mapa wszystkich 30 problemów](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md).
- [Oryginalne materiały źródłowe](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/README.md).
- [Scenariusze użytkowe](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/ux/usage.md).
- [Mechanika auth i decyzja Kapitana](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md).

## Model i kolejność

Jeden orchestrator i dokładnie 16 bezpośrednich dzieci. Brak wnuków.
Kolejność jest liniowa: 01 → 02 → … → 16, zapisana w dependencies dzieci.
Parent nie zależy od własnych dzieci w frontmatter; ich odbiór jest warunkiem zamknięcia.
Każde dziecko ma własny jawny bundle i testowalny rezultat. Nie ma osobnego taska research.
Rozmiary są orientacyjne, nie stanowią budżetu ani powodu do ograniczenia jakości.

| Krok | ID | Zakres | Rozmiar | Zależność |
|---|---|---|---|---|
| 01 | [8xs.t.pu0.0](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/8xs.t.pu0.0-zapewni-kompletny-runtime-z-instalatora.s.md) | Zapewnić kompletny runtime z instalatora | large | — |
| 02 | [8xs.t.pu0.1](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/8xs.t.pu0.1-uruchamia-nadzorc-z-konfiguracji-projektu.s.md) | Uruchamiać nadzorcę z konfiguracji projektu | large | 8xs.t.pu0.0 |
| 03 | [8xs.t.pu0.2](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/2-uruchamia-obserwatory-zmian-przez-watch/8xs.t.pu0.2-uruchamia-obserwatory-zmian-przez-watch.s.md) | Uruchamiać obserwatory zmian przez watch | medium | 8xs.t.pu0.1 |
| 04 | [8xs.t.pu0.3](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/3-reagowa-na-lokalny-stan-projektu/8xs.t.pu0.3-reagowa-na-lokalny-stan-projektu.s.md) | Reagować na lokalny stan projektu | large | 8xs.t.pu0.2 |
| 05 | [8xs.t.pu0.4](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/4-obserwowa-zmiany-pr-oraz-repozytorium/8xs.t.pu0.4-obserwowa-zmiany-pr-oraz-repozytorium.s.md) | Obserwować zmiany PR oraz repozytorium | medium | 8xs.t.pu0.3 |
| 06 | [8xs.t.pu0.5](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/5-dostarcza-odpowiedzi-bez-r-cznego/8xs.t.pu0.5-dostarcza-odpowiedzi-bez-r-cznego-relay.s.md) | Dostarczać odpowiedzi bez ręcznego relay | large | 8xs.t.pu0.4 |
| 07 | [8xs.t.pu0.6](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/8xs.t.pu0.6-zamyka-sprawy-hitl-bez-sierot.s.md) | Zamykać sprawy HITL bez sierot | large | 8xs.t.pu0.5 |
| 08 | [8xs.t.pu0.7](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md) | Delegować zadania przez role i ace-lab auth | large | 8xs.t.pu0.6 |
| 09 | [8xs.t.pu0.8](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/8xs.t.pu0.8-prowadzi-zadania-przez-review-i-merge.s.md) | Prowadzić zadania przez review i merge | large | 8xs.t.pu0.7 |
| 10 | [8xs.t.pu0.9](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/8xs.t.pu0.9-dostarcza-wydania-i-zamyka-cykle.s.md) | Dostarczać wydania i zamykać cykle | large | 8xs.t.pu0.8 |
| 11 | [8xs.t.pu0.a](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/a-uruchamia-projekty-z-katalogu-laba/8xs.t.pu0.a-uruchamia-projekty-z-katalogu-laba.s.md) | Uruchamiać projekty z katalogu laba | large | 8xs.t.pu0.9 |
| 12 | [8xs.t.pu0.b](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/b-proponowa-odpowiedzi-jako-second-captain/8xs.t.pu0.b-proponowa-odpowiedzi-jako-second-captain.s.md) | Proponować odpowiedzi jako Second Captain | medium | 8xs.t.pu0.a |
| 13 | [8xs.t.pu0.c](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/8xs.t.pu0.c-uczy-sugestie-na-decyzjach-kapitana.s.md) | Uczyć sugestie na decyzjach Kapitana | medium | 8xs.t.pu0.b |
| 14 | [8xs.t.pu0.d](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/8xs.t.pu0.d-utrwali-operacje-hosta-i-higien.s.md) | Utrwalić operacje hosta i higienę | medium | 8xs.t.pu0.c |
| 15 | [8xs.t.pu0.e](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/e-potwierdzi-pe-ny-cykl-zimnego/8xs.t.pu0.e-potwierdzi-pe-ny-cykl-zimnego-startu.s.md) | Potwierdzić pełny cykl zimnego startu | large | 8xs.t.pu0.d |
| 16 | [8xs.t.pu0.f](.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/f-sprawdzi-odporno-i-zamkn-program/8xs.t.pu0.f-sprawdzi-odporno-i-zamkn-program.s.md) | Sprawdzić odporność i zamknąć program | large | 8xs.t.pu0.e |

## Kontrakt interfejsu

- ace-overseer start w katalogu laba zapewnia spaces i nadzorców skonfigurowanych projektów.
- Ta sama komenda w katalogu projektu uruchamia nadzorcę tylko tego projektu.
- Powtórzenie i restart odtwarzają stan bez duplikacji sesji lub zakończonych skutków.
- Agent uzyskuje ograniczony dostęp przez ace-lab auth; role i terminy wynikają z konfiguracji hosta, a cleanup ma potwierdzony wynik.
- Kapitan otrzymuje pytania z oznaczonymi sugestiami; decyzję zatwierdza człowiek.
- Brak konfiguracji, dostępu lub gotowości jest konkretnym błędem; nie jest zgadywany sukces.

## Kryteria akceptacji programu

- [ ] Wszystkie 16 dzieci ma udokumentowany odbiór własnego zakresu.
- [ ] Zimny start laba z co najmniej dwoma projektami i osobny start projektu działają.
- [ ] Nadzorcy delegują wykonanie, a cały cykl kończy się zainstalowanym rezultatem i rekordem w Git.
- [ ] Dostęp coworkerów przez auth ma właściwy principal/scope/termin i potwierdzenie cleanup; awaria revoke nie udaje sukcesu.
- [ ] Testy oraz niezależny review dotyczą aktualnego kandydata; CI jest advisory.
- [ ] Odpowiedź HITL dociera, jest stosowana raz i zamyka sprawę bez ręcznego relay.
- [ ] Second Captain sugeruje w tym samym wątku i korzysta z rzeczywistych decyzji bez samodzielnego zatwierdzania.
- [ ] Restart, duplikat, lost-reply, wrong-head i awaria obserwacji mają wykonane próby odzyskania.
- [ ] Co najmniej 30 minut zdrowej ciszy po uspokojeniu stanu nie powoduje dodatkowych wywołań modelu.
- [ ] Runtime nie wymaga ręcznych zależności lub kopiowania rozszerzeń; tryb installed jest zachowany.
- [ ] Raport końcowy mapuje dowody na ten program oraz odpowiednie kryteria gad.2/sbz.9.

## Plan weryfikacji

Każdy wycinek ma komponentową kontrolę warunków, rzeczywistą ścieżkę producent → konsument
i negatywny scenariusz. Kroki 15–16 składają te dowody w odbiór całego produktu i odporności.
Testy pakietów wyłącznie przez ace-test/ace-test-suite. Niezależny review przed merge.
Nie uruchamiać testów produktu ani operacji na labie w fazie draftowania.

## Stan wejściowy i powiązania

Raport laba deklaruje closeout af68f8fc1cc7, sync r6 PASS oraz 41 → 1 worktree.
To zachowany kontekst, nie nowy wynik audytu. Naprawione problemy wracają jako regresje.
Wykorzystać istniejące prace 8xg.t.sbz, w tym instalację .7 i odbiór .9.
Spec 8xr.t.9o9 odnaleziono i odczytano z Forgejo af68f8fc1cc7f1645e2d3caed7abb92f0262b47b;
mapa źródeł oraz kopia speca są w docs/review-source-map.md i docs/sources.
Historia Git nie dowodzi obecnego runtime ani treści review poszczególnych PR.
Ta rodzina nie zmienia statusów starszych tasków podczas tworzenia draftów.

## Inwentarz pojęć

| Pojęcie | Wprowadzenie / zmiana | Usunięcie | Docelowy status |
|---|---|---|---|
| Kontekstowy start projektu/laba | 02, 11 | — | Docelowy interfejs |
| Guide z gema | 02 | Ręczny guide w 14 | Docelowe instrukcje |
| Stała obserwacja | 03–05 | Martwe obserwacje w 07 | Istniejący właściciel, bez nowego serwisu stanu |
| Dostawa bez ręcznego relay | 06–07 | Stare trasy/relay w 06, 14 | Docelowy przepływ HITL |
| Auth i provider plugins | 08 | Zastępowane skrypty i ścieżki credential w 08 | Docelowy cykl lease, jeden właściciel; bez brokera mutacji |
| Second Captain | 12–13 | — | Rola doradcza coworkera |
| Interim start | Już istnieje wg raportu | 14 po odbiorze 02, 11 | Usunięty |
| Właściciele stanu | Zachowani we wszystkich krokach | — | Bez drugiej kolejki/rejestru |

## Poza zakresem

Samodzielne decyzje Second Captaina, drugi ludzki Kapitan, fine-tuning modelu,
pane-close w Herdr, nowy silnik kolejki/rejestr/journal/cache, kompatybilność wsteczna
i ponowne wykonywanie zakończonego closeoutu. Draftowanie nie wdraża żadnej zmiany.

## Ustalenia przeglądu rodziny

Każdy pierwotny zamiar nadal ma dziecko; zachowano dokładnie 16 dzieci i kolejność.
Krok 01 obejmuje integrację/packaging istniejącego ace-wake z fg, nie reimplementację
install/resume. Kroki 03–05 mają jedną infrastrukturę obserwacji i mierzalne granice.
Krok 06 dostarcza bezpośredni reply z korelacją maszyny/rootu/sesji; krok 07 odpowiada
za zakończenie zastosowania i sprzątanie. Krok 08 dostarcza ace-lab auth i pluginy
Forgejo/GitHub/env na podstawie istniejących mechanik, wraz z instalacją i cleanup. Krok 09 wiąże także testy z HEAD. Krok 10
kończy automatyczny delivery i record PR bez rekurencyjnych wydań. Kroki 12–13 rozróżniają
sugestię, ludzką decyzję i lesson, z filtrem sekretów przed modelem. Kroki 15–16
mają konkretne scenariusze odmowy i odzyskania, nie tylko ogólny nakaz testowania.

Mapa akceptacji parenta: dzieci .0 (runtime), .1/.a/.e (start), .7/.8/.9/.e
(delegacja/delivery/auth), .8/.f (test/review HEAD), .5/.6/.f (HITL), .b/.c/.e
(Second Captain), .2/.3/.4/.f (restart/awarie/idle), .f (macierz i historyczne kryteria).
Pierwszy checkbox wymaga dowodów odbioru wszystkich dzieci; review speców go nie zaznacza.

## Następny etap

Review 2026-10-29 objął wszystkie 16 dzieci. Wynik i mapa zmian: docs/review.md.
Wykonanie zaakceptowanych dzieci przez as-task-work respektuje liniowe dependencies.
Pytanie HIGH w .7 jest rozstrzygnięte. Promocja rodziny oznacza gotowość specyfikacji
do wykonania; nie jest odbiorem produktu ani zwolnieniem liniowych zależności.
