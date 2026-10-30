# Postęp 8xs.t.pu0.f — odporność i zamknięcie programu (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398).

## Zrealizowane w źródłach

1. **Macierz awarii — testy granic przekazań** (nowe suite'y):
   - `ace-lab/test/fast/auth/resilience_test.rb` (4): nieznany wynik issue
     → retry tworzy DOKŁADNIE jeden live grant, przerwany rekord pozostaje
     widocznym revoke-pending do reconcile; SIGKILL wykonawcy → grant martwy
     po use_until, użycie odmówione; utrata sieci przy revoke → NIGDY
     claimed success, reconcile domyka ten sam grant (dokładny token, raz);
     cleanup niezależny od modelu (handoff wyczyszczony z lease);
   - `ace-hitl .../hitl_collision_test.rb` (2): ta sama sprawa w dwóch
     rootach worktree → reply i suggestion to jawna ambiguigkeit, ZERO
     side-efektów w obu kopiach;
   - `ace-wake/test/zero-idle-window.test.mjs` (1): 30 minut zdrowej ciszy
     → 0 wywołań modelu; polling techniczny liczony osobno (obserwacje
     rosną, timery armed); realna zmiana po oknie nadal wybudza.
2. **Naprawiony defekt** (wykryty przez macierz): `LeaseStore#find_live`
   i `#live?` zwracały rekord `revoke-pending` jako żywy przydział — po
   przerwanym issue retry zwracał martwy grant zamiast nowego. Naprawa:
   żywy jest wyłącznie rekord `issued` w terminach. Scenariusz ponowiony
   (zielony), pełny suite ace-lab 625/0 fail — potwierdzony cały dotknięty
   przebieg (service + resilience + installer).
3. **Raport zamykający** (`docs/closing-report.md` w tasku): pełna macierz
   granic przed/po z dowodami źródłowymi i kolumną lab; okno zero-idle
   (granica 30 min; liczby przed/po; techniczny polling osobno; starsze 4h
   z 9o9 NIE jest dodatkowym gate); mapa checkboxów rodziny; gad.2 F1/F2/F3
   (status historyczny BEZ ZMIAN do potwierdzenia własnych kryteriów);
   sbz.9 (mapa przy finalnym odbiorze; nieznane kryterium = NIEPOTWIERDZONE);
   potwierdzone vs pozostałe ograniczenia (m.in. host-revoke przy
   niedostępnym hoście — niezależne native expiry GitHub).

## Dowody

- ace-lab 625 (nowe 4 resilience), ace-hitl 391+2 kolizje (393), ace-wake
  134 JS (nowy zero-idle) — wszystkie suite'y rodzinne 0 fail.

## Granice / odroczone (finalny odbiór)

- Wykonanie całej macierzy na żywym labie; 30-minutowe okno na żywym
  runtime z faktycznymi liczbami; negativ install flow; mapa końcowa na
  checkboxy (wypełnienie raportu zamykającego dowodami lab) i dopiero
  wtedy decyzja o statusach zadań rodziny oraz historycznych gad.2/sbz.9.
