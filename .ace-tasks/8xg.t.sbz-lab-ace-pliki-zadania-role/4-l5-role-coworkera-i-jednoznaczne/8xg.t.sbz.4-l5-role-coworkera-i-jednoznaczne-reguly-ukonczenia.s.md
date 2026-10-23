---
id: 8xg.t.sbz.4
status: in-progress
priority: high
created_at: "2026-10-17 18:53:35"
estimate: large
dependencies: []
tags: [lab, lab-l5, file-based]
parent: 8xg.t.sbz
needs_review: true
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-review/handbook/workflow-instructions/review/pr.wf.md, ace-review/docs/usage.md, ace-assign/README.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md, .ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: "L5: Role coworkera i jednoznaczne reguły ukończenia"
---

# L5: Role coworkera i jednoznaczne reguły ukończenia

## Cel i zachowanie

Worker, reviewer, integrator i spec domykają własne zlecenia; planner pozostaje właścicielem przygotowania z L4.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

## Subtaski i kolejność

- [8xg.t.sbz.4.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/0-dostarczy-role-worker-i-spec/8xg.t.sbz.4.0-dostarczy-role-worker-i-spec.s.md) — Dostarczyć role worker i spec jako konfigurację oraz instrukcje ace-coworker. Worker implementuje i sprawdza; spec tworzy lub doprecyzowuje wymagania.
- [8xg.t.sbz.4.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/1-domyka-poprawki-wewn-trz-roli/8xg.t.sbz.4.1-domyka-poprawki-wewn-trz-roli-reviewer.s.md) — Niezależny od workera reviewer wykonuje review, sam poprawia potwierdzone błędy, sprawdza diff poprawek i wraca do pełnego review. Może rozwijać swój assignment.
- [8xg.t.sbz.4.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/2-egzekwowa-pe-ne-rundy-i/8xg.t.sbz.4.2-egzekwowa-pe-ne-rundy-i-limit-review.s.md) — Minimum 3 pełne rundy; ostatnie 2 kolejne bez potwierdzonych High/Critical i brak wcześniejszych nierozwiązanych High/Critical. Maksimum 10 pełnych rund. Diff review nie zwiększa licznika.
- [8xg.t.sbz.4.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/3-dostarczy-integratora-zale-nego-od/8xg.t.sbz.4.3-dostarczy-integratora-zale-nego-od-wynik-w.s.md) — Integrator wykonuje przewidzianą przez projekt integrację, sprawdzając zależności, aktualne zmiany, wykonane testy i wynik niezależnego review przed merge.
- [8xg.t.sbz.4.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/4-ujednolici-workflow-review-i-obs/8xg.t.sbz.4.4-ujednolici-workflow-review-i-obs-ug-forge.s.md) — Ujednolicić as-pr-review, workflow i presety z regułami ról. Zachować neutralną obsługę GitHub/Forgejo i przyjąć istniejącą poprawkę qkc.0 zamiast implementować ją ponownie.

## Kryteria odbioru

- [ ] Każda rola otrzymuje własny assignment i oddaje właściwy rezultat: zmianę ze sprawdzeniami albo kompletną specyfikację.
- [ ] Wykryty błąd jest naprawiony i ponownie sprawdzony w ramach jednego zlecenia reviewer, bez przełączania każdej poprawki przez overseera.
- [ ] Sekwencje czysta/czysta/czysta oraz błąd/czysta/czysta kończą po rundzie 3. Spełnienie reguły w rundzie 10 kończy sukcesem.
- [ ] Gotowy i sprawdzony kandydat zostaje zintegrowany, a raport wskazuje rzeczywisty wynik potrzebny do odblokowania zależnej pracy.
- [ ] Typed pr:REFERENCE przyjmuje numery, owner/repository i poprawne URL GitHub /pull/ oraz Forgejo /pulls/, zachowując właściwy target; przypadek qkc.0 przechodzi finalny review/integrację.

## Weryfikacja i scenariusze błędów

- Nieudane wymagane testy blokują sukces workera; nierozstrzygnięty istotny brak wymagań jest zgłaszany przez spec.
- Brak skutecznej naprawy lub potrzebna decyzja produktowa jest eskalowana; nie wolno oznaczyć nierozwiązanego High/Critical jako sukcesu.
- Brak akceptacji po rundzie 10 eskaluje; przerwane raporty nie liczą się jako czyste, High/Critical zeruje serię, restart nie zeruje licznika ani historii ustaleń.
- Nieaktualne review po zmianie kandydata lub niespełniona zależność wstrzymują merge; niepewny wynik operacji jest sprawdzany zamiast ponawiany w ciemno.
- Zero i błędne referencje są odrzucane przed ekstrakcją bundle; parsowanie nie odpytuje sieci ani nie zgaduje github.com. Stare protected receipt gates nie wracają przez presety.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8wr.t.qkc](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/8wr.t.qkc-prove-the-complete-forge-neutral-delivery-acceptance.s.md)
- [8wr.t.qkc.0](.ace-tasks/_archive/8x/v/8wr.t.qkc-prove-the-complete-forge-neutral/0-accept-forge-neutral-urls-in/8wr.t.qkc.0-accept-forge-neutral-urls-in-typed-review.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Poprawka qkc.0 ma zapisany commit `9b9d72d65` i wcześniejszy wynik 91 testów / 182 asercji. To historyczny dowód źródła; finalny niezależny review, integracja i wydanie pozostają do sprawdzenia w nowym programie.


## Ponowne otwarcie L5 — 2026-10-23

Rodzic ponownie `in-progress`: istniejący liść `.4.4` ma nowy draft formalnego
approval providera GitHub/Forgejo i przekazania do integratora. Pełny kontrakt
i nowe, niewykonane kryteria są wyłącznie w tym liściu. Wcześniejsze dowody
pozostają zachowane; nie oznaczają dostarczenia formalnego approval. `.4.1`,
`.4.2` i `.4.3` zachowują zakres i historię, bez nowych siblingów lub usług.
