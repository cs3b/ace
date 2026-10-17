# Przetwarzać raporty i kontynuować kolejkę — scenariusze użycia

## Interfejs

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Powiązać raport z właściwym taskiem i krokiem, zapisać go w prywatnym zadaniu zarządzającym, następnie uruchomić kolejny odblokowany krok lub obsłużyć błąd.

Oczekiwany wynik: Jeden realny obieg planner → worker → raport → reviewer działa już w L6; wyniki aktualizują właściwy task nadrzędny.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Powtórzony raport nie uruchamia następnego kroku dwa razy; raport niepasujący do zlecenia lub eskalacja nie są traktowane jako sukces.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
