# Przeprowadzać instalację nowego laba — scenariusze użycia

## Interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: ace-lab install prowadzi nową instalację przez konta, katalogi, konfigurację, adaptery HITL, klucze i weryfikację; korzysta z paczek ACE.

Oczekiwany wynik: Na świeżym środowisku kończy instalację gotową do project add i uruchomienia coworkera.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Gotowy lub obcy lab powoduje odmowę nadpisania; brak wymaganych uprawnień/narzędzi jest konkretnie zgłoszony, bez pozornego sukcesu.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
