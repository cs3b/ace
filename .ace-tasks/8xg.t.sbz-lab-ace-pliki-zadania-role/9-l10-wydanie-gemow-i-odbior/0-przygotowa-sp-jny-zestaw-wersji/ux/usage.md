# Przygotować spójny zestaw wersji do wydania — scenariusze użycia

## Interfejs

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Po przyjęciu L9 przygotować spójny zestaw wersji gemów, CHANGELOG, minimalne zależności i kolejność publikacji.

Oczekiwany wynik: Manifest wskazuje dokładne wersje, źródło i artefakty; instalacja przygotowanych paczek rozwiązuje wymagane zależności.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Niezgodny floor lub paczka spoza przyjętego zestawu zatrzymuje przygotowanie wydania; samo przygotowanie nie oznacza publikacji.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
