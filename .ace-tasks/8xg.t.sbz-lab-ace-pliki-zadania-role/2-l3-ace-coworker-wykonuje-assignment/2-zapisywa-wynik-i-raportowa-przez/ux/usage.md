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
