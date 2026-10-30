# Stan endgame — 8xs.t.pu0 (2026-10-30)

## Wykonane (source-level + release prep)

- **Wszystkie 16 podtasków** rodziny 8xs.t.pu0 ukończone na poziomie źródeł
  (kommit po kommicie na jednym branchu/PR #398, 21 kommitów).
- **Pełny suite monorepo** (`bin/ace-test-suite`): 12 812 testów green;
  6 pakietów z błędami (ace-support-cli, ace-llm-providers-cli, pi, tmux,
  hitl-hermes, runtime) — **identyczne profile na czystym main**
  (zweryfikowane uruchomieniem tych samych pakietów na main): stan
  istniejący/środowiskowy, ZERO regresji z tej gałęzi; wszystkie 9 zmienionych
  pakietów zielone.
- **Release set przygotowany** (wfi://release/local): 9 pakietów z bumpami
  minor (ace-lab 0.14.0, ace-overseer 0.27.0 + follower constraint coworker
  ~> 0.7, ace-coworker 0.7.0, ace-hitl 0.25.0, ace-wake 0.1.0 pierwsza
  publikacja, ace-git 0.32.0, ace-handbook 0.37.0,
  ace-handbook-integration-pi 0.8.0, ace-herdr 0.9.0); changelogi spięte w
  sekcje datowane; root CHANGELOG z zestawionym wpisem; suite'y powtórzone
  po bumpach — zielone.

## Bramka merge (decyzja Kapitana 2026-09-27)

Wykonane testy ✓ (powyżej). Zalega: **niezależny review** PR #398 (rola
reviewera; gate z kroku 09 wiąże review z HEAD 566acf491) i formalny
approval właściwym kontem lane (merge przez integratora z expected-head).

## Do wykonania po merge (wymaga dostępu poza tą sesją)

1. Publikacja 9 gemów na RubyGems w kolejności zależności
   (as-release-bump/rubygems-publish; OTP Kapitana przez HITL ask --secret).
2. Odbiór na labie wg `wfi://overseer/cold-cycle-acceptance` (krok .e):
   zimny start z opublikowanych gemów, pełny cykl z jedną osią tożsamości,
   negative flow, okno zero-idle 30 min, macierz awarii na żywym runtime.
3. Wypełnienie raportu zamykającego (krok .f) dowodami z labu; dopiero
   wtedy decyzja o statusach zadań rodziny (teraz: in-progress) oraz
   mapowanie na kryteria gad.2/sbz.9 (bez automatycznego zamykania
   historycznych programów).
4. Sprzątanie z wykazu .d po odbiorze zimnego startu.
