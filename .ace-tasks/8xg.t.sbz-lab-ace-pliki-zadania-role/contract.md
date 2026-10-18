# Kontrakt programu laba ACE

Zatwierdzone przez użytkownika 2026-10-17. To wymagania nowego programu;
sprzeczne opisy w starych taskach i obecnych dokumentach są kontekstem do zastąpienia.

## Właściciele i miejsca zapisu

- `ace-lab` przygotowuje środowisko i projekty; nie prowadzi kolejki pracy.
- Każdy overseer ma własny `ace-task --in _overseer`, poza Git. Tylko on nim zarządza.
- Task projektowy ma własne worktree. Kolejne role pracują w nim sekwencyjnie;
  overseer zapewnia jednego aktywnego wykonawcę. Różne taski mogą działać równolegle.
- Postęp związany z zadaniem, który ma przetrwać między turami, zapisuje się w folderze zadania.
- `.ace-local/coworker/` zawiera rolę, źródło jej instrukcji, prompt startowy,
  task, odwołanie do assignmentu, adres overseera, zasady raportowania i obsługi błędów.
- Istniejący `ace-assign` przechowuje plan wykonania. Nie kopiujemy jego kroków
  do drugiej kolejki ani do konfiguracji coworkera.
- `ace-hitl` przechowuje własne zdarzenia w plikach agenta; raport dociera do overseera,
  który interpretuje wiadomość i aktualizuje swój task zarządzający.

## Proces i role

Overseer układa lub deleguje rewizję drzewa pracy, a przygotowanie szczegółowych
assignmentów deleguje plannerowi. Planner zapewnia worktree i planuje sekwencję
assignmentów od razu. Po starcie wykonujący driver może rozwijać swój assignment,
dodawać kroki i review w granicach celu oraz reguł roli. Nie zmienia w ten sposób
celu nadrzędnego ani zależności w prywatnym drzewie overseera.

Role worker, reviewer, integrator, planner i spec używają wspólnego `ace-coworker`.
Assignment kończy się sukcesem po wykonaniu wymaganych kroków albo zgłoszeniem
błędu; stan lokalny i wiadomość do overseera zachowują wynik i postęp.

Reviewer jest niezależny od workera. Sam poprawia wykryte błędy, sprawdza diff
poprawek i przeprowadza kolejne pełne rundy. Minimum 3 pełne rundy, ostatnie 2
kolejne bez potwierdzonych High/Critical i brak nierozwiązanych wcześniejszych
High/Critical. Maksimum 10 pełnych rund: jeśli dziesiąta spełnia warunki, kończy
sukcesem; w przeciwnym razie eskaluje do overseera. Diff review nie zwiększa tego
licznika. Przerwane lub niekompletne review nie jest czystą rundą. Wznowienie
zachowuje dotychczasowe ustalenia, liczniki i wyniki.

## Komunikacja i kontynuacja

`ace-hitl` ma stały interfejs dla ludzi i agentów. Rozróżnia raport bez oczekiwania
na odpowiedź oraz pytanie/eskalację wymagającą odpowiedzi. Adresowanie zachowuje
maszynę, folder i ID albo maszynę i panel. Reply trafia do właściwej sprawy.
Adaptery są konfigurowalne, pojedynczo lub w zestawie; `ace-hitl-hermes` pozostaje
adapterem. Obsługa tmux/Herdr nie wymaga innego interfejsu nadawcy. Nervus jest
przykładem przyszłego adaptera, nie dodatkowym zakresem tego programu.

Ponowienie dostarczenia wiadomości nie oznacza ponowienia wykonania zadania.
Restart odczytuje istniejący task, assignment i prawdę o worktree/projekcie.
Nie budujemy wspólnego journala, dodatkowej bazy stanu, cache'u kolejki, silnika
kolejkowania ani usług pośredniczących w autoryzacji mutacji. Uprawnienia należą
do istniejących kont i plików. Zachowujemy potrzebne transporty adapterów i terminali.

Overseer kontynuuje już zleconą pracę i odblokowane subtaski. Samodzielne szukanie
nowej pracy i poziomy proaktywności pozostają poza obecnym zakresem.

## Odbiór i granice programu

Pierwszy obieg coworker–overseer sprawdzamy w L6; L9 obejmuje pełny test przed
publikacją, L10 osobny test wersji z RubyGems. Zależności budowy w tym programie
nie są runtime'owym drzewem `_overseer`.

Bez warstw kompatybilności ze starym modelem laba (ADR-024). Instalator odmawia
nadpisania gotowego/obcego laba, ale potrafi dokończyć własną przerwaną instalację.
Nie kasujemy istniejących worktree, branchy, raportów ani historii starych zadań.
Nie dodajemy VM, systemu rozproszonego ani nowej granicy izolacji jako warunku MVP.

Implementacja: `bin/ace-test <pakiet> all`, `bin/ace-test-suite`, niezależny review
przed merge i commity ograniczone do właściwych ścieżek. CI jest doradcze.
Zapis tego backlogu nie jest wykonaniem funkcji, testów systemu ani publikacją.

## Kolejność realizacji backlogu

[Fale pracy i integracja](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md) zastępują pierwotny łańcuch L1–L10. Zależności są zapisane na poziomie liści. Zależny liść czeka na odebrany i zintegrowany wynik; overseer odwzorowuje merge w swoim prywatnym procesie. Główne taski grupują odbiór, nie serializują wszystkich prac.

## Doprecyzowanie po review 2026-10-18

`_overseer` jest zwykłym ignorowanym folderem tasków. Politykę własności,
przydziałów i sekwencji ról realizuje overseer, nie guardy nazw folderów
w ace-task/ace-assign/ace-git-worktree. Może korzystać z subagentów do planowania,
analizy i weryfikacji; sam pozostaje właścicielem zapisu procesu.
W backlogu implementacyjnym jedno worktree może obejmować główny task i jego
kolejne podtaski. Pośrednie wyniki integrować, gdy odblokowują inny tor.
