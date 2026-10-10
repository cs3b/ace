# Proposed usage contract

These are acceptance scenarios for the draft, not claims of current functionality. Commands use the installed executable spelling; inside ACE use `bin/ace-*`.

## Small prompt

Input: `ace-llm "Review this small example" -m agy:gemini-3.7-flash-medium`

Expected: Direct prompt transport; normal result.

## Large review

Input: `ace-review --preset quick --auto-execute --subject diff:HEAD`

Expected: With an AGY lane and a 354141-byte prepared prompt, full content arrives through supported file delivery.

## Denied file read

Input: `Run the large-prompt scenario with file read refused by the headless CLI`

Expected: Actionable provider failure; cleanup completes and no partial review is marked complete.

