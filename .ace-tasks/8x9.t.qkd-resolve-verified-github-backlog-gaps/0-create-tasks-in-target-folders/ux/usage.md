# Proposed usage contract

These are acceptance scenarios for the draft, not claims of current functionality. Commands use the installed executable spelling; inside ACE use `bin/ace-*`.

## Create in next

Input: `ace-task create "Folder creation example" --status draft --in next`

Expected: Exit 0, one complete task in next.

## Create in maybe

Input: `ace-task create "Deferred example" --status draft --in maybe`

Expected: Exit 0, one complete task in maybe.

## Reject invalid destination

Input: `ace-task create "Invalid example" --in nonexistent-folder`

Expected: Actionable nonzero error; no new task artifacts.

