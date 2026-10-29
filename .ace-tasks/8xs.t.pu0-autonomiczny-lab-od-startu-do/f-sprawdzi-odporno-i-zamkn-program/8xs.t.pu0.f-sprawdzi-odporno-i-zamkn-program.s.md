---
id: 8xs.t.pu0.f
status: pending
priority: medium
created_at: "2026-10-29 17:13:47"
estimate: large
dependencies: [8xs.t.pu0.e]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-lab/docs/usage.md, ace-overseer/docs/usage.md, ace-coworker/docs/usage.md, ace-hitl/docs/usage.md, ace-handbook-integration-pi/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/e-potwierdzi-pe-ny-cykl-zimnego/8xs.t.pu0.e-potwierdzi-pe-ny-cykl-zimnego-startu.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, .ace-tasks/_archive/8x/w/8xa.t.ega-deliver-gad2-closure-records-via/gad2-closure-summary.md, ace-test-runner/docs/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md]
  commands: []
---

# Sprawdzić odporność i zamknąć program

## Cel

Potwierdzić odporność procesu na przerwania i zamknąć program wyłącznie na podstawie dowodów.

## Specyfikacja zachowania

Krok 16/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Wykonać próby restartu nadzorcy/coworkera na granicach przekazań, powtórzonego zdarzenia, utraty reply, zmiany HEAD i awarii źródła obserwacji.
- Sprawdzić co najmniej 30 minut zdrowej bezczynności: zero dodatkowych wywołań modelu po uspokojeniu stanu; techniczny polling jest dozwolony.
- Po odzyskaniu dostępności proces rozpoznaje trwały stan i kontynuuje bez zgubienia pracy lub ponowienia zakończonych skutków.
- Każdy znaleziony defekt naprawić w zakresie odpowiedzialnego komponentu, ponowić jego scenariusz i potwierdzić cały dotknięty przebieg.
- Raport końcowy mapuje dowody na kryteria tej rodziny oraz gad.2/sbz.9. Statusy historycznych programów zmieniać wyłącznie po potwierdzeniu ich kryteriów, nigdy na podstawie samej deklaracji done.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Przerwane przekazanie | Restartować na granicy raportu, odpowiedzi oraz publikacji/instalacji | Odzyskanie kontynuuje właściwy etap bez powielenia jego zakończonych skutków. |
| Wrong-head i lost-reply | Zmienić HEAD po review; osobno utracić dostawę odpowiedzi przed zapisem | Nieaktualny review nie dopuszcza merge; niedostarczona odpowiedź pozostaje wykrywalna i może zostać ponowiona. |
| Zero-idle i awaria obserwacji | Obserwować 30 minut bez zmian, następnie przerwać źródło i przywrócić | Zero dodatkowych tur w ciszy; jawna awaria i skuteczne odzyskanie obserwacji. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Każda próba awarii ma wejściowy stan, oczekiwany wynik, faktyczne dowody i wynik ponowienia po naprawie.
- [ ] Nie ma zagubionych decyzji, podwójnych zakończonych operacji ani bezproduktywnych tur w oknie zero-idle.
- [ ] Raport zamykający rozróżnia potwierdzone kryteria od pozostających ograniczeń; brak niespełnionych wymaganych kryteriów do zamknięcia rodziny.
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
Poprzednik: 8xs.t.pu0.e.
Następny krok: odbiór i zamknięcie taska nadrzędnego.
Starsze zakresy do wykorzystania: 8xg.t.sbz.8, 8xg.t.sbz.9.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Macierz awarii obejmuje granice przed/po: zapisie raportu, przyjęciu odpowiedzi,
wykonaniu skutku, zapisie applied, merge, publish, install i integracji rekordu. Dla
niepewnego zewnętrznego skutku dopuszczalnym bezpiecznym wynikiem jest jawna blokada
do reconcile — nigdy fałszywe done ani ślepy replay. Potwierdzić też dwie sesje jednego
cwd, kolizję case-id między worktree, malformed frontmatter i awarię pojedynczego źródła.

Wymagane okno tej rodziny to >=30 min zdrowej ciszy zgodnie z późniejszym briefem;
starsze 4h w 9o9 nie jest dodatkowym gate tego programu. Podać granice okna, liczbę
model calls przed/po i liczbę technicznych odczytów oddzielnie. Awaria i odzyskanie
źródła są osobnym scenariuszem poza oknem zdrowej ciszy.

Końcowa macierz mapuje każdy checkbox rodziny i każde zastosowane kryterium sbz.9.
Dla gad.2 wykorzystać zachowane `gad2-closure-summary.md`: F1 worker recovery,
F2 overseer restart/adoption i F3 lost-operation-response. Status historycznego programu
nie jest automatycznie zmieniany; wymagania dawnego authority modelu nie wracają do
produktu. Nieznane historyczne kryterium zaznaczyć jako niepotwierdzone zamiast dopisywać PASS.
Zamknięcie nowej rodziny wymaga jej pełnych kryteriów; mapa do starych prac nie jest
uprawnieniem do zamknięcia starych tasków. Konsumenci: scenariusze ace-lab/ace-overseer,
testy odpowiedzialnych komponentów i końcowy zapis w tasku.

### Integracja ace-lab auth po decyzji Kapitana

Macierz crash dla kryterium 1 obejmuje także auth z .7: issue przed handoff,
utracona odpowiedź issue, SIGKILL coworkera, restart hosta oraz utrata sieci podczas
revoke. Wynik potwierdza brak drugiego aktywnego przydziału po retry, odmowę użycia
po use_until i niezależność cleanup od modelu. Revoke-pending/unknown pozostaje
nierozliczoną sprawą do potwierdzenia; nie wpisywać PASS na podstawie usunięcia env/pliku.
Udokumentować ograniczenie host-revoke przy niedostępnym hoście i niezależne native expiry.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Tabela wszystkich granic crash z przed/po stanem i dowodem recovery; powtórzyć dotknięty pełny przepływ po naprawie. |
| 2 | Duplicate/lost reply/wrong HEAD/niepewny publish oraz 30 min idle; zero powtórzonych zakończonych efektów, zero model calls w zdrowej ciszy. |
| 3 | Macierz 16 dzieci + parent, sbz.9 i znane F1/F2/F3 gad.2; każde PASS ma dowód, ograniczenia oddzielone, stare taski bez automatycznej zmiany statusu. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

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
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/e-potwierdzi-pe-ny-cykl-zimnego/8xs.t.pu0.e-potwierdzi-pe-ny-cykl-zimnego-startu.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md
