---
id: 8wm.t.vs1
status: pending
priority: high
created_at: "2026-09-23 21:11:10"
estimate: TBD
dependencies: [8wm.t.vrz]
needs_review: false
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

## Spec review findings (review-8wmw3q, codex gpt-5.6-luna)

Wymagania dla buildera spec (A3):

- folder contract document must be versioned and ship a JSON schema:
  filename validation, encoding + size bounds, ownership/permissions,
  invalid-file handling (quarantine), collision and undeleted-file retries;
- define state transitions: write → validate → deliver → ACK deletion /
  retry / quarantine;
- atomic write = same-directory tmp file + rename, no root privileges;
- `8wm.t.vp9` is the lab-config side (separate repo, intentional
  cross-repo reference); canonical contract location/ownership is settled
  in A4 (8wm.t.vs2) — reference it explicitly.

## Pipeline

Pełny pipeline architekta: spec przez buildera, kod przez buildera, review z
executed checks, merge, release testowanym publisherem.
