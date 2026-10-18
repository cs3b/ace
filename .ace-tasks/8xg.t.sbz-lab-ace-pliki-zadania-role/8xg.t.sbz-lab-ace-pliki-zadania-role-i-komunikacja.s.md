---
id: 8xg.t.sbz
status: draft
priority: critical
created_at: "2026-10-17 18:53:19"
estimate: large
dependencies: []
tags: [lab, program, file-based]
title: "Lab ACE: pliki, zadania, role i komunikacja"
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/backlog-map.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
---

# Lab ACE: pliki, zadania, role i komunikacja

## Cel i rezultat

Dostarczyć prosty lab ACE oparty na plikach, prywatnych zadaniach overseera,
assignmentach coworkerów i wspólnym ace-hitl z adapterami. Cel końcowy:
`gem install ace-lab` → `ace-lab install` → `ace-lab project add` → pełna
sekwencja przygotowania, implementacji, review i integracji → statusy.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Główne taski

| Plan | ID | Rezultat / właściciel zakresu |
|---|---|---|
| L1 | [8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md) | Uporządkować odpowiedzialności i usunąć stary model laba |
| L2 | [8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md) | Wspólna komunikacja przez ace-hitl i adaptery |
| L3 | [8xg.t.sbz.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md) | Ace-coworker wykonuje assignment do końca lub zgłasza błąd |
| L4 | [8xg.t.sbz.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md) | Planner przygotowuje worktree, assignmenty i start coworkera |
| L5 | [8xg.t.sbz.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md) | Role coworkera i jednoznaczne reguły ukończenia |
| L6 | [8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md) | Kolejka overseera w prywatnym ace-task |
| L7 | [8xg.t.sbz.6](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md) | Status overseera i kontynuacja zleconej pracy w pi |
| L8 | [8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md) | Instalacja nowego laba i dodawanie projektu |
| L9 | [8xg.t.sbz.8](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md) | Pełny przepływ i scenariusze awarii przed publikacją |
| L10 | [8xg.t.sbz.9](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md) | Wydanie gemów i odbiór nowego laba z RubyGems |

Kolejność określają konkretne dependencies liści i [fale pracy](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).
Po L1 równolegle ruszają HITL, podstawy coworkera, prywatne drzewo overseera
i statusy. Role poprzedzają pełne przygotowanie assignmentów przez plannera.
Pierwszy pełny obieg zamyka L6; następnie równolegle rozwijamy status/pi i instalację.
L9 odbiera cały zestaw przed publikacją; L10 wydaje gemy i sprawdza nowy lab.

## Kryteria zamknięcia programu

- [ ] Wszystkie zakresy L1–L10 są odebrane z rzeczywistymi wynikami.
- [ ] Overseer prowadzi wyłącznie swoje prywatne zadania i nie ma drugiego silnika kolejki.
- [ ] Planner przygotowuje zadanie, role realizują własne assignmenty, HITL dostarcza raporty i Reply.
- [ ] Reviewer sam naprawia i spełnia regułę minimum 3 / ostatnie 2 czyste / maksimum 10 pełnych rund.
- [ ] Restart i błędy zachowują pracę, a jeden task nie ma dwóch aktywnych wykonawców w worktree.
- [ ] Test całego przepływu przechodzi przed publikacją oraz osobno na wydanych gemach w nowym labie.

## Zależności, testy i domyślne decyzje

Rodzic nie zależy od własnych dzieci w polu dependencies; ich zakończenie jest
warunkiem odbioru programu. Powiązania między etapami i subtaskami są zapisane
w ich frontmatter. To backlog implementacyjny, nie aktywna kolejka _overseer.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

Hermes pozostaje adapterem; Nervus i rozbudowa proaktywności są poza zakresem.
Nie migrujemy istniejącego laba przez instalator ani nie budujemy nowych VM.
Nie tworzymy journala, brokera autoryzacji mutacji ani dodatkowego cache'u stanu.
Stan po review 2026-10-18: L1 i jego dzieci są done po PR #379; grupy 8xg.t.sbz.1, .2, .5, .6 wraz z dziećmi mają gotowe specyfikacje (pending). Pozostałe drafty wymagają osobnego review. Pending nie oznacza wykonania produktu ani spełnienia dependencies.

## Materiały i zastąpienie poprzedniego programu

[Mapa pełnego drzewa i zastąpień](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/backlog-map.md).
Stare zadania otrzymują powód, wskazanie następców, status cancelled i archiwizację.
Istniejące rezultaty pozostają do wykorzystania; ukończony k9y, eksperyment ig5,
niezależne zgłoszenia błędów i wcześniejsze archiwum pozostają niezmienione.
