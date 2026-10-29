---
id: 8xs.t.pu0.2
status: pending
priority: medium
created_at: "2026-10-29 17:13:41"
estimate: medium
dependencies: [8xs.t.pu0.1]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-handbook-integration-pi/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/2-kontynuowa-zlecon-prac-w-pi/8xg.t.sbz.6.2-kontynuowa-zlecon-prac-w-pi.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/8xs.t.pu0.1-uruchamia-nadzorc-z-konfiguracji-projektu.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/2-uruchamia-obserwatory-zmian-przez-watch/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, ace-test-runner/docs/usage.md]
  commands: []
---

# Uruchamiać obserwatory zmian przez watch

## Cel

Zapewnić, że rejestracja watcha rzeczywiście rozpoczyna obserwację i kończy się wybudzeniem.

## Specyfikacja zachowania

Krok 03/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: medium.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Publiczny /watch w harnessie po poprawnej rejestracji uruchamia obserwator, także na lokalnym filesystemie.
- Zachowana jest obsługa virtiofs przez techniczny poll-fallback. Reakcja dotyczy właściwego odbiorcy, a identyczny stan nie generuje kolejnych tur.
- Zatrzymanie, błąd startu i ponowne uzbrojenie watcha mają widoczny wynik; martwy watch nie wygląda jak działający.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Lokalny watch | Zarejestrować /watch na źródle projektu i zmienić obserwowany plik | Odbiorca dostaje jedno skuteczne powiadomienie o zmianie. |
| Virtiofs | Powtórzyć scenariusz zmiany na udziale virtiofs | Działa wykrycie przez obsługiwany mechanizm, bez agentowego sleep-poll. |
| Błąd źródła | Zarejestrować watch dla niedostępnego źródła | Widoczny błąd zamiast samego wpisu sugerującego działającą obserwację. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Zmiana pliku powoduje faktyczne wybudzenie w lokalnym filesystemie i w virtiofs.
- [ ] Brak zmiany daje zero dodatkowych wywołań modelu podczas obserwowanego okresu.
- [ ] Błąd uruchomienia obserwatora jest widoczny; ponowne uzbrojenie nie dubluje powiadomień.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-handbook-integration-pi
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.1.
Następny krok: 8xs.t.pu0.3.
Starsze zakresy do wykorzystania: 8xg.t.sbz.6.2.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Nie zakładać, że w kodzie brakuje wywołania start: `WakeRegistry.addWatch` już je
wykonuje. Najpierw odtworzyć publiczny `/watch add probe --path PATH --message TEXT`
na wersji pakietu z kroku 01 i wskazać faktyczną przyczynę nieskutecznej obserwacji.
Wykorzystać jedną ścieżkę aktywacji z ask bridge. Krok obejmuje kontrakt, w którym `/eyes`
nie kasuje aktywnych watchy ani nie odrzuca `/watch add`; stała obserwacja i ask używają
tej samej infrastruktury dostawy. Wycofać konkurujące właścicielstwo obserwacji, bez shimów.

Brak wymaganego pliku to błąd, ale jeszcze nieutworzony inbox w poprawnym worktree jest
stabilnym stanem absent i jego utworzenie musi zostać wykryte. Wspierane: atomic replace,
rename/delete/create, identyczne bytes z nowym mtime, rejestracja podczas compaction/busy,
zmiana między baseline a uzbrojeniem i ponowne uzbrojenie po błędzie.
Virtiofs/FUSE korzysta z istniejącego poll fallback 2.5 s. Runtime error jest widoczny
w list/status; remove+add ma zapewnić jeden działający watcher. Brak zdarzenia przez <=2
interwały pollingu po potwierdzonej zmianie jest niepowodzeniem próby.

Konsumenci: ace-wake, pi integration oraz bridge ace-hitl ask. Test publicznej komendy
musi przejść przez rejestrację Pi, native watcher i konsumpcję wiadomości przez sesję;
samo wywołanie callbacka lub rejestracja definicji nie zamyka kryterium.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Publiczny /watch z /eyes włączonym i wyłączonym; lokalny FS oraz virtiofs; dokładnie jedna skonsumowana zmiana, także atomic replace. |
| 2 | Identyczny zapis i 30 min zdrowej ciszy: zero dodatkowych model calls; liczyć osobno techniczny polling. |
| 3 | Unreadable source, absent inbox, błąd runtime, remove+add, compaction i registration race; brak zgubienia lub duplikacji. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-handbook-integration-pi/docs/usage.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/2-kontynuowa-zlecon-prac-w-pi/8xg.t.sbz.6.2-kontynuowa-zlecon-prac-w-pi.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/8xs.t.pu0.1-uruchamia-nadzorc-z-konfiguracji-projektu.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/2-uruchamia-obserwatory-zmian-przez-watch/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
