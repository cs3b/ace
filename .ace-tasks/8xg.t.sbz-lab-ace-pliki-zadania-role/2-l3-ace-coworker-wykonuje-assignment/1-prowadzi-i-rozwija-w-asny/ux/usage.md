# Prowadzić i rozwijać własny ace-assign — scenariusze użycia

## Interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Coworker prowadzi istniejący ace-assign do końca. Po uruchomieniu może dodawać kroki, naprawy i sprawdzenia w granicach celu i reguł roli.

Oczekiwany wynik: Dodane sprawdzenie zostaje częścią tego samego planu, jest wykonane i widoczne przez ace-assign.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Dodanie kroku nie tworzy drugiej kolejki i nie omija ograniczeń roli ani zależności nadzorowanych przez overseera.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
