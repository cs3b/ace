# L8: Instalacja nowego laba i dodawanie projektu — scenariusze użycia

## Interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Przygotować konta, katalogi, uprawnienia, klucze i dostępne role zgodnie z konfiguracją laba. Dostęp wynika z kont i plików, bez odtworzenia brokera usług z iy6.

Oczekiwany wynik: Docelowy wykonawca ma dostęp do potrzebnych plików i własnych kluczy; konfiguracja wskazuje poprawny kontekst pracy.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak uprawnienia jest zgłaszany; sekret nie trafia do Git, specyfikacji taska, argumentów diagnostycznych ani raportów.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
