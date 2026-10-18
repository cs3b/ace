# Wynik realizacji — 8xg.t.sbz.1.3 (L2.4: retencja i ponowienia niedostarczonych)

Data: 2026-10-18. Ten sam worktree i ten sam PR #383 (fala 1).

## Co powstało

- **Retencja na pliku zdarzenia** (jedyny właściciel stanu — ADR-034, zero
  journala/kolejki): `send` utrwala w frontmatterze zdarzenia
  `delivery.<route>.{status, adapter, detail, attempted_at}` — wynik,
  powód błędu i znacznik czasu ostatniej próby każdej trasy. Przed każdym
  wywołaniem adaptera zapisywany jest marker `in_flight`: awaria procesu w
  trakcie dostawy zostawia wynik NIEZNANY, który kolejny `send` ponawia
  (at-least-once — duplikat możliwy, odbiorca rozpoznaje po case ID;
  exactly-once nie jest obiecane).
- **Ponawianie dostawy sprawy, nie zadania**: domyślny `send` ponawia
  wyłącznie trasy niedostarczone/nieznane i pomina potwierdzone delivered;
  `--force` ponawia wszystkie (to samo ID sprawy, ta sama treść, to samo
  powiązanie taska — renderowanie odtwarzane z pliku zdarzenia);
  `--dry-run` pokazuje decyzje bez dostawy i bez zapisu. Ponowienie
  w pełni dostarczonego zdarzenia to no-op sukces (exit 0).
- **Widoczność**: `list --delivery undelivered|delivered` odkrywa zatrzymane
  zdarzenia; `show` wypisuje blok `Delivery:` z zatrzymanym powodem błędu.
- cząsteczka `HitlDeliveryState` (czysta logika decyzji); sender rozszerzony
  o `force:`/`dry_run:`/`now_proc:`; FieldUpdater (flock, atomowy zapis
  zagnieżdżonych kluczy) jako prymityw utrwalania. ace-hitl 0.22.0;
  ace-hitl-hermes 0.8.1 (tylko dokumentacja — adapter bez zmian:
  identyczne ponowienie już idempotentne, ponowienie po konsumpcji to
  uzasadniony duplikat rozpoznawany po ID).

## Kryteria odbioru

- [x] Po przywróceniu transportu zachowany raport trafia do overseera z tym
  samym powiązaniem do taska — test
  `test_retry_after_transport_restoration_delivers_same_case_and_task`
  (niedostępna trasa → failure zatrzymany; trasa zdrowa → delivered z tym
  samym `(case ID)` i `Task:`); smoke na żywo: folder ukryty →
  `unavailable - ContractError: hermes folder does not exist` → folder
  przywrócony → `delivered - published 8xhmbc` (to samo ID).
- [x] Utrata potwierdzenia dostarczenia i ponowienie nie wykonują ponownie
  assignmentu ani nie odblokowują następnego kroku dwa razy — test
  `test_stale_in_flight_marker_is_unknown_and_retried_with_same_id`
  (symulacja crash: odbiorca przyjął, potwierdzenie zaginęło; ponowienie
  niesie identyczne ID i treść — duplikat identyfikowalny; asercja, że
  ponowienie wykonuje wyłącznie dostawę: brak resume, brak zapisu
  odpowiedzi, status `recorded` nietknięty). Faktyczne nieuruchomienie
  kroku drugi raz odbieramy w .5.4 (zgodnie ze specyfikacją).
- [x] Wynik zgodny z kontraktem i użyteczny — retencja w pliku zdarzenia
  (ADR-034), `list --delivery`/`show` dla następnej roli; partially
  delivered stan przeżywa abort (test
  `test_unknown_adapter_abort_retains_attempted_route_records`).

## Weryfikacja

- `bin/ace-test ace-hitl all` — 336 testów, 0 błędów (nowe: delivery state
  6, sender retention 8, CLI retention 6).
- `bin/ace-test ace-hitl-hermes all` — 197 testów, 0 błędów.
- Manualny smoke (/tmp/hitl-retry): pełny cykl unavailable → restored →
  delivered → no-op skip → `list --delivery undelivered` puste; `show`
  wypisuje `Delivery: captain-telegram (hermes): delivered - published
  8xhmbc to lab01/project (2026-10-18T14:52:39Z)`.
- Lint: wszystkie zmienione .md passed.
