# Autonomiczny Lab — zaakceptowany brief

Źródło: ustalenia z Kapitanem w rozmowie 2026-10-29. Dokument opisuje docelowe zachowanie;
nie jest deklaracją, że funkcje już działają. Kolejność wykonania wynika z taska nadrzędnego
i dependencies jego 16 bezpośrednich dzieci. Brak kolejnych poziomów podtasków.

## Cel widziany z zewnątrz

Kapitan przekazuje cel. Lab sam organizuje pracę, deleguje ją, sprawdza wynik i doprowadza
zmianę do działającego wdrożenia. Człowiek podejmuje decyzje poza przyznaną autonomią
i dostarcza OTP. Host odpowiada za infrastrukturę i jej awarie.

Jedno polecenie: ace-overseer start. Zakres wynika z konfiguracji katalogu uruchomienia.

| Katalog | Zachowanie |
|---|---|
| Lab | Uruchamia nadzorcę laba, odczytuje skonfigurowane projekty, zapewnia ich spaces w Herdr i uruchamia lub odnajduje nadzorców projektów. |
| Projekt | Uruchamia lub odnajduje nadzorcę danego projektu, z jego konfiguracją i instrukcjami. |

Ponowny start uzupełnia braki, rozpoznaje żywe sesje i nie tworzy duplikatów.
Brak lub niejednoznaczność wymaganej konfiguracji daje konkretny błąd.
Projekt może działać samodzielnie bez nadzorcy całego laba.

## Role

- Kapitan jest człowiekiem: określa cel, ograniczenia i podejmuje wymagane decyzje.
- Overseer laba zna projekty, nadzorców, zasoby, blokady i eskalacje między projektami.
- Overseer projektu zna zadania, wykonania, worktree'y, raporty, PR-y i stan dostarczania.
  Wybiera następną czynność i deleguje wykonanie właściwej roli.
- Coworkerzy przygotowują zadania, implementują, recenzują, integrują oraz publikują.
  Dostają zakres, kontekst, kryteria zakończenia i potrzebny dostęp.
- Second Captain jest coworkerem doradczym uczącym się na decyzjach człowieka.

Nadzorcy wykonują koordynację; nie przejmują implementacji, review ani publikacji od
wykonawców. Instrukcje wszystkich ról są dostarczane w gemach, z normalnymi nadpisami ACE.

## Pełny cykl

1. Przyjęcie celu i zapis kryteriów zakończenia.
2. Odczyt istniejącego stanu, zależności i dostępnego zespołu.
3. Przygotowanie worktree, assignmentu, instrukcji i dostępu; delegacja.
4. Wykonanie oraz raport wyniku albo blokady.
5. Wykonane testy i niezależny review konkretnego kandydata.
6. Wymagane formalne approval i merge przez właściwe konta.
7. Release, publikacja, instalacja i wdrożenie rozszerzeń.
8. Sprawdzenie działania pod docelowym kontem na zainstalowanych wersjach.
9. Zintegrowany rekord cyklu w Git, aktualizacja zadania i zamknięcie spraw.

Każde przekazanie ma właściciela następnego działania, trwały dowód i sposób wznowienia.
Cykl wymagający wdrożenia pozostaje otwarty do sprawdzenia runtime i zintegrowania rekordu.
Merge gate: wykonane testy oraz niezależny werdykt review. CI pozostaje doradcze.
Zmiana HEAD wymaga aktualnych podstaw weryfikacji.

## Rozruch i obserwacja

Guide z gema opisuje oba zakresy nadzorcy, delegację, eskalacje, dostęp i domknięcie.
Start ładuje guide, konfigurację i profil modelu/harnessu. Odtwarza stan zamiast rozpoczynać
pracę od nowa. Widoczne są: zespół, zadania, worktree'y, assignmenty, HITL oraz PR/repo.

Watch faktycznie uruchamia obserwator. Zmiana wybudza właściwego odbiorcę.
Start po przerwaniu wykrywa również pracę pozostawioną podczas nieobecności.
Brak zmian nie powoduje tur modelu; techniczne odpytywanie źródła jest dopuszczalne.
Awaria źródła obserwacji musi być odróżniona od zdrowej ciszy.

## HITL

Ask tworzy sprawę, wysyła pytanie, uzbraja wznowienie i kończy turę.
Hermes dostarcza odpowiedź przez ace-hitl reply na maszynie wskazanej adresem sprawy.
Odpowiedź zostaje zapisana, zauważona, zastosowana, a sprawa zamknięta.
Ponowna dostawa nie powoduje powtórzenia skutków. Spóźniona odpowiedź nie otwiera
zamkniętej sprawy ani nie zmienia wykonanej decyzji automatycznie.
Blocking wait pozostaje wyłącznie ścieżką awaryjną.

## Second Captain

To agent, nie drugi człowiek. Proponuje odpowiedź na pytanie kierowane do Kapitana.
Sugestia wraz z uzasadnieniem i podstawami jest częścią tego samego wątku ace-hitl,
oznaczoną jako propozycja. Nie blokuje wysłania pytania i nie stanowi ludzkiej zgody.

Po decyzji człowieka Second Captain porównuje ją ze swoją sugestią i zapisuje wnioski
przy sprawie. Kolejne sugestie korzystają z właściwej historii decyzji i wskazują źródła.
Historia HITL pozostaje źródłem wiedzy; nie tworzymy równoległego magazynu decyzji.
Należy zachować przykłady potrzebne do uczenia przy sprzątaniu transportu i watchy.
Przy braku precedensu agent ujawnia brak podstaw zamiast fabrykować wcześniejsze decyzje.
Odpowiedź człowieka ma pierwszeństwo także wtedy, gdy nadejdzie przed sugestią.
OTP i wartości sekretów nie są materiałem do uczenia.

W tym zakresie uczenie oznacza używanie historii i utrwalonych wniosków, nie trening
parametrów modelu. Samodzielne podejmowanie decyzji jest przyszłym rozszerzeniem,
wymagającym osobnej decyzji o zakresie autonomii.

## Uprawnienia i runtime

Każda rola zna dozwolone operacje oraz sposób uzyskania dostępu. Dostęp dla coworkera jest
ograniczony zadaniem i czasem; jego zakończenie jest częścią cyklu. Generowanie poświadczeń
jest dozwolone tylko w jawnie przyznanym zakresie. Sekrety pozostają w bezpiecznych
mechanizmach przekazania, nie w promptach, raportach lub transkryptach.

Doprecyzowanie Kapitana podczas review 2026-10-29: docelowy interfejs to `ace-lab auth`,
z pluginami Forgejo (issue/revoke), GitHub i env. Agent prosi o krótkotrwały dostęp
właściwej roli (np. developer/reviewer). Krok .7 pakuje istniejące mechaniki lab-config,
wraz z zakresem, terminami, bezpiecznym handoff i cleanup; źródła w docs/auth-mechanics.md.
Expiry providera, zaplanowany revoke hosta i ekspozycja static env są jawnie rozróżniane.

Właściwy wzorzec kont według raportu laba: lab-overseer jako autor i merger,
lab-merge-ace jako formalny approver po niezależnym review.
Uprawnienia sprawdzamy w docelowym środowisku; samo posiadanie tokena nie rozszerza roli.

Instalacja uzgadnia manifest, wersje gemów, wymagane zależności przechodnie i rozszerzenia.
Sprawdza środowisko docelowych kont i potrzebę restartu działających procesów.

## Własność stanu i dostarczanie

Obowiązuje docs/lab-flow.md: taski projektu w .ace-tasks/, prywatne zadania nadzorcy
w .ace-tasks/_overseer/, assignmenty, coworkerzy i HITL u obecnych właścicieli.
Topologia korzysta z istniejącej konfiguracji ace-lab. Nie dodajemy kolejki, journala,
rejestru topologii, warstwy autoryzacji mutacji ani dodatkowego cache'u stanu.
Jawnie zatwierdzony cykl auth ma jednego właściciela w ace-lab i minimalny rekord lease;
.7 aktualizuje mapę właścicieli oraz ADR-034. Nie kopiuje do auth postępu tasków/assignmentów.

Implementację przygotowujemy na hoście; lab odbiera opublikowane wydania i służy do
potwierdzenia działania. Rozróżniamy źródła, integrację, publikację, instalację i odbiór.
ACE_TOOLCHAIN=installed zachowuje zainstalowane executables i instrukcje z gemów:
brak zależności oznacza brak gotowości, bez przechodzenia na źródła checkoutu.

Synchronizacja mirroru ma powtarzalny reviewowany przebieg hosta.
Usuwamy stare konfiguracje i rozwiązania tymczasowe dopiero po odbiorze ich zastępstw.
Nie wprowadzamy kompatybilności wstecznej ani kolejnych tymczasowych ścieżek.

## Odbiór

- Start laba zapewnia nadzorców co najmniej dwóch projektów; projekt startuje też samodzielnie.
- Ponowny start i restart nie dublują nadzorców ani ukończonych operacji.
- Pełny cykl jest delegowany i kończy się sprawdzonym wdrożeniem oraz rekordem w Git.
- Opóźniona decyzja dociera do właściwej sprawy bez ręcznego relay.
- Sugestia Second Captaina i rzeczywista decyzja są rozróżnialne i użyteczne jako historia.
- Utrata odpowiedzi, duplikat, awaria obserwacji i zmiana HEAD mają sprawdzoną obsługę.
- Brak zmian oznacza brak bezproduktywnych tur modelu.
- Runtime działa bez ręcznego doinstalowywania zależności i kopiowania rozszerzeń.
- Raport odbioru wskazuje rzeczywiste wersje, kandydatów, role i dowody.

## Poza zakresem

Samodzielne decyzje Second Captaina, dodatkowy ludzki Kapitan, fine-tuning modelu,
zamykanie pojedynczego pane w Herdr, ponowne wykonywanie już potwierdzonego closeoutu.
Samo utworzenie tej rodziny draftów nie zmienia statusów starszych tasków ani stanu laba.
