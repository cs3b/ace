---
id: 8xg.t.sbz.8.3
status: draft
priority: medium
created_at: "2026-10-17 18:54:29"
estimate: medium
dependencies: ["8xg.t.sbz.7"]
tags: ["lab", "lab-l9", "file-based"]
parent: 8xg.t.sbz.8
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-task/docs/usage.md", "ace-review/handbook/workflow-instructions/review/pr.wf.md", "ace-overseer/docs/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md", ".ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md", ".ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md", ".ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/3-sprawdzi-macierz-forge-i-instalacji/ux/usage.md", ".ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/acceptance/matrix.md", ".ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/acceptance/coupling-inventory.md", ".ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/acceptance/producer-gaps.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Sprawdzić macierz forge i instalacji"
---

# Sprawdzić macierz forge i instalacji

## Cel

Przed release potwierdzony jest pełny system z lokalnie zbudowanych paczek. Ten subtask dostarcza następujący wycinek: Przenieść potrzebną macierz qkc: lokalny Git, GitHub, domyślne i nazwane Forgejo; task/issues, worktree/PR, review, integracja i rozwiązywanie workflow. Osobno świeża i przerwana instalacja.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Istniejące testy i scenariusze ACE; lokalne gemy, świeże środowisko, zapis wyników przy zadaniu. Bez nowego frameworka odbioru.

Przenieść potrzebną macierz qkc: lokalny Git, GitHub, domyślne i nazwane Forgejo; task/issues, worktree/PR, review, integracja i rozwiązywanie workflow. Osobno świeża i przerwana instalacja.

## Kryteria odbioru

- [ ] Działają właściwe URL i wybór forge, task/issue i PR lifecycle oraz przegląd i integracja; wyniki wskazują scenariusz, provider, wersje, komendę, wynik i raport.
- [ ] Błędny lub niejednoznaczny serwer, brak uprawnień, offline, zmiana kandydata i niedostępne środowisko są jawne. Niewykonany wymagany scenariusz nie jest zaliczany.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Działają właściwe URL i wybór forge, task/issue i PR lifecycle oraz przegląd i integracja; wyniki wskazują scenariusz, provider, wersje, komendę, wynik i raport.
- Scenariusz błędu / niepoprawnego wejścia: Błędny lub niejednoznaczny serwer, brak uprawnień, offline, zmiana kandydata i niedostępne środowisko są jawne. Niewykonany wymagany scenariusz nie jest zaliczany.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L8 / 8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)
- [8wr.t.qkc](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md)
- [8wr.t.qkc.0](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Macierz obejmuje lokalny Git bez wymaganego dostępu do forge, GitHub, domyślne oraz nazwane Forgejo: rozwiązywanie repozytorium i PR, lifecycle worktree, task/issue link-sync-close-reopen, review, integrację oraz instalację workflow. Wykorzystać dotychczasowe scenariusze qkc, usuwając zależność od protected execution i journala. Używać skonfigurowanych środowisk testowych; brak środowiska oznacza niewykonany wymagany wiersz.
