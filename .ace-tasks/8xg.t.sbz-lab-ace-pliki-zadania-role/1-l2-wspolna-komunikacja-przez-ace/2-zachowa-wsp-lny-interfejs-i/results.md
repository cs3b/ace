# Wynik realizacji — 8xg.t.sbz.1.2 (L2.3: wspólny interfejs i konfigurowalne adaptery)

Data: 2026-10-18. Ten sam worktree i ten sam PR #383 (fala 1).

## Co powstało

- **`ace-hitl send <ref>`** — jawny krok dostarczenia utrwalonego zdarzenia
  przez skonfigurowane trasy. Interfejs nadawcy niezależny od adaptera:
  przełączenie transportu to czysta zmiana konfiguracji (`hitl.adapters.routes`
  w kaskadzie) — bez zmiany assignmentu ani logiki coworkera.
- **Rejestr adapterów** `Ace::Hitl::Adapters` (duck-typed, lustrowany z
  `Ace::Runtime`): fabryka `register(name, ->(route))`, lazy entrypoint
  `lib/ace/hitl/adapters/<name>.rb`, fail-closed `UnknownAdapterError` z listą
  dostępnych. Przyszły adapter (np. Nervus) nie wymaga zmiany w ace-hitl.
- **Fan-out z izolacją tras** (`Organisms::HitlSender`): każda trasa
  raportuje własny wynik (`:delivered`/`:failed`/`:unavailable`); sukces
  jednej trasy nie ukrywa błędu drugiej; niedostępny adapter nigdy nie
  przełącza się na innego odbiorcę (testy no-rerouting); wyjątek trasy jest
  zawarty, pozostałe trasy działają. Brak skonfigurowanych tras → konkretny
  błąd wskazujący `hitl.adapters.routes`.
- **Wbudowany adapter `terminal`**: wspólny tekst zdarzenia (`Atoms::
  HitlEventText` — prefiks `[HITL question]`/`[HITL report <result>]`,
  `Reply-To:` tylko na pytaniach, kontekst task/assignment/step) trafia do
  pane przez dowolny runtime ace-runtime (tmux/herdr) wybrany w konfiguracji.
- **Adapter `hermes`** (w ace-hitl-hermes 0.8.0): publikuje wspólne
  renderowanie do folderu kanału jako outbound kind `question` (typ zachowany
  w prefiksie body; raporty nigdy nie oczekują odpowiedzi). Jawne ID zdarzenia:
  identyczne ponowienie idempotentne (`already pending`), kolizja z inną
  treścią → `:failed` bez nadpisania, brak folderu → `:unavailable`.
- Wyniki dostarczenia raportowane, nie utrwalane — retencja niedostarczonych
  i ponowienia to 8xg.t.sbz.1.3. Lokalny plik zdarzenia pozostaje trwałym
  zapisem. ace-hitl 0.21.0.

## Kryteria odbioru

- [x] Przełączenie konfiguracji transportu nie wymaga zmiany assignmentu ani
  logiki coworkera; skonfigurowany zestaw tras raportuje własne wyniki —
  trasy wprost z kaskady; `test_fan_out_delivers_shared_text_to_every_route`,
  `test_failing_route_prints_alongside_success_and_exits_one`; smoke: ta sama
  komenda, terminal (herdr) + hermes w jednej konfiguracji, per-route output.
- [x] Niedostępny adapter nie powoduje cichego wysłania do innego odbiorcy;
  przyszły adapter Nervus nie wymaga nowego interfejsu HITL —
  `test_unavailable_route_does_not_hide_other_route_nor_reroute` (zdrowa trasa
  dostaje dokładnie jedną dostawę), test entrypoint-convention w
  `registry_test`; brak zmian interfejsu dla nowego adapteru (duck contract).
- [x] Wynik zgodny z kontraktem i użyteczny — brak nowego właściciela stanu
  (ADR-034); `HitlEvent#recipient/#reply_to` + wspólny tekst konsumowane przez
  adaptery; scenariusze dostawa-i-Reply z prawdziwym folderem kanału
  (korelacja odpowiedzi po dokładnym ID) w `hitl_adapter_test.rb` i lokalne
  wiązanie odpowiedzi w `hitl_sender_test.rb`.

## Weryfikacja

- `bin/ace-test ace-hitl all` — 316 testów, 0 błędów (nowe: registry 7,
  terminal 6, event text 4, route loader 9, sender 7, CLI send 4).
- `bin/ace-test ace-hitl-hermes all` — 197 testów, 0 błędów (nowe:
  `hitl_adapter_test.rb` — 7, w tym realny folder kanału i korelacja
  odpowiedzi po ID).
- Manualny smoke (/tmp/hitl-send): 2 trasy w jednej konfiguracji —
  `lab-terminal (terminal): failed - pane_not_found` +
  `captain-telegram (hermes): delivered - published 8xhln5 to lab01/project`,
  exit 1 (sukces nie ukrywa błędu); ponowne `send` → hermes `already pending`;
  usunięcie tras → `no adapter routes configured; set hitl.adapters.routes
  (.ace/hitl/config.yml)`.
- Lint: wszystkie zmienione .md passed (hitl.wf.md ma 3 wstępne błędy
  frontmatter obecne na HEAD).
