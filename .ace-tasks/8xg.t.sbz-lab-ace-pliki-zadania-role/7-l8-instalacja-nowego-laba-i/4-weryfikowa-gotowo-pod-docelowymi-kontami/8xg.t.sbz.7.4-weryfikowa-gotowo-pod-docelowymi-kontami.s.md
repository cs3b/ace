---
id: 8xg.t.sbz.7.4
status: done
priority: medium
created_at: "2026-10-17 18:54:27"
estimate: medium
dependencies: [8xg.t.sbz.7.3, 8xg.t.sbz.6]
tags: [lab, lab-l8, file-based]
parent: 8xg.t.sbz.7
needs_review: true
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-lab/docs/usage.md, ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md, ace-hitl/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/3-ace-lab-project-add-step/8xg.t.qn6.3-ace-lab-project-add-step-by-step.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md, .ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/4-weryfikowa-gotowo-pod-docelowymi-kontami/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: Weryfikować gotowość pod docelowymi kontami
---

# Weryfikować gotowość pod docelowymi kontami

## Cel

Nowy lab i projekt są gotowe do pracy właściwych ról pod właściwymi kontami. Ten subtask dostarcza następujący wycinek: Końcowa weryfikacja instalacji sprawdza pliki, narzędzia, role i skonfigurowane drogi komunikacji pod docelowymi kontami.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

Końcowa weryfikacja instalacji sprawdza pliki, narzędzia, role i skonfigurowane drogi komunikacji pod docelowymi kontami.

## Kryteria odbioru

- [ ] Dostęp do worktree, konfiguracji i odpowiedniego klucza oraz komunikacja są potwierdzone dla rzeczywistego wykonawcy, nie tylko konta instalatora.
- [ ] Brak pliku, złe uprawnienia, rola lub niedziałający adapter uniemożliwiają oznaczenie laba jako gotowego.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Dostęp do worktree, konfiguracji i odpowiedniego klucza oraz komunikacja są potwierdzone dla rzeczywistego wykonawcy, nie tylko konta instalatora.
- Scenariusz błędu / niepoprawnego wejścia: Brak pliku, złe uprawnienia, rola lub niedziałający adapter uniemożliwiają oznaczenie laba jako gotowego.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L8.4 / 8xg.t.sbz.7.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/3-wznawia-w-asn-przerwan-instalacj/8xg.t.sbz.7.3-wznawia-w-asn-przerwan-instalacj.s.md), [L7 / 8xg.t.sbz.6](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.3](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/3-ace-lab-project-add-step/8xg.t.qn6.3-ace-lab-project-add-step-by-step.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xb.t.iy6](.ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
