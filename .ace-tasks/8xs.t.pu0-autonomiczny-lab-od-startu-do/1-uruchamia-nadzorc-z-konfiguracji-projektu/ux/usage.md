# Uruchamiać nadzorcę z konfiguracji projektu — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Pierwszy start

Wejście / wywołanie: W katalogu skonfigurowanego projektu: ace-overseer start.

Oczekiwany wynik: Powstaje sesja nadzorcy z guide z gema i rozpoznanym stanem projektu.

## Scenariusz 2: Istniejąca sesja

Wejście / wywołanie: Ponownie ace-overseer start w tym samym projekcie.

Oczekiwany wynik: Wynik identyfikuje istniejącego nadzorcę bez dodatkowej sesji.

## Scenariusz 3: Nieprzygotowany katalog

Wejście / wywołanie: ace-overseer start w katalogu bez wymaganej konfiguracji.

Oczekiwany wynik: Brak uruchomienia zgadywanego projektu; komunikat podaje brak konfiguracji.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/8xs.t.pu0.1-uruchamia-nadzorc-z-konfiguracji-projektu.s.md.

## Uściślenia review

Konfiguracja startu należy do istniejącej kaskady `.ace/overseer/config.yml`.
Sekcja `start` ma jawne `scope: project|lab`, `profile` (odwołanie do skonfigurowanego
profilu harnessu/modelu) i `instructions` (źródło handbook). Wartość scope musi pochodzić
z konfiguracji tego katalogu, nie z przypadkowej globalnej listy projektów. Projekt rozpoznaje
kanoniczny root repo; podkatalog/symlink tego rootu prowadzi do tego samego właściciela.
Worktree projektu nie uruchamia drugiego nadzorcy całego projektu. Brak scope/profilu lub
sprzeczny root to błąd przed startem. Na tym etapie scope lab zgłasza niewdrożoną zdolność.

`ace-overseer start [--dry-run] [--format table|json]` zwraca scope, root, źródła
konfiguracji/instrukcji, profil, runtime identity i stan started/reused/blocked. Exit 0
tylko dla gotowego startu/reuse; dry-run pokazuje plan bez sesji, synchronizacji i wywołania
modelu. Żadnych domyślnych modeli z interim skryptu. Start używa Herdr i jego istniejącej
tożsamości sesji; dwa równoczesne wywołania nie tworzą dwóch agentów. Żywa sesja o innym
cwd/profilu/wersji jest konfliktem, nie jest przejmowana. Martwa sesja może zostać zastąpiona
po sprawdzeniu rzeczywistego stanu, z nową tożsamością wskazaną w wyniku.

Guide projektu dostarcza ace-overseer przez handbook, z normalnymi override. Po starcie
agent odczytuje prywatne zadania oraz stan od właścicieli, kontynuuje istniejącą pracę;
przy pustej liście pozostaje idle. Brak coworkera zgłasza, nie przejmuje jego roli.
Konsumenci: ace-overseer, ace-herdr/ace-runtime, ace-lab, handbook i późniejszy lab start.
