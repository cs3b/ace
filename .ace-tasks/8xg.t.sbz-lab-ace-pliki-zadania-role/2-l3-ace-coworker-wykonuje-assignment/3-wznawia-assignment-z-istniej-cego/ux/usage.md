# Wznawiać assignment z istniejącego worktree — scenariusze użycia

## Interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Po przerwaniu odczytać istniejący assignment, task i rzeczywisty stan tego samego worktree; kontynuować niedokończoną pracę.

Oczekiwany wynik: Restart w połowie zlecenia zachowuje ukończone kroki i lokalne zmiany oraz wraca do pracy pozostałej do wykonania.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Jeżeli nie wiadomo, czy merge/publikacja zaszły, sprawdzić ich stan lub zgłosić blokadę zamiast ślepo wykonywać je ponownie; nie tworzyć nowego taska/worktree.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
