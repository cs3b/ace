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
