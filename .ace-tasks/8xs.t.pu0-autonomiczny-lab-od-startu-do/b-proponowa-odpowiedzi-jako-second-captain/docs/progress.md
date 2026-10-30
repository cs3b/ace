# Postęp 8xs.t.pu0.b — sugestia Second Captaina (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Rendering wątku Hermes (Telegram,
odpowiedź na dokładny message-id pytania) — strona transportu, odbiór na labie
odroczony na koniec programu.

## Zrealizowane w źródłach

1. **Zapis suggestion w ace-hitl** (jawny typ, nie Answer):
   - `HitlSuggestionEditor`: własna sekcja `## Suggestion` (author, at,
     refs, proposal, rationale) wstawiona PRZED `## Answer` — edytor Answer
     zastępuje końcówkę pliku od nagłówka Answer, więc sugestia przetrwa
     każdą aktualizację odpowiedzi; zapis atomowy pod flock;
   - `HitlManager#add_suggestion`: jedna propozycja na case (identyczne
     powtórzenie = `:duplicate` no-op; inna druga = odmowa), case
     `secret: true` nigdy nie trafia do doradcy, case już answered = odmowa
     („discard the late suggestion" — decyzja człowieka bez drugiego
     approval); referencja wyłącznie dokładnym id (bez skrótów);
   - `ace-hitl suggest CASE --by --text --rationale [--refs]`.
2. **Rola second-captain w ace-coworker**: preset doradczy (instrukcja
   `wfi://coworker/second-captain`, start_prompt per-case, reporting HITL)
   + workflow: czyta dokładną sprawę i wskazane podstawy, pisze JEDNĄ
   oznaczoną sugestię i kończy; bez budzenia Kapitana, bez otwierania spraw,
   bez stosowania odpowiedzi; sekretne sprawy zgłaszane jako mismatch;
   późna sugestia po decyzji = discard + zamknięcie assignmentu bez
   powiadomienia.
3. Sugestia nie zwalnia żadnego gate'a (integration gate z kroku 09 nie zna
   typu suggestion — Answer/approval pozostają jedyną droga) i nie jest
   Answer (answered/false nietknięte — testowane).
4. Dokumentacja usage (sekcja Suggest) + CHANGELOGe (ace-hitl,
   ace-coworker).

## Dowody

- `bin/ace-test ace-hitl` — 386 testów, 0 fail; nowe `hitl_suggest_test`
  (6): sugestia oznaczona/autorowana/uzasadniona z podstawami bez
  answered:true; identyczne powtórzenie duplicate + inna druga odmowa;
  Answer NIE usuwa sugestii (sekcja przed Answer); sugestia po odpowiedzi
  człowieka odrzucona bez zapisu; sprawa secret nigdy do doradcy;
  skrót/nieznane id odmowa.
- `bin/ace-test ace-coworker` — 400 testów, 0 fail (preset + workflow w
  tree).

## Granice / odroczone

- Trigger delegacji nadzorcy (obserwacja nowego nietajnego pytania po
  rozpoczęciu dostawy) — guide/obserwacja z kroków 04-05; pełne okablowanie
  na labie.
- Wysłanie sugestii w wątku dokładnego message-id pytania przez Hermes —
  strona transportu (lab); brak potwierdzonego message-id = brak wysyłki w
  przypadkowy wątek (kontrakt w workflow).
- Publikacja gemów.
