---
id: 8xg.t.sbz.9
status: draft
priority: high
created_at: "2026-10-17 18:53:37"
estimate: large
dependencies: []
tags: ["lab", "lab-l10", "file-based"]
parent: 8xg.t.sbz
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-lab/README.md", "ace-handbook/handbook/skills/as-release/SKILL.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md", ".ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "L10: Wydanie gemów i odbiór nowego laba z RubyGems"
---

# L10: Wydanie gemów i odbiór nowego laba z RubyGems

## Cel i zachowanie

Publicznie wydany zestaw instaluje się i wykonuje pełny proces w nowym labie.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

## Subtaski i kolejność

- [8xg.t.sbz.9.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/0-przygotowa-sp-jny-zestaw-wersji/8xg.t.sbz.9.0-przygotowa-sp-jny-zestaw-wersji-do-wydania.s.md) — Po przyjęciu L9 przygotować spójny zestaw wersji gemów, CHANGELOG, minimalne zależności i kolejność publikacji.
- [8xg.t.sbz.9.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/1-opublikowa-gemy-w-kolejno-ci/8xg.t.sbz.9.1-opublikowa-gemy-w-kolejno-ci-zale-no.s.md) — Opublikować uzgodniony zestaw gemów w kolejności zależności, zapisując rzeczywisty wynik dla każdej paczki.
- [8xg.t.sbz.9.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/2-sprawdzi-wie-y-lab-z/8xg.t.sbz.9.2-sprawdzi-wie-y-lab-z-rubygems.s.md) — W nowym środowisku użyć wyłącznie wydanych gemów: gem install ace-lab → ace-lab install → ace-lab project add → pełna sekwencja zadania → statusy.
- [8xg.t.sbz.9.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/3-zamkn-program-na-podstawie-wyniku/8xg.t.sbz.9.3-zamkn-program-na-podstawie-wyniku-odbioru.s.md) — Zamknąć program dopiero po udokumentowanym odbiorze nowego laba z RubyGems; zapisać wersje, rezultat oraz rzeczywiste ograniczenia.

## Kryteria odbioru

- [ ] Manifest wskazuje dokładne wersje, źródło i artefakty; instalacja przygotowanych paczek rozwiązuje wymagane zależności.
- [ ] Każda wymagana wersja jest dostępna w RubyGems i odpowiada zaakceptowanemu artefaktowi.
- [ ] Potwierdzone wersje i ścieżki pochodzą z RubyGems, a cały proces działa bez checkoutowych binstubów i lokalnych override.
- [ ] Końcowy zapis łączy wykonane kryteria L1–L10 z wynikami i wskazuje zaakceptowany zestaw paczek.

## Weryfikacja i scenariusze błędów

- Niezgodny floor lub paczka spoza przyjętego zestawu zatrzymuje przygotowanie wydania; samo przygotowanie nie oznacza publikacji.
- Przy częściowym niepowodzeniu lub utracie odpowiedzi sprawdzić dostępne wersje i dopiero kontynuować brakujące publikacje; nie deklarować pełnego release bez potwierdzeń.
- Nieopublikowana zależność, niegotowa instalacja albo nieukończone zadanie oznaczają niezaliczony odbiór, nie przejście na źródła lokalne.
- Brak któregokolwiek wymaganego odbioru pozostawia program otwarty; liczba commitów, review albo sam status done workera nie zastępują celu.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
