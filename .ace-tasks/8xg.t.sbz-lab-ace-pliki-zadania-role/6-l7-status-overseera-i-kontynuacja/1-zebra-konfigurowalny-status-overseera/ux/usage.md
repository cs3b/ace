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
