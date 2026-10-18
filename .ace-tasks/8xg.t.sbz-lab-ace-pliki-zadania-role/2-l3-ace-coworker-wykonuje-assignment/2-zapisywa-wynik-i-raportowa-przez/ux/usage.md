# Zapisywać wynik i raportować przez HITL — scenariusze użycia

## Interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Trwały postęp zapisuje się przy tasku, pomocniczy stan w .ace-local/coworker/. Po zakończeniu assignmentu albo błędzie coworker raportuje przez ace-hitl.

Oczekiwany wynik: Zakończony assignment pozostawia wynik i raport do overseera; błąd zawiera przyczynę i stan umożliwiający dalsze działanie.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Samo zakończenie procesu lub wysłanie raportu nie oznacza wykonania nieukończonych kroków; niedostarczenie raportu nie gubi lokalnego wyniku.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Po integracji .1 i .2.1 raport zawiera ID taska, assignmentu i kroku oraz wynik i odnośnik do lokalnych dowodów. Trwały wynik pracy trafia do folderu taska; pomocniczy stan wykonawcy do `.ace-local/coworker/`, a wiadomość do HITL przez jego interfejs.
Oddzielić wynik wykonania od dostarczenia: poprawnie ukończony assignment z niedostarczonym raportem zachowuje sukces pracy i jawny błąd dostarczenia. Błąd wykonania zapisuje przyczynę i niedokończony krok, nie fałszywe work done. Sprawdzić oba przypadki z odbiorcą testowym; nie wymagać gotowego .5.
