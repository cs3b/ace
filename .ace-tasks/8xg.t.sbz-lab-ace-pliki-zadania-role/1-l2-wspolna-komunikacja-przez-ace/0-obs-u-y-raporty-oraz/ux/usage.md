# Obsłużyć raporty oraz prośby o odpowiedź — scenariusze użycia

## Interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Ten sam interfejs ace-hitl obsługuje raport zakończenia/błędu oraz pytanie lub eskalację. Tylko prośba wymagająca decyzji oczekuje na odpowiedź.

Oczekiwany wynik: Raport work done trafia do overseera bez oczekiwania na Reply; pytanie pozostaje oczekujące i może wstrzymać assignment.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak odpowiedzi na pytanie nie jest zgodą ani sukcesem; raport bez odpowiedzi nie staje się zablokowanym pytaniem.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Rozszerzyć istniejący plikowy interfejs `ace-hitl create/show/update/wait`, zamiast odtwarzać usunięte `overseer-send`. Rozróżnienie raportu od pytania należy do zdarzenia HITL, nie do roli odbiorcy. Raport zawiera wynik (sukces/błąd), treść i referencje task/assignment/krok, ma własne ID i nie oczekuje odpowiedzi. Pytanie zachowuje istniejący cykl odpowiedzi. Zapis lokalny nie oznacza dostarczenia.
Pierwszy wycinek odbieramy lokalnie: utworzenie raportu, odczyt i brak oczekiwania na odpowiedź; pytanie pozostaje oczekujące. Zdalne adresowanie i adaptery są kolejnymi liśćmi .1.1–.1.3, nie warunkiem rozpoczęcia .1.0. Publiczną składnię rozszerzenia utrwalić w help/usage przed integracją konsumentów.
