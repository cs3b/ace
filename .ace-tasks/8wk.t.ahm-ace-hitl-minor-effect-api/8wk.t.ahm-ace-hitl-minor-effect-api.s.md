---
title: "ace-hitl minor — requester-side effect-callback API"
id: 8wk.t.ahm
status: pending
priority: high
created_at: "2026-09-22 13:35:00"
estimate:
dependencies: []
tags: [ace-hitl, hitl, effects, minor, pilot]
needs_review: false
---

# ace-hitl minor — requester-side effect-callback API

Deliver the gem half of the HITL v3 effect contract (specced and
lab-side-owned in lab-config `8wn.t.efx`; program umbrella
`8wn.t.hit`):

- `ace-hitl` request creation gains the `effect` block: `relay`
  (always) + optional `callback` (match regexp, exec-style argv with
  `{answer}`, cwd, timeout) declared BY THE REQUESTER — the callback
  runs as the requester's Unix identity (security = shell level,
  Captain decision 2026-09-22); commands never come from Telegram.
- Answer consumption/status surface for waiting consumers
  (`<project>:<id>` addressing).
- Backwards compatible minor bump of ace-hitl; version decided at
  implementation.

This is the PAYLOAD of the self-delivery pilot (lab-config
`8wn.t.pil`): the scoped ace overseer runs this task through the full
cycle — spec → task → review → builder → review → publish attempt —
with zero operator intervention; the only human input is the
Captain's Telegram answers.
