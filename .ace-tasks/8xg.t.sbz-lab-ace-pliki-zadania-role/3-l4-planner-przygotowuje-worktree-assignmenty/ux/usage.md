# L4: Planner przygotowuje worktree, assignmenty i start coworkera — scenariusze użycia

## Interfejs

Wejście: task i sekwencja ról. Wynik: worktree, assignmenty oraz .ace-local/coworker/ i raport gotowości.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Planner jako coworker przyjmuje task i oczekiwaną sekwencję ról; odnajduje lub przygotowuje jedno właściwe worktree zadania.

Oczekiwany wynik: Ponowne przygotowanie tego samego zadania używa jego istniejącego worktree, zachowując pracę i powiązanie z taskiem.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Istniejący aktywny wykonawca lub niepasujące worktree powodują zgłoszenie konfliktu do overseera, a nie nadpisanie pracy.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
