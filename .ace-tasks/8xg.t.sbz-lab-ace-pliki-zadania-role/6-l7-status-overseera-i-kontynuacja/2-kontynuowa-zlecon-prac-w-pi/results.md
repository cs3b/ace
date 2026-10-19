# Wyniki — 8xg.t.sbz.6.2 „Kontynuować zleconą pracę w pi" (L7.3)

Data: 2026-10-19. Worktree: `t-sbz-wave-3`. Zakres właścicielski: `ace-handbook-integration-pi/**`, `ace-herdr/**`.

## Co zostało zrobione

### 1. Prompt wznowienia `/continue-work` (ace-handbook-integration-pi)

Nowy kanoniczny szablon `handbook/prompts/continue-work.md` (projekcja do `.pi/prompts/continue-work.md`). Działa na dwa wyzwalacze: wiadomość-raport obudziła sesję albo restart sesji. Cykl wznowienia:

1. **Czyta prawdę, nie pamięć**: `ace-task --in _overseer list`/`show` (zlecony proces), assignmenty `ace-assign` w `.ace-local/assign/`, prawda projektu: `ace-task list`, `ace-overseer status`, `ace-git-worktree list`, `git status --short`.
2. **Przetwarza raporty** przez istniejącą bramkę `ace-overseer process-reports` (dedup po stanie zdarzenia — powtórzenie dostarczenia ≠ powtórzenie pracy).
3. **Kontynuuje ten sam zlecony proces** przez `ace-overseer work-on` / `ace-overseer handoff`.

Reguły niezbywalne: jedna egzekucja overseera (wiadomość w trakcie tury to follow-up TEJ samej tury, nigdy druga egzekucja), brak samodzielnego szukania pracy (No self-seeking), nieczytelne źródło to błąd do zgłoszenia, nie „pusty i gotowy" stan, commity path-scoped.

Usunięty został stary `handbook/prompts/work-backlog.md`: jego cykl „wybierz pierwszy pending z backlogu" był samodzielnym szukaniem pracy — sprzeczny z kontraktem. Bez aliasu (ADR-024).

### 2. Transport raportu w pi (istniejące mechanizmy, bez drugiej kolejki)

- **Waking po pliku**: sesja overseera subskrybuje raz `/watch add reports --path .ace-local/hitl --message "new ace-hitl report; run /continue-work"` — nowy plik zdarzenia ace-hitl budzi oczekującą sesję; w trakcie aktywnej tury wake trafia do kolejki follow-up tej samej sesji (pi sama kweuje; nigdy druga egzekucja); powtórzenia koalesują per źródło; definicja przeżywa restart i rejestruje się dokładnie raz.
- **Push Herdr**: `ace-herdr deliver` promptuje raport do pane overseera — idempotentny per event id (powtórzone powiadomienie tego samego zdarzenia short-circuituje na rekordzie dostawy; równoległe dostawy jedno zdarzenie promptują raz), bootstrap agenta z bramką gotowości.
- **Kolejka provider-native**: `ACE_HERDR_PI_QUEUE_CLIENT` — istniejący adapter w `NativeQueueExecutor` (receipt związany z digestem); bez zmian kodu, udokumentowane.

### 3. Testy

- Nowy suity JS `ace-handbook-integration-pi/test/js/report-wake.test.mjs` (5 scenariuszy, przez fałszywy host pi na RZECZYWISTYM rozszerzeniu ace-wake):
  1. raport budzi oczekującą sesję dokładnie raz (bounded, source-prefixed);
  2. raport w trakcie aktywnej tury → jeden queued follow-up (nigdy druga egzekucja), powtórzenia koalesują do jednej wiadomości;
  3. restart → watch rejestruje się dokładnie raz, bez replayu starych raportów; kolejny raport budzi dalej ten sam proces;
  4. powtórzone identyczne powiadomienie (niezmieniony fingerprint) → brak nowego wake'a;
  5. świeży raport po settled → dokładnie jeden kolejny follow-up do tej samej sesji.
- Zaktualizowane testy fast (`pi_test.rb`): kompletność i projekcja szablonu `continue-work` (klauzule: _overseer, assignmenty, prawda projektu, process-reports/work-on/handoff, jedna egzekucja, delivery repetition, No self-seeking).
- Poziom feat (rzeczywiste Pi SDK) przeszedł bez zmian — potwierdza, że projekcja i rozszerzenie działają w prawdziwym runtime pi.

### 4. Dokumentacja / changelogi

- `ace-handbook-integration-pi`: README (use case L7.3), docs/usage.md (sekcja „Continuing commissioned work with /continue-work" + wiring report wake), CHANGELOG [Unreleased].
- `ace-herdr`: docs/usage.md (sekcja „Delivering reports to a pi overseer (L7.3)"), CHANGELOG [Unreleased]. Zmiana wyłącznie dokumentacyjna — kod Herdr (deliverer, NativeQueueExecutor) już spełniał wymagania; dodawanie kodu nie było potrzebne (najprostsza poprawna implementacja).

## Wykonane weryfikacje

- `bin/ace-test ace-handbook-integration-pi all` → 10 tests, 89 assertions, 0 failures (w tym suita node JS oraz feat w prawdziwym Pi SDK — runtime pi 0.87.1 dostępny w sandboxie).
- `bin/ace-test ace-herdr all` → 614 tests, 2527 assertions, 0 failures.
- Raporty: `.ace-local/test/reports/handbook-integration-pi/af3221b9-…/`, `.ace-local/test/reports/herdr/6a146af4-…/`.

## Mapowanie kryteriów odbioru

- **„Raport budzi oczekującego overseera; po restarcie kontynuuje ten sam proces i istniejące assignmenty."** — waking: test JS #1 (watch na `.ace-local/hitl`) oraz push Herdr (istniejące testy deliverera); restart + kontynuacja: test JS #3 (rejestracja dokładnie raz, ten sam proces budzi się dalej) + prompt `/continue-work` czytający _overseer/assignmenty/prawdę projektu (test fast kompletności). ✅ na poziomie mechanizmów; patrz „Scenariusze niewykonane".
- **„Powtórzone powiadomienia nie tworzą drugiej egzekucji; brak nowej zleconej pracy nie prowadzi do samodzielnego szukania kolejnych zadań."** — testy JS #2/#4/#5 (koalescing, follow-up zamiast drugiej egzekucji, idempotentność identycznego powiadomienia), idempotencja per event id w delivererze (testy istniejące), reguły „one overseer execution" / „No self-seeking" w prompcie (test fast). ✅
- **„Wynik zgodny z kontraktem i możliwy do użycia przez następną rolę/narzędzie."** — brak drugiej kolejki (transport = istniejący ace-wake watch / herdr deliver / pi queue client), właściciele stanu bez zmian, prompt używa wyłącznie publicznych bramek `ace-overseer`. ✅

## Scenariusze niewykonane (wymagają prawdziwego pi w laboratorium)

W sandboxie wykonano testy w prawdziwym Pi SDK (poziom feat), ale poniższych scenariuszy end-to-end NIE wykonano jako pełnego przepływu labowego (Lead decyduje o suficie dla bramki fali):

1. **Pełny obieg hitl→herdr→pi**: prawdziwy raport `ace-hitl send` → `ace-herdr deliver` do żywego pane z sesją pi overseera → sesja budzi się i wykonuje `/continue-work` na prawdziwych plikach `_overseer`/`.ace-local/assign/`.
2. **Restart prawdziwej sesji**: `pi --resume` z perspektywą `/continue-work` na trwałym katalogu sesji po faktycznym restarcie procesu (feat testuje reload w SDK, nie restart procesu z dysku).
3. **Kolejka provider-native z realnym `pi-overseer-queue-client`**: scenariusz idle-vs-followUp z realnym binarnym klientem wskazanym przez `ACE_HERDR_PI_QUEUE_CLIENT` (klient nie jest częścią tego repo; w sandboxie nie był dostępny).

Zgodnie ze specyfikacją: brak runtime to niewykonany scenariusz, nie powód do budowy zastępczego serwisu — nie budowano żadnego.

## Decyzje

- Usunięto `/work-backlog` (samodzielne szukanie pracy sprzeczne z kontraktem) zamiast zostawiać oba prompty — zasada najprostszej implementacji i ADR-024.
- Integracja zostaje po stronie istniejącego adaptera/rozszerzenia pi (ace-wake `/watch` na folderze ace-hitl) — zero nowego kodu transportowego w ACE, zgodnie z review gotowości.
- Herdr: tylko dokumentacja; kod (deliverer idempotentny per event id, NativeQueueExecutor) już realizuje wymagane semantyki.

## Uwagi dla Lead / następnej roli

- Zmiany w `ace-overseer/**` widoczne w worktree należą do równoległego taska 8xg.t.sbz.6.1 — nie były touche'owane przez ten task.
- `docs/lab-flow.md` (właściciel: task .6.1) powinien po integracji odnotować L7.3 jako shipped (tabela fal wiersz L7) — zalecenie, nie zmiana z tej strony.
- Realnie brakuje binarnego `pi-overseer-queue-client` w labie, jeśli Lead chce scenariusz 3; po stronie ACE niczego nie brakuje.

## Poprawki po review (runda 1)

Zastosowano 4 zweryfikowane ustalenia z `.ace-local/review/sessions/review-8xij7k/review-report-review-default.md`:

1. **H-1 (HIGH, 8xijeywf)** — `nodeWatchFactory` obsługuje teraz cele katalogowe jawnie: katalog (`np. .ace-local/hitl`) jest watcherowany bezpośrednio, a każdy event dziecka jest akceptowany (filtrowanie szumu zostało w fingerprint mtime/size). Poprzedni schemat (watch rodzica + filtr basename) nie mógł zadziałać na Linuksie (inotify dostarcza eventy utworzenia pliku wyłącznie do watcha na samym katalogu) i był zawodny na macOS (ścieżki zagnieżdżone odrzucane filtrem). Cele plikowe zachowują dotychczasowy watch rodzica odporny na atomowe podmiany. Dodano test na prawdziwym FS w `test/js/watch-subscription.test.mjs`: watch tymczasowego katalogu, utworzenie pliku w środku, dokładnie jedno przebudzenie. Zaktualizowano komentarz `triggerWatch`/`watchedDir` w fake host do nowego kształtu watchera. CHANGELOG [Unreleased] odnotowuje nowy kontrakt watcha katalogów.
2. **L-1 (Low, 8xijeywg)** — wspólny harness sesji wydzielony do `test/js/session-harness.mjs`; `report-wake.test.mjs` i `installed-wake-extension.test.mjs` korzystają z tej samej implementacji (z guardem `if (shutdown)` w reload) — harnessy nie mogą rozjechać się.
3. **L-2 (Low, 8xijeywh)** — usunięto martwe wywołanie `host.setAgentActive(true)` w `report-wake.test.mjs`; sterownikiem ścieżki active-turn pozostaje `setIdle(false)`.
4. **L-3 (Low, 8xijeywi)** — przy asercji `deliverAs: "followUp"` dodano jednolinijkowy komentarz: asercja przypina kontrakt dostarczania wyłącznie przez kolejkę; semantyka pojedynczej egzekucji żyje w hoście pi, którego fake nie może sfalsyfikować.

Weryfikacja: `bin/ace-test ace-handbook-integration-pi all` — 10 testów, 89 asercji, 0 failures (pełny suite JS, w tym nowy test katalogowy na prawdziwym FS, wykonuje się wewnątrz warstwy fast). Zakres zapisów: wyłącznie `ace-handbook-integration-pi/**` plus ten plik results.
