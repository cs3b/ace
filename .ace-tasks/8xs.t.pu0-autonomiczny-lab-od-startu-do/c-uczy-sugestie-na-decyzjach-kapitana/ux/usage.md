# Uczyć sugestie na decyzjach Kapitana — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Korekta jako przykład

Wejście / wywołanie: Kapitan odrzuca sugestię i podaje inną odpowiedź; później pojawia się podobne pytanie.

Oczekiwany wynik: Nowa propozycja ma dostęp do rzeczywistej decyzji i odnosi się do jej kontekstu.

## Scenariusz 2: Brak precedensu

Wejście / wywołanie: Zadać pytanie bez odpowiedniej historii.

Oczekiwany wynik: Agent zaznacza brak przykładów i nie wymyśla wcześniejszej zgody.

## Scenariusz 3: Sekret i izolacja

Wejście / wywołanie: W historii są sprawy OTP lub sprawa innego niedostępnego projektu.

Oczekiwany wynik: Wartości sekretów i niedozwolony kontekst nie są używane ani ujawniane.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/8xs.t.pu0.c-uczy-sugestie-na-decyzjach-kapitana.s.md.

## Uściślenia review

Trigger uczenia to zaakceptowana nietajna odpowiedź człowieka do sprawy z sugestią.
Wniosek zapisuje ace-hitl przy tej sprawie jako lesson z odwołaniem do dokładnych rewizji
pytania/sugestii/decyzji, autorem agenta i czasem. Idempotencja po case + decision revision;
wniosek nie jest nową decyzją i nie zmienia jej autora. Brak sugestii oznacza brak
porównania, nie zmyśloną zgodność. Race zamknięcia nie kasuje historii ani nie wznawia operacji.

Default retrieval ograniczony do tego samego projektu i obecnie dostępnych nietajnych
spraw; nie korzystać z szerszego dostępu nadzorcy laba jako przyzwolenia na dzielenie
historii. Wybierać podobny temat/rodzaj decyzji, podać referencje i ograniczenia; nowsza
jawna korekta Kapitana ma pierwszeństwo nad wcześniejszą sugestią. Brak podstaw jest
widoczny. Bez embedding-store, indeksu decyzji ani kopii korpusu poza HITL.

Filtr secret/OTP i uprawnień działa przed przekazaniem historii do modelu; także treść
sugestii/wniosku nie może przywrócić wykluczonych wartości. Konsumenci: ace-hitl
odczyt/sekcje/historia, ace-coworker instrukcje second-captain, ace-overseer trigger.
