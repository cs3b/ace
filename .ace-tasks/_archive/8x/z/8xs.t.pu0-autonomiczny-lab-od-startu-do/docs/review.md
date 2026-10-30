# Review specyfikacji 8xs.t.pu0 — 2026-10-29

Przejrzano parent i wszystkie 16 bezpośrednich dzieci. Zachowano zaakceptowany liniowy
podział i wszystkie 30 problemów z mapy. Poprawiono specyfikacje, scenariusze usage oraz
bundles; nie implementowano produktu i nie wykonywano operacji na labie.

## Najważniejsze ustalenia i naprawy

1. **Różne bazy źródeł i nieaktualne bundles.** Lokalny HEAD nie zawierał raportowanych
   poprawek ask/virtiofs ani przeniesienia ace-wake. Odczytano aktualny fg/main
   `af68f8fc1cc7f1645e2d3caed7abb92f0262b47b` i brakujący spec 9o9. Krok .0 obejmuje
   pakietowanie obecnego top-level ace-wake, .5 integrację istniejącego ask i jednej trasy.
   Mapa źródeł zastępuje odwołania do usuwanej lokalizacji rozszerzenia.
2. **Niepełny odbiór runtime.** Install/resume/verify już istnieją, ale obecność gema
   na liście nie dowodzi zależności, aktywacji właściwej wersji CLI ani rozszerzenia.
   Dodano te próby, dry-run oraz rozróżnienie restart-required od ready.
3. **Konkurujący obserwatorzy i luka przy restarcie.** `/watch` wywołuje już start;
   `/eyes` usuwa watches. Dodano jedną infrastrukturę, publiczną próbę aktywacji,
   granice opóźnienia, backlog po starcie i izolację awarii źródeł. Remote watch obejmuje
   także komentarze, approval i ponowne otwarcie PR, z kontrolą pagination/rate-limit.
4. **HITL nie miał pełnego kontraktu dostawy i zastosowania.** Reply nie istnieje
   w odczytanym CLI. Ustalono bezpośrednie wywołanie przez skonfigurowane SSH, stdin,
   dokładną korelację root/case/sesji, odpowiedź przed arm, utracony ACK i dwa współbieżne
   odbiory. Applied wymaga dowodu skutku u właściciela; niepewny efekt wymaga reconcile.
5. **Testy nie były związane z HEAD w istniejącym gate.** Dodano wymaganie head do
   test evidence oraz kontrolę wyścigu gate → merge, z zachowaniem advisory CI.
6. **Historia doradcy mogła zniknąć lub udawać decyzję.** Obecny edytor Answer zastępuje
   końcówkę pliku. Spec wymaga odrębnych zachowywanych suggestion/lesson i autorów,
   pierwszeństwa odpowiedzi człowieka oraz filtrowania sekretów przed modelem.
7. **Brakowało jednoznacznych granic odbioru.** Dodano per-child mapę kryteriów do
   scenariuszy, odmowę instalacji w .e, granice crash w .f, brak rekurencyjnego release
   dla record-only PR i ostrożne mapowanie do historycznych F1/F2/F3 gad.2.

## Wynik dla dzieci

| Dziecko | Ocena specyfikacji | Istotne doprecyzowanie |
|---|---|---|
| .0 | pending | Packaging ace-wake, dependency closure, aktywacja wersji, install/verify |
| .1 | pending | Jawny scope/profile/instructions, dry-run, tożsamość i współbieżny start |
| .2 | pending | Publiczny watch, współpraca z eyes/ask, virtiofs i registration race |
| .3 | pending | Sześć klas lokalnych źródeł, backlog i semantyczne ACK |
| .4 | pending | Oba forge, komentarze/approval/HEAD, limit opóźnienia i recovery |
| .5 | pending | Bezpośredni reply, stdin, dokładny odbiorca i utracone potwierdzenie |
| .6 | pending | Receipt/application, niepewny efekt, konflikt i bezpieczny sweep |
| .7 | pending | ace-lab auth, pluginy Forgejo/GitHub/env, role/scope/TTL, handoff i cleanup |
| .8 | pending | Testy dla HEAD, niezależność review i wyścig merge |
| .9 | pending | Publisher, sekret poza modelem, digest/recovery i zakończenie rekordu |
| .a | pending | Wewnętrzna lokalizacja projektu, pusta lista, partial readiness |
| .b | pending | Typ suggestion, ten sam wątek, człowiek szybszy niż doradca |
| .c | pending | Lesson/revision, retrieval tego projektu, brak sekretów i duplikatów |
| .d | pending | Jawny kierunek sync, ff-only/no-op, zachowanie aktywnych zasobów |
| .e | pending | Cel → pełny cykl, odmowa install oraz rzeczywiste role |
| .f | pending | Macierz crash/recovery, 30 min idle, mapa dowodów bez fałszywego PASS |

## Rozstrzygnięte pytanie o dostęp

Kapitan doprecyzował: dostarczyć ace-lab auth z pluginami Forgejo (issue/revoke),
GitHub i env, aby agent prosił o krótkotrwały dostęp swojej roli. Istniejące mechaniki
należy uporządkować i spakować. Research rozszerzony na repo lab-config odnalazł
Forgejo create/revoke per role, GitHub App leases i protected file handoff.
Źródła oraz różnicę między nowym tokenem a kopiowaniem admin PAT dokumentuje
`docs/auth-mechanics.md`; wcześniejszy wniosek o braku mechanizmu dotyczył przeszukanych
źródeł ACE, nie całego laba.

.7 ma kompletny kontrakt request/status/exec/revoke/reconcile, profile i principal/scope,
TTL, bezpieczne przekazanie, jednego właściciela lease oraz rozstrzygnięcie retry/crash.
Natywne expiry, host-revoke i process-scoped env mają jawne różnice; brak gwarancji
nie jest raportowany jako sukces. Installer/owner map/ADR i guides są częścią dostawy
.7. .8/.9/.e/.f oraz parent konsumują ten kontrakt. Nie wprowadzono nowego dziecka,
brokera mutacji ani control plane labd.

Otwarte pytania: 0 HIGH, 0 MEDIUM. Duży rozmiar wycinków pozostaje advisory.
Zachowano dokładnie 16 dzieci i liniową kolejność wymaganą przez użytkownika.

## Readiness i weryfikacja review

Gotowe dzieci mają wejście/proces/wyjście, granice, interfejs/defaults, wskazanych
konsumentów, bundle, usage dla zmienianych interfejsów oraz mapę wszystkich kryteriów
do pozytywnych i negatywnych prób. Po odpowiedzi i research .7 przechodzi również
decision-complete/defaults i no-blocking-questions. Parent przechodzi child readiness.
Przejrzano także zmienione kontrakty odbiorców .8/.9/.e/.f i brak sprzeczności z briefem.
Readiness dotyczy możliwości rozpoczęcia implementacji, nie dowodu wykonania funkcji.

Weryfikacja zapisu obejmuje strukturę 17 specs, kompletność ścieżek bundle, łańcuch
dependencies, parse frontmatter, brak zaznaczonych kryteriów wykonania oraz kontrolę diffu.
Pierwszych 15 promocji wykonano przez ace-task i potwierdzono show zaraz po każdej
zmianie. Po rozstrzygnięciu auth ten sam krok wykonano dla .7, a następnie parenta.
Wszystkie 17 specyfikacji mają status pending i needs_review: false.

## Decyzja

Przejrzano 16 dzieci; promowano 16; zablokowane 0. Parent: pending, needs_review: false.
Gotowość dotyczy specyfikacji. Wykonanie przez as-task-work respektuje dependencies;
żadne kryterium akceptacji produktu nie zostało zaznaczone.

## Źródła i zakres

Pełne provenance i mapa kodu: docs/review-source-map.md. Odnaleziony materiał:
docs/sources/standing-wake-af68f8fc1.md. Dane historyczne nie są odczytem VM.
W tym review nie uruchamiano testów produktu, modeli labowych, publikacji ani deployu.
Nie zmieniono kodu produkcyjnego, wcześniejszych tasków ani kont/uprawnień.

## Skills Applied

Loaded/Executed: as-task-review (`.agents/skills/as-task-review/SKILL.md`,
`wfi://task/review`), z `project` i `wfi://bundle` jako kontekstem.
