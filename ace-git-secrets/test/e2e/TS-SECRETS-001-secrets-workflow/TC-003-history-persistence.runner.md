# Goal 3 — History Persistence

## Goal

Remove the file containing secrets from the working tree using `git rm`, commit the removal, then re-scan. Verify the scanner still detects the secrets in git history (since `git rm` does not clean history).

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/removal.stdout`, `.stderr`, `.exit` — git rm and commit output
- `results/tc/03/removal.sha` — commit SHA after the removal commit
- `results/tc/03/removal.show` — `git show --stat` for the captured removal SHA
- `results/tc/03/rescan.stdout`, `.stderr`, `.exit` — scan after removal

## Constraints

- Remove config.env with `git rm`, commit, then re-scan.
- Capture explicit proof that the removal was committed, not only that the file
  was deleted from the working tree.
- The scan uses `gitleaks git` which inspects full commit history.
- All artifacts must come from real tool execution, not fabricated.
