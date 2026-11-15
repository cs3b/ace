---
doc-type: user
title: Instalacja i upgrade laba ACE
purpose: Bezpieczna aktualizacja zainstalowanego runtime bez resetu pracy laba.
ace-docs:
  last-updated: '2026-11-15'
  last-checked: '2026-11-15'
---

# Wdrożenie i aktualizacja laba ACE z RubyGems

Stan sprawdzony **2026-11-15**. Procedura dotyczy zainstalowanego runtime,
nie bundle'a rozwijanego projektu. Nie resetuje VM, Forgejo, zadań ani sesji.

| Pakiet | RubyGems (sprawdzone API) | Lokalny kandydat użyty w UTM |
|---|---|---|
| ace-lab | 0.16.3 | 0.16.3 (identyczna paczka) |
| ace-runtime | 0.4.3 | 0.4.3 |
| ace-overseer | 0.31.2 | 0.31.2 |
| ace-herdr | 0.11.3 | ten sam |

Publikację potwierdzono przez API konkretnych wersji RubyGems.
**`ace-lab 0.16.3` jest opublikowany i ma identyczną sumę SHA256 jak paczka
sprawdzona na UTM:**
`f7fc76858c393d184ada9b33bc73a75db45d855fe47436a670ea29dfe8f8e482`.
Wcześniejsze lokalne buildy runtime/overseer mają inne sumy niż ich wydania;
nie przedstawiamy całego przebiegu jako testu identycznego zestawu z RubyGems.

**Upgrade na zachowanej UTM sprawdzony:** `ace-lab verify` uruchomione przez
zwykłe SSH zwraca `ready: true`, 69 pass, 0 fail i 1 unknown (zdalny Git,
którego verifier nie odpytuje). Osobny odczyt Git z poświadczeniami
skonfigurowanej roli potwierdził dostęp do Forgejo.
Do upgrade'u starego laba użyj `ace-lab 0.16.3`; naprawia kontekst Ruby/Gem
oraz duplikaty rejestru rozszerzeń obecne w 0.16.2.
Nie jest to nowy pełny przebieg autonomii ani odbiór Omarchy. Istniejące procesy
Pi zachowano; mogą nadal mieć instrukcje wczytane przed aktualizacją.

Źródła kontraktu: [ace-lab](../ace-lab/docs/usage.md),
[runtime bundle](../ace-lab/docs/runtime-bundle.md),
[Overseer](../ace-overseer/docs/usage.md), [Herdr](../ace-herdr/docs/usage.md)
i [właściciele stanu](lab-flow.md). Aktualne ograniczenia odbioru:
[raport instalacji i HITL](../.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/docs/2026-11-15-final-acceptance.md).

## Wymagania

Ruby ≥ 3.2 (zalecane 3.4), Bundler, Git, Node.js (dla Pi oraz rozszerzenia
`ace-wake`) i natywne binarium `herdr` dopasowane do wersji gemu `ace-herdr`
(`ace-herdr native-source verify`). Żadnego checkoutu repozytorium ACE jako
źródła wykonywania — wyłącznie zainstalowane gemy (`ACE_TOOLCHAIN=installed`).

## 1. Instalacja bazowa i `ACE_TOOLCHAIN=installed`

Instalator jest jedynym gemem potrzebnym do bootstrapu. Użyj zatwierdzonej,
opublikowanej wersji `ace-lab`; docelowe pakiety przypina manifest poniżej.
Nie instaluj każdego pakietu osobno i nie uruchamiaj instalatora ze źródeł projektu.
Na starym labie sprawdź rzeczywistą ścieżkę instalatora: samo zainstalowanie
nowszego gemu nie przełącza binstuba zablokowanego starym Gemfile.lock.

Tryb `installed` zapisz w konfiguracji Herdr i Overseera (`toolchain: installed`).
Sesje dostają środowisko z konfiguracji produktu. Nie wymagają ręcznego `source`.
Administrator podczas instalacji również jawnie zachowuje ten tryb:
`sudo env ACE_TOOLCHAIN=installed /pełna/ścieżka/ace-lab install`.

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

Dla autonomicznego laba zarządzanego przez manifest wdrożeniowy administrator
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
    - { name: ace-lab, version: 0.16.3 }
    - { name: ace-overseer, version: 0.31.2 }
    - { name: ace-coworker, version: 0.10.0 }
    - { name: ace-hitl, version: 0.27.0 }
    - { name: ace-wake, version: 0.4.0 }
    - { name: ace-herdr, version: 0.11.3 }
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
  model: glm-5.3-flash
  credentials: /etc/lab/ace-lab/pi-auth.json
  herdr:
    account: mo
    socket: /run/lab/herdr/herdr.sock
```

Wykonanie instalacji i weryfikacji:

```bash
sudo env ACE_TOOLCHAIN=installed ace-lab install --dry-run   # predykcja zmian bez zapisu
sudo env ACE_TOOLCHAIN=installed ace-lab install             # jedno wywołanie Bundlera + projekcja rozszerzeń + granty
ace-lab verify --format json     # odczytowa weryfikacja gotowości pod kontami docelowymi
```

## 3. Upgrade istniejącego laba — bez odtwarzania środowiska

1. **Zapisz punkt wyjścia.** Zachowaj małą kopię z datą: manifest
   `/etc/lab/ace-lab/install.yml`, Gemfile i Gemfile.lock z katalogu bundle,
   konfiguracje Herdr/Overseer oraz wersje i identyfikatory żywych sesji.
   Kopie zawierające poświadczenia muszą być prywatne. Nie eksportuj całej VM.
   Nie kasuj `.ace-local`, `.ace-tasks`, worktree ani danych Forgejo.
2. **Wybierz jeden sprawdzony zestaw.** Zmień wyłącznie odpowiednie piny
   `gemset.gems` w istniejącym manifeście. Nie zastępuj konfiguracji starego
   laba przykładem z tej strony. Zachowaj projekty, koordynatora, granty,
   ścieżki i źródła środowiska ról. Jeśli konfiguracja nadal wymaga starego
   wystawcy systemowego, najpierw dopasuj ją do bieżącego kontraktu
   [środowiska sesji](../ace-lab/docs/usage.md); aktualizacja gemów nie jest
   automatyczną migracją dowolnego starego hosta.
3. **Użyj poprawionego instalatora i sprawdź plan.** Polecenia wykonuje operator
   z Ruby, Bundlerem i Git dostępnymi również w kontekście administratora.
   Zweryfikuj ścieżkę CLI oraz wersję przed zastosowaniem zmian:
   ```bash
   command -v ace-lab
   ace-lab --version
   sudo env ACE_TOOLCHAIN=installed ace-lab install --dry-run
   sudo env ACE_TOOLCHAIN=installed ace-lab install --format json
   ```
   `dry-run` przewiduje zmiany; brak błędu procesu nie oznacza, że nie ma
   konfliktów w raporcie. Właściwy install wykonuje **jeden `bundle install`**,
   wystawia binstuby, projektuje rozszerzenia i uzgadnia konfigurację laba.
   Nie instaluje ponownie systemu, Node, Pi ani Forgejo.
4. **Sprawdź wynik raz, jawnie:**
   ```bash
   ace-lab verify --format json
   ```
   Błąd dostępu do `ruby`/`gem`, niezgodność rozszerzeń lub brak źródła to
   niezaliczona gotowość, nie powód do ponownej instalacji wszystkiego.
   `unknown` dla zdalnego repo wymaga osobnego odczytowego sprawdzenia forge.
   Projekt pozostaje własnością `mo:mo`, runtime i chronione rozszerzenia
   własnością administratora. Nie zmieniaj właściciela projektu na root.
   Jeśli administrator dostaje Git `dubious ownership`, zaufanie może
   dotyczyć tylko sprawdzonej ścieżki, np. `sudo git config --global --add
   safe.directory /lab/ace`; nigdy `safe.directory '*'`.
5. **Przeładuj tylko to, co zmienione.** Dla zmienionego rozszerzenia Pi użyj
   `/reload` w istniejącej sesji; zachowaj pending, acknowledgements i budżet
   eyes. Nie zakładaj, że ponowne `start` przeładowuje żywy proces — może go
   ponownie wykorzystać. Natywny Herdr aktualizuj tylko, gdy wymaga tego
   kontrakt nowego `ace-herdr`, zgodnie z `native-source`; gem i binarium
   natywne są osobnymi artefaktami.
6. **Potwierdź działanie z katalogu laba, jako jego operator:**
   ```bash
   cd /lab
   ace-herdr status --format json
   ace-overseer start --scope lab --reconcile --format json
   ```
   Sprawdź faktyczne sesje, zakres i zdrowie eyes oraz zachowanie przydziałów.
   Sam istniejący panel nie potwierdza gotowości nadzorcy. Nie wysyłaj ponownie
   wykonanych zadań. W razie błędu zachowaj stan i popraw ostatni etap.

Nieudane rozwiązywanie bundle przywraca poprzedni Gemfile/lock/config Bundlera;
nie jest to rollback wszystkich zmian konfiguracji laba. Nie usuwaj starych
artefaktów potrzebnych do diagnostyki. Lokalny kandydat musi mieć jawne SHA
źródeł i sumy `.gem`; nie przedstawiaj go jako wydania RubyGems.

## 4. Uruchomienie i autonomiczna praca

### 4.1. Start serwera Herdr i nadzorców (`--scope lab`)

```bash
cd /lab
ace-herdr start
# W terminalu/panelu Herdr, z katalogu /lab:
ace-overseer start --scope lab --format json
```

- `ace-overseer start --scope lab` uruchamia lub wykorzystuje sesję Lab
  Overseera. Jawne `--reconcile` uzgadnia nadzorców skonfigurowanych projektów
  bez restartowania koordynatora.
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
ace-overseer work-on --task <TASK_ID> --manager <MANAGER_ID> --runtime herdr --json

# 2. Odbiór raportów po przebudzeniu przez eyes:
# W Pi użyj ace_eyes z action="process-reports": odbiór i dokładne potwierdzenie.
# CLI odbiera raporty; samo nie zastępuje potwierdzenia rozszerzenia:
ace-overseer process-reports --json

# 3. Przekazanie do kolejnej roli z sekwencji (np. worker -> reviewer -> integrator):
ace-overseer handoff --task <TASK_ID> --manager <MANAGER_ID> --runtime herdr --json
```

- Zwykłe dostarczanie kodu przechodzi przez sekwencję `worker → reviewer → integrator`
  (3/2/10 rund `ace-review` + formalny `APPROVED` od niezależnego konta na
  dokładnym SHA kandydata przed merge’em).
- Operacyjna weryfikacja konfiguracji (`bootstrap-verifier`) sprawdza dowody
  wykonania z raportu workera bez wywoływania `ace-review`, PR ani `integrator`.
- Po spełnieniu wymaganej sekwencji ról i warunków zakończenia (w tym startu
  projektu dla bootstrapu lub integracji kodu), procesor zamyka managera jako
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
   ace-hitl close <CASE_ID> --lesson-file lesson.yml
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
