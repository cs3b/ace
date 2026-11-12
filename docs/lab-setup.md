# Wdrożenie i aktualizacja laba ACE z RubyGems

Instrukcja uruchomienia nowego środowiska (lab) oraz aktualizacji działającego
laba do najnowszych wydań z RubyGems (stan na `2026-11-12`: `ace-lab 0.16.1`,
`ace-overseer 0.31.0`, `ace-coworker 0.10.0`, `ace-hitl 0.27.0`,
`ace-wake 0.4.0`, `ace-herdr 0.11.2`). Źródłem prawdy dla schematów są pliki
dostarczane z gemami: [ace-lab/docs/usage.md](../ace-lab/docs/usage.md),
[ace-overseer/docs/usage.md](../ace-overseer/docs/usage.md),
[ace-herdr/docs/usage.md](../ace-herdr/docs/usage.md) oraz mapa właścicieli
stanu w [docs/lab-flow.md](lab-flow.md).

## Wymagania

Ruby ≥ 3.2 (zalecane 3.4), Bundler, Git, Node.js (dla Pi oraz rozszerzenia
`ace-wake`) i natywne binarium `herdr` dopasowane do wersji gemu `ace-herdr`
(`ace-herdr native-source verify`). Żadnego checkoutu repozytorium ACE jako
źródła wykonywania — wyłącznie zainstalowane gemy (`ACE_TOOLCHAIN=installed`).

## 1. Instalacja bazowa i `ACE_TOOLCHAIN=installed`

```bash
gem install \
  ace-lab:0.16.1 \
  ace-overseer:0.31.0 \
  ace-coworker:0.10.0 \
  ace-hitl:0.27.0 \
  ace-wake:0.4.0 \
  ace-herdr:0.11.2 \
  ace-handbook
```

`ace-handbook` (oraz `ace-handbook-integration-pi`) dostarcza instrukcje
`wfi://...` dla procesu `work-on-task` i ról nadzorcy/wykonawców. Pozostałe
zależności (`ace-task`, `ace-assign`, `ace-review`, `ace-git`,
`ace-git-worktree`) rozwiążą się automatycznie z RubyGems lub przez zablokowany
bundle zarządzany przez `ace-lab install`.

Weryfikacja wersji CLI:

```bash
ace-lab --version && ace-overseer --version && ace-coworker --version && ace-hitl --version && ace-herdr --version
```

W środowisku wykonawczym ustaw:

```bash
export ACE_TOOLCHAIN=installed
```

W trybie `installed` checkout projektu jest wyłącznie źródłem zadań i
konfiguracji domenowej, a nie kodu ACE. Nie używaj `bin/ace-*`, `bundle exec`
względem checkoutu projektu ani lokalnych ścieżek gemów. Brak zainstalowanej
zależności jest błędem gotowości (bez fallbacku do źródeł repozytorium).

## 2. Ścieżka A — lokalna rejestracja projektu (bez roota)

Dla pojedynczego konta deweloperskiego wystarczy `ace-lab project add`:
rejestruje repozytorium, tworzy prywatny katalog `.ace-tasks/_overseer/`
(ignorowany przez Git) i dopisuje projekt w `<path>/.ace/lab/config.yml`:

```bash
mkdir -p ~/Labs/<projekt> && cd ~/Labs/<projekt> && git init
ace-lab project add <projekt> --path "$PWD"
ace-lab status                 # oczekiwane: configured + projekt
```

## 2'. Ścieżka B — pełny install z manifestu (`/etc/lab/ace-lab/install.yml`)

Dla autonomicznego laba управляanego przez manifest wdrożeniowy administrator
umieszcza plik `/etc/lab/ace-lab/install.yml` (własność `root:root`, tryb
`0644`; brak flagi `--manifest` jest celowy — manifest musi leżeć poza kaskadą
zapisywalną przez agentów):

```yaml
schema_version: 1
machine: lab01
accounts:
  - username: mo
    role: overseer
    create: false
    home: /home/mo
directories:
  - path: /lab
    owner: mo
    mode: "0755"
roles:
  - { id: lab-overseer, account: mo, instructions: "wfi://overseer/lab-start" }
  - { id: project-overseer, account: mo, instructions: "wfi://overseer/start" }
  - { id: worker, account: mo, instructions: "wfi://coworker/worker" }
  - { id: verifier, account: mo, instructions: "wfi://coworker/reviewer" }
  - { id: integrator, account: mo, instructions: "wfi://coworker/integrator" }
coordinator:
  id: lab
  path: /lab
  environment_files:
    lab-overseer: /home/mo/.config/ace/lab-overseer.json
projects:
  - id: ace
    path: /lab/ace
    remote: git@forge:org/ace.git
    label: ACE
    environment_files:
      project-overseer: /home/mo/.config/ace/ace-overseer.json
      worker: /home/mo/.config/ace/ace-worker.json
      verifier: /home/mo/.config/ace/ace-reviewer.json
      integrator: /home/mo/.config/ace/ace-integrator.json
      second-captain: /home/mo/.config/ace/ace-second-captain.json
grants:
  mo: [lab, ace]
gemset:
  gem_home: /opt/ace/runtime/bundle/ruby/3.4.0
  bin_dir: /opt/ace/runtime/bin
  gems:
    - { name: ace-lab, version: 0.16.1 }
    - { name: ace-overseer, version: 0.31.0 }
    - { name: ace-coworker, version: 0.10.0 }
    - { name: ace-hitl, version: 0.27.0 }
    - { name: ace-wake, version: 0.4.0 }
    - { name: ace-herdr, version: 0.11.2 }
    - { name: ace-handbook-integration-pi, version: 0.9.1 }
  extensions:
    - gem: ace-wake
      path: /opt/ace/runtime/pi-extensions
      account: mo
session_runtime:
  node: /opt/ace/toolchains/node/bin/node
  pi: /opt/ace/runtime/pi/node_modules/@earendil-works/pi-coding-agent/dist/cli.js
  path:
    - /opt/ace/runtime/bin
    - /opt/ace/toolchains/ruby/bin
    - /opt/ace/toolchains/node/bin
    - /usr/bin
  provider: zai
  model: glm-5.3
  credentials: /etc/lab/ace-lab/pi-auth.json
  herdr:
    account: mo
    socket: /run/lab/herdr/herdr.sock
```

Wykonanie instalacji i weryfikacji:

```bash
sudo ace-lab install --dry-run   # predykcja zmian bez zapisu
sudo ace-lab install             # jedno wywołanie Bundlera + projekcja rozszerzeń + granty
ace-lab verify --format json     # odczytowa weryfikacja gotowości pod kontami docelowymi
```

## 3. Aktualizacja istniejącego laba (Upgrade do nowych wydań)

Aby zaktualizować działający lab do nowego zestawu wydań:

1. **Zaktualizuj wersje w `/etc/lab/ace-lab/install.yml`** w sekcji `gemset.gems`
   (np. `ace-lab: 0.16.1`, `ace-overseer: 0.31.0`, `ace-coworker: 0.10.0`,
   `ace-hitl: 0.27.0`, `ace-wake: 0.4.0`, `ace-herdr: 0.11.2`). Jeśli zmienił się
   kontrakt natywnego Herdr (np. `ace-herdr 0.11.2`), zaktualizuj również
   binarium `herdr` i sprawdź `ace-herdr native-source verify`.
2. **Sprawdź plan zmian i zastosuj konwergencję**:
   ```bash
   sudo ace-lab install --dry-run
   sudo ace-lab install --format json
   ```
   `ace-lab install` instaluje kompletny zestaw jednym wywołaniem Bundlera z
   trwałym `Gemfile`/`Gemfile.lock` w `gem_home` (w razie błędu przywraca
   poprzedni działający lockfile), wystawia binstuby i aktualizuje projekcję
   rozszerzenia `ace-wake` w `gemset.extensions`.
3. **Zweryfikuj gotowość runtime**:
   ```bash
   ace-lab verify
   ```
4. **Przeładuj rozszerzenie `ace-wake` / sesje nadzorców**:
   - Jeśli raport `ace-lab install` zawiera `"restart_required": true` dla
     projekcji `ace-wake`, uruchomione procesy Pi trzymają w pamięci poprzednią
     wersję rozszerzenia.
   - W działających sesjach nadzorców (`/lab` oraz `/lab/<projekt>`) wykonaj
     `/reload` — od `ace-wake 0.4.0` i `ace-overseer 0.31.0` przeładowanie
     automatycznie odtwarza `eyes` z `ACE_OVERSEER_EYES_CONFIG` i zachowuje
     stan okna budżetu, `acknowledged` oraz `pending` bez zerowania liczników.
   - Następnie potwierdź spójność sesji:
     ```bash
     ace-overseer start --scope lab --reconcile --format json
     ```

## 4. Uruchomienie i autonomiczna praca (`ace-overseer 0.31.0`)

### 4.1. Start serwera Herdr i nadzorców (`--scope lab`)

```bash
ace-herdr start --format json
ace-overseer start --scope lab --format json
```

- `ace-overseer start --scope lab` uruchamia (lub uzgadnia z `--reconcile`)
  sesję Lab Overseera w `/lab` oraz sesje Project Overseerów dla każdego
  skonfigurowanego projektu.
- Start przekazuje `ACE_OVERSEER_EYES_CONFIG` w środowisku procesu Pi, dzięki
  czemu rozszerzenie `ace-wake` automatycznie uzbraja `eyes` podczas
  inicjalizacji sesji (zanim pojawi się pierwszy prompt).
- Jeśli nowy projekt nie ma jeszcze własnej konfiguracji `.ace/overseer/config.yml`,
  Lab Overseer deleguje jej przygotowanie i niezależną weryfikację przez role
  `bootstrap-worker` → `bootstrap-verifier` (`wfi://overseer/bootstrap-delegation`),
  a po akceptacji raportu weryfikatora wywołuje `confirm-start`.

### 4.2. Delegacja zadań, odbiór raportów i handoff

W projekcie (lub w `/lab` przy bootstrapie) nadzorca tworzy prywatne zadanie
koordynacyjne (`MANAGER_ID`) w `.ace-tasks/_overseer/` i deleguje wykonanie z
jawnym powiązaniem `--manager`:

```bash
# 1. Start pierwszej roli (np. worker) — zapisuje powiązanie w managerze przed uruchomieniem:
ace-overseer work-on --task <TASK_ID> --manager <MANAGER_ID> --runtime herdr --format json

# 2. Odbiór raportu po przebudzeniu przez eyes:
# W sesji Pi nadzorca używa narzędzia rozszerzenia `process_reports`
# (które wywołuje process-reports i potwierdza dokładne rewizje obserwacji).
# Z poziomu CLI odpowiednikiem dla konkretnego raportu jest:
ace-overseer process-reports \
  --report <REPORT_ID> \
  --manager <MANAGER_ID> \
  --task <TASK_ID> \
  --role <ROLE> \
  --assignment <ASSIGNMENT_ID> \
  --json

# 3. Przekazanie do kolejnej roli z sekwencji (np. worker -> reviewer -> integrator):
ace-overseer handoff --task <TASK_ID> --manager <MANAGER_ID> --runtime herdr --format json
```

- Zwykłe dostarczanie kodu przechodzi przez sekwencję `worker → reviewer → integrator`
  (3/2/10 rund `ace-review` + formalny `APPROVED` od niezależnego konta na
  dokładnym SHA kandydata przed merge’em).
- Operacyjna weryfikacja konfiguracji (`bootstrap-verifier`) sprawdza dowody
  wykonania z raportu workera bez wywoływania `ace-review`, PR ani `integrator`.
- Gdy wszystkie role zadeklarowane w `metadata.roles` zadania managera zostaną
  zaakceptowane, `ReportProcessor` automatycznie zamyka zadanie managera jako
  `done` w `.ace-tasks/_overseer/`.

### 4.3. Decyzje HITL, Second Captain i lekcje (`ace-hitl 0.27.0`)

Gdy pojawia się pytanie decyzyjne do Kapitana (`ace-hitl ask --to captain`):

1. Nadzorca tworzy prywatny manager decyzji (`--in _overseer`) i deleguje rolę
   doradczą `second-captain` (`--hitl-case <CASE_ID>`), która zapisuje w sprawie
   sekcję `Suggestion` (`ace-hitl suggest <CASE_ID> ...`) i kończy pracę.
2. Kapitan odpowiada lokalnie lub przez transport:
   ```bash
   printf 'A\n' | ace-hitl reply <CASE_ID> --stdin
   ```
3. Po przebudzeniu nadzorca stosuje decyzję i zamyka sprawę atomowo wraz z
   lekcją porównującą rekomendację z decyzją Kapitana:
   ```bash
   ace-hitl apply <CASE_ID> --ref <MANAGER_ID>
   ace-hitl close <CASE_ID> --lesson-file < LESSON_FILE >
   ```
   Po zamknięciu powiązanych spraw HITL i zadań potomnych manager decyzji w
   `_overseer` przechodzi w stan `done`.

## 5. Statusy i diagnostyka (odczyt)

```bash
ace-lab status                         # konfiguracja laba + stan lokalnych katalogów
ace-lab verify                         # pełna weryfikacja kont, gemów, rozszerzeń i grantów
ace-overseer status --format json      # źródła: taski, worktree, _overseer, HITL, sesje + podsumowanie operation
ace-herdr status --format json         # żywe workspace'y, panele, agent_status i completion_seq
```
