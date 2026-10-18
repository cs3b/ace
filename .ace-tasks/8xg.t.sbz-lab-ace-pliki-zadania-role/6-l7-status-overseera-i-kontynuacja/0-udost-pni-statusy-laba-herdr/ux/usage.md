# Udostępnić statusy laba Herdr i worktree — scenariusze użycia

## Interfejs

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Dostarczyć ace-herdr status pokazujący spaces/tabs/panes oraz ace-lab status czytający konfigurację i pliki. Widok worktree oprzeć na ukończonym k9y i obecnym ace-git-worktree list.

Oczekiwany wynik: Bez starego procesu właściciela laba widać konfigurację i lokalny stan; Herdr pokazuje rzeczywisty układ, a worktree zachowują skojarzenia z taskami.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Nieobecny runtime lub niepełna konfiguracja są oznaczone, a nie przedstawione jako pusty i gotowy lab. Nie dublować funkcji k9y.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

`ace-herdr status` zestawia istniejące list_workspaces/list_tabs/list_panes w czytelny układ; `ace-lab status` czyta obecną konfigurację/topologię i dostępne pliki. Status nie uruchamia usług ani nie wymaga przyszłego instalatora. Widok worktree wykorzystuje istniejące `ace-git-worktree list` (k9y), bez nowej implementacji tej funkcji.
Odbiór: przygotowana konfiguracja + dostępny Herdr, niedostępny Herdr i brak konfiguracji laba. Wynik rozróżnia pusty poprawny zbiór, brak konfiguracji i błąd źródła. Brak coworkera/overseera jest informacją, nie blokadą budowy tego liścia. Nie deklarować ich gotowości na podstawie samej topologii.
