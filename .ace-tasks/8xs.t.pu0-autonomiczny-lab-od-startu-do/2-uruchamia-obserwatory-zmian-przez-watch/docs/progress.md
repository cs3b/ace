# Postęp 8xs.t.pu0.2 — /watch rzeczywiście obserwuje (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Odbiór runtime (żywa sesja Pi,
virtiofs na labie) odroczony na koniec programu (decyzja Kapitana).

## Reprodukcja (zgodnie z kontraktem review)

Na wersji pakietu po kroku 01 odtworzono publiczną ścieżkę `/watch add probe
--path P --message M` z aktywnym `/eyes`:

1. **Rejestracja odrzucona**: handler `/watch add` zwracał błąd „Legacy
   watches are retired while eyes owns observation" — watch nigdy nie
   powstawał (triggerWatch: no watcher registered). Faktyczną przyczyną
   nieskutecznej obserwacji było więc KONKURUJĄCE właścicielstwo obserwacji
   przez eyes, a nie brak wywołania start (`WakeRegistry.addWatch` startuje).
2. **Aktywne watche usuwane**: `retireLegacy` wywoływane przy `eyes start`,
   bind i reload usuwało wszystkie wpisy /loop i /watch.

## Naprawa

- `index.js`: usunięte guardy `eyes.active()` w `/watch add` i `/loop add` oraz
  całe okablowanie `retireLegacy`; eyes i rejestr współistnieją — wspólna
  infrastruktura dostawy (registry + sendUserMessage), bez shimów.
- `wake/eyes-runtime.js`: parametr i wywołania `retireLegacy` usunięte
  (start/bind/retire); pozostałe semantyki eyes (breaker, quota, retire) bez
  zmian.

## Dowody

- Nowe testy `test/watch-eyes-coexistence.test.mjs` (ścieżka publicznej
  komendy przez rejestrację Pi → native watcher → konsumpcję wiadomości):
  - `/watch add` pod aktywnym eyes: rejestracja przyjęta, dokładnie jedno
    wybudzenie na zmianę, 30 s zdrowej ciszy = zero dodatkowych tur;
  - `eyes start` po dodaniu watcha: watch przeżywa, nadal dostarcza.
  Przed naprawą oba testy failowały (reprodukcja).
- Zaktualizowany `test/eyes-runtime.test.mjs`: koegzystencja timerów
  (obserwator + 2 loopy), loop add pod eyes przyjęty, retire eyes zostawia
  loopy; asercje strumienia eyes odseparowane od ticków loopów.
- Pełny suite JS: 131 testów, 0 fail (`node --test` + `bin/ace-test ace-wake`).
  Istniejące pokrycie regresyjne bez zmian: virtiofs poll-fallback 2,5 s,
  atomic replace, rename/delete/create, unreadable source (widoczny błąd, nie
  pozorna obserwacja), absent inbox → detekcja utworzenia, remove+add,
  identyczne bytes (content hash), błąd runtime widoczny w status/list.
- `bin/ace-test ace-handbook-integration-pi` — 9 testów, 0 fail; usage
  dokumentuje kontrakt koegzystencji.

## Odroczone (koniec programu)

- Odbiór na labie: prawdziwy udział virtiofs, sesja Pi z guide z kroku 02,
  publiczny /watch w żywym harnessu, publikacja gemu ace-wake.
