# Postęp 8xs.t.pu0.d — operacje hosta i higiena (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398).

## Zrealizowane w źródłach

1. **Powtarzalna operacja hosta sync mirror** — `wfi://git/mirror-sync`
   (ace-git, istniejący namespace workflow Git):
   - jawne source/target/ref (dla tej rodziny: fg Forgejo cs3b/ace → origin
     GitHub cs3b/ace); OBA pełne SHA odczytane przed jakimkolwiek
     działaniem;
   - identity (SHA==SHA) = no-op; wyłącznie fast-forward; push
     --force-with-lease z ODCZYTANYM SHA targetu (ruch targetu między
     odczytem a pushem = odmowa i restart); zwykły --force zabroniony;
   - divergence = STOP + osobne reviewowane uzgodnienie (bez reset/force/
     kasowania refów); historyczne SHA (af68f8fc1…) to EVIDENCE do review,
     nie SHA do narzucenia;
   - odwrócone źródło/cel wykrywane w planie; dry-run bez mutacji;
   - wynik: ref, SHA przed/po OBU stron, weryfikacja; ponowienie po
     sukcesie = identity;
   - bez nowego skryptu hardkodującego lab — zmiany narzędziowe należą do
     ace-git/adapterów.
2. **Wykaz pozostałości** (`docs/cleanup-inventory.md` w tasku): 6
   pozycji z kwalifikacją, zastępstwem i warunkiem usunięcia — interim
   `.ace-bin/overseer-start` (zastąpiony przez `ace-overseer start` .1/.a;
   grep: brak odwołań poza historią review), ręczny OPERATION-GUIDE.md
   (host), duplikaty trasy (po odbiorze reply .5), collaborator
   lab-overseer-ace (zmienia WŁAŚCICIEL PLATFORMY Forgejo, nie manifest
   install — ten tylko powiększa grants; weryfikacja użycia na labie;
   ta sama nazwa w innym repo nie kwalifikuje), martwy watch ask-8xskgh i
   sierota 8xptgt (przez sweep .6 z weryfikacją identyfikatorów;
   historyczne ID z relacji nie są listą delete).
   Explicite zachowane: salvage, kanoniczna historia HITL (materiał
   Second Captaina), aktywne zasoby (użycie dyskwalifikuje usunięcie);
   pane-close pozostaje osobnym follow-upem, nigdy zamknięcie tab.
3. Warunek wykonania usunięć: PO odbiorze zimnego startu z zainstalowanych
   gemów (krok .e) — zimny start dowodzi braku zależności od protez
   (zgodnie z briefem: usuwamy zastąpione dopiero po odbiorze).

## Dowody

- `bin/ace-test ace-git` — 595 testów, 0 fail (workflow w tree handbook).
- Workflow spełnia mapę kryteriów 1 (SHA przed/po, ff-only, identity no-op,
  reversed detection, dry-run) — kontrakt tekstowo wiążący; wykonanie na
  prawdziwych remotes = odbiór na labie (koniec programu).

## Granice / odroczone

- Wykonanie sync na żywych repo + sprzątanie #1–#6 — po odbiorze zimnego
  startu (.e) i weryfikacji na labie; publikacja gemów.
