---
id: 8xg.t.sbz.4.2
status: draft
priority: medium
created_at: "2026-10-17 18:54:18"
estimate: medium
dependencies: ["8xg.t.sbz.4.1"]
tags: ["lab", "lab-l5", "file-based"]
parent: 8xg.t.sbz.4
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-review/handbook/workflow-instructions/review/pr.wf.md", "ace-review/docs/usage.md", "ace-assign/README.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md", ".ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md", ".ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/2-egzekwowa-pe-ne-rundy-i/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Egzekwować pełne rundy i limit review"
---

# Egzekwować pełne rundy i limit review

## Cel

Worker, reviewer, integrator i spec domykają własne zlecenia; planner pozostaje właścicielem przygotowania z L4. Ten subtask dostarcza następujący wycinek: Minimum 3 pełne rundy; ostatnie 2 kolejne bez potwierdzonych High/Critical i brak wcześniejszych nierozwiązanych High/Critical. Maksimum 10 pełnych rund. Diff review nie zwiększa licznika.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Minimum 3 pełne rundy; ostatnie 2 kolejne bez potwierdzonych High/Critical i brak wcześniejszych nierozwiązanych High/Critical. Maksimum 10 pełnych rund. Diff review nie zwiększa licznika.

## Kryteria odbioru

- [ ] Sekwencje czysta/czysta/czysta oraz błąd/czysta/czysta kończą po rundzie 3. Spełnienie reguły w rundzie 10 kończy sukcesem.
- [ ] Brak akceptacji po rundzie 10 eskaluje; przerwane raporty nie liczą się jako czyste, High/Critical zeruje serię, restart nie zeruje licznika ani historii ustaleń.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Sekwencje czysta/czysta/czysta oraz błąd/czysta/czysta kończą po rundzie 3. Spełnienie reguły w rundzie 10 kończy sukcesem.
- Scenariusz błędu / niepoprawnego wejścia: Brak akceptacji po rundzie 10 eskaluje; przerwane raporty nie liczą się jako czyste, High/Critical zeruje serię, restart nie zeruje licznika ani historii ustaleń.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L5.2 / 8xg.t.sbz.4.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/1-domyka-poprawki-wewn-trz-roli/8xg.t.sbz.4.1-domyka-poprawki-wewn-trz-roli-reviewer.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8wr.t.qkc](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md)
- [8wr.t.qkc.0](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Poprawka qkc.0 ma zapisany commit `9b9d72d65` i wcześniejszy wynik 91 testów / 182 asercji. To historyczny dowód źródła; finalny niezależny review, integracja i wydanie pozostają do sprawdzenia w nowym programie.
