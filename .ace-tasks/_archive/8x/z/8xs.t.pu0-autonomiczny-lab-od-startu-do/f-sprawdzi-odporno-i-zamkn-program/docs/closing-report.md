# Raport zamykający (szkielet uzupełniany dowodami) — 8xs.t.pu0.f (2026-10-30)

Zasady: każdy checkbox rodziny mapowany jest na DOWÓD (źródło: test /
scenariusz / odbiór na labie). „POTWIERDZONE (źródło)" = pokryte testem lub
wiążącym kontraktem w źródłach; „OCZEKUJE NA LAB" = wykonanie na
zainstalowanym labie (odroczony finalny odbiór programu — decyzja Kapitana).
Statusy historycznych programów (gad.2/sbz.9) zmieniane WYŁĄCZNIE po
potwierdzeniu ich własnych kryteriów; mapa nie jest uprawnieniem do
zamknięcia starych tasków; nieznane historyczne kryterium = NIEPOTWIERDZONE
(nigdy dopisany PASS).

## Macierz awarii (granice przed/po) — pokrycie

| Granica | Scenariusz | Dowód (źródło) | Lab |
|---|---|---|---|
| Zapis raportu | duplikat raportu / settled | ace-overseer event_observation (settled/duplicate; tylko terminal trees) | e2e |
| Przyjęcie odpowiedzi | duplikat/konflikt reply | ace-hitl reply tests (duplicate bez zapisu, conflict bez nadpisania) | e2e |
| Wykonanie skutku → applied | crash okna; exactly-once skutku | gate apply duplicate/conflict + workflow reconcile (właściciel efektu) | e2e |
| Merge | HEAD drift po review/testach/approval | gate stale evidence tests + expected-head adaptera | e2e |
| Publish | przerwana publikacja, resume | publisher workflow (wersja+digest; konflikt = blokada) | e2e |
| Install | przerwany krok / brak zależności | ace-lab installer tests (resume convergence; missing dep = not ready) + negative flow .e | e2e |
| Record | zamknięcie cyklu | lifecycle close/apply tests + cycle-record workflow | e2e |
| Auth: issue przed handoff | nieznany wynik issue → retry | NOWE auth/resilience_test (jeden live grant; pending widoczny; **naprawiony defekt find_live/live?**) | e2e |
| Auth: SIGKILL wykonawcy | use_until zabija grant | resilience_test (odmowa użycia po terminie) | e2e |
| Auth: utrata sieci przy revoke | revoke-pending → reconcile | resilience_test (nigdy claimed; reconcile domyka) | e2e |
| Dwie sesje jednego cwd | owner mismatch | eyes owner-cwd test + per-session ask bridge | e2e |
| Kolizja case-id między worktree | reply/suggest na kolidującym id | NOWE hitl_collision_test (jawna ambiguigkeit, zero side-efektów) | e2e |
| Malformed frontmatter | nieparsowalna sprawa | hitl parse klasifikowane (JSON::ParserError → classified) | e2e |
| Awaria pojedynczego źródła | degraded source | LocalSources/RemoteSources degraded tests + health markers | e2e |

Naprawiony defekt (zgodnie z „każdy znaleziony defekt naprawić"):
`LeaseStore#find_live/#live?` zwracały rekord revoke-pending jako żywy
przydział → po przerwaniu issue retry zwracał martwy grant. Naprawione
(only-state-issued); scenariusz ponowiony i zielony; pełny suite ace-lab
625 testów 0 fail.

## Okno zero-idle

Dowód źródłowy: NOWY `zero-idle-window.test.mjs` (ace-wake): 30 minut
zdrowej ciszy na zegarze manualnym → **0** wywołań modelu; techniczny
polling liczony OSOBNO (obserwacje eyes dalej rosną; timery armed); realna
zmiana po oknie nadal wybudza. Granica okna: 30 min (brief rodziny;
starsze 4h z 9o9 NIE jest dodatkowym gate). Liczby przed/po: model calls
0/0; technical observations N/M (M>N). Awaria/odzyskanie źródła = osobny
scenariusz (source-health marker), poza oknem ciszy. Na labie: faktyczne
30-minutowe okno na żywym runtime z osobnym zliczaniem.

## Mapa checkboxów rodziny → dowody

Wypełniana przy finalnym odbiorze; struktura: checkbox kroku .0–.f →
dowód źródłowy (progressy kroków) → dowód lab (do zebrania). Wszystkie
kroki .0–.f mają COMPLETE source-level dowody (patrz docs/progress.md
kroków); żaden checkbox nie jest zaznaczony DONE na poziomie zadania —
statusy pozostały in-progress do odbioru lab.

## gad.2 (zachowany gad2-closure-summary.md)

- F1 worker recovery → dowody: reply/lifecycle/gate crash tests + lab e2e.
- F2 overseer restart/adoption → start reuse/conflict tests + eyes reload
  reconcile + lab e2e.
- F3 lost-operation-response → auth resilience + revoke-pending →
  reconcile + mirror-sync divergence (bez destrukcji) + lab e2e.
Status gad.2 pozostaje BEZ ZMIAN do potwierdzenia jego własnych kryteriów.

## sbz.9

Mapa checkboxów sbz.9 na dowody tej rodziny wykonywana przy finalnym
odbiorze; zamknięcie sbz.9 wymaga jego pełnych kryteriów (dowody z kroków
.e/.f na labie), nie samej deklaracji done tej rodziny.

## Potwierdzone vs pozostałe ograniczenia (stan bieżący)

POTWIERDZONE (źródło): wszystkie zakresy kroków .0–.f z testami (ace-lab
625, ace-overseer 399, ace-hitl 391, ace-coworker 400, ace-wake 134 JS,
ace-handbook 64, ace-git 595, ace-herdr 615 — 0 fail).
OCZEKUJE NA LAB: publikacja gemów; zimny pełny cykl (scenariusz .e);
negativ install flow; okno zero-idle na żywym runtime; mirror-sync na
żywych repo; sprzątanie z wykazu .d; wątki Hermes; scheduler hosta dla
host-revoke (ograniczenie: host-revoke nie wykona się przy niedostępnym
hoście — niezależne native expiry GitHub; Forgejo bez natywnego TTL widoczne
przed handoffem).
