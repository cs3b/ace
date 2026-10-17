# Wznawiać własną przerwaną instalację — scenariusze użycia

## Interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Rozpoznawać własną niedokończoną instalację i umożliwiać dokończenie zachowanych etapów; odróżniać ją od gotowego laba i obcych zasobów.

Oczekiwany wynik: Przerwanie po kontach lub katalogach i ponowne uruchomienie kończą tę samą instalację bez duplikatów i utraty konfiguracji.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Obcy katalog lub niespójny stan nie są automatycznie przejmowane ani czyszczone; brak możliwości wznowienia daje konkretną informację.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
