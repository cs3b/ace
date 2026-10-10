# Proposed usage contract

These are acceptance scenarios for the draft, not claims of current functionality. Commands use the installed executable spelling; inside ACE use `bin/ace-*`.

## Independent source feedback

Input: `Deliver a task with a declared active source reference and no delivery-thread binding`

Expected: One authorized consumption note with shipped PR/SHA; durable receipt.

## Retry closeout

Input: `Resume closeout after publication succeeded but the caller was interrupted`

Expected: Reconcile existing receipt; no duplicate note.

## Prose citation only

Input: `Deliver a task mentioning a thread URL only in References`

Expected: Advisory only; no message is sent.

