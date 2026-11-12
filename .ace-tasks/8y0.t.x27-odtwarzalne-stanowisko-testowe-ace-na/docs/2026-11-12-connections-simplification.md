# Uproszczenie połączeń ACE — zatwierdzony plan

Status: in-progress. Poprzedni przebieg i jego dowody pozostają historyczne.

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

## Local implementation evidence

Six implementation slices are present; task remains in-progress until live acceptance.
Independent reviewer `review_manager_bindings` found no remaining blocker in reviewed
working delta after exact historical revision and failure-JSON fixes.

- Coworker full: 425 tests / 2017 assertions, report d805d960-58e3-40ef-bc00-260b1da3ed18.
- Subsequent actual-model evidence: 1/9, c1a8d118-6b02-4393-8ad4-e29ec1121fdb.
- Subsequent real error-JSON CLI: 4/50, 2dc95509-e839-4d9e-89d0-1c640487f47f.
- HITL full: 412/2122, zero failures/errors, five skips, 7aa5b311-5309-437a-b215-4b132565f8c5.
- Wake full JS wrappers: 2/7, 9a8b77ae-f26f-4567-9e55-cf87a3199964.
- Overseer full run reached 614 tests; last three integration fixtures modeled the
  old acceptance write without a revision and old ambiguous-role error. Fixtures
  now represent the new atomic owner write and conflict refusal; rerun pending.

VM has not been changed in this implementation stage. Both coordinators are idle,
terminal IDs unchanged. Model usage and remaining quota for this stage unknown;
no paid VM/model tests have been started.
