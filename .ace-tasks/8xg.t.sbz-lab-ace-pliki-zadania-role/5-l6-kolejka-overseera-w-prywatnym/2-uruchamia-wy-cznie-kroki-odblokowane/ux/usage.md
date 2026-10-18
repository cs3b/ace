# Uruchamiać wyłącznie kroki odblokowane zależnościami — scenariusze użycia

## Interfejs

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Uruchamiać tylko subtaski, których zależności są spełnione. Wymóg wcześniejszego merge modelować przez zależność od kroku integracji, nie od samego końca implementacji.

Oczekiwany wynik: Zadanie B czeka na integrację A mimo ukończenia workera A, a po potwierdzeniu integracji staje się odblokowane.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Błąd, brak wyniku lub anulowanie wymaganego poprzednika nie są traktowane jako udane spełnienie zależności.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Wykorzystać istniejącą ścieżkę work-on i zadania _overseer. Decyzja o starcie należy do overseera; kolejność nie jest nowym runtime schedulerem. Potwierdzić wynik wymaganego kroku integracji; cancelled/skipped/archiwum bez dowodu wymaganego wyniku nie są takim potwierdzeniem, nawet jeśli ogólny sorter tasków pokazuje je inaczej.
Start dopiero po pełnym plannerze .3 i .5.1. Sprawdzić B oczekujące na merge A, B po potwierdzeniu integracji oraz brakujący/cykliczny poprzednik. Nie zmieniać przy tym ogólnych reguł ace-task ani wprowadzać guardów roli do narzędzi delegowania.
