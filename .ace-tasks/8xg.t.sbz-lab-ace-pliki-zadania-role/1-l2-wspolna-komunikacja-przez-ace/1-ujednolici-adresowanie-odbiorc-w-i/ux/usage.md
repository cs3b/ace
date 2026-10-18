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

## Doprecyzowanie odbioru po review 2026-10-18

Odbiorca jest jawnym adresem z konfiguracji: maszyna + folder zdarzeń + ID sprawy albo maszyna + panel. Adres odpowiedzi wskazuje pierwotnego nadawcę i sprawę; task/assignment/krok to kontekst, nie zamiennik ID wiadomości. Lokalne Reply wykorzystuje istniejące `update <ref> --answer`; transport przekazuje ten sam kontekst bez wyszukiwania „ostatniego pytania”.
Sprawdzić dwa worktree, powtórzone lokalne skróty ID oraz brakujący/niedostępny cel. Nie zgadywać odbiorcy ani nie pisać do innego folderu. Konfigurację adresu czyta HITL; konsument podaje skonfigurowany cel bez własnej implementacji routingu.
