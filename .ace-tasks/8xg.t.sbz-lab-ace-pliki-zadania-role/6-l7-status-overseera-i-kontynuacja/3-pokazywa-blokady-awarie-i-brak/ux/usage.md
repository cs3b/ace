# Pokazywać blokady awarie i brak danych — scenariusze użycia

## Interfejs

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Status i instrukcje rozróżniają pracę trwającą, zakończoną, oczekującą na decyzję, przerwaną oraz brak informacji. Zachowują opis przeszkody i następnego działania.

Oczekiwany wynik: Overseer widzi, na czyją decyzję lub jaki wynik czeka, i może kontynuować po usunięciu przeszkody.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Niedostępny forge, agent lub plik nie jest sukcesem ani sygnałem do uruchomienia zastępczej pracy na tym samym worktree.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Stany widoku: trwa praca, wynik ukończony, oczekiwanie na decyzję, przerwanie, brak danych. To interpretacja istniejących źródeł, nie nowe statusy ace-task. Pokazać konkretny task/assignment, przyczynę i następne działanie.
Test utraty forge, procesu i pliku podczas pracy oraz powrotu źródła. Odświeżenie/wznowienie nie tworzy nowego wykonawcy. Niespójność między raportem a assignmentem pozostaje jawna do sprawdzenia; widok sam niczego nie zamyka.
