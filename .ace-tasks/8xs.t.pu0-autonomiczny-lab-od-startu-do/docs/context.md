# Kontekst, źródła i reguły wykonania

## Pierwszeństwo i status dowodów

Wymagania z briefu i liniowego podziału zostały zaakceptowane przez użytkownika 2026-10-29.
Załączniki w docs/sources są historycznymi raportami. Późniejsze ustalenia rozmowy
doprecyzowują hierarchię laba/projektów, Second Captaina i liniową kolejność.
Starsze opisy „drugi Kapitan = drugi odbiorca/człowiek” są zastąpione rolą agenta doradczego.

Raport laba wskazuje Forgejo = GitHub = af68f8fc1cc7, sync r6 PASS, zachowane
records/spec/config/interim-start oraz redukcję worktree'ów 41 → 1, z zachowanym salvage.
To deklaracja z dostarczonego raportu, nie niezależny audyt VM. Nie powtarzamy closeoutu.
Dalsza automatyzacja zapisu rekordów pozostaje wymagana.

Lokalny checkout w analizie był czysty; .gitignore zawierał /.ace-tasks/_overseer/.
Raport o zmienionym /_overseer/ dotyczył innego stanu/checkoutu. Nie utożsamiać tych ścieżek.
Lokalny ace-overseer miał observe, status i delegowanie, ale nie publiczne start.
Dokumenty historyczne mogą mieć nieaktualne statusy; przed zmianą porównać kod,
wydanie i środowisko docelowe. Wykorzystać gotowy rezultat, dopisać brakujący odbiór,
nie implementować ponownie naprawy na podstawie samej starej listy.

## Wykonanie i kontekst świeżej sesji

Każdy podtask jawnie ładuje project, brief, ten dokument, mapę problemów, właścicieli stanu,
własne scenariusze UX oraz źródła swojego zakresu. Nie ma domyślnego dziedziczenia bundle.
Parent jest mapą programu; dependencies dzieci określają linię 01–16.
Nie tworzyć wnuków ani pobocznych tasków w tej rodzinie bez zmiany zaakceptowanego zakresu.

W repo używać bin/ace-*; nie przekierowywać, nie potokować ani nie przetwarzać wyjścia CLI.
W trybie ACE_TOOLCHAIN=installed używać zainstalowanych CLI, gemów i instrukcji.
W dowodach podać ich rzeczywiste ścieżki; zachować tryb przy wznowieniu coworkera.
Binstuby nie są dopuszczalnym fallbackiem dla instalowanego laba.

Zmiany produkcyjne dopiero przez as-task-work. Rodzina przeszła as-task-review;
wynik promocji i uzupełnienia po odpowiedzi Kapitana są w docs/review.md.
Przed implementacją porównać spec z bieżącymi źródłami; zachować przyjęte zachowanie
i granice odpowiedzialności.

## Weryfikacja każdego wycinka

Specyfikacje opisują przyszłe próby, nie wyniki już wykonanych testów.
Każdy wycinek ma scenariusz pozytywny, scenariusz błędu i odbiór rzeczywistego przekazania.
Implementacja obejmuje odpowiednią dokumentację, testy przez ace-test/ace-test-suite,
niezależny review, a gdy zmienia runtime — publikację, instalację i odbiór pod docelowym
kontem. Dla dokumentacji i operacji stosować właściwą kontrolę dowodów zamiast
pozornych testów kodu. Komendy w specs nie są wykonywane podczas draftowania.

Testy scenariuszy agentowych muszą obserwować faktyczną delegację/wybudzenie oraz efekty.
Status komendy, rejestracja watcha lub komunikat „sent” nie wystarczają do dowodu konsumpcji.
Dla zero-idle obserwować liczbę tur/wywołań modelu, nie wymagać braku technicznego pollingu.
Nie tworzyć nowego systemu telemetrii na potrzeby dowodów.

Nie utrwalać sekretów. Prompty przekazywać jako pliki/ustrukturyzowane argumenty.
SHA, wersje i wyniki brać z dowodów; nie dopisywać wymyślonych końcówek.
Path-scoped commity; nie resetować obcych zmian. Nie usuwać salvage ani aktywnych spraw.

## Starsze prace i referencje laba

- 8xg.t.sbz: istniejące role, delegacja, HITL, status, instalacja i odbiór; bundle etapów
  wskazuje odpowiednie istniejące specyfikacje zamiast kopiować ich wykonanie.
- 8xg.t.sbz.7 / PR77: raportowane prace instalatora; sprawdzić stan integracji i wydania.
- 8xg.t.sbz.9 i gad.2: końcowy raport ma mapować spełnione kryteria; nie zamykać ich
  automatycznie na podstawie samego ukończenia nowego taska.
- 8xr.t.9o9: raportowany spec dostawy Hermes. Nie znaleziono go w lokalnym checkoutcie
  podczas draftowania; referencja pozostaje identyfikatorem z laba, nie fikcyjnym linkiem.
  Review odnalazł i odczytał spec z fg/af68f8fc1; kopia i porównanie są w
  docs/sources/standing-wake-af68f8fc1.md oraz docs/review-source-map.md.
- PR74, PR77, PR79 pochodzą z repozytorium Forgejo cs3b/ace; odczytano historię
  fg/main, lecz nie dyskusje tych PR. Nie traktować ich jako numerów PR GitHub.
- Dostarczone źródła nie są plikami ace-idea i nie wymagają archiwizacji idei.

Nie zmieniamy statusów istniejących zadań podczas draftowania tej rodziny.
Nie odtwarzamy starych warstw admission/authority z archiwów. Doprecyzowanie Kapitana
zatwierdza jednak ace-lab auth i pluginy z krótkotrwałymi role credentials. To zakres .7,
nie blokada do ponownej zgody. Źródła lab-config i granice ponownego użycia opisuje
docs/auth-mechanics.md; nie utożsamiać starego admin PAT copy z nowym tokenem.

## Początek i koniec wycinka

Przed pracą: odczytać brief i źródła, potwierdzić poprzednika, wskazać bieżącą lukę
oraz ścieżkę producent → konsument. Po pracy: zapisać wynik i dowody w tasku/assignmencie,
oddzielić kod, publikację, instalację i odbiór; podać następny odblokowany podtask.

## Aktualizacja po review 2026-10-29

Stan źródeł, przyjęte defaults i rozróżnienie kodu od odbioru opisuje docs/review-source-map.md.
Wynik gotowości rodziny: docs/review.md. Wcześniejsze zdania o braku źródeł opisują fazę draftowania.
