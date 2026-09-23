---
id: 8wm.t.vs0
status: pending
priority: high
created_at: "2026-09-23 21:11:08"
estimate: TBD
dependencies: [8wm.t.vrz]
needs_review: false
tags: [ace-herdr, hitl, delivery, bootstrap]
---

# ace-herdr: push delivery + agent bootstrap (deliver -> prompt <pane>)

## Kapitan dictation (A2)

ace-herdr: doręczenie pushem + bootstrap.

- `deliver(ref, answer)` -> `herdr agent prompt <pane>`;
- brak agenta -> `herdr agent start` + doręczenie (odpowiedź nie ginie).

Zależność: po A1 (8wm.t.vrz). Biegnie równolegle z A3 (8wm.t.vs1).

## Scope extension (Kapitan, 2026-09-23 — brief 8wl.t.gad.7, back-ref)

Warstwa ergonomiczna zero-token nad herdr CLI (jak ace-tmux dla tmuxa):

1. **Dispatch podagenta w 1 komendzie**: tab + `herdr agent start` +
   prompt z sensownymi domyślnymi: ten sam workspace/sesja co
   wywołujący, label = id zadania, nazwa agenta = id zadania, prompt
   z pliku lub stdin.
2. **Monitor bez szumu**: odczyt stanu/wyjścia agenta; oczekiwanie na
   gotowość (wait); wyciszenie kodów/statusów.
3. **Domknięcie**: rename/close po zakończeniu, zwrot wyniku.

Wszystko deterministyczne (zero token) — cienki wrapper na socket API
herdra; żadnych decyzji LLM w środku. Domyślnie ten sam space, w którym
pracuje wywołujący.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera, review z
executed checks, merge, release testowanym publisherem.

## Spec review findings (review-8wmw3q, codex gpt-5.6-luna)

Wymagania dla buildera spec (A2):

- readiness detection after `herdr agent start` before prompting the pane;
- idempotency key (event/message ID) so retries never duplicate answers;
- retry limits + backoff; terminal-failure reporting when delivery is
  impossible;
- tests: existing-agent delivery, bootstrap delivery, startup failure,
  duplicate delivery.
