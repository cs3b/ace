# Goal 1 - Notes Reorganization

## Goal

Organize five dated note files from `notes/inbox/` into a date-based archive
using `ace-b36ts` tokens derived from each note date.

## Public Path

- Confirm command behavior with `ace-b36ts/docs/usage.md` and `ace-b36ts --help`.
- Save command captures and derived evidence under `results/tc/01/`.

## Steps

1. Inspect `notes/inbox/` and capture the five source filenames.
2. For each file date (`YYYY-MM-DD`), generate a token using `ace-b36ts encode "<date> 00:00:00 UTC" --format day`.
3. Rename each note to `<token>-<original-name>`.
4. Move each renamed file into `notes/archive/{year}/{month}/{week}/` where:
   - `{year}` is 4-digit year from source date
   - `{month}` is 2-digit month from source date
   - `{week}` is ISO week (`W01`-`W53`)
5. After the reorganization finishes, capture the final recursive listing of `notes/inbox/` into `results/tc/01/inbox-final.txt` so the verifier can confirm the source directory is empty.
6. Capture the final recursive listing of `notes/archive/` into `results/tc/01/archive-final.txt` so the verifier can confirm file count, token prefixes, and `year/month/week` segmentation from an explicit artifact.

## Constraints

- Use real `ace-b36ts` CLI outputs; do not invent tokens.
- Keep all work inside the sandbox.
- Do not delete note content.
- Use filesystem outcomes under `notes/archive/` as the primary oracle.
- Capture final source-directory state explicitly; do not leave inbox cleanup to inference.
- Do not write ad-hoc reflection or helper recipe artifacts outside `results/tc/01/`.
