# Weryfikacja: proces wykonania w subtaskach (8xg.t.sbz.5.1)

Data: 2026-10-18. Demo na izolowanym korzeniu `/tmp/ace-l6-demo/.ace-tasks`
(`--root`), żeby nie zanieczyścić prawdziwej listy _overseer.

## Drzewo zarządzające z cyklem życia

```
$ bin/ace-task create "Manage: deliver feature A" --in _overseer --root ...   # 8xh.t.grm
$ bin/ace-task create "Prepare worktree and assignments for feature A" --child-of 8xh.t.grm   # .0
$ bin/ace-task create "Implement feature A" --child-of 8xh.t.grm                              # .1
$ bin/ace-task create "Review feature A"    --child-of 8xh.t.grm                              # .2
$ bin/ace-task create "Integrate feature A" --child-of 8xh.t.grm                              # .3
$ bin/ace-task update 8xh.t.grm --set project_task=<ref zadania projektowego>
$ bin/ace-task update 8xh.t.grm.1 --set dependencies=8xh.t.grm.0   # itd. .2←.1, .3←.2
```

Referencje worktree/assignmentów dopisywane tylko po rzeczywistym
przygotowaniu przez plannera (tu celowo ich brak — planner to L4).

## Przykład dwóch zadań: B zależy od integracji A

```
$ bin/ace-task update 8xh.t.grn.0 --set dependencies=8xh.t.grm.3
$ bin/ace-task show 8xh.t.grn.0
○ 8xh.t.grn.0  Implement feature B
  status: pending  |  depends: 8xh.t.grm.3  |  parent: 8xh.t.grn
```

Sekwencja stanów (dowód):

1. `.0 done`, `.1 done` (impl A ukończona), `.2/.3 pending`:
   ```
   $ bin/ace-task show 8xh.t.grm
   ○ 8xh.t.grm  Manage: deliver feature A     ← rodzic NIE jest zamknięty
     ✓ .0 Prepare   ✓ .1 Implement
     ○ .2 Review    ○ .3 Integrate
   ```
   Implementacja A skończona, ale `grn.0` (B) nadal czeka na `.3`.

2. `.2 done`, `.3 done` (integracja potwierdzona):
   ```
   Info: Archived parent task 8xh.t.grm because all subtasks are terminal.
   ```
   `grn.0` rozwiązane jako odblokowane. Uwaga: auto-archiwizacja rodzica
   zadziałała, bo demo-root nie jest w repo Git (ace-task pyta Git o rzeczywistą
   ścieżkę); w labie na ścieżce gitignored completed task nie jest
   auto-archiwizowany — zgodnie z docs/lab-flow.md.

## Scenariusz błędu — anulowany poprzednik

```
$ bin/ace-task update 8xh.t.gsc.0 --set status=cancelled      # Integrate C
$ bin/ace-task update 8xh.t.gsf --set dependencies=8xh.t.gsc.0
```

Zależność od anulowanego kroku nie jest spełnieniem: reguła należy do
procesu overseera (workflow `wfi://overseer/queue`, Contract rule 2:
„error, no result, or cancellation ... archived-without-proof predecessors
are not satisfaction”). Sorter ogólny nie jest dowodem — overseer sprawdza
status i dowód wymaganego wyniku integracji.

## Samo zakończenie implementacji nie zamyka taska zarządzającego

Widok w kroku 1 powyżej: rodzic `8xh.t.grm` pozostał `pending` (`○`) przy
ukończonej implementacji, dopóki review i integracja były otwarte.

## Wynik

- Instrukcja: `ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md`
  (rozwiązywana przez `ace-bundle wfi://overseer/queue`; ace-lint: pass).
- Przykład: powyższe drzewo (worked example także w sekcji workflow).
- Dokumentacja pakietu: `ace-overseer/docs/usage.md`, `ace-overseer/README.md`.
- Ten liść zapisuje/odczytuje proces; uruchamianie wykonawców należy do
  .5.2–.5.4 (zablokowane na L4).
