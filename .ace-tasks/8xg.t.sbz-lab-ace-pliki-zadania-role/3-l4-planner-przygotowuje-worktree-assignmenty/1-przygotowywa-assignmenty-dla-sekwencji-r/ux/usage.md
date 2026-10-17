# Przygotowywać assignmenty dla sekwencji ról — scenariusze użycia

## Interfejs

Wejście: task i sekwencja ról. Wynik: worktree, assignmenty oraz .ace-local/coworker/ i raport gotowości.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Planner przygotowuje assignmenty dla całej znanej sekwencji od razu, korzystając z konfiguracji projektu i ról; określa oczekiwany wynik każdego zlecenia.

Oczekiwany wynik: Worker i reviewer dostają różne procesy, dopasowane do tego samego taska; kolejność i warunki odbioru są jawne.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak wymaganego procesu projektu/roli jest raportowany, a planner nie podstawia procesu innej roli bez podstaw.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
