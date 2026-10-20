# Wyniki — 8xg.t.sbz.7.4 „Weryfikować gotowość pod docelowymi kontami" (L8.5)

Data: 2026-10-19 · Branch: `t-sbz-wave-3` (worktree `.ace-wt/t-sbz-wave-3`) ·
ace-lab [Unreleased] (bez bumpu wersji — fala L8 trwa; wpis w CHANGELOG).

## Kryteria odbioru (cytat ze specyfikacji) i mapowanie

> - [ ] Dostęp do worktree, konfiguracji i odpowiedniego klucza oraz
>   komunikacja są potwierdzone dla rzeczywistego wykonawcy, nie tylko
>   konta instalatora.
> - [ ] Brak pliku, złe uprawnienia, rola lub niedziałający adapter
>   uniemożliwiają oznaczenie laba jako gotowego.
> - [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia
>   przez następną rolę lub narzędzie.

### 1. Gotowość potwierdzona pod docelowymi kontami (nie kontem instalatora)

Nowa komenda **`ace-lab verify [--format table|json] [-q]`** (organizm
`Organisms::Verify`, komenda `CLI::Commands::Verify`) — wyłącznie
odczyt, rekomputuje fakty z TYCH SAMYCH artefaktów, z których
install/resume wywodzą prawdę (manifest zaufany, bity uprawnień i
własność na plikach, repozytoria, rejestr per-projekt
`.ace/lab/config.yml`, zaufany dokument grants), patrz punkt 3.

Sekcje sprawdzeń (każde pass/fail/unknown + konkretny powód):

- **accounts** — konto istnieje (passwd), home zgodny z manifestem,
  login shell używalny (`nologin`/`false` blokuje gotowość);
- **directories** — deklarowany katalog istnieje, tryb zgodny z
  manifestem, właściciel = uid konta;
- **keys** — para używalna: tryby 0600/0644/`.ssh` 0700, własność
  konta ORAZ fingerprint publicznej połowy zgodny z kluczem
  wyliczonym z prywatnej — **reuse**: dokładnie ta sama sonda, którą
  stosuje `prepare` (uczyniona publiczną jako
  `KeyProvisioner#pair_fingerprint`, bez reimplementacji);
- **roles** — instrukcje czytelne dla konta roli — **reuse**:
  `RoleVerifier` z L8.1 (bity statyczne + reachability + grupy
  dodatkowe);
- **repositories** — ścieżka jest toplevel repozytorium, origin zgadza
  się z manifestem; lokalne origin → sonda `git ls-remote`
  (przez seam argv, ADR-031); sieciowy origin → **unknown**
  („requires network; not probed by the read-only verifier”);
- **grants** — dokument zaufany istnieje/weryfikowalny
  (seam `trusted_read`, domyślnie `GrantResolver.read_verified`) i
  każdy principal manifestu widzi swoje projekty przez **realne
  mechanizmy odczytu** (`CallerAuthorizer#authorized_project_ids`);
- **registry** — projekt zarejestrowany w `.ace/lab/config.yml`
  (widoczność w kaskadzie: `ace-lab projects`/`ace-overseer projects`);
- **overseer** — `.ace-tasks/_overseer/` istnieje i jest ignorowany
  przez **prawdziwe reguły Git** (`git check-ignore`), zgodnie z
  duchem ADR-034 (nigdy nie zgadujemy z nazwy folderu).

Dowód „fresh == resumed” (brak ukrytych luk po resume):
`test_resumed_install_verifies_ready_with_no_hidden_gaps` buduje stan
po awarii (katalogi+klucz+tylko atlas, bez grants), dokańcza
instalację re-runem (L8.4) i weryfikuje ready. Test
`test_read_only_verification_mutates_nothing` dowodzi odczynności
(inode klucza, bajt w bajt dokument grants i rejestr).

### 2. Brak pliku / złe uprawnienia / rola blokują oznaczenie gotowości

`ready` = false przy KAŻDYM nieudanym checku; raport renderuje się
najpierw w całości (porażka vedle zdrowych danych — nic nie jest
ukrywane), potem komenda kończy się niezerowym exitem z listą
`lab is not ready (N failed check(s)): <sekcja>/<item>: <powód>`.
Przypadki udowodnione w testach (każdy z izolacją — zdrowe dane
przechodzą obok porażki):

- tryb klucza prywatnego 0644 → fail tylko keys
  (`test_wrong_private_key_mode_fails_only_the_key_check`);
- podmieniona połowa publiczna → fingerprint niedostępny, „not
  usable” (`test_swapped_public_key_fails_the_pair_usability_check`);
- brak pliku instrukcji roli → fail tylko roles
  (`test_missing_instructions_file_fails_only_the_role_check`);
- brak konta → fail accounts + zależne keys/roles, repozytoria i
  grants dalej sprawdzone
  (`test_missing_account_fails_account_and_dependent_checks`);
- shell `nologin` → fail accounts
  (`test_non_login_shell_blocks_readiness_under_the_target_account`);
- brak dokumentu grants → fail widoczności przy zdrowym pozostałym
  stanie (`test_missing_grants_document_fails_visibility_without_hiding_health`);
- częściowe grants → fail principalu z listą brakujących projektów
  (`test_partial_grants_fail_the_principal_with_the_missing_project`);
- `_overseer` wypięte z .gitignore → fail overseer dla tego projektu,
  drugi projekt dalej pass
  (`test_overseer_folder_not_gitignored_fails_the_overseer_check`);
- brak wpisu w rejestrze → fail registry dla tego projektu
  (`test_missing_registry_entry_fails_project_visibility`);
- obcy origin → konkretna odmowa
  (`test_foreign_origin_mismatch_is_a_concrete_failure`);
- nieosiągalny lokalny origin → fail „is not reachable”
  (`test_unreachable_local_origin_is_a_concrete_failure`);
- sieciowy origin → **unknown**, NIE blokuje ready
  (`test_network_remote_origin_is_reported_unknown_but_not_a_failure`)
  — decyzja: unknown ≠ failure; „udawanie” porażki sieciowej
  czyniłoby verify bezużytecznym offline (brak danych jest raportowany
  jawnie w counts.unknown).

CLI: happy path renderuje tabelę z `Result: ready` i exit 0; porażka
renderuje raport, potem błąd z konkretnym powodem; `--format json`
wydaje stabilny schemat `ready/machine/manifest/authorization_path/
checks/counts` (`test/commands/verify_test.rb`, 3 testy).

### 3. Zgodność z kontraktem i używalność

- ADR-034 / kontrakt: **zero** nowych właścicieli stanu — verify nic
  nie pisze (dowód inode/bajt w bajt w testach); prawda wyłącznie z
  artefaktów istniejących właścicieli; brak journala/markerów/cache.
- Raport install NIE jest utrwalany nigdzie — dlatego verify
  konsumuje artefakty bezpośrednio (manifest + filesystem + zaufany
  dokument + rejestr), a stabilny JSON schemat grants (utrwalony w
  .7.3) pozostaje zgodny z odczytem verify.
- argv seams (ADR-031): git/ssh-keygen tylko przez `runner`;
  passwd przez `account_lookup`; zaufany odczyt przez `trusted_read`
  — testy bez kont sieciowych i bez prawdziwego /etc.
- `docs/lab-flow.md` BEZ zmian — nie pojawił się nowy rodzaj
  artefaktu (oczekiwanie spełnione).

## Decyzje

1. **Reuse zamiast reimplementacji**: fingerprint pary jako publiczna
   sonda tylko-do-odczytu na `KeyProvisioner`; `RoleVerifier` i
   `CallerAuthorizer` użyte wprost; `_overseer` sprawdzany przez
   `git check-ignore` (realne reguły Git, nie parser .gitignore).
2. **Network remote = unknown, nie fail** — brak danych nie jest
   porażką, jest jawnie raportowany („missing data is not readiness”
   spełnione odwrotnie: porażka wymaga faktu, nie domysłu).
3. **Login class** zrealizowany jako shell z passwd (nologin/false →
   fail); nil shell → pass (nieznany, nie zabójczy) — realne wpisy
   passwd zawsze mają shell.
4. **Sekcja grants** zawiera syntetyczny check dokumentu
   (`(document)`) + checky per principal — jednolity schemat kluczy
   (`principal/status/reason/projects`).
5. Poprawka produktowa przy okazji: wewnętrzna sonda pary mogła
   zwracać `false` zamiast `nil` (znormalizowane; wpisy Fixed).

## Zmienione pliki

- Implementacja (nowe): `ace-lab/lib/ace/lab/organisms/verify.rb`,
  `ace-lab/lib/ace/lab/cli/commands/verify.rb`.
- Implementacja (zmienione): `ace-lab/lib/ace/lab/molecules/
  key_provisioner.rb` (publiczna sonda `pair_fingerprint`,
  normalizacja nil), `ace-lab/lib/ace/lab/cli.rb` (rejestracja),
  `ace-lab/lib/ace/lab.rb` (require), `ace-lab/test/test_helper.rb`
  (FakeEntry + shell).
- Testy (nowe): `ace-lab/test/organisms/verify_test.rb` (15),
  `ace-lab/test/commands/verify_test.rb` (3).
- Dokumentacja: `ace-lab/CHANGELOG.md` ([Unreleased] Added/Fixed),
  `ace-lab/docs/usage.md` (sekcja „Verify (L8.5)” + odświeżone
  akapity o falach L8).
- Brak zmian: `docs/lab-flow.md`.

## Weryfikacja

`bin/ace-test ace-lab all` → **489 testów, 2290 asercji, 0 failures,
0 errors, 4 skipped** (baseline 471; +18 nowych; skipy istniejące,
środowiskowe — żaden z nowych plików nie skipuje na tej maszynie).

## Scenariusze NIEwykonane (wymagają realnego laba — uczciwie)

- Realne konta systemowe (dscl/useradd), realne uid-y obcych
  właścicieli, realny `/etc/lab/ace-lab/` — w testach wyłącznie seam
  passwd i seam zaufanego odczytu (tworzenie kont pozostaje pokryte
  testami molekuł L8.1).
- Sieciowy origin (ssh://forge, https) — celowo NIE sondowany przez
  verify (unknown); realne `git ls-remote`/klonowanie po SSH pod
  docelowym kontem do przetestowania na realnym labie (L9 full-flow).
- „Komunikacja” w sensie adapterów HITL (hermes/herdr): poza zakresem
  tego slice'u — weryfikacja sprawdza pliki, uprawnienia, role i
  drogi komunikacji, które artefakty opisują (grants/registry/klucze);
  konfiguracja adapterów nie jest orchestrowana przez L8 (patrz
  granice w .7.3).
- `ace-overseer projects` jako osobny proces pod kontem docelowym —
  verify potwierdza widoczność przez te same mechanizmy odczytu
  (CallerAuthorizer + registry); pełny e2e z realnym kontem — L9/L10.

## Poprawki po review (runda 1)

Session `review-8ximnw`, werdykt Approve, 10 findingów (2 Medium, 8 Low; 4 skipped). Applied:
1. (M1) origin_url czyta surowy URL (`git config --get remote.origin.url`) — brak fałszywych mismatchy przez `insteadOf`.
2. (M2) Odmowa „dubious ownership" git rozpoznawana (stderr) w rev-parse i check-ignore → akcjonowalny powód (safe.directory / konto właściciela), nie „not a Git repository"; +test runner-stub.
3. (L1) Niezaufany dokument grants → syntetyczny fail checku `(document)` zamiast przerwania całego raportu; +test.
4. (L2) Przeredagowany UNKNOWN: „not a local-path remote; not probed".
5. (L3) usage.md: klauzula o efemerycznym tmpdir scratch przy fingerprint probe.
6. (L4) `principals` usuwany ze syntetycznego checku w JSON (jednolity schemat).
7. (L5) `out.lines.first` w sprawdzaniu toplevel (odporność na multi-line).
Skipped: niezależne odpalenie suity (bramka Lead), refaktor label_for, guard SECTION_LABELS (kosmetyka).
Retest: `bin/ace-test ace-lab all` → 491/2304/0.
