---
id: 8xg.t.sbz.9.3
status: draft
priority: medium
created_at: "2026-10-17 18:54:31"
estimate: medium
dependencies: ["8xg.t.sbz.9.2", "8xg.t.sbz.0", "8xg.t.sbz.1", "8xg.t.sbz.2", "8xg.t.sbz.3", "8xg.t.sbz.4", "8xg.t.sbz.5", "8xg.t.sbz.6", "8xg.t.sbz.7", "8xg.t.sbz.8"]
tags: ["lab", "lab-l10", "file-based"]
parent: 8xg.t.sbz.9
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-lab/README.md", "ace-handbook/handbook/skills/as-release/SKILL.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md", ".ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/3-zamkn-program-na-podstawie-wyniku/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Zamknąć program na podstawie wyniku odbioru"
---

# Zamknąć program na podstawie wyniku odbioru

## Cel

Publicznie wydany zestaw instaluje się i wykonuje pełny proces w nowym labie. Ten subtask dostarcza następujący wycinek: Zamknąć program dopiero po udokumentowanym odbiorze nowego laba z RubyGems; zapisać wersje, rezultat oraz rzeczywiste ograniczenia.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

Zamknąć program dopiero po udokumentowanym odbiorze nowego laba z RubyGems; zapisać wersje, rezultat oraz rzeczywiste ograniczenia.

## Kryteria odbioru

- [ ] Końcowy zapis łączy wykonane kryteria L1–L10 z wynikami i wskazuje zaakceptowany zestaw paczek.
- [ ] Brak któregokolwiek wymaganego odbioru pozostawia program otwarty; liczba commitów, review albo sam status done workera nie zastępują celu.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Końcowy zapis łączy wykonane kryteria L1–L10 z wynikami i wskazuje zaakceptowany zestaw paczek.
- Scenariusz błędu / niepoprawnego wejścia: Brak któregokolwiek wymaganego odbioru pozostawia program otwarty; liczba commitów, review albo sam status done workera nie zastępują celu.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L10.3 / 8xg.t.sbz.9.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/2-sprawdzi-wie-y-lab-z/8xg.t.sbz.9.2-sprawdzi-wie-y-lab-z-rubygems.s.md), [L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md), [L3 / 8xg.t.sbz.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md), [L4 / 8xg.t.sbz.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md), [L5 / 8xg.t.sbz.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md), [L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md), [L7 / 8xg.t.sbz.6](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md), [L8 / 8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md), [L9 / 8xg.t.sbz.8](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
