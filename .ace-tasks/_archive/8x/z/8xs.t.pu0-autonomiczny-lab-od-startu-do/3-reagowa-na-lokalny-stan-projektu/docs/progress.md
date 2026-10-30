# Postęp 8xs.t.pu0.3 — nadzorca reaguje na lokalny stan (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Odbiór runtime na labie odroczony
na koniec programu (decyzja Kapitana).

## Zrealizowane w źródłach

1. **`Molecules::LocalSources`** — rzutowanie pięciu lokalnych klas źródeł
   (zadania projektu, prywatne `_overseer`, worktree'e, dostępność coworkerów,
   postęp assignmentów) od ich właściciów stanu:
   - ace-task (list „next" / „_overseer"), ace-git-worktree (list_all),
     ace-coworker WorktreeExecutorProbe + ActiveExecutorRule (istniejące
     identyfikatory uruchomienia — commissioned assignment id, nie nazwy pane)
     nad inventory ace-assign;
   - każdy wiersz {key, revision, type}: rewizja zmienia się tylko przy realnej
     zmianie u właściciela (status zadania, zbiór zależności, subtask statusy,
     path/branch worktree, active/evidence executora, state/progress
     assignmentu) — identyczny stan = identyczna rewizja = cisza bez tur modelu;
   - awaria źródła degraduje tylko to źródło: marker `source-health` z rewizją
     keyed by klasa błędu (identyczna awaria nie spamuje; nowa klasa budzi
     raz), mapy `sources` ok/degraded, zdrowe źródła projekują dalej.
2. **`Molecules::EventObservation` rozszerzone** — projekcja observe łączy
     zdarzenia HITL (istniejące semantyczne rewizje + settled/duplicate) z
     wierszami LocalSources; degraded HITL (np. unknown recipient) degraduje
     tylko HITL, lokalne źródła projekują dalej; schema bez zmian
     (`ace.hitl.observation/v1`) — eyes konsumuje bez modyfikacji.
3. **Start guide** (`wfi://overseer/start`): sekcja Standing observation —
     uzbrojenie /eyes (domyślny reconcile 15 s), reconcile zaległych rewizji
     po restarcie przed wyborem pracy, ACK dopiero po przyjęciu przez
     właściwy task/assignment (settled modelu nie jest dowodem).
4. Dokumentacja usage (sekcja `ace-overseer observe`) + CHANGELOG.

Restart/backlog: eyes utrwala rewizje w session entries — po restarcie
niepotwierdzone rewizje (w tym raport z czasu nieobecności) reconcilują się
przy bind (istniejący test eyes-runtime: „unacknowledged revision reconciles
on reload"); koegzystencja /watch z kroku 03 zapewnia jedną infrastrukturę
dostawy.

## Dowody

- `bin/ace-test ace-overseer` — 388 testów, 0 fail. Nowe:
  - `local_sources_test` (4): pełne rzutowanie 5 klas z stabilnymi rewizjami,
    identyczny stan = identyczne rewizje, realna zmiana rewizuje dokładnie ten
    wiersz, awaria worktree/task degraduje tylko swoje źródła + widoczny
    marker, powtórzona awaria tej samej klasy = ta sama rewizja;
  - `event_observation_test` (3): semantyki adopcji HITL bez zmian, merded
    projection z local rows + sources health, degraded HITL nie zatrzymuje
    lokalnych źródeł.
- `bin/ace-test ace-wake` — suite JS (131 testów) zielony: kontrakt
  rewizji/ACK eyes po stronie konsumenta bez zmian.

## Odroczone (koniec programu)

- Odbiór na labie: raport coworkera → semantic wake → odczyt → kontynuacja w
  żywej sesji; restart z raportem w czasie nieobecności; awaria źródła na
  żywym runtime; publikacja gemów.
