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

## Poprawki po review (runda 1)

Zastosowano wszystkie 7 ustaleń z raportu
`.ace-local/review/sessions/review-8xidjr/review-report-review-default.md`:

1. **CLI dla `record!` (wysoki)** — nowa komenda
   `ace-coworker rounds record --assignment <id> --type full|delta
   --status completed|aborted [--confirmed id:sev,...] [--resolved id,...]`
   (`lib/ace/coworker/cli/commands/rounds.rb`, zarejestrowana w CLI jako
   `rounds`), wywołuje `ReviewRoundStore#record!` i wypisuje werdykt
   (tabela/JSON, konwencje pozostałych komend). Zaktualizowano regułę 6 w
   `reviewer.wf.md` (odwołanie do komendy zamiast metody Ruby) i
   `docs/usage.md` (nowa sekcja `ace-coworker rounds record`). Testy:
   `test/commands/rounds_test.rb`.
2. **Uszkodzony plik stanu nie resetuje historii (wysoki)** — `record!`
   czyta plik ściśle (`strict_read`): brak pliku → `[]`; nieparsowalny
   JSON albo wartość nie-tablicowa → `Ace::Coworker::Error` "corrupt round
   history at <path>" i plik pozostaje nietknięty na dysku. `read` pozostaje
   pobłażliwy dla czytelników. Testy: uszkodzony-plik→`record!` rzuca,
   poprawna historia zachowana.
3. **Limit 10 rund jest terminalny (średni)** — `RoundRule.acceptable`
   wymaga dodatkowo `full_rounds <= MAX_FULL_ROUNDS`; spełnienie reguły w
   rundzie 11+ daje `:escalate`, nie `:accept`. Test regresyjny: 10 rund
   z nierozwiązanym High + rozwiązująca runda 11 + czysta 12 → `:escalate`;
   dotychczasowy test sukcesu w rundzie 10 nadal przechodzi.
4. **Walidacja kształtu rekordu na granicy molekuły (średni)** — nowy czysty
   atom `Atoms::RoundRecordSchema.errors` (wzorzec `RolePresetSchema`):
   type ∈ full|delta, status ∈ completed|aborted, confirmed = tablica hashy
   z niepustymi stringami id+severity, resolved = tablica niepustych
   stringów; błędy per pole, nigdy `TypeError`. Walidowany jest nowy rekord
   oraz elementy wczytanej historii. Testy: element nie-Hash, rekord z
   kluczami symbolicznymi, confirmed jako pojedynczy Hash.
5. **Mapa właścicieli stanu (średni)** — nowy wiersz
   `.ace-local/coworker/review-rounds/` (właściciel: rola reviewer w
   coworkerze) w `docs/lab-flow.md`; `docs/tools.md` ma tabelę
   state-owners — dodano wiersz również tam.
6. **Sprzątanie tmp (niski)** — `ReviewRoundStore#write` w
   `begin/ensure File.delete(tmp_path) if File.exist?(tmp_path)`; test z
   wymuszonym błędem `rename` potwierdza brak pozostałości `*.tmp.*`.
7. **Nit `reverse_each.each` (niski)** — `round_rule.rb`: zbędne `.each`
   usunięte.

Dodatkowo: udokumentowano (komentarz w `record!` + jawny test
`test_record_is_last_write_wins_under_interleaved_writers`) założenie
jednego pisarza — `record!` to niezsynchronizowany read-modify-write,
współbieżne wywołania są last-write-wins; w lab-flow (jeden executor na
worktree) założenie to jest spełnione z natury. CHANGELOG `[Unreleased]`
dostał nowy punkt o komendzie CLI.

Weryfikacja: `bin/ace-test ace-coworker all` → **311 testów, 1262 asercji,
0 błędów, 0 porażek**.
