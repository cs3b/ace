# Autonomiczny lab — draft usage

## Scenariusz 1: cały lab

Wejście: skonfigurowany, gotowy runtime i co najmniej dwa projekty.
Wywołanie: ace-overseer start w katalogu laba.
Wynik: spaces i nadzorcy projektów, agregowany stan i samodzielnie kontynuowane zlecenie.

## Scenariusz 2: samodzielny projekt i ponowny start

Wywołanie: ace-overseer start w katalogu projektu, następnie ponowienie i start całego laba.
Wynik: jedna żywa sesja projektu, właściwe instrukcje i odtworzona obserwacja.

## Scenariusz 3: decyzja z sugestią i błąd dostawy

Wejście: pytanie wymagające decyzji człowieka.
Wynik: pytanie oraz oznaczona sugestia Second Captaina w tej samej sprawie HITL.
Niedostępny doradca nie blokuje pytania. Błąd dostawy odpowiedzi jest jawny.
Po ponowieniu odpowiedź trafia do właściwej sprawy i wywołuje najwyżej jeden skutek.

## Konwencja wykonania

W repo używać bin/ace-*. W installed labie używać zainstalowanych CLI/gemów/workflow.
To kontrakt docelowy, nie deklaracja obecnego działania.
