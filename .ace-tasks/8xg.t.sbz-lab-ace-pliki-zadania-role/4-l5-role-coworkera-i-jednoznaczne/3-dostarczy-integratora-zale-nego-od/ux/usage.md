# Dostarczyć integratora zależnego od wyników pracy — scenariusze użycia

## Interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Integrator wykonuje przewidzianą przez projekt integrację, sprawdzając zależności, aktualne zmiany, wykonane testy i wynik niezależnego review przed merge.

Oczekiwany wynik: Gotowy i sprawdzony kandydat zostaje zintegrowany, a raport wskazuje rzeczywisty wynik potrzebny do odblokowania zależnej pracy.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Nieaktualne review po zmianie kandydata lub niespełniona zależność wstrzymują merge; niepewny wynik operacji jest sprawdzany zamiast ponawiany w ciemno.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
