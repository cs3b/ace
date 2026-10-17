# Opublikować gemy w kolejności zależności — scenariusze użycia

## Interfejs

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Opublikować uzgodniony zestaw gemów w kolejności zależności, zapisując rzeczywisty wynik dla każdej paczki.

Oczekiwany wynik: Każda wymagana wersja jest dostępna w RubyGems i odpowiada zaakceptowanemu artefaktowi.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Przy częściowym niepowodzeniu lub utracie odpowiedzi sprawdzić dostępne wersje i dopiero kontynuować brakujące publikacje; nie deklarować pełnego release bez potwierdzeń.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
