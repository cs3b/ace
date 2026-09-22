---
id: 8wl.t.gb4
status: pending
priority: medium
created_at: "2026-09-22 10:52:21"
estimate: 
dependencies: []
tags: [ace-task, b36ts, doctor, enhancement, provenance]
---

# ace-task doctor: catch well-formed forged ids (b36ts decodes to the future)

## Why (selfimprove 2026-09-22, lab-config)

The lab-config incident: 8 hand-forged task ids in 3 repos — 3 broke
the folder convention (invisible to list), 5 were well-formed forgeries
decoding to the FUTURE — and `ace-task doctor` caught none of the
well-formed ones (it validates shape, not provenance).

Enhancement: doctor (and/or create) validates that every task id
decodes (b36ts, 2sec) to a time that is not in the future; forged ids
fail loudly. Interim gate already shipped consumer-side:
tests/test_task_ids.py in cs3b/lab-config (pure-python decoder port).

Status: WAITING in maybe per Captain — the scoped ace overseer picks
this up when the Lab is ready (self-delivery pipeline), no operator
push.

## Acceptance criteria

- [ ] doctor flags ids decoding to the future (and undecodable ids),
      with the offending path and decoded time in the message.
- [ ] regression tests: well-formed forgery (future), broken shape,
      valid past id — the lab-config test ported as reference.
- [ ] create --in bug (0.37.3 manager.move NoMethodError) fixed or
      noted — it minted debris tasks before failing.
