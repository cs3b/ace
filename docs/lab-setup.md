# Wdrożenie nowego laba ACE z RubyGems

Instrukcja dla każdego świeżego środowiska (lab). Obowiązuje po wydaniu L10
(2026-10-20); źródłem prawdy jest dokumentacja dostarczona z gemem:
`gem contents ace-lab` → `README.md` i `docs/usage.md` (schematy
`install.yml` i `.ace/lab/config.yml`, stany kroków, kody wyjścia).

## Wymagania

Ruby ≥ 3.2, git. Żadnego checkoutu repozytorium ACE — wyłącznie RubyGems.

## 1. Instalacja

```bash
gem install ace-lab ace-overseer ace-coworker ace-herdr
```

Zależności (w tym ace-task, ace-hitl, ace-assign, ace-review,
ace-git-worktree) rozwiążą się same z RubyGems. Weryfikacja wersji:

```bash
ace-lab --version && ace-overseer --version && ace-coworker --version && ace-herdr --version
```

## 2. Ścieżka A — konfiguracja z palca (bez roota)

Bez kont systemowych. Wystarczy `project add` (L8.2): rejestruje repo,
tworzy prywatne `.ace-tasks/_overseer/` i wpis projektu w
`<path>/.ace/lab/config.yml` (kaskada ADR-022).

```bash
mkdir -p ~/Labs/<projekt> && cd ~/Labs/<projekt> && git init
ace-lab project add <projekt> --path "$PWD"
ace-lab status                 # oczekiwane: configured + projekt
ace-lab projects --format json
```

Topologię (agenci/usługi) dopisuje się ręcznie w `.ace/lab/config.yml`
albo `~/.ace/lab/config.yml` — schemat w `docs/usage.md` gemu.
Listing w `ace-lab projects` wymaga grantu z warstwy zaufanej (patrz
ścieżka B); `ace-lab status` działa bez grantów.

## 2'. Ścieżka B — pełny install (realne konta, katalogi, klucze, role)

Dla labów wielokontowych. Administrator umiesza root-owned manifest
w `/etc/lab/ace-lab/install.yml` (`schema_version: 1`; sekcje
`accounts`, `directories`, `keys`, `roles`, `projects`, `grants` —
wszystkie opcjonalne; `create: true` kont wymaga uprawnień
administratora). Świadomie nie ma flagi `--manifest` — dokument
wdrożeniowy musi być poza kaskadą zapisywalną przez wywołującego.

```bash
ace-lab install --dry-run     # predykcja bez zmian
ace-lab install               # prepare → project add → granty; idempotentne,
                               # wznowienie po awarii = ponowne uruchomienie
ace-lab verify                # odczytowa weryfikacja gotowości pod kontami
```

## 3. Praca — sekwencja zadania

```bash
ace-task create "<zadanie>"            # zadania w .ace-tasks/
ace-coworker prepare ...               # worktree/assignmenty wg ról (L4/L5)
ace-coworker start --config .ace-local/coworker/prepare/<rola>.yml
ace-overseer process-reports           # interpretacja raportów + kontynuacja
ace-overseer handoff --task <ref>      # przekazanie worktree kolejnej roli
```

## 4. Statusy (odczyt)

```bash
ace-lab status        # konfiguracja laba + stan lokalnych plików
ace-overseer status   # źródła: taski, worktree, kolejka _overseer, attention
ace-herdr status      # terminale / namespace
```

Model właścicieli stanu: [docs/lab-flow.md](lab-flow.md).
