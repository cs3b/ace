# Postęp 8xs.t.pu0.6 — domknięcie cyklu życia spraw HITL (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Sweep faktycznych sierot laba
(8xptgt, ask-8xskgh) — identyfikatory do zweryfikowania w docelowym labie
(odroczony odbiór, decyzja Kapitana).

## Zrealizowane w źródłach

1. **Stany w kanonicznym pliku** (bez drugiego rejestru):
   - receipt: pending → received (odpowiedź trwale zapisana);
   - application: pending → applied → closed; cancelled = zakończenie bez
     zastosowania; raporty pozostają recorded (nie oczekują odpowiedzi);
   - `HitlManager#case_lifecycle` — odczyt faktów tylko z pliku.
2. **Przejścia atomowe z odrzucaniem konfliktów** (flock + validate+write):
   - `apply_answer_effect(ref, effect_ref)` — zapis zastosowania z
     referencją właściciela efektu (task/assignment/PR); identyczna
     referencja = no-op (`:duplicate`), inna = konflikt; exactly-once
     należy do skutku: po crashu konsument najpierw sprawdza efekt u
     właściciela (kontrakt dokumentowany; nierozstrzygalność = jawna
     blokada uzgodnienia, nie ślepe powtórzenie);
   - `close_case` — terminalny wyłącznie po dowodzie applied; duplikat
     no-op; zamknięta sprawa nigdy się nie otwiera (jawna zmiana decyzji =
     nowa sprawa);
   - `cancel_case` — terminalny bez zastosowania (również dla answered
     bez applied); applied to historia — tylko close.
3. **CLI**: `ace-hitl apply CASE --ref`, `ace-hitl close CASE`,
   `ace-hitl sweep [--apply]`.
4. **Sweep list-first**: kwalifikuje pliki wake-request ask-bridge wobec
   kanonicznych spraw; kandydaci do usunięcia wyłącznie requesty spraw
   closed/cancelled; aktywne (pending/received/applied), nieznane id,
   nieparsowalne requesty i kanoniczna historia (w tym historia dla Second
   Captaina) zawsze zachowane; bez `--apply` tylko wykaz.

## Dowody

- `bin/ace-test ace-hitl` — 378 testów, 0 fail; nowe
  `hitl_case_lifecycle_test` (6): pełny cykl receipt→applied→closed,
  close bez dowodu applied odrzucony, re-apply tej samej referencji no-op /
  inna konflikt, późna inna odpowiedź po zamknięciu odrzucona + plik
  zamrożony + apply po close odrzucony („never re-opens"), cancel
  (terminal/duplicate/answered-unapplied OK/applied tylko close),
  sweep: kwalifikuje tylko closed, zachowuje active/unknown/history,
  `--apply` usuwa wyłącznie kwalifikowane.
- Późna odpowiedź do zamkniętej sprawy: `receive_answer` z kroku 06
  odrzuca konflikt bez zapisu — sprawa nie „otwiera się" ponownie.

## Granice / odroczone

- Sweep faktycznych pozostałości laba (8xptgt, martwy watch ask-8xskgh):
  identyfikatory z relacji do weryfikacji na labie przed działaniem;
  historyczne ID z relacji nie są listą do delete (zachowane).
- Rejestrowanie id dostawy (delivery id) i właściciela pytania w pliku:
  pola zapisywane przy odbiorze Hermes na labie (payload dostawy); obecnie
  receive_answer zapisuje receipt/answered_at.
- Odbiór na labie (crash windows na żywym przepływie), publikacja gemu.
