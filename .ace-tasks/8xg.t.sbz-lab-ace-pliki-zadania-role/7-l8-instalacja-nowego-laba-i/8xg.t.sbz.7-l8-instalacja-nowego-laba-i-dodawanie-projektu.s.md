---
id: 8xg.t.sbz.7
status: done
priority: high
created_at: "2026-10-17 18:53:36"
estimate: large
dependencies: []
tags: [lab, lab-l8, file-based]
parent: 8xg.t.sbz
needs_review: true
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-lab/docs/usage.md, ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md, ace-hitl/docs/usage.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/3-ace-lab-project-add-step/8xg.t.qn6.3-ace-lab-project-add-step-by-step.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md, .ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: "L8: Instalacja nowego laba i dodawanie projektu"
---

# L8: Instalacja nowego laba i dodawanie projektu

## Cel i zachowanie

Nowy lab i projekt są gotowe do pracy właściwych ról pod właściwymi kontami.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

## Subtaski i kolejność

- [8xg.t.sbz.7.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/0-przygotowa-konta-katalogi-uprawnienia-i/8xg.t.sbz.7.0-przygotowa-konta-katalogi-uprawnienia-i-klucze.s.md) — Przygotować konta, katalogi, uprawnienia, klucze i dostępne role zgodnie z konfiguracją laba. Dostęp wynika z kont i plików, bez odtworzenia brokera usług z iy6.
- [8xg.t.sbz.7.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/1-dodawa-projekt-gotowy-do-pracy/8xg.t.sbz.7.1-dodawa-projekt-gotowy-do-pracy-zespo-u.s.md) — ace-lab project add przygotowuje repozytorium, konfigurację projektu, prywatne _overseer, presety ról, komunikację i dane potrzebne plannerowi.
- [8xg.t.sbz.7.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/2-przeprowadza-instalacj-nowego-laba/8xg.t.sbz.7.2-przeprowadza-instalacj-nowego-laba.s.md) — ace-lab install prowadzi nową instalację przez konta, katalogi, konfigurację, adaptery HITL, klucze i weryfikację; korzysta z paczek ACE.
- [8xg.t.sbz.7.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/3-wznawia-w-asn-przerwan-instalacj/8xg.t.sbz.7.3-wznawia-w-asn-przerwan-instalacj.s.md) — Rozpoznawać własną niedokończoną instalację i umożliwiać dokończenie zachowanych etapów; odróżniać ją od gotowego laba i obcych zasobów.
- [8xg.t.sbz.7.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/4-weryfikowa-gotowo-pod-docelowymi-kontami/8xg.t.sbz.7.4-weryfikowa-gotowo-pod-docelowymi-kontami.s.md) — Końcowa weryfikacja instalacji sprawdza pliki, narzędzia, role i skonfigurowane drogi komunikacji pod docelowymi kontami.

## Kryteria odbioru

- [ ] Docelowy wykonawca ma dostęp do potrzebnych plików i własnych kluczy; konfiguracja wskazuje poprawny kontekst pracy.
- [ ] Dodany projekt jest widoczny w statusie, a planner może przygotować jego pierwszy task bez ręcznego naprawiania katalogów.
- [ ] Na świeżym środowisku kończy instalację gotową do project add i uruchomienia coworkera.
- [ ] Przerwanie po kontach lub katalogach i ponowne uruchomienie kończą tę samą instalację bez duplikatów i utraty konfiguracji.
- [ ] Dostęp do worktree, konfiguracji i odpowiedniego klucza oraz komunikacja są potwierdzone dla rzeczywistego wykonawcy, nie tylko konta instalatora.

## Weryfikacja i scenariusze błędów

- Brak uprawnienia jest zgłaszany; sekret nie trafia do Git, specyfikacji taska, argumentów diagnostycznych ani raportów.
- Ponowne dodanie nie niszczy konfiguracji ani zmian istniejącego projektu; konflikt lokalizacji jest zgłaszany przed nadpisaniem.
- Gotowy lub obcy lab powoduje odmowę nadpisania; brak wymaganych uprawnień/narzędzi jest konkretnie zgłoszony, bez pozornego sukcesu.
- Obcy katalog lub niespójny stan nie są automatycznie przejmowane ani czyszczone; brak możliwości wznowienia daje konkretną informację.
- Brak pliku, złe uprawnienia, rola lub niedziałający adapter uniemożliwiają oznaczenie laba jako gotowego.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.3](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/3-ace-lab-project-add-step/8xg.t.qn6.3-ace-lab-project-add-step-by-step.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xb.t.iy6](.ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
