# Wynik realizacji — 8xg.t.sbz.1.1 (L2.2: adresowanie odbiorców i Reply)

Data: 2026-10-18. Ten sam worktree i ten sam PR #383 (fala 1).

## Co powstało

- **Adres odbiorcy z konfiguracji** (`--to <name>` lub `default_recipient`):
  maszyna + folder zdarzeń + ID sprawy (forma folderowa; ID stemplowane z
  nowego zdarzenia) albo maszyna + panel (forma panelowa). Konfiguracja w
  kaskadzie `hitl` (`machine`, `default_recipient`, `recipients`); czyta ją
  HITL — konsument podaje skonfigurowaną nazwę bez własnego routingu.
  Nowe: `Atoms::HitlAddress` (czysta walidacja/format, display zgodny z
  kształtem hermes `<machine>/<folder>/<id>` / `<machine>/panel/<panel>`) i
  `Molecules::HitlAddressResolver` (resolve/default/sender_address,
  fail-closed).
- **Reply wiąże się z pierwotną sprawą**: pytania zapisują `reply_to`
  (maszyna nadawcy + jego folder zdarzeń + własne ID sprawy). Lokalna
  odpowiedź to nadal `update <ref> --answer` wiązany dokładnym ID; transport
  (1.2) przekaże ten sam kontekst zamiast szukać „ostatniego pytania”.
  Task/assignment/step pozostają kontekstem, nie zamiennikiem ID.
- **Fail-closed przed zapisem**: nieznana nazwa odbiorcy (z listą
  skonfigurowanych), niepoprawny adres w konfiguracji, brak `hitl.machine`
  — jawne błędy, nic nie zostaje zapisane. Niejednoznaczny skrót ID →
  `AmbiguousReferenceError` z kandydatami; nieistniejące ID → not found;
  cudze zdarzenie nigdy nie dostaje odpowiedzi (testy regresyjne).
- **Naprawiony siedzący bug**: `HitlConfigLoader` podwójnie opakowywał
  namespace (`{"hitl" => {"hitl" => …}}`), przez co nadpisania
  konfiguracji w produkcji nigdy nie działały. Teraz akceptuje pliki
  z kluczem `hitl:` i płaskie (konwencja jak w ace-git-commit), z testami
  regresyjnymi.
- `show`/create wypisują `Recipient:`/`Reply-To:`; `HitlEvent#recipient`/
  `#reply_to` wystawiają hashe adresów dla adapterów (dostawa w .1.2/.1.3;
  zapis lokalny ≠ dostarczenie). ace-hitl 0.19.0 → 0.20.0 (pin hermes
  ~> 0.20.0).

## Kryteria odbioru

- [x] Dwa worktree z różnymi pytaniami otrzymują swoje Reply; raport można
  powiązać z właściwym taskiem i assignmentem — test
  `test_two_worktrees_each_answer_their_own_event` (osobne rooty, scope
  current, każde zdarzenie odpowiedziane dokładnie swoim Reply);
  `test_report_carries_recipient_but_no_reply` wiąże raport z
  taskiem/assignmentem.
- [x] Nieznany odbiorca lub niepasujące ID daje jawny błąd i nie zapisuje
  odpowiedzi w cudzym zadaniu — `test_unknown_recipient_writes_nothing`,
  `test_repeated_shortcut_is_ambiguous_and_writes_no_answer`,
  `test_missing_id_is_not_found_and_writes_nothing` + odpowiedniki CLI.
- [x] Wynik zgodny z kontraktem i użyteczny przez następne narzędzie — płaskie
  klucze frontmatter + `#recipient`/`#reply_to`; help CLI utrwala `--to`.

## Weryfikacja

- `bin/ace-test ace-hitl all` — 278 testów, 0 błędów (nowe: atom 11,
  resolver 9, manager addressing 10, CLI addressing 6, loader 2).
- Manualny przebieg (/tmp/hitl-addr z `.ace/hitl/config.yml`):
  `create --to overseer` → `Recipient: lab01/.ace-local/hitl/8xhkep`,
  `Reply-To: lab01/.ace-local/hitl/8xhkep`; `--to ghost` → „Unknown HITL
  recipient 'ghost'. Configured recipients: captain, overseer”.
- Lint: usage/README/CHANGELOG passed.
