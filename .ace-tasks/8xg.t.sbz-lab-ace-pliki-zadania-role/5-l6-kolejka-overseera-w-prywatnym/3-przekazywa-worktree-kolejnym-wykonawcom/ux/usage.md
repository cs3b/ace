# Przekazywać worktree kolejnym wykonawcom — scenariusze użycia

## Interfejs

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Overseer przydziela kolejne role do tego samego worktree zadania i pilnuje jednego aktywnego wykonawcy. Dostępność wynika z przydziałów i rzeczywistego stanu.

Oczekiwany wynik: Worker kończy, następnie startuje reviewer, potem integrator; dwa różne taski mogą korzystać z różnych worktree.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Zajęte worktree nie otrzymuje drugiego wykonawcy; nieznany stan nie oznacza wolnego zasobu ani pozwolenia na nadpisanie zmian.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Przydział odczytać z taska zarządzającego i sprawdzić obecny stan wykonawcy/worktree istniejącymi narzędziami. Zakończenie assignmentu i przekazanie pracy kończy poprzedni przydział; dopiero potem następna rola zaczyna w tym samym worktree.
Brak danych lub zaginiona sesja wymagają wyjaśnienia/wznowienia, nie uruchomienia drugiego agenta. Sprawdzić sekwencję worker/reviewer/integrator oraz równoległość dwóch różnych worktree. Regułę egzekwuje overseer, bez nowego rejestru lease, serwisu lub blokad nazw w ace-git-worktree.
