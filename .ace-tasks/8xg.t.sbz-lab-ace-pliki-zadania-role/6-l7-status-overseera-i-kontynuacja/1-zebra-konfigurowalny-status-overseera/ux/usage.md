# Zebrać konfigurowalny status overseera — scenariusze użycia

## Interfejs

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: ace-overseer status zbiera konfigurowalne źródła: PR/issues GitHub lub Forgejo, projektowy ace-task, _overseer, worktree, Herdr i postęp coworkerów.

Oczekiwany wynik: Overseer z jednego widoku rozpoznaje trwające kroki, gotową pracę, zależności i dostępne zasoby; wyłączenie źródła w konfiguracji jest respektowane.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Awaria źródła jest pokazana obok dostępnych wyników; brak danych nie staje się potwierdzeniem wolnego worktree lub zakończonego zadania.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Rozszerzyć obecny `ace-overseer status`, nie tworzyć konkurencyjnego dashboardu. Konfiguracja wybiera istniejące źródła: forge PR/issues, ace-task projektu/_overseer, worktree, Herdr, coworker. Każde źródło pokazuje dane lub jawny błąd/wyłączenie. Źródła korzystają z interfejsów ich właścicieli.
Test konfiguracji z wyłączonym forge oraz awarii jednego źródła przy działających pozostałych. Pokazać pochodzenie informacji; nie zapisywać trwałej kopii kolejki. Nieznany przydział nie oznacza wolnego worktree. Wymaga .5 i .6.0, nie blokuje wcześniejszej pracy nad .6.0.
