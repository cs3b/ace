---
id: 8wm.t.vs1
status: pending
priority: high
created_at: "2026-09-23 21:11:10"
estimate: TBD
dependencies: [8wm.t.vrz]
tags: [ace-hitl-hermes, hitl, hermes, folder-contract]
---

# ace-hitl-hermes: folder as interface — registry, notifications, atomic answer files, folder contract

## Kapitan dictation (A3)

ace-hitl-hermes: folder jako interfejs.

- plugin przejmuje rejestr kanałów, notyfikacje, formaty;
- odpowiedź Kapitana = plik `<folder>/<id>.json` z polami
  `answer` / `sender` / `received_at`;
- zapis atomic (tmp + rename).

## Folder contract (wspólny z lab-config 8wm.t.vp9)

- folder współdzielony lab <-> hermes;
- ACK = skasowanie pliku przez labd po doręczeniu;
- walidacja treści fail-closed;
- plugin pisze bez roota.

Zależność: po A1 (8wm.t.vrz). Biegnie równolegle z A2 (8wm.t.vs0).

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera, review z
executed checks, merge, release testowanym publisherem.
