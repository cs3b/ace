# Raportować gotowość lub braki overseerowi — scenariusze użycia

## Interfejs

Wejście: task i sekwencja ról. Wynik: worktree, assignmenty oraz .ace-local/coworker/ i raport gotowości.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Planner przekazuje przez ace-hitl gotowość: task, worktree, role i przygotowane assignmenty, albo konkretną listę braków.

Oczekiwany wynik: Overseer otrzymuje komplet do uruchomienia pierwszego kroku; nie musi sam komponować szczegółowego ace-assign.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Niepełna konfiguracja lub brak worktree nie są raportowane jako gotowe zlecenie i nie uruchamiają nieprzygotowanego coworkera.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
