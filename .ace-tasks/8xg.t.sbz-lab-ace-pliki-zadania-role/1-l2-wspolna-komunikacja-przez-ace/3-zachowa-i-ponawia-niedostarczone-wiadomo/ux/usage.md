# Zachować i ponawiać niedostarczone wiadomości — scenariusze użycia

## Interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Niedostarczona wiadomość oraz powód błędu pozostają w lokalnych plikach HITL. Ponawia się dostarczenie tej samej sprawy, a nie jej zadanie.

Oczekiwany wynik: Po przywróceniu transportu zachowany raport trafia do overseera z tym samym powiązaniem do taska.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Utrata potwierdzenia dostarczenia i ponowienie nie wykonują ponownie assignmentu ani nie odblokowują następnego kroku dwa razy.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Ponowienie zachowuje ID i treść lokalnego zdarzenia; użytkownik/agent ponawia dostarczenie, nie assignment. Przy częściowym sukcesie ponawiane są trasy niedostarczone lub o nieznanym wyniku. Przy nieznanym wyniku możliwy jest duplikat, więc odbiorca rozpoznaje ID; nie obiecujemy exactly-once transportu.
Test: odbiorca przyjął raport, potwierdzenie zaginęło, ponowienie niesie to samo ID. W tym liściu odbiorca testowy potwierdza identyfikowalność duplikatu; faktyczne nieuruchomienie kolejnego kroku drugi raz odbieramy w .5.4. Brak zależności implementacyjnej od przyszłego overseera.
