# Zamykać sprawy HITL bez sierot — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Zamknięcie sprawy

Wejście / wywołanie: Dostarczyć i zastosować odpowiedź, zakończyć czynność.

Oczekiwany wynik: Sprawa jest zamknięta, niepotrzebny watch nie wybudza odbiorcy.

## Scenariusz 2: Duplikat i restart

Wejście / wywołanie: Ponowić odpowiedź po restarcie odbiorcy.

Oczekiwany wynik: Brak ponownego wykonania zakończonej operacji.

## Scenariusz 3: Późna odpowiedź i sweep

Wejście / wywołanie: Odpowiedzieć na zamkniętą sprawę i przejrzeć pozostałości transportu.

Oczekiwany wynik: Brak automatycznej zmiany decyzji; aktywne sprawy i historia pozostają.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/8xs.t.pu0.6-zamyka-sprawy-hitl-bez-sierot.s.md.

## Uściślenia review

Stan pozostaje w kanonicznym pliku HITL. Ustalić rozdzielnie receipt (pending/received)
i zastosowanie (pending/applied/closed, z cancelled jako zakończenie bez zastosowania);
raporty pozostają recorded i nie oczekują odpowiedzi. W pliku zapisywać identyfikator
dostawy, właściciela pytania i referencję do wyniku istniejącego taska/assignmentu.
Nie tworzyć z tego drugiego rejestru efektów. Kolejne aktualizacje przez ace-hitl muszą
być atomowe i odrzucać konflikt równoczesnych odpowiedzi.

Exactly-once dotyczy skutku, nie samej liczby powiadomień. Gdy proces padł po efekcie,
przed applied, konsument najpierw sprawdza wynik u właściciela efektu (PR/release/assignment).
Brak możliwości rozstrzygnięcia oznacza jawną blokadę uzgodnienia, nigdy ślepe powtórzenie.
Zamknięcie dopiero po dowodzie applied; duplikat jest no-op, późna odmienna odpowiedź
odrzucona jako konflikt i nie otwiera case. Jawna zmiana decyzji wymaga nowej sprawy.

Sweep najpierw pokazuje listę/kryterium kwalifikacji. Usuwa tylko powiązane watch/request/
transport po dowiedzionym zamknięciu; unknown delivery, aktywna sprawa, nierozpoznany
zasób i kanoniczna historia są zachowane. Historyczne ID z relacji nie są listą do delete.
Nie usuwać całego worktree z otwartym HITL. Konsumenci: ace-hitl, ace-wake,
ace-hitl-hermes, ace-coworker oraz process-reports w ace-overseer.
