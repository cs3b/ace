# Mapa wszystkich 30 problemów sesji

Numery odpowiadają liście użytkownika. Status jest relacją sesji, nie nowym audytem.

| # | Problem | Stan wejściowy | Pokrycie w krokach 01–16 |
|---|---|---|---|
| 1 | NameError HITL | Raportowane fixed 0.9.4+ | 06–07, 15–16: regresja |
| 2 | Blokujące tury i sleep-poll | Raportowane ask/PR74 | 04, 06, 16: brak bezproduktywnych tur |
| 3 | Virtiofs bez zdarzeń | Raportowany poll-fallback 0.7.2 | 03: regresja na virtiofs |
| 4 | /watch rejestruje bez startu | Otwarte | 03 |
| 5 | Dwie konfiguracje trasy | Kod raportowany 0.9.5; pozostałości | 06, 14 |
| 6 | Hard guards odrzucające nadawców | Raportowane soft guards 0.9.5 | 06, 08: poprawny dostęp |
| 7 | Ownership i event root | Raportowana poprawa | 06–07: właściwy właściciel i ścieżka |
| 8 | OTP relay/okna/pilność | Pętla raportowana jako udowodniona | 10: użyć i sprawdzić |
| 9 | Odpowiedź zatrzymana w transporcie | Otwarte | 06 |
| 10 | Author różny od approvera | Rozwiązane operacyjnie | 08–09: utrwalić wzorzec |
| 11 | Zły collaborator lab-overseer-ace | Właściwe konto ma write; zbędne pozostaje | 14 |
| 12 | Nieaktualny manifest | Otwarte | 01 |
| 13 | Ręczny deploy rozszerzeń | Otwarte | 01 |
| 14 | Overseer wykonuje zamiast delegować | Otwarte | 02, 08–10, 15 |
| 15 | Start bez instrukcji | Otwarte | 02, 11 |
| 16 | Brak stałych oczu | Otwarte | 03–05 |
| 17 | Bootstrap task-store | Raportowany jako done | 02, 11, 15: regresja |
| 18 | Rekordy bez commitów | Ręczny closeout raportowany done | 10: automatyczne przyszłe cykle |
| 19 | Zamknięcie tab zamiast pane | Follow-up poza rodziną | 14: zachować bezpieczną obsługę |
| 20 | Błędy quoting promptów | Reguła procesu | Wszystkie: pliki/argv |
| 21 | Fabrykowanie końcówek SHA | Reguła procesu | Wszystkie: identyfikatory z dowodów |
| 22 | Second Captain | Doprecyzowany jako agent doradczy | 12–13 |
| 23 | Zero-idle token burns | Otwarte do odbioru | 04–05, 16 |
| 24 | Klucz publishera w transkrypcie | Decyzja użytkownika: bez rotacji | 08, 10: env/wrapper; nie powtarzać ekspozycji |
| 25 | Brak json w runtime | Naprawione ręcznie | 01: zależności przechodnie |
| 26 | Sieroty HITL i stare replies | Otwarte | 07 |
| 27 | Martwy watch ask-8xskgh | Higiena | 03, 07 |
| 28 | Interim overseer-start | Zapisany w Git; zastępstwo otwarte | 02, 11, 14 |
| 29 | Niezapisany .gitignore canonical | Zastąpione raportem closeoutu | 14: sprawdzić stan, nie powtarzać closeoutu |
| 30 | Ręczny OPERATION-GUIDE.md | Tymczasowy | 02, 14 |

Dodatkowe ustalenia rozmowy: start z katalogu laba/projektu → kroki 02 i 11;
Second Captain proponuje w tym samym HITL i uczy się na decyzjach → 12–13;
jeden parent, 16 dzieci, liniowo, bez wnuków → cała rodzina.
Zamknięcie gad.2/sbz.9 wymaga dowodów z 15–16, nie tylko statusu podtasków.
