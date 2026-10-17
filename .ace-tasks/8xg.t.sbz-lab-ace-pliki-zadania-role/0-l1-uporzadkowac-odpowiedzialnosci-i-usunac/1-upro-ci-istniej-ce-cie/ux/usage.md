# Uprościć istniejące ścieżki wykonania laba — scenariusze użycia

## Interfejs

Operacje istniejących ace-task i ace-assign działają lokalnie na ich plikach; nowe zachowanie nie wymaga starego authority.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Zastąpić stare labowe authority/listenery/journale bezpośrednią pracą na istniejących plikach narzędzi. Usunąć wymagania protected execution w zastępowanym przepływie, zachowując potrzebne operacje.

Oczekiwany wynik: Task i assignment można utworzyć, odczytać i prowadzić bez uruchamiania starej usługi admission i właściciela journala.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak starego listenera nie blokuje zwykłej pracy; rzeczywisty brak uprawnień do własnych plików jest zgłaszany. Nie usuwać transportu tmux/Herdr lub HITL tylko dlatego, że korzysta z socketu.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
