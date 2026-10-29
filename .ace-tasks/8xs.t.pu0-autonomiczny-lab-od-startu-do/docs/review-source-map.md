# Źródła i ustalenia review — 2026-10-29

Review specyfikacji obejmuje lokalny HEAD `4af975ee66603cac55d69a406d7f9add71718fc6` oraz odczytany z remote
`fg` commit `af68f8fc1cc7f1645e2d3caed7abb92f0262b47b`. `git ls-remote fg refs/heads/main` potwierdziło drugi SHA;
`git fetch --no-tags fg main` pobrało obiekty bez merge i bez zmiany checkoutu.
Remote fg to `ssh://git@forgejo.tail6c0887.ts.net:2222/cs3b/ace.git`.
Nie wykonano testów produktu, audytu VM, instalacji, publikacji ani sprzątania laba.
Nie należy utożsamiać odczytanego Git z dowodem stanu uruchomionych procesów.

## Materiały odnalezione

- `.ace-tasks/8xr.t.9o9-overseer-standing-wake-loops-watch/8xr.t.9o9-overseer-standing-wake-loops-watch-start-fix.s.md` istnieje w odczytanym commicie; pełna kopia jest w
  `.ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md`. Zawiera zarówno obserwację, jak i późniejszą decyzję o bezpośrednim reply.
- Rekord `8xs.t.j70` w tym samym commicie:
  `.ace-tasks/_records/8x/z/8xs.t.j70-domknij-cycle-2b-pr83-merge/8xs.t.j70-domknij-cycle-2b-pr83-merge-publish-3.s.md`.
  Raportuje podwójną konsumpcję przez dwie sesje, 16 s do transportu i 13m40s do case.
  To historyczny raport, nie nasz wynik. Jego starsze reguły relay, blokującego wait,
  kopiowania rozszerzeń i wykonywania merge przez nadzorcę zastępuje brief tej rodziny.
- PR74, PR77, PR79 i PR83 w relacji dotyczą repozytorium Forgejo `cs3b/ace`.
  Samych dyskusji/approval tych PR nie odczytano; historia commitów nie zastępuje review.
- Interim start jest w `.ace-bin/overseer-start` tego commita. Hardkoduje runtime,
  projekt i profil oraz tworzy nowy tab; nie jest docelowym kontraktem `start`.

## Mapa źródeł i rzeczywistych luk

| Zakres | Odczytane źródło | Wniosek dla wykonania |
|---|---|---|
| Instalacja | `ace-lab/lib/ace/lab/molecules/gemset_provisioner.rb`, `organisms/install.rb`, `organisms/verify.rb`, `docs/usage.md` | Install/resume/verify istnieją. Obecny probe sprawdza obecność wersji, nie aktywację CLI, pełny dependency closure ani załadowaną wersję rozszerzenia. Rozszerzyć ten przepływ. |
| Wake | Lokalnie `ace-handbook-integration-pi/handbook/extensions/ace-wake/`; w fg `ace-wake/` | fg przeniósł źródło i testy, dodał poll fallback oraz ask bridge. Usunął projekcję rozszerzenia z pi; README nakazuje ręczne kopiowanie. Krok 01 ma dostarczyć pakiet, krok 03 naprawia rzeczywistą ścieżkę aktywacji. |
| Watch/eyes | `ace-wake/index.js`, `wake/wake-registry.js`, `wake/ask-bridge.js`, `wake/eyes-runtime.js` w fg | `addWatch` już wywołuje `watches.start`. `/eyes` usuwa watches i odrzuca `/watch add`; bridge nie przypisuje case do konkretnej sesji. Nie zakładać braku samego wywołania start ani dwóch niezależnych pętli. |
| Obserwacja | `ace-overseer/lib/ace/overseer/molecules/event_observation.rb` | Obecny observe projektuje HITL; nie obejmuje jeszcze wszystkich lokalnych źródeł ani PR/review/comments. |
| Ask/reply | `ace-hitl/lib/ace/hitl/cli.rb`, `cli/commands/ask.rb` w fg | Ask jest w fg, nie w lokalnym HEAD. Publicznego reply nie ma w żadnym z tych dwóch źródeł. Krok 06 włącza istniejący ask i dostarcza brakujący reply. |
| Transport | `ace-hitl-hermes/docs/native-folder.md`, `lib/ace/hitl/hermes/organisms/native_sync.rb` oraz `molecules/native_folder.rb` w fg | Jedna trasa w `.ace/hitl/config.yml` jest już zaimplementowana w fg; import reply nadal zależy od sync. Kontrakt tej rodziny zastępuje tę ścieżkę bezpośrednim poleceniem na maszynie właściciela. |
| Start | `ace-overseer/lib/ace/overseer/cli.rb` | Brak publicznego start. |
| Topologia | `ace-lab/lib/ace/lab/molecules/project_registry.rb`, `atoms/topology_schema.rb`, `atoms/public_projection.rb` | Zapis zawiera path/remote; normalizacja i publiczna projekcja zwracają tylko id/label. Start potrzebuje wewnętrznego odczytu lokalizacji od ace-lab, bez ujawniania prywatnych ścieżek w publicznym CLI. |
| Delegacja | `ace-coworker/lib/ace/coworker/atoms/config_schema.rb`, `ace-coworker/docs/usage.md` | Brief i role istnieją; docs jawnie mówią, że coworker nie pożycza tokenów ani nie zmienia tożsamości. Decyzja Kapitana dodaje ace-lab auth; mechaniki issue/revoke znaleziono w lab-config, a ich przeniesienie i integracja należą do .7. Źródła: docs/auth-mechanics.md. |
| Merge | `ace-coworker/lib/ace/coworker/atoms/integration_gate.rb` | Review ma head; tests mają tylko executed/passed. Powiązać również dowód testów z kandydatem i weryfikować stan przy rzeczywistym merge. |
| Historia HITL | `ace-hitl/lib/ace/hitl/molecules/hitl_answer_editor.rb`, `models/hitl_event.rb` | Edytor Answer zastępuje końcówkę dokumentu. Sugestie i wnioski muszą mieć zachowywane sekcje/metadata u tego samego właściciela; nie wolno uznać zwykłego append za bezpieczne. |

## Uzupełnienie: auth

Po odpowiedzi Kapitana odczytano `cs3b/lab-config` przy HEAD
`ced5f99a08766a1058e2bf745307a5459638f10a`: Forgejo issue/revoke per role,
GitHub App leases oraz protected file/env handoff. `docs/auth-mechanics.md` podaje
funkcje, provenance obcych lokalnych zmian, dokumentację providerów i ograniczenia.
Wcześniejszy brak źródła dotyczył wyłącznie ACE i raportu cycle-2b, nie całego laba.
To rozstrzyga pytanie HIGH w .7. Pakietowanie cyklu auth, trzech pluginów oraz cleanup
jest częścią .7; nie dodano dziecka ani nowej kolejki. Minimalny lease record ma
jednego właściciela, a .7 aktualizuje canonical owner map i ADR-034.

## Granica źródeł i wdrożenia

W kroku 01 porównać obie linie źródeł i włączyć potrzebne istniejące zmiany wake/packaging
do kandydata przez zwykły reviewowany przepływ. Krok 06 odpowiada za integrację istniejących
zmian ask, parsera frontmatter i jednej trasy. Nie wykonywać ślepego merge całej gałęzi.
Nie kopiować starego path rozszerzenia ani instrukcji ręcznego deployu do nowych bundles.
Po integracji zaktualizować bundle do ostatecznych istniejących ścieżek; ta mapa i kopia
speca zapewniają kontekst przed powstaniem tych plików w bieżącej linii.
Dokładne źródła z fg można odczytać przez `git show af68f8fc1cc7f1645e2d3caed7abb92f0262b47b:<path>`.

Prace pozostają liniowe, bez nowego taska integracyjnego i bez wnuków. Kroki 01–09 mogą
korzystać z istniejących ręcznie uruchamianych workflow release do odbioru swojego runtime;
krok 10 automatyzuje ich delegowanie. To nie jest zależność wstecz do kroku 10.

## Weryfikacja i wspólne domyślne zachowanie

- Każdy scenariusz zapisuje wejście, rzeczywisty kandydat, konto/rolę, polecenie,
  wynik i lokalizację dowodu w tasku/assignmencie. Nie zaznaczać kryteriów wykonania w review.
- Kryteria 1–3 każdego dziecka mają poniżej własną mapę dowodów. Kryterium właścicieli
  stanu wymaga kontroli diffu i zapisów w scenariuszu; kryterium integracji/dokumentacji
  wymaga przejścia producent → konsument oraz zgodnych przykładów usage i negatywnej próby.
- Dla zmian kodu: `bin/ace-test <pakiet> all` dla każdego zmienionego pakietu,
  właściwy scenariusz integracyjny i `bin/ace-test-suite` według workflow verification.
  Domyślne `bin/ace-test <pakiet>` oznacza fast i samo nie dowodzi integracji.
  W installed obowiązują instalowane executables; brak runnera jest błędem gotowości.
- Brak pracy to poprawny stan idle. Błąd odczytu to degraded, nigdy pusta lista.
  Nowy stan awarii i odzyskania może raz wybudzić odbiorcę; identyczna awaria nie spamuje.
- In-process observer nie wskrzesza martwego procesu; po jawnym starcie odczytuje
  zaległy stan. Watchdog hosta pozostaje poza zakresem.
- CLI zachowuje istniejące formaty/quiet/verbose tam, gdzie są dostępne; quiet nie ukrywa
  błędów. Nowe start ma table/json i dry-run, bez force omijającego kontrolę tożsamości.
  Pozostałe nowe opcje force/dry-run są poza zakresem, jeśli spec ich nie wymienia.
- Dane odpowiedzi, OTP i poświadczenia nie trafiają do argv, promptów ani logów.
  Budzenie o odpowiedzi tajnej przekazuje tylko identyfikator; istniejący bezpieczny
  kanał wykonawcy konsumuje wartość poza modelem. Second Captain pomija takie sprawy.

## Skills Applied

Loaded: `.agents/skills/as-task-review/SKILL.md` i `wfi://task/review`.
Executed: workflow review specyfikacji oraz ładowanie `project` / `wfi://bundle`.
Nie uruchamiano workflow implementacji ani odbioru runtime: przedmiotem jest gotowość speców.
