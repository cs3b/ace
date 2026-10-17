# Sprawdzić awarie wznowienia i eskalacje — scenariusze użycia

## Interfejs

Istniejące testy i scenariusze ACE; lokalne gemy, świeże środowisko, zapis wyników przy zadaniu. Bez nowego frameworka odbioru.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Wykonać scenariusze przerwania coworkera, restartu overseera, niedostarczenia i powtórzenia raportu, pytania HITL oraz limitu review.

Oczekiwany wynik: Po wznowieniu zachowany jest postęp i właściwy adres Reply; eskalacja po dziesiątej nieudanej pełnej rundzie dociera do overseera.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Utrata odpowiedzi na merge lub publikację nie powoduje ślepego powtórzenia efektu; brak adaptera daje niedostarczenie, a nie sukces.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
