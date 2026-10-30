# Postęp 8xs.t.pu0.9 — dostarczenie wydania i zamknięcie cyklu (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Rzeczywista publikacja gemów i
odbiór runtime na labie — odroczony koniec programu (decyzja Kapitana; zgodnie
z briefem: implementacja na hoście, lab odbiera opublikowane wydania).

## Zrealizowane w źródłach

1. **OTP jako sekretna sprawa HITL** (bez ujawniania wartości):
   - `ace-hitl ask --secret` — jawne oznaczenie przy tworzeniu (bez
     heurystyki tytułu): `secret: true` w sprawie + flaga `secret` w wake
     request dla bridge'a;
   - ace-wake: watch uzbrojony z `redact` — wybudzenie niesie wyłącznie
     REFERENCJĘ sprawy (delta bez excerptu; komunikat wskazuje secure
     channel); wartość wykonawca czyta z pliku sprawy przez wrapper, nigdy z
     wake; normalne ask'i nadal niosą treść odpowiedzi;
   - brak terminu odpowiedzi Kapitana; odrzucone/wygasłe OTP = nowa sprawa,
     bez replay (workflow).
2. **Workflow wydawcy** (`wfi://release/publisher`, ace-handbook): dostęp
   przez ace-lab auth (profil publisher, weryfikacja principal/repo/scope/
   use_until; statyczny env nie jest dowodem remote expiry; pauza dostępu nie
   przedłuża lease), istniejące workflow release (inventory/bump/changelog/
   coordinated commit), publikacja z OTP-sekret, resume: zgodna wersja+digest
   = już opublikowane (kontynuuj brakujące kroki), konflikt wersji/digestu =
   blokada (bez nadpisywania/bumpowania naokoło), nieudana publikacja =
   jawny stan wznowialny.
3. **Rekord cyklu** (`wfi://release/cycle-record`): kontrakt zapisu w
   `.ace-tasks/_records` — task/cycle, source HEAD, review/test evidence
   (bound heads), publish versions+digests (sprawdzone w repo artefaktów),
   ścieżki/wersje runtime i wynik odbioru pod kontem docelowym; record-only
   PR przez zwykły review; bez uruchamiania release bez zmiany produktu i bez
   rekurencyjnego rekordu; task done dopiero po odbiorze i integracji
   rekordu.
4. Dokumentacja usage (ask --secret) + CHANGELOGe (ace-hitl, ace-wake,
   ace-handbook).

## Dowody

- `bin/ace-test ace-hitl` — 380 testów, 0 fail (w chwili kroku); nowe 2:
  ask --secret utrwala `secret: true` w sprawie i flagę w wake-request;
  normalny ask bez oznaczenia.
- ace-wake suite JS — nowe `secret-ask.test.mjs` (2): bridge uzbraja redact
  watch z komunikatem secure-channel (normalny bez redact); integracyjnie z
  REALNYM WakeRegistry + watch portem: wybudzenie sekretnego wake bez
  wartości OTP („918273" nieobecne), normalne wake z treścią odpowiedzi.
- `bin/ace-test ace-handbook` — 64 testy, 0 fail (workflowy w tree handbook).

## Granice / odroczone

- Pełny przebieg na labie: merge → release → publish (z OTP przez Hermes) →
  ace-lab install → verify pod kontem docelowym → rekord w _records przez
  reviewowany PR; przerwana publikacja z realnym repo artefaktów.
- Publikacja gemów (ace-hitl, ace-wake, ace-handbook).

---
Uwaga porządkowa (2026-10-30): pierwotna kopia tego pliku znalazła się przez
pomyłkę w katalogu z literówką (`.t.pu0-automiczny…`) i została usunięta po
odtworzeniu treści tutaj; zawartość odpowiada stanowi z commitu kroku.
