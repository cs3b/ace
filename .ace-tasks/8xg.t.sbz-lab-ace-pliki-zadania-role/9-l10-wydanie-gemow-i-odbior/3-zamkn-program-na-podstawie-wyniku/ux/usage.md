# Zamknąć program na podstawie wyniku odbioru — scenariusze użycia

## Interfejs

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Zamknąć program dopiero po udokumentowanym odbiorze nowego laba z RubyGems; zapisać wersje, rezultat oraz rzeczywiste ograniczenia.

Oczekiwany wynik: Końcowy zapis łączy wykonane kryteria L1–L10 z wynikami i wskazuje zaakceptowany zestaw paczek.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak któregokolwiek wymaganego odbioru pozostawia program otwarty; liczba commitów, review albo sam status done workera nie zastępują celu.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
