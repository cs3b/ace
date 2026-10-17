# Dodawać projekt gotowy do pracy zespołu — scenariusze użycia

## Interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: ace-lab project add przygotowuje repozytorium, konfigurację projektu, prywatne _overseer, presety ról, komunikację i dane potrzebne plannerowi.

Oczekiwany wynik: Dodany projekt jest widoczny w statusie, a planner może przygotować jego pierwszy task bez ręcznego naprawiania katalogów.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Ponowne dodanie nie niszczy konfiguracji ani zmian istniejącego projektu; konflikt lokalizacji jest zgłaszany przed nadpisaniem.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
