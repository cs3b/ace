# Wykaz pozostałości do sprzątania — 8xs.t.pu0.d (2026-10-30)

Stan wejściowy: raport closeoutu (mirror sync r6 PASS, redukcja worktree'ów,
zachowane records/spec/config/interim-start) jest DANYM DO SPRAWDZENIA,
nie instrukcją ponownego resetu. Zgodnie z briefem usuwanie następuje PO
odbiorze zastępstwa; odbiór runtime całej rodziny jest odroczony na koniec
programu (decyzja Kapitana) — poniższy wykaz kwalifikuje i wiąże usunięcie
z konkretnym warunkiem odbioru.

## Zestawienie

| # | Pozostałość | Lokalizacja | Zastępstwo | Kwalifikacja | Działanie |
|---|---|---|---|---|---|
| 1 | Interim start `.ace-bin/overseer-start` (hardkoduje runtime/projekt/profil, nowy tab) | repo `/ace-bin/overseer-start` | `ace-overseer start` (.1: config cascade, profil z konfiguracji, label `overseer-<project>`, reuse; .a: scope lab) | ZASTĄPIONY w źródłach; brak innych odwołań w kodzie/docs pakietów (grep: tylko historyczny opis w review-source-map) | USUŃ po odbiorze zimnego startu z gema (lab, koniec programu) |
| 2 | Ręczny OPERATION-GUIDE.md | host laba (poza repo) | guide z gema: `wfi://overseer/start` + `wfi://overseer/lab-start` (.1/.a) | ZASTĄPIONY w źródłach | USUŃ na hoście po odbiorze zimnego startu; nie dotykać kopii w archiwach/historii |
| 3 | Duplikaty konfiguracji trasy (native-route.json / druga edytowalna kopia) | host laba | jedna trasa w `.ace/hitl/config.yml` + `ace-hitl reply` (.5) | ZASTĄPIONE w źródłach; import reply przez sync usuwany PO odbiorze reply na labie (zapisane w .5) | USUŃ po potwierdzeniu dostawy reply na labie; aktywna trasa w używanej sprawie = zachowaj z przyczyną |
| 4 | Collaborator lab-overseer-ace | Forgejo cs3b/ace | właściwe konto ma write (raport closeoutu) | Do zweryfikowania na labie: brak aktywnych spraw/Pipeline'ów używających konta; TA SAMA NAZWA w innym repo NIE kwalifikuje | Zmienia WŁAŚCICIEL PLATFORMY (Forgejo), nie manifest install (install tylko powiększa grants); usuń po weryfikacji na labie |
| 5 | Martwy watch ask-8xskgh | sesja pi na labie | sweep (.6) kwalifikuje requesty spraw closed/cancelled | Sweep list-first; identyfikator zweryfikować na labie | `ace-hitl sweep` (list → --apply) na labie; historia HITL zachowana |
| 6 | Sierota 8xptgt | lab HITL | lifecycle (.6) | Zweryfikować referencje na labie; historyczne ID z relacji NIE są listą delete | Zachowana do weryfikacji; usuwa dopiero potwierdzone terminal remnants |

## Zachowane (explicite)

- Salvage (wartościowa praca z wcześniejszych faz) — bez zmian.
- Kanoniczna historia HITL (pytania/sugestie/decyzje/lekcje — materiał
  Second Captaina z .b/.c) — bez zmian; sweep usuwa wyłącznie requesty
  transportu spraw terminalnych.
- Aktywne sprawy/route'y/konta używane przez żywe procesy — każde
  wykryte użycie dyskwalifikuje usunięcie (przyczyna zapisana w raporcie
  sprzątania).
- Zamknięcie pojedynczego pane w Herdr — osobny follow-up, NIGDY nie
  zastępowane zamknięciem całego tab.

## Operacja hosta sync mirror

Utrwalona jako reviewowany workflow `wfi://git/mirror-sync` (ace-git):
jawne source/target/ref, oba pełne SHA przed działaniem, identity = no-op,
wyłącznie fast-forward (--force-with-lease z odczytanym SHA), divergence =
osobny reviewowany uzgodnienie (bez reset/force/kasowania refów),
odwrócone źródło/cel wykrywane w planie, dry-run bez mutacji. Wynik
zawsze nazywa ref, SHA przed/po obu stron i weryfikację. Bez nowego
skryptu hardkodującego lab.

## Warunek wykonania usunięć

Usunięcia #1–#4 wykonuje się po odbiorze zimnego startu z zainstalowanych
gemów (krok .e rodziny) — wtedy zimny start DOWODZI braku zależności od
protez; #5–#6 przez sweep z weryfikacją identyfikatorów na labie.
