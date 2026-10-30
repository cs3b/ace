# Postęp 8xs.t.pu0.c — uczenie Second Captaina na decyzjach (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398).

## Zrealizowane w źródłach

1. **`ace-hitl lesson`** (`HitlManager#add_lesson` + `HitlLessonEditor`):
   - po zaakceptowanej odpowiedzi człowieka na sprawę Z sugestią — jeden
     zapis `## Lesson` przy tej samej sprawie: relation
     (accepted/rejected/modified), takeaway, referencje do dokładnych
     rewizji (`case:<id>`, `suggestion:<id>-s1`, `decision:<answered_at>`),
     autor agenta i czas;
   - idempotencja: identyczne powtórzenie = `:duplicate`; inny drugi wniosek
     = odmowa („reprocessing does not multiply");
   - brak sugestii = brak porównania (odmowa, bez fikcyjnej zgodności);
     brak odpowiedzi = odmowa; sekcja przed `## Answer` — wniosek nie
     nadpisuje pytania/sugestii/decyzji i nie zmienia autora odpowiedzi.
2. **`ace-hitl history`** (`#decision_history`): cytowalna historia decyzji
   dla następnej sugestii — odpowiedziane, NIETAJNE pytania w bieżącym
   scope projektu; wiersze z weryfikowalnymi referencjami (id sprawy,
     suggestion, decision, lesson+relation, decision_at); sekrety/OTP
   filtrowane PRZED przekazaniem czegokolwiek do modelu; szerszy dostęp
   nadzorcy laba nie jest przyzwoleniem na dzielenie historii; bez
   embedding-store/indeksu decyzji/kopii korpusu — HITL jedynym źródłem.
3. **Workflow second-captain** rozszerzony: uczenie po każdej decyzji
   (lesson), podstawianie następnej sugestii w cytowalnej historii (nowsza
   korekta Kapitana > starsza sugestia), jawny brak precedensu zamiast
   fabrykacji, sekrety nigdy w propozycjach/wnioskach/cytatach.
4. Dokumentacja usage (Lesson & History) + CHANGELOG.

## Dowody

- `bin/ace-test ace-hitl` — 391 testów, 0 fail; nowe
  `hitl_lesson_history_test` (5): odrzucona sugestia → lesson z pełnymi
  referencjami przy zachowaniu pytania/sugestii/odpowiedzi; idempotencja +
  odmowa drugiego innego wniosku; brak sugestii = odmowa bez zapisu;
  history cytowalna i bez sekretów (sprawa OTP nieobecna, wartość
  „918273" nieobecna w output); zamknięcie sprawy (apply+close) zachowuje
  question+suggestion+answer+lesson.
- `bin/ace-test ace-coworker` — 400 testów, 0 fail.

## Granice / odroczone

- Trigger lesson (wybudzenie doradcy po decyzji) — obserwacja z kroków
  04-05 na labie; wybór „podobnego tematu" po stronie agenta na cytowalnej
  historii; publikacja gemów.
