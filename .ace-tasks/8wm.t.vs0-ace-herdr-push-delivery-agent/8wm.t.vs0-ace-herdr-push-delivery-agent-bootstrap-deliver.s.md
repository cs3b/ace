---
id: 8wm.t.vs0
status: pending
priority: high
created_at: "2026-09-23 21:11:08"
estimate: TBD
dependencies: [8wm.t.vrz]
tags: [ace-herdr, hitl, delivery, bootstrap]
---

# ace-herdr: push delivery + agent bootstrap (deliver -> prompt <pane>)

## Kapitan dictation (A2)

ace-herdr: doręczenie pushem + bootstrap.

- `deliver(ref, answer)` -> `herdr agent prompt <pane>`;
- brak agenta -> `herdr agent start` + doręczenie (odpowiedź nie ginie).

Zależność: po A1 (8wm.t.vrz). Biegnie równolegle z A3 (8wm.t.vs1).

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
