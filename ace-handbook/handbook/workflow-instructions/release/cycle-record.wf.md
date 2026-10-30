---
name: release-cycle-record
description: Write the integrated delivery-cycle evidence record into .ace-tasks/_records through a normal reviewed record-only PR
allowed-tools: Bash, Read
doc-type: workflow
title: Delivery Cycle Record Workflow
purpose: Bind the record contract — one reviewed document per delivery cycle naming task/cycle, source HEAD, review/test evidence, publish versions and digests, runtime paths and the runtime outcome — without starting a new release or a recursive record.
ace-docs:
  last-updated: '2026-10-30'
  last-checked: '2026-10-30'
---
# Delivery Cycle Record Workflow

## Goal

Close a delivery cycle with a durable, reviewed Git record of the WHOLE path:
sources, integration, publication, installation, runtime outcome (task
8xs.t.pu0.9). The record is evidence, not a control queue: the live cycle
state stays in its task/assignment until the record is integrated.

## Instructions

### 1) Gather facts from the owners — never from memory

Every value comes from evidence produced by the owners:

- task/cycle reference and the managing assignment;
- source HEAD (the merged candidate) and the merge proof;
- review/test evidence: the independent reviewer verdict, the executed test
  commands with their results, and the HEAD each was bound to
  (`ace-coworker gate` inputs);
- publication: package versions and artifact digests from the artifact
  repository (checked, not assumed — an interrupted publish must have been
  reconciled first);
- runtime: the installed gem/CLI/extension paths and versions the target
  account actually ran, and the acceptance result.

Do not fabricate identifiers, SHAs, or version endings. If a fact is
missing, the cycle is NOT complete — say so in the task and stop.

### 2) Write the record

Place one document under `.ace-tasks/_records/<dated-cycle-slug>/` with the
sections: Goal, Source (HEAD, PR), Review & Tests (bound heads, verdicts,
commands), Publication (versions + digests), Installation & Runtime
(paths, versions, acceptance under the target account), Outcome (closed or
explicitly open with the blocking reason and resume point).

### 3) Integrate through a normal review

The record goes through a record-only PR with the ordinary review/integration
gate. It does NOT trigger another release (no product change) and requires no
recursive record of its own merge. After the record's integration, mark the
task done (`ace-task update <ref> --set status=done` — archive per the task
family's convention).

## Boundaries

- No secrets, OTP values, or tokens in the record.
- A failed or partially deployed cycle keeps the task open with a resumable
  blocking state; the record documents the stage truthfully instead.
