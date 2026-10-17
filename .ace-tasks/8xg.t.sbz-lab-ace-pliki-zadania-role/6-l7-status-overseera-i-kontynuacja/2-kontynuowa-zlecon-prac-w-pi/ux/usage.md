# Kontynuować zleconą pracę w pi — scenariusze użycia

## Interfejs

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Mechanizmy w pi przyjmują wiadomości podczas pracy i oczekiwania oraz wznawiają zlecony proces. Po restarcie overseer czyta _overseer i aktualną prawdę o projekcie.

Oczekiwany wynik: Raport budzi oczekującego overseera; po restarcie kontynuuje on ten sam proces i istniejące assignmenty.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Powtórzone powiadomienia nie tworzą drugiej egzekucji; brak nowej zleconej pracy nie prowadzi do samodzielnego szukania kolejnych zadań.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
