---
id: 8wm.t.vs3
status: pending
priority: high
created_at: "2026-09-23 21:11:14"
estimate: TBD
dependencies: [8wm.t.vs2]
tags: [ace-hitl, pilot, release, rubygems]
---

# Pilot: next ACE release exclusively via ace-hitl ask + tested publisher (OTP as HITL answer)

## Kapitan dictation (A5)

Pilot: kolejny release ace WYŁĄCZNIE przez `ace-hitl ask` + tested publisher
(`.ace-bin/ace-rubygems-publish`).

- OTP = zwykła odpowiedź HITL (`kind=otp`);
- agent sam decyduje, czy odpowiedź wystarczy — nie działa, pyta ponownie.

Zależność: po A4 (8wm.t.vs2).

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera, review z
executed checks, merge, release testowanym publisherem.
