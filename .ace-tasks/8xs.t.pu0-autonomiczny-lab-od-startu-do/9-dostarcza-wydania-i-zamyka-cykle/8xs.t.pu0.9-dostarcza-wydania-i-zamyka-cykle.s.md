---
id: 8xs.t.pu0.9
status: draft
priority: medium
created_at: "2026-10-29 17:13:44"
estimate: large
dependencies: [8xs.t.pu0.8]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-overseer/docs/usage.md", "ace-lab/docs/usage.md", "ace-hitl/docs/usage.md", ".ace-handbook/workflow-instructions/release/rubygems-publish.wf.md", ".ace-handbook/workflow-instructions/release/local.wf.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/8xs.t.pu0.8-prowadzi-zadania-przez-review-i-merge.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/ux/usage.md"], "commands": []}
---

# Dostarczać wydania i zamykać cykle

## Cel

Doprowadzić zmergowaną zmianę do potwierdzonego runtime i trwałego zamknięcia cyklu.

## Specyfikacja zachowania

Krok 10/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Nadzorca deleguje release inventory/bumps/build/publish zgodnie z istniejącymi workflow projektu.
- Publisher obsługuje OTP przez HITL; sekret klucza pozostaje w dozwolonym wrapperze/env. Ask kończy turę, oczekiwanie nie jest pętlą modelu.
- Po publikacji instalacja uzgadnia runtime i rozszerzenia oraz wykonuje odbiór pod docelowym kontem.
- Rekord cyklu trafia do .ace-tasks/_records przez właściwy reviewowany PR. Cykl pozostaje otwarty do integracji rekordu; jego commit nie uruchamia kolejnego wydania bez zmian produktu.
- Przerwanie zachowuje znany etap i rzeczywiste wersje. Wznowienie rozpoznaje już opublikowane artefakty i nie udaje zakończenia częściowo wdrożonego cyklu.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Pełne dostarczenie | Po merge nadzorca deleguje release → publish → install → verify → record | Zmiana działa pod docelowym kontem, a rekord cyklu jest w Git. |
| Opóźnione OTP | Kapitan odpowiada później na pytanie publishera | Publikacja kontynuuje właściwy etap; wygasłe OTP wymaga nowego pytania, bez ujawniania wartości. |
| Awaria instalacji | Przerwać instalację po udanej publikacji, następnie wznowić | Cykl pozostaje otwarty; wznowienie rozpoznaje opublikowane wersje i doprowadza do odbioru. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Raport pokazuje osobno źródła, integrację, publikację, instalację i wynik runtime.
- [ ] Opóźnione OTP wznawia poprawny krok publikacji bez ręcznego relay i bez tokenów podczas oczekiwania.
- [ ] Zadanie jest zakończone dopiero po udanym odbiorze i zintegrowanym rekordzie; awaria pozostawia wznowialną blokadę.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-overseer
- bin/ace-test ace-lab
- bin/ace-test ace-hitl
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.8.
Następny krok: 8xs.t.pu0.a.
Starsze zakresy do wykorzystania: 8xg.t.sbz.9.

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
- ace-overseer/docs/usage.md
- ace-lab/docs/usage.md
- ace-hitl/docs/usage.md
- .ace-handbook/workflow-instructions/release/rubygems-publish.wf.md
- .ace-handbook/workflow-instructions/release/local.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/8xs.t.pu0.8-prowadzi-zadania-przez-review-i-merge.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/ux/usage.md
