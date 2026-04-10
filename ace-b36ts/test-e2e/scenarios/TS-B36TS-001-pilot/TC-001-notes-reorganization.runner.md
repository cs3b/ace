# Goal 1 - Notes Reorganization

## Goal
Organize five dated note files from `notes/inbox/` into a date-based archive using b36ts-prefixed names.

## Steps
1. Inspect `notes/inbox/` and capture the five source filenames.
2. For each file date (`YYYY-MM-DD`), generate a token using `ace-b36ts encode "<date> 00:00:00 UTC" --format day`.
3. Rename each note to `<token>-<original-name>`.
4. Move each renamed file into `notes/archive/{year}/{month}/{week}/` where:
   - `{year}` is 4-digit year from source date
   - `{month}` is 2-digit month from source date
   - `{week}` is ISO week (`W01`-`W53`)
5. Write `results/tc/01/final-reflection.txt` describing:
   - commands used
   - final folder layout summary
   - one limitation or assumption

## Constraints
- Use real `ace-b36ts` CLI outputs; do not invent tokens.
- Keep all work inside the sandbox.
- Do not delete note content.
