# Wdrożenie nowego laba ACE z RubyGems

Instrukcja dla każdego świeżego środowiska (lab). Obowiązuje po wydaniu L10
(2026-10-20); źródłem prawdy jest dokumentacja dostarczona z gemem:
`gem contents ace-lab` → `README.md` i `docs/usage.md` (schematy
`install.yml` i `.ace/lab/config.yml`, stany kroków, kody wyjścia).

## Wymagania

Ruby ≥ 3.2, git. Żadnego checkoutu repozytorium ACE — wyłącznie RubyGems.

## 1. Instalacja

```bash
gem install ace-lab ace-overseer ace-coworker ace-herdr ace-handbook
```

`ace-handbook` jest potrzebny dla rzeczywistego procesu `work-on-task`; cztery
gemy podstawowe nie gwarantują dostępności całego kontekstu tego procesu.

Zależności (w tym ace-task, ace-hitl, ace-assign, ace-review,
ace-git-worktree) rozwiążą się same z RubyGems. Weryfikacja wersji:

```bash
ace-lab --version && ace-overseer --version && ace-coworker --version && ace-herdr --version
```

Ustaw `ACE_TOOLCHAIN=installed` w środowisku wybranego użytkownika/runtime:

```bash
export ACE_TOOLCHAIN=installed
```

W tym trybie checkout projektu jest źródłem tasków i konfiguracji domenowej,
a nie narzędzi ACE. Nie używaj `bin/ace-*`, `bundle exec` ani lokalnych ścieżek
źródłowych gemów/workflow. Domyślne `auto` służy nadal do developmentu ACE.
Brak zainstalowanej zależności jest błędem gotowości, bez fallbacku do checkoutu.
Sprawdzaj załadowane wersje/ścieżki i `instructions_source` w briefie JSON;
samo `which` nie dowodzi wybranego runtime. Herdr musi przekazać tryb oraz
Ruby/GEM_HOME/GEM_PATH po inicjalizacji powłoki także w ponownie użytym pane.
Istniejący proces nie zmienia środowiska od zmiany konfiguracji workspace.

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
ace-task create "<zadanie>"            # zapisz zwrócony pełny ID
ace-coworker prepare --task <ID> --roles worker,reviewer --to <overseer> --format json
```

`prepare` przygotowuje worktree, assignmenty i konfiguracje ról; nie uruchamia
agenta. Odczytaj zwrócone ścieżki i ID, a w przygotowanym worktree wykonaj:

```bash
ace-coworker start --config .ace-local/coworker/prepare/worker.yml --format json
```

`start` waliduje i renderuje brief; nie wykonuje zadania. Overseer przekazuje
brief do rzeczywistego agenta przez `ace-herdr dispatch` (właściwy workspace,
nowy pane, `--cwd` przygotowanego worktree), a następnie weryfikuje faktyczny
start. Worker prowadzi konkretny assignment, zawsze z jawnym ID:

```bash
ace-assign status --assignment <ID-assignmentu>
ace-assign start --assignment <ID-assignmentu>
ace-overseer process-reports
ace-overseer handoff --task <ID-tasku>
```

Nie wybieraj assignmentu przez przypadkowy domyślny selektor. Wznowienie zachowuje
konfigurację i `toolchain: installed`; nie tworzy nowej próby tylko dlatego, że
terminal zniknął. Raport, przyjęcie wyniku i start następnej roli są osobnymi
zdarzeniami. Przejście tego smoke potwierdza dopiero obserwowany proces i dowody
wykonania, nie sam render briefu lub zaakceptowanie transportu.

## 4. Statusy (odczyt)

```bash
ace-lab status        # konfiguracja laba + stan lokalnych plików
ace-overseer status   # źródła: taski, worktree, kolejka _overseer, attention
ace-herdr status      # terminale / namespace
```

Model właścicieli stanu: [docs/lab-flow.md](lab-flow.md).
