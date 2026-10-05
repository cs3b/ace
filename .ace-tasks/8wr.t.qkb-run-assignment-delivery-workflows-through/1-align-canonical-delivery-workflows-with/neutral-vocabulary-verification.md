# Executed neutral vocabulary source verification

Initial source candidate: `b6a93a33779709009cb495171c14a20bdb73c40f`, based on
`a33ccd92ce45dc84e06985254873405981dc4220`.
Correction candidate: `f29c72e3a45a7f3715ac93a8ab9fc7a806b2ed6b`.
[Round1 independent review](neutral-vocabulary-source-review-round1.md) requested
changes for the missing explicit standalone entry mode. The correction restores
it and places requested preparation before final evidence/merge; post-merge
preparation is a distinct follow-up candidate.
[Round2 independent review](neutral-vocabulary-source-review-round2.md) **APPROVES
the bounded source checkpoint at exact f29c72e3a45a7f3715ac93a8ab9fc7a806b2ed6b**.
Root owns final composed-tree verification and integration. The earlier request
for changes is retained without rewriting its verdict.

[The source checkpoint](neutral-vocabulary-source-checkpoint.md) describes the
bounded ownership and remaining whole-task/installed gates. No runtime API,
version or dependency changed. No task completion is claimed.

## Executed receipts

[Receipt index](evidence/neutral-vocabulary/receipt-index.json) records original
paths, retained paths and byte hashes of generated raw/report/summary files.
Copies are unchanged; counts below distinguish total tests from skips.

| Command/scope | Result | Execution ID |
| --- | --- | --- |
| `bin/ace-test ace-handbook test/feat/neutral_pr_vocabulary_test.rb test/fast/organisms/provider_syncer_test.rb`, initial | 38 tests, 327 assertions, no failures/errors | 788d988c-b74b-4550-9f48-1cf472d03840 |
| Assign catalog/executor/preset group, five files | 103 tests, 545 assertions, no failures/errors | 52e96a91-faa8-4577-a823-1af3e3d9874c |
| `bin/ace-test ace-handbook all` | 77 tests, 535 assertions, no failures/errors | 9e33c1c7-c468-4d6f-a2b8-dfa88caa02f5 |
| `bin/ace-test ace-git all` | 575 tests, 1425 assertions, no failures/errors | cc4ce7cd-8794-4c24-8c2e-276dcc0123ec |
| `bin/ace-test ace-git-worktree all` | 528 passed, 18 skipped, 1550 assertions, no failures/errors | e0c2058e-1419-4cb3-9c1c-3b7f2b8083eb |
| `bin/ace-test ace-review all` | 937 passed, 4 skipped, 2975 assertions, no failures/errors | 7bb99ac4-9302-4cb3-88fe-e32f7c2a1b2c |
| Focused Handbook group after standalone correction | 38 tests, 327 assertions, no failures/errors | 89fdf32b-0b85-41d1-8ae6-f886d610ec99 |
| Independent reviewer, initial b6 source | 2 tests, 42 assertions, no failures/errors; semantic verdict REQUEST CHANGES | 1b551cfe-8b01-47d7-baff-1c7186b9b379 |
| Independent reviewer, exact f29 correction | 2 tests, 42 assertions, no failures/errors; bounded semantic verdict APPROVE | ef460be3-45c8-47e0-a2b6-5cafccbe9300 |

The exact five Assign files are retained in its report configuration and tested
file list; its package implementation was unchanged. The broad package checks
tested the initial behavioral source before freeze, with only editorial
changelog/checkpoint additions afterward. The last focused check tested the
corrected source before its corrective commit.

Frozen initial `bin/ace-test-suite --timeout 300` completed at b6a93a337:
**51 package passes, 11,273 tests passed, 24 skipped, 34,610 assertions,
zero failures/errors**, exit0 in131.98 seconds. Its
[51-entry manifest](evidence/neutral-vocabulary/initial-combined-suite-manifest.json)
retains invocation-bound summaries, selected files, targets and report hashes,
including both configured Lab entries. Assign completed in129.24 seconds.
This is the established combined verification ceiling; default targets were
unchanged. It is historical b6 verification, not relabeled as an exact f29 suite.

The f29 delta changes only the generic delivery workflow prose, source checkpoint
and retained round1 report. The source/projection regression was rerun; independent
delta review assesses the actual instructions and standalone/managed boundary.
No broad-suite failure is erased or claimed as reviewed approval.

## Source checks and limits

[Named-consumer inventory](neutral-vocabulary-source-inventory.md) records the
active source checks, retained historical/rejection examples, owning gems and
unchanged consumers. It is a source vocabulary gate, not installed acceptance.

Source `ace-nav resolve` and `ace-bundle` both resolve the four final names to this
worktree's package-owned files. Normal agents sync reported102 skills,
2updated and2removed. Old skills return unknown errors. Old WFI names remain
reachable through the existing explicit user registration pointing at installed
ace-git0.24.0; `--why` identified priority20 `@ace-git-user`. This candidate
introduces no alias, changes no user configuration and claims no clean installed
old-name rejection.

Read-only CLI help checked create/update/ready/merge/show/review/delivery options.
The real manifest/scanner/projection test performs no package build/install.
Controlled ordinary tests and manual source inspection provide no live forge,
authorized executor, cross-user native, installed publication or Lab proof.
Both frozen commits passed committed diff checks; all whole qkb.1 remaining
criteria stay open.
