# Uruchamiać obserwatory zmian przez watch — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Lokalny watch

Wejście / wywołanie: Zarejestrować /watch na źródle projektu i zmienić obserwowany plik.

Oczekiwany wynik: Odbiorca dostaje jedno skuteczne powiadomienie o zmianie.

## Scenariusz 2: Virtiofs

Wejście / wywołanie: Powtórzyć scenariusz zmiany na udziale virtiofs.

Oczekiwany wynik: Działa wykrycie przez obsługiwany mechanizm, bez agentowego sleep-poll.

## Scenariusz 3: Błąd źródła

Wejście / wywołanie: Zarejestrować watch dla niedostępnego źródła.

Oczekiwany wynik: Widoczny błąd zamiast samego wpisu sugerującego działającą obserwację.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/2-uruchamia-obserwatory-zmian-przez-watch/8xs.t.pu0.2-uruchamia-obserwatory-zmian-przez-watch.s.md.

## Uściślenia review

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
