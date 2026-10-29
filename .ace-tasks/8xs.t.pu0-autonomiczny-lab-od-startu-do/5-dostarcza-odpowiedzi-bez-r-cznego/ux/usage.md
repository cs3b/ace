# Dostarczać odpowiedzi bez ręcznego relay — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Odpowiedź zewnętrzna

Wejście / wywołanie: Ask w projekcie, następnie odpowiedź Kapitana przez Hermes.

Oczekiwany wynik: Hermes wywołuje ace-hitl reply dla adresata sprawy; agent kontynuuje.

## Scenariusz 2: Odbiorca po restarcie

Wejście / wywołanie: Dostarczyć odpowiedź podczas nieobecności odbiorcy, potem wznowić.

Oczekiwany wynik: Zapisana odpowiedź jest dostępna i zostaje zauważona.

## Scenariusz 3: Błędny adres

Wejście / wywołanie: Próba dostawy do nieistniejącej sprawy lub niedostępnej maszyny.

Oczekiwany wynik: Jawne niedostarczenie; brak fałszywego sukcesu lub przekierowania do cudzej sprawy.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/5-dostarcza-odpowiedzi-bez-r-cznego/8xs.t.pu0.5-dostarcza-odpowiedzi-bez-r-cznego-relay.s.md.

## Uściślenia review

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
