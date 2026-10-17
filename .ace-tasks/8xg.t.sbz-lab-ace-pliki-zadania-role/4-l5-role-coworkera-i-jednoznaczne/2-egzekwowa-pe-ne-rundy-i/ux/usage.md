# Egzekwować pełne rundy i limit review — scenariusze użycia

## Interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Minimum 3 pełne rundy; ostatnie 2 kolejne bez potwierdzonych High/Critical i brak wcześniejszych nierozwiązanych High/Critical. Maksimum 10 pełnych rund. Diff review nie zwiększa licznika.

Oczekiwany wynik: Sekwencje czysta/czysta/czysta oraz błąd/czysta/czysta kończą po rundzie 3. Spełnienie reguły w rundzie 10 kończy sukcesem.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak akceptacji po rundzie 10 eskaluje; przerwane raporty nie liczą się jako czyste, High/Critical zeruje serię, restart nie zeruje licznika ani historii ustaleń.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
