# Uproszczenie połączeń ACE — zatwierdzony plan

Status: done. Poprzedni przebieg i jego dowody pozostają historyczne.

## b: Delegacja zapisuje komplet powiązań

work-on i handoff otrzymują --manager. Przed startem zapisują powiązanie projektu, bezpośrednie role i przydziały przez ace-task. Po starcie zapisują rzeczywiste referencje wykonawcy. Ponowienie i przerwanie nie dublują procesu; konflikt jest błędem.

## c: Operacyjna weryfikacja konfiguracji

Konfiguracja: bootstrap-worker → bootstrap-verifier, rzeczywiste kontrole, bez ace-review/PR/integratora. Kod zachowuje 3/2/10 i aktualny HEAD. Usunąć sprzeczne instrukcje.

## d: Odbiór raportów i dokładne potwierdzenia

process-reports --json, postęp stderr. ace_eyes process-reports potwierdza wyłącznie dokładne zakończone rewizje po przyjęciu, sprzątaniu i kontynuacji. Błąd lub nowsza rewizja pozostaje oczekująca.

## e: Start nadzorcy uzbraja eyes

Start zarządza standardowym eyes.json i ACE_OVERSEER_EYES_CONFIG. Inicjalizacja uzbraja obserwację bez modelu. Gotowość wymaga pierwszej tury i zdrowych wymaganych źródeł; wznowienie zachowuje ack/pending/budżet.

## f: Domknięcie managera i lekcji HITL

Manager zamyka się przez ace-task po wszystkich wymaganiach, bez publicznego archiwum. HITL close --lesson-file zapisuje lekcję i zamknięcie atomowo, z dowodem zastosowania decyzji. Sugestia wymaga lekcji. Kapitan odpowiada lokalnie na VM.

## g: Wynik operacji pomiary i zachowany przebieg

Wyniki rozróżniają zakończone, działające, oczekujące, blokady i dowody. Pomiary wykorzystują istniejące raporty/sesje/review, faktyczny model i oddzielne input/output/cache, unknown zamiast zera, bez podwajania. Testy lokalne, niezależne review, artefakty poza checkoutem, jedno wdrożenie i przebieg bez resetu VM.

## Granice

Bez nowego serwisu, kolejki ani magazynu. Istniejąca VM/Forgejo i praca pozostają zachowane. Wszystkie testowe modele GLM-5.3-Flash. Lokalne artefakty, jeden bundle install --local, restart tylko potrzebnych procesów. RubyGems osobno z main.

## Przebieg

Naprawa konfiguracji i niezależna weryfikacja → zadanie kodowe, review i merge → przerwanie i powtórzenie raportu → rzeczywista lokalna odpowiedź Kapitana → pięć minut zdrowej obserwacji bez dodatkowych tur. Release pozostaje otwarty. Każda interwencja i awaria trafia do raportu oraz istniejącej retrospektywy.

## Local implementation & live UTM VM acceptance evidence

All six implementation slices (`8y0.t.x27.b`–`8y0.t.x27.g`) passed deterministic package suites (`ace-coworker` 425/2017, `ace-hitl` 412/2122, `ace-wake` 65 JS + 2 Ruby wrapper suites, `ace-overseer` 616/3243) and the preserved UTM ARM64 live acceptance flow (`192.168.64.84`, evidence in `.ace-local/simple-runtime-start/connections-candidate/`):

- **Stage 1 (`8y0.t.x27.e` — [`stage1-eyes-start-and-reload.json`](../../../.ace-local/simple-runtime-start/connections-candidate/stage1-eyes-start-and-reload.json))**:
  - `ACE_TOOLCHAIN=installed ace-overseer start --scope lab --format json` booted lab coordinator `w2:p8` (`/lab`) and project coordinator `w3:pZ` (`/lab/ace`) with `ACE_OVERSEER_EYES_CONFIG` arming `eyes` automatically (`scope: "all"`) before the first user prompt.
  - `/reload` on `w3:pZ` preserved `window` (`start: 1794511490668, wakes: 4`), `acknowledged` (`79`), and `pending` (`20`) without zeroing; `ace-overseer start --scope lab --format json` and `--reconcile` confirmed `status: "ready", ready: true`.
- **Stage 2 (`8y0.t.x27.b`, `8y0.t.x27.c`, `8y0.t.x27.d` — [`stage2-bootstrap-verification.json`](../../../.ace-local/simple-runtime-start/connections-candidate/stage2-bootstrap-verification.json))**:
  - Delegated `8yb.t.toh` under private manager `8yb.t.toc` (`roles: [bootstrap-worker, bootstrap-verifier]`). `ManagerBinding` prepared `8yb.t.toc.0` (`bootstrap-worker`, `8ybtpx`), `8yb.t.toc.1` (`bootstrap-verifier`, `8ybtpx1`), and `8yb.t.toc.2` (`confirm-start`).
  - `bootstrap-worker` (report `8ybtsm`) and `bootstrap-verifier` (report `8ybtvs`) ran real operational checks without `ace-review`/PR/`integrator`; `ace_eyes(action: "process-reports")` verified receipts, retired executors, confirmed project start readiness on `8yb.t.toc.2`, and closed `8yb.t.toc` (`done` in `_overseer`).
- **Stage 3 (`8y0.t.x27.b`, `8y0.t.x27.d`, `8y0.t.x27.g` — [`stage3-code-delivery-and-replay.json`](../../../.ace-local/simple-runtime-start/connections-candidate/stage3-code-delivery-and-replay.json))**:
  - Delegated Forgejo Issue #14 (`LabFixtureCounter#decrement`, `8yb.t.ud1`) under private manager `8yb.t.ud0` (`roles: [worker, reviewer, integrator]`, assignments `8ybudl`, `8ybudl1`, `8ybudl2`).
  - Interrupted `coworker-8ybudl` (`w3:p13`) mid-turn (`ctrl+c`/`ctrl+d`) and resumed via `ace-overseer work-on --task 8yb.t.ud1 --manager 8yb.t.ud0 --runtime herdr` on the same transcript (`01a1d166-6da3-7783-a636-163d5bad857f.jsonl`) without duplicate tasks or assignments.
  - `worker` (report `8ybuqa`, PR #15 `f6ffc23c...`) → `reviewer` (report `8ybv8y`, 3/2/10 `ace-review` rounds `review-8ybuu7`/`review-8ybuzs`/`review-8ybv3h` + formal `APPROVED` by `e2e-reviewer` on `f6ffc23c...`) → `integrator` (report `8ybvd9`, PR #15 merged at `e00f33f6...`, Issue #14 closed, Issue #4 open) completed and closed `8yb.t.ud0` (`done` in `_overseer`).
  - Replay `ace-overseer process-reports --json --owner overseer --scope all` returned `duplicate: 34, success: 0, error: 0, unmatched: 0` with zero re-executions.
- **Stage 4 (`8y0.t.x27.f` — [`stage4-hitl-decision-and-lesson.json`](../../../.ace-local/simple-runtime-start/connections-candidate/stage4-hitl-decision-and-lesson.json))**:
  - Created HITL decision case `8ybubn` (`--to captain`), delegated `second-captain` (`8yb.t.ubz`, assignment `8ybucf`, report `8ybufn`) under private manager `8yb.t.ubv` (`hitl_case: 8ybubn`).
  - Delivered real Captain answer **A** locally on VM (`ace-hitl reply 8ybubn --stdin`), applied effect (`ace-hitl apply 8ybubn --ref 8yb.t.ubv`), atomically closed with comparison lesson (`ace-hitl close 8ybubn --lesson-file ...`, `relation: accepted`), and closed `8yb.t.ubv` (`done` in `_overseer`) via `ace_eyes(action: "process-reports")`.
- **Stage 5 (`8y0.t.x27.g` — [`stage5-idle-and-operation-summary.json`](../../../.ace-local/simple-runtime-start/connections-candidate/stage5-idle-and-operation-summary.json))**:
  - 6 samples over 300 seconds (`21:01:30Z`–`21:06:31Z`) on `w2:p8` (`/lab`) and `w3:pZ` (`/lab/ace`) confirmed `completion_seq_delta: 0`, `wakes_delta: 0`, `pending_count: 0`, `errors: 0`, and advancing 30s observations with all required sources `"ok"`.
