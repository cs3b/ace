---
id: 8xg.t.sbz.4.4
status: done
priority: medium
created_at: "2026-10-17 18:54:18"
estimate: medium
dependencies: [8xg.t.sbz.4.0, 8xg.t.sbz.4.2, 8xg.t.sbz.4.3]
tags: [lab, lab-l5, file-based]
parent: 8xg.t.sbz.4
needs_review: true
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-review/handbook/workflow-instructions/review/pr.wf.md, ace-review/docs/usage.md, ace-assign/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/4-ujednolici-workflow-review-i-obs/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: Ujednolicić workflow review i obsługę forge
---

# Ujednolicić workflow review i obsługę forge

## Cel

Worker, reviewer, integrator i spec domykają własne zlecenia; planner pozostaje właścicielem przygotowania z L4. Ten subtask dostarcza następujący wycinek: Ujednolicić as-pr-review, workflow i presety z regułami ról. Zachować neutralną obsługę GitHub/Forgejo i przyjąć istniejącą poprawkę qkc.0 zamiast implementować ją ponownie.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Ujednolicić as-pr-review, workflow i presety z regułami ról. Zachować neutralną obsługę GitHub/Forgejo i przyjąć istniejącą poprawkę qkc.0 zamiast implementować ją ponownie.

## Kryteria odbioru

- [ ] Typed pr:REFERENCE przyjmuje numery, owner/repository i poprawne URL GitHub /pull/ oraz Forgejo /pulls/, zachowując właściwy target; przypadek qkc.0 przechodzi finalny review/integrację.
- [ ] Zero i błędne referencje są odrzucane przed ekstrakcją bundle; parsowanie nie odpytuje sieci ani nie zgaduje github.com. Stare protected receipt gates nie wracają przez presety.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Typed pr:REFERENCE przyjmuje numery, owner/repository i poprawne URL GitHub /pull/ oraz Forgejo /pulls/, zachowując właściwy target; przypadek qkc.0 przechodzi finalny review/integrację.
- Scenariusz błędu / niepoprawnego wejścia: Zero i błędne referencje są odrzucane przed ekstrakcją bundle; parsowanie nie odpytuje sieci ani nie zgaduje github.com. Stare protected receipt gates nie wracają przez presety.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L5.1 / 8xg.t.sbz.4.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/0-dostarczy-role-worker-i-spec/8xg.t.sbz.4.0-dostarczy-role-worker-i-spec.s.md), [L5.3 / 8xg.t.sbz.4.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/2-egzekwowa-pe-ne-rundy-i/8xg.t.sbz.4.2-egzekwowa-pe-ne-rundy-i-limit-review.s.md), [L5.4 / 8xg.t.sbz.4.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/3-dostarczy-integratora-zale-nego-od/8xg.t.sbz.4.3-dostarczy-integratora-zale-nego-od-wynik-w.s.md)

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
