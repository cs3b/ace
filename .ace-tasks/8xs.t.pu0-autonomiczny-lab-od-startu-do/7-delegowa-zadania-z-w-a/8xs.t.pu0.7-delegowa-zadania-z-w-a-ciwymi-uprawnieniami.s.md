---
id: 8xs.t.pu0.7
status: draft
priority: medium
created_at: "2026-10-29 17:13:43"
estimate: large
dependencies: [8xs.t.pu0.6]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-coworker/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md", "ace-lab/docs/usage.md", "ace-coworker/handbook/workflow-instructions/coworker/worker.wf.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/8xs.t.pu0.6-zamyka-sprawy-hitl-bez-sierot.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/ux/usage.md"], "commands": []}
---

# Delegować zadania z właściwymi uprawnieniami

## Cel

Pozwolić nadzorcy delegować zadanie wraz z wystarczającym, ograniczonym dostępem.

## Specyfikacja zachowania

Krok 08/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Brief coworkera niesie zadanie, właściwy worktree/cwd, assignment, instrukcje, kryteria odbioru oraz zasady raportowania.
- Coworker otrzymuje referencję do dostępu z określonym zakresem i czasem; zakończenie lub przerwanie zadania kończy przydział zgodnie z mechanizmem dostępu.
- Role znają procedury użycia i ewentualnego generowania poświadczeń wyłącznie w przyznanym zakresie.
- Wzorzec kont laba: lab-overseer autor/merger; lab-merge-ace formalny approver po niezależnym review. W innych projektach użyć ich skonfigurowanych ról.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Pełna delegacja | Nadzorca przygotowuje i zleca zadanie przez ace-coworker | Wykonawca pracuje w poprawnym worktree z assignmentem i raportuje do nadzorcy. |
| Brak uprawnienia | Zlecić operację bez wymaganego dostępu | Coworker raportuje konkretną blokadę przez HITL. |
| Zakończenie przydziału | Zakończyć albo przerwać zlecenie z czasowym dostępem | Przydział kończy się zgodnie z zakresem; sekret nie pojawia się w raporcie. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Praca wykonawcza jest realizowana przez coworkera, a nadzorca otrzymuje raport.
- [ ] Brak potrzebnego dostępu powoduje eskalację z przyczyną, nie przejęcie pracy przez nadzorcę lub rozszerzenie praw.
- [ ] Prompty i dowody nie zawierają wartości sekretów; przydział dostępu jest zakończony po zadaniu.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-coworker
- bin/ace-test ace-overseer
- bin/ace-test ace-lab
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.6.
Następny krok: 8xs.t.pu0.8.
Starsze zakresy do wykorzystania: 8xg.t.sbz.2, 8xg.t.sbz.3, 8xg.t.sbz.4.

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
- ace-coworker/docs/usage.md
- ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md
- ace-lab/docs/usage.md
- ace-coworker/handbook/workflow-instructions/coworker/worker.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/8xs.t.pu0.6-zamyka-sprawy-hitl-bez-sierot.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/ux/usage.md
