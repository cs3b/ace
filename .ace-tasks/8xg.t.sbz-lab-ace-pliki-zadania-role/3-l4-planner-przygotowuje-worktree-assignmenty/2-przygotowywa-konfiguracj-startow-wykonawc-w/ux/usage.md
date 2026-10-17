# Przygotowywać konfigurację startową wykonawców — scenariusze użycia

## Interfejs

Wejście: task i sekwencja ról. Wynik: worktree, assignmenty oraz .ace-local/coworker/ i raport gotowości.

Scenariusze opisują kontrakt zachowania; nie deklarują, że nowe komendy lub funkcje już istnieją.

## Przebieg poprawny

Wywołanie / wejście: Przygotować w .ace-local/coworker/ kontekst uruchomienia każdej zaplanowanej roli: instrukcje, prompt, odwołanie do assignmentu, adres i reguły raportowania.

Oczekiwany wynik: Kolejna rola startuje z własnym kontekstem w worktree zadania; dane assignmentu są referencją do ace-assign.

## Błąd lub przerwanie

Wywołanie / sytuacja: użyć tego samego interfejsu w warunkach braku wymaganej gotowości, błędu lub przerwania wskazanych poniżej.

Oczekiwany wynik: Przygotowanie kolejnej roli nie nadpisuje bieżącego stanu aktywnego drivera ani nie przenosi sekretów do taska.

## Reguły wspólne

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.
