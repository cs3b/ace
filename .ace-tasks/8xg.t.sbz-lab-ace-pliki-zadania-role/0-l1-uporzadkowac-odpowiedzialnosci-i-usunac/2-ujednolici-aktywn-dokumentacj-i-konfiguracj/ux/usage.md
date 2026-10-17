# Ujednolicić aktywną dokumentację i konfigurację — scenariusze użycia

## Interfejs

Operacje istniejących ace-task i ace-assign działają lokalnie na ich plikach; nowe zachowanie nie wymaga starego authority.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Ujednolicić aktywne README, instrukcje, presety i konfigurację wokół przyjętych właścicieli stanu. Stare taski i raporty pozostają historycznym kontekstem.

Oczekiwany wynik: Świeża sesja czytająca aktywne instrukcje potrafi przejść plikowy przepływ bez dokumentacji starego laba.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Żadna aktywna instrukcja nowego przepływu nie odsyła do anulowanego taska jako obowiązującego właściciela ani nie wymaga starego journala.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
