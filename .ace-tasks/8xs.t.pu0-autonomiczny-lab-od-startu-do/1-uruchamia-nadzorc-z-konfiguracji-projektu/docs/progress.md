# Postęp 8xs.t.pu0.1 — start nadzorcy projektu (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398, `.ace-wt/ace-t.pu0`). Odbiór
runtime (żywy herdr, konta docelowe) odroczony na koniec programu (decyzja
Kapitana).

## Zrealizowane w źródłach

1. **Kontrakt startu** (`Atoms::StartContract`): jawna sekcja `start`
   (scope/profile/instructions) + mapa `profiles` w kaskadzie
   `.ace/overseer/config.yml`; brak sekcji/klucza/profilu = konkretny błąd
   przed jakąkolwiek sesją; scope `lab` jawnie zgłasza niewdrożoną zdolność
   (krok .a); zero domyślnych modeli z interim skryptu.
2. **Kanoniczny root projektu** (`Molecules::ProjectRootResolver`): podkatalog,
   symlink i worktree tego samego repo → jeden właściciel (git-common-dir).
3. **Orkiestrator startu** (`Organisms::StartOrchestrator`): tożsamość sesji =
   label `overseer-<project>` w herdr; żywy właściciel → `reused` (bez drugiej
   sesji); żywy pane o obcym cwd → `blocked` (konflikt, nigdy przejęcie);
   martwy właściciel → zastąpienie z `replaced_pane`; start: tab w workspace
   wywołującego + `agent_start` z profilem (model/thinking) i guide jako
   standing instructions (--append-system-prompt, passthrough args).
4. **CLI** `ace-overseer start [--dry-run] [--format table|json]`: raport
   status/scope/root/label/workspace/pane/agent/profile/instructions;
   exit 0 tylko started/reused/dry_run; blocked = błąd CLI.
5. **Guide z gema**: `handbook/workflow-instructions/overseer/start.wf.md`
   (`wfi://overseer/start`) — rola koordynacyjna, delegacja, eskalacja HITL,
   idle, jawne niewdrożone zdolności.
6. **ace-herdr**: `agent_start(args:)` — passthrough argumentów harnessu po `--`.

## Dowody

- `bin/ace-test ace-overseer` — 382 testy, 0 fail (nowe: kontrakt 7,
  orkiestrator 9 scenariuszy w tym reuse/konflikt/martwy/podkatalog+worktree/
  dry-run/nieprzygotowany katalog/nierozwiązywalny guide, CLI 3).
- `bin/ace-test ace-herdr` — 615 testów, 0 fail (args passthrough bez zmiany
  istniejących ścieżek).
- CLI smoke (ruby 3.4.8, /tmp/ovs-start-smoke): repo bez konfiguracji →
  `blocked` + exit 1 z konkretnym komunikatem; skonfigurowany projekt dry-run →
  `dry_run`, exit 0, poprawny root/label/profil/instrukcje; podkatalog → ten
  sam root.

## Odroczone (koniec programu)

- Odbiór na labie z żywym herdr: pierwszy start tworzy sesję z guide
  załadowanym przez harness (tożsamość + odczyt task-store), reuse
  współbieżny, martwy właściciel na żywym runtime.
- Publikacja gemów (ace-overseer, ace-herdr) i wersje.
