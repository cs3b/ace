# Audyt otwartych zgłoszeń GitHub — 2026-10-10

Repozytorium: https://github.com/cs3b/ace. Sprawdzono wszystkie 15 otwartych issues zwróconych przez GitHub. Zakres to zgłoszenia, nie pełny audyt Actions ani wszystkich pull requestów.

Punkt odniesienia: `aaf6dfec4c2d93c8f0b1c7cd53b6a07c68942659`. Po `git fetch origin` HEAD i origin/main wskazywały ten sam commit. Drzewo robocze przed audytem było czyste.

## Rekomendacja

Najpierw naprawić tworzenie tasków (#333), ignorowanie lokalnych filtrów review (#322) oraz obsługę dowodów dla plików binarnych (#330). Następnie AGY (#320), politykę zaufania bundle (#331) i brakujący kontrakt zamykania źródłowego feedbacku (#334). Utworzono nadrzędny task **8x9.t.qkd** i sześć osobnych subtasków. Nie są to puste stubs: każdy ma zakres zachowania, kryteria, scenariusze negatywne, plan testów, kontekst i kontrakt użycia.

## Macierz wszystkich zgłoszeń

| Issue | Wynik weryfikacji aktualnego main | Decyzja / task |
|---|---|---|
| [#333](https://github.com/cs3b/ace/issues/333) | **Odtworzony CLI**: NoMethodError i osierocony plik taska po create --in next. | Naprawić najpierw: **8x9.t.qkd.0**. |
| [#322](https://github.com/cs3b/ace/issues/322) | **Częściowo naprawiony**: PR filtering działa w testach; **odtworzona luka** dla lokalnego diff:HEAD oraz ignorowania strategy. | Naprawić pozostałość: **8x9.t.qkd.2**; nie przepisywać działającego PR scope. |
| [#330](https://github.com/cs3b/ace/issues/330) | Historyczna komenda zniknęła. **Odtworzona luka na granicy komponentów**: manifest binary-only przechodzi full_pr_coverage!. Nie wykonano pełnego bypassu campaign acceptance. Brak znalezionego konsumenta binary receipt. | **8x9.t.qkd.3**, aktualny kontrakt campaign + realna izolacja; nie przywracać starego gate. |
| [#320](https://github.com/cs3b/ace/issues/320) | **Odtworzony** błąd string-key max_prompt_length; kod nadal używa argv i domyślnego limitu 100000 B. | **8x9.t.qkd.1**. Native AGY read_file/permissions wymaga późniejszego smoke testu. |
| [#331](https://github.com/cs3b/ace/issues/331) | **Potwierdzone analizą źródła**: ace-bundle hard-code'uje wyjątek ace-review. Testy istniejących zabezpieczeń przechodzą. | **8x9.t.qkd.4**; to brak jawnej polityki, nie dowód obejścia istniejących zabezpieczeń. |
| [#334](https://github.com/cs3b/ace/issues/334) | **Historyczna reprodukcja nieaktualna**: wfi://task/deliver nie rozwiązuje się. W aktualnych źródłach brak kontraktu cited feedback. | **8x9.t.qkd.5**, niski priorytet; wdrożyć zachowanie w utrzymywanym właścicielu delivery. Bez testu z prawdziwym Nervus nie twierdzimy, że odtworzono problem konsumenta. |
| [#323](https://github.com/cs3b/ace/issues/323) | Rdzeń budżetowania pełnego promptu jest zaimplementowany; przechodzą testy oversized context, Unicode, rezerwy output, limitów modelu i odrzucenia nadmiarowego input. | Kandydat do rozliczenia/zwężenia issue. Nie tworzono duplikatu. Pełna macierz dawnych strategy entrypoints i wszystkich granic z issue nie była odtwarzana. |
| [#327](https://github.com/cs3b/ace/issues/327) | Przechodzą regresje JSON z codex w ścieżce, final-message, Pi model/reasoning argv i odrzucania błędnych modeli oraz testy target/role. | Główne reprodukcje naprawione; kandydat do zamknięcia po pełnym mapowaniu execution identity single/multi i wszystkich entrypointów. Bez nowego taska implementacyjnego. |
| [#325](https://github.com/cs3b/ace/issues/325) | GoalsBrief używa CacheStore, digests źródeł/promptu/modelu i accepted/proposed authority; przechodzą testy reuse, invalidation i fallback. | **Częściowo potwierdzona realizacja**. Zachowanie unresolved decisions, grupowanie dużych korpusów i jakość semantyczna wymagają szerszej ewaluacji. Nie oznaczać automatycznie całego issue jako done. |
| [#324](https://github.com/cs3b/ace/issues/324) | Istnieje przecięcie file_pattern_groups dla module/lens. Nie znaleziono pełnego współdzielonego kontraktu ownership/context graph i propagacji consumer edges. | Odrębna funkcja rozwojowa; odłożyć za kolejkę błędów. Brak twierdzenia o wykonaniu całości. |
| [#326](https://github.com/cs3b/ace/issues/326) | **Wykryty failing test publicznego CLI** po head drift: akceptacja odrzuca historyczny dowód wykonania. CampaignManager/evidence/policy istnieją; bieżące taski **8x0.t.ig3** i **8x0.t.ig4** pozostają in-progress. | Dowód dopisany do **8x0.t.ig3**; nie zamykać #326. Kontynuować istniejące taski. Ich metadata oraz częściowe testy nie stanowią dowodu pełnego zamknięcia tego issue. |
| [#338](https://github.com/cs3b/ace/issues/338) | Nowszy kod i zaakceptowana specyfikacja ig4 określają min. 3 / max. 5 rund delivery oraz 2 discovery. Issue żąda 2/20 i premium slots 1/10/20. Nie znaleziono premium accounting w aktualnej polityce. | **Sprzeczny/starszy kontrakt**. Rozliczyć w ig4: zachować nowszą politykę, jawnie zdecydować los premium cap. Nie tworzyć drugiego silnika ani zmieniać limitu na 20 na podstawie starego zgłoszenia. |
| [#321](https://github.com/cs3b/ace/issues/321) | Task **8wm.t.nnv** ma done i ogólną notatkę settlement; child checklist nadal niezaznaczony, issue_sync_pending=true, GitHub epic otwarty. | Rozliczać osobno dzieci. Samo archiwum nie dowodzi wykonania #322–327. |
| [#317](https://github.com/cs3b/ace/issues/317) | Propozycja housekeeping, nie konkretna regresja. Brak znalezionego odpowiadającego taska w .ace-tasks; ace:tracked nie wskazuje tu zweryfikowanego powiązania. Przeczytano też komentarz o records/artifacts/protected content. | Odłożyć jako osobny program funkcjonalny; nie mieszać z naprawami review/task. |
| [#318](https://github.com/cs3b/ace/issues/318) | Propozycja polityki aktualizacji i research, nie odtwarzalny błąd. Brak znalezionego odpowiadającego taska w .ace-tasks mimo ace:tracked. | Odłożyć; wymaga własnego porównania aktualnych narzędzi i decyzji zakresu. Nie weryfikowano zewnętrznych twierdzeń o updaterach. |

## Dowody reprodukcji

### #333: publiczne CLI

Uruchomiono checkout binstub w `/tmp/ace-github-triage-20261010`:

```sh
PATH=/Users/mc/.local/share/mise/installs/ruby/3.4.8/bin:$PATH /Users/mc/Ps/ace/bin/ace-task create 'Reproduce issue 333' --status draft --in next
```

Exit 1: `undefined method move` w `ace-task/lib/ace/task/cli/commands/create.rb:122`. Pozostał plik `.ace-tasks/8x9.t.qjm-reproduce-issue-333/8x9.t.qjm-reproduce-issue-333.s.md` w katalogu tymczasowym. `TaskManager#update` obsługuje move_to; publicznego move brak. Pierwszy start poza repo ujawnił mismatch Ruby 3.4.9/native extension 3.4.8; odtworzenie ponowiono na zgodnym 3.4.8. Tego lokalnego problemu środowiska nie utożsamiano z #333.

### #320, #322, #330: kontrolowane próby bez wywołań modeli

Źródło próby zachowano w [reproduction-probe.md](reproduction-probe.md). Skrypt `/tmp/ace-github-triage-20261010/probe.rb` używa aktualnego Bundlera i źródeł repo. Dla #322 tworzy prawdziwe tymczasowe repo Git i preset, a następnie przygotowuje prompt z auto_execute=false. Wynik:

```text
AGY: Ace::LLM::ProviderError: Antigravity CLI prompt bytesize 354141 exceeds configured limit 100000.
STRATEGY: resolved key present=false
LOCAL: success=true error=
LOCAL: prompt contains excluded diff=true
BINARY: full_pr_coverage! accepts binary-only manifest; binaries=["assets/photo.png"]
```

#330 to próba rzeczywistego DiffScope -> CampaignContract z kompletnym manifestem i dopasowanymi SHA. Nie zastępuje pełnego testu CLI, importu autorytatywnego receipt ani izolacji. Task wymaga tych testów przed uznaniem naprawy za gotową.

## Wykonane testy istniejącego kodu

Wszystkie polecenia wykonano przez `bin/ace-test`; nie modyfikowano testów ani kodu produktu. Transport modeli w tych scenariuszach jest kontrolowany, bez płatnych zapytań.

| Zakres | Wynik | Raport w .ace-local/test/reports |
|---|---|---|
| ace-review: prompt_budget, goals_brief, diff_scope | 29 testów / 111 asercji, PASS | review/a54b4885-bbd9-4341-bc25-eb820055ae99/ |
| ace-llm-providers-cli: agy_client, pi_client, codex_client | 135 / 376, PASS | llm-providers-cli/c964c520-73e9-419f-ab07-7751a22d6a0d/ |
| ace-review: review_manager, preset_manager, campaign_policy, campaign_convergence | 155 / 628, PASS | review/a630a76f-804e-4b5e-be25-79dc21de30e9/ |
| ace-bundle: bundle_loader | 83 / 294, PASS | bundle/984ec050-3e8d-4ece-b3ed-20b963473932/ |
| ace-review: review_packet_integration | 1 / 3, PASS | review/41da8f56-9370-452d-af86-cf6b5fd6c1f6/ |
| ace-llm: pi_glm53_target, codex_target, role_resolver | 18 / 108, PASS | llm/28c31ca5-84be-41d7-a059-0a0a8060f937/ |

Dodatkowo uruchomiono `bin/ace-test ace-review test/feat/campaign_cli_test.rb test/feat/campaign_phase_cli_test.rb`: **3 testy / 141 asercji, 1 failure, 0 errors**. Raport: `review/04bf56cf-fd37-4b90-afa6-d0e3bf191e4c/`. Failure w `campaign_cli_test.rb:178`, test `test_public_json_dry_run_restart_replay_head_drift_and_acceptance`:

```text
accepted execution evidence unavailable: Error: Historical evidence requires review collection/approval and an exact recorded head
```

Sprawdzenie `recorded["accepted"]` po czwartej rundzie dla nowego head zwraca false. Jest to potwierdzony failing scenario obecnego CLI; nie rozstrzygnięto jeszcze, czy przyczyną jest runtime, czy nieaktualny kontrakt fixture. Dowód przypisano istniejącemu właścicielowi **8x0.t.ig3**. Wymagane rozstrzygnięcie ma zachować sprawdzanie historycznych SHA, nie osłabiać walidacji dla uzyskania zielonego testu.

Łącznie **424 testy, 1661 asercji, 1 failure, 0 errors**; pierwsze sześć grup (421 testów) przeszło. Jedno wcześniejsze polecenie z --filter review_safe wybrało zero plików; nie zaliczono go jako weryfikacji i zastąpiono pełnym plikiem bundle_loader. Nie wykonano pełnego monorepo suite, prawdziwego AGY ani consumer acceptance Nervus/PlayaGo. Zielone testy nie dowodzą brakujących scenariuszy: #320 i #322 odtworzono mimo zielonych istniejących suite.

## Sposób pracy i następny krok

Wykonano workflowy as-bug-analyze, as-task-finder, as-task-draft oraz pomocnicze badanie według as-search-research. Użytkownik zlecił utworzenie tasków, więc utworzono drafty bez dodatkowego etapu potwierdzania samego zapisu. Najpierw należy wykonać readiness review **8x9.t.qkd.0**, potem przejść do as-task-work; kolejne dzieci według kolejki w specyfikacji nadrzędnej.

GitHub pozostawiono bez komentarzy i zamykania issues. `ace-task create --issue` automatycznie publikuje tracking update; dlatego taski utworzono CLI bez tego argumentu, a pełne remote_issue dodano lokalnie z issue_sync_pending=true. To świadome odstępstwo od automatycznego issue sync w workflow: bieżące zlecenie dotyczy planu i lokalnych tasków, a nie publikacji wiadomości. Przed przyszłym sync sprawdzić, czy issue nie uzyskało innego właściciela. Nie przywracać do pracy starego epicu tylko dlatego, że pozostaje otwarty na GitHubie.
