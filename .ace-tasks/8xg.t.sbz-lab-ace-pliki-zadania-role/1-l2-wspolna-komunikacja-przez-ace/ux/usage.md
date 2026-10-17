# L2: Wspólna komunikacja przez ace-hitl i adaptery — scenariusze użycia

## Interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Ten sam interfejs ace-hitl obsługuje raport zakończenia/błędu oraz pytanie lub eskalację. Tylko prośba wymagająca decyzji oczekuje na odpowiedź.

Oczekiwany wynik: Raport work done trafia do overseera bez oczekiwania na Reply; pytanie pozostaje oczekujące i może wstrzymać assignment.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak odpowiedzi na pytanie nie jest zgodą ani sukcesem; raport bez odpowiedzi nie staje się zablokowanym pytaniem.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
