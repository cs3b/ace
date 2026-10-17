# Dostarczyć role worker i spec — scenariusze użycia

## Interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Dostarczyć role worker i spec jako konfigurację oraz instrukcje ace-coworker. Worker implementuje i sprawdza; spec tworzy lub doprecyzowuje wymagania.

Oczekiwany wynik: Każda rola otrzymuje własny assignment i oddaje właściwy rezultat: zmianę ze sprawdzeniami albo kompletną specyfikację.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Nieudane wymagane testy blokują sukces workera; nierozstrzygnięty istotny brak wymagań jest zgłaszany przez spec.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
