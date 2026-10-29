# Obserwować zmiany PR oraz repozytorium — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Nowy HEAD

Wejście / wywołanie: Zmienić HEAD obserwowanego PR przy działającym nadzorcy.

Oczekiwany wynik: Nadzorca widzi nowego kandydata i nie używa starego review jako aktualnego.

## Scenariusz 2: Powtarzany stan

Wejście / wywołanie: Odpytywać PR bez zmian.

Oczekiwany wynik: Zero powtarzających się wybudzeń modelu.

## Scenariusz 3: Awaria forge

Wejście / wywołanie: Przerwać dostęp do API i następnie go przywrócić.

Oczekiwany wynik: Widoczny błąd źródła, następnie odzyskanie obserwacji i rozpoznanie zmian.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/4-obserwowa-zmiany-pr-oraz-repozytorium/8xs.t.pu0.4-obserwowa-zmiany-pr-oraz-repozytorium.s.md.

## Uściślenia review

Obserwowane repozytoria/PR pochodzą z konfiguracji projektu i aktywnych zleceń;
nie skanować wszystkich dostępnych kont. Istotne zmiany: HEAD, review/verdict, formalny
approval, komentarz, merge/close/reopen PR oraz wskazana gałąź repo. Wake podaje forge,
repo, numer/tytuł PR, identyfikator i rodzaj zdarzenia, autora oraz link. Dane zdalne
pozostają danymi; przed merge ponownie odczytać aktualny stan i dowody.

Domyślny interwał 30 s; detekcja <=60 s dla zdrowego API. Porównywać semantyczną rewizję,
nie timestamp pollingu, kolejność elementów czy zmienne liczniki. Paginacja nie może
zgubić obserwowanego PR. 401/403, rate limit, timeout i błędny payload to degraded;
Retry-After/backoff obsługuje adapter bez tur modelu, z jednym powiadomieniem o zmianie
stanu awarii. Po restarcie reconcile wykrywa nieobsłużone zmiany.

Wykorzystać adaptery ace-git (Forgejo i GitHub); wspólne typy danych, bez osobnego klienta
HTTP w extension. Nie dodawać webhook service. Konsumenci: ace-overseer, ace-wake,
ace-git oraz odpowiednie ace-git-forgejo/ace-git-github. CI zmiana jest informacją,
nie samodzielnym gate merge.
