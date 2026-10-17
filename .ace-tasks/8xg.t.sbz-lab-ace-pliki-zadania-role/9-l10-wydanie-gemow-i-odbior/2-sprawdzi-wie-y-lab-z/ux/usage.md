# Sprawdzić świeży lab z RubyGems — scenariusze użycia

## Interfejs

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: W nowym środowisku użyć wyłącznie wydanych gemów: gem install ace-lab → ace-lab install → ace-lab project add → pełna sekwencja zadania → statusy.

Oczekiwany wynik: Potwierdzone wersje i ścieżki pochodzą z RubyGems, a cały proces działa bez checkoutowych binstubów i lokalnych override.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Nieopublikowana zależność, niegotowa instalacja albo nieukończone zadanie oznaczają niezaliczony odbiór, nie przejście na źródła lokalne.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
