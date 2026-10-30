# Postęp 8xs.t.pu0.8 — zadanie przez testy, review i merge (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Pełny przebieg worker → reviewer
→ integracja na żywym forgu — odbiór na labie odroczony na koniec programu.

## Zrealizowane w źródłach

1. **IntegrationGate wiąże wszystkie podstawy z dokładnym HEAD kandydata**
   (`ace-coworker/atoms/integration_gate.rb`):
   - dowód testów musi nieść `head`, którego uruchomienie obejmowało — gołe
     `executed/passed` BLOKUJE merge („test evidence not bound to a candidate
     head"), a inny tested head = „stale test evidence" (zmiana kodu/rebase po
     testach unieważnia podstawę starego kandydata);
   - formalny approval (`approval.head`, `approval.by`) również odnosi się do
     HEAD: brak head = blokada, inny head = „stale formal approval", a
     approval z konta AUTORA = blokada (formalny approver to inne
     skonfigurowane konto lane; zgodnie z integracją auth z .7 — lease autora
     nie daje formalnego approval);
   - istniejące reguły rund 3/2/10 i role bez zmian — jeden gate, bez
     drugiego.
2. **CLI** `ace-coworker gate`: `--tests-head`, `--approval-head`,
   `--approval-by`, `--author`; brak approval pomija sprawdzanie (poprzednia
   semantyka lane bez formalnego approval).
3. **Wyścig gate ↔ merge**: potwierdzone istniejące expected-head w adapterze
   (`service_merge`/`merge_pull_request(number:, expected_head:)`), który
   odmawia kandydata przesuniętego po gate; udokumentowane w usage
   (integrator czyta HEAD bezpośrednio przed merge i przekazuje expected SHA).
   CI pozostaje advisory (decyzja Kapitana) — udokumentowane.
4. Dokumentacja usage (pełny nowy opis gate) + CHANGELOG.

## Dowody

- `bin/ace-test ace-coworker` — 400 testów, 0 fail; nowe (4):
  - test evidence bez head blokuje;
  - zmiana HEAD po testach blokuje (stale test evidence);
  - formal approval: poprawny head+inne konto przechodzi; inny head, brak
    head i approval konta autora blokują (osobno :approval w failed_checks);
  - pominięty approval zachowuje poprzednią semantykę.
- Zaktualizowane testy istniejące (ready_input z tests.head; powód „multiple
  failures" 6 — nowe binding-reason w tests).

## Granice / odroczone

- Pełny przebieg na labie: worker report → handoff do reviewera (istniejący
  `ace-overseer handoff`/assignmenty) → review → formal approval z lease
  (.7) → merge z expected-head na prawdziwym forgu; utrata odpowiedzi po
  merge → sprawdzenie forge zamiast ślepego powtórzenia.
- Publikacja gemu ace-coworker.
