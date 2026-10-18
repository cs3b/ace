# Zachować wspólny interfejs i konfigurowalne adaptery — scenariusze użycia

## Interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Wspólny interfejs nadawcy nie zależy od adaptera. Zachować ace-hitl-hermes jako adapter, istniejące drogi tmux/Herdr i konfigurację jednego lub kilku adapterów.

Oczekiwany wynik: Przełączenie konfiguracji transportu nie wymaga zmiany assignmentu lub logiki coworkera; skonfigurowany zestaw tras raportuje własne wyniki dostarczenia.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Niedostępny adapter nie powoduje cichego wysłania do innego odbiorcy; dodanie przyszłego adaptera Nervus nie wymaga nowego interfejsu HITL.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Doprecyzowanie odbioru po review 2026-10-18

Konsumenci: ace-coworker, ace-overseer, ace-hitl-hermes i istniejące transporty terminalowe. Hermes oraz tmux/Herdr korzystają z tego samego raportu/pytania/Reply; adapter tłumaczy transport, nie reguły roli. Zachować obecne mechanizmy lifecycle/relay i konfigurację transportów, bez przywracania authority/proposals.
Dla wielu skonfigurowanych tras pokazać wynik każdej. Sukces jednej trasy nie ukrywa błędu drugiej; brak skonfigurowanej trasy daje konkretny błąd. Testy adapterów używają kontrolowanych odbiorców; samo wywołanie mocka nie zastępuje scenariusza przesłania i Reply. Nervus poza zakresem.
