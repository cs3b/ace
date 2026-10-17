# Weryfikować gotowość pod docelowymi kontami — scenariusze użycia

## Interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Końcowa weryfikacja instalacji sprawdza pliki, narzędzia, role i skonfigurowane drogi komunikacji pod docelowymi kontami.

Oczekiwany wynik: Dostęp do worktree, konfiguracji i odpowiedniego klucza oraz komunikacja są potwierdzone dla rzeczywistego wykonawcy, nie tylko konta instalatora.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak pliku, złe uprawnienia, rola lub niedziałający adapter uniemożliwiają oznaczenie laba jako gotowego.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
