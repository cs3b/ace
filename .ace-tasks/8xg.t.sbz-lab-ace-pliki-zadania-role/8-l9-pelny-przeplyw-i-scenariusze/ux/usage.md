# L9: Pełny przepływ i scenariusze awarii przed publikacją — scenariusze użycia

## Interfejs

Istniejące testy i scenariusze ACE; lokalne gemy, świeże środowisko, zapis wyników przy zadaniu. Bez nowego frameworka odbioru.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Na lokalnie zbudowanych gemach w świeżym środowisku wykonać planner → worker → reviewer z poprawkami → integrator → odblokowanie następnego taska.

Oczekiwany wynik: Wynik dokumentuje faktyczne przejścia ról, taski, worktree, review i integrację wraz z wersjami testowanych paczek.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Niespełniona zależność lub nieukończony assignment nie przechodzą do następnego kroku i nie są oznaczane jako sukces całego testu.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
