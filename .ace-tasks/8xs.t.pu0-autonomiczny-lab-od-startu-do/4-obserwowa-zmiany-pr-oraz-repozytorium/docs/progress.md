# Postęp 8xs.t.pu0.4 — obserwacja zmian PR/repo (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Odbiór runtime (żywy forge,
konta docelne) odroczony na koniec programu (decyzja Kapitana).

## Zrealizowane w źródłach

1. **`Molecules::RemoteSources`** — konfigurowana obserwacja PR przez
   ISTNIEJĄCE adaptery forge (`Ace::Git::Providers.for`: Forgejo + GitHub; bez
   osobnego klienta HTTP, bez webhook service):
   - źródło deklaracji: `observe.remote.pull_requests` w kaskadzie
     `.ace/overseer/config.yml` (serwer + numer) — nigdy skan wszystkich kont;
   - dwa wiersze na PR: `pr:<server>:<nr>` (cykl życia: nowy HEAD przez
     head_sha, state open/merged/closed → merge/close/reopen, title/draft) i
     `pr-activity:<server>:<nr>` (posortowany zbiór tożsamości review+comment:
     id/author/state/head_sha — nowy review/approval/komentarz rewizuje raz;
     reorder payloadu i zmienne liczniki nie rewizują);
   - payload wybudzenia: forge, numer/tytuł PR, rodzaj i identyfikator
     zdarzenia, autor, link;
   - awaria API (401/403, rate limit, timeout, zły payload) degraduje tylko
     swoje źródło: marker `source-health` z rewizją keyed by klasa błędu (jedno
     wybudzenie na tryb awarii; identyczna awaria nie spamuje); retry/backoff
     zostaje w adapterach; recovery rozpoznaje zmianę przez normalną rewizję.
2. **Integracja z observe** — `EventObservation` dokleja wiersze remote do
   projekcji (bez konfiguracji: zero wierszy remote); health mapy `sources`
   obejmują `pr:<server>`.
3. Dokumentacja usage (konfiguracja + kontrakt) + CHANGELOG.

## Dowody

- `bin/ace-test ace-overseer` — 393 testy, 0 fail. Nowe
  (`remote_sources_test`, 5): payload wierszy pr/activity; identyczny stan =
  identyczne rewizje (zero tur); reorder nie rewizuje; nowy HEAD / nowy review
  / merge rewizują właściwe wiersze; awaria forge → marker degraded o stabilnej
  rewizji przy powtórzeniu tej samej klasy błędu.
- Restart/backlog: rewizje pr/activity konsumowane przez eyes wg istniejącego
  kontraktu klucz/rewizja (niepotwierdzone rewizje reconcilują po restarcie).

## Granice / odroczone

- Surowa obserwacja HEAD gałęzi repo (bez PR): providery nie wystawiają API
  odczytu HEAD gałęzi — zmiany HEAD są obserwowane przez PR (head_sha); pełne
  śledzenie gałęzi wymaga rozszerzenia providerów (ujęte przy odbiorze kroku,
  jeśliRequired).
- Odbiór na labie: prawdziwy Forgejo/GitHub, scenariusze 401/429/timeout,
  paginacja, detekcja <=2 interwałów; publikacja gemów.
