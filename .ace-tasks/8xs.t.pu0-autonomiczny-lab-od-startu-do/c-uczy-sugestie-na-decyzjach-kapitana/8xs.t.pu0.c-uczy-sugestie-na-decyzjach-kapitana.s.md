---
id: 8xs.t.pu0.c
status: pending
priority: medium
created_at: "2026-10-29 17:13:46"
estimate: medium
dependencies: [8xs.t.pu0.b]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-hitl/docs/usage.md, ace-coworker/docs/usage.md, ace-hitl-hermes/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/b-proponowa-odpowiedzi-jako-second-captain/8xs.t.pu0.b-proponowa-odpowiedzi-jako-second-captain.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, ace-hitl-hermes/docs/native-folder.md]
  commands: []
---

# Uczyć sugestie na decyzjach Kapitana

## Cel

Poprawiać kolejne sugestie na podstawie rzeczywistych decyzji człowieka i ich kontekstu.

## Specyfikacja zachowania

Krok 13/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: medium.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Po decyzji Kapitana agent porównuje ją z własną propozycją i zapisuje wnioski przy tej samej sprawie.
- Kolejna sugestia otrzymuje odpowiednią, dostępną w swoim zakresie historię; wskazuje sprawy źródłowe i ograniczenia podobieństwa.
- Kanonicznym źródłem pozostaje HITL. Zapis wniosku nie nadpisuje pytania, propozycji ani rzeczywistej decyzji.
- Brak przykładów jest jawny; nie tworzy fikcyjnych precedensów. Sekrety, OTP i sprawy poza przyznanym dostępem nie są materiałem uczenia.
- Zakres obejmuje używanie historii i wniosków. Nie obejmuje fine-tuningu ani samodzielnego zatwierdzania decyzji.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Korekta jako przykład | Kapitan odrzuca sugestię i podaje inną odpowiedź; później pojawia się podobne pytanie | Nowa propozycja ma dostęp do rzeczywistej decyzji i odnosi się do jej kontekstu. |
| Brak precedensu | Zadać pytanie bez odpowiedniej historii | Agent zaznacza brak przykładów i nie wymyśla wcześniejszej zgody. |
| Sekret i izolacja | W historii są sprawy OTP lub sprawa innego niedostępnego projektu | Wartości sekretów i niedozwolony kontekst nie są używane ani ujawniane. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Korekta sugestii przez człowieka jest zachowana i może zostać wskazana w kolejnym podobnym pytaniu.
- [ ] Każde powołanie się na wcześniejszą decyzję da się sprawdzić w źródłowej sprawie.
- [ ] Powtórne przetworzenie decyzji nie mnoży identycznych wniosków; historia zachowuje właściwego autora.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-hitl
- bin/ace-test ace-coworker
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.b.
Następny krok: 8xs.t.pu0.d.
Starsze zakresy do wykorzystania: 8xg.t.sbz.1.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Trigger uczenia to zaakceptowana nietajna odpowiedź człowieka do sprawy z sugestią.
Wniosek zapisuje ace-hitl przy tej sprawie jako lesson z odwołaniem do dokładnych rewizji
pytania/sugestii/decyzji, autorem agenta i czasem. Idempotencja po case + decision revision;
wniosek nie jest nową decyzją i nie zmienia jej autora. Brak sugestii oznacza brak
porównania, nie zmyśloną zgodność. Race zamknięcia nie kasuje historii ani nie wznawia operacji.

Default retrieval ograniczony do tego samego projektu i obecnie dostępnych nietajnych
spraw; nie korzystać z szerszego dostępu nadzorcy laba jako przyzwolenia na dzielenie
historii. Wybierać podobny temat/rodzaj decyzji, podać referencje i ograniczenia; nowsza
jawna korekta Kapitana ma pierwszeństwo nad wcześniejszą sugestią. Brak podstaw jest
widoczny. Bez embedding-store, indeksu decyzji ani kopii korpusu poza HITL.

Filtr secret/OTP i uprawnień działa przed przekazaniem historii do modelu; także treść
sugestii/wniosku nie może przywrócić wykluczonych wartości. Konsumenci: ace-hitl
odczyt/sekcje/historia, ace-coworker instrukcje second-captain, ace-overseer trigger.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Kapitan odrzuca propozycję → lesson → podobne pytanie wykorzystuje prawdziwą korektę; brak propozycji nie tworzy fikcyjnego porównania. |
| 2 | Odczytać wszystkie cytowane case/revision i autora; zmieniony/zamknięty case zachowuje pytanie, suggestion, Answer i lesson. |
| 3 | Powtórzony trigger i restart nie mnożą lessons; OTP oraz niedostępny projekt odfiltrowane przed modelem; brak precedensu jest jawny. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-hitl/docs/usage.md
- ace-coworker/docs/usage.md
- ace-hitl-hermes/docs/usage.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/b-proponowa-odpowiedzi-jako-second-captain/8xs.t.pu0.b-proponowa-odpowiedzi-jako-second-captain.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
