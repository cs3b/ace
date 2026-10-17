# Ujednolicić workflow review i obsługę forge — scenariusze użycia

## Interfejs

Role i presety ace-coworker; workflow as-pr-review zachowuje neutralne referencje forge i uzgodnioną regułę 3/2/10.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Ujednolicić as-pr-review, workflow i presety z regułami ról. Zachować neutralną obsługę GitHub/Forgejo i przyjąć istniejącą poprawkę qkc.0 zamiast implementować ją ponownie.

Oczekiwany wynik: Typed pr:REFERENCE przyjmuje numery, owner/repository i poprawne URL GitHub /pull/ oraz Forgejo /pulls/, zachowując właściwy target; przypadek qkc.0 przechodzi finalny review/integrację.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Zero i błędne referencje są odrzucane przed ekstrakcją bundle; parsowanie nie odpytuje sieci ani nie zgaduje github.com. Stare protected receipt gates nie wracają przez presety.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
