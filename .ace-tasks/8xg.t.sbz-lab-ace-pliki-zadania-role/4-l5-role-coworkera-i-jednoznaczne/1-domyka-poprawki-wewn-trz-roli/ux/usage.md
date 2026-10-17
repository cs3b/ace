# Domykać poprawki wewnątrz roli reviewer — scenariusze użycia

## Interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Niezależny od workera reviewer wykonuje review, sam poprawia potwierdzone błędy, sprawdza diff poprawek i wraca do pełnego review. Może rozwijać swój assignment.

Oczekiwany wynik: Wykryty błąd jest naprawiony i ponownie sprawdzony w ramach jednego zlecenia reviewer, bez przełączania każdej poprawki przez overseera.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak skutecznej naprawy lub potrzebna decyzja produktowa jest eskalowana; nie wolno oznaczyć nierozwiązanego High/Critical jako sukcesu.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
