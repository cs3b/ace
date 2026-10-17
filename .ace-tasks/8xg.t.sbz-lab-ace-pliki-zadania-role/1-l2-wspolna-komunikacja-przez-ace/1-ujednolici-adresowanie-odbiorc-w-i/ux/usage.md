# Ujednolicić adresowanie odbiorców i Reply — scenariusze użycia

## Interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Zachować adres odbiorcy: maszyna, folder i ID albo maszyna i panel. Odpowiedź wiąże się z pierwotną sprawą i właściwym agentem.

Oczekiwany wynik: Dwa worktree z różnymi pytaniami otrzymują swoje Reply; raport można powiązać z właściwym taskiem i assignmentem.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Nieznany odbiorca lub niepasujące ID daje jawny błąd i nie zapisuje odpowiedzi w cudzym zadaniu.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
