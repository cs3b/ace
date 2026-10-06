# Safe commit preparation during Git operations

## Active merge

After resolving and staging a merge, run `bin/ace-git-commit ace-assign --no-split -m "Merge accepted source"`.
Expected: nonzero refusal identifying an active merge, no index or metadata mutation, guidance to complete using native `git commit`. Completing that merge preserves both parents.

## Sequenced operation

During an active cherry-pick or rebase, invoke `bin/ace-git-commit`.
Expected: nonzero refusal before staging or message generation. Existing native `git cherry-pick --continue` or `git rebase --continue` remains usable after required resolutions.

## Ordinary scoped commit

With no operation active, run `bin/ace-git-commit docs/example.md --no-split -m "docs: clarify example"`.
Expected: requested change committed using existing behavior; unrelated working changes remain uncommitted.
