# Przypisać stan do właścicieli i lokalizacji — scenariusze użycia

## Interfejs

Operacje istniejących ace-task i ace-assign działają lokalnie na ich plikach; nowe zachowanie nie wymaga starego authority.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Zadania projektowe, prywatne _overseer, assignmenty, konfiguracja coworkera i pliki HITL mają jawnego właściciela; każda informacja ma jedno miejsce zapisu.

Oczekiwany wynik: W przykładzie task → assignment → raport można wskazać plik i właściciela każdej zmiany; _overseer nie jest śledzony przez Git.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Coworker nie zapisuje do _overseer ani nie utrzymuje kopii kolejki; brak konfiguracji właściciela jest pokazany jako brak gotowości.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
