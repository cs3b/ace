# Handoff dla agenta zarządzającego labem — uruchomienie 8xs.t.pu0

Data: 2026-10-30. Wszystko poniżej jest już opublikowane/scalone; nic nie
wymaga checkoutu tego repo jako runtime.

## Stan wyjściowy

- PR #398 **MERGED** do main (`317796f56`); 53/53 pakietów zielone.
- **9 gemów na RubyGems** (wydane 2026-10-30): ace-lab 0.14.0,
  ace-overseer 0.27.0, ace-coworker 0.7.0, ace-hitl 0.25.0, ace-wake 0.1.0,
  ace-git 0.32.0, ace-handbook 0.37.0, ace-handbook-integration-pi 0.8.0,
  ace-herdr 0.9.0 (ace-hitl-hermes ≥0.9.6 z rubygems jako zależność transportu).
- Digesty: `docs/release-artifacts-sha256.md` w tym tasku (r4, z e45dbbc05 —
  kod 9 gemów niezmieniony od buildu).

## 1. Instalacja runtime na labie (subzadanie .0)

```bash
export ACE_TOOLCHAIN=installed
gem install ace-lab -v 0.14.0        # pociągnie zależności (ace-overseer, ace-git, ace-handbook…)
gem install ace-coworker -v 0.7.0 ace-hitl-hermes   # role + transport
```

- Pracuj w **katalogu koordynacyjnym laba** (lab root, NIE repo ACE):
  `ace-lab install` wg manifestu gemset (konwergencja gemów + rozszerzeń
  `extensions_package`); verify: `ace-lab verify` — wszystko `ok`.
- **Zapisz manifest instalacyjny** jako `.ace-local/release/installation-manifest.json`
  (wymagany przez `ace-test-e2e ace-monorepo-e2e TS-MONO-001` — proof
  propagacji release'u).
- Izolacja: projekt zawierający checkout ACE NIE może go używać jako
  runtime — w trybie installed zawsze installed launcher (sprawdź:
  `ace-overseer start --dry-run` w takim projekcie wskazuje installed bin).

## 2. Topologia i uprawnienia

- `~/.ace/lab/config.yml` (w lab root: `.ace/lab/config.yml`):
  `topology.projects: [{id, path}]` — każda ścieżka to projekt z własnym
  nadzorcą (subzadanie .a).
- HITL: `.ace-local/hitl/config.yml` z `machine` + `recipients`
  (Kapitan przez panel; nadzór przez folder).
- Auth (subzadanie .7): profile w configu GrantResolver:
  - **forgejo**: admin PAT jako `issuer`; scope `poziom:subject`
    (np. `write:repository` → RepoTargetOption `owner/name` — wpisuj
    repo jako `owner/name`, NIE gołą nazwę — puste/ownerless = odmowa);
    tokeny mają deterministyczną nazwę `ace-lab-<lease-id>` (recovery po
    utracie odpowiedzi działa po nazwie).
  - **github**: App installation; scope = prawdziwe nazwy permission
    endpointu (`write:contents`, `read:pull_requests`…; `write:repository`
    jest NIEPRAWIDŁOWE i zostanie odrzucone).
- **Host revoke scheduler** (brak daemona z założenia, ADR-034):
  dodaj cron/host-job wołający `ace-lab auth reconcile` (np. co 5 min) —
  bez tego token wygasa tylko naturalnie po `use_until`.

## 3. Start laba (subzadania .1/.a)

```bash
cd <lab-root> && ace-overseer start --scope lab
```

Oczekiwane: status `ready`, sesja nadzorcy laba w space `lab-overseer`,
**każdy projekt we własnym space** (`overseer-<project>`), pierwsza tura
potwierdzona (brak `prompt_failed`). Restart/ponowny start naprawia braki,
nie restartuje zdrowych sesji. Obserwacja: /eyes uzbrojone przez standing
instructions; `ace-overseer status` / `observe` pokazuje źródła lokalne
+ `observe.remote.pull_requests` (jeśli skonfigurowane).

## 4. Transport Hermes → reply (subzadanie .5)

- `ace-hitl-hermes plugin install` wg guide'a transportu; sparuj folder
  HITL ownera (tam gdzie `ace-hitl reply CASE --stdin` ma działać).
- Cykl do odbioru: ask (może być `--secret` dla OTP) → deliver przez
  Hermes → `ace-hitl-hermes sync` → odpowiedź ląduje w sprawie
  (`answered: true`) → wznowienie. Przetestuj **duplicate** (identyczna
  odpowiedź = no-op) i **late reply po cancel** (odmowa, plik nietknięty).

## 5. Odbiór: zimny cykl (subzadania .e/.f)

Wykonaj scenariusz **`wfi://overseer/cold-cycle-acceptance`** (guide w
ace-handbook 0.37.0) na co najmniej 2 projektach:

1. Cold start od zera (nowy lab root, instalacja, topologia, start).
2. Pełny cykl: task → cowoker (worker/reviewer/second-captain) → review →
   gate (`ace-coworker gate --candidate-head … --tests-head …`) →
   approval → merge → publish (OTP jako sprawa `--secret`).
3. Negative flow: duplicate/late reply, odmowa anonimowego approval,
   przerwany handoff (revoke-pending → `revoke --force` lub reconcile).
4. **30 minut ciszy**: zero tur modelu przy niezmienionym stanie
   (zero-idle) — realne okno, nie test zegara.
5. Runtime versions: `loaded_version` z żywych procesów = 9 opublikowanych
   wersji; zapisz manifest + record PR.
6. Po pomyślnym odbiorze: `ace-test-e2e ace-monorepo-e2e TS-MONO-001`
   (proof propagacji) + higiena wg `docs/cleanup-inventory.md`
   (temporary `.ace-bin/` overrides, duplicate routes, stare ask-i).

## Kryteria zamknięcia programu (dowody do zebrania)

- [ ] manifest instalacyjny + verify ok na labie
- [ ] sesje: lab overseer + per-project spaces + pierwsza tura potwierdzona
- [ ] Hermes→reply end-to-end (w tym duplicate + late)
- [ ] auth: wydanie→exec→revoke na realnym forge/github + scheduler aktywny
- [ ] cold-cycle acceptance ≥2 projekty + 30-min zero-idle
- [ ] loaded_version = wydane wersje; TS-MONO-001 SAFE
- [ ] record PR + closing report z live evidence

Punkty 5–6 sekcji „Do wykonania po merge" w `docs/endgame-status.md`
zostają spełnione właśnie tym odbiorem.
