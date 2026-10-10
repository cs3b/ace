# Proposed usage contract

These are acceptance scenarios for the draft, not claims of current functionality. Commands use the installed executable spelling; inside ACE use `bin/ace-*`.

## Missing receipt

Input: `Run current campaign review for a PR changing only assets/photo.png without alternative evidence`

Expected: Binary verification remains incomplete; delivery cannot be accepted.

## Valid isolated verification

Input: `Verify the exact PNG using trusted policy and import its bound receipt into the current campaign`

Expected: Only that head/base/artifact obtains an alternative-verification disposition.

## Stale artifact

Input: `Replace the PNG after receipt creation and retry campaign acceptance`

Expected: Receipt rejected; no accepted outcome.

