---
id: 8xg.t.sbz.3
status: draft
priority: high
created_at: "2026-10-17 18:53:34"
estimate: medium
dependencies: []
tags: ["lab", "lab-l4", "file-based"]
parent: 8xg.t.sbz
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-assign/README.md", "ace-git-worktree/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md", ".ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "L4: Planner przygotowuje worktree, assignmenty i start coworkera"
---

# L4: Planner przygotowuje worktree, assignmenty i start coworkera

## Cel i zachowanie

Overseer deleguje przygotowanie, a role otrzymują kompletny kontekst pracy.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

Wejście: task i sekwencja ról. Wynik: worktree, assignmenty oraz .ace-local/coworker/ i raport gotowości.

## Subtaski i kolejność

- [8xg.t.sbz.3.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/0-przyjmowa-zlecenie-przygotowania-i-zapewnia/8xg.t.sbz.3.0-przyjmowa-zlecenie-przygotowania-i-zapewnia-worktree.s.md) — Planner jako coworker przyjmuje task i oczekiwaną sekwencję ról; odnajduje lub przygotowuje jedno właściwe worktree zadania.
- [8xg.t.sbz.3.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/1-przygotowywa-assignmenty-dla-sekwencji-r/8xg.t.sbz.3.1-przygotowywa-assignmenty-dla-sekwencji-r-l.s.md) — Planner przygotowuje assignmenty dla całej znanej sekwencji od razu, korzystając z konfiguracji projektu i ról; określa oczekiwany wynik każdego zlecenia.
- [8xg.t.sbz.3.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/2-przygotowywa-konfiguracj-startow-wykonawc-w/8xg.t.sbz.3.2-przygotowywa-konfiguracj-startow-wykonawc-w.s.md) — Przygotować w .ace-local/coworker/ kontekst uruchomienia każdej zaplanowanej roli: instrukcje, prompt, odwołanie do assignmentu, adres i reguły raportowania.
- [8xg.t.sbz.3.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/3-raportowa-gotowo-lub-braki-overseerowi/8xg.t.sbz.3.3-raportowa-gotowo-lub-braki-overseerowi.s.md) — Planner przekazuje przez ace-hitl gotowość: task, worktree, role i przygotowane assignmenty, albo konkretną listę braków.

## Kryteria odbioru

- [ ] Ponowne przygotowanie tego samego zadania używa jego istniejącego worktree, zachowując pracę i powiązanie z taskiem.
- [ ] Worker i reviewer dostają różne procesy, dopasowane do tego samego taska; kolejność i warunki odbioru są jawne.
- [ ] Kolejna rola startuje z własnym kontekstem w worktree zadania; dane assignmentu są referencją do ace-assign.
- [ ] Overseer otrzymuje komplet do uruchomienia pierwszego kroku; nie musi sam komponować szczegółowego ace-assign.

## Weryfikacja i scenariusze błędów

- Istniejący aktywny wykonawca lub niepasujące worktree powodują zgłoszenie konfliktu do overseera, a nie nadpisanie pracy.
- Brak wymaganego procesu projektu/roli jest raportowany, a planner nie podstawia procesu innej roli bez podstaw.
- Przygotowanie kolejnej roli nie nadpisuje bieżącego stanu aktywnego drivera ani nie przenosi sekretów do taska.
- Niepełna konfiguracja lub brak worktree nie są raportowane jako gotowe zlecenie i nie uruchamiają nieprzygotowanego coworkera.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
