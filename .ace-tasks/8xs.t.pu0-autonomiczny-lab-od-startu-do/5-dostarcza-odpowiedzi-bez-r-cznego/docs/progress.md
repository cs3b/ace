# Postęp 8xs.t.pu0.5 — odpowiedź bez ręcznego relay (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Strona Hermes (Python plugin,
SSH do maszyny właściciela, binding machine/konto/root w konfiguracji trasy)
jest właścicielem hosta/labu — odbiór na labie odroczony na koniec programu.

## Zrealizowane w źródłach

1. **`HitlManager#receive_answer`** — zapis dostarczonej odpowiedzi dla
   DOKŁADNIEJ jednej sprawy:
   - referencja musi być dokładnym id (skrót/latest → jawny błąd; kolizja
     nigdy nie trafia do cudzej sprawy);
   - idempotencja: ponowienie identycznej odpowiedzi = `:duplicate` bez
     zapisu; konflikt (inna treść) = `AnswerConflictError`, decyzja człowieka
     nigdy nie jest nadpisywana;
   - report zamiast question = błąd; pusty tekst odrzucany na poziomie CLI;
   - zapis przez istniejący, flockowany `apply_field_and_answer_updates`
     (first_answer) — jeden właściciel zapisu odpowiedzi.
2. **`ace-hitl reply CASE_ID --stdin`** — komenda odbiorcy na maszynie
   właściciela: treść wyłącznie przez stdin (nigdy shell/argv), wynik zawiera
   tylko `{"case":..., "state":"received|duplicate"}`; sukces = potwierdzony
   trwały zapis przez ace-hitl (nie frame w transporcie); każda porażka to
   jawne „not delivered" bez zmian w jakiejkolwiek sprawie.
3. Ask pozostaje create/send/arm/end-turn (bez zmian); ask bridge w ace-wake
   wiąże oczekiwanie z sesją (per-session watch port, case-bound watch) —
   odpowiedź zapisana podczas nieobecności odbiorcy jest trwałym rekordem i
   zostaje skonsumowana po powrocie sesji (istniejące testy ask-bridge).

## Dowody

- `bin/ace-test ace-hitl` — 372 testy, 0 fail; nowe `hitl_cli_reply_test`
  (7): received z poprawnym outputem, duplicate bez nadpisania pliku,
  konflikt bez zmiany decyzji, pusta odpowiedź, report, skrót i nieznane id,
  trwałość odpowiedzi po „zniknięciu" pytającego.
- CLI smoke (scratch project /tmp/hitl-reply-smoke, bundle exec):
  `echo "Proceed" | ace-hitl reply 8xt0ga --stdin` →
  `{"case":"8xt0ga","state":"received"}` exit 0; ponownie → `duplicate`
  exit 0; inna treść → exit 1 „never overwrites a decision"; nieznane id →
  exit 1 „no HITL case with exact id"; plik sprawy: `answered: true` +
  `## Answer`.

## Granice / odroczone

- Strona transportu Hermes (SSH, konto, host key, korelacja adresu
  machine/project/root/case z wysłanym pytaniem) — host/lab; bez nowego
  serwisu i bez auto-provisioningu (not-ready przy braku konfiguracji).
- Usunięcie importu reply przez sync/pośrednika — dopiero PO odbiorze nowej
  ścieżki na labie (reguła briefu: usuwamy zastąpione dopiero po odbiorze).
- Jawne oznaczanie sekretnych odpowiedzi przy tworzeniu pytania (bez
  heurystyki tytułu) — do domknięcia przy odbiorze .6/.7 (cykl życia spraw).
- Publikacja gemu ace-hitl.
