# Zapewnić prywatną nietrackowaną listę overseera — scenariusze użycia

## Interfejs

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Zapewnić lokalną listę ace-task --in _overseer zarządzaną wyłącznie przez jej overseera, poza Git i odrębną od tasków projektowych.

Oczekiwany wynik: Po zapisie i wznowieniu lista jest dostępna dla właściciela; git status nie pokazuje jej jako plików do commitu.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Coworker raportuje przez wiadomość i nie zapisuje do listy overseera; odczyt/zapis złej lokalizacji nie tworzy ukrytej drugiej listy.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

PR #379 już dostarczył zwykłą ignorowaną `.ace-tasks/_overseer/` i ogólne zachowanie ace-task. Pozostały zakres tego liścia to przygotowanie/udokumentowanie użycia przez rolę overseera i weryfikacja tego przepływu, nie nowe funkcje ace-task. Utworzenie folderu i wpisu Gitignore odbywa się w konfiguracji projektu; docelowy instalator konsumuje to w .7.
Użyć `ace-task create ... --in _overseer`, show/update/list i ponownego odczytu po wznowieniu. Wykazać Gitignore i brak zmian trackowanych. Reguła „coworker nie zapisuje listy” jest instrukcją roli; nie dodawać blokad nazw/ścieżek do ace-task, ace-assign ani ace-git-worktree. Subagenci mogą analizować i weryfikować plan; overseer pozostaje właścicielem jego zapisu. Brak HITL/coworkera nie blokuje lokalnego odbioru tego liścia.
