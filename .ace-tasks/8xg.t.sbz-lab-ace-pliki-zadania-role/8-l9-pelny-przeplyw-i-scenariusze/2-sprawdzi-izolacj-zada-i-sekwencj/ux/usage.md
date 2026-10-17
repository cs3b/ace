# Sprawdzić izolację zadań i sekwencję ról — scenariusze użycia

## Interfejs

Istniejące testy i scenariusze ACE; lokalne gemy, świeże środowisko, zapis wyników przy zadaniu. Bez nowego frameworka odbioru.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Uruchomić dwa zadania z odrębnymi worktree i wynikami; dla jednego zadania obserwować sekwencyjną zmianę ról.

Oczekiwany wynik: Zmiany, assignmenty i raporty pozostają przypisane do właściwego taska; jedna rola oddaje worktree przed startem następnej.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Próba drugiego przydziału do zajętego worktree zostaje powstrzymana; wiadomość drugiego zadania nie zamyka pierwszego.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
