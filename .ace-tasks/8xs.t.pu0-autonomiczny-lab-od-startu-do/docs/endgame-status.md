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

## Dodatek: odbiór z zbudowanych gemów (2026-10-30, runda 18)

Kolejny etap odbioru producer→consumer na poziomie artefaktu: 9 gemów
zbudowanych, SHA-256 spisane (`/tmp/pu0-gem-build/SHA256SUMS` —przy
finalnej publikacji), zainstalowane w izolowanym GEM_HOME z opublikowanymi
zależnościami z RubyGems, uruchomione z ACE_TOOLCHAIN=installed.

- **Defekty znalezione i naprawione** (commit 839e1b093): `ace-lab auth`
  NameError na niezdefiniowanej klasie `Ace::Lab::Auth::Error` (jawna baza);
  `ace-hitl help` nie listował 7 nowych komend (dopełniony
  REGISTERED_COMMANDS). Oba zweryfikowane z przebudowanych gemów.
- **Pełny cykl HITL z zainstalowanego gema**: create → reply (received,
  exit 0) → identyczne ponowienie (duplicate, exit 0) → apply --ref →
  close → sweep — wszystkie wyniki zgodne z kontraktem.
- **observe (installed)**: projekcja `ace.hitl.observation/v1` z pięcioma
  lokalnymi źródłami + hitl, źródła zdrowe, schema zgodna.
- **start --dry-run (installed)**: wfi:// bez zainstalowanego nav =
  poprawna blokada z konkretnym komunikatem; instructions jako plik =
  pełny plan (scope/root/label/profile/instrukcje) z poprawnym rootem.
- **gate (installed)**: stale review blokuje; zgodne HEAD-y +
  tests-head + approval-head/author przechodzą (ready).

Pozostałe bramki bez zmian: niezależny review + approval + merge PR #398,
publikacja (OTP Kapitana), zimny cykl na labie.

## Dodatek 2: PR description + próba review (2026-10-30, runda 19)

- **PR #398 description zaktualizowana** pełnym zestawieniem kroku po kroku
  (16 wierszy tabeli deliverables, weryfikacja, bramka merge) przez
  `ace-git pr update` (head 3e05c9933); tytuł odzwierciednia staged release
  set. Draft pozostaje do niezależnego review.
- **Próba automated review**: packet full-diff (~169k tokenów) i deltas
  przekraczają budżet 128k; delta ostatnich 8 kommitów (od 02ed496f4)
  mieści się w budżecie i przygotowuje się poprawnie, ale wykonanie LLM
  (pi:zai/glm-5.3) kończy się błędem środowiskowym `node:fs` — ten sam,
  który wcześniej blokował `ace-task plan` i `ace-git-commit` w tej sesji.
  Review verdict wymaga działającego providera poza tą sesją lub roli
  ludzkiego reviewera; to pozostaje warunkiem bramki merge.

Bramki końcowe (bez zmian): niezależny review → formalny approval → merge →
publish (OTP) → zimny cykl na labie.
