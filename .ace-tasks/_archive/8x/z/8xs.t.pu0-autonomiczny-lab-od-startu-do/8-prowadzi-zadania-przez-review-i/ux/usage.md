# Prowadzić zadania przez review i merge — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Poprawny kandydat

Wejście / wywołanie: Worker dostarcza PR, reviewer sprawdza go, integrator odbiera.

Oczekiwany wynik: Wykonane testy i niezależny werdykt wraz z wymaganym approval prowadzą do merge.

## Scenariusz 2: Zmiana HEAD

Wejście / wywołanie: Zmienić kandydata po review przed merge.

Oczekiwany wynik: Następuje właściwa ponowna weryfikacja nowego kandydata.

## Scenariusz 3: Brak dowodu

Wejście / wywołanie: Zgłosić sukces bez wykonanych testów lub z nierozwiązanym wymaganym findingiem.

Oczekiwany wynik: Gate zatrzymuje integrację i pokazuje brakującą podstawę.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/8xs.t.pu0.8-prowadzi-zadania-przez-review-i-merge.s.md.

## Uściślenia review

Zachować istniejące reguły rund 3/2/10 i role, nie tworzyć drugiego gate.
Zestaw dowodów przy assignment/review zawiera HEAD, wykonane komendy i ich wynik oraz
niezależną tożsamość reviewera. Powiązanie testów z HEAD jest obowiązkowe: obecne
`executed/passed` bez head nie wystarcza. Aktualizować atom gate, CLI, report producerów
i konsumentów równocześnie. Formalny provider approval również odnosi się do tego HEAD.

Zmiana kodu/rebase po testach albo review unieważnia podstawy dotyczące starego kandydata.
Integrator bezpośrednio przed merge odczytuje HEAD i approval oraz korzysta z warunku
oczekiwanego SHA w adapterze; wyścig między gate a merge ma odmówić staremu kandydatowi.
Gdy merge się wykonał, lecz utracono odpowiedź, sprawdzić forge, nie ponawiać skutku na ślepo.
CI red nie blokuje przy wykonanych przechodzących testach i akceptującym niezależnym review.

Konsumenci: ace-coworker gate/rounds/report i workflow reviewer/integrator, ace-overseer
handoff/process-reports, ace-git oraz oba adaptery forge. Autor i formalny approver
muszą być zgodni ze skonfigurowanymi lane; brak uprawnienia pozostaje blokadą.

## Dostęp roli przez auth

Reviewer, formalny approver i integrator pobierają odrębne lease przez ace-lab auth
według .7. Przed operacją zweryfikować principal, repo, scope i use_until; zmiana roli
nie przejmuje tokenu poprzednika. Do dowodu kryterium 1 dołączyć request → review/merge
→ revoke bez sekretów. W próbie negatywnej lease autora nie daje formalnego approval,
a expiry przed merge daje odmowę bez fallbacku do konta nadzorcy.
