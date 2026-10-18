# L3: Ace-coworker wykonuje assignment do końca lub zgłasza błąd — scenariusze użycia

## Interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Start coworkera czyta .ace-local/coworker/: rolę, źródło instrukcji, prompt startowy, task, istniejący assignment, adres overseera oraz zasady błędów.

Oczekiwany wynik: Wykonawca startuje w przygotowanym worktree z właściwą rolą i dokładnie wskazanym assignmentem.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Brak instrukcji roli, taska albo assignmentu daje konkretny błąd; coworker nie zgaduje innego zlecenia.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Wszystkie dzieci objęto review osobno. Pending oznacza gotową specyfikację, nie ukończoną funkcję ani zniesienie dependencies. Zlecenie tej grupy rozpoczyna się od dostępnych liści według execution-order.md; późniejsza blokada nie zatrzymuje wcześniejszego zakresu. Jeden główny zakres ma jedno worktree, role i subtaski pracują kolejno, a potrzebne poprzednikom fragmenty można integrować osobnymi PR-ami.
