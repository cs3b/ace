---
id: 8xg.t.sbz.8
status: done
priority: high
created_at: "2026-10-17 18:53:37"
estimate: large
dependencies: []
tags: [lab, lab-l9, file-based]
parent: 8xg.t.sbz
needs_review: true
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-task/docs/usage.md, ace-review/handbook/workflow-instructions/review/pr.wf.md, ace-overseer/docs/usage.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/ux/usage.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/acceptance/matrix.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/acceptance/coupling-inventory.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/acceptance/producer-gaps.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: "L9: Pełny przepływ i scenariusze awarii przed publikacją"
---

# L9: Pełny przepływ i scenariusze awarii przed publikacją

## Cel i zachowanie

Przed release potwierdzony jest pełny system z lokalnie zbudowanych paczek.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

Istniejące testy i scenariusze ACE; lokalne gemy, świeże środowisko, zapis wyników przy zadaniu. Bez nowego frameworka odbioru.

## Subtaski i kolejność

- [8xg.t.sbz.8.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/0-sprawdzi-pe-n-sekwencj-przygotowania/8xg.t.sbz.8.0-sprawdzi-pe-n-sekwencj-przygotowania-i-wykonania.s.md) — Na lokalnie zbudowanych gemach w świeżym środowisku wykonać planner → worker → reviewer z poprawkami → integrator → odblokowanie następnego taska.
- [8xg.t.sbz.8.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/1-sprawdzi-awarie-wznowienia-i-eskalacje/8xg.t.sbz.8.1-sprawdzi-awarie-wznowienia-i-eskalacje.s.md) — Wykonać scenariusze przerwania coworkera, restartu overseera, niedostarczenia i powtórzenia raportu, pytania HITL oraz limitu review.
- [8xg.t.sbz.8.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/2-sprawdzi-izolacj-zada-i-sekwencj/8xg.t.sbz.8.2-sprawdzi-izolacj-zada-i-sekwencj-r-l.s.md) — Uruchomić dwa zadania z odrębnymi worktree i wynikami; dla jednego zadania obserwować sekwencyjną zmianę ról.
- [8xg.t.sbz.8.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/3-sprawdzi-macierz-forge-i-instalacji/8xg.t.sbz.8.3-sprawdzi-macierz-forge-i-instalacji.s.md) — Przenieść potrzebną macierz qkc: lokalny Git, GitHub, domyślne i nazwane Forgejo; task/issues, worktree/PR, review, integracja i rozwiązywanie workflow. Osobno świeża i przerwana instalacja.

## Kryteria odbioru

- [ ] Wynik dokumentuje faktyczne przejścia ról, taski, worktree, review i integrację wraz z wersjami testowanych paczek.
- [ ] Po wznowieniu zachowany jest postęp i właściwy adres Reply; eskalacja po dziesiątej nieudanej pełnej rundzie dociera do overseera.
- [ ] Zmiany, assignmenty i raporty pozostają przypisane do właściwego taska; jedna rola oddaje worktree przed startem następnej.
- [ ] Działają właściwe URL i wybór forge, task/issue i PR lifecycle oraz przegląd i integracja; wyniki wskazują scenariusz, provider, wersje, komendę, wynik i raport.

## Weryfikacja i scenariusze błędów

- Niespełniona zależność lub nieukończony assignment nie przechodzą do następnego kroku i nie są oznaczane jako sukces całego testu.
- Utrata odpowiedzi na merge lub publikację nie powoduje ślepego powtórzenia efektu; brak adaptera daje niedostarczenie, a nie sukces.
- Próba drugiego przydziału do zajętego worktree zostaje powstrzymana; wiadomość drugiego zadania nie zamyka pierwszego.
- Błędny lub niejednoznaczny serwer, brak uprawnień, offline, zmiana kandydata i niedostępne środowisko są jawne. Niewykonany wymagany scenariusz nie jest zaliczany.

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
- [8wr.t.qkc](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md)
- [8wr.t.qkc.0](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Macierz obejmuje lokalny Git bez wymaganego dostępu do forge, GitHub, domyślne oraz nazwane Forgejo: rozwiązywanie repozytorium i PR, lifecycle worktree, task/issue link-sync-close-reopen, review, integrację oraz instalację workflow. Wykorzystać dotychczasowe scenariusze qkc, usuwając zależność od protected execution i journala. Używać skonfigurowanych środowisk testowych; brak środowiska oznacza niewykonany wymagany wiersz.
