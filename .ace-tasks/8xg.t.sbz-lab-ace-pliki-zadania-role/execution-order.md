# Kolejność budowy, praca równoległa i integracja

Program `8xg.t.sbz`. Aktualizacja kolejności na podstawie zależności konkretnych
subtasków, 2026-10-17. Numery L1–L10 grupują zakres; nie stanowią już jednego
szeregowego łańcucha. Cel i kryteria odbioru pozostają bez zmian.

## Jak czytać zależności

`dependencies` liścia oznacza wymagany odebrany i zintegrowany wynik poprzednika.
Samo „worker skończył” lub otwarty PR nie odblokowuje zależnego zadania. W czasie
wykonania overseer odwzorowuje taki warunek przez subtask integracji w swoim
prywatnym drzewie; nie dodajemy nowego statusu ani silnika kolejki do ace-task.

Główne taski L1–L10 są grupami odbioru. Ich puste `dependencies` nie oznacza,
że można od razu wykonać wszystkie dzieci: gotowość odczytuje się z konkretnych
liści. Rodzic jest odebrany dopiero po wszystkich wymaganych dzieciach.

Fale opisują typowy przebieg, a nie globalne bariery. Gdy konkretny poprzednik
jest zintegrowany, jego następca może ruszyć bez czekania na niezależne tory.
Po review 2026-10-18 grupy 8xg.t.sbz.1, .2, .5, .6 i ich dzieci mają specyfikacje gotowe do wykonania (pending); pozostałe grupy wymagają własnego review. Pending nie znosi dependencies. Dokument nie uruchamia agentów.


## Start po merge PR #379 i review 2026-10-18

Przed wykonaniem pobrać aktualny main zawierający `76bc3d4e8` oraz ten review.
L1 `8xg.t.sbz.0` i jego dzieci są done; nie wykonywać ich ponownie.
Review specyfikacji jest częścią przygotowania zlecenia, nie powodem pytania
o zgodę na pominięcie draft. Nie usuwać rzeczywistych zależności.

| Główny task | Pierwszy zakres | Granica integracji |
|---|---|---|
| `8xg.t.sbz.1` — HITL | `.1.0` → `.1.1` → `.1.2` → `.1.3` | Całe HITL odblokowuje `.2.2` |
| `8xg.t.sbz.2` — coworker | `.2.0` → `.2.1` | `.2.2` czeka na `.1`, potem `.2.3` |
| `8xg.t.sbz.5` — overseer | `.5.0` → `.5.1` | `.5.2` czeka na `.3`; lokalna lista już istnieje po L1 |
| `8xg.t.sbz.6` — statusy/pi | `.6.0` | `.6.1`/`.6.2` czekają na `.5`; nie blokują `.6.0` |

Skróty `.x.y` w tabeli mają prefiks `8xg.t.sbz`. Nie delegować od razu całego
rodzica jako niepodzielnej implementacji. Po dojściu do niespełnionej zależności
zintegrować wykonany fragment i zachować worktree do kontynuacji.

## Fale pracy

| Fala | Co budujemy | Co może działać równolegle | Punkt integracji |
|---|---|---|---|
| 0 — wspólna podstawa | L1.1 → L1.2 → L1.3 | Przygotowanie kolejnych specyfikacji, bez równoczesnego przebudowywania tych samych ścieżek wykonania | Lokalne taski i assignmenty działają bez starego authority/journala; dokumentacja odpowiada kodowi |
| 1 — cztery niezależne tory | A: L2.1 → L2.2 → L2.3 → L2.4; B: L3.1 → L3.2; C: L6.1 → L6.2; D: L7.1 | HITL, podstawy coworkera, prywatne drzewo overseera i statusy składowe mają odrębnych właścicieli | Przyjęty HITL oraz start/driver coworkera pozwalają złożyć raportowanie |
| 2 — wykonawca z raportem | L3.3 → L3.4 | L4.1 po L3.2 i L6.2; L8.1 po L2.2 i L3.1 | Coworker wykonuje assignment, raportuje i wznawia pracę; planner potrafi przygotować worktree |
| 3 — role i przygotowanie | L5.1 równolegle z L5.2 → L5.3 → L5.4; potem L5.5 | Worker/spec i tor reviewer/integrator; można dokończyć L4.1 oraz L8.1 | Po integracji ról: L4.2 → L4.3 → L4.4 przygotowują rzeczywiste assignmenty i start |
| 4 — pierwszy pełny obieg | L6.3 → L6.4 → L6.5 | Niezależna praca nad scenariuszami testowymi; bez deklarowania odbioru L9 | Planner → worker → raport → reviewer; spełniona zależność uruchamia właściwy kolejny krok |
| 5 — widoczność i instalacja | A: L7.2; B: L7.3; C: L8.2 → L8.3 → L8.4 | Status, kontynuacja w pi i instalator; po A+B domknąć L7.4 | Po L7.4 i L8.4 wykonać L8.5 pod docelowymi kontami |
| 6 — odbiór przed release | L9.1, L9.2, L9.3, L9.4 | Cztery scenariusze na oddzielnych środowiskach i tym samym zestawie wersji | Wszystkie wymagane scenariusze zaliczone na spójnym kandydacie |
| 7 — wydanie i świeży lab | L10.1 → L10.2 → L10.3 → L10.4 | Przygotowanie dokumentacji wydania; publikację prowadzi jeden integrator | Paczki z RubyGems przechodzą pełny scenariusz na nowym labie |

## Co przekazujemy między torami

- L1 ustala właścicieli i istniejące plikowe operacje. Sprzeczne stare wymagania nie wracają przez nową funkcję.
- L2 dostarcza ten sam interfejs raportu/pytania/Reply niezależnie od adaptera. L3.3 korzysta z niego dopiero po integracji całego L2.
- L3.1 określa odczytywany kontekst `.ace-local/coworker/`, L3.2 prowadzi assignment. Planner korzysta z tego kontraktu, nie definiuje konkurencyjnego formatu.
- L5 dostarcza faktyczne role i procesy. Dlatego pełne przygotowanie assignmentów L4.2 czeka na L5, mimo niższego numeru L4.
- L6.1–L6.2 mogą dostarczyć prywatne drzewo wcześniej. Uruchamianie i przekazywanie pracy L6.3–L6.5 czeka na gotowego plannera i role.
- L7 status jedynie zbiera stan źródeł. Kontynuacja pi i instalator mogą powstawać równolegle po działającym L6.
- L8.5 odbiera gotowe środowisko razem z widocznością i kontynuacją L7. Dopiero potem L9 wykonuje odbiór całego zestawu.

## Odpowiedzialność za wspólne pliki

Zlecenie może obejmować główny task wraz z podtaskami. Jeden główny zakres
ma jedno worktree z jednym aktywnym wykonawcą; jego liście są kolejnymi
krokami, nie obowiązkiem tworzenia nowych worktree. Dependencies nadal
sprawdzamy na poziomie liści. Zakres może dostarczyć kilka kolejnych PR-ów: np.
8xg.t.sbz.5.0–.5.1 integrujemy przed plannerem, resztę .5 po plannerze.
Reviewer przejmuje worktree dopiero po zakończeniu workera; poprawki reviewera
pozostają częścią jego assignmentu. Nie uruchamiać dwóch niezależnych driverów
na tym samym worktree.

Przed przydziałem sprawdzić planowane ścieżki zmian. Tory z tabeli są kandydatami
do pracy równoległej, nie gwarancją braku konfliktów w nieprzeczytanym diffie.
Jeżeli obydwa zadania zmieniają ten sam wspólny kontrakt lub rejestrację CLI,
wyznaczyć jednego właściciela tego pliku i zintegrować jego zmianę przed konsumentem.

| Obszar | Właściciel | Zasada współpracy |
|---|---|---|
| Usunięcie starych mechanizmów | L1 | Zintegrować przed nowymi ścieżkami w tych samych pakietach |
| HITL i adaptery | L2 | Coworker konsumuje interfejs; nie tworzy własnego transportu |
| Start coworkera i jego driver | L3 | Planner zapisuje format czytany przez coworkera |
| Przygotowanie assignmentów | L4 | Korzysta z ról L5 i istniejącego ace-assign |
| Instrukcje ról i presety review | L5 | L5.5 zbiera wspólną rejestrację i sprawdza spójność presetów |
| Drzewo, przydziały i raporty overseera | L6 | Bez równoległego przebudowywania tych samych miejsc przez status lub pi |
| Odczyt statusu / rozszerzenie pi | L7.2 / L7.3 | Osobne zakresy; wspólny wynik weryfikuje L7.4 |
| Konfiguracja instalacji projektu/laba | L8 | L7.1 czyta konfigurację; zmiany jej formatu dostarcza jeden właściciel |
| Gemfile, wersje, wspólny lockfile i manifest wydania | Integrator odpowiedniej fali / L10 przy release | Sporne wspólne zmiany integrować kolejno; nie zastępować całego pliku z obcej gałęzi |

## Procedura integracji

1. Przed uruchomieniem liścia przeprowadzić review jego specyfikacji i przygotować task/worktree/assignment oraz ścieżki, za które odpowiada.
2. Worker implementuje, następnie niezależny reviewer naprawia i odbiera według zasad roli. `bin/ace-test` oraz `bin/ace-test-suite` i niezależny werdykt są bramką przed merge.
3. Integrator scala gotowe wyniki w kolejności ich rzeczywistych zależności. Niezależne tory można scalać, gdy są gotowe; nie czekają na najwolniejszy tor fali.
4. Jeżeli integracja zmieniła kandydata lub rozwiązywano konflikty, wykonać adekwatne sprawdzenia i odnowić review dla zmienionego wyniku. Nie mieszać akceptacji starego kandydata z nowym kodem.
5. Na styku komponentów sprawdzić rzeczywisty przepływ producent → konsument. L3.3: wykonawca → HITL. L4.4: planner → uruchamialny kontekst. L6.5: pełny obieg pracy. L8.5: instalacja → wykonawca pod docelowym kontem.
6. Dopiero przyjęta integracja odblokowuje zależne zadanie. Wiadomość `work done` z etapu implementacji nie zastępuje tego warunku.
7. Scenariusze L9 uruchamiać na tym samym kandydacie i w osobnych środowiskach. Poprawka zmieniająca testowany zakres wymaga ponowienia dotkniętych scenariuszy przed wydaniem.

Nie tworzymy nowego zadania integracyjnego jako dodatkowej infrastruktury.
Przydział integratorowi i zależności merge zapisuje overseer w swoim procesie.

## Pełna kolejność subtasków

Tabela poniżej odpowiada dokładnie polom dependencies. Odwołanie do L oznacza
odebranie całej grupy, odwołanie do L.n — konkretnego subtaska.

| Subtask i ID | Zintegrowane poprzedniki |
|---|---|
| [L1.1 / 8xg.t.sbz.0.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/0-przypisa-stan-do-w-a/8xg.t.sbz.0.0-przypisa-stan-do-w-a-cicieli-i.s.md) | Brak |
| [L1.2 / 8xg.t.sbz.0.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/1-upro-ci-istniej-ce-cie/8xg.t.sbz.0.1-upro-ci-istniej-ce-cie-ki-wykonania.s.md) | [L1.1 / 8xg.t.sbz.0.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/0-przypisa-stan-do-w-a/8xg.t.sbz.0.0-przypisa-stan-do-w-a-cicieli-i.s.md) |
| [L1.3 / 8xg.t.sbz.0.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/2-ujednolici-aktywn-dokumentacj-i-konfiguracj/8xg.t.sbz.0.2-ujednolici-aktywn-dokumentacj-i-konfiguracj.s.md) | [L1.2 / 8xg.t.sbz.0.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/1-upro-ci-istniej-ce-cie/8xg.t.sbz.0.1-upro-ci-istniej-ce-cie-ki-wykonania.s.md) |
| [L2.1 / 8xg.t.sbz.1.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/0-obs-u-y-raporty-oraz/8xg.t.sbz.1.0-obs-u-y-raporty-oraz-pro-by.s.md) | [L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md) |
| [L2.2 / 8xg.t.sbz.1.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/1-ujednolici-adresowanie-odbiorc-w-i/8xg.t.sbz.1.1-ujednolici-adresowanie-odbiorc-w-i-reply.s.md) | [L2.1 / 8xg.t.sbz.1.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/0-obs-u-y-raporty-oraz/8xg.t.sbz.1.0-obs-u-y-raporty-oraz-pro-by.s.md) |
| [L2.3 / 8xg.t.sbz.1.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/2-zachowa-wsp-lny-interfejs-i/8xg.t.sbz.1.2-zachowa-wsp-lny-interfejs-i-konfigurowalne-adaptery.s.md) | [L2.2 / 8xg.t.sbz.1.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/1-ujednolici-adresowanie-odbiorc-w-i/8xg.t.sbz.1.1-ujednolici-adresowanie-odbiorc-w-i-reply.s.md) |
| [L2.4 / 8xg.t.sbz.1.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/3-zachowa-i-ponawia-niedostarczone-wiadomo/8xg.t.sbz.1.3-zachowa-i-ponawia-niedostarczone-wiadomo-ci.s.md) | [L2.3 / 8xg.t.sbz.1.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/2-zachowa-wsp-lny-interfejs-i/8xg.t.sbz.1.2-zachowa-wsp-lny-interfejs-i-konfigurowalne-adaptery.s.md) |
| [L3.1 / 8xg.t.sbz.2.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/0-startowa-z-przygotowanej-konfiguracji-coworkera/8xg.t.sbz.2.0-startowa-z-przygotowanej-konfiguracji-coworkera.s.md) | [L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md) |
| [L3.2 / 8xg.t.sbz.2.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/1-prowadzi-i-rozwija-w-asny/8xg.t.sbz.2.1-prowadzi-i-rozwija-w-asny-ace-assign.s.md) | [L3.1 / 8xg.t.sbz.2.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/0-startowa-z-przygotowanej-konfiguracji-coworkera/8xg.t.sbz.2.0-startowa-z-przygotowanej-konfiguracji-coworkera.s.md) |
| [L3.3 / 8xg.t.sbz.2.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/2-zapisywa-wynik-i-raportowa-przez/8xg.t.sbz.2.2-zapisywa-wynik-i-raportowa-przez-hitl.s.md) | [L3.2 / 8xg.t.sbz.2.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/1-prowadzi-i-rozwija-w-asny/8xg.t.sbz.2.1-prowadzi-i-rozwija-w-asny-ace-assign.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md) |
| [L3.4 / 8xg.t.sbz.2.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/3-wznawia-assignment-z-istniej-cego/8xg.t.sbz.2.3-wznawia-assignment-z-istniej-cego-worktree.s.md) | [L3.3 / 8xg.t.sbz.2.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/2-zapisywa-wynik-i-raportowa-przez/8xg.t.sbz.2.2-zapisywa-wynik-i-raportowa-przez-hitl.s.md) |
| [L4.1 / 8xg.t.sbz.3.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/0-przyjmowa-zlecenie-przygotowania-i-zapewnia/8xg.t.sbz.3.0-przyjmowa-zlecenie-przygotowania-i-zapewnia-worktree.s.md) | [L3.2 / 8xg.t.sbz.2.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/1-prowadzi-i-rozwija-w-asny/8xg.t.sbz.2.1-prowadzi-i-rozwija-w-asny-ace-assign.s.md), [L6.2 / 8xg.t.sbz.5.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/1-zapisywa-proces-wykonania-w-subtaskach/8xg.t.sbz.5.1-zapisywa-proces-wykonania-w-subtaskach.s.md) |
| [L4.2 / 8xg.t.sbz.3.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/1-przygotowywa-assignmenty-dla-sekwencji-r/8xg.t.sbz.3.1-przygotowywa-assignmenty-dla-sekwencji-r-l.s.md) | [L4.1 / 8xg.t.sbz.3.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/0-przyjmowa-zlecenie-przygotowania-i-zapewnia/8xg.t.sbz.3.0-przyjmowa-zlecenie-przygotowania-i-zapewnia-worktree.s.md), [L5 / 8xg.t.sbz.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md) |
| [L4.3 / 8xg.t.sbz.3.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/2-przygotowywa-konfiguracj-startow-wykonawc-w/8xg.t.sbz.3.2-przygotowywa-konfiguracj-startow-wykonawc-w.s.md) | [L4.2 / 8xg.t.sbz.3.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/1-przygotowywa-assignmenty-dla-sekwencji-r/8xg.t.sbz.3.1-przygotowywa-assignmenty-dla-sekwencji-r-l.s.md) |
| [L4.4 / 8xg.t.sbz.3.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/3-raportowa-gotowo-lub-braki-overseerowi/8xg.t.sbz.3.3-raportowa-gotowo-lub-braki-overseerowi.s.md) | [L4.3 / 8xg.t.sbz.3.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/2-przygotowywa-konfiguracj-startow-wykonawc-w/8xg.t.sbz.3.2-przygotowywa-konfiguracj-startow-wykonawc-w.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md) |
| [L5.1 / 8xg.t.sbz.4.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/0-dostarczy-role-worker-i-spec/8xg.t.sbz.4.0-dostarczy-role-worker-i-spec.s.md) | [L3 / 8xg.t.sbz.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md) |
| [L5.2 / 8xg.t.sbz.4.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/1-domyka-poprawki-wewn-trz-roli/8xg.t.sbz.4.1-domyka-poprawki-wewn-trz-roli-reviewer.s.md) | [L3 / 8xg.t.sbz.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md) |
| [L5.3 / 8xg.t.sbz.4.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/2-egzekwowa-pe-ne-rundy-i/8xg.t.sbz.4.2-egzekwowa-pe-ne-rundy-i-limit-review.s.md) | [L5.2 / 8xg.t.sbz.4.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/1-domyka-poprawki-wewn-trz-roli/8xg.t.sbz.4.1-domyka-poprawki-wewn-trz-roli-reviewer.s.md) |
| [L5.4 / 8xg.t.sbz.4.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/3-dostarczy-integratora-zale-nego-od/8xg.t.sbz.4.3-dostarczy-integratora-zale-nego-od-wynik-w.s.md) | [L5.3 / 8xg.t.sbz.4.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/2-egzekwowa-pe-ne-rundy-i/8xg.t.sbz.4.2-egzekwowa-pe-ne-rundy-i-limit-review.s.md) |
| [L5.5 / 8xg.t.sbz.4.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/4-ujednolici-workflow-review-i-obs/8xg.t.sbz.4.4-ujednolici-workflow-review-i-obs-ug-forge.s.md) | [L5.1 / 8xg.t.sbz.4.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/0-dostarczy-role-worker-i-spec/8xg.t.sbz.4.0-dostarczy-role-worker-i-spec.s.md), [L5.3 / 8xg.t.sbz.4.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/2-egzekwowa-pe-ne-rundy-i/8xg.t.sbz.4.2-egzekwowa-pe-ne-rundy-i-limit-review.s.md), [L5.4 / 8xg.t.sbz.4.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/3-dostarczy-integratora-zale-nego-od/8xg.t.sbz.4.3-dostarczy-integratora-zale-nego-od-wynik-w.s.md) |
| [L6.1 / 8xg.t.sbz.5.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/0-zapewni-prywatn-nietrackowan-list-overseera/8xg.t.sbz.5.0-zapewni-prywatn-nietrackowan-list-overseera.s.md) | [L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md) |
| [L6.2 / 8xg.t.sbz.5.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/1-zapisywa-proces-wykonania-w-subtaskach/8xg.t.sbz.5.1-zapisywa-proces-wykonania-w-subtaskach.s.md) | [L6.1 / 8xg.t.sbz.5.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/0-zapewni-prywatn-nietrackowan-list-overseera/8xg.t.sbz.5.0-zapewni-prywatn-nietrackowan-list-overseera.s.md) |
| [L6.3 / 8xg.t.sbz.5.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/2-uruchamia-wy-cznie-kroki-odblokowane/8xg.t.sbz.5.2-uruchamia-wy-cznie-kroki-odblokowane-zale-no.s.md) | [L6.2 / 8xg.t.sbz.5.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/1-zapisywa-proces-wykonania-w-subtaskach/8xg.t.sbz.5.1-zapisywa-proces-wykonania-w-subtaskach.s.md), [L4 / 8xg.t.sbz.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md) |
| [L6.4 / 8xg.t.sbz.5.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/3-przekazywa-worktree-kolejnym-wykonawcom/8xg.t.sbz.5.3-przekazywa-worktree-kolejnym-wykonawcom.s.md) | [L6.3 / 8xg.t.sbz.5.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/2-uruchamia-wy-cznie-kroki-odblokowane/8xg.t.sbz.5.2-uruchamia-wy-cznie-kroki-odblokowane-zale-no.s.md) |
| [L6.5 / 8xg.t.sbz.5.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/4-przetwarza-raporty-i-kontynuowa-kolejk/8xg.t.sbz.5.4-przetwarza-raporty-i-kontynuowa-kolejk.s.md) | [L6.4 / 8xg.t.sbz.5.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/3-przekazywa-worktree-kolejnym-wykonawcom/8xg.t.sbz.5.3-przekazywa-worktree-kolejnym-wykonawcom.s.md) |
| [L7.1 / 8xg.t.sbz.6.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/0-udost-pni-statusy-laba-herdr/8xg.t.sbz.6.0-udost-pni-statusy-laba-herdr-i-worktree.s.md) | [L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md) |
| [L7.2 / 8xg.t.sbz.6.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/1-zebra-konfigurowalny-status-overseera/8xg.t.sbz.6.1-zebra-konfigurowalny-status-overseera.s.md) | [L7.1 / 8xg.t.sbz.6.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/0-udost-pni-statusy-laba-herdr/8xg.t.sbz.6.0-udost-pni-statusy-laba-herdr-i-worktree.s.md), [L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md) |
| [L7.3 / 8xg.t.sbz.6.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/2-kontynuowa-zlecon-prac-w-pi/8xg.t.sbz.6.2-kontynuowa-zlecon-prac-w-pi.s.md) | [L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md) |
| [L7.4 / 8xg.t.sbz.6.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/3-pokazywa-blokady-awarie-i-brak/8xg.t.sbz.6.3-pokazywa-blokady-awarie-i-brak-danych.s.md) | [L7.2 / 8xg.t.sbz.6.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/1-zebra-konfigurowalny-status-overseera/8xg.t.sbz.6.1-zebra-konfigurowalny-status-overseera.s.md), [L7.3 / 8xg.t.sbz.6.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/2-kontynuowa-zlecon-prac-w-pi/8xg.t.sbz.6.2-kontynuowa-zlecon-prac-w-pi.s.md) |
| [L8.1 / 8xg.t.sbz.7.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/0-przygotowa-konta-katalogi-uprawnienia-i/8xg.t.sbz.7.0-przygotowa-konta-katalogi-uprawnienia-i-klucze.s.md) | [L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md), [L2.2 / 8xg.t.sbz.1.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/1-ujednolici-adresowanie-odbiorc-w-i/8xg.t.sbz.1.1-ujednolici-adresowanie-odbiorc-w-i-reply.s.md), [L3.1 / 8xg.t.sbz.2.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/0-startowa-z-przygotowanej-konfiguracji-coworkera/8xg.t.sbz.2.0-startowa-z-przygotowanej-konfiguracji-coworkera.s.md) |
| [L8.2 / 8xg.t.sbz.7.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/1-dodawa-projekt-gotowy-do-pracy/8xg.t.sbz.7.1-dodawa-projekt-gotowy-do-pracy-zespo-u.s.md) | [L8.1 / 8xg.t.sbz.7.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/0-przygotowa-konta-katalogi-uprawnienia-i/8xg.t.sbz.7.0-przygotowa-konta-katalogi-uprawnienia-i-klucze.s.md), [L4 / 8xg.t.sbz.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md), [L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md) |
| [L8.3 / 8xg.t.sbz.7.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/2-przeprowadza-instalacj-nowego-laba/8xg.t.sbz.7.2-przeprowadza-instalacj-nowego-laba.s.md) | [L8.2 / 8xg.t.sbz.7.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/1-dodawa-projekt-gotowy-do-pracy/8xg.t.sbz.7.1-dodawa-projekt-gotowy-do-pracy-zespo-u.s.md) |
| [L8.4 / 8xg.t.sbz.7.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/3-wznawia-w-asn-przerwan-instalacj/8xg.t.sbz.7.3-wznawia-w-asn-przerwan-instalacj.s.md) | [L8.3 / 8xg.t.sbz.7.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/2-przeprowadza-instalacj-nowego-laba/8xg.t.sbz.7.2-przeprowadza-instalacj-nowego-laba.s.md) |
| [L8.5 / 8xg.t.sbz.7.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/4-weryfikowa-gotowo-pod-docelowymi-kontami/8xg.t.sbz.7.4-weryfikowa-gotowo-pod-docelowymi-kontami.s.md) | [L8.4 / 8xg.t.sbz.7.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/3-wznawia-w-asn-przerwan-instalacj/8xg.t.sbz.7.3-wznawia-w-asn-przerwan-instalacj.s.md), [L7 / 8xg.t.sbz.6](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md) |
| [L9.1 / 8xg.t.sbz.8.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/0-sprawdzi-pe-n-sekwencj-przygotowania/8xg.t.sbz.8.0-sprawdzi-pe-n-sekwencj-przygotowania-i-wykonania.s.md) | [L8 / 8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md) |
| [L9.2 / 8xg.t.sbz.8.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/1-sprawdzi-awarie-wznowienia-i-eskalacje/8xg.t.sbz.8.1-sprawdzi-awarie-wznowienia-i-eskalacje.s.md) | [L8 / 8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md) |
| [L9.3 / 8xg.t.sbz.8.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/2-sprawdzi-izolacj-zada-i-sekwencj/8xg.t.sbz.8.2-sprawdzi-izolacj-zada-i-sekwencj-r-l.s.md) | [L8 / 8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md) |
| [L9.4 / 8xg.t.sbz.8.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/3-sprawdzi-macierz-forge-i-instalacji/8xg.t.sbz.8.3-sprawdzi-macierz-forge-i-instalacji.s.md) | [L8 / 8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md) |
| [L10.1 / 8xg.t.sbz.9.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/0-przygotowa-sp-jny-zestaw-wersji/8xg.t.sbz.9.0-przygotowa-sp-jny-zestaw-wersji-do-wydania.s.md) | [L9 / 8xg.t.sbz.8](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md) |
| [L10.2 / 8xg.t.sbz.9.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/1-opublikowa-gemy-w-kolejno-ci/8xg.t.sbz.9.1-opublikowa-gemy-w-kolejno-ci-zale-no.s.md) | [L10.1 / 8xg.t.sbz.9.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/0-przygotowa-sp-jny-zestaw-wersji/8xg.t.sbz.9.0-przygotowa-sp-jny-zestaw-wersji-do-wydania.s.md) |
| [L10.3 / 8xg.t.sbz.9.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/2-sprawdzi-wie-y-lab-z/8xg.t.sbz.9.2-sprawdzi-wie-y-lab-z-rubygems.s.md) | [L10.2 / 8xg.t.sbz.9.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/1-opublikowa-gemy-w-kolejno-ci/8xg.t.sbz.9.1-opublikowa-gemy-w-kolejno-ci-zale-no.s.md) |
| [L10.4 / 8xg.t.sbz.9.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/3-zamkn-program-na-podstawie-wyniku/8xg.t.sbz.9.3-zamkn-program-na-podstawie-wyniku-odbioru.s.md) | [L10.3 / 8xg.t.sbz.9.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/2-sprawdzi-wie-y-lab-z/8xg.t.sbz.9.2-sprawdzi-wie-y-lab-z-rubygems.s.md), [L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md), [L3 / 8xg.t.sbz.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md), [L4 / 8xg.t.sbz.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md), [L5 / 8xg.t.sbz.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md), [L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md), [L7 / 8xg.t.sbz.6](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md), [L8 / 8xg.t.sbz.7](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md), [L9 / 8xg.t.sbz.8](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md) |

## Walidacja i zastosowane instrukcje

Zmiana obejmuje tylko specyfikacje i dependencies. Nie uruchomiono wykonawców,
nie wykonano implementacji, integracji ani publikacji. Sprawdzić zgodność tabeli
z frontmatter, 42 liście, brak cykli także przez rodziców i brak zależności od
anulowanego programu. Wcześniejsze kryteria odbioru nadal obowiązują.

Loaded: as-task-plan (analiza zależności), as-task-draft (aktualizacja specyfikacji).
Executed: aktualizacja draftów. Pełnego JIT workflow as-task-plan dla pending taska
nie uruchamiano: to plan kolejności backlogu draft, a nie plan implementacji pojedynczej funkcji.
