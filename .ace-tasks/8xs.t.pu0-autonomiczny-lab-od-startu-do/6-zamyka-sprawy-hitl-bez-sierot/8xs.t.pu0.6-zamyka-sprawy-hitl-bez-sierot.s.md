---
id: 8xs.t.pu0.6
status: pending
priority: medium
created_at: "2026-10-29 17:13:43"
estimate: large
dependencies: [8xs.t.pu0.5]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-hitl/docs/usage.md, ace-overseer/docs/usage.md, ace-hitl-hermes/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/5-dostarcza-odpowiedzi-bez-r-cznego/8xs.t.pu0.5-dostarcza-odpowiedzi-bez-r-cznego-relay.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, ace-test-runner/docs/usage.md, ace-hitl-hermes/docs/native-folder.md]
  commands: []
---

# Zamykać sprawy HITL bez sierot

## Cel

Zamykać sprawy HITL i usuwać pozostałości bez utraty aktywnych pytań ani historii decyzji.

## Specyfikacja zachowania

Krok 07/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Właściciel HITL rozróżnia oczekiwanie, otrzymanie odpowiedzi, zastosowanie i zakończenie; dokładne nazwy techniczne stanów są dobierane do istniejącego modelu.
- Ponowna dostawa i restart nie powtarzają skutków odpowiedzi. Późna odpowiedź do zamkniętej sprawy nie zmienia automatycznie zakończonej decyzji.
- Sprzątanie transportu i watchy zachowuje aktywne sprawy oraz historię pytań/decyzji potrzebną Second Captainowi.
- Wykonać rozpoznany sweep zgłoszonych sierot, m.in. 8xptgt, i martwego watcha ask-8xskgh; identyfikatory zweryfikować w docelowym labie przed działaniem.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Zamknięcie sprawy | Dostarczyć i zastosować odpowiedź, zakończyć czynność | Sprawa jest zamknięta, niepotrzebny watch nie wybudza odbiorcy. |
| Duplikat i restart | Ponowić odpowiedź po restarcie odbiorcy | Brak ponownego wykonania zakończonej operacji. |
| Późna odpowiedź i sweep | Odpowiedzieć na zamkniętą sprawę i przejrzeć pozostałości transportu | Brak automatycznej zmiany decyzji; aktywne sprawy i historia pozostają. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Dwa doręczenia tej samej odpowiedzi prowadzą do najwyżej jednego skutku biznesowego.
- [ ] Restart między dostawą i zastosowaniem zachowuje możliwą kontynuację.
- [ ] Sweep ma wykaz rozpoznanych pozostałości; nie usuwa aktywnej sprawy ani kanonicznej historii decyzji.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-hitl
- bin/ace-test ace-overseer
- bin/ace-test ace-hitl-hermes
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.5.
Następny krok: 8xs.t.pu0.7.
Starsze zakresy do wykorzystania: 8xg.t.sbz.1, 8xg.t.sbz.5.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Stan pozostaje w kanonicznym pliku HITL. Ustalić rozdzielnie receipt (pending/received)
i zastosowanie (pending/applied/closed, z cancelled jako zakończenie bez zastosowania);
raporty pozostają recorded i nie oczekują odpowiedzi. W pliku zapisywać identyfikator
dostawy, właściciela pytania i referencję do wyniku istniejącego taska/assignmentu.
Nie tworzyć z tego drugiego rejestru efektów. Kolejne aktualizacje przez ace-hitl muszą
być atomowe i odrzucać konflikt równoczesnych odpowiedzi.

Exactly-once dotyczy skutku, nie samej liczby powiadomień. Gdy proces padł po efekcie,
przed applied, konsument najpierw sprawdza wynik u właściciela efektu (PR/release/assignment).
Brak możliwości rozstrzygnięcia oznacza jawną blokadę uzgodnienia, nigdy ślepe powtórzenie.
Zamknięcie dopiero po dowodzie applied; duplikat jest no-op, późna odmienna odpowiedź
odrzucona jako konflikt i nie otwiera case. Jawna zmiana decyzji wymaga nowej sprawy.

Sweep najpierw pokazuje listę/kryterium kwalifikacji. Usuwa tylko powiązane watch/request/
transport po dowiedzionym zamknięciu; unknown delivery, aktywna sprawa, nierozpoznany
zasób i kanoniczna historia są zachowane. Historyczne ID z relacji nie są listą do delete.
Nie usuwać całego worktree z otwartym HITL. Konsumenci: ace-hitl, ace-wake,
ace-hitl-hermes, ace-coworker oraz process-reports w ace-overseer.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Dwie równoczesne identyczne dostawy i dwa budzenia → jeden skutek; odmienna odpowiedź odrzucona. |
| 2 | Crash przed efektem, po efekcie przed applied, po applied przed closed; reconcile właściciela rozstrzyga albo jawnie blokuje niepewny efekt. |
| 3 | Sweep obejmuje closed/cancelled/pending/unknown i historię z sugestią; usuwa tylko potwierdzone pozostałości, zachowuje aktywne i nieznane. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-hitl/docs/usage.md
- ace-overseer/docs/usage.md
- ace-hitl-hermes/docs/usage.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/5-dostarcza-odpowiedzi-bez-r-cznego/8xs.t.pu0.5-dostarcza-odpowiedzi-bez-r-cznego-relay.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
