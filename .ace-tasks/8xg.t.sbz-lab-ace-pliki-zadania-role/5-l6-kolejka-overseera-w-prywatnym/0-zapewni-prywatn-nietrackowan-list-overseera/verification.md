# Weryfikacja: prywatna nietrackowana lista overseera (8xg.t.sbz.5.0)

Data: 2026-10-18. Repo: /Users/mc/Ps/ace (main, po PR #379).

## Przebieg poprawny — zapis i wznowienie

Przygotowanie folderu (raz, konfiguracja projektu; wpis już istnieje):

- `mkdir -p .ace-tasks/_overseer`
- `.gitignore:47` zawiera `/.ace-tasks/_overseer/`

Pełny obieg na żywo (każde wywołanie to osobny proces — wznowienie przez
ponowny odczyt):

```
$ bin/ace-task create "L6 verification: private overseer list round-trip" --in _overseer --tags l6-verify
Created task 8xh.t.gr4
  Path: .ace-tasks/_overseer/8xh.t.gr4-l6-verification-private-overseer-list/...s.md

$ bin/ace-task list --in _overseer
○   8xh.t.gr4  L6 verification: private overseer list round-trip [l6-verify] (_overseer)
Tasks: ○ 1 • 1 of 461 — archive 437 | maybe 12 | next 11 | overseer 1

$ bin/ace-task show 8xh.t.gr4
○ 8xh.t.gr4 ... status: pending | folder: _overseer

$ bin/ace-task update 8xh.t.gr4 --set status=progress   # → status: progress
$ bin/ace-task update 8xh.t.gr4 --set status=done        # → list: ✓

$ bin/ace-task list          # widok główny: zadania _overseer NIE są w root view
```

Git nie widzi listy jako plików do commitu:

```
$ git check-ignore -v .ace-tasks/_overseer/8xh.t.gr4-*/...s.md
.gitignore:47:/.ace-tasks/_overseer/	...

$ git status --short -- .ace-tasks/_overseer | wc -l
0
```

Zadanie weryfikacyjne usunięte po teście (lista wróciła do stanu pustego
folderu). Folder `.ace-tasks/_overseer/` pozostaje przygotowany.

## Scenariusz błędu — brak ukrytej drugiej listy

- Widok główny `ace-task list` i `--in _overseer` są rozłączne; licznik
  `overseer 1` pokazuje osobne źródło. Zapis/odczyt w złej lokalizacji nie
  tworzy drugiej listy — jedynym miejscem jest `.ace-tasks/_overseer/`.
- Reguła „coworker raportuje przez wiadomość, nie zapisuje listy” jest
  instrukcją roli — jest częścią workflow
  `ace-bundle wfi://overseer/queue` (Contract rules, pkt 1 i 5). Zgodnie z
  review NIE dodano blokad nazw/ścieżek do ace-task, ace-assign ani
  ace-git-worktree.

## Wynik

Kryteria odbioru liścia spełnione na istniejącym zachowaniu ace-task (PR #379)
plus instrukcja roli w `ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md`.
Nowe funkcje ace-task nie były wymagane i nie powstały.
