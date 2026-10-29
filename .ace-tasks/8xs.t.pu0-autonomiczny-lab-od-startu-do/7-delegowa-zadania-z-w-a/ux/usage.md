# Delegować zadania z właściwymi uprawnieniami — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Pełna delegacja

Wejście / wywołanie: Nadzorca przygotowuje i zleca zadanie przez ace-coworker.

Oczekiwany wynik: Wykonawca pracuje w poprawnym worktree z assignmentem i raportuje do nadzorcy.

## Scenariusz 2: Brak uprawnienia

Wejście / wywołanie: Zlecić operację bez wymaganego dostępu.

Oczekiwany wynik: Coworker raportuje konkretną blokadę przez HITL.

## Scenariusz 3: Zakończenie przydziału

Wejście / wywołanie: Zakończyć albo przerwać zlecenie z czasowym dostępem.

Oczekiwany wynik: Przydział kończy się zgodnie z zakresem; sekret nie pojawia się w raporcie.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md.
