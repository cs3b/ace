---
id: 8xg.t.sbz.1.2
status: in-progress
priority: medium
created_at: "2026-10-17 18:54:11"
estimate: medium
dependencies: [8xg.t.sbz.1.1]
tags: [lab, lab-l2, file-based]
parent: 8xg.t.sbz.1
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-hitl/README.md, ace-hitl/docs/usage.md, ace-hitl-hermes/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/2-zachowa-wsp-lny-interfejs-i/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
title: Zachować wspólny interfejs i konfigurowalne adaptery
---

# Zachować wspólny interfejs i konfigurowalne adaptery

## Cel

Nadawca komunikuje się z człowiekiem i agentem przez ten sam interfejs. Ten subtask dostarcza następujący wycinek: Wspólny interfejs nadawcy nie zależy od adaptera. Zachować ace-hitl-hermes jako adapter, istniejące drogi tmux/Herdr i konfigurację jednego lub kilku adapterów.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Wspólny interfejs nadawcy nie zależy od adaptera. Zachować ace-hitl-hermes jako adapter, istniejące drogi tmux/Herdr i konfigurację jednego lub kilku adapterów.

## Kryteria odbioru

- [x] Przełączenie konfiguracji transportu nie wymaga zmiany assignmentu lub logiki coworkera; skonfigurowany zestaw tras raportuje własne wyniki dostarczenia.
- [x] Niedostępny adapter nie powoduje cichego wysłania do innego odbiorcy; dodanie przyszłego adaptera Nervus nie wymaga nowego interfejsu HITL.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Przełączenie konfiguracji transportu nie wymaga zmiany assignmentu lub logiki coworkera; skonfigurowany zestaw tras raportuje własne wyniki dostarczenia.
- Scenariusz błędu / niepoprawnego wejścia: Niedostępny adapter nie powoduje cichego wysłania do innego odbiorcy; dodanie przyszłego adaptera Nervus nie wymaga nowego interfejsu HITL.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L2.2 / 8xg.t.sbz.1.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/1-ujednolici-adresowanie-odbiorc-w-i/8xg.t.sbz.1.1-ujednolici-adresowanie-odbiorc-w-i-reply.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Konsumenci: ace-coworker, ace-overseer, ace-hitl-hermes i istniejące transporty terminalowe. Hermes oraz tmux/Herdr korzystają z tego samego raportu/pytania/Reply; adapter tłumaczy transport, nie reguły roli. Zachować obecne mechanizmy lifecycle/relay i konfigurację transportów, bez przywracania authority/proposals.
Dla wielu skonfigurowanych tras pokazać wynik każdej. Sukces jednej trasy nie ukrywa błędu drugiej; brak skonfigurowanej trasy daje konkretny błąd. Testy adapterów używają kontrolowanych odbiorców; samo wywołanie mocka nie zastępuje scenariusza przesłania i Reply. Nervus poza zakresem.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-hitl-hermes/README.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.

## Korekta z rzeczywistego wdrożenia — 2026-10-20

Opublikowany nadawca wysyła adresowane zdarzenie wszystkimi trasami. Terminal
interpretuje nazwę kanału Kapitana jako pane, a poprawne dostarczenie inną trasą
kończy się błędem całości. Obecny plugin Hermesa wywołuje Ruby CLI, którego nie ma
w rzeczywistym kontenerze Hermesa; `serve` wymaga starego endpointu lifecycle.
Te braki należą do tego istniejącego zadania, z korelacją z .1.1 i retencją .1.3.

Aktualny kontrakt: trasa deklaruje nazwy odbiorców, rozwiązywane do dokładnego
adresu zapisanego na zdarzeniu. Wysyłane są tylko pasujące trasy; zero dopasowań
to błąd bez skutku. Kilka jawnie pasujących tras oznacza żądane dostarczenie
każdą z nich, z niezależnym wynikiem. Błędna trasa nie powoduje zmiany odbiorcy.

Istniejący gateway Hermesa pozostaje jedynym pollerem Telegrama. Plugin
dostarczany w gemie obsługuje pliki natywnych zdarzeń bez Ruby i bez endpointu
lifecycle; nie tworzy nowego procesu usługi. Konfiguracja ogranicza kanały,
nadawców i projekty. Transport wiąże odpowiedź z dokładnym pierwotnym projektem,
worktree i sprawą. Tylko `ace-hitl` aktualizuje swoją sprawę; jednorazowe
uzgodnienie transportu wykonuje istniejący nadzorca podczas przebudzenia.
Zwykła wiadomość w grupie jest nową instrukcją dla skonfigurowanego koordynatora,
nie odpowiedzią na przypadkowe oczekujące pytanie.

Plan poprawki: selekcja tras i test bez efektów ubocznych; natywny kontrakt
plikowy i import odpowiedzi przez właściciela; plugin gatewaya i test bez Ruby;
testy duplikatów, restartu, dwóch worktree i błędnej korelacji; dokumentacja
konfiguracji, testy pakietów oraz niezależny review. Wdrożenie, rzeczywisty
Telegram i odbiór instalacji pozostają osobnymi niewykonanymi bramkami.

Pierwszy wycinek poprawia również błąd wykryty przy rzeczywistym `prepare`:
walidator panelu odrzucał natywny uchwyt Herdr `w7:p1`. Panel zachowuje teraz
ten dokładny identyfikator; reguły machine/folder i odrzucenie ścieżek pozostają.
Testy nadawcy: 40 testów, 209 asercji, bez błędów. Próba całego `hitl all`:
332 testy, 1724 asercje, 1 failure, 0 errors, 5 skipped. Jedyny failure jest
w niezmienionym teście TLS `test_service_admits_exactly_the_pinned_client_identity`:
spodziewany komunikat o fingerprint, otrzymane `ECONNRESET`. To nie jest PASS
całego pakietu ani dowód wdrożenia. Raport próby:
`ace-hitl/.ace-local/test/reports/hitl/a0e2359d-eeab-4767-a3b2-e7eb7a2141be/`.

Przy implementacji natywnego transportu sprawdzono rzeczywisty interfejs Hermesa:
rejestracja pluginów poprzedza połączenie adapterów. Brak aktywnego adaptera
przed wywołaniem send musi pozostać `waiting_gateway`; nie wolno zaklasyfikować
go jako niepewnej wysyłki ani oznaczyć jako dostarczone. Dopiero wywołanie send
przekracza granicę skutku: jego przerwanie daje `unknown`, bez automatycznej
powtórki. Własny test importerów wykrył też pustą sekcję Answer w nowym zdarzeniu;
idempotentny import sprawdza zawartość pod blokadą pliku, a nie sam nagłówek.

Pierwszy wycinek `565fb925539bcb7a322b9f0782e74a11a8fb8278` przeszedł
niezależny review: APPROVE. Reviewer odtworzył również powyższy błąd TLS na
niezmienionej bazie; pełny HITL nadal nie jest oznaczony jako zielony.

Drugi wycinek dodaje jawny adapter `hermes_native`, pakietowy plugin Pythona
oraz jednorazowe `ace-hitl-hermes sync`. Przetestowano rzeczywiste prywatne pliki
Ruby → plugin Python bez Ruby w PATH → Ruby, dwa worktree z takim samym ID,
dokładne Reply także do części dzielonej wiadomości, duplikaty/restart, odmowę
innego nadawcy/projektu, symlinki, brak połączonego gatewaya i utraconą odpowiedź
send bez powtórki. Zwykła instrukcja trafia tylko do koordynatora. Zapis pliku
nie jest `delivered`; status kanonicznej trasy zmienia dopiero wynik adaptera
z konkretnymi identyfikatorami wiadomości. Żądania z `lab_request_id` nie mogą
przejść do tego transportu ani importera — pozostają w uwierzytelnionym lifecycle.

Wykonane testy źródła i artefaktu:

```text
bin/ace-test hitl-hermes all
209 tests, 1205 assertions, 0 failures, 0 errors
report: ace-hitl-hermes/.ace-local/test/reports/hitl-hermes/9fbfd0bf-355a-4236-9000-fc2bc77297a2/

Po końcowym doprecyzowaniu odmowy managed lifecycle:
bin/ace-test hitl-hermes test/fast/organisms/native_sync_test.rb test/fast/commands/native_plugin_test.rb
11 tests, 67 assertions, 0 failures, 0 errors
report: ace-hitl-hermes/.ace-local/test/reports/hitl-hermes/8bae13fb-a53c-46a9-aaf6-3328ea520f74/
```

Test komend buduje rzeczywisty gem, wyciąga go, porównuje zapakowany
`plugin/native_transport.py` oraz sprawdza podłogę zależności HITL.
Publiczne API RubyGems zwróciło 2026-10-20 odpowiednio 0.23.1 i 0.9.0;
przygotowane wersje to ace-hitl 0.23.2 i ace-hitl-hermes 0.9.1, z wymaganiem
HITL >= 0.23.2. `bundle check`, kontrola whitespace i gitleaks przeszły.
Doctor: 860 zadań, 509 ostrzeżeń, 0/100; nie jest to czysta globalna baza.

Konfiguracja, migracja selektorów `recipients`, instalacja pluginu, cutover
jednego właściciela grupy i granice retencji są opisane w
`ace-hitl-hermes/docs/native-folder.md`. Drugi wycinek czeka na niezależny review.
Brak publikacji, instalacji, aktywacji lub wysłania wiadomości Telegram w ramach
tego wycinka. Rzeczywisty odbiór z wydanych gemów i istniejącego współdzielonego
folderu pozostaje otwarty; zadanie nadal in-progress.

Review R1 dla `af7038c81d9252a5f893e922b8118c6914c8559f`: REJECT. Reviewer
wykazał rzeczywistą kolejność startu Hermesa: background plugin discovery przed
pętlą gatewaya, a późniejsze discover jest idempotentne. Samo `spawn_task`
warunkowe przy register nie uruchamiało transportu po takim pre-discovery.
Poprawka ma użyć istniejącego `register_platform_handler` wywoływanego w
`TelegramAdapter.connect`, bez nowego pollera lub wątku usługi.

Dodatkowy audit wdrożenia wykazał brak cutover: zainstalowany plugin lab-hitl
3.1.0 obsługuje też grupy hosta i wcześniejsze Reply. Zastąpienie całego pluginu
native-only je odcina, a dwa aktywne hooki mogą wykonać dwa skutki, bo Hermes
wywołuje wszystkie callbacki przed oceną skip. Usunięcie grupy Lab z konfiguracji
starego pluginu odcina również autoryzację dawnych odpowiedzi z tej grupy.
Autoryzowana korekta: jeden hook w pakiecie, z opcjonalnym adapterem przejściowym
istniejącego protokołu brokera. Dokładne legacy Reply zachowuje starego właściciela;
nowy ruch natywny i grupy hosta mają rozłączne decyzje routingu. Brak importu
zewnętrznego kodu Pythona, nowego procesu/usługi i zmian live.

Korekta R2 wykonana host-side: factory Telegram connect startuje jeden
supervised task po synchronicznym pre-discovery, również przy samym outbound.
Test obejmuje ponowne wywołanie factory bez duplikatu i anulowanie przy unload.
Jeden pakietowy hook obsługuje opcjonalny `legacy_broker`: stare dokładne Reply
w grupie Lab i grupach hosta zostają w brokerze, nowy ruch Labu jest natywny,
pozostałe grupy hosta używają dotychczasowych kanałów. Testy obejmują nieznane
Reply, odmowę nadawcy, przerwaną odpowiedź brokera bez ponowienia/fallbacku,
niedostępną projekcję oraz rzeczywisty tymczasowy Unix socket z kontrolą peer UID.
Stare projekcje nie są zapisywane, a pytania OTP nie są odtwarzane.

Read-only w rzeczywistym gatewayu: socket i obie projekcje są własnością UID1000
(odpowiednio 0600 i 0440); zapytanie SO_PEERCRED bez wysłania bajtów żądania
potwierdziło UID0/GID0 serwera. Konfiguracja przejściowa wiąże więc peer UID0,
nie UID właściciela pliku socketu. Nie wywołano operacji brokera.

```text
bin/ace-test hitl-hermes all
211 tests, 1219 assertions, 0 failures, 0 errors
report: ace-hitl-hermes/.ace-local/test/reports/hitl-hermes/e904c446-685d-4abe-a16b-e158d2bc0ea7/

Końcowe sprawdzenie wszystkich trzech zapakowanych modułów:
bin/ace-test hitl-hermes test/fast/commands/native_plugin_test.rb
3 tests, 32 assertions, 0 failures, 0 errors
report: ace-hitl-hermes/.ace-local/test/reports/hitl-hermes/f7ca912d-4dd7-4244-9917-c21f05403c9b/
```

W środku testów komend wykonano 9 przypadków natywnych i 9 startup/transition
w Pythonie bez Ruby/CLI w PATH oraz build/extract gema z porównaniem bajtów
wszystkich trzech modułów pluginu. R2 czeka na świeży niezależny verdict;
R1 pozostaje REJECT dla swojego SHA. Wersje 0.23.2/0.9.1 nieopublikowane.
Wdrożenie wymaga wyłączenia starego hooka przy aktywacji nowego pojedynczego
hooka, zachowując istniejący broker, wszystkie grupy i oczekujące pytania.
