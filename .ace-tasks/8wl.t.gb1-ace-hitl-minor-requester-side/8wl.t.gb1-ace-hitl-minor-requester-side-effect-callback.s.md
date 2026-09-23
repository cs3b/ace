---
title: "ace-hitl minor - requester-side effect-callback API"
id: 8wl.t.gb1
status: in-progress
priority: high
created_at: "2026-09-22 10:52:16"
estimate: 
dependencies: []
tags: [ace-hitl, hitl, effects, minor, pilot]
needs_review: false
---

# ace-hitl minor — requester-side effect-callback API

# ace-hitl minor — requester-side effect-callback API

Deliver the gem half of the HITL v3 effect contract (specced and
lab-side-owned in lab-config `8wl.t.ga9`; program umbrella
`8wl.t.gad`):

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
`8wl.t.gac`): the scoped ace overseer runs this task through the full
cycle — spec → task → review → builder → review → publish attempt —
with zero operator intervention; the only human input is the
Captain's Telegram answers.
