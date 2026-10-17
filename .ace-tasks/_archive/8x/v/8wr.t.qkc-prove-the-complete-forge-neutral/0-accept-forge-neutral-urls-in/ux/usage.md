# Typed PR review input

`pr:https://forge.example/team/repo/pulls/25` and `pr:https://forge.example:3443/git/team/repo/pull/25` produce a bundle PR selector retaining the exact supplied URL. Parsing alone performs no endpoint operation. The same provider lifecycle later resolves and verifies the selected server/repository.

`pr:0`, `pr:owner/repo#0`, `pr:https://forge.example/team/repo/pulls/0`, and `pr:not-a-reference` raise an input error before bundle extraction. Numeric, qualified and GitHub URL forms remain valid.
