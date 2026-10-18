# Review gotowości czterech torów po PR #379

Zakres: 8xg.t.sbz.1 (HITL), .2 (coworker), .5 (overseer), .6 (status/pi).
Przejrzano 17 liści i 4 rodziców; wszystkie 21 specyfikacji promowano przez
ace-task do pending / needs_review=false, po czym każdą odczytano przez show.
Pozostałych draftów programu nie promowano. L1 pozostaje done.

## Ustalenia i naprawy

- Zintegrowana podstawa: PR #379, commit 76bc3d4e8. Lokalne main po rebase
  zawiera tę zmianę; nie trzeba ponownie wykonywać L1.
- Jeden główny zakres może korzystać z jednego worktree; subtaski i role
  wykonuje się kolejno. Pośrednie PR-y odblokowują inne tory.
- HITL lokalny raport/pytanie poprzedza adresowanie i adaptery. Dostarczenie
  nie jest wynikiem assignmentu; retry zachowuje ID, odbiorca rozpoznaje duplikat.
- Start/drive coworkera można odebrać lokalnie, bez przyszłego plannera/ról/HITL.
  Integracja raportowania ma własne dependencies i pozostaje późniejszym krokiem.
- _overseer jest zwykłym ignorowanym folderem już obsługiwanym po L1. Pozostały
  zakres .5.0 to użycie przez rolę i sprawdzenie; żadnych nowych guardów ace-task.
- Proces .5.1 można przygotować przed plannerem; .5.2 nadal czeka na pełne .3.
  Reguły przydziałów należą do overseera, nie do nowego silnika kolejki.
- Statusy składowe działają na obecnych źródłach; nie czekają na instalator.
  Niedostępność jest jawna. Pi korzysta z istniejącego transportu, nie zastępczej usługi.
- Rozdzielono zakres lokalnych testów liści od późniejszych testów integracyjnych.
  Przykłady i doprecyzowania dodano także w usage każdego przeglądanego taska.

## Gotowe do rozpoczęcia

| ID | Nazwa |
|---|---|
| 8xg.t.sbz.1.0 | Obsłużyć raporty oraz prośby o odpowiedź |
| 8xg.t.sbz.2.0 | Startować z przygotowanej konfiguracji coworkera |
| 8xg.t.sbz.5.0 | Zapewnić prywatną nietrackowaną listę overseera |
| 8xg.t.sbz.6.0 | Udostępnić statusy laba Herdr i worktree |

Granice kontynuacji i integracji: execution-order.md. Pending określa gotowość
specyfikacji; nie zezwala na omijanie zależności liści.

## Weryfikacja wykonana

- Rebase origin/main: bez konfliktów; 4 wcześniejsze commity już upstream,
  retrospektywa zachowana z równoważnym patchem (git range-diff).
- bundle check: OK.
- bin/ace-test ace-task fast: 540 testów, 1704 asercje, 0 failures/errors,
  2 skipped. Raport: .ace-local/test/reports/task/ce1eff55-c20a-44fe-9efc-58e1c6c810ea/.
- Walidacja 53 specyfikacji: bez cykli również po uwzględnieniu odbioru rodziców;
  dependencies przejrzanych tasków niezmienione, pliki bundle istnieją,
  klucze bundle mają kolejność presets/files/commands.
- Odczyt CLI wszystkich 21 promocji; dokładnie cztery powyższe liście mają
  status pending i wszystkich bezpośrednich poprzedników done.
- git diff --check: OK. Zmieniono tylko backlog i jego dokumentację.

To review specyfikacji, nie niezależny review kodu ani odbiór nowych funkcji.
Nie uruchamiano pełnej suity kodu dla zmian specyfikacji. Brak nierozstrzygniętych
pytań produktowych w tym zakresie; szczegóły implementacji ustala JIT plan
przy zachowaniu zapisanych interfejsów, właścicieli i kryteriów odbioru.

Zastosowane workflow: as-git-rebase, as-task-review, as-git-commit.
