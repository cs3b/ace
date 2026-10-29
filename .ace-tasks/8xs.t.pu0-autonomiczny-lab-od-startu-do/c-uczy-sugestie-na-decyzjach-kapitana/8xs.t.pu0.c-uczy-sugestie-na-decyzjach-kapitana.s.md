---
id: 8xs.t.pu0.c
status: draft
priority: medium
created_at: "2026-10-29 17:13:46"
estimate: medium
dependencies: [8xs.t.pu0.b]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-hitl/docs/usage.md", "ace-coworker/docs/usage.md", "ace-hitl-hermes/docs/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/b-proponowa-odpowiedzi-jako-second-captain/8xs.t.pu0.b-proponowa-odpowiedzi-jako-second-captain.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/ux/usage.md"], "commands": []}
---

# Uczyć sugestie na decyzjach Kapitana

## Cel

Poprawiać kolejne sugestie na podstawie rzeczywistych decyzji człowieka i ich kontekstu.

## Specyfikacja zachowania

Krok 13/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: medium.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

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

Zachowanie wynika z zaakceptowanego briefu. Szczegóły techniczne wymagają review aktualnych źródeł przed wykonaniem. Brak nowych pytań produktowych blokujących zapis draftu.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

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
