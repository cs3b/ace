---
id: 8xs.t.pu0.5
status: pending
priority: medium
created_at: "2026-10-29 17:13:42"
estimate: large
dependencies: [8xs.t.pu0.4]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-hitl/docs/usage.md, ace-hitl-hermes/docs/usage.md, ace-hitl/handbook/workflow-instructions/hitl.wf.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/4-obserwowa-zmiany-pr-oraz-repozytorium/8xs.t.pu0.4-obserwowa-zmiany-pr-oraz-repozytorium.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/5-dostarcza-odpowiedzi-bez-r-cznego/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, ace-test-runner/docs/usage.md, ace-hitl-hermes/docs/native-folder.md]
  commands: []
---

# Dostarczać odpowiedzi bez ręcznego relay

## Cel

Zapewnić powrót decyzji człowieka do właściwego agenta bez ręcznego relay.

## Specyfikacja zachowania

Krok 06/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Hermes rozwiązuje adres sprawy i dostarcza reply przez ace-hitl na maszynie właściciela.
- Ask zachowuje create/send/arm/end-turn. Odbiorca odpowiedzi może być nieaktywny podczas dostawy; trwały zapis umożliwia późniejszą kontynuację.
- Jedna konfiguracja trasy jest źródłem prawdy. Pozostałe native-route.json są usuwane dopiero po potwierdzeniu używanej trasy.
- Wykorzystać raportowane naprawy NameError, soft guards i event-root; nie rozszerzać praw z powodu samego posiadania adresu.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Odpowiedź zewnętrzna | Ask w projekcie, następnie odpowiedź Kapitana przez Hermes | Hermes wywołuje ace-hitl reply dla adresata sprawy; agent kontynuuje. |
| Odbiorca po restarcie | Dostarczyć odpowiedź podczas nieobecności odbiorcy, potem wznowić | Zapisana odpowiedź jest dostępna i zostaje zauważona. |
| Błędny adres | Próba dostawy do nieistniejącej sprawy lub niedostępnej maszyny | Jawne niedostarczenie; brak fałszywego sukcesu lub przekierowania do cudzej sprawy. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Zewnętrzna odpowiedź trafia do właściwej sprawy na właściwej maszynie i powoduje wznowienie.
- [ ] Brak ręcznego relay nie blokuje dostawy.
- [ ] Błąd adresu lub niedostępna maszyna daje informację o niedostarczeniu; treść nie trafia do innej sprawy.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-hitl
- bin/ace-test ace-hitl-hermes
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.4.
Następny krok: 8xs.t.pu0.6.
Starsze zakresy do wykorzystania: 8xg.t.sbz.1.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Włączyć do bieżącej linii istniejący ask/jedną trasę/poprawki frontmatter z odczytanego
fg, bez odtwarzania starego authority/broker. Kontrakt docelowy reply jest nowy:
`ace-hitl reply CASE_ID --stdin`, uruchomiony w jawnie wskazanym katalogu właściciela;
odpowiedź czytana ze stdin, wynik zawiera wyłącznie case i stan received/duplicate.
Pusty tekst, report zamiast question, konflikt odpowiedzi lub brak dokładnej sprawy dają
nonzero bez zmiany innego case. Nie wyszukiwać latest ani po skrócie przy kolizji.

Przyjęty default transportu: istniejące SSH do maszyny właściciela, z jawnie skonfigurowanym
kontem i zweryfikowanym host key, bez nowego serwisu. Hermes używa strukturalnego payloadu
na stdin stałego polecenia odbiorcy; tekst odpowiedzi nie staje się komendą shell ani argv.
Adres machine/project/root/case pochodzi z korelacji wysłanego pytania, nigdy z treści Telegram.
Maszyna, konto i dozwolony root są jawnie związane z projektem w konfiguracji obecnej trasy.
Brak skonfigurowanego dostępu to not-ready, bez automatycznego provisioning uprawnień.

Sukces oznacza potwierdzony zapis przez ace-hitl, nie zapis reply frame w transporcie.
Po utracie potwierdzenia uzgodnić identyfikator dostawy z case; ponowienie tej samej
odpowiedzi jest idempotentne, konflikt nie nadpisuje decyzji. Usunąć aktywny import
reply przez sync/pośrednika po odbiorze nowej ścieżki. Nie utrzymywać fallbacku relay.

Ask wiąże oczekiwanie z tożsamością pytającej sesji i kanonicznym rootem; dwie sesje
w tym samym cwd nie konsumują tej samej decyzji. Odpowiedź przed arm, podczas restartu
lub w main/worktree o tym samym case-id musi trafić do właściwego właściciela.
Sekretne odpowiedzi oznaczać jawnie przy tworzeniu pytania, bez heurystyki tytułu;
wake przekazuje tylko referencję. Konsumenci: ace-hitl, ace-wake, Python plugin Hermes,
ace-hitl-hermes, instrukcje ask i publisher.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Telegram exact Reply → SSH → installed reply → właściwy case → wake pytającego; dwa worktree i dwie sesje współdzielące cwd, tylko właściwy właściciel działa. |
| 2 | Odpowiedź przed arm i podczas braku pytającego; restart widzi received, nie wymaga kolejnego mtime; utrata ACK po zapisie nie gubi decyzji. |
| 3 | Zła maszyna/root/case, unauthorized sender, malformed YAML, konflikt oraz tekst z quoting: brak zapisu w cudzej sprawie, brak sekretu w logu/argv/wake. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-hitl/docs/usage.md
- ace-hitl-hermes/docs/usage.md
- ace-hitl/handbook/workflow-instructions/hitl.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/4-obserwowa-zmiany-pr-oraz-repozytorium/8xs.t.pu0.4-obserwowa-zmiany-pr-oraz-repozytorium.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/5-dostarcza-odpowiedzi-bez-r-cznego/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
