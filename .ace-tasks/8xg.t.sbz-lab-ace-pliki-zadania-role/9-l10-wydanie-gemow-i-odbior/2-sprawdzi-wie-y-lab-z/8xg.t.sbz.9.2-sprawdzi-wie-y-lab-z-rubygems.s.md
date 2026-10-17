---
id: 8xg.t.sbz.9.2
status: draft
priority: medium
created_at: "2026-10-17 18:54:30"
estimate: medium
dependencies: ["8xg.t.sbz.9.1"]
tags: ["lab", "lab-l10", "file-based"]
parent: 8xg.t.sbz.9
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-lab/README.md", "ace-handbook/handbook/skills/as-release/SKILL.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md", ".ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/2-sprawdzi-wie-y-lab-z/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Sprawdzić świeży lab z RubyGems"
---

# Sprawdzić świeży lab z RubyGems

## Cel

Publicznie wydany zestaw instaluje się i wykonuje pełny proces w nowym labie. Ten subtask dostarcza następujący wycinek: W nowym środowisku użyć wyłącznie wydanych gemów: gem install ace-lab → ace-lab install → ace-lab project add → pełna sekwencja zadania → statusy.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

W nowym środowisku użyć wyłącznie wydanych gemów: gem install ace-lab → ace-lab install → ace-lab project add → pełna sekwencja zadania → statusy.

## Kryteria odbioru

- [ ] Potwierdzone wersje i ścieżki pochodzą z RubyGems, a cały proces działa bez checkoutowych binstubów i lokalnych override.
- [ ] Nieopublikowana zależność, niegotowa instalacja albo nieukończone zadanie oznaczają niezaliczony odbiór, nie przejście na źródła lokalne.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Potwierdzone wersje i ścieżki pochodzą z RubyGems, a cały proces działa bez checkoutowych binstubów i lokalnych override.
- Scenariusz błędu / niepoprawnego wejścia: Nieopublikowana zależność, niegotowa instalacja albo nieukończone zadanie oznaczają niezaliczony odbiór, nie przejście na źródła lokalne.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L10.2 / 8xg.t.sbz.9.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/1-opublikowa-gemy-w-kolejno-ci/8xg.t.sbz.9.1-opublikowa-gemy-w-kolejno-ci-zale-no.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
