# Wynik wykonania — 8xg.t.sbz.7.0 (L8.1)

Data: 2026-10-19. Branch: `t-sbz-wave-2`, zakres `a25d8e64b..cd5c97c42`.

## Dostarczenie

`ace-lab prepare [--dry-run] [--format table|json] [-q]` (ace-lab 0.11.0 → **0.12.0**) — faza przygotowania laba z zaufanego manifestu:

- manifest `/etc/lab/ace-lab/install.yml` (root-owned, czytany fail-closed przez istniejący `GrantResolver.read_verified`; brak flagi `--manifest` — wybór manifestu przez wywołującego = produkcja uprawnień); `Atoms::InstallSchema` (v1: machine/accounts/directories/keys/roles, wartościowo-wolne błędy, odrzucanie nieznanych kluczy);
- dostawcy idempotentni: `AccountProvisioner` (darwin dscl z GeneratedUID + Password "*", linux useradd; klasyfikowane braki uprawnień/binarium; przewidywanie w dry-run wierne wet-run), `DirectoryProvisioner` (tryb/własność, odmowa symlink/obcego przejęcia, klasyfikacja EPERM/ENOENT/exec_failed/sygnały), `KeyProvisioner` (ed25519, `.ssh`/`.pub`/klucz: lstat-guards, `Dir.mkdir` leaf + re-lstat, fd-based chmod/chown z `O_NOFOLLOW`, odroczony chown `.ssh`, guard `.pub` przed keygenem, odmowa przejęcia obcej pary/`.ssh`, regeneracja `.pub`, fingerprint-only), `RoleVerifier` (wiązanie konta + źródło instrukcji, POSIX per-class + grupy dodatkowe);
- `Organisms::Prepare` (stała kolejność konta→katalogi→klucze→role, propagacja zależności i unresolved-uid, raport JSON z `ok`), CLI render-then-raise (wet failures ≠ 0; dry-run = 0);
- higiena sekretów jako kryterium odbioru: materiał klucza nigdy nie wchodzi do Ruby poza `ssh-keygen -y`; raporty tylko fingerprint; testy-kanarki na 3 warstwach; guard drzewa git dla ścieżek kluczy.

## Kryteria odbioru → dowody

1. **Wykonawca ma dostęp do plików i własnych kluczy; poprawny kontekst** — dostawcy katalogów/kluczy wymuszają własność konta i tryby 0700/0600/0644 (testy realne: ssh-keygen w tmpdir, chown na własny uid); manifest nazywa machine/konta/role.
2. **Brak uprawnienia zgłaszany; sekret nie trafia do Git/spec/args/raportów** — klasyfikowane EPERM/euid/enoent/exec_failed/sygnał; guard `.git`; kanarki sekretów; błędy wartościowo-wolne; argv arrays (ADR-031).
3. **Zgodność z kontraktem, użyteczny przez następne narzędzie** — raport JSON deterministyczny (kontrakt dla 7.1 `project add` / 7.2 `install`); granice L8.2–L8.5 udokumentowane w usage.md.

## Weryfikacja

- `bin/ace-test ace-lab all` → **333 testy, 1456 asercji, 0 failed**, 4 skipped (pre-existing).
- `bin/ace-test-suite` → 52 pakiety, 12 119 testów, 0 failed (stan po implementacji; finałowa bramka PR ponowi pełny suite).
- `bin/ace-lint` zmienionego markdown: bez nowych klas ostrzeżeń.

## Review (6 rund, pełna konwergencja)

- R1 `review-8xhxmu`: 1×Critical (symlink privilege hazard) + 1×High (dry-run misprediction) + 7 dalszych — naprawione (`74c16e4dd`, `42e5e9ab6`).
- R2 `review-8xhxzx`: 2×High (wet `existing` przez symlink `.ssh`; TOCTOU create) + F-3..F-8 — naprawione (`a5e89ab9b`, `97378bdb7`, `30d057dda`, `0bd7b002f`).
- R3 `review-8xhydw`: 1×High (path-based chmod/chown klucza prywatnego) + Medium/Low — naprawione (`3a3a13e19`); 2 itemy odroczone celowo (skip z uzasadnieniem).
- R4 `review-8xhysi`: 1×High (SystemCallError leak) + M1–M3/L1–L2 — naprawione (`bad7c30b3`, `12f6c5c8a`).
- R5 `review-8xhz37`: 1×High (brak guardu `.pub` na generate) + reszta — naprawione (`3de8b95a8`).
- R6 `review-8xhzg3`: **verdict: brak Critical/High — mergeable**; 3 niskie action-items (odrzucenie nieznanych kluczy manifestu; 4. limit predykcji udokumentowany; test JSON wet-failure) — naprawione (`cd5c97c42`).
- Wszystkie feedback items resolved `fixed` (R1: 9, R2: 10, R3: 8+2 skip, R4: 6, R5: 6); R6 action-items applied bez itemów (niskie, po konwergencji).
- Zaakceptowane resztki (udokumentowane w usage.md): mikroskopijne okno re-lstat→path-based chmod/chown na liściu katalogu (brak fd-based dir chmod w stdlib); zawężony keygen rename-race (materiał root-owned 0600); pesymistyczna predykcja przy patologicznym uid-reuse.

## Commity (zakres 7.0)

`ceeb32894`, `50ee5425c`, `74c16e4dd`, `42e5e9ab6`, `a5e89ab9b`, `97378bdb7`, `30d057dda`, `0bd7b002f`, `3a3a13e19`, `bad7c30b3`, `12f6c5c8a`, `3de8b95a8`, `cd5c97c42`.
