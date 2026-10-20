# Odbiór L9 z udokumentowanymi ograniczeniami — 2026-10-20

Decyzja operatora programu (przy fali 4): liście `.8.0`–`.8.3` oraz grupa `.8`
zostają zaliczone z jawnym zapisem zakresu wykonanego lokalnie i zakresu
świadomie niewykonanego, ponieważ wymaga on realnych kont, sieci/SSH, żywego
pi E2E i prawdziwych list issue u providerów — poza testowalnym zakresem
programu. Zapis powstaje przed startem L10 (`.9.0` ma zależność `8xg.t.sbz.8`).

## Zakres wykonany (dowody w main, merge #393 = `346b26cb`)

- Pełny cykl kolejki overseera na prawdziwym CLI, łącznie z wznowieniem po
  awaryjnym ucięciu procesu: 
  `ace-overseer/test/fast/integration/queue_cycle_integration_test.rb`
  (fala 3, review `review-8xirsk` approve).
- Sekwencja przygotowania i wykonania w realnym CLI przygotowana przez fale
  2–3: planner/worktree, assignmenty, role worker/spec/reviewer, raporty,
  eskalacja HITL (testy pakietów ace-coworker, ace-overseer, ace-hitl;
  suite 52 pakiety / 43 622 asercje / 0 failures — ostatni pełny przebieg
  przed merge #393).
- Instalacja świeżego laba i `project add` z weryfikacją ról/narzędzi
  (ace-lab `install`, `project_add`, `verify` — tri-state probe, precedente
  route/config/command) — pokrywa lokalną część macierzy instalacji `.8.3`.
- Izolacja zadań i sekwencja ról: osobne worktree, prywatne drzewo
  `_overseer`, brak współdzielenia stanu (testy L5–L7, fale 1–3).

## Zakres świadomie niewykonany (poza zakresem programu)

- `.8.0` — pełna sekwencja na realnych kontach operatora (network, SSH).
- `.8.1` — awarie/wznowienia na żywym pi i u prawdziwych providerów
  (E2E poza lokalnym CLI); lokalny odpowiednik (crash-cut resume) wykonany.
- `.8.2` — izolacja mierzona na realnych, równoległych środowiskach.
- `.8.3` — macierz forge × instalacja wobec prawdziwych forges i kont;
  lokalnie sprawdzono ścieżkę github-cs3b.

Powyższe pozostaje jawne również w końcowym zapisie programu (`.9.3`):
liczba commitów ani review nie zastępuje odbioru; odbiór L9 jest warunkowy
i opiera się na decyzji operatora z tego dnia, nie na wykonaniu scenariuszy
realnych.
