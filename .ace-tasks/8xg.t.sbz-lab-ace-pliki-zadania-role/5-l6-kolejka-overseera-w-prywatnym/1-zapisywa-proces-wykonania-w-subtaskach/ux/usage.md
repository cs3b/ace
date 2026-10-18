# Zapisywać proces wykonania w subtaskach — scenariusze użycia

## Interfejs

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Otrzymany zakres pracy zapisać jako task zarządzający z subtaskami przygotowania, implementacji, review, integracji i kolejnych kroków wymaganych przez projekt.

Oczekiwany wynik: Drzewo pokazuje kolejność i powiązania z zadaniami projektowymi, worktree oraz assignmentami ról.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Samo zakończenie implementacji nie zamyka taska zarządzającego, gdy pozostaje review, integracja lub inny wymagany krok.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Dostarczyć instrukcję i przykład: zwykły task zarządzający w _overseer, subtaski przygotowanie → implementacja → review → integracja, jawne dependencies oraz referencje do taska projektowego. Worktree/assignment dopisać po ich rzeczywistym przygotowaniu, nie fabrykować referencji przed plannerem.
Ten liść zapisuje i odczytuje proces, nie uruchamia jeszcze wykonawców. Przykład dwóch zadań: B zależy od integracji A, nie od końca workera A. Sprawdzić zależność między folderami i niezakończenie rodzica przed review/integracją. Przygotowanie szczegółowych assignmentów nadal należy do plannera; subagenci do przeglądu procesu są dozwoleni.
