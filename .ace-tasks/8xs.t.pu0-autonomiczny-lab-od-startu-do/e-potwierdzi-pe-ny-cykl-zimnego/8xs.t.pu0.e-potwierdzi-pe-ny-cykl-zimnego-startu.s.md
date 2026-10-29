---
id: 8xs.t.pu0.e
status: draft
priority: medium
created_at: "2026-10-29 17:13:47"
estimate: large
dependencies: [8xs.t.pu0.d]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-lab/docs/usage.md", "ace-overseer/docs/usage.md", "ace-coworker/docs/usage.md", "ace-hitl/docs/usage.md", "ace-handbook-integration-pi/docs/usage.md", "ace-herdr/docs/usage.md", ".ace-handbook/workflow-instructions/release/rubygems-publish.wf.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/8xs.t.pu0.d-utrwali-operacje-hosta-i-higien.s.md"], "commands": []}
---

# Potwierdzić pełny cykl zimnego startu

## Cel

Udowodnić, że wszystkie przekazania składają się na pełny autonomiczny cykl w zainstalowanym labie.

## Specyfikacja zachowania

Krok 15/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Przygotować powtarzalny scenariusz od zimnego startu laba z dwoma projektami i zadaniem wybranym do realizacji.
- Przejść przez rzeczywiste delegowanie, raporty, pytanie HITL z sugestią Second Captaina, niezależny review, merge, publikację, instalację i rekord.
- Operator nie wykonuje kolejnych promptów, kopiowania odpowiedzi ani ręcznego deployu. Kapitan udziela jedynie potrzebnych decyzji i OTP.
- Dowody zawierają rzeczywiste identyfikatory kandydata, wersje, konta, ścieżki runtime i wyniki; nie kończą się na sukcesie komendy.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Zimny pełny cykl | ace-overseer start w przygotowanym labie z co najmniej dwoma projektami | Wybrane zadanie przechodzi cały zaakceptowany przebieg do rekordu w Git. |
| Interakcja z Kapitanem | W trakcie cyklu wymagana jest decyzja i sugestia Second Captaina | Sugestia jest w tym samym HITL; tylko decyzja człowieka zwalnia wymagane działanie. |
| Ponowny start po sukcesie | Ponowić start po zamknięciu cyklu | Brak ponownej publikacji, delegacji lub zastosowania zakończonej decyzji. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Cały cykl kończy się sprawdzonym wdrożeniem i zintegrowanym rekordem.
- [ ] Role wykonawców oraz niezależność review są wykazane dowodami, a nadzorca rzeczywiście deleguje.
- [ ] Powtórne uruchomienie start po zakończonym cyklu nie wykonuje ponownie zamkniętej pracy.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Wykonanie scenariuszy akceptacji przez właściwy runner ace-test/ace-test-suite; polecenia domenowe wskazuje tabela. Wyniki i rzeczywiste ścieżki runtime zapisać przy tasku.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.d.
Następny krok: 8xs.t.pu0.f.
Starsze zakresy do wykorzystania: 8xg.t.sbz.8, 8xg.t.sbz.9.

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
- ace-lab/docs/usage.md
- ace-overseer/docs/usage.md
- ace-coworker/docs/usage.md
- ace-hitl/docs/usage.md
- ace-handbook-integration-pi/docs/usage.md
- ace-herdr/docs/usage.md
- .ace-handbook/workflow-instructions/release/rubygems-publish.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/8xs.t.pu0.d-utrwali-operacje-hosta-i-higien.s.md
