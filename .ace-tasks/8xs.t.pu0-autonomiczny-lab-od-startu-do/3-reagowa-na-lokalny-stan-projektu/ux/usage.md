# Reagować na lokalny stan projektu — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Raport końca pracy

Wejście / wywołanie: Coworker raportuje wynik; nadzorca obserwuje projekt.

Oczekiwany wynik: Nadzorca przetwarza raport i wybiera kolejny etap zgodny z zależnościami.

## Scenariusz 2: Restart

Wejście / wywołanie: Zatrzymać nadzorcę, dostarczyć raport, uruchomić ace-overseer start.

Oczekiwany wynik: Oczekujący raport zostaje obsłużony bez zgubienia lub zdublowania pracy.

## Scenariusz 3: Cisza i awaria

Wejście / wywołanie: Pozostawić stan bez zmian, następnie odłączyć źródło.

Oczekiwany wynik: Cisza nie uruchamia modelu; awaria jest odróżniona od zdrowego braku zmian.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/3-reagowa-na-lokalny-stan-projektu/8xs.t.pu0.3-reagowa-na-lokalny-stan-projektu.s.md.

## Uściślenia review

Start uzbraja lokalne źródła: taski projektu i _overseer, role/dostępność zespołu,
worktree, assignment progress oraz HITL. `ace-overseer observe` rozszerza istniejącą
projekcję o te źródła; dane odczytuje od ich właścicieli. Session-owned stan obserwacji
przechowuje tylko rewizje/ACK, nigdy drugi stan zadań. ACK następuje po przyjęciu przez
właściwy task/assignment; settled modelu nie jest dowodem obsłużenia.

Po starcie najpierw reconcile zaległych raportów i aktualnych assignmentów, następnie
wybór pracy przez istniejący plan/dependencies. Gotowe zadania wybierać według istniejącej
kolejności ace-task; niespełnione zależności pozostają blocked. Pusty zbiór jest idle.
Zmiana powstała przed startem nie może zniknąć jako nowy baseline. Rozpoznawanie live/stale
coworkera używa istniejących identyfikatorów uruchomienia, nie samych nazw pane.

Awaria jednego źródła degraduje tylko to źródło i ma ograniczone ponowienia z backoff;
pozostałe działają. Default lokalnego reconcile 15 s, wykrycie <=2 interwały przy zdrowym
źródle. Completion ping do adresu z briefu jest szybką wskazówką; trwały raport HITL
pozostaje podstawą kontynuacji. Brak pane kieruje raport do HITL bez nowej kolejki.
Konsumenci: ace-overseer, ace-wake, ace-task, ace-assign, ace-coworker, ace-hitl, Herdr.
