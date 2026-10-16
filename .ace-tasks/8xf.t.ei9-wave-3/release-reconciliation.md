# Rebased source release reconciliation

This is a source release checkpoint for 8xf.t.ei9, not installed acceptance.

The 30 completed commits were rebased onto main
`f653537283410935204fc210d13ce176c66abbb7`. Range comparison retained all 30;
29 patches were identical, and the release commit preserved both sides of the
root changelog conflict. Before rebase:
`124c2a79180c8f653cc42d9363a86a5ae0f4e1f6`; rebased implementation:
`b21e450174d1cf9b111018e4eac47dc35eb8c4dc`.

## Registry and payload audit

Direct RubyGems API audit at 2026-10-16T17:13:59.324564+00:00 checked all 50 local
gemspecs: 42 version matches, eight unpublished higher versions, no lower local
versions and no lookup failures. The Captain's newly published ace-lint 0.30.11,
ace-llm-providers-cli 0.36.2 and ace-design 0.2.0 match both local versions and
published payloads. They must not be republished.

| Package | Published | Pending |
|---|---|---|
| ace-assign | 0.69.0 | 0.70.0 |
| ace-bundle | 0.45.0 | 0.45.1 |
| ace-herdr | 0.5.1 | 0.6.0 |
| ace-hitl | 0.15.0 | 0.16.0 |
| ace-lab | 0.7.0 | 0.8.0 |
| ace-overseer | 0.21.1 | 0.22.0 |
| ace-review | 0.60.2 | 0.60.3 |
| ace-task | 0.39.3 | 0.40.0 |

All 42 matching-version archives were downloaded and checked against the
registry's SHA-256. Forty-one have exactly the same packaged files and bytes as
this checkout. The sole difference is the existing ace-llm 0.42.0 CHANGELOG note
about credential redaction; its executable/library payload is identical. That
historical documentation correction is not a new release or publication request.

All local ACE runtime dependency constraints accept the selected local versions.
The 42 matching versions have the same runtime dependency metadata as RubyGems.
The approved Unix/mTLS join and protected configuration reader are included in
the still-unpublished Lab 0.8.0 and HITL 0.16.0 releases; no published version is
being changed. Unfinished Hermes routing stays outside this release.

Audit inputs and full reports are in the retained worktree directory
`.ace-local/git/8xfptc-rebase/version-audit/`: `rubygems-audit.json`,
`published-payload-comparison.json`, `dependencies.json` and `local-payloads.json`.
The API source for each package is `https://rubygems.org/api/v1/gems/NAME.json`.

## Superseded artifacts and publication boundary

`initial-runtime-release.json` remains an unchanged historical record of the
unpublished 5768ec3dd cut. Its exact archives proved disposable installation;
they do not describe the rebased source including the later TLS join. The active
worktree publisher queue and those package-directory archives were moved to
`.ace-local/git/8xfptc-rebase/superseded-artifacts/`. No archive or receipt was
silently overwritten. Production adoption of that cut is on hold.

After current source tests and independent review pass, integrate the completed
source into main and build the pending artifacts there with the existing
publisher. Publish only that main-built set. Registry publication, production
installation and two-project autonomous acceptance remain separate gates.

## Independent integration review

Independent reviewer verdict: APPROVE for the rebase, reconciled versions and
integration of completed source into main. The reviewer independently refreshed
all 50 registry records, verified the new three published payloads and the LLM
changelog exception, checked dependency compatibility and all 85 changed
packaged runtime/assets files. Isolated packaging/workflow checks passed
14 tests / 145 assertions (`overseer/44566c1e-ee7c-4f68-96e8-5da87687e137`).
`bundle check` and `git diff --check` passed. The default 51-package suite is
being executed separately; its final result is required before integration.
