# Wynik: 8xg.t.sbz.4.2 — Egzekwować pełne rundy i limit review

## Co zaimplementowano

Reguła zbieżności 3/2/10 jako działający kod w `ace-coworker`:

- **`Ace::Coworker::Atoms::RoundRule`** — czysty (bez IO) ewaluator reguły.
  Wejście: uporządkowana lista rekordów rund (każdy z `type`
  full|delta, `status` completed|aborted, `confirmed` — lista
  `{id, severity}`, `resolved` — lista id ustaleń rozwiązanych w tej
  rundzie). Wyjście: werdykt `:continue | :accept | :escalate` (jawny
  wynik, nigdy wyjątek) plus wyprowadzone liczniki: `full_rounds`,
  `completed_full_rounds`, `consecutive_clean`,
  `unresolved_high_critical`.
- **`Ace::Coworker::Molecules::ReviewRoundStore`** — trwałość historii
  rund w pliku `.ace-local/coworker/review-rounds/<assignment_id>.json`
  (lokalacja własna coworkera, wzorowana na istniejącym
  `ReportStateStore`; zapis atomowy, walidacja id, odporność na
  uszkodzony plik). `record!` dopisuje rundę i zwraca aktualny werdykt
  reguły — restart odczytuje ten sam plik, więc licznik rund i historia
  ustaleń nie resetują się.

Reguła: akceptacja wymaga ≥3 zakończonych pełnych rund, z których
ostatnie 2 kolejne są czyste (brak potwierdzonych High/Critical) oraz
brak wcześniejszych nierozwiązanych High/Critical; spełnienie reguły w
rundzie 10 kończy sukcesem; brak akceptacji po 10 pełnych rundach daje
`:escalate` (dla roli reviewer: pytanie decyzyjne ace-hitl do
overseera). Rundy delta/fix-diff nie zwiększają licznika pełnych rund i
są przezroczyste dla serii czystych rund (ani nie budują, ani nie
zrywają serii); ich potwierdzone ustalenia wchodzą do historii
 nierozwiązanych. Runda przerwana (aborted) nie jest czysta i zrywa
serię; potwierdzony High/Critical zeruje serię czystych rund.

## Pliki

- `ace-coworker/lib/ace/coworker/atoms/round_rule.rb` — nowy, czysta
  reguła 3/2/10 (werdykt + liczniki).
- `ace-coworker/lib/ace/coworker/molecules/review_round_store.rb` —
  nowy, plikowa historia rund w lokalizacji coworkera.
- `ace-coworker/lib/ace/coworker.rb` — rejestracja autoload obu
  komponentów.
- `ace-coworker/test/atoms/round_rule_test.rb` — nowy, testy jednostkowe
  wszystkich kryteriów.
- `ace-coworker/test/molecules/review_round_store_test.rb` — nowy,
  testy trwałości w tym restart (persist → reload → liczniki zachowane).
- `ace-coworker/CHANGELOG.md` — wpis pod `[Unreleased]` / Added;
  zaktualizowany stare „stated, not yet enforced" w wpisie 4.1.
- `ace-coworker/docs/usage.md` — mała wzmianka o wymuszonej regule przy
  presetcie reviewer.
- `ace-coworker/handbook/workflow-instructions/coworker/reviewer.wf.md`
  — mała edycja punktu 6: zamiast „to be built by 8xg.t.sbz.4.2" —
  odwołanie do `RoundRule` / `ReviewRoundStore` i sposobu użycia
  (`record!`, werdykt, restart nie zeruje liczników).

## Weryfikacja

- `bin/ace-test ace-coworker all` → **287 testów, 1183 asercje, 0
  failures, 0 errors**.
- `bin/ace-test ace-coworker` (domyślny zestaw) → ten sam wynik: 287/1183, 0/0.
- Nie uruchamiano całego `bin/ace-test-suite` (brama Lead'a).

## Pokrycie kryteriów odbioru

- „czysta/czysta/czysta oraz błąd/czysta/czysta kończą po rundzie 3" —
  `test_clean_clean_clean_accepts_at_round_three`,
  `test_error_clean_clean_accepts_at_round_three_when_high_resolved`
  (runda z High zakończona naprawą, rozwiązane id w późniejszej rundzie).
- „Spełnienie reguły w rundzie 10 kończy sukcesem" —
  `test_rule_satisfied_at_round_ten_succeeds` (10 pełnych rund, High z
  rundy 1 rozwiązany, rundy 9–10 czyste → `:accept`).
- „Brak akceptacji po rundzie 10 eskaluje" —
  `test_no_acceptance_after_round_ten_escalates_as_explicit_outcome`
  (jawny `:escalate`, nie wyjątek);
  `test_aborted_rounds_still_count_toward_the_ten_limit` (przerwane
  rundy liczą się do limitu 10 — nie da się eskalacji uniknąć pętlą
  przerwań).
- „Przerwane raporty nie liczą się jako czyste" —
  `test_aborted_round_is_not_clean_and_breaks_the_streak` (aborted nie
  jest czysta i zrywa serię).
- „High/Critical zeruje serię" — `test_high_critical_finding_resets_the_streak`
  oraz `test_unresolved_high_blocks_accept_even_after_three_rounds`
  (nierozwiązane High/Critical blokuje akceptację; Medium/Low nie).
- „Diff review nie zwiększa licznika" —
  `test_delta_round_never_advances_the_counter_or_breaks_the_streak`;
  dodatkowo `test_unresolved_high_confirmed_in_a_delta_round_blocks_accept`
  (ustalenia z delty wchodzą do historii).
- „Restart nie zeruje licznika ani historii ustaleń" —
  `test_restart_preserves_counters_and_verdict` (persist → nowa
  instancja store → `record!` trzeciej rundy zwraca `:accept` z
  zachowanymi licznikami).
- „Wynik zgodny z kontraktem i możliwy do użycia" — werdykt jest
  wartością zwracaną (`:continue|:accept|:escalate`) i licznikami; rola
  reviewer kieruje się nim wg zaktualizowanego reviewer.wf.md
  (`:escalate` → pytanie decyzyjne ace-hitl). Nie budowano
  spekulatywnego runnera — uruchomienie roli to instrukcja workflow,
  zgodnie z ustaleniem w tasku.

## Decyzje

1. **Przerwane pełne rundy liczą się do limitu 10** (ale nie do minimum 3
   ani do serii czystych) — inaczej pętla przerwań omijałaby eskalację;
   to zgodne z „przerwane nie jest czystą rundą" i ducha limitu 10.
2. **Delta jest w pełni przezroczysta dla serii czystych** (nie zrywa
   jej): zgodnie z reviewer.wf.md, delta liczy się do reguły tylko gdy
   obejmuje cały zakres zmian — wtedy wywołujący zapisuje ją jako
   `type: "full"`; potwierdzone ustalenia z delty wchodzą mimo to do
   historii nierozwiązanych.
3. **Czysta reguła jako atom, trwałość jako molekuła** — zgodnie ze
   wzorcem ATOM repozytorium (analogicznie do `PrepareDecision`,
   `ReportStateStore`); lokalacja stanu: istniejąca własność coworkera
   `.ace-local/coworker/`, bez nowego właściciela stanu, bazy czy
   journala.
4. Rozdzielczość ustaleń: identyfikatory z `ace-review` feedback;
   rozwiązanie = pojawienie się id na liście `resolved` dowolnej
   późniejszej rundy.
