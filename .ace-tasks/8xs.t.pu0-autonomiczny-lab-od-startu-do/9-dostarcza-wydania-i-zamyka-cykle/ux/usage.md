# Dostarczać wydania i zamykać cykle — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Pełne dostarczenie

Wejście / wywołanie: Po merge nadzorca deleguje release → publish → install → verify → record.

Oczekiwany wynik: Zmiana działa pod docelowym kontem, a rekord cyklu jest w Git.

## Scenariusz 2: Opóźnione OTP

Wejście / wywołanie: Kapitan odpowiada później na pytanie publishera.

Oczekiwany wynik: Publikacja kontynuuje właściwy etap; wygasłe OTP wymaga nowego pytania, bez ujawniania wartości.

## Scenariusz 3: Awaria instalacji

Wejście / wywołanie: Przerwać instalację po udanej publikacji, następnie wznowić.

Oczekiwany wynik: Cykl pozostaje otwarty; wznowienie rozpoznaje opublikowane wersje i doprowadza do odbioru.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/8xs.t.pu0.9-dostarcza-wydania-i-zamyka-cykle.s.md.
